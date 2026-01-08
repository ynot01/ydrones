AddCSLuaFile()

SWEP.PrintName = "Drone Remote"
SWEP.Author = "ynot01"
SWEP.Instructions = "Primary fire at an unsynced drone to sync to it. Secondary fire to control a synced drone. Reload to toggle a synced drone's engine."

SWEP.Category = "ynot01's Drones"

SWEP.Slot = 0
SWEP.SlotPos = 0

SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.ViewModel = "models/anthon/c_drone_controller.mdl"
SWEP.WorldModel = "models/anthon/w_drone_controller.mdl"
SWEP.ViewModelFOV = 70
SWEP.UseHands = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.DrawAmmo = false

--[[
surface.CreateFont( "yDrones:FontLarge", {
    font = "Roboto",
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
]]

-- self:GetNWBool("synced", false)
local white = Color(255,255,255)
local black = Color(0,0,0,200)
SWEP.my_drone = NULL
function SWEP:DrawHUD()
    if IsValid(self.my_drone) and self.my_drone:GetNWEntity("pilot", NULL) == LocalPlayer() then
        return
    end
    draw.RoundedBox(4, ScrW() * 0.5 - ScreenScale(100), ScreenScale(250), ScreenScale(200), ScreenScale(50), black)
    if !self:GetNWBool("synced", false) then
        draw.SimpleTextOutlined("Drone not connected", "yDrones:FontSmall", ScrW() * 0.5, ScreenScale(266.6666), white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, black)
        draw.SimpleTextOutlined("Click on a drone to sync or unsync", "yDrones:FontSmall", ScrW() * 0.5, ScreenScale(283.3333), white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, black)
        return
    end
    if !IsValid(self.my_drone) then
        draw.SimpleTextOutlined("Drone out of range", "yDrones:FontSmall", ScrW() * 0.5, ScreenScale(275), white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, black)
    else
        draw.SimpleTextOutlined(self.my_drone.PrintName, "yDrones:FontSmall", ScrW() * 0.5, ScreenScale(266.6666), white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, black)
        draw.SimpleTextOutlined("Integrity: " .. tostring(math.Round(100 * self.my_drone:Health() / self.my_drone:GetMaxHealth())) .. "%", "yDrones:FontSmall", ScrW() * 0.5, ScreenScale(283.3333), white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, black)
    end
    draw.SimpleTextOutlined("Right click to pilot, reload to toggle engine", "yDrones:FontTiny", ScrW() * 0.5, ScreenScale(295), white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, black)
    local drone_ent = self:GetNWEntity("drone", NULL)
    for k,v in ents.Iterator() do
        if drone_ent != v then continue end
        local drone = v
        if drone:IsDormant() then continue end
        self.my_drone = drone
        return
    end
    self.my_drone = NULL
end

function SWEP:Equip()
    self:SetHoldType("pistol")
end

function SWEP:Deploy()
end

function SWEP:PrimaryAttack()
    if CLIENT then return end

    if self:GetNWBool("synced", false) and IsValid(self:GetNWEntity("drone", NULL)) then
        local drone = self:GetNWEntity("drone", NULL)
        drone:SetNWEntity("synced", false)
        drone:SetNWEntity("remote", NULL)
        self:SetNWBool("synced", false)
        self:SetNWEntity("drone", NULL)
    end

    local ply = self:GetOwner()
    ply:LagCompensation(true)
    local tr = util.TraceLine( {
        start = ply:GetShootPos(),
        endpos = ply:GetShootPos() + ply:GetAimVector() * 500,
        filter = ply
    } )
    ply:LagCompensation(false)

    local drone = tr.Entity
    if IsValid(drone) and drone.DroneModel and (!IsValid(drone:GetNWEntity("remote", NULL)) or drone:GetNWEntity("remote", NULL) == self) then
        drone:SetNWEntity("synced", true)
        drone:SetNWEntity("remote", self)
        self:SetNWBool("synced", true)
        self:SetNWEntity("drone", drone)
    end
end

function SWEP:SecondaryAttack()
    if CLIENT then return end
    local drone = self:GetNWEntity("drone", NULL)
    if !IsValid(drone) then return end
    if IsValid(drone:GetNWEntity("pilot", NULL)) and drone:GetNWEntity("pilot", NULL) != self:GetOwner() then -- how did we get here
        drone:RemovePilot(drone:GetNWEntity("pilot", NULL))
    end
    if IsValid(drone:GetNWEntity("pilot", NULL)) then
        drone:RemovePilot(drone:GetNWEntity("pilot", NULL))
    else
        drone:MakePilot(self:GetOwner())
    end
end

SWEP.last_reload = -999
function SWEP:Reload()
    if CLIENT then return end
    local drone = self:GetNWEntity("drone", NULL)
    if !IsValid(drone) then return end
    if self.last_reload > CurTime() - 1 then return end
    self.last_reload = CurTime()
    drone:ToggleEngine()
end
