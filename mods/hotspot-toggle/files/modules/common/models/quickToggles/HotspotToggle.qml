import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import Quickshell
import Quickshell.Io

// Quick toggle that starts/stops a Wi-Fi hotspot through ~/.local/bin/ii-hotspot
// (installed by the hotspot-toggle mod). Settings: ~/.config/ii-mods/hotspot.conf
QuickToggleModel {
    id: root
    name: Translation.tr("Hotspot")

    toggled: false
    available: true
    icon: "wifi_tethering"
    tooltipText: Translation.tr("Wi-Fi hotspot (create_ap)")

    readonly property string helper: Quickshell.env("HOME") + "/.local/bin/ii-hotspot"

    mainAction: () => {
        if (root.toggled) {
            stopProc.running = true
        } else {
            startProc.running = true
        }
    }

    Process {
        id: startProc
        command: [root.helper, "start"]
        onExited: (exitCode, exitStatus) => checkProc.running = true
    }

    Process {
        id: stopProc
        command: [root.helper, "stop"]
        onExited: (exitCode, exitStatus) => checkProc.running = true
    }

    // exit code 0 = hotspot is running
    Process {
        id: checkProc
        command: [root.helper, "status"]
        onExited: (exitCode, exitStatus) => root.toggled = (exitCode === 0)
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: checkProc.running = true
    }
}
