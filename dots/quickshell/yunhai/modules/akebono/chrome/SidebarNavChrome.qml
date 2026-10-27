pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property var pages: []
    property int currentPage: 0
    property Component header
    property real pageRightMargin: 0

    property var history: [0]
    property int historyPos: 0

    signal pageLoaded(var item)

    readonly property real squircleSmoothing: Config.options.squircle.smoothing

    component StickyPill: ShaderEffect {
        property vector2d size: Qt.vector2d(width, height)
        property color color: "#000000"
        property real radius: 13
        property real smoothing: 4.0
        property real inset: 2
        property real pillHalfH: 16
        property real fromY: 0
        property real toY: 0
        property real leadProg: 1
        property real bodyProg: 1
        property real dollopScale: 0.5
        property real sminK: 22
        fragmentShader: Quickshell.shellPath("assets/shaders/akebono/stickypill.frag.qsb")
    }

    function navigate(i) {
        if (i === root.currentPage)
            return;
        var h = root.history.slice(0, root.historyPos + 1);
        h.push(i);
        root.history = h;
        root.historyPos = h.length - 1;
        root.currentPage = i;
    }
    function goBack() {
        if (root.historyPos <= 0)
            return;
        root.historyPos -= 1;
        root.currentPage = root.history[root.historyPos];
    }
    function goForward() {
        if (root.historyPos >= root.history.length - 1)
            return;
        root.historyPos += 1;
        root.currentPage = root.history[root.historyPos];
    }

    component ChevronBtn: RippleButton {
        id: chevBtn
        property string glyph
        implicitWidth: 34
        implicitHeight: 34
        buttonRadius: Appearance.rounding.full
        colBackground: "transparent"
        colBackgroundHover: Appearance.colors.colLayer1Hover
        colRipple: Appearance.colors.colLayer1Active
        contentItem: MaterialSymbol {
            text: chevBtn.glyph
            iconSize: 22
            opacity: chevBtn.enabled ? 1 : 0.35
            color: Appearance.colors.colOnLayer0
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 10

        Item {
            Layout.preferredWidth: 248
            Layout.fillHeight: true

            Squircle {
                anchors.fill: parent
                color: Appearance.colors.colLayer1
                radius: 26
                smoothing: root.squircleSmoothing
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Loader {
                    Layout.fillWidth: true
                    sourceComponent: root.header
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Appearance.colors.colSubtext
                    opacity: 0.25
                }

                Item {
                    id: tabHost
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    readonly property real rowHeight: 40
                    readonly property real rowSpacing: 5
                    function rowCenterY(i) {
                        return i * (rowHeight + rowSpacing) + rowHeight / 2;
                    }
                    function movePill() {
                        pill.fromY = pill.toY;
                        pill.toY = rowCenterY(root.currentPage);
                        leadAnim.restart();
                        bodyAnim.restart();
                    }
                    Component.onCompleted: {
                        var c = rowCenterY(root.currentPage);
                        pill.fromY = c;
                        pill.toY = c;
                        pill.leadProg = 1;
                        pill.bodyProg = 1;
                    }
                    Connections {
                        target: root
                        function onCurrentPageChanged() {
                            tabHost.movePill();
                        }
                    }

                    StickyPill {
                        id: pill
                        anchors.fill: parent
                        visible: root.pages.length > 0
                        color: Appearance.colors.colPrimaryContainer
                        radius: 13
                        smoothing: root.squircleSmoothing
                        inset: 2
                        pillHalfH: 16.5
                        dollopScale: 0.5
                        sminK: 22

                        NumberAnimation {
                            id: leadAnim
                            target: pill
                            property: "leadProg"
                            from: 0
                            to: 1
                            duration: 280
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            id: bodyAnim
                            target: pill
                            property: "bodyProg"
                            from: 0
                            to: 1
                            duration: 470
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.4
                        }
                    }

                    Column {
                        id: tabColumn
                        anchors.fill: parent
                        spacing: tabHost.rowSpacing

                        Repeater {
                            model: root.pages
                            delegate: Item {
                                id: tabDelegate
                                required property int index
                                required property var modelData
                                width: tabColumn.width
                                height: tabHost.rowHeight
                                readonly property bool selected: root.currentPage === index

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 13
                                    color: (rowMouse.containsMouse && !tabDelegate.selected) ? Appearance.colors.colLayer1Hover : "transparent"
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 12

                                    MaterialSymbol {
                                        text: tabDelegate.modelData.icon
                                        rotation: tabDelegate.modelData.iconRotation || 0
                                        iconSize: 22
                                        fill: tabDelegate.selected ? 1 : 0
                                        color: tabDelegate.selected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: tabDelegate.modelData.name
                                        font.pixelSize: Appearance.font.pixelSize.normal
                                        font.weight: tabDelegate.selected ? Font.DemiBold : Font.Normal
                                        color: tabDelegate.selected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    id: rowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.navigate(tabDelegate.index)
                                }
                            }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 6
                Layout.topMargin: 4
                spacing: 10

                ChevronBtn {
                    glyph: "chevron_left"
                    enabled: root.historyPos > 0
                    onClicked: root.goBack()
                }
                ChevronBtn {
                    glyph: "chevron_right"
                    enabled: root.historyPos < root.history.length - 1
                    onClicked: root.goForward()
                }
                StyledText {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    text: root.pages[root.currentPage] ? root.pages[root.currentPage].name : ""
                    font.pixelSize: Appearance.font.pixelSize.title
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer0
                    elide: Text.ElideRight
                }
            }

            Loader {
                id: pageLoader
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.rightMargin: root.pageRightMargin
                active: Config.ready
                source: root.pages[root.currentPage] ? Quickshell.shellPath(root.pages[root.currentPage].component) : ""

                onLoaded: root.pageLoaded(item)

                Connections {
                    target: root
                    function onCurrentPageChanged() {
                        pageLoader.opacity = 0;
                        fadeIn.restart();
                    }
                }
                MotionAnimation {
                    id: fadeIn
                    target: pageLoader
                    property: "opacity"
                    from: 0
                    to: 1
                    motion: Motion.effects
                }
            }
        }
    }
}
