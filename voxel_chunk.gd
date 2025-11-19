extends StaticBody3D
class_name VoxelChunk

# Voxel chunk that generates a mesh from voxel data
@export var chunk_size: int = 16
@export var voxel_size: float = 1.0
@export var noise: FastNoiseLite
@export var chunk_position: Vector3i = Vector3i.ZERO

var voxel_data: Array = []
var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D

func _ready():
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	collision_shape = CollisionShape3D.new()
	add_child(collision_shape)
	
	generate_voxel_data()
	generate_mesh()

func generate_voxel_data():
	voxel_data.clear()
	voxel_data.resize(chunk_size * chunk_size * chunk_size)
	
	for x in range(chunk_size):
		for y in range(chunk_size):
			for z in range(chunk_size):
				var world_x = chunk_position.x * chunk_size + x
				var world_y = chunk_position.y * chunk_size + y
				var world_z = chunk_position.z * chunk_size + z
				
				# Simple height-based terrain generation
				var height = noise.get_noise_2d(world_x, world_z) * 10.0 + 5.0
				var voxel_value = 1 if world_y < height else 0
				
				var index = x + y * chunk_size + z * chunk_size * chunk_size
				voxel_data[index] = voxel_value

func get_voxel(x: int, y: int, z: int) -> int:
	if x < 0 or x >= chunk_size or y < 0 or y >= chunk_size or z < 0 or z >= chunk_size:
		return 0
	var index = x + y * chunk_size + z * chunk_size * chunk_size
	return voxel_data[index]

func generate_mesh():
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Create a simple material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.4, 0.6, 0.3)  # Green terrain color
	surface_tool.set_material(material)
	
	# Generate faces for visible voxels
	for x in range(chunk_size):
		for y in range(chunk_size):
			for z in range(chunk_size):
				if get_voxel(x, y, z) == 0:
					continue
				
				var world_pos = Vector3(x, y, z) * voxel_size
				
				# Check each face and add if neighbor is empty
				# Front face (+Z)
				if get_voxel(x, y, z + 1) == 0:
					add_quad(surface_tool, world_pos, 
						Vector3(0, 0, voxel_size), Vector3(voxel_size, 0, 0), Vector3(0, voxel_size, 0))
				
				# Back face (-Z)
				if get_voxel(x, y, z - 1) == 0:
					add_quad(surface_tool, world_pos + Vector3(0, 0, voxel_size), 
						Vector3(-voxel_size, 0, 0), Vector3(0, 0, -voxel_size), Vector3(0, voxel_size, 0))
				
				# Right face (+X)
				if get_voxel(x + 1, y, z) == 0:
					add_quad(surface_tool, world_pos + Vector3(voxel_size, 0, 0), 
						Vector3(0, 0, voxel_size), Vector3(0, 0, -voxel_size), Vector3(0, voxel_size, 0))
				
				# Left face (-X)
				if get_voxel(x - 1, y, z) == 0:
					add_quad(surface_tool, world_pos, 
						Vector3(0, 0, -voxel_size), Vector3(0, 0, voxel_size), Vector3(0, voxel_size, 0))
				
				# Top face (+Y)
				if get_voxel(x, y + 1, z) == 0:
					add_quad(surface_tool, world_pos + Vector3(0, voxel_size, 0), 
						Vector3(voxel_size, 0, 0), Vector3(0, 0, voxel_size), Vector3(-voxel_size, 0, 0))
				
				# Bottom face (-Y)
				if get_voxel(x, y - 1, z) == 0:
					add_quad(surface_tool, world_pos, 
						Vector3(voxel_size, 0, 0), Vector3(0, 0, voxel_size), Vector3(0, 0, -voxel_size))
	
	surface_tool.generate_normals()
	var mesh = surface_tool.commit()
	mesh_instance.mesh = mesh
	
	# Create collision shape
	if mesh:
		var shape = mesh.create_trimesh_shape()
		collision_shape.shape = shape

func add_quad(surface_tool: SurfaceTool, pos: Vector3, v1: Vector3, v2: Vector3, v3: Vector3):
	var normal = v1.cross(v2).normalized()
	
	surface_tool.set_normal(normal)
	surface_tool.add_vertex(pos)
	surface_tool.add_vertex(pos + v1)
	surface_tool.add_vertex(pos + v1 + v2)
	
	surface_tool.add_vertex(pos)
	surface_tool.add_vertex(pos + v1 + v2)
	surface_tool.add_vertex(pos + v3)

