extends Node

const SFX_PATH = "res://assets/sfx/"
const MUSIC_PATH = "res://assets/music/"

var sfx_library = {}
var music_library = {}

var sfx_players = []
var music_player: AudioStreamPlayer
var max_sfx_players: int = 8

var master_volume: float = 1.0
var sfx_volume: float = 0.8
var music_volume: float = 0.6

func _ready():
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

	for i in range(max_sfx_players):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)

	_preload_sfx()
	_preload_music()
	_update_volumes()

func _preload_sfx():
	var sfx_files = {
		"light_punch": "light_punch.wav",
		"heavy_punch": "heavy_punch.wav",
		"light_kick": "light_kick.wav",
		"heavy_kick": "heavy_kick.wav",
		"block": "block.wav",
		"block_hit": "block_hit.wav",
		"hit_light": "hit_light.wav",
		"hit_heavy": "hit_heavy.wav",
		"knockdown": "knockdown.wav",
		"special": "special.wav",
		"jump": "jump.wav",
		"land": "land.wav",
		"step": "step.wav",
		"win": "win.wav",
		"dead": "dead.wav",
		"countdown": "countdown.wav",
		"fight": "fight.wav",
		"ui_click": "ui_click.wav",
		"ui_hover": "ui_hover.wav",
		"combo_2": "combo_2.wav",
		"combo_3": "combo_3.wav",
		"combo_4": "combo_4.wav",
		"combo_5": "combo_5.wav",
		"perfect_block": "perfect_block.wav"
	}

	for key in sfx_files.keys():
		var path = SFX_PATH + sfx_files[key]
		if ResourceLoader.exists(path):
			sfx_library[key] = load(path)

func _preload_music():
	var music_files = {
		"main_menu": "main_menu.ogg",
		"battle": "battle.ogg",
		"boss": "boss.ogg",
		"victory": "victory.ogg",
		"defeat": "defeat.ogg"
	}

	for key in music_files.keys():
		var path = MUSIC_PATH + music_files[key]
		if ResourceLoader.exists(path):
			music_library[key] = load(path)

func play_sfx(sfx_name: String, pitch_variation: float = 0.0):
	if not sfx_library.has(sfx_name):
		return

	for player in sfx_players:
		if not player.playing:
			player.stream = sfx_library[sfx_name]
			player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
			player.play()
			return

func play_music(music_name: String, fade_duration: float = 1.0):
	if not music_library.has(music_name):
		return

	var new_stream = music_library[music_name]

	if music_player.playing and music_player.stream == new_stream:
		return

	if music_player.playing:
		_fade_music_out(fade_duration / 2.0)
		var timer = get_tree().create_timer(fade_duration / 2.0)
		await timer.timeout

	music_player.stream = new_stream
	music_player.play()
	_fade_music_in(fade_duration / 2.0)

func stop_music(fade_duration: float = 1.0):
	if music_player.playing:
		_fade_music_out(fade_duration)
		var timer = get_tree().create_timer(fade_duration)
		await timer.timeout
		music_player.stop()

func _fade_music_in(duration: float):
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", linear_to_db(music_volume), duration)

func _fade_music_out(duration: float):
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", linear_to_db(0.001), duration)

func set_master_volume(volume: float):
	master_volume = clamp(volume, 0.0, 1.0)
	_update_volumes()

func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)
	_update_volumes()

func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)
	_update_volumes()

func _update_volumes():
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))

	var sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus >= 0:
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(sfx_volume))

	var music_bus = AudioServer.get_bus_index("Music")
	if music_bus >= 0:
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(music_volume))

func play_attack_sfx(attack_type: String):
	match attack_type:
		"light_punch": play_sfx("light_punch", 0.1)
		"heavy_punch": play_sfx("heavy_punch", 0.05)
		"light_kick": play_sfx("light_kick", 0.1)
		"heavy_kick": play_sfx("heavy_kick", 0.05)
		"special": play_sfx("special")

func play_hit_sfx(is_heavy: bool):
	if is_heavy:
		play_sfx("hit_heavy")
	else:
		play_sfx("hit_light")

func play_combo_sfx(combo_count: int):
	match combo_count:
		2: play_sfx("combo_2")
		3: play_sfx("combo_3")
		4: play_sfx("combo_4")
		_: play_sfx("combo_5") if combo_count >= 5 else play_sfx("combo_2")
