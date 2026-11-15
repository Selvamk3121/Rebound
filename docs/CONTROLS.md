# REBOUND: Control Mapping Specification

## Default Input Mapping

| Action Identifier | Input Device | Physical Key / Mouse | Description |
| :--- | :--- | :--- | :--- |
| `move_up` | Keyboard | `W` / `Up Arrow` | Move player upward |
| `move_down` | Keyboard | `S` / `Down Arrow` | Move player downward |
| `move_left` | Keyboard | `A` / `Left Arrow` | Move player leftward |
| `move_right` | Keyboard | `D` / `Right Arrow` | Move player rightward |
| `fire` | Keyboard / Mouse | `Spacebar` (Primary) / `LMB` | Fire equipped weapon / Ricochet shot |
| `interact` | Keyboard | `E` | Interact with doors, panels, pickups |
| `reload` | Keyboard | `R` | Reload weapon magazine |
| `inventory` | Keyboard | `I` | Toggle backpack inventory screen |
| `weapon_1` | Keyboard | `1` | Select Standard Firearm (Pistol frame) |
| `weapon_2` | Keyboard | `2` | Select Security Ricochet Gun (Shotgun frame) |
| `weapon_3` | Keyboard | `3` | Select Advanced Bio-Energy Weapon (Rifle frame) |
| `weapon_4` | Keyboard | `4` | Select Heavy Kinetic Vulcan (Heavy frame) |
| `cycle_weapon` | Mouse | `Wheel Up` / `Wheel Down` | Cycle previous / next weapon |
| `retry` | Keyboard | `R` / `Enter` / `Space` | Retry sector after victory or defeat |
| `pause` | Keyboard | `Escape` | Pause game / open in-game menu |

### Aiming Mechanics
- The weapon pivot and player view track the real-time mouse cursor position in world space via `get_global_mouse_position()`.
- Movement velocity is strictly normalized when moving diagonally ($||\vec{V}|| = \text{speed}$) to prevent diagonal speed exploitation.
