extends Node

class_name ResourceLoader

# ========== 精灵图路径 ==========
const SPRITE_PATH = "res://assets/sprites/"
const BACKGROUND_PATH = "res://assets/backgrounds/"
const SFX_PATH = "res://assets/sfx/"
const MUSIC_PATH = "res://assets/music/"

# ========== 角色精灵图 ==========
# 每个角色需要以下动画（PNG 序列帧）：
# idle_01.png ~ idle_06.png    (待机)
# walk_01.png ~ walk_08.png    (行走)
# jump_01.png ~ jump_03.png    (跳跃)
# fall_01.png ~ fall_02.png    (下落)
# lpunch_01.png ~ lpunch_04.png (轻拳)
# hpunch_01.png ~ hpunch_05.png (重拳)
# lkick_01.png ~ lkick_04.png  (轻脚)
# hkick_01.png ~ hkick_05.png  (重脚)
# block_01.png ~ block_02.png  (格挡)
# bhit_01.png ~ bhit_02.png    (格挡受击)
# lhit_01.png ~ lhit_03.png    (轻受击)
# hhit_01.png ~ hhit_04.png    (重受击)
# down_01.png ~ down_04.png    (击倒)
# getup_01.png ~ getup_04.png  (起身)
# special_01.png ~ special_08.png (必杀技)
# win_01.png ~ win_06.png      (胜利)
# dead_01.png ~ dead_04.png    (死亡)
# crouch_01.png ~ crouch_02.png (蹲下)

# ========== 生成彩色占位精灵图 ==========
static func generate_placeholder_sprite(color: Color, size: Vector2i = Vector2i(64, 128)) -> ImageTexture:
	var image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(color)

	# 添加边框
	for x in range(size.x):
		image.set_pixel(x, 0, Color.WHITE)
		image.set_pixel(x, size.y - 1, Color.WHITE)
	for y in range(size.y):
		image.set_pixel(0, y, Color.WHITE)
		image.set_pixel(size.x - 1, y, Color.WHITE)

	# 添加角色标识
	var font = ThemeDB.fallback_font
	if font:
		# 简化：在中心画一个十字
		var cx = size.x / 2
		var cy = size.y / 2
		for i in range(-10, 11):
			image.set_pixel(cx + i, cy, Color.WHITE)
			image.set_pixel(cx, cy + i, Color.WHITE)

	var texture = ImageTexture.create_from_image(image)
	return texture

# ========== 加载角色精灵图 ==========
static func load_character_sprites(character_id: String) -> SpriteFrames:
	var sprite_frames = SpriteFrames.new()

	# 角色颜色映射
	var colors = {
		"ryuichi": Color(0.9, 0.2, 0.2),   # 红色
		"kage": Color(0.6, 0.2, 0.8),      # 紫色
		"tetsuzan": Color(0.2, 0.7, 0.3),  # 绿色
		"shimo": Color(0.2, 0.5, 0.9)      # 蓝色
	}

	var color = colors.get(character_id, Color(0.5, 0.5, 0.5))

	# 定义动画
	var animations = {
		"idle": {"frames": 4, "fps": 5},
		"walk": {"frames": 6, "fps": 8},
		"jump": {"frames": 2, "fps": 5},
		"fall": {"frames": 2, "fps": 5},
		"light_punch": {"frames": 3, "fps": 10},
		"heavy_punch": {"frames": 4, "fps": 8},
		"light_kick": {"frames": 3, "fps": 10},
		"heavy_kick": {"frames": 4, "fps": 8},
		"block": {"frames": 1, "fps": 5},
		"block_hit": {"frames": 2, "fps": 5},
		"hit_light": {"frames": 2, "fps": 5},
		"hit_heavy": {"frames": 3, "fps": 5},
		"knockdown": {"frames": 3, "fps": 5},
		"getup": {"frames": 3, "fps": 5},
		"special": {"frames": 6, "fps": 8},
		"win": {"frames": 4, "fps": 5},
		"dead": {"frames": 3, "fps": 5},
		"crouch": {"frames": 1, "fps": 5}
	}

	for anim_name in animations.keys():
		var anim_data = animations[anim_name]
		var frame_count = anim_data["frames"]
		var fps = anim_data["fps"]

		# 尝试加载实际资源
		var loaded_frames = 0
		for i in range(frame_count):
			var frame_num = i + 1
			var file_name = "%s_%02d.png" % [anim_name, frame_num]
			var file_path = SPRITE_PATH + character_id + "/" + file_name

			if ResourceLoader.exists(file_path):
				var texture = load(file_path)
				if texture:
					if loaded_frames == 0:
						sprite_frames.add_animation(anim_name)
						sprite_frames.set_animation_speed(anim_name, fps)
						if anim_name in ["light_punch", "heavy_punch", "light_kick", "heavy_kick", "special", "hit_light", "hit_heavy", "knockdown", "getup"]:
							sprite_frames.set_animation_loop(anim_name, false)
						else:
							sprite_frames.set_animation_loop(anim_name, true)

					sprite_frames.add_frame(anim_name, texture)
					loaded_frames += 1

		# 如果没有加载到任何帧，使用占位图
		if loaded_frames == 0:
			sprite_frames.add_animation(anim_name)
			sprite_frames.set_animation_speed(anim_name, fps)
			if anim_name in ["light_punch", "heavy_punch", "light_kick", "heavy_kick", "special", "hit_light", "hit_heavy", "knockdown", "getup"]:
				sprite_frames.set_animation_loop(anim_name, false)
			else:
				sprite_frames.set_animation_loop(anim_name, true)

			var placeholder = generate_placeholder_sprite(color)
			for i in range(frame_count):
				sprite_frames.add_frame(anim_name, placeholder)

	return sprite_frames

# ========== 加载背景 ==========
static func load_background(stage_id: String) -> Texture2D:
	var file_path = BACKGROUND_PATH + stage_id + ".png"
	if ResourceLoader.exists(file_path):
		return load(file_path)

	# 生成占位背景
	var image = Image.create(1280, 720, false, Image.FORMAT_RGBA8)

	# 渐变背景
	for y in range(720):
		var t = float(y) / 720.0
		var color = Color(0.1, 0.1, 0.15).lerp(Color(0.2, 0.15, 0.1), t)
		for x in range(1280):
			image.set_pixel(x, y, color)

	# 添加网格线
	for x in range(0, 1280, 64):
		for y in range(720):
			image.set_pixel(x, y, Color(0.3, 0.3, 0.3, 0.3))
	for y in range(0, 720, 64):
		for x in range(1280):
			image.set_pixel(x, y, Color(0.3, 0.3, 0.3, 0.3))

	return ImageTexture.create_from_image(image)

# ========== 生成音效 ==========
static func generate_sfx_waveform(sfx_type: String) -> AudioStreamWAV:
	var sample_rate = 44100
	var duration = 0.2
	var num_samples = int(sample_rate * duration)

	var data = PackedByteArray()
	data.resize(num_samples * 2)  # 16-bit mono

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var sample = 0.0

		match sfx_type:
			"light_punch", "light_kick":
				sample = sin(t * 800 * PI * 2) * exp(-t * 20)
			"heavy_punch", "heavy_kick":
				sample = sin(t * 400 * PI * 2) * exp(-t * 15)
			"block":
				sample = sin(t * 1200 * PI * 2) * exp(-t * 30) * 0.5
			"hit":
				sample = (randf() * 2 - 1) * exp(-t * 10)
			"special":
				sample = sin(t * 600 * PI * 2) * exp(-t * 5)
			_:
				sample = sin(t * 1000 * PI * 2) * exp(-t * 25)

		# 转换为 16-bit
		var value = int(clamp(sample * 32767, -32768, 32767))
		data.encode_s16(i * 2, value)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data

	return stream

# ========== 加载音效 ==========
static func load_sfx(sfx_name: String) -> AudioStream:
	var file_path = SFX_PATH + sfx_name + ".wav"
	if ResourceLoader.exists(file_path):
		return load(file_path)

	# 生成占位音效
	return generate_sfx_waveform(sfx_name)

# ========== 加载音乐 ==========
static func load_music(music_name: String) -> AudioStream:
	var ogg_path = MUSIC_PATH + music_name + ".ogg"
	var mp3_path = MUSIC_PATH + music_name + ".mp3"
	var wav_path = MUSIC_PATH + music_name + ".wav"

	if ResourceLoader.exists(ogg_path):
		return load(ogg_path)
	if ResourceLoader.exists(mp3_path):
		return load(mp3_path)
	if ResourceLoader.exists(wav_path):
		return load(wav_path)

	# 生成占位音乐（简单的嗡嗡声）
	var sample_rate = 44100
	var duration = 5.0
	var num_samples = int(sample_rate * duration)

	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var sample = sin(t * 220 * PI * 2) * 0.1  # 低音A
		var value = int(clamp(sample * 32767, -32768, 32767))
		data.encode_s16(i * 2, value)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = num_samples

	return stream
