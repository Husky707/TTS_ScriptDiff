-------------------------------------------------------------------------------
--- Auto-fill the TTS/TI4 MultiRoller
-- TTS/TI4 by Darth Batman and Raptor1210.
-- TI4 MultiRoller by the_Mantis and GarnetBear
-- @author Darrell
-- #include <~/TI4-TTS/TI4/Objects/AutoFillMultiRoller>
--
-- This script keeps track of the last activated system (command token dropped
-- by the active player this turn), and fills the MultiRoller.
--
-- The active fleet takes into account if the MultiRoller belongs to attacker,
-- defender, or third party who happens to have range with an adjacent PDS2.
-- Per-planet combats assign units to the closest planet.
--
-- It scans for Antimass Deflector on the other party, and selects the best unit
-- for Plasma Scoring.
--
-- PDS2 targets adjacent and through-wormhole, including the Creuss flagship's
-- mobile delta wormhole.  The Winnu flagship sets its count to the number of
-- non-fighter opponents.  The Xxcha flagship has an adjacent-reaching PDS.
--
-- Creuss players might want to enable "grid" on their homeworld so it aligns well
-- with the table grid, making sure units on the planet are counted.
--
-- This requires Turns be enabed to ignore when a non-active player touches a
-- command token.  (Turns are automatically enabled via the "place trade goods
-- and set turns" button.)  For a hot-seat like environment, a player must
-- change color to current active turn in order to recognize system activation.
-------------------------------------------------------------------------------

function getHelperClient(helperObjectName)
    local function getHelperObject()
        for _, object in ipairs(getAllObjects()) do
            if object.getName() == helperObjectName then return object end
        end
        error('missing object "' .. helperObjectName .. '"')
    end
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
    local helperObject = false
    local function getCallWrapper(functionName)
        helperObject = helperObject or getHelperObject()
        if not helperObject.getVar(functionName) then error('missing ' .. helperObjectName .. '.' .. functionName) end
        return function(parameters) return copyTable(helperObject.call(functionName, parameters)) end
    end
    return setmetatable({}, { __index = function(t, k) return getCallWrapper(k) end })
end
local _systemHelper = getHelperClient('TI4_SYSTEM_HELPER')
local _unitHelper = getHelperClient('TI4_UNIT_HELPER')
local _zoneHelper = getHelperClient('TI4_ZONE_HELPER')

-------------------------------------------------------------------------------

local TAG = "NeutralCombatRoller"

-- Neutral unit attributes table
local _neutralUnitAttrs = { 
    ['Neutral Carrier'] = { cost = 3, spaceCombat = { dice = 1, hit = 9 }, move = 2, capacity = 6, ship = true },
    ['Neutral Cruiser'] = { cost = 2, spaceCombat = { dice = 1, hit = 6 }, move = 3, capacity = 1, ship = true },
    ['Neutral Destroyer'] = { antiFighterBarrage = { dice = 3, hit = 6 }, cost = 1, spaceCombat = { dice = 1, hit = 8 }, move = 2, ship = true },
    ['Neutral Dreadnought'] = { sustainDamage = true, bombardment = { dice = 1, hit = 5 }, cost = 4, spaceCombat = { dice = 1, hit = 5 }, move = 2, capacity = 1, ship = true },
    ['Neutral Fighter'] = { cost = 0.5, spaceCombat = { dice = 1, hit = 8 }, ship = true },
    ['Neutral Flagship'] = { sustainDamage = true, cost = 8, spaceCombat = { dice = 2, hit = 7 }, move = 1, capacity = 3, ship = true },
    ['Neutral Infantry'] = { cost = 0.5, groundCombat = { dice = 1, hit = 8 } },
    ['Neutral Mech'] = { cost = 2, groundCombat = { dice = 1, hit = 6 }, sustainDamage = true },
    ['Neutral PDS'] = { planetaryShield = true, spaceCannon = { dice = 1, hit = 6, range = 0 }, structure = true },
    ['Neutral Space Dock'] = { production = -2, structure = true },
    ['Neutral War Sun'] = { ship = true, disablePlanetaryShield = true, sustainDamage = true, bombardment = { dice = 3, hit = 3 }, cost = 12, spaceCombat = { dice = 3, hit = 3 }, move = 2, capacity = 6 }
}

-------------------------------------------------------------------------------

-- Register click functions.
function getOnClickFunctionBody(autoFillType, planetIndex)
    local function body(clickObject, clickerColor, altClick)
        local planetName = false

        -- If this button is planet-specific, get that planet’s name
        if planetIndex then
            local system = _systemHelper.getActivatedSystem()
            if system and system.planets and system.planets[planetIndex] then
                planetName = system.planets[planetIndex].name
            end
        end

        if autoFillType == "SPACE_COMBAT" then
            rollNeutralCombat("spaceCombat")
        elseif autoFillType == "BOMBARDMENT" then
            rollNeutralCombat("bombardment", planetName)
        elseif autoFillType == "SPACE_CANNON_OFFENSE" then
            rollNeutralCombat("spaceCannon")
        elseif autoFillType == "SPACE_CANNON_DEFENSE" then
            rollNeutralCombat("spaceCannon", planetName)
        elseif autoFillType == "ANTI_FIGHTER_BARRAGE" then
            rollNeutralCombat("antiFighterBarrage")
        elseif autoFillType == "GROUND_COMBAT" then
            rollNeutralCombat("groundCombat", planetName)
        else
            printToAll("Unknown combat type: " .. tostring(autoFillType), {1,0,0})
        end
    end
    return body
end

local AUTOFILL_TYPE = {
	SPACE_CANNON_OFFENSE = { perPlanet = false },
    ANTI_FIGHTER_BARRAGE = { perPlanet = false },
    SPACE_COMBAT = { perPlanet = false },
    BOMBARDMENT = { perPlanet = true },
    SPACE_CANNON_DEFENSE = { perPlanet = true },
    GROUND_COMBAT = { perPlanet = true },
}
function getOnClickFunctionName(autoFillType, planetIndex)
    if planetIndex then
        return "click_" .. autoFillType .. "_" .. tostring(planetIndex)
    else
        return "click_" .. autoFillType
    end
end
function createOnClickFunctions()
    for autoFillType, attrs in pairs(AUTOFILL_TYPE) do
        if attrs.perPlanet then
            for i = 1, 5 do
                local n = getOnClickFunctionName(autoFillType, i)
                local f = getOnClickFunctionBody(autoFillType, i)
                self.setVar(n, f)
            end
        else
            local n = getOnClickFunctionName(autoFillType, false)
            local f = getOnClickFunctionBody(autoFillType, false)
            self.setVar(n, f)
        end
    end
end
createOnClickFunctions()

-------------------------------------------------------------------------------

local _bombardmentPlasmaScoringOnPlanet = false
local _rollOnSelf = false

-------------------------------------------------------------------------------

function onSystemActivation(system)
    updateUi()
end
function onLoad()
    updateUi()
end

-------------------------------------------------------------------------------

function updateUi()
    local system = _systemHelper.getActivatedSystem()
    local planets = system and system.planets or false

    -- Object in game space is x=1.43, y=0.2, z=2
    -- Object in button space is x=715, y=0.2, z=1000

    local NO_LABEL = '---'

    local fontSize = 44
    local labelFontSize = 30
    local scaleUpDown = 4

    local gapXZ = 0.04
    local gapU = gapXZ / 1.43
    local hMajorZ = 0.3
    local hMinorZ = 0.03

    local hMajor = hMajorZ / 2 * 1000
    local hMinor = hMinorZ / 2 * 1000

    local panelX = 1.43 - (gapXZ * 2)  -- remove gap padding

    self.clearButtons()

    local function numColsAttrs(cols)
        local gapTotalU = gapU * (cols - 1)
        local colTotalU = 1 - gapTotalU
        local w = colTotalU / cols
        local u0 = w / 2
        local du = w + gapU

        -- Slightly off for some reason.  Ad-hoc fix.
        --u0 = u0 - (cols - 1) * 0.01
        w = w - 0.01 + (cols - 1) * 0.01

        return {
            x0 = (u0 * panelX) - (panelX / 2),
            dx = du * panelX,
            w = w * (panelX * 500)
        }
    end

    -- ROW
    local attrs = numColsAttrs(2)
    local x = attrs.x0
    local y = 0.21
    local z = -1 + gapXZ + (hMajorZ / 2)
    local w = attrs.w
    local h = hMajor
    self.createButton({
        click_function = getOnClickFunctionName('SPACE_CANNON_OFFENSE', false),
        function_owner = self,
        label          = 'Space Cannon\nOffense',
        position       = { x = x, y = y, z = z },
        rotation       = { x = 0, y = 0, z = 0 },
        scale          = { x = 1/scaleUpDown, y = 1, z = 1/scaleUpDown },
        width          = w * scaleUpDown,
        height         = h * scaleUpDown,
        font_size      = fontSize * scaleUpDown,
		color          = {r=0.25, g=0.25, b=0.25},
		font_color     = {r=1, g=1, b=1},
        tooltip        = 'Space Cannon Offense',
    })
    x = x + attrs.dx
    self.createButton({
        click_function = getOnClickFunctionName('ANTI_FIGHTER_BARRAGE', false),
        function_owner = self,
        label          = 'Anti-Fighter\nBarrage',
        position       = { x = x, y = y, z = z },
        rotation       = { x = 0, y = 0, z = 0 },
        scale          = { x = 1/scaleUpDown, y = 1, z = 1/scaleUpDown },
        width          = attrs.w * scaleUpDown,
        height         = h * scaleUpDown,
        font_size      = fontSize * scaleUpDown,
		color          = {r=0.25, g=0.25, b=0.25},
		font_color     = {r=1, g=1, b=1},
        tooltip        = 'Anti-Fighter Barrage',
    })

    -- ROW
    z = z + gapXZ + hMajorZ + hMinorZ
    --z = z + gapXZ + hMajorZ
    local attrs = numColsAttrs(1)
    local x = attrs.x0
    local w = attrs.w
    self.createButton({
        click_function = getOnClickFunctionName('SPACE_COMBAT', false),
        function_owner = self,
        label          = 'Space Combat',
        position       = { x = x, y = y, z = z },
        rotation       = { x = 0, y = 0, z = 0 },
        scale          = { x = 1/scaleUpDown, y = 1, z = 1/scaleUpDown },
        width          = w * scaleUpDown,
        height         = h * scaleUpDown,
        font_size      = fontSize * scaleUpDown,
		color          = {r=0.25, g=0.25, b=0.25},
		font_color     = {r=1, g=1, b=1},
        tooltip        = 'Space combat',
    })

    -- LABEL+ROW
    z = z + gapXZ + (hMajorZ + hMinorZ) / 2
    self.createButton({
        click_function = 'doNothing',
        function_owner = self,
        label          = string.upper('Bombardment'),
        position       = { x = 0, y = y, z = z },
        rotation       = { x = 0, y = 0, z = 0 },
        scale          = { x = 1/scaleUpDown, y = 1, z = 1/scaleUpDown },
        width          = 0,
        height         = 0,
        font_size      = labelFontSize * scaleUpDown,
		color          = {r=0.25, g=0.25, b=0.25},
		font_color     = {r=1, g=1, b=1},
        tooltip        = nil,
    })
    z = z + gapXZ + (hMajorZ + hMinorZ) / 2
    local attrs = numColsAttrs(planets and #planets or 1)
    local x = attrs.x0
    local w = attrs.w
    if not planets then
        self.createButton({
            click_function = 'doNothing',
            function_owner = self,
            label          = NO_LABEL,
            position       = { x = x, y = y, z = z },
            rotation       = { x = 0, y = 0, z = 0 },
            scale          = { x = 1/scaleUpDown, y = 1, z = 1/scaleUpDown },
            width          = w * scaleUpDown,
            height         = h * scaleUpDown,
            font_size      = fontSize * scaleUpDown,
			color          = {r=0.25, g=0.25, b=0.25},
			font_color     = {r=1, g=1, b=1},
            tooltip        = nil,
        })
    else
        for i, planet in ipairs(planets) do
            self.createButton({
                click_function = getOnClickFunctionName('BOMBARDMENT', i),
                function_owner = self,
                label          = planet.name,
                position       = { x = x, y = y, z = z },
                rotation       = { x = 0, y = 0, z = 0 },
                scale          = { x = 1/scaleUpDown, y = 1, z = 1/scaleUpDown },
                width          = w * scaleUpDown,
                height         = h * scaleUpDown,
                font_size      = fontSize * scaleUpDown,
				color          = {r=0.25, g=0.25, b=0.25},
				font_color     = {r=1, g=1, b=1},
                tooltip        = 'Bombard ' .. planet.name,
            })
            x = x + attrs.dx
        end
    end

    -- LABEL+ROW
    z = z + gapXZ + (hMajorZ + hMinorZ) / 2
    self.createButton({
        click_function = 'doNothing',
        function_owner = self,
        label          = string.upper('Space Cannon Defense'),
        position       = { x = 0, y = y, z = z },
        rotation       = { x = 0, y = 0, z = 0 },
        scale          = { x = 1/scaleUpDown, y = 1, z = 1/scaleUpDown },
        width          = 0,
        height         = 0,
        font_size      = labelFontSize * scaleUpDown,
		color          = {r=0.25, g=0.25, b=0.25},
		font_color     = {r=1, g=1, b=1},
        tooltip        = nil,
    })
    z = z + gapXZ + (hMajorZ + hMinorZ) / 2
    local attrs = numColsAttrs(planets and #planets or 1)
    local x = attrs.x0
    local w = attrs.w
    if not planets then
        self.createButton({
            click_function = 'doNothing',
            function_owner = self,
            label          = NO_LABEL,
            position       = { x = x, y = y, z = z },
            rotation       = { x = 0, y = 0, z = 0 },
            scale          = { x = 1/scaleUpDown, y = 1, z = 1/scaleUpDown },
            width          = w * scaleUpDown,
            height         = h * scaleUpDown,
            font_size      = fontSize * scaleUpDown,
			color          = {r=0.25, g=0.25, b=0.25},
			font_color     = {r=1, g=1, b=1},
            tooltip        = nil,
        })
    else
        for i, planet in ipairs(planets) do
            self.createButton({
                click_function = getOnClickFunctionName('SPACE_CANNON_DEFENSE', i),
                function_owner = self,
                label          = planet.name,
                position       = { x = x, y = y, z = z },
                rotation       = { x = 0, y = 0, z = 0 },
                scale          = { x = 1/scaleUpDown, y = 1, z = 1/scaleUpDown },
                width          = w * scaleUpDown,
                height         = h * scaleUpDown,
                font_size      = fontSize * scaleUpDown,
				color          = {r=0.25, g=0.25, b=0.25},
				font_color     = {r=1, g=1, b=1},
                tooltip        = 'Space Cannon Defense on ' .. planet.name,
            })
            x = x + attrs.dx
        end
    end

    -- LABEL+ROW
    z = z + gapXZ + (hMajorZ + hMinorZ) / 2
    self.createButton({
        click_function = 'doNothing',
        function_owner = self,
        label          = string.upper('Ground Combat'),
        position       = { x = 0, y = y, z = z },
        rotation       = { x = 0, y = 0, z = 0 },
        scale          = { x = 1/scaleUpDown, y = 1, z = 1/scaleUpDown },
        width          = 0,
        height         = 0,
        font_size      = labelFontSize * scaleUpDown,
		color          = {r=0.25, g=0.25, b=0.25},
		font_color     = {r=1, g=1, b=1},
        tooltip        = nil,
    })
    z = z + gapXZ + (hMajorZ + hMinorZ) / 2
    local attrs = numColsAttrs(planets and #planets or 1)
    local x = attrs.x0
    local w = attrs.w
    if not planets then
        self.createButton({
            click_function = 'doNothing',
            function_owner = self,
            label          = NO_LABEL,
            position       = { x = x, y = y, z = z },
            rotation       = { x = 0, y = 0, z = 0 },
            scale          = { x = 1/scaleUpDown, y = 1, z = 1/scaleUpDown },
            width          = w * scaleUpDown,
            height         = h * scaleUpDown,
            font_size      = fontSize * scaleUpDown,
			color          = {r=0.25, g=0.25, b=0.25},
			font_color     = {r=1, g=1, b=1},
            tooltip        = nil,
        })
    else
        for i, planet in ipairs(planets) do
            self.createButton({
                click_function = getOnClickFunctionName('GROUND_COMBAT', i),
                function_owner = self,
                label          = planet.name,
                position       = { x = x, y = y, z = z },
                rotation       = { x = 0, y = 0, z = 0 },
                scale          = { x = 1/scaleUpDown, y = 1, z = 1/scaleUpDown },
                width          = w * scaleUpDown,
                height         = h * scaleUpDown,
                font_size      = fontSize * scaleUpDown,
				color          = {r=0.25, g=0.25, b=0.25},
				font_color     = {r=1, g=1, b=1},
                tooltip        = 'Ground combat on ' .. planet.name,
            })
            x = x + attrs.dx
        end
    end
end

function doNothing()
    --
end
-------------------------------------------------------------
-- Dice Spawning Logic
-------------------------------------------------------------
function neutralSpaceCombat() rollNeutralCombat("spaceCombat") end
function neutralBombardment() rollNeutralCombat("bombardment") end
function neutralSpaceCannon() rollNeutralCombat("spaceCannon") end
function neutralAFB() rollNeutralCombat("antiFighterBarrage") end
function neutralGroundCombat(planetName)
    rollNeutralCombat("groundCombat", planetName)
end

local neutralUnitBase = getObjectFromGUID('c399bd')

-- Map unit types to dice colors
local DICE_COLOR = {
    ["Dreadnought"] = "Purple",
    ["Flagship"] = "Black",
    ["Destroyer"] = "Red",
    ["War Sun"] = "Orange",
    ["Carrier"] = "Blue",
    ["Fighter"] = "Teal",
    ["Infantry"] = "Green",
    ["Cruiser"] = "Brown",
    ["PDS"] = "Orange",
    ["Space Dock"] = "Yellow",
    ["Mech"] = "Pink"
}

local UNIT_ORDER = {"Dreadnought","Flagship","Destroyer","War Sun","Carrier","Fighter","Cruiser","PDS","Space Dock","Infantry","Mech"}

-- Spawn position helper
local function getDieSpawnPosition(globalDieIndex, totalDice)
    if not neutralUnitBase then
        broadcastToAll("Neutral Unit Base not found!", {1,0,0})
        return {x=0, y=1, z=0}
    end

    local basePos = neutralUnitBase.getPosition()
    local sideOffsetX = 3      -- how far to the side from the base
    local spacing = 2          -- distance between each die
    local yOffset = 1          -- height above table
    local zOffset = 0          -- optional stagger along Z for nicer physics

    -- Center all dice around basePos.x + sideOffsetX
    local totalWidth = (totalDice - 1) * spacing
    local x = basePos.x + sideOffsetX
    local y = basePos.y + yOffset
    local z = basePos.z + zOffset - totalWidth / 2 + (globalDieIndex - 1) * spacing

    return { x = x, y = y, z = z }
end

-- Random 3D rotation helper
local function randomRotation()
    local u1, u2, u3 = math.random(), math.random(), math.random()
    local u1sqrt, u1m1sqrt = math.sqrt(u1), math.sqrt(1-u1)
    local qx = u1m1sqrt * math.sin(2*math.pi*u2)
    local qy = u1m1sqrt * math.cos(2*math.pi*u2)
    local qz = u1sqrt * math.sin(2*math.pi*u3)
    local qw = u1sqrt * math.cos(2*math.pi*u3)

    local ysqr = qy*qy
    local t0 = -2*(ysqr + qz*qz)+1
    local t1 = 2*(qx*qy - qw*qz)
    local t2 = -2*(qx*qz + qw*qy)
    local t3 = 2*(qy*qz - qw*qx)
    local t4 = -2*(qx*qx + ysqr)+1

    if t2 > 1 then t2 = 1 end
    if t2 < -1 then t2 = -1 end

    local xr = math.asin(t2)
    local yr = math.atan2(t3, t4)
    local zr = math.atan2(t1, t0)

    return { math.deg(xr), math.deg(yr), math.deg(zr) }
end
-----------------------------------------------------------
-- Spawns dice for a single unit and rolls them
-----------------------------------------------------------
local function spawnAndRollAllDice(validUnits, combatType)
    local allDiceObjs = {}
    local totalDice = 0

    -- Count total dice for this roll
    for unitIndex, unitName in ipairs(UNIT_ORDER) do
        for _, unit in ipairs(validUnits) do
            if unit.unitType:gsub("Neutral ","") == unitName then
                local stats = _neutralUnitAttrs[unit.unitType][combatType]
                if stats and stats.dice > 0 then
                    totalDice = totalDice + stats.dice
                end
            end
        end
    end

    -- Spawn dice using a global die index
    local globalDieIndex = 1
    for unitIndex, unitName in ipairs(UNIT_ORDER) do
        for _, unit in ipairs(validUnits) do
            if unit.unitType:gsub("Neutral ","") == unitName then
                local stats = _neutralUnitAttrs[unit.unitType][combatType]
                if stats and stats.dice > 0 then
                    local diceObjs = {}
                    for dieIndex = 1, stats.dice do
                        local die = spawnObject({
                            type = "Die_10",
                            position = getDieSpawnPosition(globalDieIndex, totalDice),
                            rotation = randomRotation()
                        })
                        die.setColorTint(Color.fromString(DICE_COLOR[unitName] or "White"))
                        die.use_grid = false
                        die.use_snap_points = false
                        die.use_hands = false
                        die.interactable = false
                        table.insert(diceObjs, die)
                        globalDieIndex = globalDieIndex + 1
                    end
                    table.insert(allDiceObjs, {unitName=unitName, diceObjs=diceObjs, hitValue=stats.hit})
                end
            end
        end
    end

    return allDiceObjs
end
-----------------------------------------------------------
-- Waits, collects dice results, and destroys dice
-----------------------------------------------------------
local function processDiceResults(allDiceObjs)
    local totalHits = 0
    local resultsLog = {}
    for _, unitDice in ipairs(allDiceObjs) do
        local rolls = {}
        local hits = 0
        for _, die in ipairs(unitDice.diceObjs) do
            local val = die.getValue()
            if val >= unitDice.hitValue then hits = hits + 1 end
            table.insert(rolls, val .. (val >= unitDice.hitValue and "#" or ""))
            die.destruct()
        end
        totalHits = totalHits + hits
        table.insert(resultsLog, unitDice.unitName .. " [HIT:" .. unitDice.hitValue .. "]: " .. table.concat(rolls, ", "))
    end
	broadcastToAll("Neutral Units rolled: " .. table.concat(resultsLog, ", "), {1,1,1})
	broadcastToAll("Neutral Units landed " .. totalHits .. " hits.", {1,1,1})
end
------------------------------------------------------
-- The main Roll Combat call function
------------------------------------------------------
function rollNeutralCombat(combatType, planetName)
    local system = _systemHelper.getActivatedSystem()
    if not system then
        broadcastToAll("No activated system found!", {1,0,0})
        return
    end

    local units = getNeutralUnitsInSystem(system, planetName)
    local validUnits = {}
    for _, unit in ipairs(units) do
        local attrs = _neutralUnitAttrs[unit.unitType]
        if attrs and attrs[combatType] and attrs[combatType].dice > 0 then
            table.insert(validUnits, unit)
        end
    end

    if #validUnits == 0 then
        printToAll("No neutral units found for " .. combatType, {1,0,0})
        return
    end

    -- Spawn all dice in a single centered line
    local allDiceObjs = spawnAndRollAllDice(validUnits, combatType)

    -- Collect results after a short delay
    Wait.time(function()
        processDiceResults(allDiceObjs)
    end, 2.0)
end

-------------------------------------------------------------
-- UNIT COLLECTION
-------------------------------------------------------------
function getNeutralUnitsInSystem(system, planetName, combatType)
    local units = {}
    if not system then return units end

    for _, obj in ipairs(getAllObjects()) do
        local name = obj.getName()
        local data = _neutralUnitAttrs[name]
        if data then
            -- Only include units that have a valid combat type
            if combatType == nil or data[combatType] then
                local pos = obj.getPosition()
                local objSystem = _systemHelper.systemFromPosition(pos)
                if objSystem and objSystem.guid == system.guid then
                    if planetName then
                        -- Only include units on the specified planet
                        local planetData = _systemHelper.planetFromPosition({
                            systemGuid = objSystem.guid,
                            position = pos,
                            exact = false
                        })
                        if planetData and string.lower(planetData.name) == string.lower(planetName) then
                            table.insert(units, { unitType = name, obj = obj })
                        end
                    else
                        -- Space-based units (ships, PDS, etc.)
                        table.insert(units, { unitType = name, obj = obj })
                    end
                end
            end
        end
    end

    return units
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