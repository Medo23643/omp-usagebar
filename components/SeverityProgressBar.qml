import QtQuick
import qs.Commons

Item {
  id: root
  property real percentage: 0.0   // 0 to 100
  property color trackColor: Util.alpha(Color.popups.text, 0.12)

  implicitWidth: 120
  implicitHeight: 6

  Rectangle {
    anchors.fill: parent
    radius: height / 2
    color: root.trackColor

    Rectangle {
      id: bar
      height: parent.height
      radius: height / 2
      width: Math.min(parent.width, Math.max(0, parent.width * (root.percentage / 100.0)))
      color: root.severityColor(root.percentage)

      Behavior on width {
        NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
      }
    }
  }

  function severityColor(pct) {
    if (pct >= 90) return Color.urgent
    if (pct >= 75) return Qt.lighter(Color.urgent, 1.25)
    if (pct >= 50) return Qt.darker(Color.accent, 1.2)
    return Color.accent
  }
}
