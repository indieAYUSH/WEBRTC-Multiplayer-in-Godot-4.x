extends HitParticleEffect
class_name ObjeHitParticle

@export var clr_time : float = 0.8

@export var particle_node : GPUParticles3D
@export var ember_par : GPUParticles3D
@export var surface_par : GPUParticles3D

func _emit_par(pos: Vector3 , _shooter_pos : Vector3):
	var normal = -(pos - _shooter_pos).normalized()
	if particle_node:
		particle_node.process_material.direction = normal
		particle_node.emitting = true
		
	if ember_par:
		ember_par.process_material.direction = normal 
		ember_par.emitting = true

	if surface_par:
		surface_par.process_material.direction = normal 
		surface_par.emitting = true

	await get_tree().create_timer(clr_time).timeout
	queue_free()
