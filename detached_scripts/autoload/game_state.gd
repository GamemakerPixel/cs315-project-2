extends Node

signal warp_enabled

var warping_enabled = false


func enable_warping() -> void:
	warping_enabled = true
	warp_enabled.emit()
