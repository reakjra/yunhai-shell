import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ListView {
    id: root
    required property var directory

    signal navigateToDirectory(string path)

    orientation: ListView.Horizontal
    clip: true
    spacing: 2

    property var pathParts: directory.split("/").filter(part => part.length > 0)

    model: pathParts.length > 0 ? pathParts : ["/"]

    delegate: SelectionGroupButton {
        id: folderButton
        required property var modelData
        required property int index

        buttonText: {
            if (pathParts.length === 0) return "/";
            if (index === 0) return "/" + modelData;
            return modelData;
        }

        toggled: index === pathParts.length - 1
        leftmost: index === 0
        rightmost: index === (pathParts.length > 0 ? pathParts.length - 1 : 0)

        onClicked: {
            if (pathParts.length === 0) {
                root.navigateToDirectory("/");
            } else {
                const path = "/" + pathParts.slice(0, index + 1).join("/");
                root.navigateToDirectory(path);
            }
        }
    }
}
