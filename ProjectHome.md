Animtool provides a simple but extensible framework for crafting keyframed animation and applying it, in realtime, to anything that can be animated.

The software provides a basic GUI for editing keyframes within timelines, and saving this data to a file.

Interpolated values from all timelines can be sent to any class implementing the AnimationRecipient interface, which then forwards the current value to some other entity.

In its initial design, code is included to control servo motors via an Arduino microcontroller connected by USB or serial.