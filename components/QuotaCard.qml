import QtQuick
import QtQuick.Layouts
import qs.Commons

ColumnLayout {
  id: root
  property string poolName: ""
  property var quotaWindows: []
  property double nowMs: Date.now()

  spacing: Style.space(3)

  Repeater {
    model: root.quotaWindows

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.space(4)

      // Top Line: Provider/Model Name + Percentage / Status
      RowLayout {
        Layout.fillWidth: true

        Text {
          text: root.poolName
          font.pixelSize: 12
          font.bold: true
          color: Color.popups.text
          Layout.fillWidth: true
          elide: Text.ElideRight
        }

        Text {
          text: modelData.isUnmetered ? "Active" : (modelData.usedPercent.toFixed(1) + "%")
          font.pixelSize: 11
          font.bold: true
          color: {
            if (modelData.isUnmetered) return Color.accent
            if (modelData.usedPercent >= 90) return Color.urgent
            if (modelData.usedPercent >= 75) return "#e5c07b"
            return Color.popups.text
          }
          horizontalAlignment: Text.AlignRight
        }
      }

      // Full-width Progress Bar (for metered models)
      SeverityProgressBar {
        visible: !modelData.isUnmetered
        Layout.fillWidth: true
        percentage: modelData.usedPercent
      }

      // Subtitle Line: Window label + Reset countdown on left, Session tokens on right
      RowLayout {
        Layout.fillWidth: true

        Text {
          text: {
            if (modelData.isUnmetered) return "Unmetered · Available"
            var windowLabel = modelData.label ? (modelData.label.charAt(0) + modelData.label.slice(1).toLowerCase()) : "Daily"
            return windowLabel + " · " + root.formatResetCountdown(modelData.resetsAt)
          }
          font.pixelSize: 10
          color: Util.alpha(Color.popups.text, 0.5)
          Layout.fillWidth: true
        }

        Text {
          visible: !!modelData.sessionTokens && modelData.sessionTokens > 0
          text: root.formatBootTokens(modelData.sessionTokens)
          font.pixelSize: 10
          color: Util.alpha(Color.popups.text, 0.6)
          horizontalAlignment: Text.AlignRight
        }
      }
    }
  }

  function formatResetCountdown(resetsAt) {
    if (!resetsAt || resetsAt <= 0) return "resets soon"
    var diffMs = resetsAt - root.nowMs
    if (diffMs <= 0) return "resets momentarily"

    var diffMins = Math.floor(diffMs / 60000)
    var hours = Math.floor(diffMins / 60)
    var mins = diffMins % 60
    var days = Math.floor(hours / 24)
    hours = hours % 24

    if (days > 0) return "resets in " + days + "d " + hours + "h"
    if (hours > 0) return "resets in " + hours + "h " + mins + "m"
    return "resets in " + mins + "m"
  }

  function formatBootTokens(n) {
    if (!n || n <= 0) return "Tokens since boot : 0"
    if (n >= 1000000) {
      var m = n / 1000000
      return "Tokens since boot : " + (m >= 100 ? m.toFixed(0) : (m >= 10 ? m.toFixed(1) : m.toFixed(2))) + " M"
    }
    if (n >= 1000) {
      var k = n / 1000
      return "Tokens since boot : " + (k >= 100 ? k.toFixed(0) : (k >= 10 ? k.toFixed(1) : k.toFixed(1))) + " K"
    }
    return "Tokens since boot : " + n
  }
}
