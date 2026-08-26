import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var settings: ({})

  // Reactive state
  property bool loading: false
  property bool hasError: false
  property string errorMessage: ""
  property double lastFetchedMs: 0
  property bool isStale: false
  property double bootTimeMs: 0
  property string todayDateStr: Qt.formatDate(new Date(), "yyyy-MM-dd")
  property bool paused: false

  onPausedChanged: {
    if (!paused) {
      refresh()
    }
  }

  // Parsed data model
  property string providerLabel: "OMP Usage"
  property string accountEmail: ""
  property var quotaPools: []
  property var tokensList: []
  property var tokensByPool: ({})
  property int totalTokens: 0
  property double maxUsedPercentage: 0.0

  // Availability / Exhaustion flags
  property bool allExhausted: false
  property bool anyExhausted: false
  property bool hasAvailable: true

  // Polling control
  property bool panelOpen: false
  property bool isActive: false

  readonly property int pollInterval: {
    if (isActive) return 3000;
    if (panelOpen) return 5000;
    return 60000;
  }

  Timer {
    id: pollTimer
    interval: root.pollInterval
    running: !root.paused
    repeat: true
    onTriggered: {
      if (!root.paused) root.refresh()
    }
  }

  // 0. Uptime detector for session tracking
  Process {
    id: uptimeProcess
    command: ["sh", "-c", "cut -d. -f1 /proc/uptime 2>/dev/null || echo 0"]
    running: true

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var secs = Number(this.text.trim()) || 0
        if (secs > 0) {
          root.bootTimeMs = Date.now() - (secs * 1000)
        }
      }
    }
  }

  // 1. Quota limits process
  Process {
    id: ompProcess
    command: ["omp", "usage", "--json"]
    running: false

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.loading = false
        var rawText = this.text.trim()
        if (!rawText) {
          root.hasError = true
          root.errorMessage = "Empty output from omp"
          root.isStale = true
          return
        }

        var start = rawText.indexOf("{")
        var end = rawText.lastIndexOf("}")
        if (start < 0 || end <= start) {
          root.hasError = true
          root.errorMessage = "No valid JSON found in omp usage output"
          root.isStale = true
          return
        }

        try {
          var data = JSON.parse(rawText.slice(start, end + 1))
          root.parsePayload(data)
          root.hasError = false
          root.errorMessage = ""
          root.isStale = false
          root.lastFetchedMs = Date.now()
        } catch (e) {
          root.hasError = true
          root.errorMessage = "JSON parse error: " + e.message
          root.isStale = true
        }
      }
    }

    onExited: function(exitCode) {
      root.loading = false
      if (exitCode !== 0) {
        root.hasError = true
        root.errorMessage = "omp exited with code " + exitCode
        root.isStale = true
      }
    }
  }

  // 2. Token stats process
  Process {
    id: statsProcess
    command: ["omp", "stats", "--json"]
    running: false

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var rawText = this.text.trim()
        if (!rawText) return
        var start = rawText.indexOf("{")
        var end = rawText.lastIndexOf("}")
        if (start < 0 || end <= start) return
        try {
          var data = JSON.parse(rawText.slice(start, end + 1))
          root.parseStats(data)
        } catch (e) {
          // Non-fatal, token stats optional
        }
      }
    }
  }

  function refresh() {
    if (root.paused) return
    if (!ompProcess.running) {
      root.loading = true
      ompProcess.running = true
    }
    if (!statsProcess.running) {
      statsProcess.running = true
    }
  }

  function formatModelLabel(modelName) {
    if (!modelName) return "Other"
    return modelName
      .split("-")
      .map(function(part) {
        if (!part) return ""
        if (part === "gpt") return "GPT"
        if (part === "oss") return "OSS"
        if (part === "glm") return "GLM"
        return part.charAt(0).toUpperCase() + part.slice(1)
      })
      .join(" ")
  }

  function parseStats(data) {
    if (!data) return
    var items = []
    var total = 0
    var poolTokens = {}

    // 1. Calculate today's totals per model (since 00:00)
    if (data.byModel && Array.isArray(data.byModel)) {
      for (var i = 0; i < data.byModel.length; i++) {
        var m = data.byModel[i]
        var inputTokens = Number(m.totalInputTokens || 0)
        var outputTokens = Number(m.totalOutputTokens || 0)
        var count = inputTokens + outputTokens
        if (count > 0) {
          total += count
          items.push({
            label: formatModelLabel(m.model),
            count: count
          })

          // Map to pool name
          var mName = (m.model || "").toLowerCase()
          if (mName.indexOf("gemini") >= 0 || mName.indexOf("google") >= 0) {
            poolTokens["GEMINI"] = (poolTokens["GEMINI"] || 0) + count
          } else if (mName.indexOf("claude") >= 0 || mName.indexOf("anthropic") >= 0) {
            poolTokens["CLAUDE"] = (poolTokens["CLAUDE"] || 0) + count
          } else if (mName.indexOf("gpt") >= 0 || mName.indexOf("openai") >= 0) {
            poolTokens["GPT-OSS"] = (poolTokens["GPT-OSS"] || 0) + count
          } else if (mName.indexOf("glm") >= 0 || mName.indexOf("zai") >= 0) {
            poolTokens["ZAI"] = (poolTokens["ZAI"] || 0) + count
          }
        }
      }
    }

    // Sort tokens descending
    items.sort(function(a, b) { return b.count - a.count })

    root.tokensList = items
    root.totalTokens = total
    root.tokensByPool = poolTokens

    // Update quota pools with session tokens immediately
    if (root.quotaPools && root.quotaPools.length > 0) {
      var updated = []
      for (var p = 0; p < root.quotaPools.length; p++) {
        var pool = root.quotaPools[p]
        var pToks = poolTokens[pool.name] || 0
        if (pool.windows && pool.windows.length > 0) {
          pool.windows[0].sessionTokens = pToks
        }
        updated.push(pool)
      }
      root.quotaPools = updated
    }
  }

  function formatProviderName(id, label, provider) {
    if (label) {
      var match = label.match(/^Usage\s*\(([^)]+)\)$/i)
      if (match) {
        var inner = match[1].trim().toLowerCase()
        if (inner === "google") return "GEMINI"
        if (inner === "anthropic") return "CLAUDE"
        if (inner === "openai") return "GPT-OSS"
        return match[1].trim().toUpperCase()
      }
      return label.toUpperCase()
    }

    if (id) {
      var parts = id.split(":")
      if (parts.length >= 2) {
        var sub = parts[1].toLowerCase()
        if (sub === "google") return "GEMINI"
        if (sub === "anthropic") return "CLAUDE"
        if (sub === "openai") return "GPT-OSS"
        return parts[1].toUpperCase()
      }
    }

    if (provider) {
      var p = provider.toLowerCase()
      if (p === "google-antigravity") return "GOOGLE ANTIGRAVITY"
      return provider.toUpperCase()
    }

    return "AI MODEL"
  }

  function parsePayload(data) {
    if (!data) return

    var reports = data.reports || []
    var pools = []
    var maxUsed = 0.0
    var totalMeteredCount = 0
    var exhaustedCount = 0
    var providerLabels = []
    var emails = []

    // 1. Process all active reports and their limits dynamically
    for (var r = 0; r < reports.length; r++) {
      var report = reports[r]
      var pName = report.provider === "google-antigravity" ? "Google Antigravity" : (report.provider || "OMP")
      if (providerLabels.indexOf(pName) < 0) providerLabels.push(pName)

      if (report.metadata && report.metadata.email) {
        if (emails.indexOf(report.metadata.email) < 0) emails.push(report.metadata.email)
      }

      var limits = report.limits || []
      for (var i = 0; i < limits.length; i++) {
        var lim = limits[i]
        var poolName = formatProviderName(lim.id, lim.label, report.provider)

        var usedPct = 0
        if (lim.amount) {
          if (lim.amount.used !== undefined) {
            usedPct = Number(lim.amount.used)
          } else if (lim.amount.usedFraction !== undefined) {
            usedPct = Number(lim.amount.usedFraction) * 100
          }
        }

        var isExhausted = (lim.status === "exhausted") || (usedPct >= 99.9) || (lim.amount && lim.amount.remainingFraction <= 0.001)

        totalMeteredCount++
        if (isExhausted) {
          exhaustedCount++
        }
        if (usedPct > maxUsed) {
          maxUsed = usedPct
        }

        var cachedToks = (root.tokensByPool && root.tokensByPool[poolName]) ? root.tokensByPool[poolName] : 0

        pools.push({
          name: poolName,
          provider: pName,
          windows: [{
            label: (lim.window && lim.window.label) ? lim.window.label.toUpperCase() : "DAILY",
            usedPercent: usedPct,
            resetsAt: lim.window ? lim.window.resetsAt : 0,
            isExhausted: isExhausted,
            isUnmetered: false,
            sessionTokens: cachedToks
          }]
        })
      }
    }

    // 2. Process configured accounts without usage (e.g. ZAI, OpenRouter, Copilot)
    var noUsageAccounts = data.accountsWithoutUsage || []
    for (var a = 0; a < noUsageAccounts.length; a++) {
      var acc = noUsageAccounts[a]
      var accProvider = (acc.provider || "PROVIDER").toUpperCase()
      if (acc.email && emails.indexOf(acc.email) < 0) emails.push(acc.email)

      var accCachedToks = (root.tokensByPool && root.tokensByPool[accProvider]) ? root.tokensByPool[accProvider] : 0

      pools.push({
        name: accProvider,
        provider: acc.provider,
        windows: [{
          label: "AVAILABLE",
          usedPercent: 0,
          resetsAt: 0,
          isExhausted: false,
          isUnmetered: true,
          sessionTokens: accCachedToks
        }]
      })
    }

    // 3. SORT: Least usage percentage on top (ascending)
    pools.sort(function(a, b) {
      var aWin = (a.windows && a.windows[0]) ? a.windows[0] : { usedPercent: 0, isUnmetered: false }
      var bWin = (b.windows && b.windows[0]) ? b.windows[0] : { usedPercent: 0, isUnmetered: false }

      // Unmetered accounts / lowest % first
      var aVal = aWin.isUnmetered ? -1 : aWin.usedPercent
      var bVal = bWin.isUnmetered ? -1 : bWin.usedPercent

      if (Math.abs(aVal - bVal) > 0.01) {
        return aVal - bVal
      }
      return a.name.localeCompare(b.name)
    })

    root.providerLabel = providerLabels.join(" + ") || "OMP Usage"
    root.accountEmail = emails.join(", ")
    root.quotaPools = pools
    root.maxUsedPercentage = maxUsed

    var hasUnmetered = noUsageAccounts.length > 0
    root.allExhausted = (totalMeteredCount > 0 && exhaustedCount >= totalMeteredCount && !hasUnmetered)
    root.anyExhausted = (exhaustedCount > 0)
    root.hasAvailable = (exhaustedCount < totalMeteredCount) || hasUnmetered
  }

  Component.onCompleted: {
    refresh()
  }
}
