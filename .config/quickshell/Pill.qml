import QtQuick

Rectangle {
    id: pill

    property string label: ""
    property color fill: "#fab387"
    property color ink: "#11141d"
    property bool pulse: true
    signal clicked
    signal rightClicked

    implicitHeight: 24
    implicitWidth: text.implicitWidth + 36
    radius: height / 2
    color: fill

    SequentialAnimation on opacity {
        running: pill.pulse
        loops: Animation.Infinite
        NumberAnimation { to: 0.7; duration: 550; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1.0; duration: 550; easing.type: Easing.InOutSine }
    }

    Text {
        id: text
        anchors.centerIn: parent
        text: pill.label
        color: pill.ink
        font.bold: true
        font.pixelSize: 13
        font.letterSpacing: 1
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => mouse.button === Qt.RightButton ? pill.rightClicked() : pill.clicked()
    }
}
