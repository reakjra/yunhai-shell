import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

Popup {
    id: root

    property color initialColor: "white"
    readonly property color selectedColor: Qt.hsva(hueValue, satValue, valValue, alphaValue)

    property real hueValue: 0
    property real satValue: 1
    property real valValue: 1
    property real alphaValue: 1

    signal accepted(color chosenColor)
    signal resetRequested()

    function openWithColor(col, defaultCol) {
        root.initialColor = defaultCol ?? col
        root.hueValue = col.hsvHue >= 0 ? col.hsvHue : 0
        root.satValue = col.hsvSaturation
        root.valValue = col.hsvValue
        root.alphaValue = col.a
        root.open()
    }

    function toHex(c) {
        function h(v) { return Math.round(v * 255).toString(16).padStart(2, '0') }
        const rgb = h(c.r) + h(c.g) + h(c.b)
        if (c.a < 1) return "#" + h(c.a) + rgb
        return "#" + rgb
    }

    function applyColor(col) {
        if (!col) return
        const c = (typeof col === "string") ? Qt.color(col) : col
        root.hueValue = c.hsvHue >= 0 ? c.hsvHue : 0
        root.satValue = c.hsvSaturation
        root.valValue = c.hsvValue
        root.alphaValue = c.a
    }

    modal: true
    anchors.centerIn: Overlay.overlay
    padding: 20
    width: 360

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.85; to: 1; duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150; easing.type: Easing.InCubic }
            NumberAnimation { property: "scale"; from: 1; to: 0.9; duration: 150; easing.type: Easing.InCubic }
        }
    }

    background: Rectangle {
        color: Appearance?.m3colors.m3surfaceContainerHigh ?? "#2b2a2a"
        radius: Appearance?.rounding.large ?? 23
    }

    contentItem: ColumnLayout {
        spacing: 12

        StyledText {
            text: Translation.tr("Pick a color")
            color: Appearance?.colors.colOnSurface ?? "white"
            font {
                family: Appearance?.font.family.title ?? "sans-serif"
                pixelSize: Appearance?.font.pixelSize.title ?? 20
                variableAxes: Appearance?.font.variableAxes.title ?? ({})
            }
        }

        // ── Picker area: SV square + vertical hue bar + vertical alpha bar ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // SV gradient
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 200

                Canvas {
                    id: svCanvas
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        ctx.fillStyle = Qt.hsva(root.hueValue, 1, 1, 1).toString()
                        ctx.fillRect(0, 0, width, height)
                        var wg = ctx.createLinearGradient(0, 0, width, 0)
                        wg.addColorStop(0, "white")
                        wg.addColorStop(1, "rgba(255,255,255,0)")
                        ctx.fillStyle = wg
                        ctx.fillRect(0, 0, width, height)
                        var bg = ctx.createLinearGradient(0, 0, 0, height)
                        bg.addColorStop(0, "rgba(0,0,0,0)")
                        bg.addColorStop(1, "black")
                        ctx.fillStyle = bg
                        ctx.fillRect(0, 0, width, height)
                    }
                    Connections {
                        target: root
                        function onHueValueChanged() { svCanvas.requestPaint() }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed: (mouse) => pick(mouse)
                    onPositionChanged: (mouse) => pick(mouse)
                    function pick(mouse) {
                        root.satValue = Math.max(0, Math.min(1, mouse.x / width))
                        root.valValue = Math.max(0, Math.min(1, 1 - mouse.y / height))
                    }
                }

                // SV indicator
                Rectangle {
                    x: root.satValue * parent.width - 7
                    y: (1 - root.valValue) * parent.height - 7
                    width: 14; height: 14; radius: 7
                    color: "transparent"
                    border.width: 2
                    border.color: root.valValue > 0.5 ? "black" : "white"
                }

            }

            // Vertical hue bar
            Item {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 200
                clip: true

                Canvas {
                    id: hueCanvas
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d")
                        var grad = ctx.createLinearGradient(0, 0, 0, height)
                        for (var i = 0; i <= 6; i++)
                            grad.addColorStop(i / 6, Qt.hsva(i / 6, 1, 1, 1).toString())
                        ctx.fillStyle = grad
                        ctx.fillRect(0, 0, width, height)
                    }
                    Component.onCompleted: requestPaint()
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed: (mouse) => root.hueValue = Math.max(0, Math.min(1, mouse.y / height))
                    onPositionChanged: (mouse) => root.hueValue = Math.max(0, Math.min(1, mouse.y / height))
                }

                Rectangle {
                    y: root.hueValue * parent.height - 2
                    width: parent.width; height: 4; radius: 2
                    color: "white"
                    border.width: 1; border.color: "#00000040"
                }
            }

            // Vertical alpha bar
            Item {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 200
                clip: true

                Canvas {
                    id: alphaCanvas
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        var sz = 5
                        for (var cy = 0; cy < height; cy += sz)
                            for (var cx = 0; cx < width; cx += sz) {
                                ctx.fillStyle = ((Math.floor(cx / sz) + Math.floor(cy / sz)) % 2 === 0) ? "#ccc" : "#fff"
                                ctx.fillRect(cx, cy, sz, sz)
                            }
                        var c = Qt.hsva(root.hueValue, root.satValue, root.valValue, 1)
                        var r = Math.round(c.r * 255), g = Math.round(c.g * 255), b = Math.round(c.b * 255)
                        var grad = ctx.createLinearGradient(0, 0, 0, height)
                        grad.addColorStop(0, "rgba(" + r + "," + g + "," + b + ",1)")
                        grad.addColorStop(1, "rgba(" + r + "," + g + "," + b + ",0)")
                        ctx.fillStyle = grad
                        ctx.fillRect(0, 0, width, height)
                    }
                    Connections {
                        target: root
                        function onHueValueChanged() { alphaCanvas.requestPaint() }
                        function onSatValueChanged() { alphaCanvas.requestPaint() }
                        function onValValueChanged() { alphaCanvas.requestPaint() }
                    }
                    Component.onCompleted: requestPaint()
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed: (mouse) => root.alphaValue = Math.max(0, Math.min(1, 1 - mouse.y / height))
                    onPositionChanged: (mouse) => root.alphaValue = Math.max(0, Math.min(1, 1 - mouse.y / height))
                }

                Rectangle {
                    y: (1 - root.alphaValue) * parent.height - 2
                    width: parent.width; height: 4; radius: 2
                    color: "white"
                    border.width: 1; border.color: "#00000040"
                }
            }
        }

        // ── Separator ──
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Appearance?.colors.colOutlineVariant ?? "#49464a"
        }

        // ── Info: previews + editable fields ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                spacing: 6

                RowLayout {
                    spacing: 6
                    Rectangle {
                        width: 24; height: 24; radius: 12
                        color: Appearance?.m3colors.m3surfaceContainerHighest ?? "#363435"
                        Rectangle {
                            anchors.fill: parent; anchors.margins: 1; radius: 11
                            color: root.selectedColor
                        }
                    }
                    StyledText {
                        text: Translation.tr("New")
                        font.pixelSize: Appearance?.font.pixelSize.smallest ?? 10
                        color: Appearance?.colors.colOnSurfaceVariant ?? "#cbc5ca"
                    }
                }

                RowLayout {
                    spacing: 6
                    Rectangle {
                        width: 24; height: 24; radius: 12
                        color: root.initialColor
                        border.width: 1
                        border.color: Appearance?.colors.colOutlineVariant ?? "#49464a"
                    }
                    StyledText {
                        text: Translation.tr("Default")
                        font.pixelSize: Appearance?.font.pixelSize.smallest ?? 10
                        color: Appearance?.colors.colOnSurfaceVariant ?? "#cbc5ca"
                    }
                }
            }

            Item { Layout.fillWidth: true }

            ColumnLayout {
                spacing: 4

                // HEX
                RowLayout {
                    spacing: 4

                    StyledText {
                        text: "HEX"
                        font.pixelSize: Appearance?.font.pixelSize.normal ?? 16
                        color: Appearance?.colors.colOnSurfaceVariant ?? "#cbc5ca"
                        Layout.preferredWidth: 42
                    }

                    Rectangle {
                        Layout.preferredWidth: 105
                        implicitHeight: 30
                        radius: Appearance?.rounding.verysmall ?? 8
                        color: Appearance?.m3colors.m3surfaceContainer ?? "#201f20"
                        border.width: hexInput.activeFocus ? 1 : 0
                        border.color: Appearance?.colors.colPrimary ?? "#cbc4cb"

                        StyledTextInput {
                            id: hexInput
                            anchors.fill: parent
                            anchors.leftMargin: 6; anchors.rightMargin: 6
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: Appearance?.font.pixelSize.small ?? 15
                            clip: true

                            Connections {
                                target: root
                                function onSelectedColorChanged() {
                                    if (!hexInput.activeFocus)
                                        hexInput.text = root.toHex(root.selectedColor).toUpperCase()
                                }
                            }

                            onAccepted: applyHex()
                            onActiveFocusChanged: {
                                if (!activeFocus) applyHex()
                                else selectAll()
                            }

                            function applyHex() {
                                let str = text.trim()
                                if (!str.startsWith("#")) str = "#" + str
                                if (/^#[0-9a-fA-F]{3}$/.test(str) || /^#[0-9a-fA-F]{6}$/.test(str) || /^#[0-9a-fA-F]{8}$/.test(str))
                                    root.applyColor(str)
                            }

                            Component.onCompleted: text = root.toHex(root.selectedColor).toUpperCase()
                        }
                    }
                }

                // RGBA
                RowLayout {
                    spacing: 4

                    StyledText {
                        text: "RGBA"
                        font.pixelSize: Appearance?.font.pixelSize.normal ?? 16
                        color: Appearance?.colors.colOnSurfaceVariant ?? "#cbc5ca"
                        Layout.preferredWidth: 42
                    }

                    Repeater {
                        model: ["r", "g", "b", "a"]

                        Rectangle {
                            required property string modelData
                            required property int index

                            Layout.preferredWidth: 38
                            implicitHeight: 30
                            radius: Appearance?.rounding.verysmall ?? 8
                            color: Appearance?.m3colors.m3surfaceContainer ?? "#201f20"
                            border.width: rgbaField.activeFocus ? 1 : 0
                            border.color: Appearance?.colors.colPrimary ?? "#cbc4cb"

                            StyledTextInput {
                                id: rgbaField
                                anchors.fill: parent
                                anchors.leftMargin: 3; anchors.rightMargin: 3
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: Appearance?.font.pixelSize.small ?? 15
                                clip: true
                                inputMethodHints: Qt.ImhDigitsOnly
                                validator: IntValidator { bottom: 0; top: 255 }

                                Connections {
                                    target: root
                                    function onSelectedColorChanged() {
                                        if (!rgbaField.activeFocus) {
                                            const c = root.selectedColor
                                            const v = [Math.round(c.r * 255), Math.round(c.g * 255), Math.round(c.b * 255), Math.round(c.a * 255)]
                                            rgbaField.text = v[index].toString()
                                        }
                                    }
                                }

                                onAccepted: applyChannel()
                                onActiveFocusChanged: {
                                    if (!activeFocus) applyChannel()
                                    else selectAll()
                                }

                                function applyChannel() {
                                    const val = parseInt(text)
                                    if (isNaN(val)) return
                                    const norm = Math.max(0, Math.min(255, val)) / 255
                                    const c = root.selectedColor
                                    let r = c.r, g = c.g, b = c.b, a = c.a
                                    if (modelData === "r") r = norm
                                    else if (modelData === "g") g = norm
                                    else if (modelData === "b") b = norm
                                    else a = norm
                                    root.applyColor(Qt.rgba(r, g, b, a))
                                }

                                Component.onCompleted: {
                                    const c = root.selectedColor
                                    const v = [Math.round(c.r * 255), Math.round(c.g * 255), Math.round(c.b * 255), Math.round(c.a * 255)]
                                    text = v[index].toString()
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Buttons ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Reset button aligned with color circles above
            RippleButton {
                Layout.leftMargin: -6
                implicitWidth: 36
                implicitHeight: 36
                buttonRadius: Appearance?.rounding.full ?? 9999
                colBackground: "transparent"
                colBackgroundHover: ColorUtils.transparentize(Appearance?.colors.colError ?? "#ffb4ab", 0.85)
                colRipple: ColorUtils.transparentize(Appearance?.colors.colError ?? "#ffb4ab", 0.7)
                onClicked: {
                    root.resetRequested()
                    root.close()
                }
                contentItem: Item {
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "restart_alt"
                        iconSize: 22
                        color: Appearance?.colors.colError ?? "#ffb4ab"
                    }
                }
            }

            Item { Layout.fillWidth: true }

            RippleButton {
                implicitWidth: 36
                implicitHeight: 36
                buttonRadius: Appearance?.rounding.full ?? 9999
                colBackground: "transparent"
                colBackgroundHover: ColorUtils.transparentize(Appearance?.colors.colOnSurface ?? "white", 0.85)
                colRipple: ColorUtils.transparentize(Appearance?.colors.colOnSurface ?? "white", 0.7)
                onClicked: root.close()
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: "close"
                    iconSize: 22
                    color: Appearance?.colors.colOnSurfaceVariant ?? "#cbc5ca"
                }
            }

            RippleButton {
                implicitWidth: 36
                implicitHeight: 36
                buttonRadius: Appearance?.rounding.full ?? 9999
                colBackground: Appearance?.colors.colPrimary ?? "#cbc4cb"
                colBackgroundHover: Appearance?.colors.colPrimaryHover ?? "#b5aeb5"
                colRipple: Appearance?.colors.colPrimaryActive ?? "#a09aa0"
                onClicked: {
                    root.accepted(root.selectedColor)
                    root.close()
                }
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: "check"
                    iconSize: 22
                    fill: 1
                    color: Appearance?.colors.colOnPrimary ?? "#322f34"
                }
            }
        }
    }
}
