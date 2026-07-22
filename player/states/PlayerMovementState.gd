class_name PlayerMovementState extends State

@export var Player : PlayerController
var PlayerAnimation : AnimationPlayer
var PlayerAnimationTree : AnimationTree
func _ready():
	await owner.ready
	var local = is_multiplayer_authority()
	set_process(local)
	set_physics_process(local)
	set_process_input(local)
	set_process_unhandled_input(local)
	set_process_shortcut_input(local)
	Player = owner as PlayerController
	PlayerAnimation = Player.get_node("PlayerAnimation") as AnimationPlayer
	#PlayerAnimationTree = Player.get_node("PlayerAnimationTree" ) as AnimationTree
