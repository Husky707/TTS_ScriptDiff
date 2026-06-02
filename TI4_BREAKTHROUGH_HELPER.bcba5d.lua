function getHelperClient(helperObjectName)
    local function getHelperObject()
        for _, object in ipairs(getAllObjects()) do
            if object.getName() == helperObjectName then return object end
        end
        error('missing object "' .. helperObjectName .. '"')
    end
    local helperObject = false
    local function getCallWrapper(functionName)
        helperObject = helperObject or getHelperObject()
        if not helperObject.getVar(functionName) then error('missing ' .. helperObjectName .. '.' .. functionName) end
        return function(parameters) return helperObject.call(functionName, parameters) end
    end
    return setmetatable({}, { __index = function(t, k) return getCallWrapper(k) end })
end

local function copyTable(t)
    if t and type(t) == 'table' then
        local copy = {}
        for k, v in pairs(t) do
            copy[k] = type(v) == 'table' and copyTable(v) or v
        end
        t = copy
    end
    return t
end

-------------------------------------------------------------------------------

function onLoad(saveState)
    self.setColorTint({ r = 0.25, g = 0.25, b = 0.25 })
    self.setScale({ x = 2, y = 0.01, z = 2 })
    self.setName('TI4_BREAKTHROUGH_HELPER')
    self.setDescription('Shared helper functions used by other objects, PLEASE LEAVE ON TABLE! This object is only visible to the black (GM) player.')

    -- Only the GM/black player can see this object.
    local invisibleTo = {}
    for _, color in ipairs(Player.getColors()) do
        if color ~= 'Black' then
            table.insert(invisibleTo, color)
        end
    end
    self.setInvisibleTo(invisibleTo)
end

function register(parameters)
    assert(type(parameters) == 'table')
    assert(type(parameters.guid) == 'string')
    assert(type(parameters.ui) == 'string')
    assert(type(parameters.onPlayCallback) == 'string')

    local breakthrough = assert(getObjectFromGUID(parameters.guid))
    breakthrough.clearButtons()

    local BUTTON_WIDTH = 500
    local BUTTON_HEIGHT = 250
    local BUTTON_FONT_SIZE = 100

    local position = { x = 0, y = -0.3, z = -1.25 }
    local rotation = { x = 0, y = 0, z = 180 }

    self.setVar('play_' .. parameters.guid, function(_, playerColor) _onClickPlay(breakthrough, parameters, playerColor) end)
    breakthrough.clearButtons()
    breakthrough.createButton({
        click_function = 'play_' .. parameters.guid,
        function_owner = self,
        label = 'Play',
        position = position,
        rotation = rotation,
        width = BUTTON_WIDTH,
        height = BUTTON_HEIGHT,
        font_size = BUTTON_FONT_SIZE,
        tooltip = 'Show UI'
    })   
end

-------------------------------------------------------------------------------

function _onClickPlay(breakthrough, parameters, playerColor)
    assert(type(breakthrough) == 'userdata')
    assert(type(parameters) == 'table')
    assert(type(playerColor) == 'string')

    -- Toggle visibility
    local seated = {}
    for _, color in pairs(getSeatedPlayers()) do
        table.insert(seated, color)
    end

    local active = UI.getAttribute(parameters.ui, 'active')
    active = string.lower(active) == 'true' and true or false
    if active or #seated == 0 then
        UI.setAttribute(parameters.ui, 'active', false)
    else
        UI.setAttribute(parameters.ui, "active", true)
        -- Tell the card in case there is any custom handling there.
        broadcastToAll('Activating ' .. breakthrough.getName(), playerColor)
        breakthrough.call(parameters.onPlayCallback, playerColor)
    end

    -- Tell any interested parties.
    local informObjects = {}
    for _, object in ipairs(getAllObjects()) do
        if object.getVar('onBreakthroughPlayed') then
            table.insert(informObjects, object)
        end
    end
    local guid = breakthrough.guid
    for i, object in ipairs(informObjects) do
        Wait.frames(function() object.call('onBreakthroughPlayed', guid) end, i)
    end
end

-------------------------------------------------------------------------------

function genericFollow(player, option, id)
    broadcastToAll(player.steam_name .. " uses " .. option .. ".", player.color)
    sendOnBreakthroughButtonClicked(player.color, option, id)
end

function notFollow(player, option, id)
    broadcastToAll(player.steam_name .. " does not use " .. option .. ".", player.color)
    sendOnBreakthroughButtonClicked(player.color, option, id)
end

function genericSilent(player, option, id)
    sendOnBreakthroughButtonClicked(player.color, option, id)
end

function closeMenu(player, menu, id)
    local vis = UI.getAttribute(menu, "visibility")
    if vis == nil or vis == "" then
        local seatedPlayers = getSeatedPlayers()
        for p, player in pairs(seatedPlayers) do
            if vis == nil or vis == "" then
                vis = player
            else
                vis = vis .. "|" .. player
            end
        end
    end
    local i, j = string.find(vis, player.color)
    local l = string.len(vis)
    if i ~= nil and j ~= nil then
        if i == 1 then
            if j == l then
                newVis = ""
            else
                newVis = string.sub(vis,j+2,l)
            end
        else
            if j == l then
                newVis = string.sub(vis,1,i-2)
            else
                newVis = string.sub(vis,1,i-1) .. string.sub(vis,j+2,l)
            end
        end
    end
    if newVis == "" then
        UI.setAttribute(menu, "active", false)
        broadcastToAll("All players have responded", "Black")
    end
    UI.setAttribute(menu, "visibility", newVis)
    sendOnBreakthroughButtonClicked(player.color, menu, id)
end


function sendOnBreakthroughButtonClicked(player, value, breakthrough)
    local handler = 'onBreakthroughButtonClicked'
    local listeners = {}
    for _, object in ipairs(getAllObjects()) do
        if object.getVar(handler) then
            table.insert(listeners, object.getGUID())
        end
    end
    if #listeners > 0 then
        local params = {
            player = player,
            breakthrough = breakthrough,
            value = value
        }
        for i, guid in ipairs(listeners) do
            local function callHandler()
                local listener = getObjectFromGUID(guid)
                if listener then
                    listener.call(handler, params)
                end
            end
            Wait.frames(callHandler, i)
        end
    end
end

-------------------------------------------------------------------------------
-- Index is only called when the key does not already exist.
local _lockGlobalsMetaTable = {}
function _lockGlobalsMetaTable.__index(table, key)
    error('Accessing missing global "' .. tostring(key or '<nil>') .. '", typo?', 2)
end
function _lockGlobalsMetaTable.__newindex(table, key, value)
    error('Globals are locked, cannot create global variable "' .. tostring(key or '<nil>') .. '"', 2)
end
setmetatable(_G, _lockGlobalsMetaTable)