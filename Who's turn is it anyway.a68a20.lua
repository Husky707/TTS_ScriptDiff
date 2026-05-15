function onLoad()
    local param = {}
    param.click_function = "button_function"
    param.function_owner = self
    param.label = "--"
    param.font_size = 300
    param.width = 3000
    param.height = 600
    param.position = {0, 0.1, 0}
    param.rotation = {0, 0, 0}

    self.setColorTint({1, 1, 1})

    self.createButton(param)
end

function button_function()
    -- print("do nothing")
end

function onPlayerTurnStart(now, prev)
    local playerName, colorName
    if Turns.enable then
        playerName = Player[now].steam_name or "??"
        colorName = now
    else
        playerName = "--"
        colorName = "Grey"
    end

    local param = self.getButtons()[1]
    param.label = playerName
    self.editButton(param)

    local rgb = stringColorToRGB(colorName)
    local color = {rgb["r"], rgb["g"], rgb["b"]}
    self.setColorTint(color)

    if Turns.enable then
        printToAll(">>> " .. playerName .. "'s turn. <<<", color)
    end
end