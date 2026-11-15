import QtQuick
import Quickshell
import Quickshell.Hyprland

// Month popup anchored under a bar item. Monday-first with ISO week numbers.
PopupWindow {
    id: cal

    property Item target
    property date today: new Date()
    property int year: today.getFullYear()
    property int month: today.getMonth()

    function toggle() {
        if (!visible) {
            today = new Date();
            year = today.getFullYear();
            month = today.getMonth();
        }
        visible = !visible;
    }

    function shift(n) {
        const d = new Date(year, month + n, 1);
        year = d.getFullYear();
        month = d.getMonth();
    }

    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        const day = t.getUTCDay() || 7;
        t.setUTCDate(t.getUTCDate() + 4 - day);
        const start = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
        return Math.ceil(((t - start) / 86400000 + 1) / 7);
    }

    readonly property int offset: (new Date(year, month, 1).getDay() + 6) % 7

    anchor.window: bar
    anchor.rect.x: target ? target.mapToItem(null, 0, 0).x + target.width - width : 0
    anchor.rect.y: bar.height + 4
    anchor.adjustment: PopupAdjustment.Slide
    implicitWidth: 300
    implicitHeight: body.implicitHeight + 24
    visible: false
    color: "transparent"

    HyprlandFocusGrab {
        windows: [cal]
        active: cal.visible
        onCleared: cal.visible = false
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
            spacing: 6

            Item {
                width: parent.width
                height: 28

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf053"
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 14
                    MouseArea { anchors { fill: parent; margins: -8 } onClicked: cal.shift(-1) }
                }
                Text {
                    anchors.centerIn: parent
                    text: Qt.formatDate(new Date(cal.year, cal.month, 1), "MMMM yyyy")
                    color: Theme.peach
                    font.family: Theme.font
                    font.pixelSize: 14
                    font.bold: true
                    MouseArea {
                        anchors { fill: parent; margins: -4 }
                        onClicked: { cal.year = cal.today.getFullYear(); cal.month = cal.today.getMonth(); }
                    }
                }
                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf054"
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 14
                    MouseArea { anchors { fill: parent; margins: -8 } onClicked: cal.shift(1) }
                }
            }

            Grid {
                columns: 8
                columnSpacing: 0
                rowSpacing: 2
                width: parent.width

                Repeater {
                    model: ["wk", "Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                    Text {
                        required property string modelData
                        width: body.width / 8
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: Theme.textRight
                        opacity: 0.55
                        font.family: Theme.font
                        font.pixelSize: 11
                    }
                }

                Repeater {
                    model: 48
                    Item {
                        id: cell
                        required property int index
                        readonly property int row: Math.floor(index / 8)
                        readonly property int col: index % 8
                        readonly property date day: new Date(cal.year, cal.month, 1 - cal.offset + row * 7 + col - 1)
                        readonly property bool isToday: col > 0 && day.toDateString() === cal.today.toDateString()
                        readonly property bool inMonth: day.getMonth() === cal.month

                        width: body.width / 8
                        height: 28

                        Rectangle {
                            anchors.centerIn: parent
                            width: 26
                            height: 26
                            radius: 13
                            visible: cell.isToday
                            color: Theme.peach
                        }
                        Text {
                            anchors.centerIn: parent
                            text: cell.col === 0
                                ? cal.isoWeek(new Date(cal.year, cal.month, 1 - cal.offset + cell.row * 7))
                                : cell.day.getDate()
                            color: cell.isToday ? Theme.crust : Theme.text
                            opacity: cell.col === 0 ? 0.4 : (cell.inMonth ? 1 : 0.3)
                            font.family: Theme.font
                            font.pixelSize: 13
                            font.bold: cell.isToday
                        }
                    }
                }
            }
        }
    }
}
