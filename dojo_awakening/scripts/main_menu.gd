extends Control

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var title_label: Label = $TitleLabel

func _ready():
	start_button.pressed.connect(_on_start)
	settings_button.pressed.connect(_on_settings)
	quit_button.pressed.connect(_on_quit)

	# 标题动画
	var tween = create_tween().set_loops()
	tween.tween_property(title_label, "position:y", title_label.position.y - 10, 1.0)
	tween.tween_property(title_label, "position:y", title_label.position.y, 1.0)

func _on_start():
	# 进入角色选择界面
	get_tree().change_scene_to_file("res://scenes/stages/character_select.tscn")

func _on_settings():
	# 打开设置菜单
	pass

func _on_quit():
	get_tree().quit()
