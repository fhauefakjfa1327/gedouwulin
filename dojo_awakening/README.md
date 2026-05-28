# 武道觉醒 (Dojo Awakening)

一款基于 Godot 4.x 开发的 2D 单机格斗游戏。

## 🎮 游戏特色

- **4 名独特角色**：均衡型、速度型、力量型、技巧型
- **完整格斗系统**：轻/重拳脚、格挡、必杀技、连击
- **智能 AI 对手**：4 种难度，行为树决策系统
- **多种游戏模式**：剧情、街机、训练、生存
- **视觉特效**：屏幕震动、打击冻结、伤害数字、连击显示
- **输入缓冲系统**：流畅的连招体验

## 🎯 操作说明

| 按键 | 功能 |
|------|------|
| A/D 或 ←/→ | 左右移动 |
| W 或 ↑ | 跳跃 |
| S 或 ↓ | 蹲下 |
| J | 轻拳 |
| U | 重拳 |
| K | 轻脚 |
| I | 重脚 |
| L | 必杀技（满槽时）|
| 空格 | 格挡 |
| ESC | 暂停 |

## 📁 项目结构

```
dojo_awakening/
├── project.godot              # 项目配置
├── scripts/
│   ├── fighter_base.gd        # 格斗者基类
│   ├── player_controller.gd   # 玩家控制器
│   ├── ai_controller.gd       # AI 控制器（行为树）
│   ├── battle_manager.gd      # 战斗管理器
│   ├── training_mode.gd       # 训练模式
│   ├── survival_mode.gd       # 生存模式
│   ├── audio_manager.gd       # 音效管理
│   ├── screen_effects.gd      # 屏幕特效
│   ├── combo_display.gd       # 连击显示
│   ├── damage_number.gd       # 伤害数字
│   ├── character_select.gd    # 角色选择
│   └── game_data.gd           # 全局数据
├── scenes/
│   ├── player/player.tscn     # 玩家场景
│   ├── enemy/enemy.tscn       # 敌人场景
│   ├── stages/
│   │   ├── main_menu.tscn     # 主菜单
│   │   ├── battle_arena.tscn  # 战斗场景
│   │   └── character_select.tscn # 角色选择
│   └── ui/hit_effect.tscn     # 受击特效
├── data/
│   └── characters.json        # 角色数据
└── assets/
    ├── sprites/               # 角色精灵图（需自行添加）
    ├── backgrounds/           # 背景图（需自行添加）
    ├── sfx/                   # 音效（需自行添加）
    └── music/                 # 音乐（需自行添加）
```

## 🚀 快速开始

1. **安装 Godot 4.x**
   - 下载 [Godot Engine](https://godotengine.org/)
   - 建议使用 Godot 4.2 或更高版本

2. **导入项目**
   - 打开 Godot
   - 点击 "Import"
   - 选择 `project.godot` 文件

3. **添加美术资源**
   - 角色精灵图：放入 `assets/sprites/`
   - 背景图：放入 `assets/backgrounds/`
   - 建议尺寸：角色 64x128px，背景 1280x720px

4. **添加音效**
   - 音效文件：放入 `assets/sfx/`
   - 音乐文件：放入 `assets/music/`
   - 支持格式：WAV, OGG

5. **运行游戏**
   - 按 F5 或点击播放按钮

## 🎨 美术资源建议

### 角色动画需求（每角色）
- idle: 待机（4-6 帧）
- walk: 行走（6-8 帧）
- jump: 跳跃（2-3 帧）
- fall: 下落（2 帧）
- light_punch: 轻拳（3-4 帧）
- heavy_punch: 重拳（4-5 帧）
- light_kick: 轻脚（3-4 帧）
- heavy_kick: 重脚（4-5 帧）
- block: 格挡（1-2 帧）
- block_hit: 格挡受击（2 帧）
- hit_light: 轻受击（2-3 帧）
- hit_heavy: 重受击（3-4 帧）
- knockdown: 击倒（3-4 帧）
- getup: 起身（3-4 帧）
- special: 必杀技（6-10 帧）
- win: 胜利（4-6 帧）
- dead: 死亡（3-4 帧）

### 推荐工具
- [Aseprite](https://www.aseprite.org/) - 像素画/动画
- [itch.io](https://itch.io/game-assets) - 免费素材

## 🔊 音效资源建议

### 需要音效
- 各类攻击音效（轻重拳脚）
- 受击音效（轻重）
- 格挡音效
- 必杀技音效
- 跳跃/落地音效
- UI 音效
- 连击语音

### 推荐工具
- [Bfxr](https://www.bfxr.net/) - 8-bit 音效生成
- [Freesound](https://freesound.org/) - 免费音效库

## 🤖 AI 行为树详解

AI 控制器使用简化行为树进行决策：

```
[根节点]
  ├── [防御评估] ← 最高优先级
  │     └── 条件：玩家正在攻击且距离近
  ├── [必杀技评估]
  │     └── 条件：必杀槽满且距离合适
  ├── [攻击评估]
  │     └── 条件：距离近且玩家硬直
  ├── [接近评估]
  │     └── 条件：距离远
  ├── [撤退评估]
  │     └── 条件：血量低或玩家必杀
  └── [待机]
```

### 难度参数
| 难度 | 反应延迟 | 侵略性 | 连击技巧 |
|------|---------|--------|---------|
| Easy | 0.3s | 0.3 | 0.2 |
| Normal | 0.15s | 0.5 | 0.5 |
| Hard | 0.08s | 0.7 | 0.7 |
| Expert | 0.03s | 0.9 | 0.9 |

## 🛠️ 扩展开发

### 添加新角色
1. 在 `data/characters.json` 中添加角色数据
2. 创建新的场景文件
3. 继承 `Fighter` 基类
4. 添加专属必杀技动画

### 添加新场景
1. 复制 `battle_arena.tscn`
2. 修改背景和碰撞体
3. 调整相机限制

### 添加新游戏模式
1. 继承 `BattleManager`
2. 重写 `_start_round()` 和 `_end_round()`
3. 在菜单中添加入口

## 📜 许可证

MIT License - 可自由使用、修改和分发。

## 🙏 致谢

- 基于 [agency-agents](https://github.com/msitarzewski/agency-agents) 游戏开发 Agent 方法论
- 使用 Godot Engine 开发
