@tool
extends EditorResourcePicker

# Observe actions on this picker's own controls, leaving native handlers intact.
# Deferred observation runs after Godot opens its chooser, including the direct
# Quick Load button. No menu IDs, names, private methods or global tree searches.
signal native_action_finished

func _ready() -> void:
	child_entered_tree.connect(_observe_child)
	for child in get_children():
		_observe_child(child)

func _observe_child(child: Node) -> void:
	if child is BaseButton:
		child.pressed.connect(_after_action, CONNECT_DEFERRED)
	elif child is PopupMenu:
		child.id_pressed.connect(_after_menu_action, CONNECT_DEFERRED)

func _after_action() -> void:
	native_action_finished.emit()

func _after_menu_action(_id: int) -> void:
	native_action_finished.emit()
