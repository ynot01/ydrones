include( "shared.lua" )

local black = Color(0,0,0)
local black_faded = Color(0,0,0,200)
local white = Color(255,255,255)
local white_faded = Color(255,255,255,128)
local bad = Color(255,160,160)
local good = Color(100,255,100)
ENT.recording_light = Color(0,0,0)
-- local drone_cursor_outline = Color(0,0,0,0)
-- local drone_cursor_inside = Color(72,255,0,0)

surface.CreateFont( "yDrones:FontLarge", {
    font = "Roboto",
    weight = 1000,
    size = ScreenScale(24)
} )
surface.CreateFont( "yDrones:FontNormal", {
    font = "Roboto",
    size = ScreenScale(16)
} )
surface.CreateFont( "yDrones:FontSmall", {
    font = "Roboto",
    size = ScreenScale(12)
} )
surface.CreateFont( "yDrones:FontTiny", {
    font = "Roboto",
    size = ScreenScale(8)
} )
surface.CreateFont( "yDrones:Font3D", {
    font = "Roboto",
    size = 24
} )

local attacking = false
local my_drone = NULL
-- local screenpos_lookpos = nil
hook.Add("CalcView", "yDrones:CalcView", function(ply, pos, angles, fov)
    for k,v in ents.Iterator() do
        if v:GetNWEntity("pilot", NULL) != LocalPlayer() then continue end
        local drone = v
        if drone:IsDormant() then continue end
        my_drone = drone
        -- screenpos_lookpos = (LocalPlayer():EyeAngles():Forward() + EyePos()):ToScreen()
        local dr_ang = LocalPlayer():EyeAngles()
        local tr = util.TraceLine({
            start = drone:GetPos() + drone:OBBCenter(),
            endpos = drone:GetPos() + (dr_ang:Up() * 1) + (dr_ang:Forward() * 7.9) + (dr_ang:Right() * -3.006),
            mask = MASK_ALL,
            filter = {drone, ply},
            hitclientonly = true
        })
        local view = {
            origin = tr.Hit and (tr.HitPos - ((tr.HitPos - tr.StartPos) * 0.0265)) or tr.HitPos,
            angles = dr_ang,
            fov = 100,
            drawviewer = true,
            znear = 0.1
        }
        local remote = LocalPlayer():GetWeapon("weapon_ydrones_remote")
        if IsValid(remote) then
            input.SelectWeapon(remote)
        end

        return view
    end
    my_drone = NULL
end)

-- local centerscreen_coords = Vector(0,0,0)
-- local drone_cursor_coords = Vector(0,0,0)
hook.Add("HUDPaint", "yDrones:DroneHUD", function()
    if !IsValid(LocalPlayer()) then return end
    if !IsValid(my_drone) or my_drone:IsDormant() then
        -- stuff here runs when not in a drone
        return
    end
    draw.NoTexture()
    surface.SetDrawColor(255,255,255,128)
    white_faded.a = (math.sin(CurTime()) * 128 + 128) * 0.5
    draw.SimpleText(string.upper(my_drone.PrintName), "yDrones:FontLarge", ScrW() * 0.5, ScrH() * 0.1, white_faded, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    surface.DrawRect(ScreenScale(20), ScreenScale(20), ScreenScale(20), ScreenScale(100))
    surface.DrawRect(ScreenScale(40), ScreenScale(20), ScreenScale(80), ScreenScale(20))
    surface.DrawRect(ScrW() - ScreenScale(40), ScreenScale(20), ScreenScale(20), ScreenScale(100))
    surface.DrawRect(ScrW() - ScreenScale(120), ScreenScale(20), ScreenScale(80), ScreenScale(20))
    surface.DrawRect(ScreenScale(20), ScrH() - ScreenScale(120), ScreenScale(20), ScreenScale(100))
    surface.DrawRect(ScreenScale(40), ScrH() - ScreenScale(40), ScreenScale(80), ScreenScale(20))
    surface.DrawRect(ScrW() - ScreenScale(40), ScrH() - ScreenScale(120), ScreenScale(20), ScreenScale(100))
    surface.DrawRect(ScrW() - ScreenScale(120), ScrH() - ScreenScale(40), ScreenScale(80), ScreenScale(20))
    draw.RoundedBox(4, ScrW() * 0.5 - ScreenScale(150), ScreenScale(250), ScreenScale(300), ScreenScale(66), black_faded)
    draw.SimpleTextOutlined("Integrity: " .. tostring(my_drone:Health()) .. "/" .. tostring(my_drone:GetMaxHealth()), "yDrones:FontSmall", ScrW() * 0.5, ScrH() * 0.75, white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, black)
    draw.SimpleTextOutlined("Click to " .. (my_drone.HasGun and "shoot" or "attach a nearby item"), "yDrones:FontSmall", ScrW() * 0.5, ScrH() * 0.8, white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, black)
    draw.SimpleTextOutlined("Right click to stop piloting", "yDrones:FontSmall", ScrW() * 0.5, ScrH() * 0.85, white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, black)
    draw.SimpleTextOutlined("Reload to toggle engine", "yDrones:FontSmall", ScrW() * 0.5, ScrH() * 0.9, white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, black)

    -- if !istable(screenpos_lookpos) then return end
    -- if !screenpos_lookpos.visible then return end
    -- centerscreen_coords[1] = ScrW() * 0.5
    -- centerscreen_coords[2] = ScrH() * 0.5
    -- drone_cursor_coords[1] = screenpos_lookpos.x
    -- drone_cursor_coords[2] = screenpos_lookpos.y
    -- drone_cursor_outline.a = centerscreen_coords:Distance2DSqr(drone_cursor_coords) * 0.01
    -- drone_cursor_inside.a = centerscreen_coords:Distance2DSqr(drone_cursor_coords) * 0.01
    -- draw.SimpleTextOutlined("•", "yDrones:FontNormal", screenpos_lookpos.x, screenpos_lookpos.y, drone_cursor_inside, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, drone_cursor_outline)
end)

hook.Add("CreateMove", "yDrones:CreateMove", function(cmd)
    if !IsValid(my_drone) or my_drone:IsDormant() then
        attacking = false
        return
    end
    if cmd:KeyDown(IN_ATTACK) then
        cmd:RemoveKey(IN_ATTACK)
        attacking = true
    else
        attacking = false
    end
end)

local last_attacking = false
hook.Add("Think", "yDrones:SendAttack", function()
    if last_attacking != attacking then
        last_attacking = attacking
        net.Start("yDrones:Attack")
            net.WriteBool(attacking)
        net.SendToServer()
    end
end)

function ENT:Initialize()
end

function ENT:Think()
end

ENT.fakeang = Angle(0,0,0)
function ENT:Draw()

    self:DrawModel()

    if self:GetNWBool("lighton", false) then
        local dlight = DynamicLight( self:EntIndex() )
        if ( dlight ) then
            dlight.pos = self:GetPos()
            dlight.r = 255
            dlight.g = 255
            dlight.b = 255
            dlight.brightness = 2
            dlight.decay = 1000
            dlight.size = 256
            dlight.dietime = CurTime() + 0.1
        end
    end

    
    local blink_val = math.Round(math.abs(math.sin(CurTime() * 3)))
    local ply = self:GetNWEntity("pilot", NULL)
    if IsValid(ply) then
        self.fakeang.y = ply:EyeAngles().y
        self:SetRenderAngles(self.fakeang)
        self.recording_light.r = blink_val * 100
        self.recording_light.g = blink_val * 255
        self.recording_light.b = blink_val * 100
    else
        self:SetRenderAngles(nil)
        self.recording_light.r = blink_val * 100
        self.recording_light.g = blink_val * 100
        self.recording_light.b = blink_val * 255
    end
    
    if self:GetSkin() == 6 then return end

    -- Right set of lights
    local ang = self:GetAngles()
    ang:RotateAroundAxis( ang:Up(), 80 )
    ang:RotateAroundAxis( ang:Right(), 0 )
    ang:RotateAroundAxis( ang:Forward(), 90 )
    local pos = self:GetPos()
    pos = pos + ang:Forward() * 2.35 -- right
    pos = pos + ang:Up() * 6.75 -- forward
    pos = pos + ang:Right() * -1.885 -- down
    cam.Start3D2D(pos, ang, 0.1)
        draw.RoundedBox(1,0,0,4,2,self.recording_light)
        if self:GetNWBool("lighton", false) then
            draw.RoundedBox(1,4,0,4,2,white)
        end
    cam.End3D2D()

    -- Left set of lights
    ang = self:GetAngles()
    ang:RotateAroundAxis( ang:Up(), 103 )
    ang:RotateAroundAxis( ang:Right(), 0 )
    ang:RotateAroundAxis( ang:Forward(), 90 )
    pos = self:GetPos()
    pos = pos + ang:Forward() * 2.4 -- right
    pos = pos + ang:Up() * 7.95 -- forward
    pos = pos + ang:Right() * -1.885 -- down
    cam.Start3D2D(pos, ang, 0.1)
        if self:GetNWBool("lighton", false) then
            draw.RoundedBox(1,0,0,4,2,white)
        end
        draw.RoundedBox(1,4,0,4,2,self.recording_light)
    cam.End3D2D()

    -- Top HP display
    ang = self:GetAngles()
    ang:RotateAroundAxis( ang:Up(), 90 )
    ang:RotateAroundAxis( ang:Right(), 0 )
    ang:RotateAroundAxis( ang:Forward(), 0 )
    pos = self:GetPos()
    pos = pos + ang:Forward() * 3 -- right
    pos = pos + ang:Up() * 4.55 -- up
    pos = pos + ang:Right() * -1 -- forward
    cam.Start3D2D(pos, ang, 0.05)
        -- draw.RoundedBox(4,-60,-40,120,80,black_faded)
        draw.SimpleTextOutlined("HP: " .. tostring(math.Round(self:Health() / self:GetMaxHealth() * 100)) .. "%", "yDrones:Font3D", 0, -20, white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, black)
        draw.SimpleTextOutlined(self:GetNWBool("synced", false) and "Synced" or "Unsynced", "yDrones:Font3D", 0, 20, self:GetNWBool("synced", false) and good or bad, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, black)
    cam.End3D2D()

    if !util.IsValidModel(self.DroneModel) then
        ang = EyeAngles()
        ang:RotateAroundAxis( ang:Up(), 90 )
        ang:RotateAroundAxis( ang:Right(), 180 )
        ang:RotateAroundAxis( ang:Forward(), 270 )
        pos = self:GetPos()
        pos.z = pos.z + 100
        cam.Start3D2D(pos, ang, 0.3)
            draw.SimpleTextOutlined("Drone model missing/invalid: " .. tostring(self.DroneModel), "yDrones:Font3D", 0, 0, white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, black)
        cam.End3D2D()
    end
end