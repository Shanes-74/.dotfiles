import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import "components"

Rectangle {
    id: container
    width: 1920
    height: 1080
    color: config.backgroundColor
    focus: !loginState.visible

    property int userIndex: 0
    property int sessionIndex: 0
    property bool isLoggingIn: false
    property color extractedAccent: config.primaryColor ? config.primaryColor : "#A9C78F"

    Component.onCompleted: {
        if (typeof userModel !== "undefined" && userModel.lastIndex >= 0) userIndex = userModel.lastIndex;
        if (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) sessionIndex = sessionModel.lastIndex;
    }

    function cleanName(name) {
        if (!name) return "";
        var s = name.toString();
        if (s.endsWith("/")) s = s.substring(0, s.length - 1);
        if (s.indexOf("/") !== -1) s = s.substring(s.lastIndexOf("/") + 1);
        if (s.indexOf(".desktop") !== -1) s = s.substring(0, s.indexOf(".desktop"));
        s = s.replace(/[-_]/g, ' ');
        return s.charAt(0).toUpperCase() + s.slice(1);
    }

    function doLogin() {
        if (!loginState.visible || isLoggingIn) return;
        var user = "";
        if (typeof userModel !== "undefined" && userModel.count > 0) {
            var idx = container.userIndex;
            if (idx < 0 || idx >= userModel.count) idx = 0;
            var edit = userModel.data(userModel.index(idx, 0), Qt.EditRole);
            var nameRole = userModel.data(userModel.index(idx, 0), Qt.UserRole + 1);
            var display = userModel.data(userModel.index(idx, 0), Qt.DisplayRole);
            user = edit ? edit.toString() : (nameRole ? nameRole.toString() : (display ? display.toString() : ""));
        }
        if (!user || user === "" || user === "User") user = sddm.lastUser;
        if (!user && typeof userModel !== "undefined" && userModel.count > 0) {
            var firstEdit = userModel.data(userModel.index(0, 0), Qt.EditRole);
            user = firstEdit ? firstEdit.toString() : "";
        }
        if (!user) return;
        container.isLoggingIn = true;
        var pass = passwordField.text;
        var sess = container.sessionIndex;
        if (typeof sessionModel !== "undefined") {
            if (sess < 0 || sess >= sessionModel.count) sess = 0;
        } else { sess = 0; }
        sddm.login(user.trim(), pass, sess);
        loginTimeout.start();
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

    Image {
        id: backgroundImage
        source: config.background
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        layer.enabled: true
    }

    FastBlur {
        id: backgroundBlur
        anchors.fill: parent
        source: backgroundImage
        radius: config.blurRadius
        opacity: loginState.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: loginState.visible ? 0.4 : 0.2
        Behavior on opacity { NumberAnimation { duration: 400 } }
    }

    // --- Pílula de Status Centralizada ---
    Rectangle {
        id: topStatusPill
        height: 48
        width: statusLayout.width + 40
        anchors {
            top: parent.top
            topMargin: 30
            horizontalCenter: parent.horizontalCenter
        }
        color: loginState.isError ? config.errorColor : (config.surfaceContainer ? config.surfaceContainer : "#1a1a1a")
        opacity: 0.90
        radius: 999
        z: 100

        RowLayout {
            id: statusLayout
            anchors.centerIn: parent
            spacing: 20
            Text {
                text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
                color: container.extractedAccent
                font.pixelSize: 15
                font.family: config.fontFamily
                font.weight: Font.Medium
            }
            Rectangle { width: 1; height: 16; color: container.extractedAccent; opacity: 0.3 }
            PowerBar {
                textColor: container.extractedAccent
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

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
            opacity: 1
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }

        Text {
            text: "Press any key to unlock"
            color: "white"
            font.pixelSize: 20
            font.family: config.fontFamily
            style: Text.Outline
            styleColor: "black"
            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
                bottomMargin: 100
            }
            opacity: 0.8
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                loginState.visible = true;
                passwordField.forceActiveFocus();
            }
        }
    }

    Item {
        id: loginState
        anchors.fill: parent
        visible: false
        opacity: visible ? 1 : 0
        z: 10
        Behavior on opacity { NumberAnimation { duration: 400 } }

        onVisibleChanged: if (visible) passwordField.forceActiveFocus();

        property bool isError: false

        SequentialAnimation {
            id: shakeAnimation
            loops: 2
            PropertyAnimation { target: loginCard; property: "x"; from: (container.width - loginCard.width)/2; to: (container.width - loginCard.width)/2 - 10; duration: 50; easing.type: Easing.InOutQuad }
            PropertyAnimation { target: loginCard; property: "x"; from: (container.width - loginCard.width)/2 - 10; to: (container.width - loginCard.width)/2 + 10; duration: 50; easing.type: Easing.InOutQuad }
            PropertyAnimation { target: loginCard; property: "x"; from: (container.width - loginCard.width)/2 + 10; to: (container.width - loginCard.width)/2; duration: 50; easing.type: Easing.InOutQuad }
            onStopped: isError = false
        }

        // --- Cartão de login ---
        Rectangle {
            id: loginCard
            width: 400
            height: 500
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            color: config.surfaceContainer ? config.surfaceContainer : "#EEEBE3"
            opacity: 0.90
            radius: 32

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 40
                spacing: 10

                // Espaço superior
                Item { Layout.preferredHeight: 5 }

                // Avatar (apenas ícone com a inicial)
                Rectangle {
                    id: avatarIcon
                    width: 160
                    height: 160
                    Layout.alignment: Qt.AlignHCenter
                    color: config.onSurfaceColor
                    opacity: 0.2
                    radius: width / 2

                    Text {
                        anchors.centerIn: parent
                        text: {
                            var name = "";
                            if (typeof userModel !== "undefined" && userModel.count > 0) {
                                var display = userModel.data(userModel.index(container.userIndex, 0), Qt.DisplayRole);
                                var nameRole = userModel.data(userModel.index(container.userIndex, 0), Qt.UserRole + 1);
                                name = display ? display.toString() : (nameRole ? nameRole.toString() : "U");
                            } else {
                                name = sddm.lastUser ? sddm.lastUser : "U";
                            }
                            return name.charAt(0).toUpperCase();
                        }
                        color: container.extractedAccent
                        font.pixelSize: 48
                        font.family: fontBold.name
                        font.weight: Font.Bold
                    }
                }

                // Nome do usuário (clicável)
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: userNameLabel.width + 40
                    Layout.preferredHeight: userNameLabel.height + 20
                    Rectangle {
                        anchors.fill: parent
                        color: config.onSurfaceColor
                        opacity: userClickArea.pressed ? 0.2 : 0
                        radius: 12
                    }
                    Text {
                        id: userNameLabel
                        anchors.centerIn: parent
                        text: {
                            if (typeof userModel !== "undefined" && userModel.count > 0) {
                                var display = userModel.data(userModel.index(container.userIndex, 0), Qt.DisplayRole);
                                return display ? display.toString() : "Shane";
                            }
                            return "Shane";
                        }
                        color: config.onSurfaceColor
                        font.pixelSize: 24
                        font.weight: Font.Bold
                        font.family: config.fontFamily
                    }
                    MouseArea {
                        id: userClickArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: userPopup.open()
                    }
                    scale: userClickArea.pressed ? 0.95 : 1.0
                }

                // Seletor de sessão
                Rectangle {
                    id: sessionPill
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 200
                    Layout.preferredHeight: 42
                    Layout.topMargin: -5
                    color: Qt.rgba(config.onSurfaceColor.r, config.onSurfaceColor.g, config.onSurfaceColor.b, 0.15)
                    radius: 50

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 15
                        Text {
                            text: "󰟀"
                            color: container.extractedAccent
                            font.pixelSize: 16
                            opacity: 0.8
                        }
                        Text {
                            text: {
                                if (typeof sessionModel !== "undefined" && sessionModel.count > 0) {
                                    var idx = container.sessionIndex;
                                    var mIdx = sessionModel.index(idx, 0);
                                    var n = sessionModel.data(mIdx, Qt.UserRole + 4);
                                    var f = sessionModel.data(mIdx, Qt.UserRole + 2);
                                    var d = sessionModel.data(mIdx, Qt.DisplayRole);
                                    var finalName = n ? n.toString() : (f ? f.toString() : (d ? d.toString() : "Session " + (idx + 1)));
                                    return cleanName(finalName) + (sessionModel.count > 1 ? " ▾" : "");
                                }
                                return "Hyprland";
                            }
                            color: container.extractedAccent
                            font.pixelSize: 14
                            font.weight: Font.Medium
                        }
                    }
                    MouseArea {
                        id: sessionClickArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sessionPopup.open()
                    }
                }

                // --- Distância entre sessão e senha ---
                Item { Layout.preferredHeight: 5 }

                // Campo de senha
                TextField {
                    id: passwordField
                    echoMode: TextInput.Password
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 18
                    color: config.onSurfaceColor
                    focus: loginState.visible
                    enabled: !container.isLoggingIn

                    background: Rectangle {
                        color: loginState.isError
                            ? Qt.rgba(config.errorColor.r, config.errorColor.g, config.errorColor.b, 0.3)
                            : Qt.rgba(config.onSurfaceColor.r, config.onSurfaceColor.g, config.onSurfaceColor.b, 0.1)
                        radius: 50
                        border.width: parent.activeFocus ? 2 : (loginState.isError ? 2 : 0)
                        border.color: loginState.isError ? config.errorColor : container.extractedAccent
                    }

                    Text {
                        text: "Enter Password"
                        color: container.extractedAccent
                        font.pixelSize: 16
                        visible: !parent.text && !parent.focus
                        anchors.centerIn: parent
                        opacity: 0.8
                    }

                    onAccepted: container.doLogin()
                }

                // --- Espaço entre senha e botão ---
                Item {
                    Layout.fillHeight: true
                    Layout.minimumHeight: 2
                }

                // Botão de login
                RoundButton {
                    id: loginButton
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 64
                    Layout.bottomMargin: 0

                    focusPolicy: Qt.NoFocus
                    enabled: !container.isLoggingIn

                    contentItem: Item {
                        Text {
                            anchors.centerIn: parent
                            text: container.isLoggingIn ? "⋯" : "→"
                            color: (container.extractedAccent.r * 0.299 + container.extractedAccent.g * 0.587 + container.extractedAccent.b * 0.114) > 0.6 ? "#000000" : "#FFFFFF"
                            font.pixelSize: 32
                        }
                    }

                    background: Rectangle {
                        color: container.isLoggingIn ? config.outlineColor : (loginButton.pressed ? Qt.darker(container.extractedAccent, 1.1) : container.extractedAccent)
                        radius: 50
                    }

                    onClicked: container.doLogin()
                }

                // Espaço inferior fixo
                Item { Layout.preferredHeight: 20 }
            }
        }

        // --- Indicadores Caps Lock e Num Lock ---
        RowLayout {
            anchors {
                top: loginCard.bottom
                topMargin: 15
                horizontalCenter: parent.horizontalCenter
            }
            spacing: 40

            Text {
                id: capsLockIndicator
                text: "Caps Lock"
                color: container.extractedAccent
                font.pixelSize: 14
                font.family: config.fontFamily
                font.weight: Font.Medium
                visible: (typeof keyboard !== "undefined" && typeof keyboard.capsLock !== "undefined") ? keyboard.capsLock : false
            }

            Text {
                id: numLockIndicator
                text: "Num Lock"
                color: container.extractedAccent
                font.pixelSize: 14
                font.family: config.fontFamily
                font.weight: Font.Medium
                visible: (typeof keyboard !== "undefined" && typeof keyboard.numLock !== "undefined") ? keyboard.numLock : false
            }
        }
    }

    Keys.onPressed: function(event) {
        if (!loginState.visible) {
            loginState.visible = true;
            passwordField.forceActiveFocus();
            event.accepted = true;
        }
    }

    Shortcut { sequence: "Escape"; enabled: loginState.visible; onActivated: { loginState.visible = false; passwordField.text = ""; container.focus = true; } }
    Shortcut { sequences: ["Return", "Enter"]; enabled: loginState.visible; onActivated: container.doLogin() }

    // Popup de seleção de usuário
    Popup {
        id: userPopup
        width: 220
        height: {
            var itemCount = (typeof userModel !== "undefined" && userModel.count > 0) ? userModel.count : 1;
            var visibleItems = Math.min(itemCount, 4);
            return 30 + 4 + 20 + (visibleItems * 90);
        }
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2 - 50
        modal: true

        background: Rectangle {
            color: config.surfaceContainer
            radius: 24
            opacity: 0.95
            border.color: config.outlineColor
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Text {
                text: "Usuários"
                font.pixelSize: 18
                font.weight: Font.Bold
                color: config.onSurfaceColor
                Layout.alignment: Qt.AlignHCenter
            }

            Rectangle {
                height: 1
                color: config.outlineColor
                opacity: 0.3
                Layout.fillWidth: true
            }

            ListView {
                id: userList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: (typeof userModel !== "undefined") ? userModel : null
                delegate: ItemDelegate {
                    width: parent.width
                    height: 56
                    background: Rectangle {
                        color: (index === userList.currentIndex) ? config.onSurfaceColor : (hovered ? config.onSurfaceColor : "transparent")
                        opacity: (hovered || index === userList.currentIndex) ? 0.2 : 0
                        radius: 12
                    }

                    contentItem: RowLayout {
                        spacing: 15
                        Item { Layout.preferredWidth: 8 }
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: (index === userList.currentIndex) ? container.extractedAccent : config.outlineColor
                            Text {
                                anchors.centerIn: parent
                                text: {
                                    var name = "";
                                    if (model.display) name = model.display.toString();
                                    else if (model.name) name = model.name.toString();
                                    else name = "U";
                                    return name.charAt(0).toUpperCase();
                                }
                                color: config.onPrimaryColor
                                font.pixelSize: 14
                            }
                        }
                        Text {
                            text: {
                                if (model.display && model.display.toString().trim() !== "")
                                    return model.display.toString();
                                if (model.name && model.name.toString().trim() !== "")
                                    return model.name.toString();
                                if (typeof userModel !== "undefined" && userModel.count > index) {
                                    var loginName = userModel.data(userModel.index(index, 0), Qt.UserRole + 1);
                                    if (loginName) return loginName.toString();
                                }
                                return "Usuário " + (index + 1);
                            }
                            color: config.onSurfaceColor
                            font.pixelSize: 14
                            Layout.fillWidth: true
                        }
                    }

                    onClicked: {
                        container.userIndex = index
                        userPopup.close()
                    }
                }
            }
        }
    }

    // Popup de seleção de sessão
    Popup {
        id: sessionPopup
        width: 220
        height: {
            var itemCount = (typeof sessionModel !== "undefined" && sessionModel.count > 0) ? sessionModel.count : 1;
            var visibleItems = Math.min(itemCount, 4);
            return 30 + 4 + 20 + (visibleItems * 90);
        }
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2 + 80
        modal: true

        background: Rectangle {
            color: config.surfaceContainer
            radius: 24
            opacity: 0.95
            border.color: config.outlineColor
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Text {
                text: "Sessões"
                font.pixelSize: 18
                font.weight: Font.Bold
                color: config.onSurfaceColor
                Layout.alignment: Qt.AlignHCenter
            }

            Rectangle {
                height: 1
                color: config.outlineColor
                opacity: 0.3
                Layout.fillWidth: true
            }

            ListView {
                id: sessionList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: (typeof sessionModel !== "undefined") ? sessionModel : null
                delegate: ItemDelegate {
                    width: parent.width
                    height: 56
                    background: Rectangle {
                        color: (index === sessionList.currentIndex) ? config.onSurfaceColor : (hovered ? config.onSurfaceColor : "transparent")
                        opacity: (hovered || index === sessionList.currentIndex) ? 0.2 : 0
                        radius: 12
                    }

                    contentItem: Text {
                        text: cleanName(model.name)
                        color: config.onSurfaceColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 14
                    }

                    onClicked: {
                        container.sessionIndex = index
                        sessionPopup.close()
                    }
                }
            }
        }
    }
}