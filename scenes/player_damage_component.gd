extends Area3D


signal deal_damage(amount : float)

@export var amount_multiplier : float = 1.0

@rpc("any_peer")
func damage(amount):
	deal_damage.emit(amount)
