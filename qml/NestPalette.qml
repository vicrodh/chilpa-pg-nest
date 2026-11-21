import QtQuick

QtObject {
    property string mode: "host"
    property bool hostDark: false
    property color hostAccent: "#b17f54"
    property color hostWindow: "#eeeee9"
    property bool hostAmbient: false
    readonly property bool ambient: mode === "host" && hostAmbient
    readonly property string finish: mode === "host" ? (hostDark ? "dark" : "light") : mode
    readonly property bool dark: finish === "dark" || finish === "wood"
    readonly property bool wood: finish === "wood"
    readonly property color window: ambient ? "transparent" : mode === "host" ? hostWindow : finish === "dark" ? "#171918" : wood ? "#33271d" : "#eeeee9"
    readonly property color panel: finish === "dark" ? "#252726" : wood ? "#493526" : "#fafaf6"
    readonly property color text: dark ? "#f0eee5" : "#292d2b"
    readonly property color muted: dark ? "#a1a598" : "#767b71"
    readonly property color edge: finish === "dark" ? "#424642" : wood ? "#9f784f" : "#cbcec5"
    readonly property color field: finish === "dark" ? "#202321" : wood ? "#3e2c20" : "#ffffff"
    readonly property color cabinet: finish === "dark" ? "#242725" : wood ? "#9d754f" : "#dedfd7"
    readonly property color cabinetEdge: finish === "dark" ? "#494c48" : wood ? "#bf986c" : "#ffffff"
    readonly property color recess: finish === "dark" ? "#101310" : wood ? "#35271b" : "#aeb3aa"
    readonly property color rail: finish === "dark" ? "#30332f" : wood ? "#ae8258" : "#e8e9e0"
    readonly property color railTop: finish === "dark" ? "#666961" : wood ? "#d4ad7a" : "#ffffff"
    readonly property color railBottom: finish === "dark" ? "#101310" : wood ? "#5a3f29" : "#a7aca2"
    readonly property color accent: mode === "host" ? hostAccent : wood ? "#ddbd88" : finish === "dark" ? "#d0af7e" : "#5d7158"
    readonly property color onAccent: Qt.hsla(accent.hslHue, accent.hslSaturation, accent.hslLightness < 0.55 ? 0.98 : 0.12, 1)
    readonly property color bookletBackground: "#161a17"
    readonly property color bookletText: "#f1f4ed"
    readonly property color bookletSecondary: "#c0cbbf"
    readonly property color bookletBorder: "#59645c"
    readonly property color bookletTrack: "#37443b"
    readonly property color bookletThumb: "#b9c9bb"
    readonly property color scrim: dark ? "#99101210" : "#701c2119"
    readonly property color negative: dark ? "#f0a18a" : "#a34b32"
    readonly property color positive: dark ? "#b3cc9e" : "#52714b"
}
