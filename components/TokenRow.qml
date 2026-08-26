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
    text: root.count.toLocaleString()
    font.pixelSize: 11
    font.bold: root.isBold
    color: root.isBold ? Color.accent : Color.popups.text
    horizontalAlignment: Text.AlignRight
  }
}
