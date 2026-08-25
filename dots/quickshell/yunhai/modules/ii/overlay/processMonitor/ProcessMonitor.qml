import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.ii.overlay

StyledOverlayWidget {
    id: root
    minimumWidth: 300
    minimumHeight: 300

    Component.onCompleted: ProcessMonitor.active = Qt.binding(() => root.visible && root.expandedPid === "")
    Component.onDestruction: ProcessMonitor.active = false

    property string searchText: ""
    property string expandedPid: ""

    // Sorting states: 0 = none, 1 = ascending, 2 = descending
    property int sortStateProcess: 0
    property int sortStateCpu: 0
    property int sortStateRam: 0

    Binding {
        target: ProcessMonitor
        property: "filter"
        value: root.searchText.trim()
    }
    Binding {
        target: ProcessMonitor
        property: "sortKey"
        value: root.sortStateProcess !== 0 ? ProcessMonitor.sortByName
            : root.sortStateRam !== 0 ? ProcessMonitor.sortByMemory
            : ProcessMonitor.sortByCpu
    }
    Binding {
        target: ProcessMonitor
        property: "sortDescending"
        value: root.sortStateProcess !== 0 ? root.sortStateProcess !== 1 : root.sortStateCpu !== 0 ? root.sortStateCpu === 1 : root.sortStateRam !== 0 ? root.sortStateRam === 1 : true
    }

    onVisibleChanged: {
        if (!root.visible)
            root.expandedPid = ""
    }

    onSearchTextChanged: {
        if (expandedPid !== "") expandedPid = ""
    }

    contentItem: OverlayBackground {
        radius: root.contentRadius
        property real padding: 6
        implicitWidth: 550
        implicitHeight: 600

        ColumnLayout {
            anchors {
                fill: parent
                margins: parent.padding
            }
            spacing: 8

            // Seach bar
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 4
                spacing: 6

                MaterialSymbol {
                    text: "search"
                    color: Appearance.colors.colOnSurfaceVariant
                    iconSize: Appearance.font.pixelSize.large
                }

                ToolbarTextField {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: 36
                    placeholderText: Translation.tr("Search processes...")
                    text: root.searchText
                    onTextChanged: root.searchText = text
                }

                Loader {
                    Layout.preferredWidth: 50
                    Layout.preferredHeight: 24
                    active: root.searchText.trim() !== ""
                    sourceComponent: Rectangle {
                        width: 50
                        height: 24
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colSecondaryContainer

                        StyledText {
                            anchors.centerIn: parent
                            text: ProcessMonitor.visibleCount
                            color: Appearance.colors.colOnSecondaryContainer
                            font.pixelSize: Appearance.font.pixelSize.small
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true

                            StyledToolTip {
                                text: Translation.tr("%1 processes found").arg(ProcessMonitor.visibleCount)
                            }
                        }
                    }
                }
            }

            // Header
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                Layout.margins: 4
                color: Appearance.colors.colSecondaryContainer
                radius: Appearance.rounding.small

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 6

                    // Process header
                    Item {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 50
                        Layout.preferredHeight: parent.height

                        StyledText {
                            id: processLabel
                            anchors.verticalCenter: parent.verticalCenter
                            text: Translation.tr("Process")
                            font.bold: true
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: root.sortStateProcess !== 0 ?
                                   Appearance.colors.colPrimary :
                                   processMouseArea.containsMouse ?
                                   Appearance.colors.colPrimary :
                                   Appearance.colors.colOnSecondaryContainer
                            opacity: processMouseArea.containsMouse ? 0.7 : 1.0
                        }

                        MaterialSymbol {
                            visible: root.sortStateProcess !== 0
                            anchors.left: processLabel.right
                            anchors.leftMargin: 3
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.sortStateProcess === 1 ? "arrow_downward" : "arrow_upward"
                            color: Appearance.colors.colPrimary
                            iconSize: 14
                        }

                        MouseArea {
                            id: processMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.sortStateCpu = 0
                                root.sortStateRam = 0
                                root.sortStateProcess = (root.sortStateProcess + 1) % 3
                            }
                        }
                    }

                    // CPU header
                    Item {
                        Layout.preferredWidth: 70
                        Layout.minimumWidth: 70
                        Layout.maximumWidth: 70
                        Layout.preferredHeight: parent.height

                        StyledText {
                            id: cpuLabel
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: Translation.tr("CPU")
                            font.bold: true
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: root.sortStateCpu !== 0 ?
                                   Appearance.colors.colPrimary :
                                   cpuMouseArea.containsMouse ?
                                   Appearance.colors.colPrimary :
                                   Appearance.colors.colOnSecondaryContainer
                            opacity: cpuMouseArea.containsMouse ? 0.7 : 1.0
                        }

                        MaterialSymbol {
                            visible: root.sortStateCpu !== 0
                            anchors.right: cpuLabel.left
                            anchors.rightMargin: 3
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.sortStateCpu === 1 ? "arrow_downward" : "arrow_upward"
                            color: Appearance.colors.colPrimary
                            iconSize: 14
                        }

                        MouseArea {
                            id: cpuMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.sortStateProcess = 0
                                root.sortStateRam = 0
                                root.sortStateCpu = (root.sortStateCpu + 1) % 3
                            }
                        }
                    }

                    // RAM header
                    Item {
                        Layout.preferredWidth: 90
                        Layout.minimumWidth: 90
                        Layout.maximumWidth: 90
                        Layout.preferredHeight: parent.height

                        StyledText {
                            id: ramLabel
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: Translation.tr("RAM")
                            font.bold: true
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: root.sortStateRam !== 0 ?
                                   Appearance.colors.colPrimary :
                                   ramMouseArea.containsMouse ?
                                   Appearance.colors.colPrimary :
                                   Appearance.colors.colOnSecondaryContainer
                            opacity: ramMouseArea.containsMouse ? 0.7 : 1.0
                        }

                        MaterialSymbol {
                            visible: root.sortStateRam !== 0
                            anchors.right: ramLabel.left
                            anchors.rightMargin: 3
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.sortStateRam === 1 ? "arrow_downward" : "arrow_upward"
                            color: Appearance.colors.colPrimary
                            iconSize: 14
                        }

                        MouseArea {
                            id: ramMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.sortStateProcess = 0
                                root.sortStateCpu = 0
                                root.sortStateRam = (root.sortStateRam + 1) % 3
                            }
                        }
                    }

                    Item {
                        Layout.preferredWidth: 36
                        Layout.minimumWidth: 36
                        Layout.maximumWidth: 36
                    }
                }
            }

            // Process list or empty state
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Loading state
                ColumnLayout {
                    anchors.centerIn: parent
                    visible: ProcessMonitor.warmingUp
                    spacing: 12

                    MaterialLoadingIndicator {
                        Layout.alignment: Qt.AlignHCenter
                        implicitSize: 48
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Translation.tr("Loading processes...")
                        color: Appearance.colors.colOnSurfaceVariant
                        font.pixelSize: Appearance.font.pixelSize.large
                    }
                }

                // Empty state message
                ColumnLayout {
                    anchors.centerIn: parent
                    visible: !ProcessMonitor.warmingUp && ProcessMonitor.visibleCount === 0
                    spacing: 12

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        text: "search_off"
                        color: Appearance.colors.colOnSurfaceVariant
                        iconSize: 48
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Translation.tr("No processes found")
                        color: Appearance.colors.colOnSurfaceVariant
                        font.pixelSize: Appearance.font.pixelSize.large
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Translation.tr("Try a different query")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                }

                // Process list
                ScrollView {
                    anchors.fill: parent
                    visible: ProcessMonitor.visibleCount > 0
                    clip: true

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        contentItem: Rectangle {
                            implicitWidth: 6
                            radius: 3
                            color: Appearance.colors.colOnSurfaceVariant
                            opacity: parent.active ? 0.7 : 0.3
                        }
                    }

                    StyledListView {
                        id: listView
                        animateAppearance: true
                        animateMovement: true
                        clip: true

                        model: ProcessMonitor.model

                        delegate: Item {
                            id: processDelegate

                            required property string pid
                            required property string name
                            required property string fullCommand
                            required property string user
                            required property double cpuPercent
                            required property double memPercent
                            required property string memoryFormatted

                            width: listView.width
                            height: delegateColumn.implicitHeight + 8
                            clip: true

                            Behavior on height {
                                enabled: !ProcessMonitor.warmingUp
                                NumberAnimation {
                                    duration: Appearance.animation.elementMoveFast.duration
                                    easing.type: Appearance.animation.elementMoveFast.type
                                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                                }
                            }

                            property bool isExpanded: root.expandedPid === processDelegate.pid

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 2
                                color: mouseArea.containsMouse ? Appearance.colors.colSecondaryContainer : "transparent"
                                radius: Appearance.rounding.small

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton
                                onClicked: {
                                    if (isExpanded) {
                                        root.expandedPid = ""
                                    } else {
                                        root.expandedPid = processDelegate.pid
                                    }
                                }
                            }

                            Column {
                                id: delegateColumn
                                width: parent.width
                                spacing: isExpanded ? 8 : 0

                                // Main row
                                Item {
                                    id: mainRow
                                    width: parent.width
                                    height: 40

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        spacing: 6

                                        StyledText {
                                            Layout.fillWidth: true
                                            Layout.minimumWidth: 50
                                            text: processDelegate.name
                                            elide: Text.ElideRight
                                            color: Appearance.colors.colOnSurface
                                            font.pixelSize: Appearance.font.pixelSize.small
                                        }

                                        StyledText {
                                            Layout.preferredWidth: 70
                                            Layout.minimumWidth: 70
                                            Layout.maximumWidth: 70
                                            horizontalAlignment: Text.AlignRight
                                            text: processDelegate.cpuPercent.toFixed(1) + "%"
                                            color: processDelegate.cpuPercent > 50 ?
                                            Appearance.colors.colError :
                                            processDelegate.cpuPercent > 25 ?
                                            '#d8ffc374' :
                                            Appearance.colors.colOnSurfaceVariant
                                            font {
                                                family: Appearance.font.family.numbers
                                                variableAxes: Appearance.font.variableAxes.numbers
                                                pixelSize: Appearance.font.pixelSize.small
                                            }
                                        }

                                        StyledText {
                                            Layout.preferredWidth: 90
                                            Layout.minimumWidth: 90
                                            Layout.maximumWidth: 90
                                            horizontalAlignment: Text.AlignRight
                                            text: processDelegate.memoryFormatted
                                            color: Appearance.colors.colOnSurfaceVariant
                                            font {
                                                family: Appearance.font.family.numbers
                                                variableAxes: Appearance.font.variableAxes.numbers
                                                pixelSize: Appearance.font.pixelSize.small
                                            }
                                        }

                                        Item {
                                            Layout.preferredWidth: 36
                                            Layout.minimumWidth: 36
                                            Layout.maximumWidth: 36
                                            Layout.preferredHeight: 36
                                            Layout.alignment: Qt.AlignVCenter

                                            RippleButton {
                                                anchors.centerIn: parent
                                                implicitWidth: 32
                                                implicitHeight: 32
                                                background.implicitWidth: 26
                                                background.implicitHeight: 26
                                                background.anchors.centerIn: this
                                                colBackground: "transparent"
                                                colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colErrorContainerHover, 0.45)
                                                buttonRadius: Appearance.rounding.full

                                                contentItem: MaterialSymbol {
                                                    anchors.centerIn: parent
                                                    text: "close"
                                                    color: Appearance.colors.colError
                                                    iconSize: Appearance.font.pixelSize.normal
                                                }

                                                onClicked: {
                                                    const pid = processDelegate.pid
                                                    // If this process is expanded, close it first
                                                    if (root.expandedPid === pid) {
                                                        root.expandedPid = ""
                                                    }
                                                    // Kill the processs
                                                    ProcessMonitor.killProcess(pid)
                                                }

                                                StyledToolTip {
                                                    text: Translation.tr("Kill (PID: %1)").arg(processDelegate.pid)
                                                }
                                            }
                                        }
                                    }
                                }

                                // Expanded details
                                Rectangle {
                                    id: detailsBox
                                    width: parent.width - 32
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    height: detailsLayout.implicitHeight + 16
                                    visible: isExpanded
                                    color: Appearance.colors.colLayer1
                                    radius: Appearance.rounding.small

                                    ColumnLayout {
                                        id: detailsLayout
                                        anchors {
                                            left: parent.left
                                            right: parent.right
                                            top: parent.top
                                            margins: 8
                                        }
                                        spacing: 4

                                        RowLayout {
                                            spacing: 4
                                            MaterialSymbol {
                                                text: "badge"
                                                color: Appearance.colors.colOnSurfaceVariant
                                                iconSize: Appearance.font.pixelSize.small
                                            }
                                            StyledText {
                                                text: Translation.tr("PID:")
                                                color: Appearance.colors.colSubtext
                                                font.pixelSize: Appearance.font.pixelSize.smallie
                                            }
                                            StyledText {
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignRight
                                                text: processDelegate.pid
                                                color: Appearance.colors.colOnSurface
                                                font.pixelSize: Appearance.font.pixelSize.smallie
                                            }
                                        }

                                        RowLayout {
                                            spacing: 4
                                            MaterialSymbol {
                                                text: "person"
                                                color: Appearance.colors.colOnSurfaceVariant
                                                iconSize: Appearance.font.pixelSize.small
                                            }
                                            StyledText {
                                                text: Translation.tr("User:")
                                                color: Appearance.colors.colSubtext
                                                font.pixelSize: Appearance.font.pixelSize.smallie
                                            }
                                            StyledText {
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignRight
                                                text: processDelegate.user
                                                color: Appearance.colors.colOnSurface
                                                font.pixelSize: Appearance.font.pixelSize.smallie
                                            }
                                        }

                                        RowLayout {
                                            spacing: 4
                                            MaterialSymbol {
                                                text: "memory"
                                                color: Appearance.colors.colOnSurfaceVariant
                                                iconSize: Appearance.font.pixelSize.small
                                            }
                                            StyledText {
                                                text: Translation.tr("Memory:")
                                                color: Appearance.colors.colSubtext
                                                font.pixelSize: Appearance.font.pixelSize.smallie
                                            }
                                            StyledText {
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignRight
                                                text: processDelegate.memPercent.toFixed(1) + "% (" + processDelegate.memoryFormatted + ")"
                                                color: Appearance.colors.colOnSurface
                                                font.pixelSize: Appearance.font.pixelSize.smallie
                                            }
                                        }

                                        RowLayout {
                                            Layout.topMargin: 2
                                            spacing: 4
                                            MaterialSymbol {
                                                Layout.alignment: Qt.AlignTop
                                                text: "terminal"
                                                color: Appearance.colors.colOnSurfaceVariant
                                                iconSize: Appearance.font.pixelSize.small
                                            }
                                            StyledText {
                                                Layout.alignment: Qt.AlignTop
                                                text: Translation.tr("Command:")
                                                color: Appearance.colors.colSubtext
                                                font.pixelSize: Appearance.font.pixelSize.smallie
                                            }
                                            StyledText {
                                                Layout.fillWidth: true
                                                text: processDelegate.fullCommand
                                                wrapMode: Text.Wrap
                                                color: Appearance.colors.colOnSurface
                                                font.pixelSize: Appearance.font.pixelSize.smallie
                                                font.family: "monospace"
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Footer
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                Layout.margins: 4
                color: Appearance.colors.colSecondaryContainer
                radius: Appearance.rounding.small

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 6

                    MaterialSymbol {
                        text: "list"
                        color: Appearance.colors.colOnSecondaryContainer
                        iconSize: Appearance.font.pixelSize.small
                    }

                    StyledText {
                        text: root.searchText.trim() !== "" ?
                        Translation.tr("Showing %1 of %2").arg(ProcessMonitor.visibleCount).arg(ProcessMonitor.totalCount) :
                        Translation.tr("Total: %1").arg(ProcessMonitor.totalCount)
                        color: Appearance.colors.colOnSecondaryContainer
                        font.pixelSize: Appearance.font.pixelSize.smallie
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        visible: root.expandedPid == ""
                        width: 6
                        height: 6
                        radius: 3
                        color: ProcessMonitor.warmingUp ?
                        Appearance.colors.colTertiary :
                        Appearance.colors.colPrimary
                    }

                    Rectangle { 
                        visible: root.expandedPid !== ""
                        width: 6
                        height: 6
                        radius: 1
                        color: ProcessMonitor.warmingUp ?
                        Appearance.colors.colTertiary :
                        Appearance.colors.colPrimary
                    }

                    StyledText {
                        text: ProcessMonitor.warmingUp ? Translation.tr("Loading...") : root.expandedPid !== "" ? Translation.tr("Paused") : Translation.tr("Live")
                        color: Appearance.colors.colOnSecondaryContainer
                        font.pixelSize: Appearance.font.pixelSize.smallie
                    }
                }
            }
        }
    }
}
