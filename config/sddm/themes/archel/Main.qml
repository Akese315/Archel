import QtQuick 2.15
import QtQuick.Controls 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#050816"

    property color accent: "#8ec5ff"
    property color panelColor: "#0f172a"
    property color textColor: "#f8fafc"

    Image {
        anchors.fill: parent
        source: "wallpapers/the-beautiful-world-bloom.png"
        fillMode: Image.PreserveAspectCrop
        opacity: 0.72
    }

    Rectangle {
        anchors.fill: parent
        color: "#050816"
        opacity: 0.45
    }

    Rectangle {
        anchors.centerIn: parent
        width: 420
        height: 420
        radius: 28
        color: "#0f172a"
        opacity: 0.6
        border.width: 1
        border.color: "#9ecbff"
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 210
        text: "ARCHEL"
        color: "#f8fafc"
        opacity: 0.7
        font.family: "Sans"
        font.pixelSize: 18
        font.weight: Font.DemiBold
        letterSpacing: 6
    }

    Clock {
        id: clock
        anchors.horizontalCenter: parent.horizontalCenter
        y: 260
        color: "#f8fafc"
        font.pixelSize: 62
        font.family: "Sans"
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 340
        text: Qt.formatDateTime(new Date(), "dddd d MMMM")
        color: "#dfe7ff"
        opacity: 0.8
        font.family: "Sans"
        font.pixelSize: 18
    }

    UserModel {
        id: userModel
        enabled: true
    }

    Login {
        id: login
        anchors.centerIn: parent
        width: 320
        height: 160
        usernameField: username
        passwordField: password
    }
}
