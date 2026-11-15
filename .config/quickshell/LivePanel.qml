import QtQuick
import Quickshell
import Quickshell.Wayland

// Floating dictation panel: live waveform from the mic and, when available,
// the live transcript text. Click-through except for the panel itself.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            visible: Sys.dictation !== "idle"
            anchors { top: true }
            margins.top: 40
            implicitWidth: 640
            implicitHeight: panel.height
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "dictation-panel"
            color: "transparent"
            mask: Region { item: panel }

            readonly property bool recording: Sys.dictation === "recording"
            readonly property color accent: recording ? Theme.recording : Theme.transcribing

            Rectangle {
                id: panel
                width: parent.width
                height: col.implicitHeight + 24
                radius: 14
                color: Qt.alpha(Theme.crust, 0.94)
                border.width: 2
                border.color: win.accent

                Column {
                    id: col
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                    spacing: 10

                    Row {
                        id: wave
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: 36
                        spacing: 3

                        Repeater {
                            model: Sys.levels.length > 0 ? Sys.levels : new Array(48).fill(0)
                            Item {
                                required property var modelData
                                width: 6
                                height: wave.height
                                Rectangle {
                                    width: parent.width
                                    height: Math.max(3, modelData / 100 * wave.height)
                                    anchors.verticalCenter: parent.verticalCenter
                                    radius: 3
                                    color: win.accent
                                    opacity: win.recording ? 1 : 0.35
                                    Behavior on height { NumberAnimation { duration: 60 } }
                                }
                            }
                        }
                    }

                    Text {
                        visible: Sys.liveText !== "" || !win.recording
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideLeft
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 15
                        text: Sys.liveText !== "" ? Sys.liveText : (win.recording ? "" : "transcribing\u2026")
                    }
                }
            }
        }
    }
}
