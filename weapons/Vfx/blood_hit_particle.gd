extends HitParticleEffect
class_name BloodHitParticle

@export var blood_spray : GPUParticles3D
@export var dripping_blood : GPUParticles3D
@export var blood_decal : PackedScene

func  _emit_par(normal: Vector3 , _shooter_pos : Vector3):
	pass
