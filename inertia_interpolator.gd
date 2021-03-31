extends Spatial
export var target = Vector3(0, 0, 0)
export var acceleration = 0.1
export var velocity = Vector3(0, 0, 0)
export var max_speed = -1

func _ready():
	pass

func _process(delta):
	var delta_translation = target - translation
	velocity += delta_translation.normalized() * pow(delta_translation.length() * acceleration, 2) * delta
	if not (max_speed == -1):
		velocity = velocity.normalized() * clamp(velocity.length(), 0, max_speed)
	
	translation += velocity * delta
