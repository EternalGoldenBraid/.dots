import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Widgets

PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    implicitHeight: 34
    color: "transparent"

    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var battery: UPower.displayDevice
    readonly property real batteryPct: battery && battery.ready
        ? (battery.percentage <= 1 ? battery.percentage * 100 : battery.percentage) : -1
    readonly property bool charging: battery && battery.state === UPowerDeviceState.Charging
    readonly property string home: Quickshell.env("HOME")

    PwObjectTracker { objects: [bar.sink, bar.source] }

    Calendar { id: calendar; target: clockModule }

    IpcHandler {
        target: "calendar-" + bar.screen.name
        function toggle(): void { calendar.toggle(); }
    }

    function run(cmd) { Quickshell.execDetached(cmd); }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.alpha(Theme.gradStart, 0.94) }
            GradientStop { position: 1; color: Qt.alpha(Theme.gradEnd, 0.94) }
        }

        Rectangle { anchors.fill: parent; color: Theme.crust; opacity: 0.2 }

        // Whole-bar tint for the most urgent state.
        Rectangle {
            anchors.fill: parent
            color: Sys.tint
            opacity: 0
            Behavior on color { ColorAnimation { duration: 250 } }

            SequentialAnimation on opacity {
                running: Sys.urgent
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 900; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.6; duration: 900; easing.type: Easing.InOutSine }
            }
        }

        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 2
            color: Theme.peach
        }
    }

    Row {
        id: left
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        height: 30

        Repeater {
            model: Hyprland.workspaces.values
                .filter(w => w.monitor === bar.monitor && w.id > 0)
                .sort((a, b) => a.id - b.id)

            Item {
                required property var modelData
                width: num.implicitWidth + 22
                height: 30

                Rectangle {
                    anchors.fill: parent
                    color: Theme.crust
                    opacity: modelData.focused ? 0.35 : 0
                }
                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: 2
                    color: Theme.textLeft
                    visible: modelData.focused
                }
                Text {
                    id: num
                    anchors.centerIn: parent
                    text: modelData.id
                    color: Theme.textLeft
                    opacity: modelData.focused ? 1 : 0.82
                    font.family: Theme.font
                    font.pixelSize: 13
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: Hyprland.dispatch("workspace " + modelData.id)
                }
            }
        }

        Module {
            text: Sys.submap !== "" ? "\uf0e7 " + Sys.submap : ""
            color: Theme.peach
            onClicked: bar.run(["hyprctl", "dispatch", "submap", "reset"])
        }
    }

    Row {
        id: center
        anchors { left: left.right; leftMargin: 24; verticalCenter: parent.verticalCenter }
        spacing: 10

        Pill {
            visible: Sys.agentState !== "none"
            label: Sys.agentText
            fill: Sys.agentState === "waiting" ? Theme.waiting
                : Sys.agentState === "asking" ? Theme.asking
                : Sys.agentState === "idle" ? Theme.done : Theme.overlay1
            ink: Theme.crust
            pulse: Sys.agentState === "waiting" || Sys.agentState === "asking"
            anchors.verticalCenter: parent.verticalCenter
            onClicked: bar.run([bar.home + "/.local/bin/agent-notify", "focus"])
        }
        Pill {
            visible: Sys.bypass
            label: "NO LOCK / SLEEP"
            fill: Theme.peach
            anchors.verticalCenter: parent.verticalCenter
            onClicked: bar.run([bar.home + "/.dotfiles/bin/hypridle-bypass-toggle"])
        }
        Pill {
            visible: Sys.dictation !== "idle"
            label: Sys.dictation === "recording" ? "LIVE DICTATION" : "TRANSCRIBING"
            fill: Sys.dictation === "recording" ? Theme.recording : Theme.transcribing
            ink: Sys.dictation === "recording" ? Theme.recordingText : Theme.transcribingText
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            id: title
            // Whatever room is left between the pills and the right-hand modules.
            readonly property real used: center.children.reduce(
                (w, c) => c === title || !c.visible ? w : w + c.width + center.spacing, 0)
            width: Math.max(0, Math.min(implicitWidth, right.x - center.x - used - 24))
            anchors.verticalCenter: parent.verticalCenter
            text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
            elide: Text.ElideRight
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 13
        }
    }

    Row {
        id: right
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        height: 30

        Module {
            text: Sys.bypass ? "\uf06e" : "\uf070"
            onClicked: bar.run([bar.home + "/.dotfiles/bin/hypridle-bypass-toggle"])
        }
        Module {
            readonly property real vol: bar.sink && bar.sink.audio ? bar.sink.audio.volume : 0
            readonly property bool muted: bar.sink && bar.sink.audio ? bar.sink.audio.muted : true
            readonly property bool micMuted: bar.source && bar.source.audio ? bar.source.audio.muted : true
            text: (muted ? "\uf026" : Math.round(vol * 100) + "% \uf028") + "  " + (micMuted ? "\uf131" : "\uf130")
            onClicked: mouse => mouse.button === Qt.RightButton
                ? (bar.source.audio.muted = !bar.source.audio.muted)
                : bar.run(["pavucontrol"])
            onScrolled: d => bar.sink.audio.volume = Math.max(0, Math.min(1.5, bar.sink.audio.volume + d * 0.05))
        }
        Module {
            text: Sys.net.kind === "wifi" ? Sys.net.name + " (" + Sys.net.signal + "%) \uf1eb"
                : Sys.net.kind === "ethernet" ? "\uf796" : "Disconnected \u26a0"
        }
        Module { text: Sys.profile === "performance" ? "\uf0e7" : Sys.profile === "power-saver" ? "\uf06c" : "\uf24e" }
        Module { text: Sys.cpu + "% \uf2db" }
        Module { text: Sys.mem + "% \uf233" }
        Module {
            text: Sys.temp + "\u00b0C \uf2c9"
            color: Sys.temp >= 80 ? Theme.waiting : Theme.textRight
        }
        Module { text: Sys.backlight >= 0 ? Sys.backlight + "% \uf185" : "" }
        Module {
            text: "\uf186"
            color: Sys.shade ? Theme.peach : Theme.overlay1
            onClicked: bar.run(["hyprshade", "toggle"])
        }
        Module { text: Sys.layout !== "" ? Sys.layout.replace("English (US)", "us") : "" }
        Module {
            text: bar.batteryPct >= 0 ? Math.round(bar.batteryPct) + "% " + (bar.charging ? "\uf0e7" : "\uf240") : ""
            color: bar.batteryPct >= 0 && bar.batteryPct < 15 && !bar.charging ? Theme.waiting : Theme.textRight
        }
        Module {
            text: Sys.note === "unread" ? "NOTE" : "note"
            bold: Sys.note === "unread"
            color: Sys.note === "unread" ? Theme.peach : Qt.rgba(0.96, 0.98, 1, 0.6)
            onClicked: mouse => bar.run([bar.home + "/.config/waybar/scripts/daily-note.sh",
                mouse.button === Qt.RightButton ? "mark-unread" : "open"])
        }
        Module {
            id: clockModule
            text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")
            onClicked: calendar.toggle()
            SystemClock { id: clock; precision: SystemClock.Minutes }
        }

        Row {
            height: 30
            spacing: 4
            leftPadding: 6
            Repeater {
                model: SystemTray.items
                Item {
                    id: trayItem
                    required property var modelData
                    width: 20
                    height: 30
                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 16
                        source: trayItem.modelData.icon
                    }
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.LeftButton) trayItem.modelData.activate();
                            else if (mouse.button === Qt.MiddleButton) trayItem.modelData.secondaryActivate();
                            else if (trayItem.modelData.hasMenu) menu.open();
                        }
                    }
                    QsMenuAnchor {
                        id: menu
                        menu: trayItem.modelData.menu
                        anchor.window: bar
                        anchor.rect.x: trayItem.mapToItem(null, 0, 0).x
                        anchor.rect.y: bar.height
                        anchor.rect.width: trayItem.width
                    }
                }
            }
        }

        Module { text: "\uf011" }
    }
}
