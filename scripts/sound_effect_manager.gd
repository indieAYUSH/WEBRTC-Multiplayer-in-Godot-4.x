extends Node3D


#============----- Refrences --------=======#
@export var player : PlayerController


@onready var walking_foot_step: AudioStreamPlayer3D = $"../movment_sfx/walking_foot_step"

#===============--------Movements Sound Effects ----------------=====================#
var bob_index  : float
var bob_current_intensity : float
var bob_current_ampl  : float
var can_play_footsteps : bool
#=-=======--xports-------=-=====#
@export_category("Movement Sound Effects")
@export var bob_freq : float
@export var bob_amplitude : float
@export var bob_smoothing : float



func _ready():
	if !player:
		player = get_parent()

func _process(delta):
	var speed = Vector2(player.velocity.x , player.velocity.z).length()
	var offsets : Vector2
	if player.player_statemachine.current_state.name == "SlideState" : return
	if speed > 0.5 and  player.is_on_floor():
		bob_current_ampl = bob_amplitude * speed 
		bob_current_intensity += delta*bob_freq*speed
		var bob_offset : Vector2
		bob_offset.y = sin(bob_current_intensity)*bob_current_ampl
		bob_offset.x = sin(bob_current_intensity/2.0)* bob_current_ampl
		offsets.x = lerp(offsets.x , bob_offset.x+0.55 , delta*bob_smoothing)
		offsets.y = lerp(offsets.y , bob_offset.y/2.0 , delta*bob_smoothing)
		var threshold = -bob_amplitude + 0.09
		if offsets.y > threshold:
			can_play_footsteps = true
		elif offsets.y < threshold and can_play_footsteps:
			can_play_footsteps = false
			play_footsteps.rpc()

@rpc("call_local")
func play_footsteps():
	walking_foot_step.play(








	)
