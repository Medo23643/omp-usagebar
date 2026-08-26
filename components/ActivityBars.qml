import QtQuick
import qs.Commons

// Three thinking dots that pulse with a wave ripple (opacity + slight scale).
// Horizontally centered with comfortable breathing room on all sides.
Item {
  id: root
  property bool active: true
  property color dotColor: Color.bar.text || Color.foreground

  implicitWidth: Style.space(22)
  implicitHeight: Style.space(14)

  Row {
    anchors.centerIn: parent
    spacing: Style.space(4)

    Repeater {
      model: 3

      Rectangle {
        id: dot
        width: Style.space(3.5)
        height: Style.space(3.5)
        radius: width / 2
        color: root.dotColor
        opacity: 0.25
        scale: 0.85
        anchors.verticalCenter: parent.verticalCenter

        SequentialAnimation {
          running: root.active
          loops: Animation.Infinite

          PauseAnimation { duration: index * 180 }

          ParallelAnimation {
            NumberAnimation {
              target: dot
              property: "opacity"
              from: 0.25
              to: 1.0
              duration: 350
              easing.type: Easing.InOutSine
            }
            NumberAnimation {
              target: dot
              property: "scale"
              from: 0.85
              to: 1.25
              duration: 350
              easing.type: Easing.InOutSine
            }
          }

          ParallelAnimation {
            NumberAnimation {
              target: dot
              property: "opacity"
              from: 1.0
              to: 0.25
              duration: 350
              easing.type: Easing.InOutSine
            }
            NumberAnimation {
              target: dot
              property: "scale"
              from: 1.25
              to: 0.85
              duration: 350
              easing.type: Easing.InOutSine
            }
          }

          PauseAnimation { duration: (2 - index) * 180 }
        }
      }
    }
  }
}
