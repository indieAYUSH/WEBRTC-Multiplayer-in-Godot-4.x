
extends Node3D
class_name MuzzleFlah

@export var FlashTimer : float
@export var Muzzleflash : GPUParticles3D
@export var ember : GPUParticles3D
@export var smoke : GPUParticles3D
@export var LightFlash : OmniLight3D

var _is_smooking : bool
var _last_flash_time: int = 0

func _show_muzzle_flash() -> void:
	if Muzzleflash:
		Muzzleflash.restart()
	if ember:
		ember.restart()
		
	if smoke:
		smoke.restart()
	if LightFlash:
		LightFlash.visible = true

	# Record the exact millisecond this specific shot was fired
	var current_flash_time = Time.get_ticks_msec()
	_last_flash_time = current_flash_time

	await get_tree().create_timer(FlashTimer).timeout


	if _last_flash_time == current_flash_time:
		if LightFlash:
			LightFlash.visible = false
		#if smoke:
			#smoke.emitting = false
