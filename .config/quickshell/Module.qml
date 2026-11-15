import QtQuick

// Plain bar text item with optional click/scroll handlers.
Item {
    id: mod

    property string text: ""
    property color color: Theme.textRight
    property bool bold: false
    property real fontSize: 13
    signal clicked(var mouse)
    signal scrolled(int delta)

    implicitWidth: label.implicitWidth + 16
    implicitHeight: 30
    visible: text !== ""

    Text {
        id: label
        anchors.centerIn: parent
        text: mod.text
        color: mod.color
        font.family: Theme.font
        font.pixelSize: mod.fontSize
        font.bold: mod.bold
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => mod.clicked(mouse)
        onWheel: wheel => mod.scrolled(wheel.angleDelta.y > 0 ? 1 : -1)
    }
}
