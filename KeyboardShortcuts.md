# Introduction #

As the GUI for Animtool does not employ menus, all interaction is accomplished via direct manipulation with the mouse and key strokes.


# Details #

Keyboard Commands
  * **q**: Quit. **NOTE** You should always use Q rather than closing the window or pressing ESC, due to a Processing bug where the application is not properly notified of window close events.
  * **o**: Open a timeline file
  * (Shift + s): "Save As..." Save the current timeline to a new file.
  * **s**: Save the current timeline data to the current file.
  * **r**: toggle looping playback.
  * **k**: Stop the playback head.
  * **j/l**: Play reverse/forward (each key touch accelerates playback in that direction).
  * **del/backspace**: Delete the current selection.
  * **=/-**: Zoom in/out.
  * **Arrow Up/Down**: Switch current timeline.
  * **Arrow Left/Right**: Scroll across timeline.

Mouse Interaction
  * `Shift + LeftClick`: Add a new keyframe
  * `  (drag to modify immediately)`
  * `LeftClick on keyframe`: Select that keyframe
  * `  (drag to modify immediately)`
  * `LeftClick no keyframe`: Deselect
  * `LeftClick no keyframe & drag`: Range select