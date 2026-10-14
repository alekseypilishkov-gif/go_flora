@tool
class_name GFInstanceRecord
extends Resource

@export_storage var schema_version: int = 1
@export_storage var record_id: String = ""
@export_storage var source_id: String = ""
@export_storage var source_revision: String = "static-v1"
@export_storage var set_id: String = ""
@export_storage var layer_id: String = ""
@export_storage var stroke_id: String = ""
@export_storage var local_transform: Transform3D = Transform3D.IDENTITY
@export_storage var local_normal: Vector3 = Vector3.UP
@export_storage var seed: int = 0
@export_storage var candidate_index: int = 0
@export_storage var cell_key: Vector2i = Vector2i.ZERO
@export_storage var flags: int = 0
@export_storage var algorithm_version: String = "sha256-counter-v1"
@export_storage var target_path: NodePath
