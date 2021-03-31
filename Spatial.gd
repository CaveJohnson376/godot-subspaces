tool
extends Spatial

const chunk_size = 512
var chunk_amount = 2

var noise
var chunks = {}
var unready_chunks = {}
var thread = Thread.new()

func _ready():
	randomize()
	noise = OpenSimplexNoise.new()
	noise.seed = randi()
	
	noise.octaves = 6
	noise.period = 80
	noise.persistence = 0.4
	
	
	if Engine.is_editor_hint():
		chunk_amount = 1
	
func add_chunk(x, z):
	var key = str(x) + "," + str(z)
	
	if chunks.has(key) or unready_chunks.has(key):
		return
		
	if not thread.is_active():
		thread.start(self, "load_chunk", [thread, x, z])
		unready_chunks[key] = 1
		
func load_chunk(arr):
	var thread = arr[0]
	var x = arr[1]
	var z = arr[2]
	
	var chunk = Chunk.new(noise, x * chunk_size, z * chunk_size, chunk_size)
	chunk.translation = Vector3(x * chunk_size, 0, z*chunk_size)
	
	call_deferred("load_done", chunk, thread)
	
func load_done(chunk, thread):
	add_child(chunk)
	var key = str(chunk.x / chunk_size) + "," + str(chunk.z / chunk_size)
	chunks[key] = chunk
	unready_chunks.erase(key)
	thread.wait_to_finish()

func get_chunk(x, z):
	var key = str(x) + "," + str(z)
	if chunks.has(key):
		return chunks.get(key)
	
	return null

func _process(delta):
	update_chunks()
	clean_up_chunks()
	reset_chunks()

func update_chunks():
	var player_translation = $"../player".translation
	var spaceship_translation = $"../spaceship_exterior".translation
	
	var p_x = int(player_translation.x) / chunk_size
	var p_z = int(player_translation.z) / chunk_size
	var s_x = int(spaceship_translation.x) / chunk_size
	var s_z = int(spaceship_translation.z) / chunk_size

	for distance in range(0, chunk_amount):
		for x in range(-100, 100):
			for z in range(-100, 100):
				var pcurDistance = Vector2(x - p_x, z - p_z).length()
				var scurDistance = Vector2(x - s_x, z - s_z).length()
				
				if (pcurDistance >= distance and distance + 1 > pcurDistance) or (scurDistance >= distance and distance + 1 > scurDistance):
					add_chunk(x, z)
					var chunk = get_chunk(x, z)
					if chunk != null:
						chunk.should_remove = false


func clean_up_chunks():
	for key in chunks:
		var chunk = chunks[key]
		if chunk.should_remove:
			chunk.queue_free()
			chunks.erase(key)

func reset_chunks():
	for key in chunks:
		chunks[key].should_remove = true
