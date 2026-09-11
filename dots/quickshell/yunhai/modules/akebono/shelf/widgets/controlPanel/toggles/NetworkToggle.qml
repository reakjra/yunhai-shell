import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Quickshell

AkToggle {
    on: Network.wifiStatus !== "disabled"
    icon: Network.materialSymbol
    onClicked: Network.toggleWifi()
    altAction: () => Quickshell.execDetached(["bash", "-c", `${Network.ethernet ? Config.options.apps.networkEthernet : Config.options.apps.network}`])
    StyledToolTip {
        text: Translation.tr("%1 | Right-click for networks, hold to configure").arg(Network.networkName)
    }
}
