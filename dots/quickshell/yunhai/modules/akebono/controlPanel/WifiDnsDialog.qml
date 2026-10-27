import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

WindowDialog {
    id: root

    readonly property var choices: ["auto", ...Network.dnsPresets.map(preset => preset.name), "custom"]
    property string choice: "auto"
    readonly property var customServers: customField.text.split(/[\s,]+/).filter(server => server !== "")
    readonly property bool customValid: root.customServers.length > 0 && root.customServers.every(root.isValidServer)
    readonly property bool canApply: !Network.dnsApplying && (root.choice !== "custom" || root.customValid)

    backgroundWidth: 440

    function isValidServer(server) {
        if (Network.isIpv6(server))
            return Network.ipv6Enabled && /^[0-9a-fA-F:]+$/.test(server) && server.split("::").length <= 2 && server.split(":").length <= 8;
        return /^((25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(25[0-5]|2[0-4]\d|1?\d?\d)$/.test(server);
    }

    function serversFor(choice) {
        if (choice === "auto")
            return [];
        if (choice === "custom")
            return root.customServers;
        return Network.applicableDns(Network.dnsPresets.find(preset => preset.name === choice).servers);
    }

    function labelFor(choice) {
        if (choice === "auto")
            return Translation.tr("Automatic (from the router)");
        if (choice === "custom")
            return Translation.tr("Custom");
        return `${choice} (${root.serversFor(choice).filter(server => !Network.isIpv6(server)).join(", ")})`;
    }

    onShowChanged: {
        if (!root.show)
            return;
        Network.dnsError = "";
        const preset = Network.dnsPresetFor(Network.customDns);
        root.choice = Network.customDns.length === 0 ? "auto" : preset ? preset.name : "custom";
        customField.text = root.choice === "custom" ? Network.customDns.join(", ") : "";
    }

    Connections {
        target: Network

        function onDnsApplyFinished(succeeded) {
            if (succeeded)
                root.dismiss();
        }
    }

    WindowDialogTitle {
        Layout.fillWidth: true
        text: Translation.tr("DNS servers")
    }

    WindowDialogParagraph {
        Layout.fillWidth: true
        text: Translation.tr("For %1, currently using %2.").arg(Network.connectionName).arg(Network.dnsServers.length > 0 ? Network.dnsServers.join(", ") : Translation.tr("none"))
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Repeater {
            model: root.choices
            delegate: StyledRadioButton {
                required property string modelData
                Layout.fillWidth: true
                checkable: false
                description: root.labelFor(modelData)
                checked: root.choice === modelData
                onClicked: root.choice = modelData
            }
        }
    }

    MaterialTextField {
        id: customField
        Layout.fillWidth: true
        visible: root.choice === "custom"
        placeholderText: Network.ipv6Enabled ? "1.1.1.1, 2606:4700:4700::1111" : "1.1.1.1, 9.9.9.9"
        onAccepted: if (root.canApply) Network.setDns(root.serversFor(root.choice))
    }

    WindowDialogParagraph {
        Layout.fillWidth: true
        visible: Network.dnsError !== ""
        text: Translation.tr("Couldn't apply: %1").arg(Network.dnsError)
        color: Appearance.colors.colError
    }

    WindowDialogButtonRow {
        Layout.fillWidth: true

        Item {
            Layout.fillWidth: true
        }
        DialogButton {
            buttonText: Translation.tr("Cancel")
            onClicked: root.dismiss()
        }
        DialogButton {
            buttonText: Translation.tr("Apply")
            enabled: root.canApply
            onClicked: Network.setDns(root.serversFor(root.choice))
        }
    }
}
