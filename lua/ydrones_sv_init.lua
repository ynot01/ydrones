resource.AddFile("sound/ydrones/drone_loop.wav")
resource.AddFile("materials/entities/ydrones_black.png")
resource.AddFile("materials/entities/ydrones_white.png")
resource.AddFile("materials/entities/ydrones_medic.png")
resource.AddFile("materials/entities/ydrones_police.png")
resource.AddFile("materials/entities/ydrones_delivery.png")
resource.AddFile("materials/entities/ydrones_gold.png")
resource.AddFile("materials/entities/ydrones_spy.png")
resource.AddFile("materials/entities/ydrones_military.png")
resource.AddFile("materials/entities/ydrones_bomber.png")
resource.AddWorkshop("1991832497")

local vec_zero = Vector(0,0,0)
local duck_vel = Vector(0,0,-1)
hook.Add( "FinishMove", "yDrones:Move", function( ply, mv )
    ply.LastMove = mv:GetVelocity():GetNormalized()
    if ply:KeyDown(IN_DUCK) then
        ply.LastMove = ply.LastMove + duck_vel
    end
    if ply.drone_exit_stun then
        mv:SetVelocity(vec_zero)
        ply.drone_exit_stun = false
    end
    if !IsValid(ply.piloting_drone) or ply.piloting_drone:IsDormant() then return end
    return true
end )

print("[yDrones] Loaded!")