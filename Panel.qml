import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui
import "./components"

Panel {
  id: root
  moduleName: "omp.usagebar"
  ipcTarget: "omp.usagebar"
  manageIpc: true

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  property double nowMs: Date.now()
  property bool paused: false

  Main {
    id: usage
    settings: root.settings
    panelOpen: root.opened
    isActive: activityDetector.active
    paused: root.paused
  }

  Activity {
    id: activityDetector
    paused: root.paused
  }

  Timer {
    interval: 30000
    running: root.opened && !root.paused
    repeat: true
    onTriggered: root.nowMs = Date.now()
  }

  // ═══════════════════════════════════════════
  // TOP BAR WIDGET BUTTON
  // ═══════════════════════════════════════════
  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    hasVisualContent: true
    active: usage.allExhausted && !root.paused
    fixedWidth: vertical ? -1 : (activityDetector.active && !root.paused ? (slotSize + Style.space(32)) : slotSize)

    Behavior on fixedWidth {
      NumberAnimation {
        duration: 250
        easing.type: Easing.OutCubic
      }
    }

    Item {
      id: iconRowContainer
      anchors.fill: parent
      clip: true

      // Robot Icon: slides left when active, centers when idle
      Item {
        id: robotContainer
        width: button.slotSize
        height: parent.height
        x: (activityDetector.active && !root.paused) ? 0 : Math.max(0, (parent.width - width) / 2)

        Behavior on x {
          NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
          }
        }

        Text {
          anchors.centerIn: parent
          text: "󱚣"
          font.family: button.fontFamily
          font.pixelSize: button.fontSize
          color: root.iconColor
          renderType: Text.NativeRendering

          Behavior on color {
            ColorAnimation { duration: 200 }
          }
        }
      }

      // Thinking Dots: comfortably positioned on the right of the robot icon using bar text color
      Item {
        id: dotsContainer
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: robotContainer.right
        anchors.leftMargin: Style.space(2)
        width: Style.space(26)
        height: parent.height
        opacity: (activityDetector.active && !root.paused) ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity {
          NumberAnimation {
            duration: 220
            easing.type: Easing.InOutQuad
          }
        }

        ActivityBars {
          anchors.centerIn: parent
          active: activityDetector.active && !root.paused
          dotColor: button.foreground
        }
      }
    }

    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) {
        usage.refresh()
      } else {
        root.toggle()
      }
    }
  }

  // ═══════════════════════════════════════════
  // ICON COLOR RESOLVER
  // ═══════════════════════════════════════════
  // - GREYISH (muted): When monitoring is paused by the user.
  // - RED (urgent): Only when ALL providers are expired/exhausted.
  // - YELLOW (warning): When at least one is expired, but others are still available.
  // - FOREGROUND (normal): When all providers are available and healthy.
  readonly property color iconColor: {
    if (root.paused) return Util.alpha(button.foreground, 0.38);
    if (usage.allExhausted) return Color.urgent;
    if (usage.anyExhausted || usage.maxUsedPercentage >= 80) return "#e5c07b";
    return button.foreground;
  }

  // ═══════════════════════════════════════════
  // POPUP KEYBOARD PANEL
  // ═══════════════════════════════════════════
  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(mainColumn.implicitHeight + Style.space(24), Style.space(560))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
    }

    BorderSurface {
      anchors.fill: parent
      color: Color.popups.background
      borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border)

      ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: Style.space(12)
        spacing: Style.space(12)

        // HEADER
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(10)

          Text {
            text: "󱚣"
            font.pixelSize: 18
            color: root.iconColor
          }

          ColumnLayout {
            spacing: 1
            Layout.fillWidth: true

            // Title line with inline working indicator
            RowLayout {
              spacing: Style.space(8)

              Text {
                text: "AI Usage"
                font.pixelSize: 14
                font.bold: true
                color: Color.popups.text
              }

              // Working indicator on the right of the title
              RowLayout {
                visible: activityDetector.active && !root.paused
                spacing: Style.space(5)

                ActivityBars {
                  active: true
                  dotColor: Color.accent
                }

                Text {
                  text: "Working..."
                  font.pixelSize: 10
                  font.italic: true
                  color: Color.accent
                }
              }

              // Paused badge
              Text {
                visible: root.paused
                text: "Paused"
                font.pixelSize: 10
                font.bold: true
                color: Util.alpha(Color.popups.text, 0.45)
              }
            }

            Text {
              text: usage.accountEmail ? (usage.providerLabel + " · " + usage.accountEmail) : usage.providerLabel
              font.pixelSize: 10
              color: Util.alpha(Color.popups.text, 0.6)
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
          }

          Text {
            text: "↻"
            font.pixelSize: 16
            color: refreshArea.containsMouse ? Color.accent : Util.alpha(Color.popups.text, 0.7)
            MouseArea {
              id: refreshArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: usage.refresh()
            }
          }
        }

        // ERROR BANNER (if any)
        ColumnLayout {
          visible: usage.hasError && !root.paused
          Layout.fillWidth: true
          spacing: 2

          Text {
            text: "⚠️ " + usage.errorMessage
            font.pixelSize: 10
            color: Color.urgent
            wrapMode: Text.Wrap
            Layout.fillWidth: true
          }
        }

        // QUOTA POOLS (Sorted least used first)
        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.space(10)

          Repeater {
            model: usage.quotaPools

            QuotaCard {
              Layout.fillWidth: true
              poolName: modelData.name
              quotaWindows: modelData.windows
              nowMs: root.nowMs
            }
          }
        }

        // TOKENS CONSUMPTION
        ColumnLayout {
          visible: usage.tokensList.length > 0 || usage.totalTokens > 0
          Layout.fillWidth: true
          spacing: Style.space(6)

          Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Util.alpha(Color.popups.text, 0.12)
          }

          Text {
            text: "TOKENS SINCE " + usage.todayDateStr + " 00:00"
            font.pixelSize: 10
            font.bold: true
            font.letterSpacing: 1
            color: Util.alpha(Color.popups.text, 0.5)
          }

          Repeater {
            model: usage.tokensList

            TokenRow {
              Layout.fillWidth: true
              label: modelData.label
              count: modelData.count
              isBold: false
            }
          }

          TokenRow {
            visible: usage.tokensList.length > 1
            Layout.fillWidth: true
            label: "TOTAL"
            count: usage.totalTokens
            isBold: true
          }
        }

        // FOOTER SEPARATOR
        Rectangle {
          Layout.fillWidth: true
          height: 1
          color: Util.alpha(Color.popups.text, 0.12)
        }

        // FOOTER ACTIONS ROW
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(6)

          // Left: Last updated timestamp
          Text {
            text: {
              if (usage.lastFetchedMs <= 0) return "Not updated yet"
              var d = new Date(usage.lastFetchedMs)
              var timeStr = Qt.formatTime(d, "HH:mm:ss")
              return "Last updated · " + timeStr + (root.paused ? " · paused" : (usage.isStale ? " · stale" : ""))
            }
            font.pixelSize: 9
            color: Util.alpha(Color.popups.text, 0.45)
            Layout.fillWidth: true
          }

          // Middle-Right: Pause / Resume Button
          PanelActionButton {
            iconText: root.paused ? "󰐥" : "󰏤"
            tooltipText: root.paused ? "Resume OMP monitoring" : "Pause OMP monitoring"
            hoverColor: root.paused ? Color.accent : Color.urgent
            foreground: root.paused ? Color.urgent : Util.alpha(Color.popups.text, 0.55)
            fontSize: 12
            size: Style.space(20)
            onClicked: root.paused = !root.paused
          }

          // Far-Right: Full OMP Stats & Graphs Dashboard Button
          PanelActionButton {
            iconText: ""
            tooltipText: "Open OMP stats & graphs dashboard"
            hoverColor: Color.accent
            foreground: Util.alpha(Color.popups.text, 0.55)
            fontSize: 12
            size: Style.space(20)
            onClicked: {
              Util.execDetached("bash ~/.config/omarchy/plugins/omp.usagebar/open-dashboard.sh")
              root.close()
            }
          }
        }
      }
    }
  }
}
