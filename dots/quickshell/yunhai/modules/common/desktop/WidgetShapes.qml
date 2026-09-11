pragma Singleton

import Quickshell
import qs.modules.common

Singleton {
    id: root

    readonly property string fallback: "theme"

    readonly property var list: [
        { id: "theme", name: "Theme", glyph: "▦" },
        { id: "square", name: "Square", glyph: "■", radius: 4, smoothing: 2 },
        { id: "rounded", name: "Rounded", glyph: "▢", radius: 26, smoothing: 2 },
        { id: "squircle", name: "Squircle", glyph: "▣", radius: 36, smoothing: 4 },
        { id: "circle", name: "Circle", glyph: "●", radius: Appearance.rounding.full, smoothing: 2, square: true, inset: 0.293 },
        { id: "slant", name: "Slant", glyph: "▰", radius: 26, smoothing: 2, skew: 0.18 },
        { id: "slantAlt", name: "Slant 2", glyph: "▱", radius: 26, smoothing: 2, skew: -0.18 },
        { id: "cookie", name: "Cookie", glyph: "✿", lobes: 10, scallop: 0.09, scale: 1.18, square: true, inset: 0.4 }
    ]

    readonly property var options: root.toOptions(root.list.filter(s => s.chipOnly !== true))
    readonly property var chipOptions: root.toOptions(root.list)

    function toOptions(shapes) {
        return shapes.map(s => ({ displayName: s.glyph, value: s.id, tooltip: s.name }));
    }

    function forId(id) {
        return root.list.find(s => s.id === id) ?? root.list.find(s => s.id === root.fallback);
    }

    function isSquare(id) {
        return root.forId(id).square === true;
    }
}
