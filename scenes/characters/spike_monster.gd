extends PathFollow2D

const SPEED = 250

var moving = false


func _physics_process(delta: float) -> void:
	if moving:
		progress += SPEED * delta
		# This is a workaround, AnimatedBody only updates when its position is
		# directly set, not set by its parent.
		$SpikeMonster.position = $SpikeMonster.position


func _on_spike_monster_trigger_body_entered(_body: Node2D) -> void:
	moving = true
