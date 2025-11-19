extends Node3D
class_name VoxelTerrain

# Manages voxel chunks and generates terrain around the player
@export var chunk_size: int = 16
@export var render_distance: int = 3
@export var voxel_size: float = 1.0
@export var player: Node3D

var noise: FastNoiseLite
var chunks: Dictionary = {}
var player_position: Vector3 = Vector3.ZERO
var last_chunk_position: Vector3i = Vector3i(999, 999, 999)

func _ready():
	# Setup noise for terrain generation
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.05
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	# Generate initial chunks
	if player:
		update_chunks(player.global_position)
	else:
		update_chunks(Vector3.ZERO)

func _process(_delta):
	# Update chunks based on player position
	if player:
		var current_chunk = world_to_chunk(player.global_position)
		if current_chunk != last_chunk_position:
			update_chunks(player.global_position)
			last_chunk_position = current_chunk

func update_chunks(player_pos: Vector3):
	player_position = player_pos
	var current_chunk = world_to_chunk(player_pos)
	
	# Remove chunks that are too far away
	var chunks_to_remove = []
	for chunk_pos in chunks.keys():
		if chunk_pos.distance_to(current_chunk) > render_distance:
			chunks_to_remove.append(chunk_pos)
	
	for chunk_pos in chunks_to_remove:
		chunks[chunk_pos].queue_free()
		chunks.erase(chunk_pos)
	
	# Generate new chunks
	for x in range(-render_distance, render_distance + 1):
		for z in range(-render_distance, render_distance + 1):
			var chunk_pos = Vector3i(current_chunk.x + x, 0, current_chunk.z + z)
			
			if not chunks.has(chunk_pos):
				create_chunk(chunk_pos)

func create_chunk(chunk_pos: Vector3i):
	var chunk = preload("res://scenes/VoxelChunk.tscn").instantiate()
	chunk.chunk_position = chunk_pos
	chunk.chunk_size = chunk_size
	chunk.voxel_size = voxel_size
	chunk.noise = noise
	chunk.position = Vector3(chunk_pos) * chunk_size * voxel_size
	
	add_child(chunk)
	chunks[chunk_pos] = chunk

func world_to_chunk(world_pos: Vector3) -> Vector3i:
	return Vector3i(
		floor(world_pos.x / (chunk_size * voxel_size)),
		0,
		floor(world_pos.z / (chunk_size * voxel_size))
	)

