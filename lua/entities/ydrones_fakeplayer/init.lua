AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

ENT.RealPlayer = NULL
ENT.RealDrone = NULL
function ENT:Initialize()
    self:SetModel( "models/Characters/hostage_04.mdl" ) -- Sets the model of the NPC.
    self:SetHullType( HULL_HUMAN ) -- Sets the hull type, used for movement calculations amongst other things.
    self:SetHullSizeNormal( )
    self:SetNPCState( NPC_STATE_SCRIPT )
    self:SetSolid( SOLID_BBOX ) -- This entity uses a solid bounding box for collisions.
    self:SetCollisionGroup(COLLISION_GROUP_NPC)
    self:CapabilitiesAdd( 8392704 ) -- CAP_ANIMATEDFACE | CAP_TURN_HEAD , 8388608 + 4096 = 8392704
    -- self:SetUseType( SIMPLE_USE ) -- Makes the ENT.Use hook only get called once at every use.
    -- self:Give("keys")
    self:DropToFloor()
    self:SetMaxHealth(9999999)
    self:SetHealth(9999999)
    self:ResetSequence(self:LookupSequence("idle_camera"))
end

function ENT:SetRealPlayer(ply, drone)
    self:SetModel(ply:GetModel())
    self:SetAngles(Angle(0, ply:GetAngles().y, 0))
    self:SetHullType( HULL_HUMAN ) -- Sets the hull type, used for movement calculations amongst other things.
    self:SetHullSizeNormal( )
    self:SetNPCState( NPC_STATE_SCRIPT )
    self:SetSolid( SOLID_BBOX ) -- This entity uses a solid bounding box for collisions.
    self:SetCollisionGroup(COLLISION_GROUP_NPC_ACTOR)
    self:CapabilitiesAdd( 8392704 ) -- CAP_ANIMATEDFACE | CAP_TURN_HEAD , 8388608 + 4096 = 8392704
    self:SetSkin(ply:GetSkin())
    self:SetNWString("playername", ply:Nick())
    self.RealPlayer = ply
    self.RealDrone = drone
    self:ResetSequence(self:LookupSequence("idle_camera"))
end

function ENT:OnTakeDamage(dmginfo)
    if self.dying then return end
    self.dying = true
    if IsValid(self.RealPlayer) and IsValid(self.RealDrone) then
        self.RealDrone:RemovePilot(self.RealPlayer)
        self.RealPlayer:TakeDamageInfo(dmginfo)
    end
    self:Remove()
end
