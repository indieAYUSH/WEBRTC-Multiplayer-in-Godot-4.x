extends Node3D



@export var weapon_damage : float = 18.0


@export var shoot_sound : AudioStream
@export var reload_sound : AudioStream

@export var current_ammo : int = 30
@export var mag_size : int = 30
@export var animation_player : AnimationPlayer
@export var player_animation : AnimationPlayer
@export var weapon_ray_cast : RayCast3D
@export var autofire : bool = true

@onready var muzzle_flash: Node3D = $world_view_model/Barrel_node/MuzzleFlash

@onready var local_barel_pos: Node3D = %local_barel_pos

@onready var ads_pivot: Node3D = $Local_view_model/Ads_pivot

@onready var shoot_sound_player: AudioStreamPlayer3D = $"../../../../../../../../weapon_Sound/shoot_sound"
@onready var reload_sound_player: AudioStreamPlayer3D = $"../../../../../../../../weapon_Sound/reload_sound"

@export var envo_hit_particles : PackedScene
@export var blood_splatter_particle : PackedScene
@export var bullet_tracer : PackedScene


@export_category("animation_name")
@export var shootin_anim : String
@export var reloading_anim : String


@onready var barrel_node: Node3D =  %local_barel_pos

@export var ads_pos : Vector3 
@export var default_pos : Vector3

var can_ads : bool = true

@export var player_controller : PlayerController

enum GUN_ANIMATION_STATE{
	NONE,
	SHOOTING,
	RELOADING
}

var current_gun_animation_state : GUN_ANIMATION_STATE = GUN_ANIMATION_STATE.NONE

@export_group("WEAPON JUICE THINGS")
@export_category("refrences")
@onready var weapon_holder: Node3D = $"../.."
@onready var weapon_juic_rig: Node3D = $".."
@export var metal_bullet_impact_Sfx : PackedScene
@export var concrete_bullet_impact : PackedScene
@export var hit_particle_effect_eno : PackedScene

@export_category("effects")
@export var weapon_tilt : bool
@export  var weapon_bob : bool

@export_group("reocil_vars")
@export var horizonatal_recoil : float = -1.0
@export var vertical_recoil : float  = 2.0


@export_category("weapon_tilt")
@export var roll_pitch : float 
@export var roll_side_rot  : float

@export_category("weapon_bob")
@export var frequency  : float
@export var amplitude : float
var bob_phase : float
var bob_intensity : float
@onready var recoil_pivot: Node3D = %recoil_pivot

@export_category("others")
@export var lerp_speed : float = 15.0
@onready var world_view_model: Node3D = $world_view_model
@onready var local_view_model: Node3D = $Local_view_model

func _unhandled_input(event: InputEvent) -> void:
	if !is_multiplayer_authority(): return
	if event.is_action_pressed("shoot"):
		shoot()
	if event.is_action_pressed("reload"):
		reload()

func _ready() -> void:
	if !is_multiplayer_authority(): return
	animation_player.animation_finished.connect(on_animation_player_finished_playing)
	local_view_model.visible = true
	world_view_model.visible = false

func on_animation_player_finished_playing(anim_name : String)->void:
	if anim_name == shootin_anim and Input.is_action_pressed("shoot") and autofire:
		shoot()
	if anim_name == reloading_anim:
		if is_multiplayer_authority():
			can_ads = true



func reload()->void:
	if current_ammo >= mag_size:
		return
	if animation_player.is_playing(): return
	current_gun_animation_state = GUN_ANIMATION_STATE.RELOADING
	animation_player.play(reloading_anim , -1.0 , 3.0 , false)
	#if is_multiplayer_authority():
		#can_ads = false
	var amt = min(mag_size , mag_size-current_ammo)
	current_ammo += amt

	show_fx.rpc()


func shoot()->void:
	var barrel_pos = local_barel_pos.global_position
	if animation_player.is_playing(): return
	
	if current_ammo <= 0:
		reload()
		return
	current_gun_animation_state = GUN_ANIMATION_STATE.SHOOTING
	animation_player.play(shootin_anim , -1.0 , 3.7 , false)
	show_fx.rpc()
	shoot_sound_player.play()
	%MuzzleFlash._show_muzzle_flash()
	current_ammo -= 1
	if weapon_ray_cast.is_colliding():
		var collider = weapon_ray_cast.get_collider()
		var pos = weapon_ray_cast.get_collision_point()
		spawn_bullet_trails.rpc(pos ,   local_barel_pos.global_position)
		if collider.has_method("damage"):
			if collider.player_died : return
			player_animation.play("hit_marker")
			collider.damage.rpc_id(collider.get_multiplayer_authority()  , weapon_damage)
			spawn_hit_particles.rpc(true ,  local_barel_pos.global_position , weapon_ray_cast.get_collision_point() , weapon_ray_cast.get_collision_normal() , weapon_ray_cast.get_collider())
		else:
			if collider.is_in_group("metal"):
				spawn_hit_sfx(metal_bullet_impact_Sfx , pos)
			else:
				spawn_hit_sfx(concrete_bullet_impact , pos)
			spawn_hit_particles.rpc(false ,  local_barel_pos.global_position , weapon_ray_cast.get_collision_point() , weapon_ray_cast.get_collision_normal() , weapon_ray_cast.get_collider())
	else:
		spawn_bullet_trails.rpc(weapon_ray_cast.target_position  , local_barel_pos.global_position)

@rpc()
func show_fx()->void:
	match current_gun_animation_state:
		GUN_ANIMATION_STATE.NONE:
			pass
		GUN_ANIMATION_STATE.SHOOTING:
			#animation_player.play(shootin_anim)
			muzzle_flash._show_muzzle_flash()
			print(Network.my_roll , " spwannign muzzle")
			#shoot_sound_player.stream = shoot_sound
			shoot_sound_player.play()
		GUN_ANIMATION_STATE.RELOADING:
			reload_sound_player.stream = reload_sound
			#reload_sound_player.play()
			animation_player.play(reloading_anim)



func _local_view_model_fx():
	pass



func _process(delta: float) -> void:
	if !is_multiplayer_authority() : return
	#if Input.is_action_pressed("ADS") and can_ads:
		#weapon_holder.position = lerp(weapon_holder.position , ads_pos , lerp_speed)
	#else:
		#weapon_holder.position = lerp(ads_pos , weapon_holder.position , lerp_speed)
	weapon_juice(delta)
	position.x = lerp(position.x , 0.0 , delta*lerp_speed)
	position.y = lerp(position.y , 0.0 , delta*lerp_speed)
	rotation.z = lerp(rotation.z , 0.0 , delta*lerp_speed)
	rotation.x = lerp(rotation.x , 0.0 , delta*lerp_speed)
	
	recoil_pivot.rotation.z = lerp(recoil_pivot.rotation.z , 0.0 , 13.0)
	recoil_pivot.rotation.x = lerp(recoil_pivot.rotation.x , 0.0 , 13.0)
	if _can_Ads() and Input.is_action_pressed("ADS"):
		ads_pivot.position = lerp(ads_pivot.position , ads_pos , delta*10.0)
		ads_pivot.rotation.x = lerp(ads_pivot.rotation.x , deg_to_rad(-5.0) , delta*10.0)
		%Camera3D.fov = lerp(%Camera3D.fov , 65.0 , lerp_speed*delta)
	else :
		if ads_pivot.position == default_pos : return
		%Camera3D.fov = lerp(%Camera3D.fov , 80.0 , lerp_speed*delta)
		ads_pivot.position = lerp(ads_pivot.position , default_pos , delta*10.0)
		ads_pivot.rotation.x = deg_to_rad(0.0)

func _can_Ads() -> bool:
	return player_controller.player_statemachine.current_state.name == "WalkState" or player_controller.player_statemachine.current_state.name  == "IdleState" or player_controller.player_statemachine.current_state.name  == "CrouchState" 

func _sway(amount: Vector2) -> void :
	position.x += amount.x * 0.09
	position.y += amount.y * 0.09 
	
	rotation.x += deg_to_rad(amount.x * 0.08)  
	rotation.z += deg_to_rad (amount.y * 0.05) 
	

func weapon_juice(delta : float ) -> void:
	var angles  : Vector3
	var offset  : Vector3
	
	var velocity = player_controller.velocity.length()
	
	if velocity > 0.01 and weapon_tilt:
		weapon_holder.rotation.x = lerp(weapon_holder.rotation.x , (roll_pitch*Input.get_axis("forward","backward"))  , delta*lerp_speed)
		weapon_holder.rotation.z = lerp(weapon_holder.rotation.z , -(roll_side_rot*Input.get_axis("left","right"))  , delta*lerp_speed)

	if velocity > 0.01 and player_controller.is_on_floor() and weapon_bob and _can_headbob():
		var speed_factor = clamp(velocity/9.5 , 0.0 , 1.0)
		bob_phase += frequency*speed_factor*delta*velocity
		bob_intensity = amplitude
		var p = position
		p.x =  sin(bob_phase*0.5) * amplitude
		p.y = sin(bob_phase)*amplitude
		offset = p
	else :
		offset = lerp(offset , Vector3.ZERO , delta*8.0)
		
	

	weapon_juic_rig.position = offset

func _can_headbob() -> bool:
	var state_name = player_controller.player_statemachine.current_state.name
	# Headbob is allowed if the player is NOT sliding or dashing
	return state_name != "SlideState" and state_name != "DashState"


@rpc("call_local")
func spawn_hit_sfx(_hit_sound : PackedScene , _postion : Vector3) -> void:
	var audio_player = _hit_sound.instantiate()
	get_tree().current_scene.add_child(audio_player)
	audio_player.global_position = _postion
	audio_player.finished.connect(audio_player.queue_free)
	audio_player.play()


@rpc("call_local")
func spawn_hit_particles(is_enemy : bool , _barrelpos : Vector3 , _postion : Vector3 , _normal:Vector3 , _owner) -> void:
	var _particles : PackedScene
	if is_enemy:
		_particles = blood_splatter_particle
	else:
		_particles = hit_particle_effect_eno
	var particle_instance  = _particles.instantiate()
	get_tree().current_scene.add_child(particle_instance)
	var pos = _postion
	particle_instance.global_position = pos
	particle_instance._emit_par(_postion ,_barrelpos )

@rpc("call_local")
func spawn_bullet_trails(hit_point : Vector3,  spawn_pos : Vector3) -> void:
	var tracer_Scene = bullet_tracer
	var trc = tracer_Scene.instantiate()
	get_tree().current_scene.add_child(trc)
	trc.global_position = spawn_pos
	trc.look_at(hit_point , Vector3.UP)
	var tween = get_tree().create_tween()
	tween.tween_property(trc , "global_position" , hit_point , 0.08)
	tween.tween_callback(trc.queue_free)
