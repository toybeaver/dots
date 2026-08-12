// Session lock for this setup. Bound to Super+ESC. Not themed — it is its own
// config and does not change with the shell theme.
//
// Uses ext-session-lock-v1 via WlSessionLock, not a layer-shell overlay. That
// distinction is the whole point: the compositor blanks every output itself and
// refuses to reveal the session until this client calls unlock(). A layer-shell
// "lockscreen" is bypassed by killing the process.
//
// The corollary is that this is FAIL-SECURE. If this process dies while locked,
// the session stays locked and the only way back is a TTY (Ctrl+Alt+F2) and
// `loginctl unlock-session`. Treat edits here with the same care as the greeter.
//
// THE UNLOCK SEQUENCE IS LOAD-BEARING. An earlier version did:
//
//     lock.unlock(); Qt.quit();
//
// which hard-froze the machine on a *correct* password. Wayland requests are
// asynchronous: Qt.quit() tore the process down before the unlock request was
// flushed, leaving the compositor holding a locked session whose client was
// dead — unrecoverable without a power cycle. Never quit until lockStateChanged
// reports locked == false. Everything below is built around that.
//
// The look deliberately mirrors the password phase of the greetd greeter at
// /etc/greetd/quickshell/shell.qml — clock, username as a label, password field.
// The two CANNOT share code: the greeter runs as the `greeter` user, which
// cannot read anything under /home (0700). So this is an intentional duplicate,
// and a visual change to one wants the same change made to the other.
//
// Differences from the greeter, by request:
//   - no session picker
//   - no way back to a username field; the user is fixed
//
// Only QtQuick — no QtQuick.Controls, same reasoning as the greeter.

import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick

ShellRoot {
    id: root

    // ---- palette (kept in step with the greeter) ----
    // Ink on paper: the card is a white block, its border and shadow both black.
    readonly property color cBase:     "#f4f1e8"
    readonly property color cField:    "#ffffff"
    readonly property color cText:     "#000000"
    readonly property color cMuted:    "#57534a"
    readonly property color cAccent:   "#a78bfa"
    readonly property color cDanger:   "#ff4d4d"

    // Brutalist additions: the hard border and the hard offset shadow. Named
    // rather than inline so the greeter copy of this file stays diffable.
    readonly property color cInk:      "#000000"
    readonly property color cShadow:   "#000000"
    readonly property color cOnAccent: "#000000"
    readonly property int   shadowOff: 6

    readonly property string username: Quickshell.env("USER") || "user"

    // ---- auth state ----
    property string promptText: ""
    property bool promptEcho: false      // PAM says whether the reply may echo
    property bool awaitingResponse: false
    property bool checking: false
    property bool unlocking: false
    property string errorText: ""
    // Shown only if an unlock somehow does not complete, so a wedged lock tells
    // the user how to get out instead of just sitting there.
    property string stuckText: ""

    // Drives WlSessionLock.locked. This MUST be a mutable property, not a
    // literal `locked: true` on the lock itself. A literal is a QML binding, and
    // the binding re-asserts true the instant unlock() changes it — so unlock()
    // silently does nothing. Combined with quitting straight afterwards, that is
    // what froze the machine: the client died while the compositor still
    // considered the session locked.
    property bool wantLocked: true

    // Did PAM actually ask us anything this transaction? If a transaction fails
    // without ever prompting, retrying immediately just hammers it — which is
    // exactly what faillock does once the account is locked out. Tracked so the
    // retry can back off instead of spinning.
    property bool promptedThisTry: false
    property int noPromptFailures: 0

    PamContext {
        id: pam

        // /etc/pam.d/login — the system's real auth stack. Works unprivileged
        // because pam_unix delegates the shadow lookup to the setuid
        // /usr/bin/unix_chkpwd, so the lock needs no root and no new pam.d file.
        config: "login"
        user: root.username

        // pamMessage carries no arguments; the details are on the context.
        onPamMessage: {
            if (pam.responseRequired) {
                root.promptedThisTry = true;
                root.promptText = pam.message;
                root.promptEcho = pam.responseVisible;
                root.awaitingResponse = true;
                root.checking = false;
            } else if (pam.messageIsError) {
                root.errorText = pam.message;
            }
        }

        onCompleted: result => {
            root.checking = false;

            if (result === PamResult.Success) {
                // Request the unlock and STOP. Quitting happens only once the
                // compositor confirms the lock is released — see lock below.
                root.unlocking = true;
                stuckWatchdog.restart();
                root.wantLocked = false;
                return;
            }

            root.awaitingResponse = false;

            if (result === PamResult.MaxTries) {
                root.errorText = "Too many attempts — locked out for a while";
            } else if (result === PamResult.Failed) {
                root.errorText = "Incorrect password";
            } else {
                root.errorText = "Authentication error";
            }

            // A finished transaction cannot be reused; open a fresh one so the
            // next attempt gets its own prompt. Back off when PAM never asked
            // for anything — measured at 13 retries in 6s without this.
            if (root.promptedThisTry) {
                root.noPromptFailures = 0;
                retry.interval = 400;
            } else {
                root.noPromptFailures += 1;
                retry.interval = Math.min(30000, 3000 * root.noPromptFailures);
                root.errorText = "Account temporarily locked — wait and try again";
            }
            retry.restart();
        }

        onError: err => {
            root.checking = false;
            root.errorText = "PAM error: " + PamError.toString(err);
            retry.restart();
        }
    }

    Timer {
        id: retry
        interval: 400
        repeat: false
        onTriggered: root.startAuth()
    }

    // The ONLY place that quits. Armed by lockStateChanged once the compositor
    // reports the session unlocked; the small delay lets the final frame land.
    Timer {
        id: byeTimer
        interval: 250
        repeat: false
        onTriggered: Qt.quit()
    }

    // If the unlock never lands, say so on screen. The session is still locked
    // at that point, so this message is the only way the user learns the way
    // out without a power cycle.
    Timer {
        id: stuckWatchdog
        interval: 4000
        repeat: false
        onTriggered: {
            if (!root.unlocking) return;
            root.stuckText = "Unlock did not complete. Switch to a TTY with "
                           + "Ctrl+Alt+F2 and run:  loginctl unlock-session";
        }
    }

    // `checking` must never stick. If PAM neither completes nor re-prompts, give
    // the field back rather than leaving a dead form on a locked screen.
    Timer {
        id: checkWatchdog
        interval: 10000
        repeat: false
        onTriggered: {
            if (!root.checking) return;
            root.checking = false;
            root.awaitingResponse = false;
            root.errorText = "Authentication timed out — try again";
            retry.restart();
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

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.tick()
    }

    function startAuth() {
        promptedThisTry = false;
        pam.start();
    }

    Component.onCompleted: {
        tick();
        startAuth();
    }

    WlSessionLock {
        id: lock
        locked: root.wantLocked

        // Quitting is gated on this. locked == false means the compositor has
        // processed the unlock and the session is visible again; only then is it
        // safe for this process to go away. See the header for what happens if
        // you quit earlier.
        onLockStateChanged: {
            if (!lock.locked) byeTimer.start();
        }

        WlSessionLockSurface {
            id: surface
            color: "transparent"

            // ---- backdrop ----
            Rectangle {
                anchors.fill: parent
                color: root.cBase

                // Full strength and no gradient veil, unlike the glass theme.
                // This wallpaper is already a flat field with a couple of
                // outlined blocks on it; dimming it would only mud a surface
                // that is deliberately flat.
                Image {
                    anchors.fill: parent
                    source: "file:///home/toyb/Pictures/wallpaper/brutal-light.png"
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 34

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    // Negative on purpose — see the greeter. At 88px the clock's
                    // line box reserves a lot of empty descender space, so the
                    // visible gap is font metrics rather than spacing.
                    spacing: -14

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.timeText
                        // cText, not a hardcoded white. The glass theme could
                        // assume white was always legible because its backdrop
                        // was dimmed to near-black; this one shows the wallpaper
                        // at full strength, and on the light twin's paper a
                        // white clock simply disappears.
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

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 324
                    implicitHeight: col.implicitHeight

                    Column {
                        id: col
                        anchors.centerIn: parent
                        width: parent.width
                        spacing: 12

                        // The user is fixed here — no field to go back to.
                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: root.username
                            color: root.cText
                            font.family: "Adwaita Sans"
                            font.pixelSize: 24
                            font.weight: 800
                            font.letterSpacing: 1.0
                            elide: Text.ElideRight
                        }

                        // The field is a hard block with an offset shadow, like
                        // every surface the shell draws. The shadow is a sibling
                        // rectangle rather than a blur — see brutal/BrutalSurface.qml.
                        Rectangle {
                            width: parent.width - root.shadowOff
                            height: 52
                            radius: 0
                            antialiasing: false
                            color: root.cField
                            border.width: 3
                            border.color: input.activeFocus ? root.cAccent : root.cInk

                            Behavior on border.color { ColorAnimation { duration: 130 } }

                            // Drawn behind, offset down-right. z keeps it under
                            // the block without reordering the Column.
                            Rectangle {
                                z: -1
                                x: root.shadowOff
                                y: root.shadowOff
                                width: parent.width
                                height: parent.height
                                color: root.cShadow
                                antialiasing: false
                            }

                            Text {
                                anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                                text: root.promptText.length > 0 ? root.promptText : "Password"
                                color: root.cMuted
                                font.family: "Noto Sans"
                                font.pixelSize: 14
                                visible: input.text.length === 0
                            }

                            TextInput {
                                id: input
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
                                echoMode: root.promptEcho ? TextInput.Normal : TextInput.Password
                                enabled: root.awaitingResponse && !root.checking

                                Component.onCompleted: forceActiveFocus()

                                // Escape only clears the field. There is nowhere
                                // to go back to, and it must never dismiss the
                                // lock.
                                Keys.onEscapePressed: input.text = ""

                                onAccepted: submit.activate()

                                Connections {
                                    target: root
                                    function onAwaitingResponseChanged() {
                                        if (root.awaitingResponse) input.forceActiveFocus();
                                    }
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            text: root.stuckText.length > 0 ? root.stuckText
                                : root.unlocking                ? "Unlocking…"
                                : root.checking                 ? "Checking…"
                                : root.errorText
                            color: (root.checking || root.unlocking) && root.stuckText.length === 0
                                   ? root.cMuted : root.cDanger
                            font.family: "Noto Sans"
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            visible: text.length > 0
                        }

                        // Wrapped in an Item so the block can move on press
                        // without fighting its own anchors. An earlier version
                        // set x/y directly on an anchors.right-ed Rectangle and
                        // derived the shadow from that x — which, because the
                        // anchor put x far from zero, threw the shadow across
                        // the card and over the username.
                        Item {
                            anchors.right: parent.right
                            width: 138 + root.shadowOff
                            height: 52 + root.shadowOff
                            opacity: root.awaitingResponse && !root.checking ? 1 : 0.45
                            Behavior on opacity { NumberAnimation { duration: 130 } }

                            Rectangle {
                                x: root.shadowOff
                                y: root.shadowOff
                                width: 138
                                height: 52
                                color: root.cShadow
                                antialiasing: false
                                visible: !mouse.containsPress
                            }

                            Rectangle {
                                id: submit

                                // Pressing moves the block onto its shadow, the
                                // same displacement the shell's tiles use. No
                                // fade, no glow.
                                x: mouse.containsPress ? root.shadowOff : 0
                                y: mouse.containsPress ? root.shadowOff : 0
                                width: 138
                                height: 52
                                radius: 0
                                antialiasing: false

                                color: root.cAccent
                                border.width: 3
                                border.color: root.cInk

                                Behavior on x { NumberAnimation { duration: 70 } }
                                Behavior on y { NumberAnimation { duration: 70 } }

                                function activate() {
                                    if (!root.awaitingResponse || root.checking) return;
                                    root.errorText = "";
                                    root.checking = true;
                                    checkWatchdog.restart();
                                    pam.respond(input.text);
                                    input.text = "";
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "UNLOCK"
                                    color: root.cOnAccent
                                    font.family: "Adwaita Sans"
                                    font.pixelSize: 19
                                    font.weight: 800
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
        }
    }
}
