pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQml.Models

import qs.services
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root

    Layout.fillWidth: true
    implicitHeight: listModel.length * 38 + 36 + 16 + 6

    color: "transparent"
    radius: Appearance.rounding.normal

    property var listModel
    property var sourceListModel
    property int selectedCompIndex

    signal updated(var newList)
    signal sourceUpdated(var newList)

    DelegateModel {
        id: visualModel
        model: { values: root.listModel }
        delegate: ConfigListViewCompactEntry {}
    }

    StyledListView {
        id: view
        interactive: false
        anchors {
            fill: parent
            margins: 6
        }
        add: null
        model: visualModel
        spacing: 2
        cacheBuffer: 50
    }

    RowLayout {
        id: componentSelectRow
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 6
        }
        spacing: 4

        StyledComboBox {
            id: componentSelector
            implicitHeight: 36
            topRightRadius: Appearance.rounding.verysmall
            bottomRightRadius: Appearance.rounding.verysmall
            buttonIcon: "add"
            textRole: "title"
            model: sourceListModel
            enabled: sourceListModel.length >= 1
            onActivated: index => {
                root.selectedCompIndex = index;
            }
        }

        RippleButton {
            implicitHeight: 36
            topLeftRadius: Appearance.rounding.verysmall
            bottomLeftRadius: Appearance.rounding.verysmall
            topRightRadius: Appearance.rounding.full
            bottomRightRadius: Appearance.rounding.full
            buttonText: Translation.tr("Add")
            enabled: sourceListModel.length >= 1
            colBackground: Appearance.colors.colSecondaryContainer
            colBackgroundHover: Appearance.colors.colSecondaryContainerHover
            rippleColor: Appearance.colors.colSecondaryContainerActive
            onClicked: {
                if (sourceListModel[root.selectedCompIndex] == null) {
                    sourceListModel.splice(root.selectedCompIndex, 1);
                    root.sourceUpdated(sourceListModel);
                    return;
                }
                listModel.push(sourceListModel[root.selectedCompIndex]);
                sourceListModel.splice(root.selectedCompIndex, 1);
                root.sourceUpdated(sourceListModel);
                root.updated(listModel);
            }
        }
    }
}
