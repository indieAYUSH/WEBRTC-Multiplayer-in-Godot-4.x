extends Control
class_name PlayerUiComponent


@onready var player = owner as PlayerController
@onready var health_bar: ProgressBar = $health_bar

func _ready():
	await owner.ready 
	if !is_multiplayer_authority():
		visible = false
		return
	await get_tree().create_timer(1.5).timeout


func _on_player_update_health(amount: float) -> void:
	health_bar.value = amount
