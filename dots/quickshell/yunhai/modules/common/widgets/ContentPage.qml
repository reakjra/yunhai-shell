import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

StyledFlickable {
    id: root
    property real baseWidth: 600
    property bool forceWidth: false
    property real bottomContentPadding: 100

    default property alias data: contentColumn.data

    property string pendingSectionId: ""
    readonly property int sectionSettleInterval: 50
    readonly property int sectionSettleTicks: 3

    clip: true
    contentHeight: contentColumn.implicitHeight + root.bottomContentPadding // Add some padding at the bottom
    implicitWidth: contentColumn.implicitWidth

    function scrollToSection(id) {
        if (!id)
            return;
        root.pendingSectionId = id;
        sectionSettleTimer.restart();
    }

    function findSection(item, id) {
        for (var i = 0; i < item.children.length; i++) {
            const child = item.children[i];
            if (child.sectionId === id)
                return child;
            const found = root.findSection(child, id);
            if (found)
                return found;
        }
        return null;
    }

    Timer {
        id: sectionSettleTimer
        interval: root.sectionSettleInterval
        repeat: true
        property real lastHeight: -1
        property int stableTicks: 0

        onTriggered: {
            if (root.contentHeight !== lastHeight) {
                lastHeight = root.contentHeight;
                stableTicks = 0;
                return;
            }
            stableTicks += 1;
            if (stableTicks < root.sectionSettleTicks)
                return;

            stop();
            lastHeight = -1;
            stableTicks = 0;

            const target = root.findSection(contentColumn, root.pendingSectionId);
            root.pendingSectionId = "";
            if (!target)
                return;

            const targetY = target.mapToItem(contentColumn, 0, 0).y - contentColumn.anchors.margins;
            sectionScrollAnimation.to = Math.max(0, Math.min(targetY, root.contentHeight - root.height));
            sectionScrollAnimation.restart();
        }
    }

    NumberAnimation {
        id: sectionScrollAnimation
        target: root
        property: "contentY"
        duration: Appearance.animation.elementMove.duration
        easing.type: Appearance.animation.elementMove.type
        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
    }

    ColumnLayout {
        id: contentColumn
        width: SettingsStyle.grouped ? undefined : (root.forceWidth ? root.baseWidth : Math.max(root.baseWidth, implicitWidth))
        anchors {
            top: parent.top
            left: SettingsStyle.grouped ? parent.left : undefined
            right: SettingsStyle.grouped ? parent.right : undefined
            horizontalCenter: SettingsStyle.grouped ? undefined : parent.horizontalCenter
            margins: SettingsStyle.grouped ? 6 : 20
        }
        spacing: SettingsStyle.grouped ? 18 : 30
    }

}
