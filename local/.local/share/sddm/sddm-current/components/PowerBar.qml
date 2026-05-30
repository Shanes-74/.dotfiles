import QtQuick 2.15

Row {
    id: powerBarRoot
    spacing: Math.round(16 * dp) // Spacing um pouco maior para respiro
    height: Math.round(36 * dp)

    property color textColor: "white"
    property real dp: 1.0

    // Bateria
    Row {
        spacing: Math.round(6 * dp)
        visible: typeof battery !== "undefined" && battery.percent !== undefined
        anchors.verticalCenter: parent.verticalCenter

        Text {
            text: (typeof battery !== "undefined" ? battery.percent : "0") + "%"
            color: textColor
            font.pixelSize: Math.round(14 * dp)
            font.family: config.fontFamily
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
        }
        
        Text {
            // Ícones Nerd Font para bateria (Carga vs Normal)
            text: (typeof battery !== "undefined" && battery.charging) ? "󱐋" : "󰁹"
            color: textColor
            font.pixelSize: Math.round(18 * dp)
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // Layout de Teclado (Apenas se houver mais de um)
    Text {
        text: (typeof keyboard !== "undefined" && keyboard.layouts.length > 0)
              ? keyboard.layouts[keyboard.currentLayout].shortName : "US"
        color: textColor
        font.pixelSize: Math.round(14 * dp)
        font.family: config.fontFamily
        font.weight: Font.Bold
        font.capitalization: Font.AllUppercase
        visible: typeof keyboard !== "undefined" && keyboard.layouts.length > 1
        anchors.verticalCenter: parent.verticalCenter
        
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
        }
    }

    // Botão Suspender
    Rectangle {
        id: suspendBtn
        anchors.verticalCenter: parent.verticalCenter
        width: Math.round(32 * dp)
        height: Math.round(32 * dp)
        radius: width / 2
        color: suspendHover.containsMouse ? Qt.rgba(textColor.r, textColor.g, textColor.b, 0.15) : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: "󰤄" // Moon icon
            color: textColor
            font.pixelSize: Math.round(18 * dp)
        }

        MouseArea {
            id: suspendHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: sddm.suspend()
        }
    }

    // Botão Reiniciar
    Rectangle {
        id: rebootBtn
        anchors.verticalCenter: parent.verticalCenter
        width: Math.round(32 * dp)
        height: Math.round(32 * dp)
        radius: width / 2
        color: rebootHover.containsMouse ? Qt.rgba(textColor.r, textColor.g, textColor.b, 0.15) : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: "󰜉" // Reboot icon
            color: textColor
            font.pixelSize: Math.round(18 * dp)
        }

        MouseArea {
            id: rebootHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: sddm.reboot()
        }
    }

    // Botão Desligar
    Rectangle {
        id: powerBtn
        anchors.verticalCenter: parent.verticalCenter
        width: Math.round(32 * dp)
        height: Math.round(32 * dp)
        radius: width / 2
        color: powerHover.containsMouse ? Qt.rgba(textColor.r, textColor.g, textColor.b, 0.15) : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: "󰐥" // Power icon
            color: textColor
            font.pixelSize: Math.round(18 * dp)
        }

        MouseArea {
            id: powerHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: sddm.powerOff()
        }
    }
}