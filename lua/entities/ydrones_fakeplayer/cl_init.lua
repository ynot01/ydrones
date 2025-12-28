include( "shared.lua" )

local black = Color(0,0,0)
local white = Color(255,255,255)
function ENT:Initialize()
    self.headset = ClientsideModel("models/Items/battery.mdl")
    self.headset:Spawn()
end
function ENT:Draw()

    if self:IsDormant() then return end

    self:DrawModel()

    local boneid = self:LookupBone("ValveBiped.Bip01_Head1")
    if boneid then
        local matrix = self:GetBoneMatrix(boneid)
        local pos = matrix:GetTranslation()
        local ang = matrix:GetAngles()
        ang:RotateAroundAxis( ang:Up(),270 )
        ang:RotateAroundAxis( ang:Right(), 0 )
        ang:RotateAroundAxis( ang:Forward(), 0 )
        pos = pos + ang:Forward() * 5 -- forward
        pos = pos + ang:Up() * -4.5 -- left
        pos = pos + ang:Right() * -4 -- down
        self.headset:SetPos(pos)
        self.headset:SetAngles(ang)
    else
        local pos = self:EyePos()
        local ang = self:EyeAngles()
        ang:RotateAroundAxis( ang:Up(), 0 )
        ang:RotateAroundAxis( ang:Right(), 0 )
        ang:RotateAroundAxis( ang:Forward(), 90 )
        pos = pos + ang:Forward() * 5 -- forward
        pos = pos + ang:Up() * -4.5 -- left
        pos = pos + ang:Right() * 4 -- down
        self.headset:SetPos(pos)
        self.headset:SetAngles(ang)
    end

    local ang = Angle()
    ang:RotateAroundAxis( ang:Up(), EyeAngles().y + 270 )
    ang:RotateAroundAxis( ang:Right(), 0 )
    ang:RotateAroundAxis( ang:Forward(), 90 )
    local pos = self:GetPos()
    pos.z = pos.z + 80 + math.sin(CurTime())
    cam.Start3D2D(pos, ang, 0.1)
        draw.SimpleTextOutlined(self:GetNWString("playername", "NULL"), "yDrones:Font3D", 0, -20, white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, black)
        draw.SimpleTextOutlined("Controlling a drone...", "yDrones:Font3D", 0, 20, white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, black)
    cam.End3D2D()

end

function ENT:OnRemove()
    self.headset:Remove()
end