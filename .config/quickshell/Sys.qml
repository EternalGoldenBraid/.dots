pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Polled state: fast (agents, bypass, dictation) and slow (system stats).
Singleton {
    id: root

    property string agentState: "none"
    property string agentText: ""
    property bool bypass: false
    property string dictation: "idle"

    property int cpu: 0
    property int mem: 0
    property int temp: 0
    property int backlight: -1
    property var net: ({ kind: "none", name: "", signal: 0 })
    property string profile: "balanced"
    property bool shade: false
    property string submap: ""
    property string layout: ""
    property string note: "read"

    property var levels: []
    property string liveText: ""

    onDictationChanged: if (dictation === "idle") { levels = []; liveText = ""; }

    Process {
        id: mic
        running: root.dictation === "recording"
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/mic-levels.py"]
        stdout: SplitParser {
            onRead: data => {
                const next = root.levels.slice(-47);
                next.push(parseInt(data));
                root.levels = next;
            }
        }
    }

    // Live transcript hook: anything that writes this file shows up in the panel.
    FileView {
        path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/handy-live.txt"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.liveText = text().trim()
        onLoadFailed: root.liveText = ""
    }

    // Most urgent state, used to tint the whole bar.
    readonly property color tint: {
        if (agentState === "waiting") return Theme.waiting;
        if (agentState === "asking") return Theme.asking;
        if (dictation === "recording") return Theme.recording;
        if (dictation === "transcribing") return Theme.transcribing;
        if (bypass) return Theme.peach;
        return "transparent";
    }
    readonly property bool urgent: tint.a > 0

    Process {
        id: fast
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/status.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const s = JSON.parse(text);
                    root.agentState = s.agent.state;
                    root.agentText = s.agent.text;
                    root.bypass = s.bypass;
                    root.dictation = s.dictation;
                } catch (e) {
                    console.warn("status parse failed:", e);
                }
            }
        }
    }

    Process {
        id: slow
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/stats.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const s = JSON.parse(text);
                    root.cpu = s.cpu;
                    root.mem = s.mem;
                    root.temp = s.temp;
                    root.backlight = s.backlight;
                    root.net = s.net;
                    root.profile = s.profile;
                    root.shade = s.shade;
                    root.submap = s.submap;
                    root.layout = s.layout;
                    root.note = s.note;
                } catch (e) {
                    console.warn("stats parse failed:", e);
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!fast.running) fast.running = true
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!slow.running) slow.running = true
    }
}
