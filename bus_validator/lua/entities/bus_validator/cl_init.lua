include('shared.lua')

surface.CreateFont("ValidatorTimeFont", {
    font = "Arial",
    size = 30,
    weight = 40,
    antialias = true,
    additive = false
})


function ENT:GetCurrentTime()
    return os.date("%H:%M") -- Формат ЧЧ:ММ
end

function ENT:Draw()
    self:DrawModel()

    local pos = self:GetPos() + self:GetUp() * 1.65 + self:GetForward() * 3.4 + self:GetRight() * - 0.68
    local ang = self:GetAngles()
    ang:RotateAroundAxis(self:GetUp(), 0)
    ang:RotateAroundAxis(self:GetRight(), -90)
    ang:RotateAroundAxis(self:GetForward(), 90)
    
    cam.Start3D2D(pos, ang, 0.0033)
        draw.SimpleText( " Автобус №10  |  " .. self:GetCurrentTime(), "ValidatorTimeFont", 0, 0, Color(255, 255, 255, 59), TEXT_ALIGN_RIGHT, TEXT_ALIGN_RIGHT)
    cam.End3D2D()
end
