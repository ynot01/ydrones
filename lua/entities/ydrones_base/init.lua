AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "ydrones_sv_init.lua" )
include( "shared.lua" )

util.AddNetworkString("yDrones:Attack")
net.Receive("yDrones:Attack", function(len, ply)
    local attacking = net.ReadBool()
    ply.drone_attacking = attacking
end)

-- ENT.remote = NULL
-- self:GetNWEntity("remote", NULL)
ENT.pilot = NULL
ENT.flygesture = nil
ENT.DroneHumSound = nil
function ENT:Initialize()
    self:SetModel( self.DroneModel )
    self:RefreshUpgrades()
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType( SIMPLE_USE )

    local phys = self:GetPhysicsObject()
    
    if phys:IsValid() then
        phys:Wake()
        phys:SetMass(self.BaseWeight)
        -- phys:SetDamping(1,1)
    end
    self.flygesture = self:AddGestureSequence( self:LookupSequence( "Fly" ), false )
    self:SetLayerLooping( self.flygesture, true )

    local filter = RecipientFilter()
    filter:AddAllPlayers()
    self.DroneHumSound = CreateSound(self, self.DroneHumSoundFile, filter)
    self.DroneHumSound:Play()
    self.DroneHumSound:ChangeVolume(0)
    self.DroneHumSound:SetSoundLevel(self.DroneHumSNDLVL)
    self.DroneHumSound:ChangePitch(math.Clamp(self.DroneHumPitchMult * 50, 0, 255))
    self:SetMaxHealth(self.DroneHealth)
    self:SetHealth(self.DroneHealth)
    -- self:MakePilot(Player(2))
end

ENT.flying = false
ENT.last_switched = -99
ENT.previous_rate = 0
function ENT:ToggleEngine()
    self.previous_rate = self:GetLayerPlaybackRate(self.flygesture)
    self.last_switched = CurTime()
    self.flying = !self.flying
end

function ENT:Use( activator, caller )
    for k,v in ipairs(ents.FindInSphere(self:GetPos(), 128)) do
        if v == self then continue end
        v:Use(activator, caller)
    end
end

function ENT:RefreshUpgrades()
    self:SetSkin( self.DroneSkin )
    for k,bodygroup in ipairs(self:GetBodyGroups()) do
        self:SetBodygroup(bodygroup.id, 0)
    end
    if self.HasGun then
        if self.GunDamage > 0 then
            self:SetBodygroup(1, 1)
        else
            self:SetBodygroup(2, 1)
        end
    end
end

local vec_zero = Vector(0,0,0)
-- local ang_zero = Angle(0,0,0)
local default_playerview_offset = Vector(0,0,64)
local default_playerview_offset_ducked = Vector(0,0,28)

hook.Add("PlayerDeath", "yDrones:Death", function(victim, inflictor, attacker)
    for k,v in ents.Iterator() do
        if v:GetNWEntity("pilot", NULL) != victim then continue end
        local drone = v
        drone:RemovePilot(victim)
    end
end)

ENT.current_rope = nil
ENT.last_shot = -999
function ENT:Think()
    if !IsValid(self:GetNWEntity("remote", NULL)) then
        self:SetNWEntity("remote", NULL)
        self:SetNWBool("synced", false)
    end
    if self:WaterLevel() >= 2 and !self.Waterproof then
        local dmginfo = DamageInfo()
        dmginfo:SetDamage( 1 )
        dmginfo:SetAttacker( game.GetWorld() )
        dmginfo:SetInflictor( game.GetWorld() )
        dmginfo:SetDamageType( DMG_CRUSH )
        self:TakeDamageInfo( dmginfo )
    end
    local ply = self:GetNWEntity("pilot", NULL)
    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        if IsValid(ply) then
            if ply:FlashlightIsOn() then
                self:SetNWBool("lighton", !self:GetNWBool("lighton", false))
                ply:Flashlight(false)
            end
            ply:SetPos(self:GetPos())
            if ply.drone_attacking and self.last_shot < CurTime() - self.GunCooldown then
                self.last_shot = CurTime()
                if self.HasGun then
                    phys:AddVelocity(ply:GetAimVector() * -5 * self.GunRecoil)
                    if self.GunDamage == 0 then
                        self:EmitSound("ambient/office/zap1.wav", 65, 100, 1, CHAN_WEAPON)
                        self:FireBullets({
                            Attacker = ply,
                            Inflictor = self,
                            Callback = function(attacker, tr, dmginfo)
                                tr.Entity:EmitSound("ambient/office/zap1.wav", 65, 100)
                                if tr.Hit and tr.Entity and tr.Entity:IsPlayer() then
                                    local oldrunspeed = tr.Entity:GetRunSpeed()
                                    local oldwalkspeed = tr.Entity:GetWalkSpeed()
                                    local oldslowwalkspeed = tr.Entity:GetSlowWalkSpeed()
                                    tr.Entity:SetRunSpeed(50)
                                    tr.Entity:SetWalkSpeed(50)
                                    tr.Entity:SetSlowWalkSpeed(50)
                                    timer.Simple(self.GunCooldown * 0.4, function()
                                        if !IsValid(tr.Entity) then return end
                                        tr.Entity:SetRunSpeed(oldrunspeed)
                                        tr.Entity:SetWalkSpeed(oldwalkspeed)
                                        tr.Entity:SetSlowWalkSpeed(oldslowwalkspeed)
                                    end)
                                end
                                return true, false
                            end,
                            Src = ply:EyePos() + ply:GetAimVector() * 5,
                            Dir = ply:GetAimVector(),
                            IgnoreEntity = self
                        })
                    elseif self.GunDamage > 0 then
                        self:EmitSound("weapons/m249/m249-1.wav", 80, 100, 1, CHAN_WEAPON)
                        self:FireBullets({
                            Attacker = ply,
                            Inflictor = self,
                            Damage = self.GunDamage,
                            Src = ply:EyePos() + ply:GetAimVector() * 5,
                            Dir = ply:GetAimVector(),
                            IgnoreEntity = self
                        })
                    else
                        self:EmitSound("items/gift_drop.wav", 75, 100, 1, CHAN_WEAPON)
                        self:FireBullets({
                            Attacker = ply,
                            Inflictor = self,
                            Callback = function(attacker, tr, dmginfo)
                                if tr.Hit and tr.Entity then
                                    tr.Entity:SetHealth(math.Clamp(tr.Entity:Health() - self.GunDamage, 0, tr.Entity:GetMaxHealth()))
                                end
                                return false, false
                            end,
                            Src = ply:EyePos() + ply:GetAimVector() * 5,
                            Dir = ply:GetAimVector(),
                            IgnoreEntity = self
                        })
                    end
                else
                    if IsValid(self.current_rope) then
                        self:EmitSound("phx/epicmetal_soft5.wav", 70, 100, 1, CHAN_WEAPON)
                        self.current_rope:Remove()
                    else
                        self:EmitSound("phx/epicmetal_soft7.wav", 70, 100, 1, CHAN_WEAPON)
                        self:FireBullets({
                            Attacker = ply,
                            Inflictor = self,
                            Damage = 0,
                            Callback = function(attacker, tr, dmginfo)
                                if tr.Hit and tr.Entity and (tr.HitPos - self:GetPos()):LengthSqr() < 2500 then
                                    self.current_rope = constraint.Rope(self, tr.Entity, 0, 0, vec_zero, tr.HitPos - tr.Entity:GetPos(), 50, 0, 5000, 1, nil, true)
                                end
                                return false, false
                            end,
                            Src = ply:EyePos() + ply:GetAimVector() * 5,
                            Dir = ply:GetAimVector(),
                            IgnoreEntity = self
                        })
                    end
                end
            end
        end
        local vel = phys:GetVelocity()
        local vel_ang = phys:GetAngleVelocity()
        -- local ang = phys:GetAngles()
        if self.flying then
            -- if vel:LengthSqr() < 1000 then
            --     self:SetVelocity(vec_zero)
            -- end
            if !IsValid(ply) then
                local oldang = phys:GetAngles()
                phys:SetAngles(Angle(0,oldang.y,0))
            end
            phys:EnableGravity(false)
            phys:SetAngleVelocity(vel_ang * 0.95)
            self.DroneHumSound:ChangePitch(math.Clamp(self.DroneHumPitchMult * (100 + (vel:Length() * 0.1)), 0, 255), 0.35)
            self.DroneHumSound:ChangeVolume(self.DroneHumVolume, 0.2)
            self:SetLayerPlaybackRate(self.flygesture, math.min(self.previous_rate + ((CurTime() - self.last_switched) * 5), 5))
            -- print(phys:GetFrictionSnapshot().ContactPoint)
            if IsValid(ply) and ply.LastMove and ply.LastMove:LengthSqr() > 0 then
                phys:AddVelocity(ply.LastMove * self.BaseSpeed)
            else
                phys:SetVelocity(vel * 0.95)
            end
        else
            phys:EnableGravity(true)
            self.DroneHumSound:ChangeVolume(0, 1)
            self.DroneHumSound:ChangePitch(math.Clamp(self.DroneHumPitchMult * 50, 0, 255), 1)
            self:SetLayerPlaybackRate(self.flygesture, math.max((self.last_switched - CurTime()) + self.previous_rate, 0))
        end
    end
    self:NextThink(CurTime())

    return true
end

ENT.pilot_pos = Vector(0,0,0)
ENT.pilot_ang = Angle(0,0,0)
ENT.fakeplayer = NULL
function ENT:MakePilot(ply)
    self.fakeplayer = ents.Create("ydrones_fakeplayer")
    self.fakeplayer:Spawn()
    self.fakeplayer:SetPos(ply:GetPos())
    self.fakeplayer:SetRealPlayer(ply, self)
    self:SetNWEntity("pilot", ply)
    self.pilot_pos = ply:GetPos()
    self.pilot_ang = ply:GetAngles()
    ply:GodEnable()
    ply:SetViewOffset(vec_zero)
    ply:SetViewOffsetDucked(vec_zero)
    ply:SetMoveType(MOVETYPE_NOCLIP)
    ply:SetNoDraw(true)
    ply:SetModelScale(0.001, 0.00001)
    ply.piloting_drone = self
end

function ENT:RemovePilot(ply)
    if !IsValid(ply) then
        ply = self:GetNWEntity("pilot", NULL)
    end
    ply.piloting_drone = nil
    self:SetNWEntity("pilot", NULL)
    if IsValid(self.fakeplayer) then
        self.fakeplayer:Remove()
    end
    self:SetAngles(Angle(0,ply:EyeAngles().y,0))
    ply:SetPos(self.pilot_pos)
    ply:SetEyeAngles(self.pilot_ang)
    ply:SetViewOffset(default_playerview_offset)
    ply:SetViewOffsetDucked(default_playerview_offset_ducked)
    ply:SetMoveType(MOVETYPE_WALK)
    ply:SetNoDraw(false)
    ply:SetModelScale(1, 0.00001)
    ply:GodDisable()
    ply.drone_exit_stun = true
end

function ENT:OnRemove()
    self.DroneHumSound:Stop()
    if IsValid(self:GetNWEntity("pilot", NULL)) then
        self:RemovePilot(self:GetNWEntity("pilot", NULL))
    end
    if IsValid(self:GetNWEntity("remote", NULL)) then
        self:GetNWEntity("remote", NULL):SetNWBool("synced", false)
        self:GetNWEntity("remote", NULL):SetNWEntity("drone", NULL)
    end
end

ENT.dying = false
function ENT:OnTakeDamage(dmginfo)
    if self.dying then return end
    self:SetHealth(self:Health() - dmginfo:GetDamage())
    local phys = self:GetPhysicsObject()
    if phys:IsValid() and dmginfo:GetDamageType() != DMG_CRUSH then
        phys:ApplyForceOffset(dmginfo:GetDamageForce(), dmginfo:GetDamagePosition())
    end
    self:EmitSound("weapons/knife/knife_hitwall1.wav")
    if self:Health() <= 0 then
        self.dying = true
        local explode = ents.Create( "env_explosion" )
        explode:SetPos( self:GetPos() )
        if IsValid(self.pilot) then
            explode:SetOwner( self.pilot )
        end
        explode:Spawn()
        explode:SetKeyValue( "iMagnitude", "0" )
        explode:Fire( "Explode", 0, 0 )
        self:Remove()
    end
end

local BounceSound = Sound( "physics/metal/metal_box_impact_hard1.wav" )
function ENT:PhysicsCollide( data, physobj )
    -- Play sound on bounce
    if data.Speed > 250 and data.DeltaTime > 0.2 then
        if true then
            self.dying = true
            local explode = ents.Create( "env_explosion" )
            explode:SetPos( self:GetPos() )
            if IsValid(self.pilot) then
                explode:SetOwner( self.pilot )
            end
            explode:Spawn()
            explode:SetKeyValue( "iMagnitude", "100" )
            explode:Fire( "Explode", 0, 0 )
            self:Remove()
        end
        sound.Play( BounceSound, self:GetPos(), 75, math.random( 90, 110 ), math.Clamp( data.Speed / 1500, 0, 1 ) )
        local dmginfo = DamageInfo()
        dmginfo:SetDamage( data.Speed * 0.02 )
        dmginfo:SetAttacker( data.HitEntity )
        dmginfo:SetInflictor( data.HitEntity )
        dmginfo:SetDamageType( DMG_CRUSH )
        self:TakeDamageInfo( dmginfo )
    end
end