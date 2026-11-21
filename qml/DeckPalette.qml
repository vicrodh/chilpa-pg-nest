import QtQuick
QtObject {
    property bool silver: false
    readonly property color faceTop: silver ? "#d5d1c9" : "#27282b"
    readonly property color faceMid: silver ? "#c7c3bb" : "#1c1d20"
    readonly property color faceBottom: silver ? "#b8b4ac" : "#151619"
    readonly property color edge: silver ? "#99ffffff" : "#1fffffff"
    readonly property color edgeLow: silver ? "#8a867e" : "#0a0a0b"
    readonly property color ink: silver ? "#1b1a18" : "#ebe7df"
    readonly property color secondary: silver ? "#4b4841" : "#a7a299"
    readonly property color keyTop: silver ? "#dedad2" : "#303135"
    readonly property color keyBottom: silver ? "#cbc7bf" : "#242528"
    readonly property color recess: silver ? "#141517" : "#0b0c0d"
    readonly property color focus: silver ? "#111111" : "#f4efe6"
    readonly property color off: silver ? "#a29e96" : "#3a3b3e"
    readonly property color amber: "#ffb547"
    readonly property color green: "#5fd36f"
    readonly property color red: "#ff5446"
}
