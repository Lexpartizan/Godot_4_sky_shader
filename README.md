# Godot_sky_shader
This project adds a dynamic sky shader to your project. It is based on https://github.com/danilw/godot-utils-and-other.

This adaptation https://github.com/Lexpartizan/Godot_sky_shader
for GODOT 4. 

Sorry it took me so long to do an adaptation, but you must have heard that there is a war in my country.

#STAND WITH UKRAINE

Complete feature list
* day-night-cycle
* Sun
* Moon
* Stars
* Clouds

# Support

The shader and demo scenes target Godot 3.2.  
There is a "version_for_Godot_3_1_2.zip" file which contains a subset of this project's content and works in Godot 3.1. Godrays dont support for Godot 3.1.2.
# Demo

Parameters in the Sky scene:
* Moon Phase: Covers the moon with a shadow from top-left of the moon to the bottom-right (and vice-verca)
* Coverage: Specifies how much the sky is covered by clouds
* Height: How close the clouds are to the viewer
* Quality Steps: 
* Wind Strength: Speed of cloud movement
* Lightning Strike: brightens the sky for less than a second

Additional changes can be made which are not currently exposed in the GUI of the demo scene, such as
* traversal route (axis of rotation and start position) of sun and Moon
[![sky](https://github.com/Lexpartizan/Godot_sky_shader/blob/master/images/sun_moon.jpg)]
First Vector3(0.0,-1.0,0.0), in the highlighted lines of code, this is start position. You can change this to distance the Sun from the zenith.
Second Vector3(1.0,0.0,0.0) this is axis of rotation.

Same information for Moon.
* wind direction, ie. direction the clouds move
set variable wind_dir (Vector2) from your code and call function _wind(value), where value is wind power.


Using as it is
* you can use the Sky.tscn scene itself: It has a GDscript attached, which gives you controls to adjust the settings. 


