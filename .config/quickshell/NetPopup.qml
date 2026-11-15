import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Network popup: path graph (you -> gateway -> internet), latency sparklines
// and the neighbour table. The probe runs only while the popup is open.
PopupWindow {
    id: pop

    property Item target
    property var gw: []
    property var inet: []
    property var info: ({ gwip: "", dev: "", neigh: [] })
    readonly property int keep: 60

    function toggle() {
        if (!visible) { gw = []; inet = []; }
        visible = !visible;
    }

    function push(arr, v) {
        const next = arr.slice(-(keep - 1));
        next.push(v);
        return next;
    }

    function health(ms) {
        if (ms === null || ms === undefined) return Theme.waiting;
        return ms < 80 ? Theme.done : ms < 200 ? Theme.peach : Theme.waiting;
    }

    function last(arr) { return arr.length ? arr[arr.length - 1] : null; }

    anchor.window: bar
    anchor.rect.x: target ? target.mapToItem(null, 0, 0).x + target.width - width : 0
    anchor.rect.y: bar.height + 4
    anchor.adjustment: PopupAdjustment.Slide
    implicitWidth: 380
    implicitHeight: body.implicitHeight + 24
    visible: false
    color: "transparent"

    HyprlandFocusGrab {
        windows: [pop]
        active: pop.visible
        onCleared: pop.visible = false
    }

    Process {
        running: pop.visible
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/net-probe.sh"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    const d = JSON.parse(line);
                    pop.info = d;
                    pop.gw = pop.push(pop.gw, d.gw);
                    pop.inet = pop.push(pop.inet, d.inet);
                } catch (e) {}
            }
        }
    }

    component Spark: Canvas {
        id: spark
        property var series: []
        property color tint: Theme.peach
        width: parent.width
        height: 44
        onSeriesChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const vals = series.filter(v => v !== null);
            const top = Math.max(50, ...vals) * 1.1;
            const dx = width / (pop.keep - 1);
            const x0 = width - (series.length - 1) * dx;
            ctx.lineWidth = 2;
            ctx.strokeStyle = tint;
            ctx.beginPath();
            let pen = false;
            series.forEach((v, i) => {
                if (v === null) { pen = false; return; }
                const y = height - 3 - v / top * (height - 6);
                if (pen) ctx.lineTo(x0 + i * dx, y); else ctx.moveTo(x0 + i * dx, y);
                pen = true;
            });
            ctx.stroke();
            ctx.fillStyle = Theme.waiting;
            series.forEach((v, i) => { if (v === null) ctx.fillRect(x0 + i * dx - 1, 0, 2, height); });
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Qt.alpha(Theme.crust, 0.96)
        border.width: 2
        border.color: Theme.peach

        Column {
            id: body
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            spacing: 10

            Text {
                text: (Sys.net.name !== "" ? Sys.net.name : Sys.net.kind) + "  " + pop.info.dev
                color: Theme.peach
                font.family: Theme.font
                font.pixelSize: 14
                font.bold: true
            }

            Item {
                width: parent.width
                height: 62

                Repeater {
                    model: [
                        { label: "you", x: 0.12, ms: 0 },
                        { label: pop.info.gwip || "gateway", x: 0.5, ms: pop.last(pop.gw) },
                        { label: "1.1.1.1", x: 0.88, ms: pop.last(pop.inet) }
                    ]
                    Item {
                        required property var modelData
                        required property int index
                        x: parent.width * modelData.x
                        y: 0
                        Rectangle {
                            x: -9
                            width: 18
                            height: 18
                            radius: 9
                            color: index === 0 ? Theme.gradEnd : pop.health(modelData.ms)
                        }
                        Text {
                            x: -width / 2
                            y: 24
                            text: modelData.label
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: 11
                        }
                        Text {
                            x: -width / 2
                            y: 40
                            visible: index > 0
                            text: modelData.ms === null ? "lost" : modelData.ms.toFixed(1) + " ms"
                            color: pop.health(modelData.ms)
                            font.family: Theme.font
                            font.pixelSize: 11
                        }
                    }
                }

                Rectangle { x: parent.width * 0.12 + 9; y: 8; width: parent.width * 0.38 - 18; height: 2; color: pop.health(pop.last(pop.gw)) }
                Rectangle { x: parent.width * 0.5 + 9; y: 8; width: parent.width * 0.38 - 18; height: 2; color: pop.health(pop.last(pop.inet)) }
            }

            Text { text: "gateway"; color: Theme.textRight; opacity: 0.55; font.family: Theme.font; font.pixelSize: 11 }
            Spark { series: pop.gw; tint: pop.health(pop.last(pop.gw)) }
            Text { text: "internet"; color: Theme.textRight; opacity: 0.55; font.family: Theme.font; font.pixelSize: 11 }
            Spark { series: pop.inet; tint: pop.health(pop.last(pop.inet)) }

            Text { text: "neighbours"; color: Theme.textRight; opacity: 0.55; font.family: Theme.font; font.pixelSize: 11 }
            Repeater {
                model: pop.info.neigh
                Text {
                    required property var modelData
                    text: modelData.ip + "  " + modelData.mac + "  " + modelData.state
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 11
                }
            }

            Rectangle {
                width: parent.width
                height: 28
                radius: 6
                color: Theme.gradStart
                Text {
                    anchors.centerIn: parent
                    text: "nmtui"
                    color: Theme.textLeft
                    font.family: Theme.font
                    font.pixelSize: 13
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: { pop.visible = false; Quickshell.execDetached(["kitty", "nmtui"]); }
                }
            }
        }
    }
}
