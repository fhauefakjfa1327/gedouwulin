extends CanvasLayer

@onready var flash_rect: ColorRect
@onready var slowdown_timer: Timer

var original_time_scale: float = 1.0

func _ready():
	flash_rect = get_node_or_null("FlashRect")
	slowdown_timer = get_node_or_null("SlowdownTimer")

	if flash_rect:
		flash_rect.visible = false
		flash_rect.color = Color(1, 1, 1, 0)

func flash_screen(color: Color = Color.WHITE, duration: float = 0.1):
	if not flash_rect:
		return

	flash_rect.color = color
	flash_rect.color.a = 0.8
	flash_rect.visible = true

	var tween = create_tween()
	tween.tween_property(flash_rect, "color:a", 0.0, duration)
	tween.tween_callback(func(): 
		if flash_rect:
			flash_rect.visible = false
	)

func hit_stop(duration: float = 0.05):
	Engine.time_scale = 0.01
	var timer = get_tree().create_timer(duration * 0.01)
	await timer.timeout
	Engine.time_scale = original_time_scale

func slowdown(duration: float = 0.5, target_scale: float = 0.3):
	original_time_scale = Engine.time_scale

	var tween = create_tween()
	tween.tween_property(Engine, "time_scale", target_scale, 0.1)

	if slowdown_timer:
		slowdown_timer.wait_time = duration
		slowdown_timer.start()
		await slowdown_timer.timeout
	else:
		var timer = get_tree().create_timer(duration)
		await timer.timeout

	tween = create_tween()
	tween.tween_property(Engine, "time_scale", original_time_scale, 0.2)

func zoom_in(duration: float = 0.3, target_zoom: Vector2 = Vector2(1.2, 1.2)):
	var camera = get_viewport().get_camera_2d()
	if camera:
		var tween = create_tween()
		tween.tween_property(camera, "zoom", target_zoom, duration)

func zoom_out(duration: float = 0.3):
	var camera = get_viewport().get_camera_2d()
	if camera:
		var tween = create_tween()
		tween.tween_property(camera, "zoom", Vector2(1.0, 1.0), duration)

func super_freeze():
	flash_screen(Color(0.5, 0.8, 1.0), 0.3)
	slowdown(1.0, 0.1)
	zoom_in(0.2, Vector2(1.3, 1.3))

	var timer = get_tree().create_timer(1.0)
	await timer.timeout
	zoom_out(0.3)
