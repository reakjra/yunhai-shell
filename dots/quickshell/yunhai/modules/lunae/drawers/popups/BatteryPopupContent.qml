pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.lunae.bar

ColumnLayout {
    id: root
    spacing: 4

    StyledPopupHeaderRow {
        icon: "battery_android_full"
        label: Translation.tr("Battery")
    }

    StyledPopupValueRow {
        visible: {
            let timeValue = Battery.isCharging ? Battery.timeToFull : Battery.timeToEmpty;
            let power = Battery.energyRate;
            return !(Battery.chargeState == 4 || timeValue <= 0 || power <= 0.01);
        }
        icon: "schedule"
        label: Battery.isCharging ? Translation.tr("Time to full:") : Translation.tr("Time to empty:")
        value: {
            function formatTime(seconds) {
                var h = Math.floor(seconds / 3600);
                var m = Math.floor((seconds % 3600) / 60);
                if (h > 0)
                    return `${h}h, ${m}m`;
                else
                    return `${m}m`;
            }
            if (Battery.isCharging)
                return formatTime(Battery.timeToFull);
            else
                return formatTime(Battery.timeToEmpty);
        }
    }

    StyledPopupValueRow {
        visible: !(Battery.chargeState != 4 && Battery.energyRate == 0)
        icon: "bolt"
        label: {
            if (Battery.chargeState == 4)
                return Translation.tr("Fully charged");
            else if (Battery.chargeState == 1)
                return Translation.tr("Charging:");
            else
                return Translation.tr("Discharging:");
        }
        value: Battery.chargeState == 4 ? "" : `${Battery.energyRate.toFixed(2)}W`
    }

    StyledPopupValueRow {
        icon: "heart_check"
        label: Translation.tr("Health:")
        value: `${(Battery.health).toFixed(1)}%`
    }
}
