import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Live map of the agent mesh: nodes are agent sessions coloured by state, edges
// are conversations from the last 24 h, pulses are messages as they arrive.
// The probe runs only while the panel is open.
Scope {
    id: root

    property bool open: false
    property var nodes: []
    property var edges: []
    property var pulses: []

    readonly property real flight: 1400
    readonly property real ripple: 700

    function toggle() { open = !open; }

    function stateColor(s) {
        return s === "working" ? Theme.transcribing
            : s === "waiting" ? Theme.waiting
            : s === "asking" ? Theme.asking
            : s === "idle" ? Theme.done
            : Theme.overlay1;
    }

    function send(from, to) {
        pulses = pulses.concat([{ from: from, to: to, t0: Date.now() }]);
    }

    onOpenChanged: if (!open) { nodes = []; edges = []; pulses = []; }

    IpcHandler {
        target: "mesh"
        function toggle(): void { root.toggle(); }
        function demo(): void {
            if (root.edges.length > 0) {
                const e = root.edges[Math.floor(Math.random() * root.edges.length)];
                root.send(e.from, e.to);
            }
        }
    }

    Process {
        running: root.open
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/mesh-probe.py"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    const d = JSON.parse(line);
                    root.nodes = d.nodes;
                    root.edges = d.edges;
                    d.msgs.forEach(m => root.send(m.from, m.to));
                } catch (e) {}
            }
        }
    }

    PanelWindow {
        id: win
        visible: root.open
        implicitWidth: 760
        implicitHeight: 560
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "agent-mesh"
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: Qt.alpha(Theme.crust, 0.95)
            border.width: 2
            border.color: Theme.peach

            Text {
                x: 20; y: 14
                text: "agent mesh  \u00b7  " + root.nodes.length + " active"
                color: Theme.peach
                font.family: Theme.font
                font.pixelSize: 14
                font.bold: true
            }

            Row {
                anchors { right: parent.right; top: parent.top; margins: 16 }
                spacing: 14
                Repeater {
                    model: ["working", "waiting", "asking", "idle", "active"]
                    Row {
                        required property string modelData
                        spacing: 5
                        Rectangle { width: 10; height: 10; radius: 5; color: root.stateColor(modelData); anchors.verticalCenter: parent.verticalCenter }
                        Text { text: modelData; color: Theme.text; opacity: 0.7; font.family: Theme.font; font.pixelSize: 11 }
                    }
                }
            }

            Canvas {
                id: canvas
                anchors { fill: parent; topMargin: 44 }

                FrameAnimation {
                    running: root.open
                    onTriggered: {
                        const now = Date.now();
                        root.pulses = root.pulses.filter(p => now - p.t0 < root.flight + root.ripple);
                        canvas.requestPaint();
                    }
                }

                function place() {
                    const order = root.nodes.slice().sort((a, b) =>
                        (a.machine + a.repo + a.id).localeCompare(b.machine + b.repo + b.id));
                    const cx = width / 2, cy = height / 2 - 6;
                    const r = Math.min(width * 0.36, height * 0.34);
                    const pos = {};
                    order.forEach((n, i) => {
                        const a = -Math.PI / 2 + i / order.length * 2 * Math.PI;
                        pos[n.id] = { x: cx + r * Math.cos(a), y: cy + r * Math.sin(a), n: n };
                    });
                    return pos;
                }

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const pos = place();
                    const now = Date.now();

                    root.edges.forEach(e => {
                        const a = pos[e.from], b = pos[e.to];
                        if (!a || !b) return;
                        ctx.strokeStyle = Qt.alpha(Theme.gradEnd, 0.15 + Math.min(e.n, 30) / 30 * 0.4);
                        ctx.lineWidth = 1 + Math.min(e.n, 30) / 10;
                        ctx.beginPath();
                        ctx.moveTo(a.x, a.y);
                        ctx.lineTo(b.x, b.y);
                        ctx.stroke();
                    });

                    root.pulses.forEach(p => {
                        const a = pos[p.from], b = pos[p.to];
                        if (!a || !b) return;
                        const age = now - p.t0;
                        if (age < root.flight) {
                            const k = age / root.flight;
                            const e = k < 0.5 ? 2 * k * k : 1 - Math.pow(-2 * k + 2, 2) / 2;
                            for (let i = 0; i < 6; i++) {
                                const kk = Math.max(0, e - i * 0.025);
                                ctx.fillStyle = Qt.alpha(Theme.peach, 1 - i / 6);
                                ctx.beginPath();
                                ctx.arc(a.x + (b.x - a.x) * kk, a.y + (b.y - a.y) * kk, 5 - i * 0.6, 0, 2 * Math.PI);
                                ctx.fill();
                            }
                        } else {
                            const k = (age - root.flight) / root.ripple;
                            ctx.strokeStyle = Qt.alpha(Theme.peach, 1 - k);
                            ctx.lineWidth = 2;
                            ctx.beginPath();
                            ctx.arc(b.x, b.y, 14 + k * 30, 0, 2 * Math.PI);
                            ctx.stroke();
                        }
                    });

                    ctx.textAlign = "center";
                    Object.keys(pos).forEach(id => {
                        const q = pos[id];
                        const col = root.stateColor(q.n.state);
                        const beat = q.n.state === "working" ? 1 + 0.12 * Math.sin(now / 250) : 1;
                        ctx.fillStyle = Qt.alpha(col, 0.22);
                        ctx.beginPath();
                        ctx.arc(q.x, q.y, 20 * beat, 0, 2 * Math.PI);
                        ctx.fill();
                        ctx.fillStyle = col;
                        ctx.beginPath();
                        ctx.arc(q.x, q.y, 11, 0, 2 * Math.PI);
                        ctx.fill();
                        ctx.fillStyle = Theme.text;
                        ctx.font = "12px '" + Theme.font + "'";
                        ctx.fillText(q.n.repo, q.x, q.y + 34);
                        ctx.fillStyle = Qt.alpha(Theme.text, 0.5);
                        ctx.font = "10px '" + Theme.font + "'";
                        ctx.fillText(q.n.machine, q.x, q.y + 47);
                    });
                }
            }

            MouseArea { anchors.fill: parent; onClicked: root.open = false }
        }
    }
}
