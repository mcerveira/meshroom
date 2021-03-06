import QtQuick 2.7
import Qt3D.Core 2.1
import Qt3D.Render 2.1
import Qt3D.Input 2.1
import Qt3D.Logic 2.0
import QtQml 2.2

import Meshroom.Helpers 1.0

Entity {
    id: root

    property Camera camera
    property real translateSpeed: 75.0
    property real tiltSpeed: 500.0
    property real panSpeed: 500.0
    property bool moving: pressed || (actionAlt.active && keyboardHandler._pressed)
    property alias focus: keyboardHandler.focus
    readonly property bool pickingActive: actionControl.active && keyboardHandler._pressed
    property alias rotationSpeed: trackball.rotationSpeed
    property alias windowSize: trackball.windowSize
    property alias trackballSize: trackball.trackballSize

    readonly property alias pressed: mouseHandler._pressed
    signal mousePressed(var mouse)
    signal mouseReleased(var mouse)
    signal mouseClicked(var mouse)
    signal mouseWheeled(var wheel)
    signal mouseDoubleClicked(var mouse)

    KeyboardDevice { id: keyboardSourceDevice }
    MouseDevice { id: mouseSourceDevice }

    TrackballController {
        id: trackball
        camera: root.camera
    }

    MouseHandler {
        id: mouseHandler
        property bool _pressed
        property point lastPosition
        property point currentPosition
        sourceDevice: mouseSourceDevice
        onPressed: {
            _pressed = true;
            currentPosition = lastPosition = Qt.point(mouse.x, mouse.y);
            mousePressed(mouse);
        }
        onReleased: {
            _pressed = false;
            mouseReleased(mouse);
        }
        onClicked: mouseClicked(mouse)
        onPositionChanged: { currentPosition = Qt.point(mouse.x, mouse.y) }
        onDoubleClicked: mouseDoubleClicked(mouse)
        onWheel: {
            var d = (root.camera.viewCenter.minus(root.camera.position)).length() * 0.2;
            var tz = (wheel.angleDelta.y / 120) * d;
            root.camera.translate(Qt.vector3d(0, 0, tz), Camera.DontTranslateViewCenter)
        }
    }

    KeyboardHandler {
        id: keyboardHandler
        sourceDevice: keyboardSourceDevice
        property bool _pressed

        // When focus is lost while pressing a key, the corresponding action
        // stays active, even when it's released.
        // Handle this issue manually by keeping an additional _pressed state
        // which is cleared when focus changes (used for 'pickingActive' property).
        onFocusChanged: if(!focus) _pressed = false
        onPressed: _pressed = true
        onReleased: _pressed = false
    }

    LogicalDevice {
        id: cameraControlDevice
        actions: [
            Action {
                id: actionLMB
                inputs: [
                    ActionInput {
                        sourceDevice: mouseSourceDevice
                        buttons: [MouseEvent.LeftButton]
                    }
                ]
            },
            Action {
                id: actionRMB
                inputs: [
                    ActionInput {
                        sourceDevice: mouseSourceDevice
                        buttons: [MouseEvent.RightButton]
                    }
                ]
            },
            Action {
                id: actionMMB
                inputs: [
                    ActionInput {
                        sourceDevice: mouseSourceDevice
                        buttons: [MouseEvent.MiddleButton]
                    }
                ]
            },
            Action {
                id: actionShift
                inputs: [
                    ActionInput {
                        sourceDevice: keyboardSourceDevice
                        buttons: [Qt.Key_Shift]
                    }
                ]
            },
            Action {
                id: actionControl
                inputs: [
                    ActionInput {
                        sourceDevice: keyboardSourceDevice
                        buttons: [Qt.Key_Control]
                    }
                ]
            },
            Action {
                id: actionAlt
                inputs: [
                    ActionInput {
                        sourceDevice: keyboardSourceDevice
                        buttons: [Qt.Key_Alt]
                    }
                ]
            }
        ]
        axes: [
            Axis {
                id: axisMX
                inputs: [
                    AnalogAxisInput {
                        sourceDevice: mouseSourceDevice
                        axis: MouseDevice.X
                    }
                ]
            },
            Axis {
                id: axisMY
                inputs: [
                    AnalogAxisInput {
                        sourceDevice: mouseSourceDevice
                        axis: MouseDevice.Y
                    }
                ]
            }
        ]
    }

    components: [
        FrameAction {
            onTriggered: {
                if(actionMMB.active || (actionLMB.active && actionShift.active)) { // translate
                    var d = (root.camera.viewCenter.minus(root.camera.position)).length() * 0.03;
                    var tx = axisMX.value * root.translateSpeed * d;
                    var ty = axisMY.value * root.translateSpeed * d;
                    root.camera.translate(Qt.vector3d(-tx, -ty, 0).times(dt))
                    return;
                }
                if(actionLMB.active){ // trackball rotation
                    trackball.rotate(mouseHandler.lastPosition, mouseHandler.currentPosition, dt);
                    mouseHandler.lastPosition = mouseHandler.currentPosition;
                    return;
                }
                if(actionAlt.active && actionRMB.active) { // zoom with alt + RMD
                    var d = (root.camera.viewCenter.minus(root.camera.position)).length() * 0.1;
                    var tz = axisMX.value * root.translateSpeed * d;
                    root.camera.translate(Qt.vector3d(0, 0, tz).times(dt), Camera.DontTranslateViewCenter)
                    return;
                }
            }
        }
    ]
}
