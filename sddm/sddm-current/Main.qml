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

    // dp: fator de escala baseado na altura da tela, design base = 1080p
    // Em 1080p → dp=1.0 | Em 1440p → dp=1.33 | Em 4K → dp=2.0 | Em 720p → dp=0.67
    property real dp: Math.min(width, height) / 1080

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

    // --- Wallpaper base ---
    Image {
        id: backgroundImage
        source: config.background
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        layer.enabled: true
    }

    // --- Blur em 4 passes encadeados (simula size=3 passes=4 do Hyprland) ---
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

    // --- Contraste (simula contrast=1.5) ---
    Item {
        anchors.fill: parent
        opacity: loginState.visible ? 1 : 0
        layer.enabled: true
        layer.effect: BrightnessContrast {
            brightness: 0.0
            contrast: 0.35
        }
        Behavior on opacity { NumberAnimation { duration: 400 } }
    }

    // --- Overlay de escurecimento (brightness=0.8 / ignore_opacity) ---
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: loginState.visible ? 0.18 : 0.15
        Behavior on opacity { NumberAnimation { duration: 400 } }
    }

    // --- Pílula de Status Centralizada ---
    Rectangle {
        id: topStatusPill
        height: Math.round(48 * dp)
        width: statusLayout.width + Math.round(40 * dp)
        anchors {
            top: parent.top
            topMargin: Math.round(30 * dp)
            horizontalCenter: parent.horizontalCenter
        }
        color: config.surfaceContainer ? config.surfaceContainer : "#1a1a1a"
        opacity: 0.90
        radius: 999
        z: 100

        RowLayout {
            id: statusLayout
            anchors.centerIn: parent
            spacing: Math.round(20 * dp)
            Text {
                text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
                color: container.extractedAccent
                font.pixelSize: Math.round(15 * dp)
                font.family: config.fontFamily
                font.weight: Font.Medium
            }
            Rectangle {
                width: 1
                height: Math.round(16 * dp)
                color: container.extractedAccent
                opacity: 0.3
            }
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
            text: "Press Enter to unlock"
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
            PropertyAnimation {
                target: loginCard; property: "x"
                from: (container.width - loginCard.width) / 2
                to:   (container.width - loginCard.width) / 2 - Math.round(10 * dp)
                duration: 50; easing.type: Easing.InOutQuad
            }
            PropertyAnimation {
                target: loginCard; property: "x"
                from: (container.width - loginCard.width) / 2 - Math.round(10 * dp)
                to:   (container.width - loginCard.width) / 2 + Math.round(10 * dp)
                duration: 50; easing.type: Easing.InOutQuad
            }
            PropertyAnimation {
                target: loginCard; property: "x"
                from: (container.width - loginCard.width) / 2 + Math.round(10 * dp)
                to:   (container.width - loginCard.width) / 2
                duration: 50; easing.type: Easing.InOutQuad
            }
            onStopped: isError = false
        }

        // --- Cartão de login ---
        Rectangle {
            id: loginCard
            width: Math.round(400 * dp)
            height: Math.round(500 * dp)
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            color: config.surfaceContainer ? config.surfaceContainer : "#EEEBE3"
            opacity: 0.90
            radius: Math.round(32 * dp)

            // Coluna centralizada — usa Column simples para alinhamento previsível
            Column {
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                    right: parent.right
                    margins: Math.round(40 * dp)
                }
                spacing: Math.round(10 * dp)

                // Espaço superior
                Item { width: 1; height: Math.round(5 * dp) }

                // Avatar
                Rectangle {
                    id: avatarIcon
                    width: Math.round(160 * dp)
                    height: Math.round(160 * dp)
                    anchors.horizontalCenter: parent.horizontalCenter
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
                        font.pixelSize: Math.round(48 * dp)
                        font.family: fontBold.name
                        font.weight: Font.Bold
                    }
                }

                // Nome do usuário (clicável)
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: userNameLabel.width + Math.round(40 * dp)
                    height: userNameLabel.height + Math.round(20 * dp)
                    Rectangle {
                        anchors.fill: parent
                        color: config.onSurfaceColor
                        opacity: userClickArea.pressed ? 0.2 : 0
                        radius: Math.round(12 * dp)
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
                        font.pixelSize: Math.round(24 * dp)
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
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.round(208 * dp)
                    height: Math.round(42 * dp)
                    color: Qt.rgba(config.onSurfaceColor.r, config.onSurfaceColor.g, config.onSurfaceColor.b, 0.15)
                    radius: 50

                    Row {
                        anchors.centerIn: parent
                        spacing: Math.round(15 * dp)
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰟀"
                            color: container.extractedAccent
                            font.pixelSize: Math.round(16 * dp)
                            opacity: 0.8
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
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
                            font.pixelSize: Math.round(14 * dp)
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

                Item { width: 1; height: Math.round(5 * dp) }

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

                // Espaço flexível entre senha e botão
                Item {
                    width: 1
                    height: Math.round(loginCard.height
                        - Math.round(40 * dp) * 2   // margins top+bottom
                        - Math.round(5 * dp)         // espaço topo
                        - Math.round(160 * dp)       // avatar
                        - Math.round(10 * dp)        // spacing
                        - (userNameLabel.height + Math.round(20 * dp)) // nome
                        - Math.round(10 * dp)
                        - Math.round(42 * dp)        // session pill
                        - Math.round(10 * dp)
                        - Math.round(5 * dp)         // spacer
                        - Math.round(10 * dp)
                        - Math.round(48 * dp)        // password
                        - Math.round(10 * dp)
                        - Math.round(42 * dp)        // botão
                        - Math.round(20 * dp)        // espaço inferior
                    )
                }

                // Botão de login
                RoundButton {
                    id: loginButton
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.round(64 * dp)
                    height: Math.round(64 * dp)

                    focusPolicy: Qt.NoFocus
                    enabled: !container.isLoggingIn

                    contentItem: Item {
                        Text {
                            anchors.centerIn: parent
                            text: container.isLoggingIn ? "⋯" : "→"
                            color: (container.extractedAccent.r * 0.299 + container.extractedAccent.g * 0.587 + container.extractedAccent.b * 0.114) > 0.6 ? "#000000" : "#FFFFFF"
                            font.pixelSize: Math.round(32 * dp)
                        }
                    }

                    background: Rectangle {
                        color: container.isLoggingIn ? config.outlineColor : (loginButton.pressed ? Qt.darker(container.extractedAccent, 1.1) : container.extractedAccent)
                        radius: 50
                    }

                    onClicked: container.doLogin()
                }

                Item { width: 1; height: Math.round(20 * dp) }
            }
        }

        // --- Indicadores Caps Lock e Num Lock ---
        RowLayout {
            anchors {
                top: loginCard.bottom
                topMargin: Math.round(15 * dp)
                horizontalCenter: parent.horizontalCenter
            }
            spacing: Math.round(40 * dp)

            Text {
                id: capsLockIndicator
                text: "Caps Lock"
                color: container.extractedAccent
                font.pixelSize: Math.round(14 * dp)
                font.family: config.fontFamily
                font.weight: Font.Medium
                visible: (typeof keyboard !== "undefined" && typeof keyboard.capsLock !== "undefined") ? keyboard.capsLock : false
            }

            Text {
                id: numLockIndicator
                text: "Num Lock"
                color: container.extractedAccent
                font.pixelSize: Math.round(14 * dp)
                font.family: config.fontFamily
                font.weight: Font.Medium
                visible: (typeof keyboard !== "undefined" && typeof keyboard.numLock !== "undefined") ? keyboard.numLock : false
            }
        }
    }

    // Só abre o login com Enter, não com qualquer tecla
    Shortcut {
        sequence: "Return"
        enabled: !loginState.visible
        onActivated: { loginState.visible = true; passwordField.forceActiveFocus(); }
    }
    Shortcut {
        sequence: "Enter"
        enabled: !loginState.visible
        onActivated: { loginState.visible = true; passwordField.forceActiveFocus(); }
    }

    Shortcut { sequence: "Escape"; enabled: loginState.visible; onActivated: { loginState.visible = false; passwordField.text = ""; container.focus = true; } }
    Shortcut { sequences: ["Return", "Enter"]; enabled: loginState.visible; onActivated: container.doLogin() }

    // Popup de seleção de usuário
    Popup {
        id: userPopup
        width: Math.round(220 * dp)
        height: {
            var itemCount = (typeof userModel !== "undefined" && userModel.count > 0) ? userModel.count : 1;
            var visibleItems = Math.min(itemCount, 4);
            return Math.round((54 + visibleItems * 90) * dp);
        }
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2 - Math.round(50 * dp)
        modal: true

        background: Rectangle {
            color: config.surfaceContainer
            radius: Math.round(24 * dp)
            opacity: 0.95
            border.color: config.outlineColor
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Math.round(10 * dp)
            spacing: Math.round(10 * dp)

            Text {
                text: "Usuários"
                font.pixelSize: Math.round(18 * dp)
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
                    height: Math.round(56 * dp)
                    background: Rectangle {
                        color: (index === userList.currentIndex) ? config.onSurfaceColor : (hovered ? config.onSurfaceColor : "transparent")
                        opacity: (hovered || index === userList.currentIndex) ? 0.2 : 0
                        radius: Math.round(12 * dp)
                    }

                    contentItem: RowLayout {
                        spacing: Math.round(15 * dp)
                        Item { Layout.preferredWidth: Math.round(8 * dp) }
                        Rectangle {
                            width: Math.round(32 * dp)
                            height: Math.round(32 * dp)
                            radius: width / 2
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
                                font.pixelSize: Math.round(14 * dp)
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
                            font.pixelSize: Math.round(14 * dp)
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
        width: Math.round(220 * dp)
        height: {
            var itemCount = (typeof sessionModel !== "undefined" && sessionModel.count > 0) ? sessionModel.count : 1;
            var visibleItems = Math.min(itemCount, 4);
            return Math.round((54 + visibleItems * 90) * dp);
        }
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2 + Math.round(80 * dp)
        modal: true

        background: Rectangle {
            color: config.surfaceContainer
            radius: Math.round(24 * dp)
            opacity: 0.95
            border.color: config.outlineColor
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Math.round(10 * dp)
            spacing: Math.round(10 * dp)

            Text {
                text: "Sessões"
                font.pixelSize: Math.round(18 * dp)
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
                    height: Math.round(56 * dp)
                    background: Rectangle {
                        color: (index === sessionList.currentIndex) ? config.onSurfaceColor : (hovered ? config.onSurfaceColor : "transparent")
                        opacity: (hovered || index === sessionList.currentIndex) ? 0.2 : 0
                        radius: Math.round(12 * dp)
                    }

                    contentItem: Text {
                        text: cleanName(model.name)
                        color: config.onSurfaceColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: Math.round(14 * dp)
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