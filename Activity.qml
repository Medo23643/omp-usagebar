import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property bool active: false
  property string currentModel: ""

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: {
      if (!pgrepProcess.running) {
        pgrepProcess.running = true
      }
    }
  }

  // Use a shell command with word-boundary matching so we only detect the
  // actual `omp` binary running a prompt/chat/run subcommand — not random
  // processes whose command lines happen to contain "omp" as a substring
  // (e.g. gnome-keyring-daemon → kcompactd).
  Process {
    id: pgrepProcess
    command: ["sh", "-c", "pgrep -x omp 2>/dev/null"]
    running: false

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var pids = this.text.trim()
        root.active = (pids.length > 0)
      }
    }
  }
}
