import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import "components"

Rectangle {
    id: container
    width: Screen.width
    height: Screen.height
    color: config.backgroundColor
    focus: !loginState.visible

    property real dp: Math.min(width, height) / 1080
    property int userIndex: 0
    property int sessionIndex: 0
    property bool isLoggingIn: false
    property color extractedAccent: config.primaryColor ? config.primaryColor : "#A9C78F"

    Component.onCompleted: {
        if (typeof userModel !== "undefined" && userModel.lastIndex >= 0)
            userIndex = userModel.lastIndex
        if (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0)
            sessionIndex = sessionModel.lastIndex
    }

    function cleanName(name) {
        if (!name) return ""
        var s = name.toString()
        if (s.endsWith("/")) s = s.substring(0, s.length - 1)
        if (s.indexOf("/") !== -1) s = s.substring(s.lastIndexOf("/") + 1)
        if (s.indexOf(".desktop") !== -1) s = s.substring(0, s.indexOf(".desktop"))
        s = s.replace(/[-_]/g, ' ')
        return s.charAt(0).toUpperCase() + s.slice(1)
    }

    function doLogin() {
        if (!loginState.visible || isLoggingIn) return

        var user = ""
        if (typeof userModel !== "undefined" && userModel.count > 0) {
            var idx = container.userIndex
            if (idx < 0 || idx >= userModel.count) idx = 0
            var edit = userModel.data(userModel.index(idx, 0), Qt.EditRole)
            var nameRole = userModel.data(userModel.index(idx, 0), Qt.UserRole + 1)
            var display = userModel.data(userModel.index(idx, 0), Qt.DisplayRole)
            user = edit ? edit.toString() : (nameRole ? nameRole.toString() : (display ? display.toString() : ""))
        }
        if (!user || user === "" || user === "User") user = sddm.lastUser
        if (!user && typeof userModel !== "undefined" && userModel.count > 0) {
            var firstEdit = userModel.data(userModel.index(0, 0), Qt.EditRole)
            user = firstEdit ? firstEdit.toString() : ""
        }
        if (!user) return

        container.isLoggingIn = true
        var pass = passwordField.text
        var sess = container.sessionIndex
        if (typeof sessionModel !== "undefined") {
            if (sess < 0 || sess >= sessionModel.count) sess = 0
        } else {
            sess = 0
        }

        sddm.login(user.trim(), pass, sess)
        loginTimeout.start()
    }

    Timer {
        id: loginTimeout
        interval: 5000
        onTriggered: container.isLoggingIn = false
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            container.isLoggingIn = false
            loginTimeout.stop()
            loginState.isError = true
            shakeAnimation.start()
            passwordField.text = ""
            passwordField.forceActiveFocus()
        }
        function onLoginSucceeded() {
            loginTimeout.stop()
        }
    }

    FontLoader { id: fontRegular; source: "assets/fonts/FlexRounded-R.ttf" }
    FontLoader { id: fontMedium; source: "assets/fonts/FlexRounded-M.ttf" }
    FontLoader { id: fontBold; source: "assets/fonts/FlexRounded-B.ttf" }

    // --- Fundo e Efeitos ---
    Image {
        id: backgroundImage
        source: config.background
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        layer.enabled: true
    }

    FastBlur {
        id: blur1
        anchors.fill: parent
        source: backgroundImage
        radius: 20
        opacity: loginState.visible ? 1 : 0
        layer.enabled: true
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
    }

    FastBlur {
        id: blur2
        anchors.fill: parent
        source: blur1
        radius: 20
        opacity: loginState.visible ? 1 : 0
        layer.enabled: true
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
    }

    FastBlur {
        id: blur3
        anchors.fill: parent
        source: blur2
        radius: 20
        opacity: loginState.visible ? 1 : 0
        layer.enabled: true
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
    }

    FastBlur {
        id: blur4
        anchors.fill: parent
        source: blur3
        radius: 20
        opacity: loginState.visible ? 1 : 0
        layer.enabled: true
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
    }

    Item {
        anchors.fill: parent
        opacity: loginState.visible ? 1 : 0
        layer.enabled: true
        layer.effect: BrightnessContrast { brightness: 0.0; contrast: 0.35 }
        Behavior on opacity { NumberAnimation { duration: 400 } }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: loginState.visible ? 0.40 : 0.20
        Behavior on opacity { NumberAnimation { duration: 400 } }
    }

    // --- Pílula de Status Superior ---
    Rectangle {
        id: topStatusPill
        height: Math.round(48 * dp)
        width: statusLayout.implicitWidth + Math.round(32 * dp)
        anchors {
            top: parent.top
            topMargin: Math.round(16 * dp)
            horizontalCenter: parent.horizontalCenter
        }
        color: config.surfaceContainer ? config.surfaceContainer : "#1a1a1a"
        opacity: 0.90
        radius: 999
        z: 100

        Row {
            id: statusLayout
            anchors.centerIn: parent
            spacing: Math.round(24 * dp)

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDateTime(new Date(), "d MMMM, dddd")
                color: container.extractedAccent
                font.pixelSize: Math.round(16 * dp)
                font.family: config.fontFamily
                font.weight: Font.Medium
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: Math.round(16 * dp)
                color: container.extractedAccent
                opacity: 0.3
            }

            PowerBar {
                anchors.verticalCenter: parent.verticalCenter
                textColor: container.extractedAccent
                dp: container.dp
            }
        }
    }

    // --- Tela de Lock (modo bloqueado) ---
    Item {
        id: lockState
        anchors.fill: parent
        visible: !loginState.visible
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }

        Clock {
            id: mainClock
            anchors.centerIn: parent
            backgroundSource: config.background
            baseAccent: container.extractedAccent
            fontFamily: config.fontFamily
            dp: container.dp
        }

        Text {
            text: "Press Enter or Click to Unlock"
            color: "white"
            font.pixelSize: Math.round(20 * dp)
            font.family: config.fontFamily
            style: Text.Outline
            styleColor: "black"
            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
                bottomMargin: Math.round(100 * dp)
            }
            opacity: 0.8
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                loginState.visible = true
                passwordField.forceActiveFocus()
            }
        }
    }

    // --- Tela de Login ---
    Item {
        id: loginState
        anchors.fill: parent
        visible: false
        opacity: visible ? 1 : 0
        z: 10
        Behavior on opacity { NumberAnimation { duration: 400 } }
        onVisibleChanged: if (visible) passwordField.forceActiveFocus()
        property bool isError: false

        SequentialAnimation {
            id: shakeAnimation
            loops: 2
            PropertyAnimation {
                target: loginCard
                property: "x"
                from: (container.width - loginCard.width) / 2
                to: (container.width - loginCard.width) / 2 - Math.round(10 * dp)
                duration: 50
                easing.type: Easing.InOutQuad
            }
            PropertyAnimation {
                target: loginCard
                property: "x"
                from: (container.width - loginCard.width) / 2 - Math.round(10 * dp)
                to: (container.width - loginCard.width) / 2 + Math.round(10 * dp)
                duration: 50
                easing.type: Easing.InOutQuad
            }
            PropertyAnimation {
                target: loginCard
                property: "x"
                from: (container.width - loginCard.width) / 2 + Math.round(10 * dp)
                to: (container.width - loginCard.width) / 2
                duration: 50
                easing.type: Easing.InOutQuad
            }
            onStopped: loginState.isError = false
        }

        // --- Cartão de Login ---
        Rectangle {
            id: loginCard
            width: Math.round(400 * dp)
            height: Math.round(500 * dp)
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            color: config.surfaceContainer ? config.surfaceContainer : "#EEEBE3"
            opacity: 0.90
            radius: Math.round(32 * dp)

            Column {
                id: cardContent
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    topMargin: Math.round(32 * dp)
                    leftMargin: Math.round(40 * dp)
                    rightMargin: Math.round(40 * dp)
                }
                spacing: Math.round(10 * dp)

                // Avatar
                Rectangle {
                    id: avatarIcon
                    width: Math.round(180 * dp)
                    height: Math.round(180 * dp)
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: config.onSurfaceColor
                    opacity: 0.2
                    radius: width / 2

                    Text {
                        anchors.centerIn: parent
                        text: {
                            var name = ""
                            if (typeof userModel !== "undefined" && userModel.count > 0) {
                                var display = userModel.data(userModel.index(container.userIndex, 0), Qt.DisplayRole)
                                var nameRole = userModel.data(userModel.index(container.userIndex, 0), Qt.UserRole + 1)
                                name = display ? display.toString() : (nameRole ? nameRole.toString() : "U")
                            } else {
                                name = sddm.lastUser ? sddm.lastUser : "U"
                            }
                            return name.charAt(0).toUpperCase()
                        }
                        color: container.extractedAccent
                        font.pixelSize: Math.round(52 * dp)
                        font.family: fontBold.name
                        font.weight: Font.Bold
                    }
                }

                // Nome do usuário (com hover)
                Item {
                    id: userNameItem
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: userNameLabel.width + Math.round(40 * dp)
                    height: userNameLabel.height + Math.round(16 * dp)

                    Rectangle {
                        anchors.fill: parent
                        radius: Math.round(12 * dp)
                        color: config.onSurfaceColor
                        opacity: userClickArea.pressed ? 0.25 : (userClickArea.containsMouse ? 0.12 : 0)
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    Text {
                        id: userNameLabel
                        anchors.centerIn: parent
                        text: {
                            if (typeof userModel !== "undefined" && userModel.count > 0) {
                                var display = userModel.data(userModel.index(container.userIndex, 0), Qt.DisplayRole)
                                return display ? display.toString() : "Shane"
                            }
                            return "Shane"
                        }
                        color: config.onSurfaceColor
                        font.pixelSize: Math.round(24 * dp)
                        font.weight: Font.Bold
                        font.family: config.fontFamily
                    }

                    MouseArea {
                        id: userClickArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: userPopup.open()
                    }

                    scale: userClickArea.pressed ? 0.95 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }

                // Seletor de sessão (com hover)
                Rectangle {
                    id: sessionPill
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.round(208 * dp)
                    height: Math.round(42 * dp)
                    radius: 50
                    color: sessionHover.containsMouse
                        ? Qt.rgba(config.onSurfaceColor.r, config.onSurfaceColor.g, config.onSurfaceColor.b, 0.25)
                        : Qt.rgba(config.onSurfaceColor.r, config.onSurfaceColor.g, config.onSurfaceColor.b, 0.15)
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: Math.round(8 * dp)

                        Text {
                            text: "󰟀"
                            color: container.extractedAccent
                            font.pixelSize: Math.round(13 * dp)
                            opacity: 0.8
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: {
                                if (typeof sessionModel !== "undefined" && sessionModel.count > 0) {
                                    var idx = container.sessionIndex
                                    var mIdx = sessionModel.index(idx, 0)
                                    var n = sessionModel.data(mIdx, Qt.UserRole + 4)
                                    var f = sessionModel.data(mIdx, Qt.UserRole + 2)
                                    var d = sessionModel.data(mIdx, Qt.DisplayRole)
                                    var finalName = n ? n.toString() : (f ? f.toString() : (d ? d.toString() : "Session " + (idx + 1)))
                                    return cleanName(finalName) + (sessionModel.count > 1 ? " ▾" : "")
                                }
                                return "Hyprland"
                            }
                            color: container.extractedAccent
                            font.pixelSize: Math.round(13 * dp)
                            font.weight: Font.Medium
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: sessionHover
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: sessionPopup.open()
                    }
                }

                Item {
                    width: 1
                    height: Math.round(4 * dp)
                }

                // Campo de senha
                TextField {
                    id: passwordField
                    echoMode: TextInput.Password
                    width: parent.width
                    height: Math.round(48 * dp)
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Math.round(18 * dp)
                    color: config.onSurfaceColor
                    focus: loginState.visible
                    enabled: !container.isLoggingIn

                    background: Rectangle {
                        color: Qt.rgba(config.onSurfaceColor.r, config.onSurfaceColor.g, config.onSurfaceColor.b, 0.1)
                        radius: 50
                        border.width: parent.activeFocus ? 2 : (loginState.isError ? 2 : 0)
                        border.color: loginState.isError ? config.errorColor : container.extractedAccent
                    }

                    Text {
                        text: "Enter Password"
                        color: container.extractedAccent
                        font.pixelSize: Math.round(16 * dp)
                        visible: !parent.text && !parent.focus
                        anchors.centerIn: parent
                        opacity: 0.8
                    }

                    onAccepted: container.doLogin()
                }
            }

            // Botão de login customizado com MouseArea
            Rectangle {
                id: loginButtonContainer
                anchors {
                    bottom: parent.bottom
                    bottomMargin: Math.round(24 * dp)
                    horizontalCenter: parent.horizontalCenter
                }
                width: Math.round(64 * dp)
                height: Math.round(64 * dp)
                radius: 50
                color: container.isLoggingIn
                    ? config.outlineColor
                    : loginMouseArea.pressed
                        ? Qt.darker(container.extractedAccent, 1.2)
                        : loginMouseArea.containsMouse
                            ? Qt.lighter(container.extractedAccent, 1.15)
                            : container.extractedAccent
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: container.isLoggingIn ? "⋯" : "→"
                    color: (container.extractedAccent.r * 0.299 + container.extractedAccent.g * 0.587 + container.extractedAccent.b * 0.114) > 0.6 ? "#000000" : "#FFFFFF"
                    font.pixelSize: Math.round(32 * dp)
                }

                MouseArea {
                    id: loginMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    enabled: !container.isLoggingIn
                    onClicked: container.doLogin()
                }
            }
        }

        // Indicadores Caps Lock / Num Lock
        Row {
            anchors {
                top: loginCard.bottom
                topMargin: Math.round(15 * dp)
                horizontalCenter: loginCard.horizontalCenter
            }
            spacing: Math.round(40 * dp)

            Text {
                text: "Caps Lock"
                color: container.extractedAccent
                font.pixelSize: Math.round(14 * dp)
                font.family: config.fontFamily
                font.weight: Font.Medium
                visible: (typeof keyboard !== "undefined" && typeof keyboard.capsLock !== "undefined") ? keyboard.capsLock : false
            }

            Text {
                text: "Num Lock"
                color: container.extractedAccent
                font.pixelSize: Math.round(14 * dp)
                font.family: config.fontFamily
                font.weight: Font.Medium
                visible: (typeof keyboard !== "undefined" && typeof keyboard.numLock !== "undefined") ? keyboard.numLock : false
            }
        }
    }

    // --- Atalhos de Teclado ---
    Shortcut {
        sequence: "Return"
        enabled: !loginState.visible
        onActivated: {
            loginState.visible = true
            passwordField.forceActiveFocus()
        }
    }

    Shortcut {
        sequence: "Enter"
        enabled: !loginState.visible
        onActivated: {
            loginState.visible = true
            passwordField.forceActiveFocus()
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: loginState.visible
        onActivated: {
            loginState.visible = false
            passwordField.text = ""
            container.focus = true
        }
    }

    Shortcut {
        sequences: ["Return", "Enter"]
        enabled: loginState.visible
        onActivated: container.doLogin()
    }

    // --- Popup de Seleção de Usuário ---
    Popup {
        id: userPopup
        width: Math.round(220 * dp)
        height: {
            var itemCount = (typeof userModel !== "undefined" && userModel.count > 0) ? userModel.count : 1
            return Math.round((54 + Math.min(itemCount, 4) * 62) * dp)
        }
        anchors.centerIn: parent
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: config.surfaceContainer ? config.surfaceContainer : "#1a1a1a"
            radius: Math.round(24 * dp)
            opacity: 0.97
            border.color: config.outlineColor ? config.outlineColor : "#444"
            border.width: 1
        }

        contentItem: Column {
            anchors.fill: parent
            anchors.margins: Math.round(10 * dp)
            spacing: Math.round(8 * dp)

            Text {
                text: "Usuários"
                font.pixelSize: Math.round(16 * dp)
                font.weight: Font.Bold
                color: config.onSurfaceColor
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Rectangle {
                width: parent.width
                height: 1
                color: config.outlineColor ? config.outlineColor : "#444"
                opacity: 0.3
            }

            ListView {
                id: userList
                width: parent.width
                height: userPopup.height - Math.round(54 * dp)
                clip: true
                model: (typeof userModel !== "undefined") ? userModel : null

                delegate: Item {
                    width: parent.width
                    height: Math.round(56 * dp)

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: Math.round(4 * dp)
                        radius: Math.round(10 * dp)
                        color: config.onSurfaceColor ? config.onSurfaceColor : "#fff"
                        opacity: userDelegateHover.containsMouse ? 0.15 : (index === container.userIndex ? 0.1 : 0)
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: Math.round(10 * dp)

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.round(28 * dp)
                            height: Math.round(28 * dp)
                            radius: width / 2
                            color: index === container.userIndex ? container.extractedAccent : (config.outlineColor ? config.outlineColor : "#555")

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    var name = ""
                                    if (model.display) name = model.display.toString()
                                    else if (model.name) name = model.name.toString()
                                    else name = "U"
                                    return name.charAt(0).toUpperCase()
                                }
                                color: config.onPrimaryColor ? config.onPrimaryColor : "#fff"
                                font.pixelSize: Math.round(12 * dp)
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: {
                                if (model.display && model.display.toString().trim() !== "") return model.display.toString()
                                if (model.name   && model.name.toString().trim()    !== "") return model.name.toString()
                                if (typeof userModel !== "undefined" && userModel.count > index) {
                                    var loginName = userModel.data(userModel.index(index, 0), Qt.UserRole + 1)
                                    if (loginName) return loginName.toString()
                                }
                                return "Usuário " + (index + 1)
                            }
                            color: config.onSurfaceColor
                            font.pixelSize: Math.round(14 * dp)
                        }
                    }

                    MouseArea {
                        id: userDelegateHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            container.userIndex = index
                            userPopup.close()
                        }
                    }
                }
            }
        }
    }

    // --- Popup de Seleção de Sessão ---
    Popup {
        id: sessionPopup
        width: Math.round(220 * dp)
        height: {
            var itemCount = (typeof sessionModel !== "undefined" && sessionModel.count > 0) ? sessionModel.count : 1
            return Math.round((54 + Math.min(itemCount, 4) * 62) * dp)
        }
        anchors.centerIn: parent
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: config.surfaceContainer ? config.surfaceContainer : "#1a1a1a"
            radius: Math.round(24 * dp)
            opacity: 0.97
            border.color: config.outlineColor ? config.outlineColor : "#444"
            border.width: 1
        }

        contentItem: Column {
            anchors.fill: parent
            anchors.margins: Math.round(10 * dp)
            spacing: Math.round(8 * dp)

            Text {
                text: "Sessões"
                font.pixelSize: Math.round(16 * dp)
                font.weight: Font.Bold
                color: config.onSurfaceColor
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Rectangle {
                width: parent.width
                height: 1
                color: config.outlineColor ? config.outlineColor : "#444"
                opacity: 0.3
            }

            ListView {
                id: sessionList
                width: parent.width
                height: sessionPopup.height - Math.round(54 * dp)
                clip: true
                model: (typeof sessionModel !== "undefined") ? sessionModel : null

                delegate: Item {
                    width: parent.width
                    height: Math.round(56 * dp)

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: Math.round(4 * dp)
                        radius: Math.round(10 * dp)
                        color: config.onSurfaceColor ? config.onSurfaceColor : "#fff"
                        opacity: sessionDelegateHover.containsMouse ? 0.15 : (index === container.sessionIndex ? 0.1 : 0)
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: cleanName(model.name)
                        color: config.onSurfaceColor
                        font.pixelSize: Math.round(14 * dp)
                    }

                    MouseArea {
                        id: sessionDelegateHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            container.sessionIndex = index
                            sessionPopup.close()
                        }
                    }
                }
            }
        }
    }
}