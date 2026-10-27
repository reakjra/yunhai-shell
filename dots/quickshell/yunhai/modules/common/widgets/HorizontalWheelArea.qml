import QtQuick

MouseArea {
    id: root

    required property Flickable flickable
    property real targetX: 0

    acceptedButtons: Qt.NoButton

    onWheel: event => {
        if (!scrollAnim.running)
            root.targetX = root.flickable.contentX;
        root.targetX = Math.max(0, Math.min(root.flickable.contentWidth - root.flickable.width, root.targetX - event.angleDelta.y));
        scrollAnim.stop();
        scrollAnim.from = root.flickable.contentX;
        scrollAnim.to = root.targetX;
        scrollAnim.restart();
        event.accepted = true;
    }

    NumberAnimation {
        id: scrollAnim
        target: root.flickable
        property: "contentX"
        duration: 300
        easing.type: Easing.OutCubic
    }
}
