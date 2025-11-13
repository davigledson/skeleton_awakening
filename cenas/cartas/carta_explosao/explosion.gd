# explosion.gd
extends Node3D

@onready var debris = $Debris_destrocos_GPUParticles3D
@onready var smoke = $Smoke_GPUParticles3D2
@onready var fire = $Fire_GPUParticles3D
@onready var som_explosao = $ExplosionSound

func _ready():
	# GARANTIR que partículas estão desligadas ao iniciar
	debris.emitting = false
	smoke.emitting = false
	fire.emitting = false
	print("🔧 Explosão criada (partículas desligadas)")

func explode():
	print("💥 BOOM! Explosão ativada!")
	
	# Ativar partículas
	debris.emitting = true
	smoke.emitting = true
	fire.emitting = true
	
	# Som
	if som_explosao:
		som_explosao.play()
	
	# Aguardar e destruir
	await get_tree().create_timer(3.0).timeout
	print("💨 Explosão finalizada")
	queue_free()
