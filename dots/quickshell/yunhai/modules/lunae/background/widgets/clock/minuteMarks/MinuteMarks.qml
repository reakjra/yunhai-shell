pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import QtQuick

Item {
    id: root

    property color color: Appearance.colors.colOnSecondaryContainer
    property string style: Config.options.background.widgets.clock.cookie.dialNumberStyle
    property string dateStyle : Config.options.background.widgets.clock.cookie.dateStyle

    FadeLoader {
        id: dotsLoader
        anchors {
            fill: parent
            margins: 10
        }
        shown: root.style === "dots"
        sourceComponent: Dots {
            color: root.color
            margins: 46 - dotsLoader.opacity * 34
        }
    }

    FadeLoader {
        id: bigHourNumbersLoader
        anchors.fill: parent
        shown: root.style === "numbers"
        sourceComponent: BigHourNumbers {
            numberSize: 80
            color: root.color
            margins: 20 - 10 * bigHourNumbersLoader.opacity
        }
    }

    FadeLoader {
        id: linesLoader
        anchors {
            fill: parent
            margins: 10
        }
        shown: root.style === "full"
        sourceComponent: Lines {
            color: root.color
            margins: 46 - linesLoader.opacity * 34
        }
    }
    
}
