-- TI4 Map Building Tool by Cruix
-- @author Cruix
-- @author Darrell (August 2020 update)
-- #include <~/CrLua/Objects/TI4_Map_Tool>

-- Maps are stored in a string by their tile numbers,
-- starting directly above Mecatol Rex and moving in
-- a clockwise spiral.

-- The map string MAY begin with "{#}" which sets the center system to tile #.

-- Tiles are retrieved by their GUIDs, so any tiles that
-- are deleted and replaced with a new GUID will need to
-- have their information updated in System Helper.

-- Nested tables are considered cross script.  Make a local copy.
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
        return function(parameters) return copyTable(helperObject.call(functionName, parameters)) end
    end
    return setmetatable({}, { __index = function(t, k) return getCallWrapper(k) end })
end
local _buttonHelper = getHelperClient('TI4_BUTTON_HELPER')
local _deckHelper = getHelperClient('TI4_DECK_HELPER')
local _exploreHelper = getHelperClient('TI4_EXPLORE_HELPER')
local _factionHelper = getHelperClient('TI4_FACTION_HELPER')
local _setupHelper = getHelperClient('TI4_SETUP_HELPER')
local _systemHelper = getHelperClient('TI4_SYSTEM_HELPER')
local _zoneHelper = getHelperClient('TI4_ZONE_HELPER')

local INPUT_LABEL_MAP_STRING = "Enter map string or press 'save' to save the current map"
local SLICE_DATALABEL_NAME = "slice_data_label"
local TILE_LIMIT = 1000  -- full 4 ring map is 61, 8 is 217
local MECATOL_TILE, MECATOL_GUID = 18, '3442d7'
local TE_MECATOL_TILE, TE_MECATOL_GUID = 112, '71a41f'
local currentRex = 112

local CUSTODIANS_TOKEN_GUID = '70642f'

-- Check these first when looking for tiles.  Otherwise look in SYSTEM_BAG_GUIDS.
local RED_BAG_GUID = 'a22bfb'
local BLUE_BAG_GUID = 'da323e'
local GREEN_BAG_GUID = 'c94fbe'
local FRACTURE_BAG_GUID = '524204'
local HYPERLANE_BAG_GUID = '60444a'
local REX_BAG_GUID = 'ef04ca' --The Setup bag
local POK_BAG_GUID, TE_BAG_GUID = '5ae03c', 'db288e'

local SYSTEM_BAG_GUIDS = {
    RED_BAG_GUID,
    BLUE_BAG_GUID,
    HYPERLANE_BAG_GUID,
    GREEN_BAG_GUID,
    FRACTURE_BAG_GUID,
    REX_BAG_GUID,
    POK_BAG_GUID,--Lets us build pre-made maps even when PoK or TE are not checked during settup (Tiles are moved into these containers)
    TE_BAG_GUID,
    "a9f343",  -- Hybrid Franken hexes
    "223e51",  -- Alister systems
    "f69885",  -- Pick-a-planet
    "cb9a22",  -- TI3 systems
}

local _mapString = false
local _autoClearCards = false

-- Remember which tiles got cloned for repeated map string entries.
local _tileClonesGuidSet = {}
local _hasCloneMenuGuidSet = {}

local _clones = false

-------------------------------------------------------------------------------

function swapRexTilesCo()
    local rexBag = getObjectFromGUID(REX_BAG_GUID)
    local curRex = getObjectFromGUID(currentRex == MECATOL_TILE and MECATOL_GUID or TE_MECATOL_GUID)
    if rexBag == nil or curRex == nil then return end

    local newRex = currentRex == MECATOL_TILE and TE_MECATOL_GUID or MECATOL_GUID
    local takePos = rexBag.getPosition() takePos.y = takePos.y + 2
    local function onSpawn(obj) obj.setLock(true) end
    for _,each in ipairs(rexBag.getObjects()) do
        if each.guid == newRex then
            newRex = rexBag.takeObject({
                guid = newRex,
                position = takePos,
                rotation = {0, 180 ,0}, --180 is normal facing for systems
                smooth = false,
                callback_function = onSpawn
            })
            coroutine.yield() coroutine.yield()
            break
        end
    end
    if type(newRex) == "string" then --Look on the table if it wasn't in bag
        for _,each in ipairs(getAllObjects()) do
            if each.getGUID() == newRex then newRex = each break end
        end
    end
    if type(newRex) == "string" then
        print("Could not find the replacement Mecatol Rex tile")
        return 1
    end

    currentRex = currentRex == TE_MECATOL_TILE and MECATOL_TILE or TE_MECATOL_TILE

    local custodiansToken = getObjectFromGUID(CUSTODIANS_TOKEN_GUID)
    if custodiansToken ~= nil then custodiansToken.setLock(true) end

    newRex.setLock(false)
    newRex.setPositionSmooth(curRex.getPosition(), false, true)
    curRex.setLock(false)
    curRex.setPositionSmooth(takePos, false, true)

    local _waiting, _timedOut = true, false
    Wait.time(function() _timedOut = true end, 4)
    while _waiting do
        coroutine.yield()
        if newRex == nil or _timedOut then
            _waiting = false
        else
            _waiting = newRex.isSmoothMoving()
            if not _waiting then
                coroutine.yield()
                newRex.setLock(true)
            end
        end
    end

    if custodiansToken ~= nil then custodiansToken.setLock(false) end
    return 1
end

--Sets Mecatol target internally and swaps physical hexes
function useLegendaryRex(use)
    local target = use and TE_MECATOL_TILE or MECATOL_TILE
    if currentRex == target then return end

    startLuaCoroutine(self, "swapRexTilesCo")
end

-- Expose a function for outsiders (and self) to set the map string.
function setMapString(mapString)
    assert(type(mapString) == 'string')

    -- Update visible string (would be nice to have a stable id for lookup).
    for _, input in ipairs(self.getInputs() or {}) do
        if input.label == INPUT_LABEL_MAP_STRING then
            input.value = mapString
            self.editInput(input)
        end
    end

    broadcastToAll('Setting map string to ' .. mapString)
    _mapString = mapString
end

-- Expose a function for outsiders (and self) to read the map string.
function getMapString()
    return _mapString or ''
end

-------------------------------------------------------------------------------

function onLoad(saveState)
    createInputs()

    self.addContextMenuItem('Add Clone To Tiles', addCloneMenuOptionToSystemTiles)
    self.addContextMenuItem('Rotate Map 180', rotateMap180)
    self.addContextMenuItem('Rotate Hyperlanes 180', rotateHyperlanes)
    self.addContextMenuItem('Spawn Premade Map', spawnPremadeMap)

    -- If any clones are still on the table, add them to the systems table.
    _clones = (saveState and string.len(saveState) > 0 and JSON.decode(saveState)) or {}
    for _, clone in ipairs(_clones) do
        if getObjectFromGUID(clone.guid) then
            _systemHelper.injectSystem(clone)
        end
    end
    if #_clones > 0 then
        print('Map tool: registering ' .. (#_clones) .. ' cloned system tiles')
    end
end

function onSave()
    -- Only save clones still on table.
    local activeClones = {}
    for _, clone in ipairs(_clones) do
        if getObjectFromGUID(clone.guid) then
            table.insert(activeClones, clone)
        end
    end
    return JSON.encode(activeClones)
end

-------------------------------------------------------------------------------

function onObjectDestroy(dyingObject)
    local guid = dyingObject.getGUID()
    if guid and _hasCloneMenuGuidSet[guid] then
        _hasCloneMenuGuidSet[guid] = nil
    end
end

function addCloneMenuOptionToSystemTiles()
    local guidToSystem = _systemHelper.systems()
    for _, object in ipairs(getAllObjects()) do
        local guid = object.getGUID()
        local system = guidToSystem[guid]
        if system and not _hasCloneMenuGuidSet[guid] then
            local function cloneSystemTile()
                local position = object.getPosition()
                position.y = position.y + 5
                local rotation = object.getRotation()
                _cloneSystem(system, position, rotation, false)
            end
            object.addContextMenuItem('Clone System Tile', cloneSystemTile)
            _hasCloneMenuGuidSet[guid] = true
        end
    end
end

function rotateMap180()
    for system, object in pairs(getPlacedSystemToObject(false)) do
        object.setLock(false)
        local collide = false
        local fast = true

        local p = object.getPosition()
        p = {
            x = -p.x,
            y = p.y + 1,
            z = -p.z
        }
        object.setPositionSmooth(p, collide, fast)

        if system.hyperlane then
            local r = object.getRotation()
            r = {
                x = 0,
                y = (r.y + 180) % 360,
                z = 0
            }
            object.setRotationSmooth(r, collide, fast)
        end
    end
    local function delayedLock()
        for system, object in pairs(getPlacedSystemToObject(false)) do
            _systemHelper.lockSystemTile(object.getGUID())
        end
    end
    Wait.time(delayedLock, 5)
end

function rotateHyperlanes()
    for system, object in pairs(getPlacedSystemToObject(false)) do
        object.setLock(false)
        local collide = false
        local fast = true

        if system.hyperlane then
            local r = object.getRotation()
            r = {
                x = 0,
                y = (r.y + 180) % 360,
                z = 0
            }
            object.setRotationSmooth(r, collide, fast)
        end
    end
    local function delayedLock()
        for system, object in pairs(getPlacedSystemToObject(false)) do
            _systemHelper.lockSystemTile(object.getGUID())
        end
    end
    Wait.time(delayedLock, 5)
end

-------------------------------------------------------------------------------

function createInputs()
    local buttonY = 0.2
    local buttonWidthMajor = 435
    local buttonWidthMinor = 100
    local buttonHeightMajor = 200
    local buttonHeightMinor = 100
    local fontSizeMajor = 100
    local fontSizeMinor = 60
    local majorX = 0.9

    self.createInput({
        input_function = 'onInputMapString',
        function_owner = self,
        position       = {x=0, y=buttonY, z=-0.2},
        width          = 1250,
        height         = 250,
        font_size      = fontSizeMinor,
        validation     = 1,
        alignment      = 2,
        value          = '',
        label          = INPUT_LABEL_MAP_STRING
    })
    self.createButton({
        click_function = 'onButtonBuild',
        function_owner = self,
        label          = 'Build',
        position       = {x=0, y=buttonY, z=0.33},
        width          = buttonWidthMajor,
        height         = buttonHeightMajor,
        font_size      = fontSizeMajor,
        tooltip        = 'Build map from current string'
    })
    self.createButton({
        click_function = 'onButtonSave',
        function_owner = self,
        label          = 'Save',
        position       = {x=0, y=buttonY, z=0.75},
        width          = buttonWidthMajor,
        height         = buttonHeightMajor,
        font_size      = fontSizeMajor,
        tooltip        = 'Update map string based on current system tile layout'

    })
    self.createButton({
        click_function = 'onButtonPlaceCards',
        function_owner = self,
        label          = 'Place Cards',
        position       = {x=-majorX, y=buttonY, z=0.33},
        width          = buttonWidthMajor,
        height         = buttonHeightMajor,
        font_size      = fontSizeMinor,
        tooltip        = 'Place cards on planets'
    })
    self.createButton({
        click_function = 'onButtonReturnCards',
        function_owner = self,
        label          = 'Return Cards',
        position       = {x=-majorX, y=buttonY, z=0.75},
        width          = buttonWidthMajor,
        height         = buttonHeightMajor,
        font_size      = fontSizeMinor,
        tooltip        = 'Return planet cards to deck'
    })
    self.createButton({
        click_function = 'onButtonClearTiles',
        function_owner = self,
        label          = 'Clear',
        position       = {x=majorX, y=buttonY, z=0.75},
        width          = buttonWidthMajor,
        height         = buttonHeightMajor,
        font_size      = fontSizeMajor,
        tooltip        = 'Return system tile to bags'
    })
    self.createButton({
        click_function = 'onButtonPlaceFrontier',
        function_owner = self,
        label          = 'Place\nFrontier Tokens',
        position       = {x=majorX, y=buttonY, z=0.33},
        width          = buttonWidthMajor,
        height         = buttonHeightMajor,
        font_size      = fontSizeMinor,
        tooltip        = 'Place Frontier tokens on zero-planet systems'
    })
    self.createButton({
        click_function = 'onButtonDrawLines',
        function_owner = self,
        label          = 'Draw\nLines',
        position       = {x=majorX, y=buttonY, z=-0.75},
        width          = buttonWidthMajor,
        height         = buttonHeightMajor,
        font_size      = fontSizeMinor,
        tooltip        = 'Redraw map rings and player zone lines'
    })

    local countZ = -0.65
    self.createButton({
        click_function = 'count_slices3',
        function_owner = self,
        label          = '3p',
        position       = {x=-1.2, y=buttonY, z=countZ},
        width          = buttonWidthMinor,
        height         = buttonHeightMinor,
        font_size      = fontSizeMinor,
        tooltip        = '3p'
    })
    self.createButton({
        click_function = 'count_slices4',
        function_owner = self,
        label          = '4p',
        position       = {x=-1, y=buttonY, z=countZ},
        width          = buttonWidthMinor,
        height         = buttonHeightMinor,
        font_size      = fontSizeMinor,
        tooltip        = '4p'
    })
    self.createButton({
        click_function = 'count_slices5',
        function_owner = self,
        label          = '5p',
        position       = {x=-0.8, y=buttonY, z=countZ},
        width          = buttonWidthMinor,
        height         = buttonHeightMinor,
        font_size      = fontSizeMinor,
        tooltip        = '5p'
    })
    self.createButton({
        click_function = 'count_slices6',
        function_owner = self,
        label          = '6p',
        position       = { x=-0.6, y=buttonY, z=countZ},
        width          = buttonWidthMinor,
        height         = buttonHeightMinor,
        font_size      = fontSizeMinor,
        tooltip        = '6p'
    })
    self.createButton({
        click_function = 'count_slices7',
        function_owner = self,
        label          = '7p',
        position       = { x=-0.4, y=buttonY, z=countZ},
        width          = buttonWidthMinor,
        height         = buttonHeightMinor,
        font_size      = fontSizeMinor,
        tooltip        = '7p'
    })
    self.createButton({
        click_function = 'count_slices8',
        function_owner = self,
        label          = '8p',
        position       = { x=-0.2, y=buttonY, z=countZ},
        width          = buttonWidthMinor,
        height         = buttonHeightMinor,
        font_size      = fontSizeMinor,
        tooltip        = '8p'
    })
    self.createButton({
        click_function = 'clear_slicelabels',
        function_owner = self,
        label          = 'Clear',
        position       = {x=0.06, y=buttonY, z=countZ},
        width          = 160,
        height         = buttonHeightMinor,
        font_size      = fontSizeMinor,
    })
    self.createButton({
        click_function = 'pass',
        function_owner = self,
        label          = 'Count Resources',
        position       = {x=-0.85, y=buttonY, z=-0.85},
        width          = 0,
        height         = 0,
        font_size      = fontSizeMinor,
    })

    -- Add a confirm step to come buttons.
    for _, buttonIndex in ipairs({ 0, 2, 3, 4, 5 }) do
        _buttonHelper.addConfirmStep({
            guid = self.getGUID(),
            buttonIndex = buttonIndex,
            confirm = {
                label = 'CLICK AGAIN\nTO CONFIRM',
                font_size = fontSizeMajor * 6 / 10,
                -- color = string
            }
        })
    end
end

function pass() end

--Any home system tile that does not match an unpacked faction
local function isMinorFactionSystem(system, obj)
        if not system or not system.home then return false end

        local factionsInPlay = _factionHelper.allFactions()
        for _,each in pairs(factionsInPlay or {}) do
            if system.tile == each.home or (obj ~= nil and each.offMapHome and obj.getName() == each.offMapHome) then
                return false
            end
        end
        return true
end

-------------------------------------------------------------------------------
-- Map building stuff
-------------------------------------------------------------------------------

function onInputMapString(_, _, input)
    _mapString = input
end

function onButtonBuild(_, color)
    startLuaCoroutine(self, 'placeTilesCoroutine')
end

function placeTilesCoroutine()
    local mapString = getMapString()
    broadcastToAll('Building map from string: ' .. mapString)

    local buildList = parseMapString(mapString)

    -- Lift the custudians token, (re)place it when finished.
    local custodiansToken = getObjectFromGUID(CUSTODIANS_TOKEN_GUID)
    if custodiansToken then
        local p = custodiansToken.getPosition() + vector(0, 5, 0)
        custodiansToken.setPosition(p)
        custodiansToken.setLock(true)
    end
    coroutine.yield(0)

    -- If map string does not start with Mecatol put it away.
    if (#buildList > 0) and (buildList[1].tile ~= TE_MECATOL_TILE and buildList[1].tile ~= MECATOL_TILE) then
        local mecatolTile = getObjectFromGUID(currentRex == MECATOL_TILE and MECATOL_GUID or TE_MECATOL_GUID)
        local rexBag = getObjectFromGUID(REX_BAG_GUID)
        if mecatolTile ~= nil and rexBag ~= nil then
            mecatolTile.setLock(false)
            rexBag.putObject(mecatolTile)
            coroutine.yield(0)
            coroutine.yield(0)
        end
    end

    -- Move home systems.
    _moveHomeSystems(buildList)
    coroutine.yield(0)

    -- Build a map from tile number to system.
    local guidToSystem = _systemHelper.systems()
    local tileToSystem = {}
    for _, system in pairs(guidToSystem) do
        tileToSystem[system.tile] = system
    end

    --Check if this map uses PoK/TE tiles when Pok/TE were not checked during settup (we will need to return planet cards to the deck)
    local _sourcesToCheck, _sourcesToReturn = {}, {}
    if not _setupHelper.getPoK() then _sourcesToCheck.PoK = true end
    if not _setupHelper.getTE() then _sourcesToCheck.TE = true end
    if next(_sourcesToCheck) then
        for i,each in ipairs(buildList) do
            local source = (tileToSystem[each.tile] or {}).source or "base"
            if _sourcesToCheck[source] then
                _sourcesToCheck[source] = nil
                _sourcesToReturn[source] = true
                if not next(_sourcesToCheck) then break end
            end
        end
    end
    if next(_sourcesToReturn) then
        local _planetsDeck = getObjectFromGUID(_deckHelper.getDeck("Planets") or "")
        local _legendaryDeck = getObjectFromGUID(_deckHelper.getDeck("Legendary Abilities") or "")
        for source,_ in pairs(_sourcesToReturn)do
            local box = getObjectFromGUID(source == 'PoK' and POK_BAG_GUID or TE_BAG_GUID)
            for i,each in ipairs((box and box.getObjects() or {})) do
                if each.name == source.." Planets" then
                    local function onSpawn(obj) if _planetsDeck then _planetsDeck.putObject(obj) else obj.setName("Planets") end end
                    local pos = _planetsDeck and _planetsDeck.getPosition() or _deckHelper.getDeckTransform("Planets").position
                    pos.y = pos.y + (i*3)
                    box.takeObject({
                        position = pos,
                        guid = each.guid,
                        smooth = false,
                        callback_function = onSpawn
                    })
                elseif each.name == source.." Legendary Abilities" then
                    local function onSpawn(obj) if _legendaryDeck then _legendaryDeck.putObject(obj) else obj.setName("Legendary Abilities")end end
                    local pos = _legendaryDeck and _legendaryDeck.getPosition() or _deckHelper.getDeckTransform("Legendary Abilities").position
                    pos.y = pos.y + (i*3)
                    box.takeObject({
                        position = pos,
                        guid = each.guid,
                        smooth = false,
                        callback_function = onSpawn
                    })
                end
            end
        end
    end

    -- Build a map from system guid to container.
    local systemGuidToBag = {}
    for _, bagGuid in ipairs(SYSTEM_BAG_GUIDS) do
        local bag = getObjectFromGUID(bagGuid)
        if bag and bag.tag == 'Bag' then
            for _, entry in ipairs(bag.getObjects()) do
                systemGuidToBag[entry.guid] = bag
            end
        end
    end
    coroutine.yield(0)

    local placedTileSet = {}
    local positionIterator = getSystemPositionsStartingAtOriginIterator(0.3)
    for i, buildEntry in ipairs(buildList) do
        local position = positionIterator()
        local tile, ab, rotation = buildEntry.tile, buildEntry.ab, buildEntry.rotation
        if rotation then
            rotation = rotation * 60
            rotation = rotation + 180 -- 0 rotation is upside down for default player position
            rotation = rotation % 360
            rotation = { x = 0, y = rotation, z = ab == 'B' and 180 or 0 }
        else
            rotation = { x = 0, y = 180, z = ab == 'B' and 180 or 0}
        end
        if tile > 0 then
            local system = tileToSystem[tile]
            if system then
                if placedTileSet[tile] then
                    _cloneSystem(system, position, rotation, true)
                else
                    placedTileSet[tile] = true
                    local bag = systemGuidToBag[system.guid]
                    placeTile(system, bag, position, rotation)
                end
            else
                broadcastToAll('unknown system tile ' .. tile, 'Red')
            end
            coroutine.yield(0)
        end
    end

    -- Release custodians token, move to mecatol location if present.
    if custodiansToken then
        local mecatolTile = getObjectFromGUID(currentRex == TE_MECATOL_TILE and TE_MECATOL_GUID or MECATOL_GUID)
        if mecatolTile then
            while mecatolTile.isSmoothMoving() do
                coroutine.yield(0)
            end
            local p = mecatolTile.getPosition() + vector(0, 5, 0)
            custodiansToken.setLock(false)
            custodiansToken.setPositionSmooth(p)
        else
            custodiansToken.setLock(false)
            local bag = getObjectFromGUID(REX_BAG_GUID)
            bag.putObject(custodiansToken)
            print("Mecatol Rex was not detected, the Custodians Token has been placed in the Setup bag.")
        end
    end

    printToAll('Builing map finished')
    return 1
end

local function delayedLock(object)
    object.use_hands = false
    local guid = object.getGUID()
    Wait.time(function() _systemHelper.lockSystemTile(guid) end, 3)
end

function placeTile(system, bag, position, rotation)
    assert(type(system) == 'table' and (not bag or type(bag) == 'userdata'))
    assert(type(position) == 'table' and type(rotation) == 'table')

    local object = false
    if bag then
        object = bag.takeObject({
            position          = position,
            rotation          = rotation,
            callback_function = delayedLock,
            smooth            = true,
            guid              = system.guid
        })
        assert(object)
    else
        -- Look on table for object.
        object = getObjectFromGUID(system.guid)
        if object then
            object.setLock(false)
            local collide = false
            local fast = true
            object.setPositionSmooth(position, collide, fast)
            object.setRotationSmooth(rotation, collide, fast)
            delayedLock(object)
        else
            broadcastToAll('cannot find system tile for ' .. system.string, 'Red')
        end
    end
end

-- Expose for outside callers.
function cloneSystem(params)
    assert(type(params.system) == 'table')
    assert(type(params.position) == 'table')
    assert(type(params.rotation) == 'table')
    assert(type(params.lock) == 'boolean')
    _cloneSystem(params.system, params.position, params.rotation, params.lock)
end

function _cloneSystem(system, position, rotation, lock)
    assert(type(system) == 'table' and type(position) == 'table' and type(rotation) == 'table' and type(lock) == 'boolean')
    local primary = assert(getObjectFromGUID(system.guid))

    -- Clone the system tile object.
    local clone = primary.clone({
        position = {
            x = position.x,
            y = position.y + 3,
            z = position.z
        },
        snap_to_grid = true,
    })
    clone.setLock(false)
    local collide = false
    local fast = true
    clone.setPositionSmooth(position, collide, fast)
    clone.setRotationSmooth(rotation, collide, fast)
    if lock then
        delayedLock(clone)
    end

    local function cloneReady()
        return clone.getGUID() ~= system.guid
    end

    local function injectClone()
        _tileClonesGuidSet[clone.getGUID()] = true

        -- Add to system helper.  Keep the same tile number for map string generation.
        local clonedSystem = {}
        for k, v in pairs(system) do
            if k == 'guid' then
                clonedSystem.guid = clone.getGUID()
            else
                clonedSystem[k] = v
            end
        end
        table.insert(_clones, clonedSystem)
        _systemHelper.injectSystem(clonedSystem)
    end

    Wait.condition(injectClone, cloneReady)
end

function onButtonClearTiles(_, color)
    startLuaCoroutine(self, 'clearTilesCoroutine')
end

--NOTE: Does not clear fracture systems
function clearTilesCoroutine()
    -- Also put away any Frontier and planet cards.
    coroutine.yield(0)
    if _setupHelper.getPoK() then _exploreHelper.retrieveFrontierTokens() end
    if _autoClearCards then
        returnCardsCoroutine()
    end

    broadcastToAll('Returning tiles')
    local redBag = getObjectFromGUID(RED_BAG_GUID)
    local blueBag = getObjectFromGUID(BLUE_BAG_GUID)
    local greenBag = getObjectFromGUID(GREEN_BAG_GUID)
    local hyperlaneBag = getObjectFromGUID(HYPERLANE_BAG_GUID)
    if redBag == nil then
        broadcastToAll('Cannot find red planet tiles bag')
    end
    if blueBag == nil then
        broadcastToAll('Cannot find blue planet tiles bag')
    end
    if hyperlaneBag == nil then
        broadcastToAll('Cannot find hyperlane tiles bag')
    end

    local pokBag = not _setupHelper.getPoK() and getObjectFromGUID(POK_BAG_GUID) or false
    local teBag = not _setupHelper.getTE() and getObjectFromGUID(TE_BAG_GUID)

    --- Returns tiles to their expansion box if that expansion is not in use; otherwise returns them to the given target bag
    local function _putIfUsing(targetBag, system)
        return system and ((system.source == 'PoK' and pokBag) or (system.source == 'TE' and teBag)) or targetBag
    end

    for system, object in pairs(getPlacedSystemToObject(false)) do
        local guid = object.getGUID()
        if _tileClonesGuidSet[guid] then
            _tileClonesGuidSet[guid] = nil
            _safeDestroyObject(object)
        else
            if (not system.fracture and (not system.home or isMinorFactionSystem(system, object))) then
                local bag = false
                if system.tile == TE_MECATOL_TILE or system.tile == MECATOL_TILE then
                    --Only clear Rex if it is not in the center or is not our target Rex
                    local p = object.getPosition()
                    local d = math.abs(p.x + p.z)
                    if system.tile ~= currentRex or d > 1 then
                        bag = assert(getObjectFromGUID(REX_BAG_GUID), "Tried to put a Rex away, but could not locate the Setup bag")
                    end
                elseif system.home then --Only minor faction tiles have made it here
                    bag = greenBag
                elseif system.hyperlane then
                    bag = hyperlaneBag
                elseif system.planets and #system.planets > 0 then
                    if (system.anomalies and #system.anomalies > 0) then
                        bag = _putIfUsing(redBag, system)
                    else
                        bag = _putIfUsing(blueBag, system)
                    end
                else
                    bag = _putIfUsing(redBag, system)
                end
                if bag then
                    object.setLock(false)
                    object.use_hands = true
                    bag.putObject(object)
                end
            end
        end
        coroutine.yield(0)
    end

    return 1
end

-------------------------------------------------------------------------------
-- Map saving stuff
-------------------------------------------------------------------------------

function onButtonSave(_, color)
    broadcastToAll('Saving map')
    startLuaCoroutine(self, 'saveTilesCoroutine')
end

--Fracture tiles are ommitted
function saveTilesCoroutine()
    -- Get tile numbers and positions, convert to hexes.
    local systemToObject = getPlacedSystemToObject(false)
    local guidToTile = {}
    local guidToPosition = {}
    for system, object in pairs(systemToObject) do
        if not system.fracture then
            local guid = assert(system.guid)
            local tile = system.tile
            if system.hyperlane then
                local rotation = object.getRotation().y
                rotation = rotation - 180  -- 180 is "normal", make 0 based for value
                rotation = (rotation + 360) % 360
                rotation = rotation + 15  -- in case not exact, gets closest
                tile = tile .. (object.is_face_down and 'B' or 'A')
                tile = tile .. math.floor(rotation / 60)
            end
            guidToTile[guid] = tile
            guidToPosition[guid] = object.getPosition()
        end
    end
    coroutine.yield(0)

    -- Add home system placeholders.
    for _, object in ipairs(getAllObjects()) do
        local color = string.match(object.getName(), '^Home System Location %((.*)%)$')
        if color then
            local guid = object.getGUID()
            guidToTile[guid] = 0
            guidToPosition[guid] = object.getPosition()
        end
    end
    coroutine.yield(0)

    -- Translate positions to hexes.
    local guidToHex = _systemHelper.hexesFromPositions(guidToPosition)

    -- Fill map from hex to map string index.
    local indexToPosition = {}
    local positionIterator = getSystemPositionsStartingAtOriginIterator()
    for _ = 1, TILE_LIMIT do
        table.insert(indexToPosition, assert(positionIterator()))
    end
    local indexToHex = _systemHelper.hexesFromPositions(indexToPosition)
    local hexToMapStringIndex = {}
    for i, hex in ipairs(indexToHex) do
        hexToMapStringIndex[hex] = i
    end
    coroutine.yield(0)

    -- Merge in a table (not a list, might have holes!)
    local result = {}
    local maxIndex = 0
    for guid, hex in pairs(guidToHex) do
        local index = hexToMapStringIndex[hex]  -- can be missing if past TILE_LIMIT
        local tile = assert(guidToTile[guid], 'missing tile ' .. guid)
        if index and tile then
            result[index] = tile
            maxIndex = math.max(maxIndex, index)
        end
    end
    coroutine.yield(0)

    -- Make it a list (fill in any holes with -1).
    for i = 1, maxIndex do
        if not result[i] then
            result[i] = -1
        end
    end
    coroutine.yield(0)

    -- If the center tile is Mecatol remove it, otherwise do special encoding.
    if #result > 0 then
        if result[1] == TE_MECATOL_TILE or result[1] == MECATOL_TILE then
            table.remove(result, 1)
        else
            result[1] = '{' .. result[1] .. '}'
        end
    end

    setMapString(table.concat(result, ' '))
    return 1
end

-------------------------------------------------------------------------------
-- Card stuff
-------------------------------------------------------------------------------

function onButtonPlaceCards(_, color)
    startLuaCoroutine(self, 'placeCardsCoroutine')
end

--- Get card guids, or deck+card guids when inside a deck.
local function getPlanetNameToCardDeckGuid()
    local planetNameSet = {}
    for _, planet in pairs(_systemHelper.planets()) do
        planetNameSet[planet.name] = true
        if planet.legendaryCard then
            planetNameSet[planet.legendaryCard] = true
        end
    end

    local planetNameToCardOrDeckAndEntryGuid = {}
    local extras = {}

    local function addResult(name, value)
        if planetNameToCardOrDeckAndEntryGuid[name] then
            -- Already have this planet.
            table.insert(extras, value)
        else
            planetNameToCardOrDeckAndEntryGuid[name] = value
        end
    end

    for _, object in ipairs(getAllObjects()) do
        local name = object.getName()
        if object.tag == 'Card' and planetNameSet[name] then
            addResult(name, {
                cardGuid = object.getGUID(),
                deckGuid = nil
            })
        elseif object.tag == 'Deck' then
            for _, entry in ipairs(object.getObjects()) do
                if planetNameSet[entry.name] then
                    addResult(entry.name, {
                        cardGuid = entry.guid,
                        deckGuid = object.getGUID()
                    })
                end
            end
        end
    end

    return planetNameToCardOrDeckAndEntryGuid, extras
end

function placeCardsCoroutine()
    broadcastToAll('Placing planet cards')
    _autoClearCards = true

    -- Find all card locations in a single pass, then place cards.
    local planetNameToCardDeckGuid = getPlanetNameToCardDeckGuid()
    coroutine.yield(0)

    -- Make sure system tiles are locked, and no longer drawable into hands.
    for system, object in pairs(getPlacedSystemToObject(false)) do
        object.use_hands = false
        _systemHelper.lockSystemTile(object.getGUID())
    end

    -- Build a map from planet name to positionS plural, in case repeated.
    local planetToTransforms = {}
    for system, object in pairs(getPlacedSystemToObject(true)) do
        if not system.home or isMinorFactionSystem(system, object) then
            for _, planet in ipairs(system.planets or {}) do
                local entry = planetToTransforms[planet.name]
                if not entry then
                    entry = {}
                    planetToTransforms[planet.name] = entry
                end
                local pos = object.positionToWorld(planet.position)
                local rot = object.getRotation()
                table.insert(entry, {
                    position = { x = pos.x, y = pos.y + 3, z = pos.z },
                    rotation = { x = rot.x, y = rot.y, z = 180 }
                })

                -- Add legendary cards as "planetName", below will place them.
                if planet.legendaryCard then
                    local entry = planetToTransforms[planet.legendaryCard]
                    if not entry then
                        entry = {}
                        planetToTransforms[planet.legendaryCard] = entry
                    end
                    local pos = object.positionToWorld(planet.position)
                    local rot = object.getRotation()
                    table.insert(entry, {
                        position = { x = pos.x + 1, y = pos.y + 1, z = pos.z },
                        rotation = { x = rot.x, y = rot.y, z = 0 } -- rotating y still forms a deck b/c single cards
                    })
                end
            end
        end
    end

    -- Place cards.
    for planetName, transforms in pairs(planetToTransforms) do
        local cardDeckGuid = planetNameToCardDeckGuid[planetName]
        if cardDeckGuid then
            local card = getObjectFromGUID(cardDeckGuid.cardGuid)
            local deck = getObjectFromGUID(cardDeckGuid.deckGuid)
            for i, transform in ipairs(transforms) do
                local pos = transform.position
                local rot = transform.rotation
                if i == 1 then
                    -- The first time placing a planet get it from the source.
                    card = placeCard(pos, rot, card, deck, cardDeckGuid.cardGuid)
                    deck = false
                else
                    -- Make clones for extra copies.
                    assert(card and card.tag == 'Card')
                    local clone = card.clone({
                        position     = pos,
                        snap_to_grid = false,
                    })
                    local collide = false
                    local fast = true
                    clone.setRotationSmooth(rot, collide, fast)
                end
                coroutine.yield(0)
            end
        else
            broadcastToAll('Missing card for "' .. planetName .. '"', 'Red')
        end
    end

    -- Lift the custudians token.
    local custodiansToken = getObjectFromGUID(CUSTODIANS_TOKEN_GUID)
    if custodiansToken then
        local function delayedLiftCustodians()
            local p = custodiansToken.getPosition()
            p.y = p.y + 2
            local collide = false
            local fast = true
            custodiansToken.setPositionSmooth(p, collide, fast)
        end
        Wait.time(delayedLiftCustodians, 3)
    end

    return 1
end

function placeCard(position, rotation, card, deck, entryGuid)
    assert(type(position) == 'table' and type(rotation) == 'table')
    if deck and deck.remainder then
        if deck.remainder.getGUID() == entryGuid then
            card = deck.remainder
            deck = false
            entryGuid = false
        else
            error('deck remainder does not match card')
        end
    end

    if card then
        local collide = false
        local fast = true
        card.setPositionSmooth(position, collide, fast)
        card.setRotationSmooth(rotation, collide, fast)
    elseif deck and entryGuid then
        card = deck.takeObject({
            guid     = entryGuid,
            position = position,
            rotation = rotation,
            smooth   = true,
        })
    else
        error('no card')
    end
    return card
end

function onButtonReturnCards(_, color)
    startLuaCoroutine(self, 'returnCardsCoroutine')
end

function returnCardsCoroutine()
    broadcastToAll('Returning planet cards')
    _autoClearCards = false

    local planetNameToCardDeckGuid, extras = getPlanetNameToCardDeckGuid()
    coroutine.yield(0)

    -- Destroy any extras.
    for _, extra in ipairs(extras) do
        if extra.card then
            _safeDestroyObject(extra.card)
        else
            local deck = getObjectFromGUID(extra.deckGuid)
            deck.takeObject({
                guid = extra.entryGuid,
                callback_function = _safeDestroyObject
            })
        end
        coroutine.yield(0)
    end

    -- Get the SET of planet names, ignore duplicates (handled by extras above).
    local planetNameSet = {}
    local unpackedFactions = {} --Return HS cards if that faction is not in play (get only minor faction planets)
    for system, object in pairs(getPlacedSystemToObject(true)) do
        if not system.home or isMinorFactionSystem(system, object) then
            for _, planet in ipairs(system.planets or {}) do
                planetNameSet[planet.name] = true
                if planet.legendaryCard then
                    planetNameSet[planet.legendaryCard] = true
                end
            end
        end
    end
    coroutine.yield(0)

    local index = 1
    for planetName, _ in pairs(planetNameSet) do
        local cardDeckGuid = planetNameToCardDeckGuid[planetName]
        if cardDeckGuid then
            _deckHelper.discardCard({
                guid = cardDeckGuid.cardGuid,
                name = planetName,
                containerGuid = cardDeckGuid.deckGuid,
                index = index
            })
            index = index + 1
        else
            broadcastToAll('Missing card for "' .. planetName .. '"', 'Red')
        end
        coroutine.yield(0)
    end

    return 1
end

-------------------------------------------------------------------------------
-- Counting stuff
-------------------------------------------------------------------------------

function count_slices3(_, color)
    count_slices(3)
end

function count_slices4(_, color)
    count_slices(4)
end

function count_slices5(_, color)
    count_slices(5)
end

function count_slices6(_, color)
    count_slices(6)
end

function count_slices7(_, color)
    count_slices(7)
end

function count_slices8(_, color)
    count_slices(8)
end

function clear_slicelabels()
    local deletedItems = false
    for _, object in ipairs(getAllObjects()) do
        if object.getName() == 'TI4 Deleted Items' then
            deletedItems = object
        end
    end
    for _, object in ipairs(getAllObjects()) do
        if(object.getName() == SLICE_DATALABEL_NAME) and (object.TextTool ~= nil) then
            if deletedItems then
                deletedItems.call('ignoreGuid', object.getGUID())
            end
            destroyObject(object)
        end
    end
end

function count_slices(count)
    clear_slicelabels()

    local tileDiameter = getInscribedTileRadius() * 2
    local function labelPosition(homeSystemPosition)
        local p = homeSystemPosition
        local magnitude = math.sqrt(p.x ^ 2 + p.z ^ 2)
        local normalized = { x = p.x / magnitude, z = p.z / magnitude }
        return {
            x = p.x + normalized.x * tileDiameter * 1,
            y = p.y + 0.02,
            z = p.z + normalized.z * tileDiameter * (p.z > 0 and 0.95 or 0.60)
        }
    end

    local homeSystemPositions = _zoneHelper.getHomeSystemPositions(count)
    local equidistantPositions = {}
    for i, p1 in ipairs(homeSystemPositions) do
        local p2 = homeSystemPositions[i < #homeSystemPositions and (i + 1) or 1]
        local dir = {
            x = (p1.x + p2.x) / 2,
            y = (p1.y + p2.y) / 2,
            z = (p1.z + p2.z) / 2,
        }
        local d = math.sqrt(dir.x ^ 2 + dir.z ^ 2)
        local normalized = {
            x = dir.x / d,
            y = dir.y,
            z = dir.z / d
        }
        local d = math.sqrt(p1.x ^ 2 + p1.z ^ 2)
        local p = {
            x = normalized.x * d,
            y = normalized.y,
            z = normalized.z * d
        }
        if math.abs(p.z) < 1 then
            p.x = p.x * 0.8  -- otherwise to far out, goes under bags
        end
        table.insert(equidistantPositions, p)
    end

    local hsValue = {}
    local eqValue = {}
    for i = 1, #homeSystemPositions do
        hsValue[i] = {
            position = labelPosition(homeSystemPositions[i]),
            tiles = {},
        }
        eqValue[i] = {
            position = labelPosition(equidistantPositions[i]),
            tiles = {}
        }
    end
    local function updateValue(valueTable, system)
        assert(type(valueTable) == 'table' and type(system) == 'table')
        table.insert(valueTable.tiles, system.tile)
    end

    local function getClosestIndex(positions, targetPosition)
        local candidates = {}
        for i, position in ipairs(positions) do
            table.insert(candidates, {
                index = i,
                dSq = (position.x - targetPosition.x) ^ 2 + (position.z - targetPosition.z) ^ 2,
            })
        end
        table.sort(candidates, function(a, b) return a.dSq < b.dSq end)
        local d = candidates[2].dSq - candidates[1].dSq
        return d > 1 and candidates[1].index or false
    end

    for system, object in pairs(getPlacedSystemToObject(false)) do
        local i = getClosestIndex(homeSystemPositions, object.getPosition())
        if i then
            updateValue(hsValue[i], system)
        else
            i = getClosestIndex(equidistantPositions, object.getPosition())
            if i then
                updateValue(eqValue[i], system)
            end
        end
    end

    local function createLabel(position, rotation, textValue, fontSizeScale)
        assert(type(textValue) == 'string')
        local text = spawnObject({
            type              = '3DText',
            position          = position,
            rotation          = rotation,
            sound             = false,
        })
        text.setName(SLICE_DATALABEL_NAME)
        text.TextTool.setValue(textValue)
        text.TextTool.setFontSize(text.TextTool.getFontSize() * (fontSizeScale or 1))
    end

    for _, value in ipairs(hsValue) do
        local text = _systemHelper.summarizeTiles(value.tiles)
        createLabel(value.position, {x=90,y=0,z=0}, text, 1.5)
    end
    for _, value in ipairs(eqValue) do
        local text = '(' .. _systemHelper.summarizeTiles(value.tiles) .. ')'
        createLabel(value.position, {x=90,y=0,z=0}, text, 1)
    end
end

-------------------------------------------------------------------------------
-- Drawing stuff
-------------------------------------------------------------------------------

function onButtonDrawLines()
    _zoneHelper.drawBordersVectorLines({})
end

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local _deletedItemsBagGuid = false
function _safeDestroyObject(object)
    assert(type(object) == 'userdata')
    local deletedItems = _deletedItemsBagGuid and getObjectFromGUID(_deletedItemsBagGuid)
    if not deletedItems then
        for _, object in ipairs(getAllObjects()) do
            if object.tag == 'Bag' and object.getName() == 'TI4 Deleted Items' then
                _deletedItemsBagGuid = object.getGUID()
                deletedItems = object
                break
            end
        end
    end
    if deletedItems then
        deletedItems.call('ignoreGuid', object.getGUID())
    end
    destroyObject(object)
end

function parseMapString(input)
    assert(type(input) == 'string')
    local buildList = {}

    input = string.upper(input)

    local centerSystem, ab, rotation = string.match(input, '^{([-]?%d+)([A-H]?)(%d*)}')
    if centerSystem then
        centerSystem = assert(tonumber(centerSystem), (centerSystem .. " could not be converted to a number"))
        --Let the settup tool determine which version of Rex we are using, not the map string
        if (centerSystem == TE_MECATOL_TILE or centerSystem == MECATOL_TILE) then
            table.insert(buildList, {tile = currentRex})
        else
            table.insert(buildList, {
                tile = centerSystem,
                ab = ab,
                rotation = tonumber(rotation or 0)
            })
        end
        local a,b = string.find(input, '}')
        input = string.sub(input, b + 1)
    else 
        --If Rex is moved out of center, fill center with blank (since they failed to declare a center system above)
        if string.match(input, (TE_MECATOL_TILE..' ')) or string.match(input, (MECATOL_TILE..' ')) then
            table.insert(buildList, {tile = -1})
        else --Otherwise Put/Keep Rex in the center
            table.insert(buildList, { tile = currentRex })
        end
    end

    --layer to interpret strings from tidraft.com
    --Replaces ',' with spaces, removes ":", repalces H# with 0
    input = string.gsub(input, ',', ' ')
    input = string.gsub(input, ':','')
    input = string.gsub(input, 'H%d*', '0')

    -- %S is non-space
    for key in string.gmatch(input, '%S+') do
        local tile, ab, rotation = string.match(key, '^([-]?%d+)([A-H]?)(%d*)$')
        assert(tile, 'bad key1 "' .. key .. '"')
        local tile = tile and tonumber(tile) or tonumber(key)
        assert(tile, 'bad key2 "' .. key .. '"')
        table.insert(buildList, {
            tile = tonumber(tile),
            ab = ab,
            rotation = tonumber(rotation or 0)
        })
    end
    return buildList
end

function getTableY()
    return _zoneHelper.getTableY()
end

function getPlacedSystemToObject(includeOutsideSystems)
    assert(type(includeOutsideSystems) == 'boolean')
    local inHandGuidSet = _zoneHelper.inHand()
    local systemToObject = {}
    local guidToSystem = _systemHelper.systems()
    for _, object in ipairs(getAllObjects()) do
        if not inHandGuidSet[object.getGUID()] then
            local system = guidToSystem[object.getGUID()]
            if system and (not includeOutsideSystems) and system.offMap then
                system = false
            end
            if system then
                systemToObject[system] = object
            end
        end
    end
    return systemToObject
end

function getOutscribedTileRadius()
    local x = Grid.sizeX or 7
    local y = Grid.sizeY or 7
    assert(x == y, 'error: not a square grid')
    return x / 2.0
end

function getInscribedTileRadius()
    local r = getOutscribedTileRadius()
    local c = r
    local b = r / 2.0
    return math.sqrt(c^2 - b^2)
end

function getSystemPositionsStartingAtOriginIterator(dy)
    local tileDiameter = getInscribedTileRadius() * 2
    local function move_in_dir(start, dir)
        return {
            x = start.x + math.sin(math.rad(dir)) * tileDiameter,
            y = start.y,
            z = start.z + math.cos(math.rad(dir)) * tileDiameter
        }
    end

    local function spiral_hex_iterator(startpos, startrot)
        local level = 0
        local dir = 120
        local steps = 0
        local north = startrot.y
        local nextpos = move_in_dir(startpos, north)
        return function()
            if level == 0 then
                level = 1
                return startpos
            end
            local thispos = nextpos
            nextpos = move_in_dir(nextpos, north + dir)
            steps = steps + 1
            if steps >= level then
                steps = 0
                dir = (dir + 60) % 360
                if dir == 120 then
                    nextpos = move_in_dir(nextpos, north)
                    level = level + 1
                end
            end
            return thispos
        end
    end

    local origin = { x = 0, y = getTableY() + (dy or 0), z = 0 }
    local rotation = { x = 0, y = 0, z = 0 }
    return spiral_hex_iterator(origin, rotation)
end

function onButtonPlaceFrontier()
    _exploreHelper.placeFrontierTokens()
end

-------------------------------------------------------------------------------

-- Optimize home system placement from available positions.
function _moveHomeSystems(buildList)
    assert(type(buildList) == 'table')

    -- Get home system positions from map string.
    local mapStringInfos = {}
    local positionIterator = getSystemPositionsStartingAtOriginIterator(0.3)
    for i, buildEntry in ipairs(buildList) do
        local position = positionIterator()
        if buildEntry.tile == 0 then
            table.insert(mapStringInfos, {
                position = position,
            })
        end
    end

    -- Get player area positions.
    local zoneInfos = {}
    local seen = {}
    for _, zoneAttr in ipairs(_zoneHelper.zonesAttributes()) do
        assert(not seen[zoneAttr.color])
        seen[zoneAttr.color] = true
        table.insert(zoneInfos, {
            color = assert(zoneAttr.color),
            position = assert(zoneAttr.center)
        })
    end

    -- Get current home system positions based on movable placeholder tiles.
    local tileInfos = {}
    local seen = {}
    for _, object in ipairs(getAllObjects()) do
        local color = string.match(object.getName(), '^Home System Location %((.+)%)$')
        if color then
            assert(not seen[color])
            seen[color] = true
            table.insert(tileInfos, {
                color = color,
                object = object,
                position = object.getPosition()
            })
        end
    end

    -- Require the same number of map string home systems, home system placeholder tiles, and player areas.
    if #mapStringInfos ~= #tileInfos then
        printToAll('Map: unable to move home systems, ' .. (#mapStringInfos) .. ' in map string but ' .. (#tileInfos) .. ' home system location tiles.', 'Red')
        return false
    elseif #mapStringInfos ~= #zoneInfos then
        printToAll('Map: unable to move home systems, ' .. (#mapStringInfos) .. ' in map string but ' .. (#zoneInfos) .. ' player areas.', 'Red')
        return false
    end

    -- Optimal placement is called "the assignment problem" and is tricky.
    -- Make a simplifying assumption that tiles in clockwise order get the
    -- player zone colors in clockwise order, choosing the best start.
    local function sortFunction(a, b)
        local a = math.atan2(a.position.z, a.position.x)
        local b = math.atan2(b.position.z, b.position.x)
        return a < b
    end
    table.sort(mapStringInfos, sortFunction)
    table.sort(zoneInfos, sortFunction)
    local best = false
    local bestDistance = false
    for _ = 1, #mapStringInfos - 1 do
        local d = 0
        for i = 1, #mapStringInfos do
            local a = mapStringInfos[i].position
            local b = zoneInfos[i].position
            d = d + math.sqrt((a.x - b.x) ^ 2 + (a.z - b.z) ^ 2)
        end
        if (not best) or d < bestDistance then
            best = copyTable(mapStringInfos)
            bestDistance = d
        end
    end

    -- Move any home systems.
    local colorToTile = {}
    for _, tileInfo in ipairs(tileInfos) do
        colorToTile[tileInfo.color] = tileInfo.object
    end
    for i, entry in ipairs(best) do
        local color = assert(zoneInfos[i].color)
        local tile = assert(colorToTile[color])
        local oldHex = _systemHelper.hexFromPosition(tile.getPosition())
        local newHex = _systemHelper.hexFromPosition(entry.position)
        if oldHex ~= newHex then
            local collide = false
            local fast = true
            tile.setPositionSmooth(entry.position, collide, fast)
            _zoneHelper.updateHomeSystemPosition({
                color = color,
                position = entry.position
            })
        end
    end
end

-------------------------------------------------------------------------------

function spawnPremadeMap()
    startLuaCoroutine(self, 'spawnPremadeMapCoroutine')
end

function spawnPremadeMapCoroutine()
    saveTilesCoroutine()

    local mapString = getMapString()
    local commaDelimited = string.gsub(mapString, ' ', ',')
    local url = 'http://ti4-card-images.appspot.com/map?tiles=' .. commaDelimited
    print('url ' .. url)

    local params = {
        image = url,
        type = 3, -- rounded
        thickness = 0.1,
    }
    local tile = spawnObject({
        type              = 'Custom_Tile',
        position          = self.getPosition() + vector(0, 3, 0),
        rotation          = self.getRotation(),
        scale             = { x = 5.67, y = 1, z = 5.67 },
        sound             = false,
        params            = params,
        snap_to_grid      = false
    })
    tile.setCustomObject(params)
    tile.setName('MAP')
    tile.setDescription(mapString)
    tile.use_grid = false
    tile.use_snap_points = false

    return 1
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