@tool
class_name GFSourcePart
extends RefCounted

var part_id: String
var mesh: Mesh
var transform := Transform3D.IDENTITY
var bounds := AABB()
