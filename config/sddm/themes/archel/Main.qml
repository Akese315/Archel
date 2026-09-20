import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#050816"

    // Couleurs : theme.conf en priorité, valeurs par défaut sinon
    property color accent: config.accent || "#8ec5ff"
    property color panelColor: config.panel || "#0f172a"
    property color textColor: config.text || "#f8fafc"
    property real panelAlpha: parseFloat(config.panelAlpha || "0.58")
    property date now: new Date()

    function doLogin() {
        errorText.text = ""
        sddm.login(userField.text, passField.text, sessionBox.currentIndex)
    }

    // --- Fond ---------------------------------------------------------
    Image {
        anchors.fill: parent
        source: config.background || "wallpapers/the-beautiful-world-bloom.png"
        fillMode: Image.PreserveAspectCrop
        opacity: 0.72
    }

    Rectangle {
        anchors.fill: parent
        color: "#050816"
        opacity: 0.45
    }

    // --- Panneau ------------------------------------------------------
    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: 420
        height: 500
        radius: 28
        color: Qt.rgba(root.panelColor.r, root.panelColor.g, root.panelColor.b, root.panelAlpha)
        border.width: 1
        border.color: "#9ecbff"
    }

    Column {
        anchors.centerIn: panel
        width: 320
        spacing: 14

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "ARCHEL"
            color: root.textColor
            opacity: 0.7
            font.pixelSize: 18
            font.weight: Font.DemiBold
            font.letterSpacing: 6
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(root.now, "hh:mm")
            color: root.textColor
            font.pixelSize: 62
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(root.now, "dddd d MMMM")
            color: "#dfe7ff"
            opacity: 0.8
            font.pixelSize: 18
        }

        // Nom d'utilisateur
        Rectangle {
            width: parent.width
            height: 44
            radius: 12
            color: "#1e293b"
            border.width: 1
            border.color: userField.activeFocus ? root.accent : "#334155"

            TextInput {
                id: userField
                anchors.fill: parent
                anchors.margins: 12
                verticalAlignment: TextInput.AlignVCenter
                color: root.textColor
                font.pixelSize: 16
                clip: true
                text: userModel.lastUser
                KeyNavigation.tab: passField
                onAccepted: passField.forceActiveFocus()
            }
            Text {
                visible: userField.text.length === 0
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "Utilisateur"
                color: root.textColor
                opacity: 0.4
                font.pixelSize: 16
            }
        }

        // Mot de passe
        Rectangle {
            width: parent.width
            height: 44
            radius: 12
            color: "#1e293b"
            border.width: 1
            border.color: passField.activeFocus ? root.accent : "#334155"

            TextInput {
                id: passField
                anchors.fill: parent
                anchors.margins: 12
                verticalAlignment: TextInput.AlignVCenter
                color: root.textColor
                font.pixelSize: 16
                clip: true
                echoMode: TextInput.Password
                passwordCharacter: "•"
                KeyNavigation.tab: sessionBox
                onAccepted: root.doLogin()
            }
            Text {
                visible: passField.text.length === 0
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "Mot de passe"
                color: root.textColor
                opacity: 0.4
                font.pixelSize: 16
            }
        }

        // Session (Hyprland, etc.)
        ComboBox {
            id: sessionBox
            width: parent.width
            height: 40
            model: sessionModel
            textRole: "name"
            currentIndex: sessionModel.lastIndex
        }

        // Bouton de connexion
        Rectangle {
            width: parent.width
            height: 46
            radius: 12
            color: loginArea.pressed ? Qt.darker(root.accent, 1.3) : root.accent

            Text {
                anchors.centerIn: parent
                text: "Se connecter"
                color: "#0b1220"
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }
            MouseArea {
                id: loginArea
                anchors.fill: parent
                onClicked: root.doLogin()
            }
        }

        Text {
            id: errorText
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#fca5a5"
            font.pixelSize: 14
            text: ""
        }
    }

    // --- Redémarrer / Éteindre ---------------------------------------
    Row {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 24
        spacing: 24

        Text {
            text: "Redémarrer"
            color: root.textColor
            opacity: 0.7
            font.pixelSize: 15
            MouseArea { anchors.fill: parent; onClicked: sddm.reboot() }
        }
        Text {
            text: "Éteindre"
            color: root.textColor
            opacity: 0.7
            font.pixelSize: 15
            MouseArea { anchors.fill: parent; onClicked: sddm.powerOff() }
        }
    }

    // --- Comportement -------------------------------------------------
    Connections {
        target: sddm
        function onLoginFailed() {
            errorText.text = "Identifiant ou mot de passe incorrect"
            passField.text = ""
            passField.forceActiveFocus()
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Component.onCompleted: {
        if (userField.text.length > 0)
            passField.forceActiveFocus()
        else
            userField.forceActiveFocus()
    }
}
