import QtQuick
import QtQuick.Effects
import Quickshell.Services.Mpris
import qs.modules.common

// A small "now playing" card for the lock screen.
// - Reads whatever MPRIS player is active (Spotify, Firefox, mpv, ...).
// - Colours come from Appearance.m3colors, i.e. the Material You palette that
//   is generated from your current wallpaper, so it follows theme changes.
// - Hides itself when nothing is playing or paused.
Item {
    id: root

    // ---- player selection -------------------------------------------------
    // Prefer a player that is playing; otherwise the first one with a title.
    function pickPlayer() {
        const list = Mpris.players.values
        let fallback = null
        for (let i = 0; i < list.length; i++) {
            const p = list[i]
            if (!p.trackTitle || p.trackTitle.length === 0) continue
            if (p.isPlaying) return p
            if (fallback === null) fallback = p
        }
        return fallback
    }

    property var player: pickPlayer()
    readonly property bool shown: player !== null && player !== undefined

    // ---- theme -------------------------------------------------------------
    readonly property var c: Appearance.m3colors
    readonly property string uiFont: (Appearance.font && Appearance.font.family && Appearance.font.family.main)
        ? Appearance.font.family.main : "sans-serif"
    readonly property string symbolFont: "Material Symbols Rounded"

    // ---- geometry ----------------------------------------------------------
    implicitWidth: 360
    implicitHeight: 92
    width: implicitWidth
    height: implicitHeight

    opacity: shown ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    transform: Translate {
        y: root.shown ? 0 : 14
        Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
    }

    // keep the progress bar fresh while playing (MPRIS does not push position)
    Timer {
        interval: 1000
        repeat: true
        running: root.shown && root.visible && root.player !== null && root.player.isPlaying
        onTriggered: root.player.positionChanged()
    }

    // ---- card ---------------------------------------------------------------
    Rectangle {
        id: card
        anchors.fill: parent
        radius: 30
        color: Qt.alpha(root.c.m3surfaceContainer, 0.80)
        border.width: 1
        border.color: Qt.alpha(root.c.m3outlineVariant, 0.55)
    }

    // ---- album art ----------------------------------------------------------
    Item {
        id: artBox
        width: 68
        height: 68
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter

        Image {
            id: artImage
            anchors.fill: parent
            visible: false
            asynchronous: true
            cache: true
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 136
            sourceSize.height: 136
            source: (root.player && root.player.trackArtUrl) ? root.player.trackArtUrl : ""
        }

        Rectangle {
            id: artMask
            anchors.fill: parent
            radius: 22
            visible: false
            layer.enabled: true
        }

        MultiEffect {
            anchors.fill: parent
            source: artImage
            maskEnabled: true
            maskSource: artMask
            visible: artImage.status === Image.Ready
        }

        // placeholder when there is no cover art
        Rectangle {
            anchors.fill: parent
            radius: 22
            visible: artImage.status !== Image.Ready
            color: root.c.m3primaryContainer

            Text {
                anchors.centerIn: parent
                text: "music_note"
                font.family: root.symbolFont
                font.pixelSize: 30
                color: root.c.m3onPrimaryContainer
            }
        }
    }

    // ---- title / artist / progress -----------------------------------------
    Item {
        id: info
        anchors.left: artBox.right
        anchors.leftMargin: 14
        anchors.right: controls.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        height: titleText.height + artistText.height + 14

        Text {
            id: titleText
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            text: root.player ? (root.player.trackTitle || "") : ""
            elide: Text.ElideRight
            maximumLineCount: 1
            font.family: root.uiFont
            font.pixelSize: 15
            font.weight: Font.DemiBold
            color: root.c.m3onSurface
        }

        Text {
            id: artistText
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: titleText.bottom
            anchors.topMargin: 1
            text: root.player ? (root.player.trackArtist || root.player.identity || "") : ""
            elide: Text.ElideRight
            maximumLineCount: 1
            font.family: root.uiFont
            font.pixelSize: 12
            color: root.c.m3onSurfaceVariant
        }

        // thin progress line
        Rectangle {
            id: track
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 3
            radius: 2
            color: Qt.alpha(root.c.m3onSurfaceVariant, 0.25)

            Rectangle {
                height: parent.height
                radius: parent.radius
                color: root.c.m3primary
                width: {
                    const p = root.player
                    if (!p || !p.lengthSupported || !p.positionSupported || p.length <= 0) return 0
                    return parent.width * Math.max(0, Math.min(1, p.position / p.length))
                }
                Behavior on width { NumberAnimation { duration: 900; easing.type: Easing.Linear } }
            }
        }
    }

    // ---- controls -----------------------------------------------------------
    Row {
        id: controls
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        // previous
        Item {
            width: 32; height: 40
            opacity: (root.player && root.player.canGoPrevious) ? 1 : 0.35
            Text {
                anchors.centerIn: parent
                text: "skip_previous"
                font.family: root.symbolFont
                font.pixelSize: 24
                color: root.c.m3onSurface
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: !!(root.player && root.player.canGoPrevious)
                onClicked: root.player.previous()
            }
        }

        // play / pause
        Rectangle {
            id: playButton
            width: 40; height: 40
            radius: root.player && root.player.isPlaying ? 14 : 20
            color: root.c.m3primary
            opacity: (root.player && root.player.canTogglePlaying) ? 1 : 0.5
            Behavior on radius { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            scale: playArea.pressed ? 0.92 : 1
            Behavior on scale { NumberAnimation { duration: 120 } }

            Text {
                anchors.centerIn: parent
                text: (root.player && root.player.isPlaying) ? "pause" : "play_arrow"
                font.family: root.symbolFont
                font.pixelSize: 24
                color: root.c.m3onPrimary
            }
            MouseArea {
                id: playArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: !!(root.player && root.player.canTogglePlaying)
                onClicked: root.player.togglePlaying()
            }
        }

        // next
        Item {
            width: 32; height: 40
            opacity: (root.player && root.player.canGoNext) ? 1 : 0.35
            Text {
                anchors.centerIn: parent
                text: "skip_next"
                font.family: root.symbolFont
                font.pixelSize: 24
                color: root.c.m3onSurface
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: !!(root.player && root.player.canGoNext)
                onClicked: root.player.next()
            }
        }
    }
}
