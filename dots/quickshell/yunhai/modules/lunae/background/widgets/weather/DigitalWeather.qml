pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.lunae.background.widgets.clock
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: -10

    property color colText: Appearance.colors.colOnSecondaryContainer

    readonly property var weatherConfig: Config.options.background.widgets.weather.digital
    readonly property real fontSize: root.weatherConfig.font.size
    readonly property bool cityBelow: root.weatherConfig.cityBelow

    property font tempFont
    tempFont {
        pixelSize: root.fontSize
        weight: root.weatherConfig.font.weight
        family: root.weatherConfig.font.family
        variableAxes: ({
            "wdth": root.weatherConfig.font.width,
            "ROND": root.weatherConfig.font.roundness
        })
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 4

        ClockText {
            visible: root.weatherConfig.showCity && !root.cityBelow
            Layout.fillWidth: false
            animateChange: false
            text: Weather.data?.city ?? ""
            color: root.colText
            font: root.tempFont
            Layout.rightMargin: root.fontSize * 0.15
        }

        ClockText {
            Layout.fillWidth: false
            animateChange: false
            text: Weather.data?.temp ?? "--°"
            color: root.colText
            font: root.tempFont
        }

        MaterialSymbol {
            visible: root.weatherConfig.showIcon
            Layout.alignment: Qt.AlignVCenter
            iconSize: root.fontSize * 0.8
            color: root.colText
            text: Icons.getWeatherIcon(Weather.data?.wCode) ?? "cloud"
            style: Text.Raised
            styleColor: Appearance.colors.colShadow
        }
    }

    ClockText {
        visible: root.weatherConfig.showCity && root.cityBelow
        Layout.alignment: Qt.AlignHCenter
        animateChange: false
        text: Weather.data?.city ?? ""
        color: root.colText
        horizontalAlignment: Text.AlignHCenter
        font {
            pixelSize: Appearance.font.pixelSize.large
            weight: Font.Normal
        }
    }
}
