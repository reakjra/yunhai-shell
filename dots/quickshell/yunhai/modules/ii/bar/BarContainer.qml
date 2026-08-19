import qs.modules.common
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property bool isBarFloating: Config.options.bar.cornerStyle === 1
    property bool isBorderless: Config.options.bar.borderless

    property bool vertical: false
    property bool extendHeight: false
    property bool extendWidth: false
    property var sourceComp 

    property int padding: isBarFloating ? 10 : 5
    property real heightExtendMultiplier: isBarFloating ? 1.2 : 1.5
    property real widthExtendMultiplier: isBarFloating ? 1.5 : 2

    property bool leftMost: false
    property bool rightMost: false

    implicitHeight: vertical ? isBorderless ? sourceComp.implicitHeight + padding * 2 : extendHeight ? sourceComp.implicitHeight * root.heightExtendMultiplier + padding * 2 : sourceComp.implicitHeight + padding * 2 : Appearance.sizes.barHeight - padding * 2
    implicitWidth: vertical ?  Appearance.sizes.barHeight - padding * 2 : extendWidth ? sourceComp.implicitWidth * root.widthExtendMultiplier + padding * 2 : sourceComp.implicitWidth + padding * 2
    
    color: Config.options?.bar.borderless ? "transparent" : Appearance.colors.colSurfaceContainerHigh

    topLeftRadius: root.leftMost ? height / 2 : Appearance.rounding.verysmall
    bottomLeftRadius: root.vertical ?  root.rightMost ? height / 2 : Appearance.rounding.verysmall : root.leftMost ? height / 2 : Appearance.rounding.verysmall
    topRightRadius: root.vertical ?  root.leftMost ? height / 2 : Appearance.rounding.verysmall : root.rightMost ? height / 2 : Appearance.rounding.verysmall
    bottomRightRadius: root.rightMost ? height / 2 : Appearance.rounding.verysmall
}