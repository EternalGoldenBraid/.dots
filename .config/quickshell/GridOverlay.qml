import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// 2x5 workspace grid, shown while the Hyprland "grid" submap is active.
Scope {
    id: root

    property bool open: false
    readonly property int cols: 5
    readonly property int rows: 2
    readonly property int current: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 0

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "submap") root.open = event.data === "grid";
        }
    }

    function populated(id) {
        for (const ws of Hyprland.workspaces.values)
            if (ws.id === id) return true;
        return false;
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            visible: root.open && Hyprland.focusedMonitor && Hyprland.focusedMonitor.name === modelData.name
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "workspace-grid"
            color: "transparent"
            mask: Region {}
            implicitWidth: 560
            implicitHeight: 230
            anchors {}

            Rectangle {
                anchors.fill: parent
                radius: 16
                color: Qt.alpha(Theme.crust, 0.94)
                border.width: 2
                border.color: Theme.peach

                Grid {
                    anchors.centerIn: parent
                    columns: root.cols
                    spacing: 10

                    Repeater {
                        model: root.cols * root.rows
                        Rectangle {
                            required property int index
                            readonly property int wsId: index + 1
                            readonly property bool active: wsId === root.current
                            width: 94
                            height: 80
                            radius: 10
                            color: active ? Theme.peach : Theme.gradStart
                            opacity: active || root.populated(wsId) ? 1 : 0.4
                            border.width: 1
                            border.color: active ? Theme.peach : Theme.gradEnd

                            Text {
                                anchors.centerIn: parent
                                text: parent.wsId
                                color: parent.active ? Theme.crust : Theme.text
                                font.family: Theme.font
                                font.pixelSize: 26
                                font.bold: parent.active
                            }
                        }
                    }
                }
            }
        }
    }
}
