extends PlayerMovementState
class_name PausedState

@export_category("Movement vars")
@export var speed : float = 7.5
@export var acceleration : float = 0.15
@export var deacceleration : float  = 0.25

func physics_update(delta : float)-> void:
	Player.update_gravity(delta)
	Player.update_movement(speed , acceleration , deacceleration)
