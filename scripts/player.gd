extends CharacterBody2D

# Character movement ability goals:
# - DONE tap/hold jump heights
# - DONE wall jump
# - DONE omni-directional dash
# - DONE coyote time
# - slide down slope when holding down on slope
# - hover fall
# - spawn platform
# - push blocks

#movement settings
@export var GRAVITY : float = 3000.0
@export var WALL_SLIDE_GRAVITY : float = 1500.0
@export var MAX_FALL_SPEED : float = 3000.0
@export var MAX_WALL_SLIDE_SPEED : float = 250.0
@export var MAX_SPEED : float = 200.0
@export var MAX_DASH_SPEED : float = 1500.0
@export var MAX_AIR_SPEED : float = 1500.0
@export var WALK_ACCEL : float = 75.0
@export var AIR_ACCEL : float = 25.0
@export var DASH : float = 600.0
@export var NORMAL_JUMP_HEIGHT : float = -300.0
@export var WALL_JUMP_HEIGHT : float = -200.0
@export var BACKFLIP_JUMP_HEIGHT : float = -1500.0
@export var COYOTE_TIME : float  = 0.09 #about 5 frames
@export var JUMP_BUFFER_TIME : float  = 0.09 #about 5 frames
@export var JUMP_RISE_TIME : float = 0.18
@export var DASH_COOLDOWN_TIME : float = 1.0 
@export var DASH_DURATION_TIME : float = .25

#timers
var coyote_timer : float = COYOTE_TIME
var jump_buffer_timer : float = 0.0
var jump_rise_timer : float = 0.0
var dash_cooldown_timer : float = 0.0
var dash_duration_timer : float = DASH_DURATION_TIME

#state flags
var jumping : bool = false
var dashing : bool = false
var skidding : bool = false

#other
@onready var last_solid = Vector2.DOWN
@onready var facing_direction = Vector2.RIGHT
@onready var on_wall_direction = 0 #-1: left; 1: right; 0: no wall

@onready var screen_size = get_viewport_rect().size

func _physics_process(_delta):
	var jump_height = NORMAL_JUMP_HEIGHT
	var accel = WALK_ACCEL
	var direction = Input.get_vector("Left", "Right", "Up", "Down")
	on_wall_direction = 0;
	#always: 
	#	update timers
	#if grounded:
	#	move / check for skid
	#	dash
	#	jump
	#if airborn:
	#	move
	#	dash
	#	wall cling
	
	#countdown timers for cooldowns/buffers
	update_timers(_delta)

	#grounded
	if is_on_floor():
		if skidding:
			print("skrrt")
		move(direction, true)
		last_solid = Vector2.DOWN
		coyote_timer = COYOTE_TIME
	#wall cling
	elif is_on_wall_only():
		if !jumping:
			on_wall_direction = find_wall_to_latch()
		coyote_timer = COYOTE_TIME
		process_gravity(_delta, WALL_SLIDE_GRAVITY, MAX_WALL_SLIDE_SPEED)
		move(direction, false)
	#in air
	else:
		if velocity.y > 0.0 : jumping = false
		process_gravity(_delta, GRAVITY, MAX_FALL_SPEED)
		move(direction, false)

	jump()
	dash(direction)
	move_and_slide()

func dash(direction):
	if Input.is_action_just_pressed("Dash") and dash_cooldown_timer <= 0.0:
		dash_duration_timer = DASH_DURATION_TIME
		dash_cooldown_timer = DASH_COOLDOWN_TIME
		if direction:
			velocity = direction * DASH
		else:
			velocity = facing_direction * DASH
		dashing = true
	#if !dashing:
	#	dash_duration_timer = DASH_DURATION_TIME
	if dash_duration_timer <= 0.0:
		dashing = false
	
func jump():
	if Input.is_action_just_pressed("Jump") and !jumping:
		jump_buffer_timer = JUMP_BUFFER_TIME
		jump_rise_timer = JUMP_RISE_TIME
	if (coyote_timer > 0.0 and jump_buffer_timer > 0.0):
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		jumping = true
	if jumping and jump_rise_timer > 0.0:
		print(on_wall_direction)
		if on_wall_direction == 0:
			velocity.y = NORMAL_JUMP_HEIGHT
		else:
			velocity.y = WALL_JUMP_HEIGHT
			velocity.x = WALL_JUMP_HEIGHT * on_wall_direction
	if Input.is_action_just_released("Jump") or jump_rise_timer < 0.0:
		jump_rise_timer = 0.0
		jumping = false

func move(direction, grounded):
	var target_speed = 0.0
	if direction:
		#allow player to maintain higher speeds if in air (bunny-hopping)
		if !grounded:
			target_speed = MAX_SPEED if abs(velocity.x) < MAX_SPEED else abs(velocity.x)
		else:
			target_speed = MAX_SPEED
	#if player is dashing we want to keep the velocity set in the dash method
	if !dashing:
		velocity.x = move_toward(velocity.x, direction.x * target_speed, WALK_ACCEL if grounded else AIR_ACCEL)
	if direction.x > 0.0:
		facing_direction = Vector2.RIGHT
		if velocity.x < 0.0:
			skidding = true
		else:
			skidding = false
	elif direction.x < 0.0:
		facing_direction = Vector2.LEFT
		if velocity.x > 0.0:
			skidding = true
		else:
			skidding = false
	if velocity.x == 0.0:
		skidding = false

func find_wall_to_latch():
	if test_move(transform,Vector2.LEFT):
		return -1;
	elif test_move(transform, Vector2.RIGHT):
		return 1
	print("We probably shouldn't reach this code...")
	return 0

#called every frame we are in air
func process_gravity(_delta, gravity, max_fall_speed):
	#if we are sliding up a wall, cut vert speed fast
	if is_on_wall_only() and velocity.y < 0:
		velocity.y /= 2
	velocity.y = move_toward(velocity.y, max_fall_speed, gravity * _delta)
	#if velocity.y >= MAX_FALL_SPEED: print("zoom")

#only count down the various timers if they are 
func update_timers(_delta):
	coyote_timer -= _delta
	jump_buffer_timer -= _delta
	jump_rise_timer -= _delta
	dash_cooldown_timer -= _delta
	dash_duration_timer -= _delta
