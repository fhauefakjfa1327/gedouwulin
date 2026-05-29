extends Control

@onready var character_grid: GridContainer = $CharacterGrid
@onready var preview_sprite: TextureRect = $PreviewPanel/PreviewSprite
@onready var name_label: Label = $PreviewPanel/NameLabel
@onready var desc_label: Label = $PreviewPanel/DescLabel
@onready var stats_container: VBoxContainer = $PreviewPanel/StatsContainer
@onready var confirm_button: Button = $ConfirmButton
@onready var back_button: Button = $BackButton

var selected_index: int = 0
var characters = [] # 移除 Array[Dictionary] 强类型
var is_locked: bool = false

func _ready():
	_load_characters()
	_setup_ui()
	_select_character(0)

func _load_characters():
	var file = FileAccess.open("res://data/characters.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			var data = json.get_data()
			characters = data["characters"] # 直接赋值，不强类型检查

func _setup_ui():
	# 创建角色选择按钮
	for i in range(characters.size()):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(120, 120)

		# 使用头像
		var avatar_path = "res://assets/sprites/" + characters[i]["id"] + "_avatar.png"
		if ResourceLoader.exists(avatar_path):
			var icon = TextureRect.new()
			icon.texture = load(avatar_path)
			icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(80, 80)
			btn.add_child(icon)
			icon.position = Vector2(20, 10)

		# 角色名标签
		var name_label_btn = Label.new()
		name_label_btn.text = characters[i]["name"]
		name_label_btn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label_btn.position = Vector2(0, 95)
		name_label_btn.size = Vector2(120, 20)
		btn.add_child(name_label_btn)

		# 设置颜色边框
		var color = Color(characters[i]["color"])
		btn.modulate = color

		btn.pressed.connect(_on_character_selected.bind(i))
		character_grid.add_child(btn)

	confirm_button.pressed.connect(_on_confirm)
	back_button.pressed.connect(_on_back)

func _on_character_selected(index: int):
	if is_locked:
		return
	_select_character(index)

func _select_character(index: int):
	selected_index = index
	var char_data = characters[index]

	# 更新预览立绘
	var portrait_path = "res://assets/sprites/" + char_data["id"] + "_portrait.png"
	if ResourceLoader.exists(portrait_path):
		preview_sprite.texture = load(portrait_path)

	name_label.text = char_data["name"]
	desc_label.text = char_data["description"]

	# 更新属性条
	_update_stat_bar("Health", char_data["stats"]["health"], 150)
	_update_stat_bar("Speed", char_data["stats"]["speed"], 250)
	_update_stat_bar("Attack", char_data["stats"]["heavy_punch"], 35)

	# 高亮选中按钮
	for i in range(character_grid.get_child_count()):
		var btn = character_grid.get_child(i)
		if i == index:
			btn.modulate = Color(1, 1, 1, 1)
			btn.self_modulate = Color(1, 1, 1, 1)
		else:
			var color = Color(characters[i]["color"])
			btn.modulate = color

func _update_stat_bar(stat_name: String, value: int, max_value: int):
	var bar_name = stat_name + "Bar"
	var bar = stats_container.get_node(bar_name)
	if bar:
		bar.max_value = max_value
		bar.value = value

	var label = stats_container.get_node(stat_name + "Label")
	if label:
		label.text = "%s: %d" % [stat_name, value]

func _on_confirm():
	if is_locked:
		return
	is_locked = true

	# 保存选择到全局数据
	var selected = characters[selected_index]
	GameData.selected_character = selected

	# 修复：使用 call_deferred 延迟场景切换，避免与 tween 竞争
	# 同时禁用输入处理防止重复触发
	set_process_input(false)

	# 过渡到战斗场景 - 使用更安全的场景切换方式
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(_do_scene_change)

func _do_scene_change():
	# 确保在当前帧结束后切换场景，避免信号/回调冲突
	call_deferred("_change_scene_deferred")

func _change_scene_deferred():
	get_tree().change_scene_to_file("res://scenes/stages/battle_arena.tscn")

func _on_back():
	get_tree().change_scene_to_file("res://scenes/stages/main_menu.tscn")

func _input(event: InputEvent):
	if is_locked:
		return

	if event.is_action_pressed("ui_left"):
		_select_character(max(0, selected_index - 1))
	elif event.is_action_pressed("ui_right"):
		_select_character(min(characters.size() - 1, selected_index + 1))
	elif event.is_action_pressed("ui_accept"):
		_on_confirm()
	elif event.is_action_pressed("ui_cancel"):
		_on_back()