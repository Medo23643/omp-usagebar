import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property bool active: false
  property bool paused: false
  property string currentModel: ""

  onPausedChanged: {
    if (paused) {
      active = false
    }
  }

  Timer {
    interval: 1200
    running: !root.paused
    repeat: true
    onTriggered: {
      if (!root.paused && !pgrepProcess.running) {
        pgrepProcess.running = true
      }
    }
  }

  // Detects active AI prompt generation/thinking/streaming in real-time.
  // When omp is sitting idle at the prompt waiting for user input, active remains false.
  Process {
    id: pgrepProcess
    command: [
      "sh", "-c",
      "if ps -e -o pid,args | grep -E '(/|\\s|^)omp(\\s|$)' | grep -v -E '((/|\\s|^)omp\\s+(stats|usage|models|completions|config|plugin|install|update|gc)|omp\\.usagebar|open-dashboard\\.sh|timeout\\s+[0-9]+\\s+omp|grep)' >/dev/null 2>&1; then recent=$(find ~/.omp/agent/sessions -name '*.jsonl' -newermt '-4 seconds' 2>/dev/null | head -1); if [ -n \"$recent\" ]; then echo '1'; fi; fi"
    ]
    running: false

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (root.paused) {
          root.active = false
          return
        }
        var res = this.text.trim()
        root.active = (res === "1")
      }
    }
  }
}
