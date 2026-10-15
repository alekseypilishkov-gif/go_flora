@tool
class_name GFPaletteEntry
extends Resource

## Источник растения. Флажок и вес ниже влияют на новые размещения, а не на сохранённые записи.
@export var source: GFVegetationSource:
	set(value):
		source = value
		emit_changed()
## Относительная вероятность в MIX, не количество уже нарисованных растений. 0 исключает из MIX.
@export var weight: float = 1.0:
	set(value):
		weight = value
		emit_changed()
## Выключение исключает источник из новых размещений, сохраняя вес, ресурс и все прежние растения.
@export var enabled: bool = true:
	set(value):
		enabled = value
		emit_changed()
