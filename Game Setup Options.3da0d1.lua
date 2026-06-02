-- @author Darrell for UI generation scripting
-- @author Milty for game setup
-- #include <~/TI4-TTS/TI4/Objects/GameSetupOptions>

local _config = false

local DEFAULT_CONFIG = {
    playerCount = 6,
    extraRings = 0,
    gamePoints = 10,
    usePoK = false,
    useCodex1 = false,
    useCodex2 = false,
    useTE = false,          -- Thunder's Edge toggle (removes TE tiles/cards when false)
    useFracture = false,    -- NEW: fracture toggle
    useTF = false,          -- NEW: Twilight's Fall WIP (now functional)
    is14ptGame = false,
    isRightClick = false,
    playerTools = false,
    gamedataOptIn = false,
}

-- === PUBLIC SHARED FLAGS (declare BEFORE globals are locked) ===
USE_TF = false  -- top-level global so other objects can read via getVar

-- Public getter (other objects can call this with object.call)
function getUseTF()
    return _config and _config.useTF == true
end

-- Optional generic getter for future flags
function getSetupFlag(key)
    if key == 'useTF' then return _config and _config.useTF == true end
    if key == 'useFracture' then return _config and _config.useFracture == true end
    if key == 'usePoK' then return _config and _config.usePoK == true end
    if key == 'useTE' then return _config and _config.useTE == true end
    return nil
end

-- Mirror flags to the global namespace and to the Global object
local function _publishFlags()
    USE_TF = (_config and _config.useTF == true) and true or false
    Global.setVar('USE_TF', USE_TF)  -- any script can read Global.getVar('USE_TF')
end
-- === END PUBLIC SHARED FLAGS ===

local CONTRIBUTORS = {
    '3tamatulg','Alister','Billy','Blarknob','BradleySigma','Brandondash','Cruix',
    'Cyrusa','Darrell','Darth Batman','Doot','Garnet Bear','Goatboy','Hooliganj',
    'Jabberwocky','Jatta Pake','Jefferson','Jirach08','Legoman','Lily','Loving Teammate',
    'Mage','Mantis','Max Philippa','Milty','Nicest_guy_22','Plat251','Positive',
    'Psicoma','Raptor1210','Rodney','Saunick','SCPT Hunter','SCPT Matt','Snorecerer',
    'Somberlord','Steve "Vorpal Dice Press"','Tactic Blue','ThatRobHuman','TheParsleySage',
    'Toppopia','Volverbot','Wekker','West','x3n d0g',
}

local BACK_MESSAGE = [[
This mod is made of contributions from many people.
-
Thanks to !CONTRIBUTORS, and the entire TI4 community for their contributions.
-
A massive shout out to Fantasy Flight Games for creating an awesome game. If you have the opportunity please support them. The board game industry wouldn't be the same without them and if you enjoy their work please, please support them and your local game stores.
]]

-------------------------------------------------------------------------------

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
local _deckHelper   = getHelperClient('TI4_DECK_HELPER')
local _factionHelper= getHelperClient('TI4_FACTION_HELPER')
local _setupHelper  = getHelperClient('TI4_SETUP_HELPER')
local _systemHelper = getHelperClient('TI4_SYSTEM_HELPER')
local _zoneHelper   = getHelperClient('TI4_ZONE_HELPER')

local _getByNameCache = {}
local _setupInProgress = false
local _updateUiFromConfigWaitId = false

-- Find a card's GUID inside a deck/container by card name.
-- Accepts a container object (Deck/Bag/etc) and a card name string.
-- Returns the GUID string or nil if not found.
function _getDeckCardGuid(container, cardName)
    if not container or type(cardName) ~= 'string' then return nil end
    local objs = {}
    if container.getObjects then
        objs = container.getObjects() or {}
    end
    for _, entry in ipairs(objs) do
        if entry and entry.name == cardName then
            return entry.guid
        end
    end
    return nil
end

-------------------------------------------------------------------------------

function onLoad(saveState)
    _config = DEFAULT_CONFIG
    if saveState and string.len(saveState) > 0 then
        _config = JSON.decode(saveState) or _config
    end

    -- Keep shared flags in sync at load
    _publishFlags()

    Wait.frames(_createUI, 2)
    scheduleUpdateUiFromConfig(4)
end

function onSave()
    return JSON.encode(_config)
end

function onPlayerConnect(playerId)
    Wait.frames(_createUI, 2)
    scheduleUpdateUiFromConfig(4)
end

function _createUI()
    local scale = self.getScale()
    local uiScale = (4 / scale.x) .. ' ' .. (4 / scale.z) .. ' ' .. (1 / scale.y)

    local function text(class, text)
        return { tag = 'Text', attributes = { class = class }, value = text }
    end

    local function toggle(id, text, isOn)
        return { tag = 'Toggle', attributes = { id = id, isOn = isOn or nil }, value = text }
    end

    local function slider(label, id, minValue, maxValue)
        local height = 20
        return {
            tag = 'HorizontalLayout',
            attributes = { childForceExpandWidth = true, childForceExpandHeight = false },
            children = {
                { tag = 'Text', attributes = { fontSize = 16, color = 'White', alignment = 'MiddleRight', minWidth = 110, minHeight = height }, value = label },
                { tag = 'Slider', attributes = { id = id, minValue = minValue, maxValue = maxValue, wholeNumbers = true, onValueChanged = 'onSliderValueChanged', minWidth = 100, minHeight = height, rectAlignment = 'MiddleCenter' }, value = minValue },
                { tag = 'Text', attributes = { id = id .. 'Value', fontSize = 16, color = 'White', alignment = 'MiddleLeft', horizontalOverflow = 'Overflow', verticalOverflow = 'Overflow', minWidth = 20, minHeight = height }, value = minValue },
            }
        }
    end

    local function spacer() return { tag = 'Text', attributes = { fontSize = 8 }} end

    local defaultColorBlock = '#FFFFFF|#1F45FC|#38ACEC|rgba(0.78,0.78,0.78,0.5)'
    local defaults = {
        tag = 'Defaults',
        children = {
            { tag = 'VerticalLayout', attributes = { spacing = 10, childForceExpandHeight = false } },
            { tag = 'HorizontalLayout', attributes = { spacing = 10 } },
            { tag = 'GridLayout', attributes = { spacing = '10 10', cellSize = '62 40' } },
            { tag = 'ToggleGroup', attributes = { toggleBackgroundColor = '#FF0000', toggleSelectedColor = '#38ACEC' } },
            { tag = 'Toggle', attributes = { fontSize = 16, textColor = 'White', onValueChanged = 'onToggleValueChanged' } },
            { tag = 'ToggleButton', attributes = { fontSize = 16, onValueChanged = 'onToggleValueChanged', colors = defaultColorBlock } },
            { tag = 'Button', attributes = { onClick = 'onButtonClick' } },
            { tag = 'Text', attributes = { class = 'title', fontSize = 20, fontStyle = 'Bold', color = 'White', alignment = 'MiddleCenter' } },
            { tag = 'Text', attributes = { class = 'heading', fontSize = 14, color = 'White', alignment = 'MiddleCenter' } },
        }
    }
    local top = {
        tag = 'Panel',
        attributes = { position = '0 0 2', rotation = '0 180 0', width = 300, height = 500, scale = uiScale },
        children = {
            {
                tag = 'VerticalLayout',
                attributes = { padding = '10 10 18 70' },
                children = {
                    text('title', 'TI4 Game Setup Options'),
                    spacer(),
                    slider('Player count', 'playerCount', 2, 8),
                    slider('Extra map rings', 'extraRings', 0, 4),
                    slider('Game points', 'gamePoints', 10, 14),
                    spacer(),
                    toggle('usePoK', 'Prophecy of Kings expansion'),
                    toggle('useTE', "Thunder's Edge expansion"),
                    toggle('useFracture', 'Enable the Fracture'),
                    toggle('useTF', "Twilight's Fall WIP"), -- shown under Fracture
                    toggle('playerTools', 'Player tools (boards, build area)'),
                    toggle('gamedataOptIn', 'Share anonymized game stats'),
                }
            },
            {
                tag = 'Panel',
                attributes = { height = 70, padding = '10 10 10 10', rectAlignment = 'LowerCenter' },
                children = { { tag = 'Button', attributes = { id = 'setup', fontSize = 24 }, value = 'Setup' } }
            }
        }
    }
    local bottom = {
        tag = 'Panel',
        attributes = { position = '0 0 -22', rotation = '0 0 0', width = 300, height = 500, padding = '20 20 20 20', scale = uiScale, color = '#000000e0' },
        children = {
            { tag = 'Text', attributes = { fontSize = 14, color = 'White', alignment = 'MiddleCenter' }, value = BACK_MESSAGE:gsub('!CONTRIBUTORS', table.concat(CONTRIBUTORS, ', ')) }
        }
    }

    self.UI.setXmlTable({ defaults, top, bottom })
end

function updateUiFromConfig()
    self.UI.setAttribute('playerCount', 'value', _config.playerCount)
    self.UI.setValue('playerCountValue', _config.playerCount)
    self.UI.setAttribute('extraRings', 'value', _config.extraRings)
    self.UI.setValue('extraRingsValue', _config.extraRings)
    self.UI.setAttribute('gamePoints', 'value', _config.gamePoints)
    self.UI.setValue('gamePointsValue', _config.gamePoints)

    self.UI.setAttribute('usePoK', 'isOn', _config.usePoK)
    self.UI.setAttribute('useTE', 'isOn', _config.useTE)
    self.UI.setAttribute('useFracture', 'isOn', _config.useFracture)
    self.UI.setAttribute('useTF', 'isOn', _config.useTF) -- reflect toggle
    self.UI.setAttribute('playerTools', 'isOn', _config.playerTools)
    self.UI.setAttribute('gamedataOptIn', 'isOn', _config.gamedataOptIn)
end

function scheduleUpdateUiFromConfig(delayFrameCount)
    if _updateUiFromConfigWaitId then
        Wait.stop(_updateUiFromConfigWaitId)
        _updateUiFromConfigWaitId = false
    end
    _updateUiFromConfigWaitId = Wait.frames(updateUiFromConfig, delayFrameCount or 2)
end

-------------------------------------------------------------------------------

local RIGHT_CLICK = '-2'

function onButtonClick(player, inputType, id)
    local isRightClick = inputType == RIGHT_CLICK and true or false
    if id == 'setup' then
        self.setLock(false)
        setupGame(isRightClick)
    else
        error('onButtonClick: unknown button "' .. id .. '"')
    end
end

function onToggleValueChanged(player, value, id)
    local valueAsBool = string.lower(value) == 'true' and true or false
    assert(type(valueAsBool) == 'boolean')

    if id == 'usePoK' then
        _config.usePoK = valueAsBool
    elseif id == 'useTE' then
        _config.useTE = valueAsBool
    elseif id == 'useFracture' then
        _config.useFracture = valueAsBool
    elseif id == 'useTF' then
        _config.useTF = valueAsBool -- store TF toggle
        _publishFlags()             -- << keep globals in sync
    elseif id == 'playerTools' then
        _config.playerTools = valueAsBool
    elseif id == 'gamedataOptIn' then
        _config.gamedataOptIn = valueAsBool
    else
        error('onToggleValueChanged: unknown toggle "' .. id .. '"')
    end
    scheduleUpdateUiFromConfig()
end

function onSliderValueChanged(player, value, id)
    value = tonumber(value)
    if id == 'playerCount' then
        _config.playerCount = value
    elseif id == 'extraRings' then
        _config.extraRings = value
    elseif id == 'gamePoints' then
        _config.gamePoints = value
    end
    scheduleUpdateUiFromConfig()
end

-------------------------------------------------------------------------------

function setupGame(isRightClick)
    if _setupInProgress then
        error('setupGame: setup in progress, ignoring second click')
        return
    end
    _setupInProgress = true

    if not isRightClick then
        _animateSelfDuringSetup()
    end

    _config.isRightClick = isRightClick
    startLuaCoroutine(self, 'setupGameCoroutine')
end

function setupGameCoroutine()
    assert(type(_config.playerCount) == 'number')
    assert(type(_config.extraRings) == 'number')
    assert(type(_config.gamePoints) == 'number')
    assert(type(_config.usePoK) == 'boolean')
    assert(type(_config.useTE) == 'boolean')
    assert(type(_config.useFracture) == 'boolean')
    assert(type(_config.useTF) == 'boolean')
    assert(type(_config.playerTools) == 'boolean')
    assert(type(_config.gamedataOptIn) == 'boolean')
    assert(type(_config.isRightClick) == 'boolean')

    -- Keep mirrors in sync before heavy setup, just in case
    _publishFlags()

    -----------------------------------------------------------------------
    -- Fracture rule: if enabled, ALWAYS add +1 extra ring (for tile space).
    -----------------------------------------------------------------------
    if _config.useFracture then
        _config.extraRings = _config.extraRings + 1
        print("[Fracture] Enabled: +1 extra ring applied.")
    end

    -- Require at least one extra ring for 7+ players (unchanged rule).
    if _config.playerCount > 6 then
        _config.extraRings = math.max(_config.extraRings, 1)
    end

    local effectiveExtraRings = _config.extraRings
    print('Setting up for ' .. _config.playerCount .. ' players with ' .. effectiveExtraRings .. ' extra map rings')

    setupPoK(_config.usePoK)
    coroutine.yield(0); coroutine.yield(0)

    setupTE(_config.useTE)
    coroutine.yield(0); coroutine.yield(0)

    _setupHelper.setup({
        playerCount = _config.playerCount,
        extraRings = effectiveExtraRings,
        gamePoints = _config.gamePoints,
        includePoK = _config.usePoK,
        playerTools = _config.playerTools and not _config.isRightClick,
        gamedataOptIn = _config.gamedataOptIn,
        isRightClick = _config.isRightClick,
    })
    coroutine.yield(0)

    -----------------------------------------------------------------------
    -- Place Fracture tiles per player count, if enabled (MOVE ONLY).
    -----------------------------------------------------------------------
    if _config.useFracture then
        placeFractureTilesFromContainer()
    end

    return 1
end

function setupTE(useTE)
    local container = _getByName("Thunder's Edge")
    if not container then
        for _, o in ipairs(getAllObjects()) do
            local n = o.getName()
            if n and string.find(n, 'Thunder') and string.find(n, 'Edge') then
                container = o
                break
            end
        end
    end
    if not container then
        error("setupTE: missing \"Thunder's Edge\" container")
    end
    coroutine.yield(0)

    local blueSystemTiles = assert(_getByName('Blue Planet Tiles'))
    local redSystemTiles  = assert(_getByName('Red Anomaly Tiles'))

    local teBlueSystemTilesGuidSet = {}
    local teRedSystemTilesGuidSet  = {}

    for _, system in pairs(_systemHelper.systems()) do
        if system.tile and system.tile >= 97 and system.tile <= 111 then
            if system.planets and #system.planets > 0 then
                assert(system.guid, 'system.guid missing for tile ' .. tostring(system.tile))
                teBlueSystemTilesGuidSet[system.guid] = true
            end
        end
        if system.tile and system.tile >= 113 and system.tile <= 117 then
            assert(system.guid, 'system.guid missing for tile ' .. tostring(system.tile))
            teRedSystemTilesGuidSet[system.guid] = true
        end
    end
    coroutine.yield(0)

    if not useTE then
        local MapTool = getObjectFromGUID('f161fa')
        if MapTool then MapTool.call('useLegendaryRex', false) end

        local posB = blueSystemTiles.getPosition(); posB.y = posB.y + 5
        for _, entry in ipairs(blueSystemTiles.getObjects()) do
            if teBlueSystemTilesGuidSet[entry.guid] then
                blueSystemTiles.takeObject({
                    position          = posB,
                    callback_function = function(object) container.putObject(object) end,
                    smooth            = false,
                    guid              = entry.guid
                })
                posB.y = posB.y + 0.5
                coroutine.yield(0)
            end
        end
        coroutine.yield(0)

        local posR = redSystemTiles.getPosition(); posR.y = posR.y + 5
        for _, entry in ipairs(redSystemTiles.getObjects()) do
            if teRedSystemTilesGuidSet[entry.guid] then
                redSystemTiles.takeObject({
                    position          = posR,
                    callback_function = function(object) container.putObject(object) end,
                    smooth            = false,
                    guid              = entry.guid
                })
                posR.y = posR.y + 0.5
                coroutine.yield(0)
            end
        end
        coroutine.yield(0)

        local actionDeckGuid = _deckHelper.getDeck('Actions')
        local actionDeck = actionDeckGuid and getObjectFromGUID(actionDeckGuid)
        if actionDeck and actionDeck.tag == 'Deck' then
            local targetNames = {}
            local targetCards = _deckHelper.getCardsWithSource({ deckName = 'Actions', source = 'TE' }) or {}
            for _, card in ipairs(targetCards) do targetNames[card] = true end
            local pos = actionDeck.getPosition(); pos.y = pos.y + 5
            for _, entry in ipairs(actionDeck.getObjects()) do
                if targetNames[entry.name] then
                    actionDeck.takeObject({
                        guid              = entry.guid,
                        position          = pos,
                        callback_function = function(obj) container.putObject(obj) end,
                        smooth            = false,
                    })
                    pos.y = pos.y + 0.2
                    coroutine.yield(0)
                end
            end
            coroutine.yield(0)
        end

        local relicsDeckGuid = _deckHelper.getDeck('Relics')
        if relicsDeckGuid then
            local relicsDeck = getObjectFromGUID(relicsDeckGuid)
            if relicsDeck and relicsDeck.tag == 'Deck' then
                local targetNames = {}
                local targetCards = _deckHelper.getCardsWithSource({ deckName = 'Relics', source = 'TE' }) or {}
                for _, card in ipairs(targetCards) do targetNames[card] = true end
                local removeGuids = {}
                for _, entry in ipairs(relicsDeck.getObjects()) do
                    if targetNames[entry.name] then table.insert(removeGuids, entry.guid) end
                end
                coroutine.yield(0)
                if #removeGuids > 0 then
                    local pos = relicsDeck.getPosition(); pos.y = pos.y + 6
                    local createDeck = false
                    for _, guid in ipairs(removeGuids) do
                        local card = relicsDeck.takeObject({ guid = guid, position = pos, smooth = false })
                        pos.y = pos.y + 0.2
                        if createDeck then
                            local needYield = createDeck.tag == 'Card'
                            createDeck.setLock(false)
                            createDeck = createDeck.putObject(card)
                            while createDeck.spawning do coroutine.yield(0) end
                            coroutine.yield(0)
                            createDeck.setLock(true)
                            if needYield then for _=1,20 do coroutine.yield(0) end end
                        else
                            createDeck = card; createDeck.setLock(true)
                        end
                        coroutine.yield(0)
                    end
                    if createDeck then
                        createDeck.setLock(false)
                        if createDeck.tag == 'Deck' then createDeck.setName("Thunder's Edge Relics") end
                        container.putObject(createDeck)
                        coroutine.yield(0)
                    end
                else
                    print('setupTE: no matching Relic cards found to remove for Thunder\'s Edge')
                end
            else
                print('setupTE: "Relics" deck missing or not a deck; skipping card removal')
            end
        else
            print('setupTE: could not locate "Relics" deck GUID; skipping card removal')
        end

        local factionsBag = assert(_getByName('Factions'))
        local pickFactionBag = assert(_getByName('Pick a Faction to Play'))
        local teFactionBoxNameSet = {}
        local teFactionTokenNameSet = {}
        for _, faction in pairs(_factionHelper.allFactions(true)) do
            if faction.source == 'TE' then
                teFactionBoxNameSet[faction.tokenName .. ' Box'] = true
                teFactionTokenNameSet[faction.tokenName .. ' Faction Token'] = true
            end
        end
        coroutine.yield(0)

        local pos = factionsBag.getPosition(); pos.y = pos.y + 5
        for _, entry in ipairs(factionsBag.getObjects()) do
            if teFactionBoxNameSet[entry.name] then
                factionsBag.takeObject({
                    position          = pos,
                    callback_function = function(object) container.putObject(object) end,
                    smooth            = false,
                    guid              = entry.guid
                })
                pos.y = pos.y + 3
                coroutine.yield(0)
            end
        end
        coroutine.yield(0)

        pos = pickFactionBag.getPosition(); pos.y = pos.y + 5
        for _, entry in ipairs(pickFactionBag.getObjects()) do
            if teFactionTokenNameSet[entry.name] then
                pickFactionBag.takeObject({
                    position          = pos,
                    callback_function = function(object) container.putObject(object) end,
                    smooth            = false,
                    guid              = entry.guid
                })
                pos.y = pos.y + 3
                coroutine.yield(0)
            end
        end
        coroutine.yield(0)
    else
        -- TE enabled: no removals here.
    end
end

function setupCodex1(useCodex1) end
function setupCodex2(useCodex2) end

function setupPoK(usePoK)
    local container = _getByName('Prophecy of Kings')
    if not container then error('setupPoK: missing box') end
    coroutine.yield(0)

    local redSystemTiles = assert(_getByName('Red Anomaly Tiles'))
    local blueSystemTiles = assert(_getByName('Blue Planet Tiles'))
    local pokRedSystemTilesGuidSet = {}
    local pokBlueSystemTilesGuidSet = {}

    for _, system in pairs(_systemHelper.systems()) do
        if system.tile >= 52 and system.tile <= 82 then
            assert(system.guid)
            if system.anomalies and #system.anomalies > 0 then
                pokRedSystemTilesGuidSet[system.guid] = true
            elseif system.planets and #system.planets > 0 then
                pokBlueSystemTilesGuidSet[system.guid] = true
            else
                pokRedSystemTilesGuidSet[system.guid] = true
            end
        end
    end
    coroutine.yield(0)

    local factionsBag = assert(_getByName('Factions'))
    local pickFactionBag = assert(_getByName('Pick a Faction to Play'))
    local pokFactionBoxNameSet = {}
    local pokFactionTokenNameSet = {}
    for _, faction in pairs(_factionHelper.allFactions(true)) do
        if faction.home and faction.home >= 52 and faction.home <= 82 then
            pokFactionBoxNameSet[faction.tokenName .. ' Box'] = true
            pokFactionTokenNameSet[faction.tokenName .. ' Faction Token'] = true
        end
    end
    coroutine.yield(0)

    if usePoK then
        print("Using PoK")
        local deckNames = _deckHelper.getDecksWithSource('PoK')
        for _, deckName in ipairs(deckNames) do
            _addCards(container.getName(), deckName, 'PoK')
            coroutine.yield(0)
        end

        local pos = container.getPosition(); pos.y = pos.y + 5
        for _, entry in ipairs(container.getObjects()) do
            if pokBlueSystemTilesGuidSet[entry.guid] then
                container.takeObject({
                    position          = pos,
                    callback_function = function(object) blueSystemTiles.putObject(object) end,
                    smooth            = false,
                    guid              = entry.guid
                })
                pos.y = pos.y + 0.5
                coroutine.yield(0)
            elseif pokRedSystemTilesGuidSet[entry.guid] then
                container.takeObject({
                    position          = pos,
                    callback_function = function(object) redSystemTiles.putObject(object) end,
                    smooth            = false,
                    guid              = entry.guid
                })
                pos.y = pos.y + 0.5
                coroutine.yield(0)
            end
        end
        coroutine.yield(0)

        for _, entry in ipairs(container.getObjects()) do
            if pokFactionBoxNameSet[entry.name] then
                container.takeObject({
                    position          = pos,
                    callback_function = function(object) factionsBag.putObject(object) end,
                    smooth            = false,
                    guid              = entry.guid
                })
                pos.y = pos.y + 3
                coroutine.yield(0)
            end
        end
        coroutine.yield(0)

        for _, entry in ipairs(container.getObjects()) do
            if pokFactionTokenNameSet[entry.name] then
                container.takeObject({
                    position          = pos,
                    callback_function = function(object) pickFactionBag.putObject(object) end,
                    smooth            = false,
                    guid              = entry.guid
                })
                pos.y = pos.y + 0.5
                coroutine.yield(0)
            end
        end
        coroutine.yield(0)
        pickFactionBag.shuffle()
    else
        print("Removing PoK")
        -- Remove cards.
        local deckNames = _deckHelper.getDecksWithSource('PoK')
        for _, deckName in ipairs(deckNames) do
            _removeCards(container.getName(), deckName, 'PoK')
            coroutine.yield(0)
        end

        -- Remove other objects.  Only do this for the "final" setup.
        if not _config.isRightClick then
            local removeNameSet = {
                --['Exploration Mat'] = true,
                ['Exploration Bag'] = true,
                ['Frontier Tokens Bag'] = true,
                ['Mallice Tile'] = true,
                ['Cultural Relic Fragments Bag'] = true,
                ['Hazardous Relic Fragments Bag'] = true,
                ['Industrial Relic Fragments Bag'] = true,
                ['Unknown Relic Fragments Bag'] = true,
            }
            for _, object in ipairs(getAllObjects()) do
                local name = object.getName()
                if removeNameSet[name] then
                    object.setLock(false)
                    container.putObject(object)
                    coroutine.yield(0)
                end
            end
            coroutine.yield(0)
        end

        -- Remove system tiles.
        local pos = redSystemTiles.getPosition()
        pos.y = pos.y + 5
        for _, entry in ipairs(redSystemTiles.getObjects()) do
            if pokRedSystemTilesGuidSet[entry.guid] then
                redSystemTiles.takeObject({
                    position          = pos,
                    callback_function = function(object) container.putObject(object) end,
                    smooth            = false,
                    guid              = entry.guid
                })
                pos.y = pos.y + 0.5
                coroutine.yield(0)
            end
        end
        local pos = blueSystemTiles.getPosition()
        pos.y = pos.y + 5
        for _, entry in ipairs(blueSystemTiles.getObjects()) do
            if pokBlueSystemTilesGuidSet[entry.guid] then
                blueSystemTiles.takeObject({
                    position          = pos,
                    callback_function = function(object) container.putObject(object) end,
                    smooth            = false,
                    guid              = entry.guid
                })
                pos.y = pos.y + 0.5
                coroutine.yield(0)
            end
        end

        -- Remove faction boxes.
        local pos = factionsBag.getPosition()
        pos.y = pos.y + 5
        for _, entry in ipairs(factionsBag.getObjects()) do
            if pokFactionBoxNameSet[entry.name] then
                factionsBag.takeObject({
                    position          = pos,
                    callback_function = function(object) container.putObject(object) end,
                    smooth            = false,
                    guid              = entry.guid
                })
                pos.y = pos.y + 3
                coroutine.yield(0)
            end
        end
        coroutine.yield(0)

        -- Remove faction tokens (pick a faction to play).
        local pos = pickFactionBag.getPosition()
        pos.y = pos.y + 5
        for _, entry in ipairs(pickFactionBag.getObjects()) do
            if pokFactionTokenNameSet[entry.name] then
                pickFactionBag.takeObject({
                    position          = pos,
                    callback_function = function(object) container.putObject(object) end,
                    smooth            = false,
                    guid              = entry.guid
                })
                pos.y = pos.y + 3
                coroutine.yield(0)
            end
        end
        coroutine.yield(0)
    end
end

-------------------------------------------------------------------------------

function onSetupHelperSetupFinished()
    printToAll('Initial setup finished, waiting a few seconds before final setup steps', 'Yellow')
    Wait.time(function() startLuaCoroutine(self, 'postSetupCoroutine') end, 5)
end

-- === NEW: Twilight's Fall replacement logic ===
local function _findFirstByNames(nameList)
    for _, n in ipairs(nameList) do
        local obj = _getByName(n)
        if obj then return obj, n end
    end
end

local function _takeFromContainerByName(container, name, position, rotation)
    if not container then return false end
    for _, entry in ipairs(container.getObjects() or {}) do
        if entry.name == name then
            container.takeObject({
                guid     = entry.guid,
                position = position,
                rotation = rotation or {x=0,y=0,z=0},
                smooth   = false
            })
            return true
        end
    end
    return false
end

function applyTwilightsFallReplacements()
    local setupBag = _getByName('Setup Bag')
    local tfCards  = _getByName('TF Strategy Cards')

    if not setupBag then
        print('[TF] ERROR: "Setup Bag" not found; skipping TF replacements.')
        return
    end
    if not tfCards then
        print('[TF] ERROR: "TF Strategy Cards" container not found; skipping TF replacements.')
    end

    -- === STRATEGY CARD SWAPS ===
    local swaps = {
        { from = {'Leadership'},            to = 'Lux'      },
        { from = {'Diplomacy','Dipolomacy'},to = 'Noctis'   },
        { from = {'Politics'},              to = 'Tyrannus' },
        { from = {'Construction'},          to = 'Civitas'  },
        { from = {'Trade'},                 to = 'Amicus'   },
        { from = {'Warfare'},               to = 'Calamitas'},
        { from = {'Technology'},            to = 'Magus'    },
        { from = {'Imperial'},              to = 'Aeterna'  },
    }

    for _, s in ipairs(swaps) do
        local oldObj, matchedName = _findFirstByNames(s.from)
        if not oldObj then
            print(string.format('[TF] WARNING: could not find %s on table; skipping.', table.concat(s.from, '/')))
        else
            local pos = oldObj.getPosition()
            local rot = oldObj.getRotation()
            setupBag.putObject(oldObj)
            coroutine.yield(0)

            local ok = _takeFromContainerByName(tfCards, s.to, pos, rot)
            if ok then
                print(string.format('[TF] Replaced "%s" with "%s".', matchedName, s.to))
            else
                print(string.format('[TF] ERROR: could not find "%s" inside "TF Strategy Cards".', s.to))
            end
            coroutine.yield(0)
        end
    end

    ----------------------------------------------------------------
    -- Agenda Phase Mat -> Splice Board (NO rotation; 3s delay before lock + placement)
    -- Also remove: "Agendas/Laws Mat", "Thunder's Edge Token", "Breakthroughs"
    ----------------------------------------------------------------
    do
        local agendaMat = _getByName('Agenda Phase Mat')
        if agendaMat then
            local pos = agendaMat.getPosition()
            local rot = agendaMat.getRotation()
            setupBag.putObject(agendaMat)
            coroutine.yield(0)

            local extraRemovals = {
                'Agendas/Laws Mat',
                "Thunder's Edge Token",
                'Breakthroughs',
            }
            for _, name in ipairs(extraRemovals) do
                local obj = _getByName(name)
                if obj then
                    setupBag.putObject(obj)
                    coroutine.yield(0)
                    print('[TF] Moved "' .. name .. '" to Setup Bag.')
                else
                    print('[TF] NOTICE: "' .. name .. '" not found.')
                end
            end

            local splice = _getByName('Splice Board')
            if splice then
                splice.setLock(false)
                splice.setPositionSmooth(pos, false, false)

                -- Wait 3 seconds before locking + placing cards
                Wait.time(function()
                    if splice and splice.setLock then splice.setLock(true) end

                    local targets = {
                        { name = "Paradigm",       pos = {x=-49.85, y=1.40, z= 3.56}, rot = {x=359.2, y=0.0, z=179.9} },
                        { name = "Abilities",      pos = {x=-49.88, y=1.36, z= 0.78}, rot = {x=359.2, y=0.0, z=179.9} },
                        { name = "Unit Upgrades",  pos = {x=-49.86, y=1.33, z=-1.41}, rot = {x=359.2, y=0.0, z=179.9} },
                        { name = "Genome",         pos = {x=-49.85, y=1.30, z=-3.56}, rot = {x=359.2, y=0.0, z=179.9} },
                    }
                    for _, t in ipairs(targets) do
                        local obj = _getByName(t.name)
                        if obj then
                            obj.setLock(false)
                            obj.setPositionSmooth(t.pos, false, false)
                            obj.setRotationSmooth(t.rot, false)
                        else
                            print('[TF] NOTICE: "' .. t.name .. '" not found to reposition.')
                        end
                    end
                end, 3.0)
            else
                local pulled = _takeFromContainerByName(setupBag, 'Splice Board', pos, rot)
                if not pulled then
                    print('[TF] WARNING: "Splice Board" not found.')
                end
            end
            coroutine.yield(0)
        else
            print('[TF] NOTICE: "Agenda Phase Mat" not found.')
        end
    end

    ----------------------------------------------------------------
    -- Deck GUID swap (b4e652 -> Setup Bag, fab0f7 -> its position)
    ----------------------------------------------------------------
    do
        local a = getObjectFromGUID('b4e652')
        local b = getObjectFromGUID('fab0f7')
        if a then
            local pos = a.getPosition()
            local rot = a.getRotation()
            setupBag.putObject(a)
            coroutine.yield(0)

            if b then
                b.setPositionSmooth(pos, false, false)
                b.setRotationSmooth(rot, false)
            else
                for _, entry in ipairs(setupBag.getObjects() or {}) do
                    if entry.guid == 'fab0f7' then
                        setupBag.takeObject({
                            guid = 'fab0f7',
                            position = pos,
                            rotation = rot,
                            smooth = false
                        })
                        break
                    end
                end
            end
            coroutine.yield(0)
        else
            print('[TF] NOTICE: Deck GUID b4e652 not found.')
        end
    end

    ----------------------------------------------------------------
    -- Agenda deck -> Edicts deck (plural)
    ----------------------------------------------------------------
    do
        local agendaDeck = _getByName('Agenda')
        if agendaDeck then
            local pos = agendaDeck.getPosition()
            local rot = agendaDeck.getRotation()
            setupBag.putObject(agendaDeck)
            coroutine.yield(0)

            local edictsDeck = _getByName('Edicts')
            if edictsDeck then
                edictsDeck.setPositionSmooth(pos, false, false)
                edictsDeck.setRotationSmooth(rot, false)
            else
                local pulled = _takeFromContainerByName(setupBag, 'Edicts', pos, rot)
                if not pulled then
                    print('[TF] WARNING: "Edicts" deck not found.')
                end
            end
            coroutine.yield(0)
        else
            print('[TF] NOTICE: "Agenda" deck not found.')
        end
    end

    ----------------------------------------------------------------
    -- Actions deck -> TF Actions (explicit transform after 0.5s)
    ----------------------------------------------------------------
    do
        local bag = setupBag or _getByName('Setup Bag')
        local actions = _getByName('Actions')
        if actions and bag then
            bag.putObject(actions)
            coroutine.yield(0)

            Wait.time(function()
                local tf = _getByName('TF Actions')
                if tf then
                    tf.setLock(false)
                    tf.setPosition({ x = -61.26, y = 1.51, z = -4.01 })
                    tf.setRotation({ x = 0.0, y = 90.0, z = 180.0 })
                else
                    print('[TF] WARNING: "TF Actions" not found.')
                end
            end, 0.5)
        else
            if not actions then print('[TF] NOTICE: "Actions" deck not found.') end
            if not bag then print('[TF] ERROR: "Setup Bag" not found.') end
        end
    end

    ----------------------------------------------------------------
    -- Move specific Relics to Setup Bag
    ----------------------------------------------------------------
    do
        local relicsDeck = _getByName('Relics')
        if relicsDeck then
            local cardNames = {
                'Maw of Worlds',
                'The Prophet\'s Tears',
                'The Quantumcore'
            }
            for _, cardName in ipairs(cardNames) do
                local guid = _getDeckCardGuid(relicsDeck, cardName)
                if guid then
                    local card = relicsDeck.takeObject({
                        guid = guid,
                        position = setupBag.getPosition() + vector(0, 3, 0),
                        smooth = false
                    })
                    setupBag.putObject(card)
                    coroutine.yield(0)
                    print('[TF] Moved "' .. cardName .. '" to Setup Bag.')
                else
                    print('[TF] NOTICE: "' .. cardName .. '" not found in Relics deck.')
                end
            end
        else
            print('[TF] NOTICE: "Relics" deck not found.')
        end
    end

        -- Move specific Secret Objectives to Setup Bag
    ----------------------------------------------------------------
    do
        local secretsDeck = _getByName('Secret Objectives')
        if secretsDeck then
            local cardNames = {
                'Betray a Friend',
                'Dictate Policy',
                'Drive the Debate',
                'Strengthen Bonds'
            }
            for _, cardName in ipairs(cardNames) do
                local guid = _getDeckCardGuid(secretsDeck, cardName)
                if guid then
                    local card = secretsDeck.takeObject({
                        guid = guid,
                        position = setupBag.getPosition() + vector(0, 3, 0),
                        smooth = false
                    })
                    setupBag.putObject(card)
                    coroutine.yield(0)
                    print('[TF] Moved Secret Objective "' .. cardName .. '" to Setup Bag.')
                else
                    print('[TF] NOTICE: Secret Objective "' .. cardName .. '" not found.')
                end
            end
        else
            print('[TF] NOTICE: "Secret Objectives" deck not found.')
        end
    end

    ----------------------------------------------------------------
    -- Benediction Token -> explicit transform
    ----------------------------------------------------------------
    do
        local bene = _getByName('Benediction Token')
        if bene then
            bene.setLock(false)
            bene.setPosition({ x = 45.13, y = 1.26, z = 1.94 })
            bene.setRotation({ x = 0.0, y = 270.0, z = 180.0 })
            coroutine.yield(0)
        else
            print('[TF] NOTICE: "Benediction Token" not found.')
        end
    end
end




function postSetupCoroutine()
    if _config.isRightClick then
        print('Skipping final setup for right-click action.  Finished.')
        _setupInProgress = false
        return 1
    end

    print('Doing final setup')
    postSetupPoK()
    coroutine.yield(0)

    if _config.useTF then
        print('[TF] Twilight\'s Fall enabled: swapping strategy cards...')
        applyTwilightsFallReplacements()
        coroutine.yield(0)
    end

    packSelfIntoSetupBag()
    coroutine.yield(0)

    _setupInProgress = false
    print('Doing final setup: finished')
    return 1
end

function postSetupPoK()
    local container = assert(_getByName('Prophecy of Kings'))
    local removeCardsGuidAndDeck = {}

    if _config.usePoK then
        local removeCards = _deckHelper.getRemoveForPoKCardNames()
        for _, cardName in ipairs(removeCards) do
            local deckName = assert(_deckHelper.getDeckName(cardName), 'getDeckName')
            local deckGuid = assert(_deckHelper.getDeck(deckName), 'getCardName')
            local deck = assert(getObjectFromGUID(deckGuid))
            for _, entry in ipairs(deck.getObjects()) do
                if entry.name == cardName then
                    table.insert(removeCardsGuidAndDeck, { guid = entry.guid, deck = deck })
                end
            end
            coroutine.yield(0)
        end
        coroutine.yield(0)

        local bag = assert(_getByName('Blue Planet Tiles')); bag.shuffle()
        local bag2 = assert(_getByName('Red Anomaly Tiles')); bag2.shuffle()
    else
        -- (Omitted: PoK-off cleanup branch; unchanged if you need it)
    end

    local deckToExtraY = {}
    for _, guidAndDeck in pairs(removeCardsGuidAndDeck) do
        local guid = guidAndDeck.guid
        local deck = guidAndDeck.deck
        assert(deck.tag == 'Deck')
        local pos = deck.getPosition()
        local extraY = deckToExtraY[deck.getGUID()] or 0
        deckToExtraY[deck.getGUID()] = extraY + 0.2
        deck.takeObject({
            guid              = guid,
            position          = { x = pos.x, y = pos.y + 10 + extraY, z = pos.z },
            callback_function = function(card) container.putObject(card) end,
            smooth            = false
        })
        coroutine.yield(0)
    end
    coroutine.yield(0)
end

-------------------------------------------------------------------------------

function packSelfIntoSetupBag()
    local setupBag = _getByName('Setup Bag')
    local tutorial = _getByName('TI4 TTS Tutorial Series')
    if tutorial then setupBag.putObject(tutorial) end
    self.setLock(false)
    setupBag.putObject(self)
end

function _copy(t)
    if t and type(t) == 'table' then
        local copy = {}
        for k, v in pairs(t) do
            copy[k] = type(v) == 'table' and _copy(v) or v
        end
        t = copy
    end
    return t
end

function _getByName(name)
    local guid = _getByNameCache[name]
    local object = guid and getObjectFromGUID(guid)
    if object then return object end
    for _, object in ipairs(getAllObjects()) do
        if object.getName() == name then
            _getByNameCache[name] = object.getGUID()
            return object
        end
    end
end

function _addCards(containerName, deckName, sourceName)
    assert(type(containerName) == 'string' and type(deckName) == 'string' and type(sourceName) == 'string')

    local container = _getByName(containerName)
    if not container then error('_addCards: missing container "' .. containerName .. '"') end

    local name = sourceName .. ' ' .. deckName
    local guid = false
    for _, entry in ipairs(container.getObjects()) do
        if entry.name == name or entry.name == deckName then
            if guid then error('_addCards: multiple "' .. name .. '" candidates') end
            guid = entry.guid
        end
    end
    if not guid then return end

    local transform = _deckHelper.getDeckTransform(deckName)
    if not transform then error('_addCards: missing location for "' .. deckName .. '"') end

    container.takeObject({
        guid = guid,
        position = { x = transform.position.x, y = transform.position.y + 5, z = transform.position.z },
        rotation = _copy(transform.rotation),
        smooth = true
    })

    local function delayedShuffle()
        local deck = getObjectFromGUID(_deckHelper.getDeck(deckName))
        if deck then deck.shuffle() end
    end
    Wait.time(delayedShuffle, 5 + math.random())
end

--- Move cards from the given source/deck to the container.  Will move a subset
-- if the deck has other cards, or the whole deck otherwise.
function _removeCards(containerName, deckName, sourceName)
    assert(type(containerName) == 'string' and type(deckName) == 'string' and type(sourceName) == 'string')

    local container = _getByName(containerName)
    if not container then
        error('_removeCards: missing container "' .. containerName .. '"')
    end

    local deck = getObjectFromGUID(_deckHelper.getDeck(deckName))
    if not deck then
        return -- this happens if the deck is already put away
    end
    if deck.tag ~= 'Deck' then
        error('"' .. deckName .. '" is not a deck')
    end

    local nameList = _deckHelper.getCardsWithSource({ deckName = deckName, source = sourceName })
    if not nameList then
        error('_removeCards: missing source "' .. sourceName .. '"')
    end
    local nameSet = {}
    for _, name in ipairs(nameList) do
        nameSet[name] = true
    end

    local removeGuids = {}
    for _, entry in ipairs(deck.getObjects()) do
        if nameSet[entry.name] then
            table.insert(removeGuids, entry.guid)
        end
    end

    if deck.getQuantity() == #removeGuids then
        container.putObject(deck)
    else
        local position = deck.getPosition()
        position.y = position.y + 5
        local createDeck = false
        for _, guid in ipairs(removeGuids) do
            local card = deck.takeObject({
                guid              = guid,
                position          = position,
                smooth            = false,
            })
            position.y = position.y + 0.2
            if createDeck then
                local needYield = createDeck.tag == 'Card'
                createDeck.setLock(false)
                createDeck = createDeck.putObject(card)
                while createDeck.spawning do
                    coroutine.yield(0)
                end
                coroutine.yield(0)
                createDeck.setLock(true)
                if needYield then
                    for _ = 1, 20 do
                        coroutine.yield(0)
                    end
                end
            else
                createDeck = card
                createDeck.setLock(true)
            end
            coroutine.yield(0)
        end
        if createDeck then
            createDeck.setLock(false)
            if createDeck.tag == 'Deck' then
                createDeck.setName(sourceName .. ' ' .. deckName)
            end
            container.putObject(createDeck)
            coroutine.yield(0)
        end
    end
end

function _animateSelfDuringSetup()
    local delay = 0.1
    local function doUpdate()
        self.rotate({ x = 0, y = 3, z = 0 })
        Wait.time(doUpdate, delay)
    end
    Wait.time(doUpdate, delay)
end

-------------------------------------------------------------------------------
-- Neutral unit helpers (from pre-made Neutral containers)
-------------------------------------------------------------------------------

-- Raycast straight down from slightly above the object's current position
-- to find the first surface Y. Returns a Y value or nil if no hit.
local function _rayDownY(pos, ignore)
    local hits = Physics.cast({
        origin        = {x=pos.x, y=pos.y + 3, z=pos.z},
        direction     = {0,-1,0},
        type          = 1,          -- Ray
        max_distance  = 10,
        debug         = false,
        ignore        = ignore and {ignore} or nil,
    })
    if hits and #hits > 0 then
        -- pick the closest hit
        local best = hits[1]
        local bestDist = best.distance or 1e9
        for i=2,#hits do
            local h = hits[i]
            local d = h.distance or 1e9
            if d < bestDist then best, bestDist = h, d end
        end
        if best and best.point then
            return best.point.y
        end
    end
end

-- ONE-SHOT settle/nudge for units (kept as-is)
local function _forceSettleOnSurface(obj)
    if not obj then return end

    local function attemptOnce()
        if not obj then return end

        local p = obj.getPosition()
        local groundY = _rayDownY(p, obj)
        if groundY then
            local targetY = groundY + 0.2
            if math.abs(p.y - targetY) > 0.05 then
                obj.setPosition({ x = p.x, y = targetY, z = p.z })
            end
        else
            -- No ray hit? give a tiny downward bump
            obj.setPosition({ x = p.x, y = p.y - 0.2, z = p.z })
        end

        if obj.setAngularVelocity then obj.setAngularVelocity({0,0,0}) end
        if obj.setVelocity then obj.setVelocity({0,-3,0}) end
        -- No retries
    end

    -- Let spawn/smoothing finish, then nudge once
    Wait.frames(attemptOnce, 2)
end

local function _spawnOneFromBag(bagName, worldPos, worldRot)
    local bag = _getByName(bagName)
    if not bag then
        print('[NeutralUnits] WARNING: missing bag "'..bagName..'"')
        return
    end
    bag.takeObject({
        position = worldPos,
        rotation = worldRot or {x=0,y=0,z=0},
        smooth   = true,
        callback_function = function(obj)
            _forceSettleOnSurface(obj)
        end
    })
end

-- D12964: 2 Cruisers, 2 Infantry (home system center used)
function placeNeutral2Cruisers2InfantryAtD12964()
    local hs = getObjectFromGUID('d12964')
    if not hs then
        print('[NeutralUnits] WARNING: missing HS guid d12964')
        return
    end
    local function p(dx, dz) return hs.positionToWorld({x=dx, y=1, z=dz}) end
    local yRot = hs.getRotation().y
    _spawnOneFromBag('Neutral Cruiser',  p( 1.2,  0.0), {x=0,y=yRot,z=0})
    _spawnOneFromBag('Neutral Cruiser',  p(-1.2,  0.0), {x=0,y=yRot,z=0})
    _spawnOneFromBag('Neutral Infantry', p( 0.5,  0.9), {x=0,y=yRot,z=0})
    _spawnOneFromBag('Neutral Infantry', p(-0.5, -0.9), {x=0,y=yRot,z=0})
end

-- ADA29D: 2 Dreads, 1 Destroyer, 3 Infantry
function placeNeutralForAda29d()
    local hs = getObjectFromGUID('ada29d')
    if not hs then
        print('[NeutralUnits] WARNING: missing HS guid ada29d')
        return
    end
    local function p(dx, dz) return hs.positionToWorld({x=dx, y=1, z=dz}) end
    local yRot = hs.getRotation().y
    _spawnOneFromBag('Neutral Dreadnought', p( 1.2,  0.2), {x=0,y=yRot,z=0})
    _spawnOneFromBag('Neutral Dreadnought', p(-1.2, -0.2), {x=0,y=yRot,z=0})
    _spawnOneFromBag('Neutral Destroyer',   p( 0.0, -1.4), {x=0,y=yRot,z=0})
    _spawnOneFromBag('Neutral Infantry',    p( 0.6,  1.0), {x=0,y=yRot,z=0})
    _spawnOneFromBag('Neutral Infantry',    p(-0.6,  1.0), {x=0,y=yRot,z=0})
    _spawnOneFromBag('Neutral Infantry',    p( 0.0,  1.5), {x=0,y=yRot,z=0})
end

-- 8D90CF: 1 Carrier, 2 Infantry, 4 Fighters
function placeNeutralFor8d90cf()
    local hs = getObjectFromGUID('8d90cf')
    if not hs then
        print('[NeutralUnits] WARNING: missing HS guid 8d90cf')
        return
    end
    local function p(dx, dz) return hs.positionToWorld({x=dx, y=1, z=dz}) end
    local yRot = hs.getRotation().y
    _spawnOneFromBag('Neutral Carrier',   p( 0.0, -1.2), {x=0,y=yRot,z=0})
    _spawnOneFromBag('Neutral Infantry',  p( 0.6,  1.0), {x=0,y=yRot,z=0})
    _spawnOneFromBag('Neutral Infantry',  p(-0.6,  1.0), {x=0,y=yRot,z=0})
    _spawnOneFromBag('Neutral Fighter',   p( 1.2,  0.2), {x=0,y=yRot,z=0})
    _spawnOneFromBag('Neutral Fighter',   p( 0.6,  0.6), {x=0,y=yRot,z=0})
    _spawnOneFromBag('Neutral Fighter',   p(-0.6,  0.6), {x=0,y=yRot,z=0})
    _spawnOneFromBag('Neutral Fighter',   p(-1.2,  0.2), {x=0,y=yRot,z=0})
end

-------------------------------------------------------------------------------
-- Fracture tiles helper (MOVE ONLY: no flip, no rotation, no nudge)
-- Still waits for all tiles to lock, then spawns Neutral units after a delay.
-------------------------------------------------------------------------------

local NEUTRAL_SPAWN_DELAY_SECONDS = 1.5

function placeFractureTilesFromContainer()
    local container = _getByName('Fracture')
    if not container then
        print('[Fracture] WARNING: container "Fracture" not found; skipping placement.')
        return
    end

    local pc = tonumber(_config.playerCount) or 0

    -- Positions for 4-6 players
    local tiles_4to6 = {
        { guid = "d12964", pos = {x=-15.75, y=1.13, z=15.16} },
        { guid = "6e69cb", pos = {x=-10.50, y=1.13, z=18.20} },
        { guid = "bf2378", pos = {x=-5.25,  y=1.13, z=21.22} },
        { guid = "ada29d", pos = {x=0.00,   y=1.13, z=24.25} },
        { guid = "1e7722", pos = {x=5.25,   y=1.13, z=21.22} },
        { guid = "5a91ee", pos = {x=10.50,  y=1.13, z=18.20} },
        { guid = "8d90cf", pos = {x=15.75,  y=1.13, z=15.16} },
    }

    -- Positions for 7-8 players
    local tiles_7to8 = {
        { guid = "d12964", pos = {x=-15.75, y=1.13, z=21.22} },
        { guid = "6e69cb", pos = {x=-10.50, y=1.13, z=24.25} },
        { guid = "bf2378", pos = {x=-5.25,  y=1.13, z=27.28} },
        { guid = "ada29d", pos = {x=0.00,   y=1.13, z=30.31} },
        { guid = "1e7722", pos = {x=5.25,   y=1.13, z=27.28} },
        { guid = "5a91ee", pos = {x=10.50,  y=1.13, z=24.25} },
        { guid = "8d90cf", pos = {x=15.75,  y=1.13, z=21.22} },
    }

    -- Decide which layout to use
    local tiles = nil
    if pc >= 4 and pc <= 6 then
        tiles = tiles_4to6
    elseif pc == 7 or pc == 8 then
        tiles = tiles_7to8
    else
        print('[Fracture] Player count '..tostring(pc)..' unsupported; skipping Fracture placement.')
        return
    end

    print("[Fracture] Placing seven Fracture tiles... (move only, then lock)")

    local inContainer = {}
    for _, entry in ipairs(container.getObjects()) do
        inContainer[entry.guid] = true
    end

    local totalToLock = #tiles
    local lockedCount = 0
    local function markLocked()
        lockedCount = lockedCount + 1
    end

    local function moveAndLock(obj, targetPos)
        if not obj then return end
        obj.setLock(false)
        -- Move to target position; do not rotate/flip/nudge
        if obj.setPositionSmooth then
            obj.setPositionSmooth(targetPos, false, false)
        else
            obj.setPosition(targetPos)
        end
        -- Lock after a tiny delay to allow physics/smoothing to complete
        Wait.frames(function()
            if obj and obj.setLock then obj.setLock(true) end
            markLocked()
        end, 2)
    end

    local function placeOne(t)
        if inContainer[t.guid] then
            container.takeObject({
                guid     = t.guid,
                position = t.pos,
                smooth   = false,
                callback_function = function(obj)
                    moveAndLock(obj, t.pos)
                end
            })
        else
            local o = getObjectFromGUID(t.guid)
            if o then
                moveAndLock(o, t.pos)
            else
                print("[Fracture] WARNING: Could not find tile GUID "..tostring(t.guid))
                -- Consider it "locked" anyway to avoid stalling the wait.
                markLocked()
            end
        end
    end

    for _, t in ipairs(tiles) do
        placeOne(t)
        coroutine.yield(0)
    end

    -- After all tiles have locked, pause, then spawn Neutral units.
    Wait.condition(
        function()
            print(string.format("[Fracture] All tiles locked. Spawning Neutral units in %.1fs...", NEUTRAL_SPAWN_DELAY_SECONDS))
            Wait.time(function()
                placeNeutral2Cruisers2InfantryAtD12964()
                placeNeutralForAda29d()
                placeNeutralFor8d90cf()
            end, NEUTRAL_SPAWN_DELAY_SECONDS)
        end,
        function()
            return lockedCount >= totalToLock
        end
    )
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

-- (Reference) GUIDs and positions:
-- 4-6 players:
-- d12964 -> -15.75, 1.13, 15.16
-- 6e69cb -> -10.50, 1.13, 18.20
-- bf2378 ->  -5.25, 1.13, 21.22
-- ada29d ->   0.00, 1.13, 24.25
-- 1e7722 ->   5.25, 1.13, 21.22
-- 5a91ee ->  10.50, 1.13, 18.20
-- 8d90cf ->  15.75, 1.13, 15.16

-- 7-8 players:
-- d12964 -> -15.75, 1.13, 21.22
-- 6e69cb -> -10.50, 1.13, 24.25
-- bf2378 ->  -5.25, 1.13, 27.28
-- ada29d ->   0.00, 1.13, 30.31
-- 1e7722 ->   5.25, 1.13, 27.28
-- 5a91ee ->  10.50, 1.13, 24.25
-- 8d90cf ->  15.75, 1.13, 21.22