# CFrameAndFlags

![Lua](https://img.shields.io/badge/Lua-blue?style=flat-square) ![Roblox](https://img.shields.io/badge/Roblox-executor-green?style=flat-square)

A Lua utility for directly reading and writing `CFrame` data and toggling primitive flags on Roblox `BasePart` instances via raw memory access.

---

## Features

- **CFrame read/write** — full position + 3×3 rotation matrix via memory I/O
- **Pitch/yaw/roll** — Euler-angle rotation matrix construction
- **Primitive flags** — set/check `Anchored`, `CanCollide`, `CanQuery`, `CanTouch`
- **Velocity cancel** — zero out a part's velocity directly in memory

---

## Memory layout

| Field | Offset | Notes |
|---|---|---|
| `BasePart → primitive` | `0x148` | uintptr |
| `primitive.cframe` | `0xC0` | 3×3 rotation + position |
| `primitive.velocity` | `0xF0` | fvector3 |
| `primitive.flags` | `0x1AE` | byte bitmask |
| flag: Anchored | `0x2` | |
| flag: CanCollide | `0x8` | |
| flag: CanQuery | `0x20` | |
| flag: CanTouch | `0x10` | |

---

## API reference

#### `read_cframe(part)` → cframe table
Reads the rotation matrix and position of a part from memory.

#### `write_cframe(part, cframe)`
Writes a cframe table (`rot` + `pos`) back to a part's primitive.

#### `rotation_from_pitch_yaw_roll(pitch, yaw, roll)` → rotation table
Builds a 3×3 rotation matrix from Euler angles (degrees).

#### `set_flag(part, flag, value)`
Sets or clears a primitive flag bit on a part. Pass `offsets.primitive_flags.*` as the flag.

#### `check_flag(part, flag)` → boolean
Returns whether a flag bit is currently set on a part.

#### `cancel_velocity(part)`
Zeroes the velocity vector of a part's primitive in memory.

---

## Usage example
```lua
-- Teleport local player on top of another character, facing upward
task.spawn(function()
    while true do
        cancel_velocity(game.Players.LocalPlayer.Character.HumanoidRootPart)

        local cf = read_cframe(game.Workspace.SomePlayer.HumanoidRootPart)
        cf.pos = cf.pos + Vector3.new(0, 5, 0)
        cf.rot = rotation_from_pitch_yaw_roll(90, 0, 0)
        write_cframe(game.Players.LocalPlayer.Character.HumanoidRootPart, cf)

        task.wait(1/240)
    end
end)

-- Anchor a part directly in memory
set_flag(game.Workspace.MyPart, offsets.primitive_flags.anchored, true)
```

---

## Notes

- Requires a `memory_read` / `memory_write` API — available in Matcha's LuaVM.
- Offsets are version-dependent and may need updating after Roblox patches.
- Rotation matrix layout is row-major: `r[row][col]`.
- Position is stored at `cframe + 0x24` as a float vector3.

---

*For educational and research purposes only.*
