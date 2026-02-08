import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    property var targetScreen: null
    property var monitor: null
    property var modes: ["ocr", "lens"]
    property string currentMode: "ocr"
    property string fullScreenshot: ""
    property string cropJpg: ""
    property string lensHtml: ""

    function executeAction() {
        if (!root.monitor)
            return;

        const scale = root.monitor.scale ?? 1;
        
        // Get monitor offset for multi-monitor setups
        const monitorX = root.monitor.lastIpcObject?.x ?? 0;
        const monitorY = root.monitor.lastIpcObject?.y ?? 0;
        
        // For grim -o (single monitor capture), use local coordinates
        // The monitor offset is only needed if capturing all monitors
        const x = Math.round(selector.selectionX * scale);
        const y = Math.round(selector.selectionY * scale);
        const w = Math.round(selector.selectionWidth * scale);
        const h = Math.round(selector.selectionHeight * scale);
        
        if (w < 10 || h < 10)
            return;

        root.visible = false;
        let cmd = "";
        if (root.currentMode === "ocr") {
            const ocrPipeline = [
                `magick "${root.fullScreenshot}" -crop ${w}x${h}+${x}+${y} -`,
                `tesseract - - -l eng`,
                `awk 'BEGIN{RS=""; FS="\\n"; ORS="\\n\\n"} {for(i=1;i<=NF;i++){printf "%s",$i; if(i<NF)printf " "} printf "\\n"}'`,
                `sed 's/  */ /g; s/[[:space:]]*$//'`,
                `wl-copy`
            ].join(" | ");
            cmd = `${ocrPipeline} && notify-send 'OCR Complete' 'Text copied to clipboard'`;
            cmd += ` ; rm -f "${root.fullScreenshot}" "${root.cropJpg}"`;
        } else {
            const buildHtml = [
                `echo '<html><body style="margin:0;display:flex;justify-content:center;align-items:center;height:100vh;background:#111;color:#fff;font-family:system-ui"><p>Searching with Google Lens…</p><form id="f" method="POST" enctype="multipart/form-data" action="https://lens.google.com/v3/upload"></form><script>'`,
                `echo "var b=atob('$B64');"`,
                `echo 'var a=new Uint8Array(b.length);for(var i=0;i<b.length;i++)a[i]=b.charCodeAt(i);var d=new DataTransfer();d.items.add(new File([a],"i.jpg",{type:"image/jpeg"}));var inp=document.createElement("input");inp.type="file";inp.name="encoded_image";inp.files=d.files;document.getElementById("f").appendChild(inp);document.getElementById("f").submit();'`,
                `echo '</script></body></html>'`
            ].join(" ; ");
            cmd = [
                `magick "${root.fullScreenshot}" -crop ${w}x${h}+${x}+${y} -resize '1000x1000>' -strip -quality 85 "${root.cropJpg}"`,
                `B64=$(base64 -w0 "${root.cropJpg}")`,
                `{ ${buildHtml} ; } > "${root.lensHtml}"`,
                `xdg-open "${root.lensHtml}"`
            ].join(" && ");
            cmd += ` ; (sleep 10 && rm -f "${root.fullScreenshot}" "${root.cropJpg}" "${root.lensHtml}") &`;
        }
        proc.command = ["sh", "-c", cmd];
        proc.running = true;
    }

    function finishInit() {
        if (!root.monitor || !root.targetScreen) {
            console.error("Cannot init: monitor or screen is null");
            return;
        }

        const ts = Date.now();
        root.fullScreenshot = Quickshell.cachePath(`snip-full-${ts}.png`);
        root.cropJpg = Quickshell.cachePath(`snip-crop-${ts}.jpg`);
        root.lensHtml = Quickshell.cachePath(`snip-lens-${ts}.html`);
        grimProc.running = true;
    }

    function tryInit() {
        const mon = Hyprland.focusedMonitor;
        if (!mon) {
            return false;
        }

        root.monitor = mon;

        // Find matching Quickshell screen
        let found = null;
        for (const screen of Quickshell.screens) {
            if (screen.name === mon.name) {
                found = screen;
                break;
            }
        }

        if (!found && Quickshell.screens.length > 0) {
            found = Quickshell.screens[0];
        }

        root.targetScreen = found;

        if (root.targetScreen) {
            initTimer.stop();
            finishInit();
            return true;
        }
        return false;
    }

    screen: targetScreen
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    visible: false

    Component.onCompleted: {
        Qt.callLater(tryInit);
    }

    Timer {
        id: initTimer
        interval: 100
        repeat: true
        running: true
        onTriggered: tryInit()
    }

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    ScreencopyView {
        id: screenCopy
        captureSource: root.targetScreen
        anchors.fill: parent
        z: -1
    }

    Process {
        id: grimProc
        command: root.monitor ? ["grim", "-o", root.monitor.name, root.fullScreenshot] : ["true"]
        onExited: (code) => {
            if (code === 0 && root.monitor) {
                root.visible = true;
            } else {
                console.error("grim failed:", code);
                if (!root.visible)
                    retryTimer.start();
                else
                    Qt.quit();
            }
        }
    }

    Timer {
        id: retryTimer
        interval: 200
        onTriggered: {
            if (root.monitor)
                grimProc.running = true;
        }
    }

    Process {
        id: proc
        onExited: (code) => {
            if (code !== 0)
                console.error("Action failed:", code);
            Qt.quit();
        }
    }

    Item {
        id: selector

        property real selectionX: 0
        property real selectionY: 0
        property real selectionWidth: 0
        property real selectionHeight: 0
        property point startPos
        property real mouseX: 0
        property real mouseY: 0

        anchors.fill: parent
        z: 1
        onSelectionXChanged: guides.requestPaint()
        onSelectionYChanged: guides.requestPaint()
        onSelectionWidthChanged: guides.requestPaint()
        onSelectionHeightChanged: guides.requestPaint()
        onMouseXChanged: guides.requestPaint()
        onMouseYChanged: guides.requestPaint()

        ShaderEffect {
            property vector4d selectionRect: Qt.vector4d(selector.selectionX, selector.selectionY, selector.selectionWidth, selector.selectionHeight)
            property real dimOpacity: 0.5
            property vector2d screenSize: Qt.vector2d(selector.width, selector.height)
            property real borderRadius: 4
            property real outlineThickness: 1

            anchors.fill: parent
            fragmentShader: Qt.resolvedUrl("dimming.frag.qsb")
        }

        Canvas {
            id: guides
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.strokeStyle = "rgba(255, 255, 255, 0.8)";
                ctx.lineWidth = 1;
                ctx.setLineDash([4, 4]);
                ctx.beginPath();
                if (!mouseArea.pressed) {
                    ctx.moveTo(selector.mouseX, 0);
                    ctx.lineTo(selector.mouseX, height);
                    ctx.moveTo(0, selector.mouseY);
                    ctx.lineTo(width, selector.mouseY);
                } else {
                    ctx.rect(selector.selectionX, selector.selectionY, selector.selectionWidth, selector.selectionHeight);
                }
                ctx.stroke();
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.CrossCursor
            onPressed: (mouse) => {
                if (mouse.button === Qt.RightButton)
                    return;
                selector.startPos = Qt.point(mouse.x, mouse.y);
                selector.selectionX = mouse.x;
                selector.selectionY = mouse.y;
                selector.selectionWidth = 0;
                selector.selectionHeight = 0;
            }
            onPositionChanged: (mouse) => {
                selector.mouseX = mouse.x;
                selector.mouseY = mouse.y;
                if (pressed && mouse.buttons & Qt.LeftButton) {
                    selector.selectionX = Math.min(selector.startPos.x, mouse.x);
                    selector.selectionY = Math.min(selector.startPos.y, mouse.y);
                    selector.selectionWidth = Math.abs(mouse.x - selector.startPos.x);
                    selector.selectionHeight = Math.abs(mouse.y - selector.startPos.y);
                }
            }
            onReleased: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    selector.selectionX = 0;
                    selector.selectionY = 0;
                    selector.selectionWidth = 0;
                    selector.selectionHeight = 0;
                    return;
                }
                if (selector.selectionWidth > 10 && selector.selectionHeight > 10)
                    root.executeAction();
            }
        }

        Rectangle {
            visible: mouseArea.pressed && selector.selectionWidth > 20
            x: selector.selectionX + selector.selectionWidth / 2 - width / 2
            y: selector.selectionY - 35
            width: sizeLabel.implicitWidth + 16
            height: sizeLabel.implicitHeight + 8
            radius: 6
            color: Qt.rgba(0, 0, 0, 0.7)
            z: 100

            Text {
                id: sizeLabel
                anchors.centerIn: parent
                text: `${Math.round(selector.selectionWidth)} × ${Math.round(selector.selectionHeight)}`
                color: "white"
                font.pixelSize: 12
                font.family: "monospace"
            }
        }
    }

    Rectangle {
        id: controlBar
        z: 10
        width: 300
        height: 50
        radius: height / 2
        color: Qt.rgba(0.15, 0.15, 0.15, 0.4)
        border.color: Qt.rgba(1, 1, 1, 0.15)
        border.width: 1
        layer.enabled: true

        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: 60
        }

        Rectangle {
            id: highlight
            height: parent.height - 8
            width: (parent.width - 8) / root.modes.length
            y: 4
            radius: height / 2
            color: "#cba6f7"
            x: 4 + (root.modes.indexOf(root.currentMode) * width)

            Behavior on x {
                SpringAnimation {
                    spring: 4
                    damping: 0.25
                    mass: 1
                }
            }
        }

        Row {
            anchors.fill: parent
            anchors.margins: 4

            Repeater {
                model: root.modes

                Item {
                    width: (controlBar.width - 8) / root.modes.length
                    height: controlBar.height - 8

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentMode = modelData
                    }

                    Text {
                        anchors.centerIn: parent
                        text: {
                            const icons = {"ocr": "󰈙", "lens": "󰍉"};
                            const labels = {"ocr": "OCR", "lens": "Google Lens"};
                            return icons[modelData] + "  " + labels[modelData];
                        }
                        color: root.currentMode === modelData ? "#11111b" : "#AAFFFFFF"
                        font.weight: root.currentMode === modelData ? Font.Bold : Font.Medium
                        font.pixelSize: 15
                        font.family: "Symbols Nerd Font"
                    }
                }
            }
        }

        layer.effect: DropShadow {
            transparentBorder: true
            radius: 8
            samples: 16
            color: "#80000000"
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (root.fullScreenshot)
                Quickshell.execDetached(["rm", "-f", root.fullScreenshot, root.cropJpg, root.lensHtml]);
            Qt.quit();
        }
    }

    Shortcut {
        sequence: "Tab"
        onActivated: {
            const i = root.modes.indexOf(root.currentMode);
            root.currentMode = root.modes[(i + 1) % root.modes.length];
        }
    }

    Shortcut {
        sequence: "t"
        onActivated: root.currentMode = "ocr"
    }

    Shortcut {
        sequence: "g"
        onActivated: root.currentMode = "lens"
    }

    Item {
        anchors.fill: parent
        z: 999

        HoverHandler {
            target: null
            onPointChanged: {
                if (!mouseArea.pressed) {
                    selector.mouseX = point.position.x;
                    selector.mouseY = point.position.y;
                }
            }
        }
    }
}
