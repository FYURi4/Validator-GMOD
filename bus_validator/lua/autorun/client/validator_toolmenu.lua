
concommand.Add("start_editing", function(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    ply:ChatPrint("[Валидатор] Режим настройки активирован. Выберите транспорт.")
    
    -- Активировать инструмент validator_tool
    ply:ConCommand("gmod_tool validator_tool")
end)

-- Хук добавления вкладки в Q-меню
hook.Add("PopulateToolMenu", "AddValidatorSettings", function()
    spawnmenu.AddToolMenuOption(
    "Utilities",
    "Инструменты Валидатора",
    "ValidatorSettings",
    "Настройка Валидаторов",
    "",
    "",
    function(panel)
        panel:ClearControls()

        panel:Help([[Для того, чтобы настроить валидаторы нужно:
        1. Нажать на кнопку ниже 'Начать настройку'.
        2. После появления gmod_tool выбрать транспорт, наведясь и нажав левую кнопку мыши.
        3. Если на транспорт имеется готовое решение, система предложит использовать стандартное решение, которое можно будет редактировать или создать свое решение с нуля.
        4. Выставить терминалы по координатам.
        5. Пользоваться.]])

        panel:Button("Начать настройку", "start_editing")
    end
    )
end)
