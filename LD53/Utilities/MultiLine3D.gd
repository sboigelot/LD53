extends Spatial

class_name MultiLine3D

export var points: PoolVector3Array

export var width:float = 1.0
export var cast_shadow:bool = false
export var material: Material
export var start_cap: Mesh
export var mid_cap: Mesh
export var end_cap: Mesh

func _ready():
	rebuild()
	
func rebuild():
	for child in get_children():
		child.free()
	
	if points.size() < 2:
		return
	
	if start_cap != null:
		var mesh_instance = MeshInstance.new()
		add_child(mesh_instance)
		mesh_instance.mesh = start_cap
		mesh_instance.global_translation = points[0]
	
	for i in (points.size() - 1):
		var start_point = points[i]
		var end_point = points[i + 1]
#		print("line3d %s -> %s" % [start_point, end_point])
	
		var line3d = Line3D.new()
		add_child(line3d)
		
		line3d.global_translation = start_point
		line3d.end_point = end_point - start_point 
		line3d.cast_shadow = cast_shadow
		line3d.width = width
		line3d.material_override = material
		
		if mid_cap != null and i < (points.size() - 2):
			var mesh_instance = MeshInstance.new()
			add_child(mesh_instance)
			mesh_instance.mesh = mid_cap
			mesh_instance.global_translation = end_point
	
	if end_cap != null and points[0] != points[points.size() - 1]:
		var mesh_instance = MeshInstance.new()
		add_child(mesh_instance)
		mesh_instance.mesh = end_cap
		mesh_instance.global_translation = points[points.size() - 1]
		
