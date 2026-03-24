# 🚀 Space Shooter 3D — Godot Engine

A 3D space shooter game built with Godot 4, with automated builds for Windows (.exe) and Android (.apk) via GitHub Actions.

## 🎮 Features
- Full 3D space environment with starfield
- Player ship with movement and shooting
- Enemy waves with AI
- Explosions and particle effects
- Score system
- Mobile touch controls (Android)
- Keyboard/mouse controls (PC)

## 🛠 Tech Stack
- **Engine**: Godot 4.x
- **Language**: GDScript
- **CI/CD**: GitHub Actions
- **Platforms**: Windows, Android

## 📦 Build Artifacts
After each push to `main`, GitHub Actions automatically produces:
- `SpaceShooter-Windows.exe` — Windows build
- `SpaceShooter-Android.apk` — Android build

## 🚀 Quick Start

### Local Development
1. Download [Godot 4](https://godotengine.org/download/)
2. Clone this repo
3. Open `project.godot` in Godot
4. Press F5 to run

### Automated Builds (GitHub Actions)
1. Fork/push to GitHub
2. Go to **Actions** tab
3. Workflow runs automatically on push
4. Download artifacts from the workflow run

## 📁 Project Structure
```
space-shooter/
├── .github/
│   └── workflows/
│       └── build.yml          # CI/CD pipeline
├── project.godot              # Godot project config
├── export_presets.cfg         # Export settings
├── scenes/
│   ├── Main.tscn              # Main game scene
│   ├── Player.tscn            # Player ship
│   ├── Enemy.tscn             # Enemy ship
│   ├── Bullet.tscn            # Projectile
│   └── Explosion.tscn         # Explosion effect
├── scripts/
│   ├── Main.gd                # Game logic
│   ├── Player.gd              # Player controller
│   ├── Enemy.gd               # Enemy AI
│   ├── Bullet.gd              # Bullet behavior
│   └── GameUI.gd              # HUD/UI
└── assets/
    └── (textures, sounds)
```

## 🎯 Controls

| Action | PC | Mobile |
|--------|-----|--------|
| Move | WASD / Arrow Keys | Joystick |
| Shoot | Space / LMB | Fire Button |
| Pause | Escape | Pause Button |

## ⚙️ Export Setup (first time)

In Godot Editor:
1. **Project → Export**
2. Add **Windows Desktop** preset
3. Add **Android** preset
4. Set Android SDK path in Editor Settings
5. The `export_presets.cfg` is already configured for CI

## 🔑 GitHub Secrets Required

For Android signing (optional, debug build works without):
- `KEYSTORE_BASE64` — base64 encoded keystore
- `KEY_ALIAS` — key alias
- `KEY_PASSWORD` — key password
- `STORE_PASSWORD` — store password
