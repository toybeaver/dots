// Quickshell greeter for greetd.
//
// Replaces gtkgreet. The reason is layout: gtkgreet builds its form as one
// fixed GtkBox and GTK3 CSS has no absolute positioning, so the session
// selector cannot be moved out of the card — displacing it with margins either
// grows the card or gets it clipped. Here the layout is ours, so the clock sits
// centred, the credentials sit centred, and the session picker sits in the
// bottom-left corner.
//
// The session list is still read from /etc/greetd/environments, exactly as
// gtkgreet did. That file stays the single source of truth and is not
// duplicated here.
//
// Deliberately uses only QtQuick — no QtQuick.Controls. Controls widgets pull a
// style that would need overriding, and every override is another thing to go
// wrong on the login path.

import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Greetd
import QtQuick

ShellRoot {
    id: root

    // ---- palette (mirrors the desktop theme) ----
    // Ink on paper. Same palette as this theme's lock screen, kept in sync by hand.
    readonly property color cBase:     "#f4f1e8"
    readonly property color cCard:     "#ffffff"
    readonly property color cField:    "#ffffff"
    readonly property color cText:     "#000000"
    readonly property color cMuted:    "#57534a"
    readonly property color cAccent:   "#a78bfa"
    readonly property color cDanger:   "#ff4d4d"

    // Brutalist additions, mirroring lock/shell.qml.
    readonly property color cInk:      "#000000"
    readonly property color cShadow:   "#000000"
    readonly property color cOnAccent: "#000000"
    readonly property color cSunk:     "#efece3"
    readonly property int   shadowOff: 6

    // ---- session list, straight from /etc/greetd/environments ----
    FileView {
        id: envFile
        path: "/etc/greetd/environments"
        blockLoading: true
        printErrors: true
    }

    readonly property var sessions: {
        const raw = envFile.text();
        const list = raw ? raw.split("\n").filter(l => l.trim().length > 0) : [];
        // Never leave the picker empty — if the file is unreadable the greeter
        // must still be able to start something.
        return list.length > 0 ? list : ["bash"];
    }

    property int sessionIndex: 0
    readonly property string session: sessions[Math.min(sessionIndex, sessions.length - 1)]

    // ---- auth state ----
    property string username: ""
    property string promptText: ""      // greetd's prompt, e.g. "Password:"
    property bool promptEcho: false     // false => mask the input
    property bool awaitingResponse: false
    property string errorText: ""
    property string infoText: ""

    function beginAuth() {
        if (username.trim().length === 0) return;
        errorText = "";
        infoText = "";
        Greetd.createSession(username.trim());
    }

    function resetAuth() {
        awaitingResponse = false;
        promptText = "";
        promptEcho = false;
    }

    // Escape abandons the in-flight session and returns to the single-field
    // state. The username is deliberately kept so it can be corrected rather
    // than retyped.
    function cancelToUsername() {
        if (Greetd.state !== GreetdState.Inactive) Greetd.cancelSession();
        resetAuth();
        errorText = "";
        infoText = "";
    }

    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) {
                root.promptText = message;
                root.promptEcho = echoResponse;
                root.awaitingResponse = true;
            } else if (error) {
                root.errorText = message;
            } else {
                root.infoText = message;
            }
        }

        function onAuthFailure(message) {
            root.errorText = message && message.length > 0 ? message : "Authentication failed";
            root.resetAuth();
        }

        function onReadyToLaunch() {
            Greetd.launch([root.session]);
        }

        function onError(err) {
            root.errorText = err;
            root.resetAuth();
        }
    }

    // ---- clock ----
    property string timeText: ""
    property string dateText: ""

    function tick() {
        const now = new Date();
        timeText = Qt.formatDateTime(now, "HH:mm");
        dateText = Qt.formatDateTime(now, "dddd, d MMMM");
    }

    Component.onCompleted: tick()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.tick()
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData

            // Only one screen owns the form and the keyboard. Duplicating an
            // exclusive-focus surface across outputs fights for input.
            readonly property bool primary: modelData === Quickshell.screens[0]

            WlrLayershell.namespace: "greeter"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: primary ? WlrKeyboardFocus.Exclusive
                                                 : WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore

            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"

            // ---- backdrop ----
            // A gradient rather than a wallpaper: the greeter runs as the
            // `greeter` user and cannot read anything under /home (0700). Drop
            // an image at /etc/greetd/background.png to use one instead.
            Rectangle {
                anchors.fill: parent
                color: root.cBase

                Image {
                    anchors.fill: parent
                    source: "file:///etc/greetd/background.png"
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                    opacity: 0.55
                }

                // No dimming veil, unlike the glass theme. See the same
                // decision in this theme's lock/shell.qml.
            }

            // ---- clock + credentials, centred ----
            Column {
                anchors.centerIn: parent
                spacing: 34
                visible: panel.primary

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    // Negative on purpose. At 88px the clock's line box reserves
                    // a lot of empty descender space below the digits, so the
                    // visible gap is font metrics rather than spacing — pulling
                    // the date up into that space is what actually closes it.
                    spacing: -14

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.timeText
                        color: root.cText
                        font.family: "Adwaita Sans"
                        font.pixelSize: 88
                        font.weight: 800
                        font.letterSpacing: 0
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.dateText
                        color: root.cMuted
                        font.family: "Noto Sans"
                        font.pixelSize: 15
                    }
                }

                // Credentials. No card behind them on purpose — the fields and
                // button carry their own surfaces, so a wrapper just boxed them
                // in and hid the backdrop.
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 324
                    implicitHeight: cardCol.implicitHeight

                    // Focus follows the phase: the username field on arrival and
                    // whenever we drop back to it, the password field the moment
                    // greetd asks for a secret.
                    Connections {
                        target: root
                        function onAwaitingResponseChanged() {
                            passInput.text = "";
                            if (root.awaitingResponse) passInput.forceActiveFocus();
                            else userInput.forceActiveFocus();
                        }
                    }

                    Column {
                        id: cardCol
                        anchors.centerIn: parent
                        width: parent.width
                        spacing: 12

                        // Once greetd asks for a secret the username becomes a
                        // label. The label lives in a slot that animates from
                        // zero height, and the field below is a SINGLE element
                        // shared by both phases rather than two that swap. That
                        // is what makes the field slide down instead of being
                        // destroyed and re-created somewhere else.
                        Item {
                            width: parent.width
                            height: root.awaitingResponse ? userLabel.implicitHeight + 8 : 0
                            clip: true

                            Behavior on height {
                                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                            }

                            Text {
                                id: userLabel
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: root.username
                                color: root.cText
                                font.family: "Adwaita Sans"
                                font.pixelSize: 24
                                font.weight: 800
                                font.letterSpacing: 1.0
                                elide: Text.ElideRight

                                opacity: root.awaitingResponse ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 220 } }
                            }
                        }

                        // ---- the field, shared by both phases ----
                        Rectangle {
                            width: parent.width
                            height: 46
                            radius: 0
                            color: root.cField
                            border.width: 3
                            border.color: (userInput.activeFocus || passInput.activeFocus)
                                          ? root.cAccent
                                          : Qt.rgba(1, 1, 1, 0.09)

                            Behavior on border.color { ColorAnimation { duration: 130 } }

                            Text {
                                anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                                text: root.awaitingResponse
                                      ? (root.promptText.length > 0 ? root.promptText : "Password")
                                      : "Username"
                                color: root.cMuted
                                font.family: "Noto Sans"
                                font.pixelSize: 14
                                visible: root.awaitingResponse ? passInput.text.length === 0
                                                               : userInput.text.length === 0
                            }

                            TextInput {
                                id: userInput
                                anchors {
                                    left: parent.left; right: parent.right
                                    leftMargin: 14; rightMargin: 14
                                    verticalCenter: parent.verticalCenter
                                }
                                color: root.cText
                                font.family: "Noto Sans"
                                font.pixelSize: 14
                                clip: true
                                selectByMouse: true
                                selectionColor: root.cAccent
                                selectedTextColor: root.cField

                                // Cross-fades with the password input rather than
                                // toggling visible, so the swap inside the field
                                // is as smooth as the movement of the field.
                                opacity: root.awaitingResponse ? 0 : 1
                                enabled: !root.awaitingResponse
                                Behavior on opacity { NumberAnimation { duration: 160 } }

                                Component.onCompleted: forceActiveFocus()
                                onAccepted: submit.activate()
                            }

                            TextInput {
                                id: passInput
                                anchors {
                                    left: parent.left; right: parent.right
                                    leftMargin: 14; rightMargin: 14
                                    verticalCenter: parent.verticalCenter
                                }
                                color: root.cText
                                font.family: "Noto Sans"
                                font.pixelSize: 14
                                clip: true
                                selectByMouse: true
                                selectionColor: root.cAccent
                                selectedTextColor: root.cField
                                // greetd tells us whether the response may echo.
                                echoMode: root.promptEcho ? TextInput.Normal : TextInput.Password

                                opacity: root.awaitingResponse ? 1 : 0
                                enabled: root.awaitingResponse
                                Behavior on opacity { NumberAnimation { duration: 160 } }

                                onAccepted: submit.activate()
                                Keys.onEscapePressed: root.cancelToUsername()
                            }
                        }

                        Text {
                            width: parent.width
                            text: root.errorText.length > 0 ? root.errorText : root.infoText
                            color: root.errorText.length > 0 ? root.cDanger : root.cMuted
                            font.family: "Noto Sans"
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            visible: text.length > 0
                        }

                        // ---- log in ----
                        // Wrapped in an Item so the block can move on press
                        // without fighting its anchors, and so the shadow is
                        // positioned relative to the WRAPPER rather than to a
                        // block whose anchors.right puts its x far from zero.
                        // Deriving the shadow from that x threw it clean across
                        // the card and over the username field.
                        Item {
                            anchors.right: parent.right
                            width: 132 + root.shadowOff
                            height: 48 + root.shadowOff

                            Rectangle {
                                x: root.shadowOff
                                y: root.shadowOff
                                width: 132
                                height: 48
                                color: root.cShadow
                                antialiasing: false
                                visible: !mouse.containsPress
                            }

                        Rectangle {
                            id: submit
                            width: 132
                            height: 48
                            radius: 0
                            antialiasing: false

                            // One flat colour. The glass theme faded between
                            // three; this style has no fades, so press is shown
                            // by displacement instead.
                            color: root.cAccent
                            border.width: 3
                            border.color: root.cInk

                            x: mouse.containsPress ? root.shadowOff : 0
                            y: mouse.containsPress ? root.shadowOff : 0
                            Behavior on x { NumberAnimation { duration: 70 } }
                            Behavior on y { NumberAnimation { duration: 70 } }

                            function activate() {
                                if (root.awaitingResponse) {
                                    Greetd.respond(passInput.text);
                                    passInput.text = "";
                                } else {
                                    root.username = userInput.text;
                                    root.beginAuth();
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "LOG IN"
                                color: root.cOnAccent
                                font.family: "Adwaita Sans"
                                font.pixelSize: 19
                                font.weight: 600
                                font.letterSpacing: 1.4
                            }

                            MouseArea {
                                id: mouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: submit.activate()
                            }
                        }
                        }
                    }
                }
            }

            // ---- session picker, bottom-left ----
            Item {
                visible: panel.primary
                anchors {
                    left: parent.left
                    bottom: parent.bottom
                    leftMargin: 28
                    bottomMargin: 26
                }
                width: pickerBox.width
                height: pickerBox.height

                Rectangle {
                    id: pickerBox
                    width: 210
                    height: 40
                    radius: 0
                    color: pickerMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.09)
                                                     : Qt.rgba(1, 1, 1, 0.05)
                    border.width: 3
                    border.color: root.cInk

                    Behavior on color { ColorAnimation { duration: 130 } }

                    Text {
                        anchors { left: parent.left; leftMargin: 13; verticalCenter: parent.verticalCenter }
                        text: root.session
                        color: root.cText
                        font.family: "Noto Sans"
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        width: parent.width - 42
                    }

                    Text {
                        anchors { right: parent.right; rightMargin: 13; verticalCenter: parent.verticalCenter }
                        text: menu.visible ? "▴" : "▾"
                        color: root.cMuted
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: pickerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: menu.visible = !menu.visible
                    }
                }

                // Opens upward so it never runs off the bottom of the screen.
                Rectangle {
                    id: menu
                    visible: false
                    anchors { left: parent.left; bottom: pickerBox.top; bottomMargin: 6 }
                    width: pickerBox.width
                    height: menuCol.implicitHeight + 10
                    radius: 0
                    color: root.cSunk
                    border.width: 3
                    border.color: root.cInk

                    Column {
                        id: menuCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 5 }

                        Repeater {
                            model: root.sessions

                            Rectangle {
                                required property int index
                                required property string modelData

                                width: menuCol.width
                                height: 34
                                color: itemMouse.containsMouse ? root.cAccent
                                                               : "transparent"

                                Text {
                                    anchors { left: parent.left; leftMargin: 13; verticalCenter: parent.verticalCenter }
                                    text: modelData
                                    color: index === root.sessionIndex ? root.cAccent : root.cText
                                    font.family: "Noto Sans"
                                    font.pixelSize: 13
                                }

                                MouseArea {
                                    id: itemMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.sessionIndex = index;
                                        menu.visible = false;
                                        input.forceActiveFocus();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
