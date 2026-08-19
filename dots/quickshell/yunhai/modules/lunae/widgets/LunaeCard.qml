import QtQuick
import qs.modules.common

Rectangle {
    property bool inner: false

    radius: inner ? Appearance.rounding.small : Appearance.rounding.normal
    color: inner ? Appearance.colors.colLayer2 : Appearance.colors.colLayer1
}
