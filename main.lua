local offsets = {
    base_part = {
        primitive = 0x148,
    },
    primitive = {
        cframe = 0xC0,
        velocity = 0xF0,
        primitive_flags = 0x1AE,
    },
    primitive_flags = {
        anchored = 0x2,
        can_collide = 0x8,
        can_query = 32,
        can_touch = 16,
    },
}

local cframe_table = {
    rot = {
        r00 = 0, r01 = 0, r02 = 0,
        r10 = 0, r11 = 0, r12 = 0,
    },
    pos = {
        X = 0,
        Y = 0,
        Z = 0,
    },
    look_vector = {
        X = 0,
        Y = 0,
        Z = 0,
    }, -- backlook? aka rot20, rot21, rot22
}

-- Helpers
local function read_fvector3(address, offset)
    local x = memory_read("float", address + offset)
    local y = memory_read("float", address + offset + 0x4)
    local z = memory_read("float", address + offset + 0x8)
    return Vector3.new(x, y, z)
end

local function write_fvector3(address, offset, vec)
    memory_write("float", address + offset, vec.X)
    memory_write("float", address + offset + 0x4, vec.Y)
    memory_write("float", address + offset + 0x8, vec.Z)
end

local function read_rotation(address)
    local r = {}
    r.r00 = memory_read("float", address + 0x00)
    r.r01 = memory_read("float", address + 0x04)
    r.r02 = memory_read("float", address + 0x08)
    r.r10 = memory_read("float", address + 0x0C)
    r.r11 = memory_read("float", address + 0x10)
    r.r12 = memory_read("float", address + 0x14)
    r.r20 = memory_read("float", address + 0x18)
    r.r21 = memory_read("float", address + 0x1C)
    r.r22 = memory_read("float", address + 0x20)
    return r
end

local function write_rotation(address, rotation)
    memory_write("float", address + 0x00, rotation.r00)
    memory_write("float", address + 0x04, rotation.r01)
    memory_write("float", address + 0x08, rotation.r02)
    memory_write("float", address + 0x0C, rotation.r10)
    memory_write("float", address + 0x10, rotation.r11)
    memory_write("float", address + 0x14, rotation.r12)
    memory_write("float", address + 0x18, rotation.r20)
    memory_write("float", address + 0x1C, rotation.r21)
    memory_write("float", address + 0x20, rotation.r22)
end

local function rotation_from_pitch_yaw_roll(pitchDeg, yawDeg, rollDeg)
    local pitch = math.rad(pitchDeg)
    local yaw = math.rad(yawDeg)
    local roll = math.rad(rollDeg)

    local cp, sp = math.cos(pitch), math.sin(pitch)
    local cy, sy = math.cos(yaw), math.sin(yaw)
    local cr, sr = math.cos(roll), math.sin(roll)

    local rot = {}
    rot.r00 = cy * cr + sy * sp * sr
    rot.r01 = sr * cp
    rot.r02 = -sy * cr + cy * sp * sr

    rot.r10 = -cy * sr + sy * sp * cr
    rot.r11 = cr * cp
    rot.r12 = sr * sy + cy * sp * cr

    rot.r20 = sy * cp
    rot.r21 = -sp
    rot.r22 = cy * cp

    return rot
end

local function set_flag(part, flag, value)
    if not part then return end
    local prim = memory_read("uintptr", part.Address + offsets.base_part.primitive)
    if prim == 0 then return end
    local flags = memory_read("byte", prim + offsets.primitive.primitive_flags)
    if value then
        flags = flags + flag - (flags // (2*flag)) * (2*flag)
    else
        if flags >= flag then
            flags = flags - flag
        end
    end
    memory_write("byte", prim + offsets.primitive.primitive_flags, flags)
end

local function check_flag(part, flag)
    if not part then return end
    local prim = memory_read("uintptr", part.Address + offsets.base_part.primitive)
    if prim == 0 then return false end
    local flags = memory_read("byte", prim + offsets.primitive.primitive_flags)
    return flags >= flag
end

-- Read/Write
local function read_cframe(part)
    if not part then return end
    local prim = memory_read("uintptr", part.Address + offsets.base_part.primitive)
    if prim == 0 then return end
    local cframe = {}
    cframe.rot = read_rotation(prim + offsets.primitive.cframe)
    cframe.pos = read_fvector3(prim, offsets.primitive.cframe + 0x24)
    return cframe
end

local function write_cframe(part, cframe)
    if not part then return end
    local prim = memory_read("uintptr", part.Address + offsets.base_part.primitive)
    if prim == 0 then return end
    write_rotation(prim + offsets.primitive.cframe, cframe.rot)
    write_fvector3(prim, offsets.primitive.cframe + 0x24, cframe.pos)
end

local function cancel_velocity(part)
    local prim = memory_read("uintptr", part.Address + offsets.base_part.primitive)
    if prim == 0 then return end
    write_fvector3(prim, offsets.primitive.velocity, Vector3.new(0, 0, 0))
end
