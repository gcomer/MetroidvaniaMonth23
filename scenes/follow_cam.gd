extends Camera2D

@export var follow_target : Node2D

const OFFSET = Vector2.ZERO#Vector2(50, -50)
const SPEED = 10.0
const MAX_DISTANCE = 500.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	print(position)
	if position.distance_to(follow_target.position) > MAX_DISTANCE:
		print("snapping cam")
		position = follow_target.position.direction_to(position) * MAX_DISTANCE
	else:
		print("moving cam")
		position.x = move_toward(position.x, follow_target.position.x, SPEED)
		position.y = move_toward(position.y, follow_target.position.y, SPEED)
