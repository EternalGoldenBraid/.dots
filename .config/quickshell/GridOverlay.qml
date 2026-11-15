import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Workspace overview shown while the Hyprland "grid" submap is active.
// Workspaces are screen-sized cards on a 2x5 plane. A pinhole camera looks at
// the plane: t = 0 is "flown in" on the focused workspace, t = 1 is pulled back
// and tilted, with the camera following the focused card.
Scope {
    id: root

    property bool open: false
    property real t: 0
    readonly property int cols: 5
    readonly property int rows: 2
    readonly property int current: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    readonly property real overviewScale: 0.34
    readonly property real tiltDeg: 38
    readonly property real focalLength: 1.6

    Behavior on t { NumberAnimation { duration: 520; easing.type: Easing.InOutCubic } }

    onOpenChanged: t = open ? 1 : 0

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "submap") root.open = event.data === "grid";
        }
    }

    function windowsOn(id) {
        const out = [];
        for (const tl of Hyprland.toplevels.values)
            if (tl.workspace && tl.workspace.id === id) out.push(tl);
        return out;
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            visible: (root.open || root.t > 0.001)
                && Hyprland.focusedMonitor && Hyprland.focusedMonitor.name === modelData.name
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "workspace-grid"
            color: "transparent"
            mask: Region {}

            readonly property real sw: width
            readonly property real sh: height
            readonly property real gap: sw * 0.12
            readonly property real cellW: sw + gap
            readonly property real cellH: sh + gap
            readonly property int idx: Math.max(0, root.current - 1)
            property real camX: (idx % root.cols) * cellW + sw / 2
            property real camY: Math.floor(idx / root.cols) * cellH + sh / 2

            Behavior on camX { NumberAnimation { duration: 380; easing.type: Easing.InOutCubic } }
            Behavior on camY { NumberAnimation { duration: 380; easing.type: Easing.InOutCubic } }

            // screen = T(centre) * Persp * Rx(tilt) * Scale * T(-camera)
            function projection() {
                const s = 1 + (root.overviewScale - 1) * root.t;
                const a = root.tiltDeg * root.t * Math.PI / 180;
                const c = Math.cos(a), n = Math.sin(a);
                const d = root.focalLength * sw;
                const place = Qt.matrix4x4(1, 0, 0, sw / 2, 0, 1, 0, sh / 2, 0, 0, 1, 0, 0, 0, 0, 1);
                const persp = Qt.matrix4x4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, -1 / d, 1);
                const tilt = Qt.matrix4x4(1, 0, 0, 0, 0, c, -n, 0, 0, n, c, 0, 0, 0, 0, 1);
                const zoom = Qt.matrix4x4(s, 0, 0, 0, 0, s, 0, 0, 0, 0, s, 0, 0, 0, 0, 1);
                const look = Qt.matrix4x4(1, 0, 0, -camX, 0, 1, 0, -camY, 0, 0, 1, 0, 0, 0, 0, 1);
                return place.times(persp).times(tilt).times(zoom).times(look);
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.crust
                opacity: 0.93 * root.t
            }

            Item {
                id: plane
                width: root.cols * win.cellW
                height: root.rows * win.cellH
                transform: Matrix4x4 { matrix: win.projection() }

                Repeater {
                    model: root.cols * root.rows

                    Rectangle {
                        id: card
                        required property int index
                        readonly property int wsId: index + 1
                        readonly property bool active: wsId === root.current
                        readonly property var wins: root.windowsOn(wsId)

                        x: (index % root.cols) * win.cellW
                        y: Math.floor(index / root.cols) * win.cellH
                        width: win.sw
                        height: win.sh
                        radius: 24
                        color: active ? Qt.alpha(Theme.gradStart, 0.55) : Qt.alpha(Theme.base, 0.9)
                        opacity: active ? root.t : Math.min(1, root.t * 1.4)
                        border.width: active ? 10 : 4
                        border.color: active ? Theme.peach : Theme.gradEnd

                        Text {
                            anchors { left: parent.left; top: parent.top; margins: parent.height * 0.05 }
                            text: card.wsId
                            color: card.active ? Theme.peach : Theme.text
                            font.family: Theme.font
                            font.pixelSize: card.height * 0.28
                            font.bold: true
                        }

                        Column {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: parent.height * 0.05 }
                            spacing: card.height * 0.012
                            Repeater {
                                model: card.wins.slice(0, 5)
                                Text {
                                    required property var modelData
                                    width: parent.width
                                    elide: Text.ElideRight
                                    text: modelData.title
                                    color: Theme.text
                                    opacity: 0.85
                                    font.family: Theme.font
                                    font.pixelSize: card.height * 0.032
                                }
                            }
                            Text {
                                visible: card.wins.length === 0
                                text: "empty"
                                color: Theme.overlay1
                                font.family: Theme.font
                                font.pixelSize: card.height * 0.04
                            }
                        }
                    }
                }
            }
        }
    }
}
