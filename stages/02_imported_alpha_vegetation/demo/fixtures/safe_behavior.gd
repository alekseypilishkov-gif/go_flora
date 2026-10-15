extends Node3D

signal touched
var ticks := 0
var signal_count := 0

func _ready() -> void:
	set_meta("authored_ready", true)
	touched.emit()

func _process(_delta: float) -> void:
	ticks += 1

func _on_touched() -> void:
	signal_count += 1
