AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')
util.AddNetworkString("BusValidator_UpdateOwner")

function ENT:Initialize()
    self:SetModel('models/gemp/bus_validator/bus_validator.mdl')
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:EntIndex()

    self.textureGroup1 = "GEMP/bus_validator/Validator_Agree"
    self.textureGroup2 = "GEMP/bus_validator/Validator_Denait"
    self.sound1 = "bus_validator/Agree.mp3"
    self.sound2 = "bus_validator/Denait.mp3"
    self.originalMaterial = self:GetMaterial() or ""
    self.isProcessing = false
    self.showTime = false
    self.timeEnd = 0

end

function ENT:Use(activator, caller)
    if self.isProcessing then return end
    
    local firstRoll = math.random(1, 3)
    
    if firstRoll == 3 then
        self.isProcessing = true
        self.showTime = true
        self.timeEnd = CurTime() + 6
        
        local secondRoll = math.random(1, 4)
        
        if secondRoll == 1 or secondRoll == 2 then
            self:SetMaterial(self.textureGroup1)
            self:EmitSound(self.sound1)
        elseif secondRoll == 3 or secondRoll == 4 then
            self:SetMaterial(self.textureGroup2)
            self:EmitSound(self.sound2)
        end
        
        timer.Create("ValidatorReset_"..self:EntIndex(), 6, 1, function()
            if IsValid(self) then
                self:SetMaterial(self.originalMaterial)
                self.isProcessing = false
                self.showTime = false
            end
        end)
    end
end

function ENT:OnRemove()
    timer.Remove("ValidatorReset_"..self:EntIndex())
end
