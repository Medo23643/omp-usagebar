import QtQuick
import QtQuick.Layouts
import qs.Commons

RowLayout {
  id: root
  property string label: ""
  property int count: 0
  property bool isBold: false

  Layout.fillWidth: true

  Text {
    text: root.label
    font.pixelSize: 11
    font.bold: root.isBold
    color: root.isBold ? Color.popups.text : Util.alpha(Color.popups.text, 0.8)
  }

  Item { Layout.fillWidth: true }

  Text {
    text: root.formatTokens(root.count)
    font.pixelSize: 11
    font.bold: root.isBold
    color: root.isBold ? Color.accent : Color.popups.text
    horizontalAlignment: Text.AlignRight
  }

  function formatTokens(n) {
    if (!n || n <= 0) return "0"
    if (n >= 1000000) {
      var m = n / 1000000
      return (m >= 100 ? m.toFixed(0) : (m >= 10 ? m.toFixed(1) : m.toFixed(2))) + "M"
    }
    if (n >= 1000) {
      var k = n / 1000
      return (k >= 100 ? k.toFixed(0) : (k >= 10 ? k.toFixed(1) : k.toFixed(1))) + "K"
    }
    return n.toLocaleString()
  }
}
