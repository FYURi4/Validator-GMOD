TOOL.Category = "Инструменты Валидатора"
TOOL.Name = "#tool.validator_tool.name"
TOOL.Command = nil
TOOL.ConfigName = ""
TOOL.ManualPlacement = TOOL.ManualPlacement or {}

-- Регистрируем сетевые сообщения
if SERVER then
    util.AddNetworkString("Validator_ShowChoiceMenu")
    util.AddNetworkString("Validator_OpenEditor")
    util.AddNetworkString("Validator_RemoveAll")
    util.AddNetworkString("Validator_StartManualPlacement")
    util.AddNetworkString("Validator_SpawnManualValidator")
    util.AddNetworkString("Validator_RequestUseTemplate")
end

-- Шаблоны для транспорта
local ValidatorTemplates = {
    ["trolleybus_ent_ziu6205"] = {
        name = "Шаблон для ZiU 6205",
        terminals = {
            {pos = Vector(17.6, -18, 25), ang = Angle(0, 60, 0)},
            {pos = Vector(130.5, -21, 25), ang = Angle(0, 120, 0)},
        }
    },
    ["prop_vehicle_airboat"] = {
        name = "Шаблон для аэробота",
        terminals = {
            {pos = Vector(200, 0, 10), ang  = Angle(0, 90, 0)},
        }
    }
}

-- Разрешённые классы
local AllowedVehicleClasses = {
    ["trolleybus_ent_ziu6205"] = true,
    ["trolleybus_ent_ziu682v013"] = true,
    ["trolleybus_ent_aksm321"] = true,
    ["trolleybus_ent_aksm321n"] = true,
    ["trolleybus_ent_aksm333"] = true,
    ["trolleybus_ent_aksm333o"] = true,
    ["trolleybus_ent_aksm333o_msk"] = true,
    ["trolleybus_ent_aksm101ps"] = true,
    ["trolleybus_ent_trolza5265"] = true,
}

-- ЛКМ — выбор транспорта
function TOOL:LeftClick(trace)
    local ply = self:GetOwner()
    local ent = trace.Entity

    -- Режим ручной установки
    if ply.ValidatorTarget and IsValid(ply.ValidatorTarget) then
        local parent = ply.ValidatorTarget

        if ent ~= parent then
            ply:ChatPrint("[Валидатор] Кликайте по выбранному объекту.")
            return false
        end

        local localPos = parent:WorldToLocal(trace.HitPos)
        local localAng = Angle(0, ply:EyeAngles().y - parent:GetAngles().y, 0)

        local validator = ents.Create("bus_validator")
        if not IsValid(validator) then return false end

        validator:SetPos(trace.HitPos)
        validator:SetAngles(localAng)
        validator:Spawn()
        validator:Activate()
        validator:SetParent(parent)

        ply:ChatPrint("[Валидатор] Валидатор добавлен на позицию: " .. tostring(localPos))
        return true
    end

    -- Обычный режим выбора
    local class = ent:GetClass()
    if not AllowedVehicleClasses[class] then
        ply:ChatPrint("[Ошибка] Этот транспорт не поддерживается валидатором!")
        return false
    end

    ply:ChatPrint("[Валидатор] Вы выбрали транспорт: " .. class)

    if ValidatorTemplates[class] then
        net.Start("Validator_ShowChoiceMenu")
            net.WriteEntity(ent)
            net.WriteString(class)
        net.Send(ply)
    else
        net.Start("Validator_OpenEditor")
            net.WriteEntity(ent)
        net.Send(ply)
    end

    return true
end

-- Обработка запроса на использование шаблона (от клиента)
net.Receive("Validator_RequestUseTemplate", function(len, ply)
    local ent = net.ReadEntity()
    local class = net.ReadString()

    if not IsValid(ent) then
        ply:ChatPrint("[Ошибка] Объект недоступен.")
        return
    end

    if ent.GetCreator and IsValid(ent:GetCreator()) and ent:GetCreator() ~= ply then
        ply:ChatPrint("[Ошибка] Этот объект вам не принадлежит.")
        return
    end

    if not ValidatorTemplates[class] then
        ply:ChatPrint("[Ошибка] Шаблон не найден.")
        return
    end

    -- Проверка, есть ли уже валидаторы
    local attachedValidators = {}
    for _, child in ipairs(ent:GetChildren()) do
        if IsValid(child) and child:GetClass() == "bus_validator" then
            table.insert(attachedValidators, child)
        end
    end

    if #attachedValidators > 0 then
        ply:ChatPrint("[Ошибка] На этом объекте уже установлены валидаторы (" .. #attachedValidators .. ").")
        return
    end

    local template = ValidatorTemplates[class]
    ply:ChatPrint("[Валидатор] Применён шаблон: " .. template.name)

    for _, terminal in ipairs(template.terminals or {}) do
        local worldPos = ent:LocalToWorld(terminal.pos)
        local worldAng = ent:LocalToWorldAngles(terminal.ang)

        local validator = ents.Create("bus_validator")
        if not IsValid(validator) then
            ply:ChatPrint("[Ошибка] Не удалось создать bus_validator.")
            continue
        end

        validator:SetPos(worldPos)
        validator:SetAngles(worldAng)
        validator:Spawn()
        validator:Activate()
        validator:SetParent(ent)

        ply:ChatPrint("[DEBUG] Спавнен валидатор на: " .. tostring(worldPos))
    end
end)



-- Пустой RightClick
function TOOL:RightClick(trace)
    return false
end

-- Не рисуем ничего в HUD
function TOOL:DrawHUD()
end

-- Пустой reload
function TOOL:Reload(trace)
    local ply = self:GetOwner()

    if ply.ValidatorTarget then
        ply.ValidatorTarget = nil
        ply:ChatPrint("[Валидатор] Режим ручной установки завершён.")
        return true
    end

    return false
end

-- Настройки инструмента в Q-меню
function TOOL.BuildCPanel(panel)
    panel:AddControl("Header", {
        Description = [[Используйте ЛКМ для выбора транспорта.
Если имеется готовый шаблон — он будет предложен автоматически.]]
    })
end


net.Receive("Validator_ShowChoiceMenu", function()
    local ent = net.ReadEntity()
    local class = net.ReadString()

    if not IsValid(ent) then return end

    print("[DEBUG] Открытие меню выбора для: " .. class)

    local frame = vgui.Create("DFrame")
    frame:SetTitle("Выбор действия для " .. class)
    frame:SetSize(350, 165)
    frame:Center()
    frame:MakePopup()

    local label = vgui.Create("DLabel", frame)
    label:SetText("Найден шаблон для этого транспорта.\nЧто вы хотите сделать?")
    label:SizeToContents()
    label:SetPos(15, 35)

    local btnTemplate = vgui.Create("DButton", frame)
    btnTemplate:SetText("Использовать шаблон")
    btnTemplate:SetSize(320, 25)
    btnTemplate:SetPos(15, 65)
    btnTemplate.DoClick = function()
        net.Start("Validator_RequestUseTemplate")
            net.WriteEntity(ent)
            net.WriteString(class)
        net.SendToServer()
        frame:Close()
    end

    local btnManual = vgui.Create("DButton", frame)
    btnManual:SetText("Настроить с нуля")
    btnManual:SetSize(320, 25)
    btnManual:SetPos(15, 95)
    btnManual.DoClick = function()
        net.Start("Validator_StartManualPlacement")
            net.WriteEntity(ent)
        net.SendToServer()
        frame:Close()
    end

    local btnRemove = vgui.Create("DButton", frame)
    btnRemove:SetText("Удалить все валидаторы")
    btnRemove:SetSize(320, 25)
    btnRemove:SetPos(15, 125)
    btnRemove.DoClick = function()
        net.Start("Validator_RemoveAll")
            net.WriteEntity(ent)
        net.SendToServer()
        frame:Close()
    end
    
end)

net.Receive("Validator_RemoveAll", function(len, ply)
    local ent = net.ReadEntity()
    if not IsValid(ent) then return end

    if ent.CPPIGetOwner and ent:CPPIGetOwner() ~= ply then
        ply:ChatPrint("[Ошибка] Этот объект вам не принадлежит.")
        return
    end

    local removed = 0
    for _, validator in ipairs(ents.FindByClass("bus_validator")) do
        if validator:GetParent() == ent then
            validator:Remove()
            removed = removed + 1
        end
    end

    ply:ChatPrint("[Валидатор] Удалено валидаторов: " .. removed)
end)
    
net.Receive("Validator_StartManualPlacement", function()
    local ent = net.ReadEntity()
    if not IsValid(ent) then return end

    if CLIENT then
        local ghost = ClientsideModel('models/gemp/bus_validator/bus_validator.mdl') -- Модель временного валидатора
        ghost:SetNoDraw(false)
        ghost:SetModelScale(0.75, 0)
        ghost:SetColor(Color(255, 255, 255, 150))
        ghost:SetRenderMode(RENDERMODE_TRANSALPHA)

        local pos, ang = Vector(0, 0, 0), Angle(0, 0, 0)

        local frame = vgui.Create("DFrame")
        frame:SetTitle("Ручная настройка валидатора")
        frame:SetSize(300, 300)
        frame:Center()
        frame:MakePopup()
        frame.OnClose = function()
            if IsValid(ghost) then ghost:Remove() end
        end

        local function updateGhost()
            if not IsValid(ent) or not IsValid(ghost) then return end
            ghost:SetPos(ent:LocalToWorld(pos))
            ghost:SetAngles(ent:LocalToWorldAngles(ang))
        end

        local inputs = {}

        local function addVecInput(labelText, key)
            frame:Add("DLabel", frame):SetText(labelText):Dock(TOP):DockMargin(5,5,5,0)

            local pnl = vgui.Create("DPanel", frame)
            pnl:SetTall(24)
            pnl:Dock(TOP)
            pnl:DockMargin(5, 0, 5, 0)

            inputs[key] = {}

            for i, axis in ipairs({"x", "y", "z"}) do
                local entry = vgui.Create("DTextEntry", pnl)
                entry:SetWide(90)
                entry:Dock(LEFT)
                entry:SetNumeric(true)
                entry:SetText("0")
                inputs[key][axis] = entry

                entry.OnChange = function()
                    local x = tonumber(inputs.pos.x:GetValue()) or 0
                    local y = tonumber(inputs.pos.y:GetValue()) or 0
                    local z = tonumber(inputs.pos.z:GetValue()) or 0
                    local pitch = tonumber(inputs.ang.x:GetValue()) or 0
                    local yaw = tonumber(inputs.ang.y:GetValue()) or 0
                    local roll = tonumber(inputs.ang.z:GetValue()) or 0

                    pos = Vector(x, y, z)
                    ang = Angle(pitch, yaw, roll)
                    updateGhost()
                end
            end
        end

        addVecInput("Позиция (X, Y, Z)", "pos")
        addVecInput("Угол (Pitch, Yaw, Roll)", "ang")

        local confirm = frame:Add("DButton")
        confirm:SetText("Установить валидатор")
        confirm:Dock(BOTTOM)
        confirm:DockMargin(5, 10, 5, 5)
        confirm.DoClick = function()
            net.Start("Validator_SpawnManualValidator")
                net.WriteEntity(ent)
                net.WriteVector(pos)
                net.WriteAngle(ang)
            net.SendToServer()

            frame:Close()
        end

        LocalPlayer().ValidatorTarget = ent
    end
end)

net.Receive("Validator_SpawnManualValidator", function(len, ply)
    local ent = net.ReadEntity()
    local pos = net.ReadVector()
    local ang = net.ReadAngle()

    if not IsValid(ent) then return end
    if ent.CPPIGetOwner and ent:CPPIGetOwner() ~= ply then
        ply:ChatPrint("[Ошибка] Вы не владелец объекта.")
        return
    end

    local validator = ents.Create("bus_validator")
    if not IsValid(validator) then
        ply:ChatPrint("[Ошибка] Не удалось создать валидатор.")
        return
    end

    validator:SetPos(ent:LocalToWorld(pos))
    validator:SetAngles(ent:LocalToWorldAngles(ang))
    validator:Spawn()
    validator:Activate()
    validator:SetParent(ent)

    ply:ChatPrint("[Валидатор] Установлен вручную.")
end)

    
