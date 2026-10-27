import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

HeroCard {
    id: root

    title: Translation.tr("Night light")
    subtitle: {
        if (!Hyprsunset.automatic)
            return Hyprsunset.temperatureActive ? Translation.tr("On") : Translation.tr("Off");
        return Hyprsunset.temperatureActive ? Translation.tr("On until %1").arg(Hyprsunset.to) : Translation.tr("Off until %1").arg(Hyprsunset.from);
    }
    switchChecked: Hyprsunset.temperatureActive
    onSwitchToggled: checked => Hyprsunset.toggleTemperature(checked)

    glyph: MaterialSymbol {
        anchors.centerIn: parent
        text: Hyprsunset.automatic ? "night_sight_auto" : "bedtime"
        iconSize: root.glyphSize
        fill: Hyprsunset.temperatureActive ? 1 : 0
        color: Appearance.colors.colOnPrimaryContainer
    }

    Flow {
        Layout.fillWidth: true
        spacing: 6

        Pill {
            icon: "thermostat"
            text: `${Hyprsunset.colorTemperature}K`
        }
        Pill {
            visible: Hyprsunset.gamma !== 100
            icon: "contrast"
            text: Translation.tr("Gamma %1%").arg(Hyprsunset.gamma)
        }
    }
}
