hs._asm.canvas
==============

### *Update September 16, 2016*
This module as a stand alone module is no longer being developed.  It has been moved into a submodule of `hs._asm.enclosure` which aims to provide a merging and expansion of `hs.webview`, `hs.drawing`, `hs._asm.canvas`, and other NSView based submodules under a single umbrella to allow more flexibility in combining a wide variety of visual elements into a Hammerspoon controlable whole.

The documentation listed here remains valid -- a wrapper for `hs._asm.canvas` is included in the `hs._asm.enclosure` hierarchy which allows use of "canvas" as described in here with minimal to no changes in your code (no promises that things might not change as I continue with the expansion, but for right now, the sample code provided here, including the `hs.drawing` wrapper, does work with no change from what is documented here.)

<hr>

### Original documentation

A different approach to drawing in Hammerspoon

`hs.drawing` approaches graphical images as independant primitives, each "shape" being a separate drawing object based on the core primitives: ellipse, rectangle, point, line, text, etc.  This model works well with graphical elements that are expected to be managed individually and don't have complex clipping interactions, but does not scale well when more complex combinations or groups of drawing elements need to be moved or manipulated as a group, and only allows for simple inclusionary clipping regions.

This module works by designating a canvas and then assigning a series of graphical primitives to the canvas.  Included in this assignment list are rules about how the individual elements interact with each other within the canvas (compositing and clipping rules), and direct modification of the canvas itself (move, resize, etc.) causes all of the assigned elements to be adjusted as a group.

### Overview

The canvas elements are defined in an array, and each entry of the array is a table of key-value pairs describing the element at that position.  Elements are rendered in the order in which they are assigned to the array (i.e. element 1 is drawn before element 2, etc.).

Attributes for canvas elements are defined in [hs._asm.canvas.attributes](#attributes). All canvas elements require the `type` field; all other attributes have default values.  Fields required to properly define the element (for example, `frame` for the `rectangle` element type) will be copied into the element definition with their default values if they are not specified at the time of creation. Optional attributes will only be assigned in the element definition if they are specified.  When the module requires the value for an element's attribute it first checks the element definition itself, then the defaults are looked for in the canvas defaults, and then finally in the module's built in defaults (specified in the descriptions below).

Matrix operations which can be assigned to element `transformation` attributes can be found in the [MATRIX.md](MATRIX.md) file.
Examples of this module in use can found in the [EXAMPLES.md](EXAMPLES.md) file.

Documentation for a wrapper to replace the built-in `hs.drawing` with this module can be found in the [DRAWING.md](DRAWING.md) file, and the wrapper itself, if you wish to use it, can be found at [hs._asm.canvas.drawing](drawing.lua).  It is also included in the precompiled binary for this module.

An example of a module which provides a view compatibile with the [views](#views) element type can be found in the [avplayer](avplayer) directory of this module.  This example submodule adds support for playing audiovisual media within a canvas.

### Installation

A precompiled version of this module may be found in this directory with the name `canvas-v0.x.tar.gz`. This can be installed by downloading the file and then expanding it as follows:

~~~sh
$ cd ~/.hammerspoon # or wherever your Hammerspoon init.lua file is located
$ tar -xzf ~/Downloads/canvas-v0.x.tar.gz # or wherever your downloads are located
~~~

If you wish to build this module yourself, and have XCode installed on your Mac, the best way (you are welcome to clone the entire repository if you like, but no promises on the current state of anything else) is to download `init.lua`, `internal.m`, `matrix.lua`, `matrix_internal.m`, `ASMCanvas.h`, `imageAdditions.m` and `Makefile` (nothing else is required, though if you wish to try out the `hs.drawing` wrapper, include `drawing.lua` as well) into a directory of your choice and then do the following:

~~~sh
$ cd wherever-you-downloaded-the-files
$ [HS_APPLICATION=/Applications] [PREFIX=~/.hammerspoon] make install
~~~

If your Hammerspoon application is located in `/Applications`, you can leave out the `HS_APPLICATION` environment variable, and if your Hammerspoon files are located in their default location, you can leave out the `PREFIX` environment variable.  For most people it will be sufficient to just type `make install`.

As always, whichever method you chose, if you are updating from an earlier version it is recommended to fully quit and restart Hammerspoon after installing this module to ensure that the latest version of the module is loaded into memory.

- - -

### Usage
~~~lua
canvas = require("hs._asm.canvas")
~~~

### Contents

##### Module Constructors
* <a href="#new">canvas.new(rect) -> canvasObject</a>

##### Module Functions
* <a href="#defaultTextStyle">canvas.defaultTextStyle() -> `hs.styledtext` attributes table</a>
* <a href="#disableScreenUpdates">canvas.disableScreenUpdates() -> None</a>
* <a href="#elementSpec">canvas.elementSpec() -> table</a>
* <a href="#enableScreenUpdates">canvas.enableScreenUpdates() -> None</a>
* <a href="#help">canvas.help([attribute]) -> string</a>

##### Module Methods
* <a href="#alpha">canvas:alpha([alpha]) -> canvasObject | currentValue</a>
* <a href="#appendElements">canvas:appendElements(element, ...) -> canvasObject</a>
* <a href="#assignElement">canvas:assignElement(elementTable, [index]) -> canvasObject</a>
* <a href="#behavior">canvas:behavior([behavior]) -> canvasObject | currentValue</a>
* <a href="#behaviorAsLabels">canvas:behaviorAsLabels(behaviorTable) -> canvasObject | currentValue</a>
* <a href="#bringToFront">canvas:bringToFront([aboveEverything]) -> canvasObject</a>
* <a href="#canvasDefaultFor">canvas:canvasDefaultFor(keyName, [newValue]) -> canvasObject | currentValue</a>
* <a href="#canvasDefaultKeys">canvas:canvasDefaultKeys([module]) -> table</a>
* <a href="#canvasDefaults">canvas:canvasDefaults([module]) -> table</a>
* <a href="#canvasElements">canvas:canvasElements() -> table</a>
* <a href="#canvasMouseEvents">canvas:canvasMouseEvents([down], [up], [enterExit], [move]) -> canvasObject | current values</a>
* <a href="#clickActivating">canvas:clickActivating([flag]) -> canvasObject | currentValue</a>
* <a href="#copy">canvas:copy() -> canvasObject</a>
* <a href="#delete">canvas:delete([fadeOutTime]) -> none</a>
* <a href="#elementAttribute">canvas:elementAttribute(index, key, [value]) -> canvasObject | current value</a>
* <a href="#elementBounds">canvas:elementBounds(index) -> rectTable</a>
* <a href="#elementCount">canvas:elementCount() -> integer</a>
* <a href="#elementKeys">canvas:elementKeys(index, [optional]) -> table</a>
* <a href="#frame">canvas:frame([rect]) -> canvasObject | currentValue</a>
* <a href="#hide">canvas:hide([fadeOutTime]) -> canvasObject</a>
* <a href="#imageFromCanvas">canvas:imageFromCanvas() -> hs.image object</a>
* <a href="#insertElement">canvas:insertElement(elementTable, [index]) -> canvasObject</a>
* <a href="#isOccluded">canvas:isOccluded() -> boolean</a>
* <a href="#isShowing">canvas:isShowing() -> boolean</a>
* <a href="#isVisible">canvas:isVisible() -> boolean</a>
* <a href="#level">canvas:level([level]) -> canvasObject | currentValue</a>
* <a href="#minimumTextSize">canvas:minimumTextSize([index], text) -> table</a>
* <a href="#mouseCallback">canvas:mouseCallback(mouseCallbackFn) -> canvasObject</a>
* <a href="#orderAbove">canvas:orderAbove([canvas2]) -> canvasObject</a>
* <a href="#orderBelow">canvas:orderBelow([canvas2]) -> canvasObject</a>
* <a href="#removeElement">canvas:removeElement([index]) -> canvasObject</a>
* <a href="#replaceElements">canvas:replaceElements(element, ...) -> canvasObject</a>
* <a href="#rotateElement">canvas:rotateElement(index, angle, [point], [append]) -> canvasObject</a>
* <a href="#sendToBack">canvas:sendToBack() -> canvasObject</a>
* <a href="#show">canvas:show([fadeInTime]) -> canvasObject</a>
* <a href="#size">canvas:size([size]) -> canvasObject | currentValue</a>
* <a href="#topLeft">canvas:topLeft([point]) -> canvasObject | currentValue</a>
* <a href="#transformation">canvas:transformation([matrix]) -> canvasObject | current value</a>
* <a href="#wantsLayer">canvas:wantsLayer([flag]) -> canvasObject | currentValue</a>

##### Module Constants
* <a href="#compositeTypes">canvas.compositeTypes[]</a>
* <a href="#windowBehaviors">canvas.windowBehaviors[]</a>
* <a href="#windowLevels">canvas.windowLevels</a>

##### Module Fields
* <a href="#attributes">canvas.attributes</a>
* <a href="#object">canvas.object[index]</a>
* <a href="#percentages">canvas.percentages</a>
* <a href="#views">canvas.views</a>

- - -

### Module Constructors

<a name="new"></a>
~~~lua
canvas.new(rect) -> canvasObject
~~~
Create a new canvas object at the specified coordinates

Parameters:
 * `rect` - A rect-table containing the co-ordinates and size for the canvas object

Returns:
 * a new, empty, canvas object, or nil if the canvas cannot be created with the specified coordinates

Notes:
 * The size of the canvas defines the visible area of the canvas -- any portion of a canvas element which extends past the canvas's edges will be clipped.
 * a rect-table is a table with key-value pairs specifying the top-left coordinate on the screen for the canvas (keys `x`  and `y`) and the size (keys `h` and `w`) of the canvas. The table may be crafted by any method which includes these keys, including the use of an `hs.geometry` object.

### Module Functions

<a name="defaultTextStyle"></a>
~~~lua
canvas.defaultTextStyle() -> `hs.styledtext` attributes table
~~~
Returns a table containing the default font, size, color, and paragraphStyle used by `hs._asm.canvas` for text drawing objects.

Parameters:
 * None

Returns:
 * a table containing the default style attributes `hs._asm.canvas` uses for text drawing objects in the `hs.styledtext` attributes table format.

Notes:
 * This method is intended to be used in conjunction with `hs.styledtext` to create styledtext objects that are based on, or a slight variation of, the defaults used by `hs._asm.canvas`.

- - -

<a name="disableScreenUpdates"></a>
~~~lua
canvas.disableScreenUpdates() -> None
~~~
Tells the OS X window server to pause updating the physical displays for a short while.

Parameters:
 * None

Returns:
 * None

Notes:
 * This method can be used to allow multiple changes which are being made to the users display appear as if they all occur simultaneously by holding off on updating the screen on the regular schedule.
 * This method should always be balanced with a call to [hs._asm.canvas.enableScreenUpdates](#enableScreenUpdates) when your updates have been completed.  Failure to do so will be logged in the system logs.

 * The window server will only allow you to pause updates for up to 1 second.  This prevents a rogue or hung process from locking the system`s display completely.  Updates will be resumed when [hs._asm.canvas.enableScreenUpdates](#enableScreenUpdates) is encountered or after 1 second, whichever comes first.

- - -

<a name="elementSpec"></a>
~~~lua
canvas.elementSpec() -> table
~~~
Returns the list of attributes and their specifications that are recognized for canvas elements by this module.

Parameters:
 * None

Returns:
 * A table containing the attributes and specifications defined for this module.

Notes:
 * This is primarily for debugging purposes and may be removed in the future.

- - -

<a name="enableScreenUpdates"></a>
~~~lua
canvas.enableScreenUpdates() -> None
~~~
Tells the OS X window server to resume updating the physical displays after a previous pause.

Parameters:
 * None

Returns:
 * None

Notes:
 * In conjunction with [hs._asm.canvas.disableScreenUpdates](#disableScreenUpdates), this method can be used to allow multiple changes which are being made to the users display appear as if they all occur simultaneously by holding off on updating the screen on the regular schedule.
 * This method should always be preceded by a call to [hs._asm.canvas.disableScreenUpdates](#disableScreenUpdates).  Failure to do so will be logged in the system logs.

 * The window server will only allow you to pause updates for up to 1 second.  This prevents a rogue or hung process from locking the system`s display completely.  Updates will be resumed when this function is encountered  or after 1 second, whichever comes first.

- - -

<a name="help"></a>
~~~lua
canvas.help([attribute]) -> string
~~~
Provides specification information for the recognized attributes, or the specific attribute specified.

Parameters:
 * `attribute` - an optional string specifying an element attribute. If this argument is not provided, all attributes are listed.

Returns:
 * a string containing some of the information provided by the [hs._asm.canvas.elementSpec](#elementSpec) in a manner that is easy to reference from the Hammerspoon console.

### Module Methods

<a name="alpha"></a>
~~~lua
canvas:alpha([alpha]) -> canvasObject | currentValue
~~~
Get or set the alpha level of the window containing the canvasObject.

Parameters:
 * `alpha` - an optional number specifying the new alpha level (0.0 - 1.0, inclusive) for the canvasObject

Returns:
 * If an argument is provided, the canvas object; otherwise the current value.

- - -

<a name="appendElements"></a>
~~~lua
canvas:appendElements(element, ...) -> canvasObject
~~~
Appends the elements specified to the canvas.

Parameters:
 * `element` - a table containing key-value pairs that define the element to be appended to the canvas.  You can specify one or more elements and they will be appended in the order they are listed.

Returns:
 * the canvas object

Notes:
 * You can also specify multiple elements in a table as an array, where each index in the table contains an element table, and use the array as a single argument to this method if this style works better in your code.

- - -

<a name="assignElement"></a>
~~~lua
canvas:assignElement(elementTable, [index]) -> canvasObject
~~~
Assigns a new element to the canvas at the specified index.

Parameters:
 * `elementTable` - a table containing key-value pairs that define the element to be added to the canvas.
 * `index`        - an optional integer between 1 and the canvas element count + 1 specifying the index position to put the new element.  Any element currently at that index will be replaced.  Defaults to the canvas element count + 1 (i.e. after the end of the currently defined elements).

Returns:
 * the canvasObject

Notes:
 * When the index specified is the canvas element count + 1, the behavior of this method is the same as [hs._asm.canvas:insertElement](#insertElement); i.e. it adds the new element to the end of the currently defined element list.

- - -

<a name="behavior"></a>
~~~lua
canvas:behavior([behavior]) -> canvasObject | currentValue
~~~
Get or set the window behavior settings for the canvas object.

Parameters:
 * `behavior` - an optional number representing the desired window behaviors for the canvas object.

Returns:
 * If an argument is provided, the canvas object; otherwise the current value.

Notes:
 * Window behaviors determine how the canvas object is handled by Spaces and Exposé. See [hs._asm.canvas.windowBehaviors](#windowBehaviors) for more information.

- - -

<a name="behaviorAsLabels"></a>
~~~lua
canvas:behaviorAsLabels(behaviorTable) -> canvasObject | currentValue
~~~
Get or set the window behavior settings for the canvas object using labels defined in [hs._asm.canvas.windowBehaviors](#windowBehaviors).

Parameters:
 * behaviorTable - an optional table of strings and/or numbers specifying the desired window behavior for the canvas object.

Returns:
 * If an argument is provided, the canvas object; otherwise the current value.

- - -

<a name="bringToFront"></a>
~~~lua
canvas:bringToFront([aboveEverything]) -> canvasObject
~~~
Places the canvas object on top of normal windows

Parameters:
 * aboveEverything - An optional boolean value that controls how far to the front the canvas should be placed. Defaults to false.
   * if true, place the canvas on top of all windows (including the dock and menubar and fullscreen windows).
   * if false, place the canvas above normal windows, but below the dock, menubar and fullscreen windows.

Returns:
 * The canvas object

- - -

<a name="canvasDefaultFor"></a>
~~~lua
canvas:canvasDefaultFor(keyName, [newValue]) -> canvasObject | currentValue
~~~
Get or set the element default specified by keyName.

Paramters:
 * `keyName` - the element default to examine or modify
 * `value`   - an optional new value to set as the default fot his canvas when not specified explicitly in an element declaration.

Returns:
 * If an argument is provided, the canvas object; otherwise the current value.

Notes:
 * Not all keys will apply to all element types.
 * Currently set and built-in defaults may be retrieved in a table with [hs._asm.canvas:canvasDefaults](#canvasDefaults).

- - -

<a name="canvasDefaultKeys"></a>
~~~lua
canvas:canvasDefaultKeys([module]) -> table
~~~
Returns a list of the key names for the attributes set for the canvas defaults.

Parameters:
 * `module` - an optional boolean flag, default false, indicating whether the key names for the module defaults (true) should be included in the list.  If false, only those defaults which have been explicitly set for the canvas are included.

Returns:
 * a table containing the key names for the defaults which are set for this canvas. May also optionally include key names for all attributes which have a default value defined by the module.

- - -

<a name="canvasDefaults"></a>
~~~lua
canvas:canvasDefaults([module]) -> table
~~~
Get a table of the default key-value pairs which apply to the canvas.

Parameters:
 * `module` - an optional boolean flag, default false, indicating whether module defaults (true) should be included in the table.  If false, only those defaults which have been explicitly set for the canvas are returned.

Returns:
 * a table containing key-value pairs for the defaults which apply to the canvas.

Notes:
 * Not all keys will apply to all element types.
 * To change the defaults for the canvas, use [hs._asm.canvas:canvasDefaultFor](#canvasDefaultFor).

- - -

<a name="canvasElements"></a>
~~~lua
canvas:canvasElements() -> table
~~~
Returns an array containing the elements defined for this canvas.  Each array entry will be a table containing the key-value pairs which have been set for that canvas element.

Parameters:
 * None

Returns:
 * an array of element tables which are defined for the canvas.

- - -

<a name="canvasMouseEvents"></a>
~~~lua
canvas:canvasMouseEvents([down], [up], [enterExit], [move]) -> canvasObject | current values
~~~
Get or set whether or not regions of the canvas which are not otherwise covered by an element with mouse tracking enabled should generate a callback for mouse events.

Parameters:
 * `down`      - an optional boolean, or nil placeholder, specifying whether or not the mouse button being pushed down should generate a callback for the canvas areas not otherwise covered by an element with mouse tracking enabled.
 * `up`        - an optional boolean, or nil placeholder, specifying whether or not the mouse button being released should generate a callback for the canvas areas not otherwise covered by an element with mouse tracking enabled.
 * `enterExit` - an optional boolean, or nil placeholder, specifying whether or not the mouse pointer entering or exiting the canvas bounds should generate a callback for the canvas areas not otherwise covered by an element with mouse tracking enabled.
 * `move`      - an optional boolean, or nil placeholder, specifying whether or not the mouse pointer moving within the canvas bounds should generate a callback for the canvas areas not otherwise covered by an element with mouse tracking enabled.

Returns:
 * If any arguments are provided, returns the canvas Object, otherwise returns the current values as four separate boolean values (i.e. not in a table).

Notes:
 * Each value that you wish to set must be provided in the order given above, but you may specify a position as `nil` to indicate that whatever it's current state, no change should be applied.  For example, to activate a callback for entering and exiting the canvas without changing the current callback status for up or down button clicks, you could use: `hs._asm.canvas:canvasMouseTracking(nil, nil, true)`.

 * Use [hs._asm.canvas:mouseCallback](#mouseCallback) to set the callback function.  The identifier field in the callback's argument list will be "_canvas_", but otherwise identical to those specified in [hs._asm.canvas:mouseCallback](#mouseCallback).

- - -

<a name="clickActivating"></a>
~~~lua
canvas:clickActivating([flag]) -> canvasObject | currentValue
~~~
Get or set whether or not clicking on a canvas with a click callback defined should bring all of Hammerspoon's open windows to the front.

Parameters:
 * `flag` - an optional boolean indicating whether or not clicking on a canvas with a click callback function defined should activate Hammerspoon and bring its windows forward. Defaults to true.

Returns:
 * If an argument is provided, returns the canvas object; otherwise returns the current setting.

Notes:
 * Setting this to false changes a canvas object's AXsubrole value and may affect the results of filters used with `hs.window.filter`, depending upon how they are defined.

- - -

<a name="copy"></a>
~~~lua
canvas:copy() -> canvasObject
~~~
Creates a copy of the canvas.

Parameters:
 * None

Returns:
 * a copy of the canvas

Notes:
 * The copy of the canvas will be identical in all respectes except:
   * The new canvas will not have a callback function assigned, even if the original canvas does.
   * The new canvas will not initially be visible, even if the original is.
 * The new canvas is an independant entity -- any subsequent changes to either canvas will not be reflected in the other canvas.

 * This method allows you to display a canvas in multiple places or use it as a canvas element multiple times.

- - -

<a name="delete"></a>
~~~lua
canvas:delete([fadeOutTime]) -> none
~~~
Destroys the canvas object, optionally fading it out first (if currently visible).

Parameters:
 * `fadeOutTime` - An optional number of seconds over which to fade out the canvas object. Defaults to zero.

Returns:
 * None

Notes:
 * This method is automatically called during garbage collection, notably during a Hammerspoon termination or reload, with a fade time of 0.

- - -

<a name="elementAttribute"></a>
~~~lua
canvas:elementAttribute(index, key, [value]) -> canvasObject | current value
~~~
Get or set the attribute `key` for the canvas element at the specified index.

Parameters:
 * `index` - the index of the canvas element whose attribute is to be retrieved or set.
 * `key`   - the key name of the attribute to get or set.
 * `value` - an optional value to assign to the canvas element's attribute.

Returns:
 * if a value for the attribute is specified, returns the canvas object; otherwise returns the current value for the specified attribute.

- - -

<a name="elementBounds"></a>
~~~lua
canvas:elementBounds(index) -> rectTable
~~~
Returns the smallest rectangle which can fully contain the canvas element at the specified index.

Parameters:
 * `index` - the index of the canvas element to get the bounds for

Returns:
 * a rect table containing the smallest rectangle which can fully contain the canvas element.

Notes:
 * For many elements, this will be the same as the element frame.  For items without a frame (e.g. `segments`, `circle`, etc.) this will be the smallest rectangle which can fully contain the canvas element as specified by it's attributes.

- - -

<a name="elementCount"></a>
~~~lua
canvas:elementCount() -> integer
~~~
Returns the number of elements currently defined for the canvas object.

Parameters:
 * None

Returns:
 * the number of elements currently defined for the canvas object.

- - -

<a name="elementKeys"></a>
~~~lua
canvas:elementKeys(index, [optional]) -> table
~~~
Returns a list of the key names for the attributes set for the canvas element at the specified index.

Parameters:
 * `index`    - the index of the element to get the assigned key list from.
 * `optional` - an optional boolean, default false, indicating whether optional, but unset, keys relevant to this canvas object should also be included in the list returned.

Returns:
 * a table containing the keys that are set for this canvas element.  May also optionally include keys which are not specifically set for this element but use inherited values from the canvas or module defaults.

Notes:
 * Any attribute which has been explicitly set for the element will be included in the key list (even if it is ignored for the element type).  If the `optional` flag is set to true, the *additional* attribute names added to the list will only include those which are relevant to the element type.

- - -

<a name="frame"></a>
~~~lua
canvas:frame([rect]) -> canvasObject | currentValue
~~~
Get or set the frame of the canvasObject.

Parameters:
 * rect - An optional rect-table containing the co-ordinates and size the canvas object should be moved and set to

Returns:
 * If an argument is provided, the canvas object; otherwise the current value.

Notes:
 * a rect-table is a table with key-value pairs specifying the new top-left coordinate on the screen of the canvas (keys `x`  and `y`) and the new size (keys `h` and `w`).  The table may be crafted by any method which includes these keys, including the use of an `hs.geometry` object.

 * elements in the canvas that have the `absolutePosition` attribute set to false will be moved so that their relative position within the canvas remains the same with respect to the new size.
 * elements in the canvas that have the `absoluteSize` attribute set to false will be resized so that their relative size with respect to the canvas remains the same with respect to the new size.

- - -

<a name="hide"></a>
~~~lua
canvas:hide([fadeOutTime]) -> canvasObject
~~~
Hides the canvas object

Parameters:
 * `fadeOutTime` - An optional number of seconds over which to fade out the canvas object. Defaults to zero.

Returns:
 * The canvas object

- - -

<a name="imageFromCanvas"></a>
~~~lua
canvas:imageFromCanvas() -> hs.image object
~~~
Returns an image of the canvas contents as an `hs.image` object.

Parameters:
 * None

Returns:
 * an `hs.image` object

Notes:
 * The canvas does not have to be visible in order for an image to be generated from it.

- - -

<a name="insertElement"></a>
~~~lua
canvas:insertElement(elementTable, [index]) -> canvasObject
~~~
Insert a new element into the canvas at the specified index.

Parameters:
 * `elementTable` - a table containing key-value pairs that define the element to be added to the canvas.
 * `index`        - an optional integer between 1 and the canvas element count + 1 specifying the index position to put the new element.  Any element currently at that index, and those that follow, will be moved one position up in the element array.  Defaults to the canvas element count + 1 (i.e. after the end of the currently defined elements).

Returns:
 * the canvasObject

Notes:
 * see also [hs._asm.canvas:assignElement](#assignElement).

- - -

<a name="isOccluded"></a>
~~~lua
canvas:isOccluded() -> boolean
~~~
Returns whether or not the canvas is currently occluded (hidden by other windows, off screen, etc).

Parameters:
 * None

Returns:
 * a boolean indicating whether or not the canvas is currently being occluded.

Notes:
 * If any part of the canvas is visible (even if that portion of the canvas does not contain any canvas elements), then the canvas is not considered occluded.
 * a canvas which is completely covered by one or more opaque windows is considered occluded; however, if the windows covering the canvas are not opaque, then the canvas is not occluded.
 * a canvas that is currently hidden or with a height of 0 or a width of 0 is considered occluded.
 * See also [hs._asm.canvas:isShowing](#isShowing).

- - -

<a name="isShowing"></a>
~~~lua
canvas:isShowing() -> boolean
~~~
Returns whether or not the canvas is currently being shown.

Parameters:
 * None

Returns:
 * a boolean indicating whether or not the canvas is currently being shown (true) or is currently hidden (false).

Notes:
 * This method only determines whether or not the canvas is being shown or is hidden -- it does not indicate whether or not the canvas is currently off screen or is occluded by other objects.
 * See also [hs._asm.canvas:isOccluded](#isOccluded).

- - -

<a name="isVisible"></a>
~~~lua
canvas:isVisible() -> boolean
~~~
Returns whether or not the canvas is currently showing and is (at least partially) visible on screen.

Parameters:
 * None

Returns:
 * a boolean indicating whether or not the canvas is currently visible.

Notes:
 * This is syntactic sugar for `not hs._asm.canvas:isOccluded()`.
 * See (hs._asm.canvas:isOccluded)[#isOccluded] for more details.

- - -

<a name="level"></a>
~~~lua
canvas:level([level]) -> canvasObject | currentValue
~~~
Sets the window level more precisely than sendToBack and bringToFront.

Parameters:
 * `level` - an optional level, specified as a number or as a string, specifying the new window level for the canvasObject. If it is a string, it must match one of the keys in [hs._asm.canvas.windowLevels](#windowLevels).

Returns:
 * If an argument is provided, the canvas object; otherwise the current value.

- - -

<a name="minimumTextSize"></a>
~~~lua
canvas:minimumTextSize([index], text) -> table
~~~
Returns a table specifying the size of the rectangle which can fully render the text with the specified style so that is will be completely visible.

Parameters:
 * `index` - an optional index specifying the element in the canvas which contains the text attributes which should be used when determining the size of the text. If not provided, the canvas defaults will be used instead. Ignored if `text` is an hs.styledtext object.
 * `text`  - a string or hs.styledtext object specifying the text.

Returns:
 * a size table specifying the height and width of a rectangle which could fully contain the text when displayed in the canvas

Notes:
 * Multi-line text (separated by a newline or return) is supported.  The height will be for the multiple lines and the width returned will be for the longest line.

- - -

<a name="mouseCallback"></a>
~~~lua
canvas:mouseCallback(mouseCallbackFn) -> canvasObject
~~~
Sets a callback for mouse events with respect to the canvas

Parameters:
 * `mouseCallbackFn`   - A function, can be nil, that will be called when a mouse event occurs within the canvas, and an element beneath the mouse's current position has one of the `trackMouse...` attributes set to true.

Returns:
 * The canvas object

Notes:
 * The callback function should expect 5 arguments: the canvas object itself, a message specifying the type of mouse event, the canvas element `id` (or index position in the canvas if the `id` attribute is not set for the element), the x position of the mouse when the event was triggered within the rendered portion of the canvas element, and the y position of the mouse when the event was triggered within the rendered portion of the canvas element.
 * See also [hs._asm.canvas:canvasMouseEvents](#canvasMouseEvents) for tracking mouse events in regions of the canvas not covered by an element with mouse tracking enabled.

 * The following mouse attributes may be set to true for a canvas element and will invoke the callback with the specified message:
   * `trackMouseDown`      - indicates that a callback should be invoked when a mouse button is clicked down on the canvas element.  The message will be "mouseDown".
   * `trackMouseUp`        - indicates that a callback should be invoked when a mouse button has been released over the canvas element.  The message will be "mouseUp".
   * `trackMouseEnterExit` - indicates that a callback should be invoked when the mouse pointer enters or exits the  canvas element.  The message will be "mouseEnter".
   * `trackMouseMove`      - indicates that a callback should be invoked when the mouse pointer moves within the canvas element.  The message will be "mouseMove".

 * The callback mechanism uses reverse z-indexing to determine which element will receive the callback -- the topmost element of the canvas which has enabled callbacks for the specified message will be invoked.

 * No distinction is made between the left, right, or other mouse buttons. If you need to determine which specific button was pressed, use `hs.eventtap.checkMouseButtons()` within your callback to check.

 * The hit point detection occurs by comparing the mouse pointer location to the rendered content of each individual canvas object... if an object which obscures a lower object does not have mouse tracking enabled, the lower object will still receive the event if it does have tracking enabled.

 * Clipping regions which remove content from the visible area of a rendered object are ignored for the purposes of element hit-detection.

- - -

<a name="orderAbove"></a>
~~~lua
canvas:orderAbove([canvas2]) -> canvasObject
~~~
Moves canvas object above canvas2, or all canvas objects in the same presentation level, if canvas2 is not given.

Parameters:
 * `canvas2` -An optional canvas object to place the canvas object above.

Returns:
 * The canvas object

Notes:
 * If the canvas object and canvas2 are not at the same presentation level, this method will will move the canvas object as close to the desired relationship as possible without changing the canvas object's presentation level. See [hs._asm.canvas.level](#level).

- - -

<a name="orderBelow"></a>
~~~lua
canvas:orderBelow([canvas2]) -> canvasObject
~~~
Moves canvas object below canvas2, or all canvas objects in the same presentation level, if canvas2 is not given.

Parameters:
 * `canvas2` -An optional canvas object to place the canvas object below.

Returns:
 * The canvas object

Notes:
 * If the canvas object and canvas2 are not at the same presentation level, this method will will move the canvas object as close to the desired relationship as possible without changing the canvas object's presentation level. See [hs._asm.canvas.level](#level).

- - -

<a name="removeElement"></a>
~~~lua
canvas:removeElement([index]) -> canvasObject
~~~
Insert a new element into the canvas at the specified index.

Parameters:
 * `index`        - an optional integer between 1 and the canvas element count specifying the index of the canvas element to remove. Any elements that follow, will be moved one position down in the element array.  Defaults to the canvas element count (i.e. the last element of the currently defined elements).

Returns:
 * the canvasObject

- - -

<a name="replaceElements"></a>
~~~lua
canvas:replaceElements(element, ...) -> canvasObject
~~~
Replaces all of the elements in the canvas with the elements specified.  Shortens or lengthens the canvas element count if necessary to accomodate the new canvas elements.

Parameters:
 * `element` - a table containing key-value pairs that define the element to be assigned to the canvas.  You can specify one or more elements and they will be appended in the order they are listed.

Returns:
 * the canvas object

Notes:
 * You can also specify multiple elements in a table as an array, where each index in the table contains an element table, and use the array as a single argument to this method if this style works better in your code.

- - -

<a name="rotateElement"></a>
~~~lua
canvas:rotateElement(index, angle, [point], [append]) -> canvasObject
~~~
Rotates an element about the point specified, or the elements center if no point is specified.

Parameters:
 * `index`  - the index of the element to rotate
 * `angle`  - the angle to rotate the object in a clockwise direction
 * `point`  - an optional point table, defaulting to the elements center, specifying the point around which the object should be rotated
 * `append` - an optional boolean, default false, specifying whether or not the rotation transformation matrix should be appended to the existing transformation assigned to the element (true) or replace it (false).

Returns:
 * the canvas object

Notes:
 * a point-table is a table with key-value pairs specifying a coordinate in the canvas (keys `x`  and `y`). The table may be crafted by any method which includes these keys, including the use of an `hs.geometry` object.
 * The center of the object is determined by getting the element's bounds with [hs._asm.canvas:elementBounds](#elementBounds).
 * If the third argument is a boolean value, the `point` argument is assumed to be the element's center and the boolean value is used as the `append` argument.

 * This method uses [hs._asm.canvas.matrix](MATRIX.md) to generate the rotation transformation and provides a wrapper for `hs._asm.canvas.matrix.translate(x, y):rotate(angle):translate(-x, -y)` which is then assigned or appended to the element's existing `transformation` attribute.

- - -

<a name="sendToBack"></a>
~~~lua
canvas:sendToBack() -> canvasObject
~~~
Places the canvas object behind normal windows, between the desktop wallpaper and desktop icons

Parameters:
 * None

Returns:
 * The canvas object

- - -

<a name="show"></a>
~~~lua
canvas:show([fadeInTime]) -> canvasObject
~~~
Displays the canvas object

Parameters:
 * `fadeInTime` - An optional number of seconds over which to fade in the canvas object. Defaults to zero.

Returns:
 * The canvas object

Notes:
 * if the canvas is in use as an element in another canvas, this method will result in an error.

- - -

<a name="size"></a>
~~~lua
canvas:size([size]) -> canvasObject | currentValue
~~~
Get or set the size of a canvas object

Parameters:
 * `size` - An optional size-table specifying the width and height the canvas object should be resized to

Returns:
 * If an argument is provided, the canvas object; otherwise the current value.

Notes:
 * a size-table is a table with key-value pairs specifying the size (keys `h` and `w`) the canvas should be resized to. The table may be crafted by any method which includes these keys, including the use of an `hs.geometry` object.

 * elements in the canvas that have the `absolutePosition` attribute set to false will be moved so that their relative position within the canvas remains the same with respect to the new size.
 * elements in the canvas that have the `absoluteSize` attribute set to false will be resized so that their relative size with respect to the canvas remains the same with respect to the new size.

- - -

<a name="topLeft"></a>
~~~lua
canvas:topLeft([point]) -> canvasObject | currentValue
~~~
Get or set the top-left coordinate of the canvas object

Parameters:
 * `point` - An optional point-table specifying the new coordinate the top-left of the canvas object should be moved to

Returns:
 * If an argument is provided, the canvas object; otherwise the current value.

Notes:
 * a point-table is a table with key-value pairs specifying the new top-left coordinate on the screen of the canvas (keys `x`  and `y`). The table may be crafted by any method which includes these keys, including the use of an `hs.geometry` object.

- - -

<a name="transformation"></a>
~~~lua
canvas:transformation([matrix]) -> canvasObject | current value
~~~
Get or set the matrix transformation which is applied to every element in the canvas before being individually processed and added to the canvas.

Parameters:
 * `matrix` - an optional table specifying the matrix table, as defined by the [hs._asm.canvas.matrix](MATRIX.md) module, to be applied to every element of the canvas, or an explicit `nil` to reset the transformation to the identity matrix.

Returns:
 * if an argument is provided, returns the canvasObject, otherwise returns the current value

Notes:
 * An example use for this method would be to change the canvas's origin point { x = 0, y = 0 } from the lower left corner of the canvas to somewhere else, like the middle of the canvas.

- - -

<a name="wantsLayer"></a>
~~~lua
canvas:wantsLayer([flag]) -> canvasObject | currentValue
~~~
Get or set whether or not the canvas object should be rendered by the view or by Core Animation.

Parameters:
 * `flag` - optional boolean (default false) which indicates whether the canvas object should be rendered by the containing view (false) or by Core Animation (true).

Returns:
 * If an argument is provided, the canvas object; otherwise the current value.

Notes:
 * This method can help smooth the display of small text objects on non-Retina monitors.

### Module Constants

<a name="compositeTypes"></a>
~~~lua
canvas.compositeTypes[]
~~~
A table containing the possible compositing rules for elements within the canvas.

Compositing rules specify how an element assigned to the canvas is combined with the earlier elements of the canvas. The default compositing rule for the canvas is `sourceOver`, but each element of the canvas can be assigned a composite type which overrides this default for the specific element.

The available types are as follows:
 * `clear`           - Transparent. (R = 0)
 * `copy`            - Source image. (R = S)
 * `sourceOver`      - Source image wherever source image is opaque, and destination image elsewhere. (R = S + D*(1 - Sa))
 * `sourceIn`        - Source image wherever both images are opaque, and transparent elsewhere. (R = S*Da)
 * `sourceOut`       - Source image wherever source image is opaque but destination image is transparent, and transparent elsewhere. (R = S*(1 - Da))
 * `sourceAtop`      - Source image wherever both images are opaque, destination image wherever destination image is opaque but source image is transparent, and transparent elsewhere. (R = S*Da + D*(1 - Sa))
 * `destinationOver` - Destination image wherever destination image is opaque, and source image elsewhere. (R = S*(1 - Da) + D)
 * `destinationIn`   - Destination image wherever both images are opaque, and transparent elsewhere. (R = D*Sa)
 * `destinationOut`  - Destination image wherever destination image is opaque but source image is transparent, and transparent elsewhere. (R = D*(1 - Sa))
 * `destinationAtop` - Destination image wherever both images are opaque, source image wherever source image is opaque but destination image is transparent, and transparent elsewhere. (R = S*(1 - Da) + D*Sa)
 * `XOR`             - Exclusive OR of source and destination images. (R = S*(1 - Da) + D*(1 - Sa)). Works best with black and white images and is not recommended for color contexts.
 * `plusDarker`      - Sum of source and destination images, with color values approaching 0 as a limit. (R = MAX(0, (1 - D) + (1 - S)))
 * `plusLighter`     - Sum of source and destination images, with color values approaching 1 as a limit. (R = MIN(1, S + D))

In each equation, R is the resulting (premultiplied) color, S is the source color, D is the destination color, Sa is the alpha value of the source color, and Da is the alpha value of the destination color.

The `source` object is the individual element as it is rendered in order within the canvas, and the `destination` object is the combined state of the previous elements as they have been composited within the canvas.

- - -

<a name="windowBehaviors"></a>
~~~lua
canvas.windowBehaviors[]
~~~
Array of window behavior labels for determining how a canvas, drawing, or webview object is handled in Spaces and Exposé

* `default`                   - The window can be associated to one space at a time.
* `canJoinAllSpaces`          - The window appears in all spaces. The menu bar behaves this way.
* `moveToActiveSpace`         - Making the window active does not cause a space switch; the window switches to the active space.

Only one of these may be active at a time:

* `managed`                   - The window participates in Spaces and Exposé. This is the default behavior if windowLevel is equal to NSNormalWindowLevel.
* `transient`                 - The window floats in Spaces and is hidden by Exposé. This is the default behavior if windowLevel is not equal to NSNormalWindowLevel.
* `stationary`                - The window is unaffected by Exposé; it stays visible and stationary, like the desktop window.

The following have no effect on `hs._asm.canvas` or `hs.drawing` objects, but can be used with windows created by other modules (as of this writing, `hs.webview` and the Hammerspoon console itself)

Only one of these may be active at a time:

* `participatesInCycle`       - The window participates in the window cycle for use with the Cycle Through Windows Window menu item.
* `ignoresCycle`              - The window is not part of the window cycle for use with the Cycle Through Windows Window menu item.

Only one of these may be active at a time:

* `fullScreenPrimary`         - A window with this collection behavior has a fullscreen button in the upper right of its titlebar.
* `fullScreenAuxiliary`       - Windows with this collection behavior can be shown on the same space as the fullscreen window.

Only one of these may be active at a time (Available in OS X 10.11 and later):

* `fullScreenAllowsTiling`    - A window with this collection behavior be a full screen tile window and does not have to have `fullScreenPrimary` set.
* `fullScreenDisallowsTiling` - A window with this collection behavior cannot be made a fullscreen tile window, but it can have `fullScreenPrimary` set.  You can use this setting to prevent other windows from being placed in the window’s fullscreen tile.

- - -

<a name="windowLevels"></a>
~~~lua
canvas.windowLevels
~~~
A table of predefined window levels usable with [hs._asm.canvas:level](#level)

Predefined levels are:
 * _MinimumWindowLevelKey - lowest allowed window level
 * desktop
 * desktopIcon            - [hs._asm.canvas:sendToBack](#sendToBack) is equivalent to this level - 1
 * normal                 - normal application windows
 * tornOffMenu
 * floating               - equivalent to [hs._asm.canvas:bringToFront(false)](#bringToFront); where "Always Keep On Top" windows are usually set
 * modalPanel             - modal alert dialog
 * utility
 * dock                   - level of the Dock
 * mainMenu               - level of the Menubar
 * status
 * popUpMenu              - level of a menu when displayed (open)
 * overlay
 * help
 * dragging
 * screenSaver            - equivalent to [hs._asm.canvas:bringToFront(true)](#bringToFront)
 * assistiveTechHigh
 * cursor
 * _MaximumWindowLevelKey - highest allowed window level

Notes:
 * These key names map to the constants used in CoreGraphics to specify window levels and may not actually be used for what the name might suggest. For example, tests suggest that an active screen saver actually runs at a level of 2002, rather than at 1000, which is the window level corresponding to kCGScreenSaverWindowLevelKey.
 * Each window level is sorted separately and [hs._asm.canvas:orderAbove](#orderAbove) and [hs._asm.canvas:orderBelow](#orderBelow) only arrange windows within the same level.
 * If you use Dock hiding (or in 10.11, Menubar hiding) please note that when the Dock (or Menubar) is popped up, it is done so with an implicit orderAbove, which will place it above any items you may also draw at the Dock (or MainMenu) level.

### Module Fields

<a name="attributes"></a>
~~~lua
canvas.attributes
~~~
Canvas Element Attributes

* `type` - specifies the type of canvas element the table represents. This attribute has no default and must be specified for each element in the canvas array. Valid type strings are:
  * `arc`           - an arc inscribed on a circle, defined by `radius`, `center`, `startAngle`, and `endAngle`.
  * `circle`        - a circle, defined by `radius` and `center`.
  * `ellipticalArc` - an arc inscribed on an oval, defined by `frame`, `startAngle`, and `endAngle`.
  * `image`         - an image as defined by one of the `hs.image` constructors.
  * `oval`          - an oval, defined by `frame`
  * `points`        - a list of points defined in `coordinates`.
  * `rectangle`     - a rectangle, optionally with rounded corners, defined by `frame`.
  * `resetClip`     - a special type -- indicates that the current clipping shape should be reset to the canvas default (the full canvas area).  See `Clipping Example`.  All other attributes, except `action` are ignored.
  * `segments`      - a list of line segments or bezier curves with control points, defined in `coordinates`.
  * `text`          - a string or `hs.styledtext` object, defined by `text` and `frame`.
  * `view`          - an independent userdata object, possibly defined by another module, which can be displayed as an element within the specified frame. Defined by `view` and `frame`. See [hs._asm.canvas.views](#views) for more information.

* The following is a list of all valid attributes.  Not all attributes apply to every type, but you can set them for any type.
  * `action`              - Default `strokeAndFill`. A string specifying the action to take for the element in the array.  The following actions are recognized:
    * `clip`          - append the shape to the current clipping region for the canvas. Ignored for `canvas`, `image`, and `text` types.
    * `build`         - do not render the element -- its shape is preserved and the next element in the canvas array is appended to it.  This can be used to create complex shapes or clipping regions. The stroke and fill settings for a complex object created in this manner will be those of the final object of the group. Ignored for `canvas`, `image`, and `text` types.
    * `fill`          - fill the canvas element, if it is a shape, or display it normally if it is a `canvas`, `image` or `text`.  Ignored for `resetClip`.
    * `skip`          - ignore this element or its effects.  Can be used to temporarily "remove" an object from the canvas.
    * `stroke`        - stroke (outline) the canvas element, if it is a shape, or display it normally if it is a `canvas`, `image` or `text`.  Ignored for `resetClip`.
    * `strokeAndFill` - stroke and fill the canvas element, if it is a shape, or display it normally if it is a `canvas`, `image` or `text`.  Ignored for `resetClip`.
  * `absolutePosition`    - Default `true`. If false, numeric location and size attributes (`frame`, `center`, `radius`, and `coordinates`) will be automatically adjusted when the canvas is resized with [hs._asm.canvas:size](#size) or [hs._asm.canvas:frame](#frame) so that the element remains in the same relative position in the canvas.
  * `absoluteSize`        - Default `true`. If false, numeric location and size attributes (`frame`, `center`, `radius`, and `coordinates`) will be automatically adjusted when the canvas is resized with [hs._asm.canvas:size](#size) or [hs._asm.canvas:frame](#frame) so that the element maintains the same relative size in the canvas.
  * `antialias`           - Default `true`.  Indicates whether or not antialiasing should be enabled for the element.
  * `arcRadii`            - Default `true`. Used by the `arc` and `ellipticalArc` types to specify whether or not line segments from the element's center to the start and end angles should be included in the element's visible portion.  This affects whether the object's stroke is a pie-shape or an arc with a chord from the start angle to the end angle.
  * `arcClockwise`        - Default `true`.  Used by the `arc` and `ellipticalArc` types to specify whether the arc should be drawn from the start angle to the end angle in a clockwise (true) direction or in a counter-clockwise (false) direction.
  * `compositeRule`       - A string, default "sourceOver", specifying how this element should be combined with earlier elements of the canvas.  See [hs._asm.canvas.compositeTypes](#compositeTypes) for a list of valid strings and their descriptions.
  * `center`              - Default `{ x = "50%", y = "50%" }`.  Used by the `circle` and `arc` types to specify the center of the canvas element.  The `x` and `y` fields can be specified as numbers or as a string. When specified as a string, the value is treated as a percentage of the canvas size.  See the section on [percentages](#percentages) for more information.
  * `clipToPath`          - Default `false`.   Specifies whether the clipping regions should be temporarily limited to the element's shape while rendering this element or not.  This can be used to produce crisper edges, as seen with `hs.drawing` but reduces stroke width granularity for widths less than 1.0 and causes occasional "missing" lines with the `segments` element type. Ignored for the `canvas`, `image`, `point`, and `text` types.
  * `closed`              - Default `false`.  Used by the `segments` type to specify whether or not the shape defined by the lines and curves defined should be closed (true) or open (false).  When an object is closed, an implicit line is stroked from the final point back to the initial point of the coordinates listed.
  * `coordinates`         - An array containing coordinates used by the `segments` and `points` types to define the lines and curves or points that make up the canvas element.  The following keys are recognized and may be specified as numbers or strings (see the section on [percentages](#percentages)).
    * `x`   - required for `segments` and `points`, specifying the x coordinate of a point.
    * `y`   - required for `segments` and `points`, specifying the y coordinate of a point.
    * `c1x` - optional for `segments, specifying the x coordinate of the first control point used to draw a bezier curve between this point and the previous point.  Ignored for `points` and if present in the first coordinate in the `coordinates` array.
    * `c1y` - optional for `segments, specifying the y coordinate of the first control point used to draw a bezier curve between this point and the previous point.  Ignored for `points` and if present in the first coordinate in the `coordinates` array.
    * `c2x` - optional for `segments, specifying the x coordinate of the second control point used to draw a bezier curve between this point and the previous point.  Ignored for `points` and if present in the first coordinate in the `coordinates` array.
    * `c2y` - optional for `segments, specifying the y coordinate of the second control point used to draw a bezier curve between this point and the previous point.  Ignored for `points` and if present in the first coordinate in the `coordinates` array.
  * `endAngle`            - Default `360.0`. Used by the `arc` and `ellipticalArc` to specify the ending angle position for the inscribed arc.
  * `fillColor`           - Default `{ red = 1.0 }`.  Specifies the color used to fill the canvas element when the `action` is set to `fill` or `strokeAndFill` and `fillGradient` is equal to `none`.  Ignored for the `canvas`, `image`, `points`, and `text` types.
  * `fillGradient`        - Default "none".  A string specifying whether a fill gradient should be used instead of the fill color when the action is `fill` or `strokeAndFill`.  May be "none", "linear", or "radial".
  * `fillGradientAngle`   - Default 0.0.  Specifies the direction of a linear gradient when `fillGradient` is linear.
  * `fillGradientCenter`  - Default `{ x = 0.0, y = 0.0 }`. Specifies the relative center point within the elements bounds of a radial gradient when `fillGradient` is `radial`.  The `x` and `y` fields must both be between -1.0 and 1.0 inclusive.
  * `fillGradientColors`  - Default `{ { white = 0.0 }, { white = 1.0 } }`.  Specifies the colors to use for the gradient when `fillGradient` is not `none`.  You must specify at least two colors, each of which must be convertible into the RGB color space (i.e. they cannot be an image being used as a color pattern).  The gradient will blend from the first to the next, and so on until the last color.  If more than two colors are specified, the "color stops" will be placed at evenly spaced intervals within the element.
  * `flatness`            - Default `0.6`.  A number which specifies the accuracy (or smoothness) with which curves are rendered. It is also the maximum error tolerance (measured in pixels) for rendering curves, where smaller numbers give smoother curves at the expense of more computation.
  * `flattenPath`         - Default `false`. Specifies whether curved line segments should be converted into straight line approximations. The granularity of the approximations is controlled by the path's current flatness value.
  * `frame`               - Default `{ x = "0%", y = "0%", h = "100%", w = "100%" }`.  Used by the `rectangle`, `oval`, `ellipticalArc`, `text`, and `image` types to specify the element's position and size.  When the key value for `x`, `y`, `h`, or `w` are specified as a string, the value is treated as a percentage of the canvas size.  See the section on [percentages](#percentages) for more information.
  * `id`                  - An optional string or number which is included in mouse callbacks to identify the element which was the target of the mouse event.  If this is not specified for an element, it's index position is used instead.
  * `image`               - Defaults to a blank image.  Used by the `image` type to specify an `hs.image` object to display as an image.
  * `imageAlpha`          - Defaults to `1.0`.  A number between 0.0 and 1.0 specifying the alpha value to be applied to the image specified by `image`.  Note that if an image is a template image, then this attribute will internally default to `0.5` unless explicitly set for the element.
  * `imageAlignment`      - Default "center". A string specifying the alignment of the image within the canvas element's frame.  Valid values for this attribute are "center", "bottom", "topLeft", "bottomLeft", "bottomRight", "left", "right", "top", and "topRight".
  * `imageAnimationFrame` - Default `0`. An integer specifying the image frame to display when the image is from an animated GIF.  This attribute is ignored for other image types.  May be specified as a negative integer indicating that the image frame should be calculated from the last frame and calculated backwards (i.e. specifying `-1` selects the last frame for the GIF.)
  * `imageAnimates`       - Default `false`. A boolean specifying whether or not an animated GIF should be animated or if only a single frame should be shown.  Ignored for other image types.
  * `imageScaling`        - Default "scalePropertionally".  A string specifying how the image should be scaled within the canvas element's frame.  Valid values for this attribute are:
    * `scaleToFit`          - shrink the image, preserving the aspect ratio, to fit the drawing frame only if the image is larger than the drawing frame.
    * `shrinkToFit`         - shrink or expand the image to fully fill the drawing frame.  This does not preserve the aspect ratio.
    * `none`                - perform no scaling or resizing of the image.
    * `scaleProportionally` - shrink or expand the image to fully fill the drawing frame, preserving the aspect ration.
  * `miterLimit`          - Default `10.0`. The limit at which miter joins are converted to bevel join when `strokeJoinStyle` is `miter`.  The miter limit helps you avoid spikes at the junction of two line segments.  When the ratio of the miter length—the diagonal length of the miter join—to the line thickness exceeds the miter limit, the joint is converted to a bevel join. Ignored for the `canvas`, `text`, and `image` types.
  * `padding`             - Default `0.0`. When an element specifies position information by percentage (i.e. as a string), the actual frame used for calculating position values is inset from the canvas frame on all sides by this amount. If you are using shadows with your elements, the shadow position is not included in the element's size and position specification; this attribute can be used to provide extra space for the shadow to be fully rendered within the canvas.
  * `radius`              - Default "50%". Used by the `arc` and `circle` types to specify the radius of the circle for the element. May be specified as a string or a number.  When specified as a string, the value is treated as a percentage of the canvas size.  See the section on [percentages](#percentages) for more information.
  * `reversePath`         - Default `false`.  Specifies drawing direction for the canvas element.  By default, canvas elements are drawn from the point nearest the origin (top left corner) in a clockwise direction.  Setting this to true causes the element to be drawn in a counter-clockwise direction. This will mostly affect fill and stroke dash patterns, but can also be used with clipping regions to create cut-outs.  Ignored for `canvas`, `image`, and `text` types.
  * `roundedRectRadii`    - Default `{ xRadis = 0.0, yRadius = 0.0 }`.
  * `shadow`              - Default `{ blurRadius = 5.0, color = { alpha = 1/3 }, offset = { h = -5.0, w = 5.0 } }`.  Specifies the shadow blurring, color, and offset to be added to an element which has `withShadow` set to true.
  * `startAngle`          - Default `0.0`. Used by the `arc` and `ellipticalArc` to specify the starting angle position for the inscribed arc.
  * `strokeCapStyle`      - Default "butt". A string which specifies the shape of the endpoints of an open path when stroked.  Primarily noticeable for lines rendered with the `segments` type.  Valid values for this attribute are "butt", "round", and "square".
  * `strokeColor`         - Default `{ white = 0 }`.  Specifies the stroke (outline) color for a canvas element when the action is set to `stroke` or `strokeAndFill`.  Ignored for the `canvas`, `text`, and `image` types.
  * `strokeDashPattern`   - Default `{}`.  Specifies an array of numbers specifying a dash pattern for stroked lines when an element's `action` attribute is set to `stroke` or `strokeAndFill`.  The numbers in the array alternate with the first element specifying a dash length in points, the second specifying a gap length in points, the third a dash length, etc.  The array repeats to fully stroke the element.  Ignored for the `canvas`, `image`, and `text` types.
  * `strokeDashPhase`     - Default `0.0`.  Specifies an offset, in points, where the dash pattern specified by `strokeDashPattern` should start. Ignored for the `canvas`, `image`, and `text` types.
  * `strokeJoinStyle`     - Default "miter".  A string which specifies the shape of the joints between connected segments of a stroked path.  Valid values for this attribute are "miter", "round", and "bevel".  Ignored for element types of `canvas`, `image`, and `text`.
  * `strokeWidth`         - Default `1.0`.  Specifies the width of stroked lines when an element's action is set to `stroke` or `strokeAndFill`.  Ignored for the `canvas`, `image`, and `text` element types.
  * `text`                - Default `""`.  Specifies the text to display for a `text` element.  This may be specified as a string, or as an `hs.styledtext` object.
  * `textAlignment`       - Default `natural`. A string specifying the alignment of the text within a canvas element of type `text`.  This field is ignored if the text is specified as an `hs.styledtext` object.  Valid values for this attributes are:
    * `left`      - the text is visually left aligned.
    * `right`     - the text is visually right aligned.
    * `center`    - the text is visually center aligned.
    * `justified` - the text is justified
    * `natural`   - the natural alignment of the text’s script
  * `textColor`           - Default `{ white = 1.0 }`.  Specifies the color to use when displaying the `text` element type, if the text is specified as a string.  This field is ignored if the text is specified as an `hs.styledtext` object.
  * `textFont`            - Defaults to the default system font.  A string specifying the name of thefont to use when displaying the `text` element type, if the text is specified as a string.  This field is ignored if the text is specified as an `hs.styledtext` object.
  * `textLineBreak`       - Default `wordWrap`. A string specifying how to wrap text which exceeds the canvas element's frame for an element of type `text`.  This field is ignored if the text is specified as an `hs.styledtext` object.  Valid values for this attribute are:
    * `wordWrap`       - wrap at word boundaries, unless the word itself doesn’t fit on a single line
    * `charWrap`       - wrap before the first character that doesn’t fit
    * `clip`           - do not draw past the edge of the drawing object frame
    * `truncateHead`   - the line is displayed so that the end fits in the frame and the missing text at the beginning of the line is indicated by an ellipsis
    * `truncateTail`   - the line is displayed so that the beginning fits in the frame and the missing text at the end of the line is indicated by an ellipsis
    * `truncateMiddle` - the line is displayed so that the beginning and end fit in the frame and the missing text in the middle is indicated by an ellipsis
  * `textSize`            - Default `27.0`.  Specifies the font size to use when displaying the `text` element type, if the text is specified as a string.  This field is ignored if the text is specified as an `hs.styledtext` object.
  * `trackMouseByBounds`  - Default `false`. If true, mouse events are based on the element's bounds (smallest rectangle which completely contains the element); otherwise, mouse events are based on the visible portion of the canvas element.
  * `trackMouseEnterExit` - Default `false`.  Generates a callback when the mouse enters or exits the canvas element.  For `canvas` and `text` types, the `frame` of the element defines the boundaries of the tracking area.
  * `trackMouseDown`      - Default `false`.  Generates a callback when mouse button is clicked down while the cursor is within the canvas element.  For `canvas` and `text` types, the `frame` of the element defines the boundaries of the tracking area.
  * `trackMouseUp`        - Default `false`.  Generates a callback when mouse button is released while the cursor is within the canvas element.  For `canvas` and `text` types, the `frame` of the element defines the boundaries of the tracking area.
  * `trackMouseMove`      - Default `false`.  Generates a callback when the mouse cursor moves within the canvas element.  For `canvas` and `text` types, the `frame` of the element defines the boundaries of the tracking area.
  * `transformation`      - Default `{ m11 = 1.0, m12 = 0.0, m21 = 0.0, m22 = 1.0, tX = 0.0, tY = 0.0 }`. Specifies a matrix transformation to apply to the element before displaying it.  Transformations may include rotation, translation, scaling, skewing, etc.
  * `view`                - Defaults to nil. The userdata object which is to be displayed for an element of type `view`.  The object must not currently belong to a visible window.  Assign nil to this property to release a previously assigned object for use elsewhere as an element or on its own (if supported).  See [hs._asm.canvas.views](#views) for more information.
  * `viewAlpha`           - Default `1.0`.  Specifies the alpha value to apply to the view in a canvas element of the `view` type.
  * `windingRule`         - Default "nonZero".  A string specifying the winding rule in effect for the canvas element. May be "nonZero" or "evenOdd".  The winding rule determines which portions of an element to fill. This setting will only have a visible effect on compound elements (built with the `build` action) or elements of type `segments` when the object is made from lines which cross.
  * `withShadow`          - Default `false`. Specifies whether a shadow effect should be applied to the canvas element.  Ignored for the `text` type.

- - -

<a name="object"></a>
~~~lua
canvas.object[index]
~~~
An array-like method for accessing the attributes for the canvas element at the specified index

Metamethods are assigned to the canvas object so that you can refer to individual elements of the canvas as if the canvas object was an array.  Each element is represented by a table of key-value pairs, where each key represents an attribute for that element.  Valid index numbers range from 1 to [hs._asm.canvas:elementCount()](#elementCount) when getting an element or getting or setting one of its attributes, and from 1 to [hs._asm.canvas:elementCount()](#elementCount) + 1 when assign an element table to an index in the canvas.  For example:

~~~lua
c = require("hs._asm.canvas")
a = c.new{ x = 100, y = 100, h = 100, w = 100 }:show()
a:insertElement({ type = "rectangle", fillColor = { blue = 1 } })
a:insertElement({ type = "circle", fillColor = { green = 1 } })
~~~
can also be expressed as:
~~~lua
c = require("hs._asm.canvas")
a = c.new{ x = 100, y = 100, h = 100, w = 100 }:show()
a[1] = { type = "rectangle", fillColor = { blue = 1 } }
a[2] = { type = "circle", fillColor = { green = 1 } }
~~~

In addition, you can change a canvas's element using this same style: `a[2].fillColor.alpha = .5` will adjust the alpha value for element 2 of the canvas without adjusting any of the other color fields.  To replace the color entirely, assign it like this: `a[2].fillColor = { white = .5, alpha = .25 }`

The canvas defaults can also be accessed with the `_default` field like this: `a._default.strokeWidth = 5`.

It is important to note that these methods are a convenience and that the canvas object is not a true table.  The tables are generated dynamically as needed; as such `hs.inspect` cannot properly display them; however, you can just type in the element or element attribute you wish to see expanded in the Hammerspoon console (or in a `print` command) to see the assigned attributes, e.g. `a[1]` or `a[2].fillColor`, and an inspect-like output will be provided.  Attributes which allow using a string to specify a percentage (see [percentages](#percentages)) can also be retrieved as their actual number for the canvas's current size by appending `_raw` to the attribute name, e.g. `a[2].frame_raw`.

Because the canvas object is actually a Lua userdata, and not a real table, you cannot use the `table.insert` and `table.remove` functions on it.  For inserting or removing an element in any position except at the end of the canvas, you must still use [hs._asm.canvas:insertElement](#insertElement) and [hs._asm.canvas:removeElement](#removeElement).

You can, however, remove the last element with `a[#a] = nil`.

To print out all of the elements in the canvas with: `for i, v in ipairs(a) do print(v) end`.  The `pairs` iterator will also work, and will work on element sub-tables (transformations, fillColor and strokeColor, etc.), but this iterator does not guarantee order.

- - -

<a name="percentages"></a>
~~~lua
canvas.percentages
~~~
Canvas attributes which specify the location and size of canvas elements can be specified with an absolute position or as a percentage of the canvas size.

Percentages may be assigned to the following attributes:
 * `frame`       - the frame used by the `rectangle`, `oval`, `ellipticalArc`, `text`, and `image` types.  The `x` and `w` fields will be a percentage of the canvas's width, and the `y` and `h` fields will be a percentage of the canvas's height.
 * `center`      - the center point for the `circle` and `arc` types.  The `x` field will be a percentage of the canvas's width and the `y` field will be a percentage of the canvas's height.
 * `radius`      - the radius for the `circle` and `arc` types.  The radius will be a percentage of the canvas's width.
 * `coordinates` - the point coordinates used by the `segments` and `points` types.  X coordinates (fields `x`, `c1x`, and `c2x`) will be a percentage of the canvas's width, and Y coordinates (fields `y`, `c1y`, and `c2y`) will be a percentage of the canvas's height.

Percentages are assigned to these fields as a string.  If the number in the string ends with a percent sign (%), then the percentage is the whole number which precedes the percent sign.  If no percent sign is present, the percentage is expected in decimal format (e.g. "1.0" is the same as "100%").

Because a shadow applied to a canvas element is not considered as part of the element's bounds, you can also set the `padding` attribute to a positive number of points to inset the calculated values by from each edge of the canvas's frame so that the shadow will be fully visible within the canvas, even when an element is set to a width and height of "100%".

- - -

<a name="views"></a>
~~~lua
canvas.views
~~~
A userdata object, potentially from another module, which can be displayed as an element within a Canvas.

The canvas element of type `view` is special in that it provides a placeholder for an appropriately generated view to be displayed as part of the canvas. This feature allows embedding the content of other modules within a canvas -- the canvas acts as its window.  The userdata object must conform to the following to be a valid candidate for this element type:
 * it must be a subclass of the Objective-C class `NSView`.
 * it must not be currently assigned to a visible (showing) window.

Notes:
 * Views can only be covered by other views - they exist above the other non-view canvas elements in the owning canvas. If you need to "draw" on top of a `view` element, you will need to add a new canvas as an additional `view` element to the parent canvas.
 * A view with it's own controls can only receive mouse events if the canvas can.  This requires that the canvas has a callback function defined, even though mouse events affecting the view are not handled by the canvas callback function. `canvasObject:mouseCallback(function() end)` is sufficient for this purpose if no other canvas element requires the callback function.

Candidate `view` objects:
 * A canvas object, which is not currently being shown, conforms to these requirements, so it is possible to use this element type to embed a canvas within another canvas.
 * `hs.webview` objects currently do not meet these requirements, but the necessary changes are currently under consideration.
 * `hs.drawing` objects do not meet these requirements, but as this module is under consideration as a replacement for `hs.drawing`, this will likely not change.  See `hs._asm.canvas.drawing` for the status of a wrapper for replacing the `hs.drawing` module.
 * An example of a "separate" module which can act as a valid object for this element type is located in the [avplayer](avplayer) directory of this repository.  More targeted HOWTO documentation is also being considered.

- - -

### License

>     The MIT License (MIT)
>
> Copyright (c) 2016 Aaron Magill
>
> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
>
