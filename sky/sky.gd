@tool
extends WorldEnvironment

var time_of_day: float = 0.0;
var one_second: float = 1.0 / (24.0 * 60.0 * 60.0); # --- What part of a second takes in a day in the range from 0 to 1

@onready var sun_moon: DirectionalLight3D = $sun_moon;
@onready var thunder_sound: AudioStreamPlayer = $thunder;
@onready var sky_shader: ShaderMaterial = environment.sky.sky_material;
@export_range(0.0, 1.0) var time_of_day_setup: float  = 0.0:
	get:
		return time_of_day_setup;
	set(value):
		time_of_day_setup = value;
		set_time_of_day(time_of_day_setup);
@export_range(0, 23, 1) var hours: int = 0:
	get:
		return hours;
	set(value):
		hours = value;
		set_time_of_day((hours*3600+minutes*60+seconds)*one_second);
@export_range(0, 59, 1) var minutes: int = 0:
	get:
		return minutes;
	set(value):
		minutes = value;
		set_time_of_day((hours*3600+minutes*60+seconds)*one_second);
@export_range(0, 59, 1) var seconds: int = 0:
	get:
		return seconds;
	set(value):
		seconds = value;
		set_time_of_day((hours*3600+minutes*60+seconds)*one_second);
#here you can change the start position of the Sun and Moon and axis of rotation
@export var sun_pos_default: Vector3 = Vector3(0.0,-1.0,0.0):
	set(value):
		sun_pos_default = value.normalized();
@export var sun_axis_rotation: Vector3 = Vector3(1.0,0.0,0.0):
	set(value):
		sun_axis_rotation = value.normalized();
#For the Moon, you cannot change the rotation axis and position, since I did not find a cheap method to correctly display the sprite on the sky sphere.
var moon_pos_default: Vector3 = Vector3(0.0,1.0,0.0): 
	set(value):
		moon_pos_default = value.normalized();
var moon_axis_rotation: Vector3 = Vector3(1.0,0.0,0.0):
	set(value):
		moon_axis_rotation = value.normalized();

@export_range(0.0, 1.0, 0.01) var clouds_coverage: float = 0.5:
	set(value):
		clouds_coverage = value;
		if is_inside_tree():
			sky_shader.set_shader_parameter("COVERAGE",1.0-(clouds_coverage*0.5+0.25));
			sky_shader.set_shader_parameter("ABSORPTION",clouds_coverage+0.75);
			sky_shader.set_shader_parameter("THICKNESS",clouds_coverage*10.0+10.0);
@export_range(0.0, 1.0, 0.01) var clouds_height: float = 0.5:
	set(value):
		clouds_height = value;
		if is_inside_tree():
			sky_shader.set_shader_parameter("HEIGHT",clouds_height);
@export_range(0.0, 10.0, 0.01) var clouds_size: float = 2.0:
	set(value):
		clouds_size = value;
		if is_inside_tree():
			sky_shader.set_shader_parameter("SIZE",clouds_size);
@export_range(0.0, 10.0, 0.01) var clouds_soft: float = 2.0:
	set(value):
		clouds_soft = value;
		if is_inside_tree():
			sky_shader.set_shader_parameter("SOFTNESS",clouds_soft);
@export_range(5, 100,1) var clouds_quality: int = 20:
	set(value):
		clouds_quality = value;
		if is_inside_tree():
			sky_shader.set_shader_parameter("STEPS",clouds_quality);
@export_range(0.0, 1.0, 0.01) var wind_strength: float = 0.1:
	set(value):
		wind_strength = value;
		if is_inside_tree():
			sky_shader.set_shader_parameter("WIND",Vector3 (wind_direction.x,0.0,wind_direction.y)*wind_strength);
@export var wind_direction: Vector2 = Vector2(1.0,0.0):
	set(value):
		wind_direction = value.normalized();
		if is_inside_tree():
			sky_shader.set_shader_parameter("WIND",Vector3 (wind_direction.x,0.0,wind_direction.y)*wind_strength);
@export_range(0.0, 0.5) var moon_size: float = 0.05:
	set(value):
		moon_size = value;
		if is_inside_tree():
			sky_shader.set_shader_parameter("moon_size",moon_size);
@export_range(-1.1, 1.0) var moon_phase: float = 1.0:
	set(value):
		moon_phase = value;
		if is_inside_tree():
			sky_shader.set_shader_parameter("MOON_PHASE",moon_phase);
@export var clouds_tint: Color = Color(1.0, 1.0, 1.0, 1.0);
@export var moon_tint: Color = Color(1.0, 1.0, 1.0, 1.0):
	set(value):
		moon_tint = value;
		if is_inside_tree():
			sky_shader.set_shader_parameter("moon_tint",moon_tint);
@export var moon_light: Color = Color(0.6, 0.6, 0.8, 1.0);
@export var sunset_light: Color = Color(1.0, 0.7, 0.55, 1.0);
@export var day_light: Color = Color(1.0, 1.0, 1.0, 1.0);
@export var sunset_offset: float = -0.1;
@export var sunset_range: float = 0.2;
@export_range(0.0, 1.0, 0.01) var night_level_light: float = 0.05;
var lighting_time: float=0.0;
@export var lighting_pos: Vector3 = Vector3(0.0,1.0,0.0):
	set(value):
		lighting_pos = value.normalized();
		if is_inside_tree():
			sky_shader.set_shader_parameter("LIGHTING_POS",lighting_pos);
@export var lighting_strike: bool = false:
	set(value):
		if (!is_inside_tree()):
			return
		if thunder_sound.is_playing():
			return;
		lighting_strike = true;
		thunder_sound.play()
		await get_tree().create_timer(0.3).timeout;
		set_process(true);
		await get_tree().create_timer(0.8).timeout;
		lighting_time = 0.0;
		lighting_strike = false;
		set_process(false);
		if sky_shader:
			sky_shader.set_shader_parameter("lighting_strength",0.0);
		set_time();

func set_time_of_day(value: float):
	var time: float = value/one_second;
	value -= 2.0/24.0;
	if value < 0.0:
		value = 1.0 + value;
	time_of_day = value
	var _hours = int(clamp(time/3600.0,0.0,23.0))
	time -= _hours*3600
	var _minutes = int(clamp(time/60,0.0,59.0))
	time -= _minutes*60
	var _seconds = int(clamp(time,0.0,59.0))
	#print (_hours, ":", _minutes, ":", _seconds)
	set_time();

func set_time():
	if !is_inside_tree():
		return;
	var light_color: Color = Color(1.0,1.0,1.0,1.0);
	var phi: float = time_of_day * 2.0 * PI;
	var sun_pos: Vector3 = sun_pos_default.rotated(sun_axis_rotation,phi) #here you can change the start position of the Sun and axis of rotation
	var moon_pos:Vector3 = moon_pos_default.rotated(moon_axis_rotation,phi) #Same for Moon
	var moon_tex_pos: Vector3 = Vector3(0.0,1.0,0.0).normalized().rotated(Vector3(1.0,0.0,0.0).normalized(),(phi+PI)*0.5) #This magical formula for shader
	var light_energy: float = smoothstep(sunset_offset,0.4, sun_pos.y);# light intensity depending on the height of the sun
	light_energy = clamp(light_energy, night_level_light, 2.0);
	var sun_height: float = sun_pos.y-sunset_offset;
	if sun_height < sunset_range:
		light_color=lerp(moon_light, sunset_light, clamp(sun_height/sunset_range,0.0,1.0))
	else:
		light_color=lerp(sunset_light, day_light, clamp((sun_height-sunset_range)/sunset_range,0.0,1.0))
	if sun_pos.y < 0.0:
		if !moon_pos.is_equal_approx(Vector3.UP) and !moon_pos.is_equal_approx(Vector3.DOWN):
			sun_moon.look_at_from_position(moon_pos,Vector3.ZERO,Vector3.UP); # move sun to position and look at center scene from position
	else:
		if !sun_pos.is_equal_approx(Vector3.UP) and !sun_pos.is_equal_approx(Vector3.DOWN):
			sun_moon.look_at_from_position(sun_pos,Vector3.ZERO,Vector3.UP); # move sun to position and look at center scene from position

	light_energy = light_energy * (1-clouds_coverage * 0.5)
	sun_moon.light_energy = light_energy;
	sun_moon.light_color = light_color;
	environment.ambient_light_color = light_color;
	environment.ambient_light_energy = light_energy;
	environment.adjustment_saturation = 1-clouds_coverage*0.5
	environment.fog_light_color = light_color;
	environment.volumetric_fog_albedo = light_color;
	#set_clouds_tint(light_color*) # comment this, if you need custom clouds tint
	sky_shader.set_shader_parameter("clouds_tint",light_color*clouds_tint);
	sky_shader.set_shader_parameter("SUN_POS",sun_pos);
	sky_shader.set_shader_parameter("MOON_POS",moon_pos);
	sky_shader.set_shader_parameter("MOON_TEX_POS",moon_tex_pos);
	sky_shader.set_shader_parameter("attenuation",clamp(light_energy,night_level_light*0.25,1.00));#clouds too bright with night_level_light

func _process(delta:float):
	if !lighting_strike:
		return;
	lighting_time += delta;
	var lighting_strength = clamp(sin(lighting_time*20.0),0.0,1.0);
	lighting_pos = lighting_pos.normalized();
	sun_moon.light_color = day_light;
	sun_moon.light_energy = lighting_strength*2;
	sky_shader.set_shader_parameter("lighting_strength",lighting_strength);
	if !lighting_pos.is_equal_approx(Vector3.UP) and !lighting_pos.is_equal_approx(Vector3.DOWN):
		sun_moon.look_at_from_position(lighting_pos,Vector3.ZERO,Vector3.UP);

func _ready():
	set_process(false);

func _input(event):
	if event.is_action_pressed("ui_accept"):
		lighting_strike = true;
