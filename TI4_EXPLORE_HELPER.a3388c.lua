-- @author Darrell for context menu stuff
-- @author Milty for adapting to exploration
-- #include <~/TI4-TTS/TI4/Helpers/TI4_ExploreHelper>

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
local _systemHelper = getHelperClient('TI4_SYSTEM_HELPER')
local _deckHelper = getHelperClient('TI4_DECK_HELPER')
local _unitHelper = getHelperClient('TI4_UNIT_HELPER')
local _zoneHelper = getHelperClient('TI4_ZONE_HELPER')

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

local exploreCards = {
    ['Propulsion Research Facility'] = {
        pull = { 'Propulsion Research Facility Token' }, -- 1r1i or blue
    },
    ['Cybernetic Research Facility'] = {
        pull = { 'Cybernetic Research Facility Token' }, -- 1r1i or yellow
    },
    ['Biotic Research Facility'] = {
        pull = { 'Biotic Research Facility Token' }, -- 1r1i or green
    },
    ['Warfare Research Facility'] = {
        pull = { 'Warfare Research Facility Token' }, -- 1r1i or red
    },
    ['Lazax Survivors'] = {
        pull = { 'Lazax Survivors Token' }, -- 1r2i
    },
    ['Rich World'] = {
        pull = { 'Rich World Token' }, -- 1r
    },
    ['Mining World'] = {
        pull = { 'Mining World Token' }, -- 2r
    },
    ['Dyson Sphere'] = {
        pull = { 'Dyson Sphere Token' }, -- 2r1i
    },
    ['Paradise World'] = {
        pull = { 'Paradise World Token' }, -- 2i
    },
    ['Tomb of Emphidia'] = {
        pull = { 'Tomb of Emphidia Token' }, -- 1i
    },
    ['Demilitarized Zone (PoK)'] = {
        pull = { 'DMZ Token' },
    },
    ['Gamma Wormhole'] = {
        pull = { 'Gamma Wormhole Token' },
    },
    ['Gamma Relay'] = {
        pull = { 'Gamma Wormhole Token' },
    },
    ['Mirage (Exploration)'] = {
        pull = { 'Mirage Token'},
    },
    ['Ion Storm'] = {
        pull = { 'Ion Storm Token' },
    },
    ['Stellar Converter'] = {
        drawTokenOnSpawn = true,
        pull = { 'Stellar Converter Token' },
    },

    -- Codex 2
    ['Nano-Forge'] = {
        drawTokenOnSpawn = true,
        pull = { 'Nano-Forge Token' },
    },
	-- Thunders Edge Commodity Tokens
	['Dynamis Core'] = {
		drawTokenOnSpawn = true,
		pull = { 'Dynamis Core Token' },
	},
	['The Watchtower'] = {
		drawTokenOnSpawn = true,
		pull = { 'The Watchtower Token' },
	},
	['Oluz Station'] = {
		drawTokenOnSpawn = true,
		pull = { 'Oluz Station Token' },
	},
	['Tsion Station'] = {
		drawTokenOnSpawn = true,
		pull = { 'Tsion Station Token' },
	},
	['Revelation'] = {
		drawTokenOnSpawn = true,
		pull = { 'Revelation Token' },
	},
}

local attachTokens = {
    ['Biotic Research Facility Token'] = {
        decal = true,
        faceUp = { resources = 1, influence = 1 },
        faceDown = { tech = 'green' },
    },
    ['Cybernetic Research Facility Token'] = {
        decal = true,
        faceUp = { resources = 1, influence = 1 },
        faceDown = { tech = 'yellow' },
    },
    ['DMZ Token'] = {
        decal = true,
    },
    ['Dyson Sphere Token'] = {
        decal = true,
        resources = 2,
        influence = 1 
    },
    -- This works for empty systems, but cultural exploration (and ghosts token) not handled.
    -- Comment out for now, let players lock them if they want.
    -- ['Gamma Wormhole Token'] = {
    --     decal = false,
    --     injectFunction = function (system, planetName, attachTokenObject)
    --         -- If empty system return it to trigger anchoring.  Do NOT do so
    --         -- if there is a planet there (ghost's token most likely).
    --         if system.planets and #system.planets > 0 then
    --             return system
    --         end
    --     end,
    --     ejectFunction = function(system, planetName, attachTokenObject)
    --         if system.planets and #system.planets > 0 then
    --             return system
    --         end
    --     end
    -- },
    ['Lazax Survivors Token'] = {
        decal = true,
        resources = 1,
        influence = 2
    },
    ['Mining World Token'] = {
        decal = true,
        resources = 2
    },
    ['Mirage Token'] = {
        decal = false,
        systemModifer = true, -- System modifiers get loaded before planet modifiers
        attachTarget = "SYSTEM",
        planetToken = {
          name = 'Mirage',
          resources = 1,
          influence = 2,
          trait = 'cultural',
          legendary = true,
          legendaryCard = 'Mirage Flight Academy',
          planetDecal = 'https://steamusercontent-a.akamaihd.net/ugc/1655600739160551828/A3FEA7A2A7275F196BB7E7E071C79E8B71015503/'
        }
    },
    ['Nano-Forge Token'] = {
        decal = true,
        resources = 2, influence = 2, legendary = true
    },
    ['Paradise World Token'] = {
        decal = true,
        influence = 2
    },
    ['Propulsion Research Facility Token'] = {
        decal = true,
        faceUp = { resources = 1, influence = 1 },
        faceDown = { tech = 'blue' },
    },
    ['Rich World Token'] = {
        decal = true,
        resources = 1
    },
    ['Stellar Converter Token'] = {
        decal = false,
        noanchor = true,
        injectFunction = function (system, planetName, attachTokenObject)
            assert(attachTokenObject.getName() == 'Stellar Converter Token')
            return _stellarConverterTokenInjectFunction(system, planetName, attachTokenObject)
        end,
        ejectFunction = function(system, planetName, attachTokenObject)
            assert(attachTokenObject.getName() == 'Stellar Converter Token')
            return _stellarConverterTokenEjectFunction(system, planetName, attachTokenObject)
        end
    },
    ['Dimensional Tear'] = {
        decal = false,
        noanchor = true,
        noLock = true,
        attachTarget = "SYSTEM",
        anomaly = {'gravity rift'}
    },
    ['Assimilated Tear'] = {
        decal = false,
        noanchor = true,
        noLock = true,
        attachTarget = "SYSTEM",
        anomaly = {'gravity rift'}
    },
    ['Titan Note Token'] = {
        decal = true,
        resources = 1, influence = 1
    },
    ['Titan Ultimate Token'] = {
        decal = true,
        resources = 3, influence = 3
    },
    ['Tomb of Emphidia Token'] = {
        decal = true,
        influence = 1
    },
    ['Warfare Research Facility Token'] = {
        decal = true,
        faceUp = { resources = 1, influence = 1 },
        faceDown = { tech = 'red' },
    },
	["Thunder's Edge Token"] = {
        decal = false,
        systemModifer = true, -- System modifiers get loaded before planet modifiers
        attachTarget = "SYSTEM",
        planetToken = {
            name = "Thunder's Edge",
            resources = 5,
            influence = 1,
            radius = 1.5,
            legendary = true,
            legendaryCard = 'Jupiter Brain',
            planetDecal = 'https://steamusercontent-a.akamaihd.net/ugc/18388505516241393101/456946CE652011BC07429250A141880255B3E76B/'
        }
    },
	['Avernus Token'] = {
        decal = false,
        systemModifer = true, -- System modifiers get loaded before planet modifiers
        noLock = true,
        attachTarget = "SYSTEM",
        planetToken = {
              name = 'Avernus',
              resources = 2,
              influence = 0,
              trait = 'hazardous',
              legendary = true,
              legendaryCard = 'The Nucleus',
              planetDecal = 'https://steamusercontent-a.akamaihd.net/ugc/11185167210483172909/6BF57A264006B31DD37DF1119BB345540101E15D/'
        }
    },
	['4X4IC "Helios" Token'] = {
		decal = true,
		faceUp = { resources = 1 },
		faceDown = { resources = 2 },
	},
}

local AttachParents = {}
local SuspendedAttachments = {}
local AttachLib = { _planetNameToDecals = {} }

---Create a planet token:
---@param tokenName string : The name of the physical token
---@param noLock boolean : Should the token lock after being placed?
---@param planetToken table : Planet table as defined in the TI4_SYSTEM_HELPER
---@param planetToken.planetDecal string : url for token's image. Don't forget to add it to the planet table
---@param exploreCard string? : Should the token be spawned by a card appearing?
---For full control over standard attachToken params, use injectAttachToken and use existing token params as a guid
function injectPlanetToken(params)
  assert(params and type(params) == "table")
  assert(params.tokenName and type(params.tokenName) == "string")
  assert(params.planetToken and type(params.planetToken) == "table")
  assert(params.planetToken.planetDecal and type(params.planetToken.planetDecal) == "string")
  assert(params.exploreCard == nil or type(params.exploreCard) == "string")
  assert(params.attachTarget == nil or params.attachTarget == "SYSTEM", "Planet tokens cannot attach to planets")
  params = copyTable(params)
  local tokenName = params.tokenName

  local attch = {
        decal = false,
        systemModifer = true, -- System modifiers get loaded before planet modifiers
        attachTarget = "SYSTEM",
        noLock = params.noLock,
        planetToken = params.planetToken
    }

  attachTokens[tokenName] = attch

  if params.exploreCard then
    -- Add to tokens associated with that card.
    local attach = exploreCards[params.exploreCard]
    if not attach then
        attach = {
            pull = {},
        }
        exploreCards[params.exploreCard] = attach
    end
    table.insert(attach.pull, tokenName)
    --Note that this is only for pulling cards from the 'Exploration Bag'
    --Token planet card(s) are auto-fetched from the Planet/Legendary deck the first time the token attaches
    if params.planetToken.legendaryCard then
      table.insert(attach.pull, params.planetToken.legendaryCard)
    end
    if params.exploreCard ~= params.planetToken.name then
      table.insert(attach.pull, params.planetToken.name)
    end
  end
end

--- Add an attachment token. Place that token into the 'Exploration Bag' for it to be fetched properly
--- @param params.name string : The name of the token object
--- @param params.fetchedBy string|table? : The name or names(array) of cards that will pull this token
-- The rest of your table will be directly copied into attachTokens without safegaurds, so watch for typos.
-- - decal (boolean): attach image to planet card?
-- - noanchor (boolean): if true, does not snap to a position.
-- - noLock (boolean): if true, the token will not lock
-- - attachTarget (string): defaults to "PLANET" out of "SYSTEM"|"PLANET_OR_SYSTEM"|"PLANET"
-- - frontier (boolean): @depricated, use attachTarget - if true, attach to systems without planets.
-- - getOrientation (table): calls the defined function to determine which way the token should be flipped
        --{guid = 'string', func = 'nameOfFunction'} -function recieve(tokenObj, planetName, systemTable) and should set token rotation
--The following can be included in a faceUp/faceDown table, or can be kept as a key in params (used as faceUpOrDown)
-- - planetToken (table): see injectPlanetToken for param details
-- - anomaly (table): array of anomaly names
-- either:
-- - faceUp = { resources = #, influence = # }
-- - faceDown = { resources = #, influence = # }
-- or:
-- - faceUpOrDown = { resources = #, influence = # }
function injectAttachmentToken(params)
    assert(params and type(params) == "table", "TI4_EXPLORE_HELPER.injectAttachmentToken() error: Failed to provide params.")
    assert(params.name and type(params.name) == "string", "TI4_EXPLORE_HELPER.injectAttachmentToken() error: Failed to provide a params.name field.")

    attachTokens[params.name] = copyTable(params)
    if params.getOrientation then
        local errHeader = "ERROR injecting "..params.name.." attachment: "
        assert(type(params.getOrientation) == "table",errHeader.."params.getOrientation must be a table with defined .guid and .func values.")
        assert(params.getOrientation.guid and type(params.getOrientation.guid) == "string", errHeader.."getOrientation.guid must be the string guid of your script object")
        assert(params.getOrientation.func and type(params.getOrientation.func) == "string", errHeader.."getOrientation.func must be the string name of the function you wish to call")
        attachTokens[params.name]._getOrientation = attachTokens[params.name].getOrientation
        attachTokens[params.name].getOrientation = function(tokenObj, planetName, system)
            local callData = attachTokens[tokenObj.getName()]._getOrientation or {}
            local callObj = callData.obj ~= nil and callData.obj or getObjectFromGUID(callData.guid)
            if not callObj then return end

            callData.obj = callObj
            callObj.call(callData.func, {tokenObj = tokenObj, planetName = planetName, system = system})
        end
    end

    if params.fetchedBy then
        local cards = type(params.fetchedBy) == "string" and {params.fetchedBy} or params.fetchedBy
        assert(type(cards) == "table", "TI4_EXPLORE_HELPER.injectAttachmentToken() inject failed: params.fetchedBy must be a string or table.")

        for _,each in ipairs(cards) do
            if exploreCards[each] then
                table.insert(exploreCards[each].pull, params.name)
            else
                exploreCards[each] = {pull = {params.name}}
            end
        end
    end
end

--- Add a card that can fetch tokens from the 'Exploration Bag' (Fetchable objects must be placed in that bag)
--- @param params.name string : The name of the card
--- @param params.tokens string|table : The name, or an array of names of the tokens this card will fetch
--- @param params.drawTokenOnSpawn boolean?
function injectAttachmentCard(params)
    assert(params and type(params) == "table", "TI4_EXPLORE_HELPER.injectAttachmentCard() error: Failed to provide a params table.")
    assert(params.name, "TI4_EXPLORE_HELPER.injectAttachmentCard(params) error: Failed to provide a params.name field.")
    local entry = { drawTokensOnSpawn = params.drawTokenOnSpawn, pull = {}}
    if params.tokens then
        entry.pull = type(params.tokens) == "string" and {params.tokens} or copyTable(params.tokens)
    end

    exploreCards[params.name] = entry
end

--- @Depricated, use injectAttachmentToken/injectAttachmentCard instead
--- Add a new exploration attach token.
-- params:
-- - cardName (string).
-- - tokenName (string).
-- - decal (boolean): attach image to planet card?
-- - noanchor (boolean): if true, does not snap to a position.
-- - noLock (boolean): if true, the token will not lock
-- - attachTarget (string): defaults to "PLANET" out of "SYSTEM"|"PLANET_OR_SYSTEM"|"PLANET"
-- - frontier (boolean): @depricated, use attachTarget - if true, attach to systems without planets.
-- - getOrientation (table): calls the defined function to determine which way the token should be flipped
        --{guid = 'string', func = 'nameOfFunction'} -function recieve(tokenObj, planetName, systemTable) and should set token rotation
--The following can be included in a faceUp/faceDown table, or can be kept as a key in params (used as faceUpOrDown)
-- - planetToken (table): see injectPlanetToken for param details
-- - anomaly (table): array of anomaly names
-- either:
-- - faceUp = { resources = #, influence = # }
-- - faceDown = { resources = #, influence = # }
-- or:
-- - faceUpOrDown = { resources = #, influence = # }
function injectAttachToken(params)
    assert(type(params) == 'table')
    assert(type(params.cardName) == 'string')
    assert(type(params.tokenName) == 'string')

    -- Add to tokens associated with that card.
    local attach = exploreCards[params.cardName]
    if not attach then
        attach = {
            pull = {},
        }
        exploreCards[params.cardName] = attach
    end
    table.insert(attach.pull, params.tokenName)

    attachTokens[params.tokenName] = copyTable(params)
    if params.getOrientation then
        local errHeader = "ERROR injecting "..params.tokenName.." attachment: "
        assert(type(params.getOrientation) == "table",errHeader.."params.getOrientation must be a table with defined .guid and .func values.")
        assert(params.getOrientation.guid and type(params.getOrientation.guid) == "string", errHeader.."getOrientation.guid must be the string guid of your script object")
        assert(params.getOrientation.func and type(params.getOrientation.func) == "string", errHeader.."getOrientation.func must be the string name of the function you wish to call")
        attachTokens[params.tokenName]._getOrientation = attachTokens[params.tokenName].getOrientation
        attachTokens[params.tokenName].getOrientation = function(tokenObj, planetName, system)
            local callData = attachTokens[tokenObj.getName()]._getOrientation or {}
            local callObj = callData.obj ~= nil and callData.obj or getObjectFromGUID(callData.guid)
            if not callObj then return end

            callData.obj = callObj
            callObj.call(callData.func, {tokenObj = tokenObj, planetName = planetName, system = system})
        end
    end
    return true
end

-------------------------------------------------------------------------------

--- Return explore token names, to be able to put them back in the bag or graveyard.
function getExploreTokenNames()
    local result = {}
    for _, attrs in pairs(exploreCards) do
        for _, tokenName in ipairs(attrs.pull or {}) do
            table.insert(result, tokenName)
        end
    end
    return result
end

--- Callable by other scripts
--- If the planet has multiple traits, provide a traitOverride or the explore will abort
--- @param params.name string : The name of the planet to explore
--- @param params.traitOverride? : Force a trait or specify which to use if the planet has multiple: "hazardous|industrial|cultural"
--- @param params.guid string? : The guid of the system tile
function explorePlanet(params)
    assert(params)
    local planet = type(params) == "string" and params or assert(params.name, "Failed to specify a planet name to TI4_EXPLORE_HELPER.explorePlanet()")
    local trait, system = nil,nil
    if type(params) == "table" then
        trait = params.traitOverride
        system = params.guid
    end

    local function _getSystem()
        local systems = _systemHelper.systems()
        for GUID,each in pairs(systems or {}) do
            for _,each in ipairs(each.planets or {}) do
                if each.name == planet then
                    return GUID
                end
            end
        end
    end
    
    system = system or _getSystem()
    if not system then
        print("TI4_EXPLORE_HELPER error: Call to explore ", planet, " failed: could not find its system.")
        return
    end

    _explorePlanet(system, planet, trait)
end

-------------------------------------------------------------------------------

local _systemModifierGUIDS, _attachGUIDS = {}, {}
function onLoad(saveState)
    self.setColorTint({ r = 0.25, g = 0.25, b = 0.25 })
    self.setScale({ x = 2, y = 0.01, z = 2 })
    self.setName('TI4_EXPLORE_HELPER')
    self.setDescription('Adds right-click exploration options to system tiles and frontier tokens, PLEASE LEAVE ON TABLE! This object is only visible to the black (GM) player.')

    -- Only the GM/black player can see this object.  Others can still interact!
    local invisibleTo = {}
    for _, color in ipairs(Player.getColors()) do
        if color ~= 'Black' then
            table.insert(invisibleTo, color)
        end
    end
    self.setInvisibleTo(invisibleTo)

    local function delayedAdd()
        local lowerPlanetNameSet = _systemHelper.planets()

        for _, object in ipairs(getAllObjects()) do
            if isExplorable(object) then
                applyExplorationGoodness(object)
            elseif isFrontierToken(object) then
                applyFrontierGoodness(object)
            elseif object.tag == 'Card' and lowerPlanetNameSet[string.lower(object.getName())] then
                -- Will re-add during attach below
                object.setDecals({})
            end

            local attachment = attachTokens[object.getName()]
            if attachment then
                if attachment.systemModifer then
                    table.insert(_systemModifierGUIDS, object.getGUID())
                else
                    table.insert(_attachGUIDS, object.getGUID())
                end
            end
        end

        startLuaCoroutine(self, '_delayedLoadAttachmentsCo')
    end

    Wait.frames(delayedAdd, 11)
end

function _delayedLoadAttachmentsCo()
    local count = #_systemModifierGUIDS + #_attachGUIDS
    for i = 1, count do
        local obj = getObjectFromGUID(table.remove(_systemModifierGUIDS) or table.remove(_attachGUIDS))
        if obj then
            AttachLib.attach(obj, false)
        end
        coroutine.yield()
    end
    return 1
end

function onObjectSpawn(object)
    local name = object.getName()

    if isExplorable(object) then
        applyExplorationGoodness(object)
    elseif isFrontierToken(object) then
        applyFrontierGoodness(object)
    elseif object.tag == 'Card' and AttachLib._planetNameToDecals[name] then
        local decals = AttachLib._planetNameToDecals[name]
        object.setDecals(decals)
    end

    -- Give token when card is drawn.
    if object.tag == 'Card' then
        _maybeDrawAttachToken(object)
    end
end

function onObjectDrop(playerColor, droppedObject)
    
    if AttachLib.isAttachToken(droppedObject) then
        if AttachLib.attach(droppedObject, true) then
            AttachLib.anchor(droppedObject)  -- move beneath any units and lock
        end
    end
    if SuspendedAttachments[droppedObject] then
        AttachLib.unsuspendChildren(droppedObject)
    end

    -- Workaround for decals disappearing when dropped on a snap point.
    -- This is a TTS bug (TODO: put tracking URL here), can remove this workaround when fixed.
    --[[ Fixed in TTS 14.0 update? Dec 2025
    if droppedObject.tag == 'Card' then
        local name = droppedObject.getName()
        local decals = AttachLib._planetNameToDecals[name]
        if decals then
            local guid = droppedObject.getGUID()
            local function delayedReapply()
                local object = getObjectFromGUID(guid)
                local decals = AttachLib._planetNameToDecals[name]
                if object and decals then
                    object.setDecals(decals)
                end
            end
            Wait.time(delayedReapply, 3)
        end
    end
    --]]

    _maybeDrawAttachToken(droppedObject)
end

function onObjectRotate(object, spin, flip, player_color, old_spin, old_flip)
    _maybeDrawAttachToken(object, flip)
end

--[[The goals of pickup detection:
    1. If a system/planet token is picked up, let its attachmnets be moved with it
    2. Thus, do not detach tokens being 'moved' with a system tile/planet token
    3. Otherwise detach tokens being picked up
Challanges:
Locked attachments will not move with thair parent, even if we find and unlock them when onObjectPickUp is called for the parent (they will fall through)
    -We will use TTS's attachmnet utils to attach these tokens to their parent when they move, then detach once done.
    This is referred to as 'suspening' in script to avoid confusion between TTS attachments and TI4 attachments
When a player picks up a system tile, all objects lifted with it get their own onObjectPickUp call with no gaurantee of order
    -onPlayerAction .PickUp action lists ALL picked up objects together, so we can know if an attachment is being 'picked up' or 'carried' with its parent obj
--]]
function onPlayerAction(p, action, objArray)
    if action ~= Player.Action.PickUp or not objArray then return end

    --We need to determine if an attachment is being 'picked up', or 'carried' by its parent
    --Detach tokens being picked up, suspend tokens being carried
    local mask = {}
    --Create a mask so that only the highest obj in a higharchy is picked up if present, filter out picked-up objects below it
        --i.e. If a system with a planet token which has an attachment are all picked up together
        --then only the system will proceed, the planet and its attachments will be suspended
    local function _recursiveAddChildren(t, children)
        for each,_ in pairs(children) do
            t[each] = true
            if AttachParents[each] then _recursiveAddChildren(t, AttachParents[each].children) end
        end
    end
    --create mask
    for _,each in ipairs(objArray) do
        if AttachParents[each] and not mask[each] then
            _recursiveAddChildren(mask, AttachParents[each].children)
        end
    end

    --Filter through mask and resolve effects
    for _,each in ipairs(objArray) do
        if not mask[each] then
            if AttachParents[each] then
                AttachLib.suspendChildren(each)
            end
            if AttachLib.isAttachToken(each) then
               AttachLib.detach(each)
            end
        end
    end
end

-- Delay fetching attachments for relic cards until properly in a player area.
-- Homebrew factions may be able to peek at relics, wait for face up in area.
function _maybeDrawAttachToken(object, flipValue)
    assert(type(object) == 'userdata')

    if object.type ~= 'Card' then
        return
    end
    if object.held_by_color then
        return
    end

    -- If flip is is progress use the destination flip value.
    local z = flipValue or object.getRotation().z
    if (z > 90) and (z < 270) then
        return -- face down (do not read attribute b/c not set for onFlip)
    end

    local attrs = exploreCards[object.getName()]
    if (not attrs) or (not attrs.drawTokenOnSpawn) then
        return
    end

    local color = _zoneHelper.zoneFromPosition(object.getPosition())
    if not color then
        return -- not in a player area
    end

    -- Do not try to look up player by color (might not be seated), instead search for a match.
    for _, player in ipairs(Player.getPlayers()) do
        if player.color == color then
            for i = 1, player.getHandCount() do
                for _, handObject in ipairs(player.getHandObjects(i)) do
                    if object == handObject then
                        return -- in hand
                    end
                end
            end
        end
    end

    -- Is the token still in the bag?  Check function will only draw if yes.
    if checkCardForToken(object, false) then
        printToAll('Fetching attachment token for ' .. object.getName() .. ' in ' .. color .. '\'s player area.', 'Yellow')
    end
end

-------------------------------------------------------------------------------

local function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

--If the label of a context menu spills over into a new line, then it looks like shit
    --In single planet systems, ommit the planet name
    --Otherwise abriviate with -H|-C|-I
local function getMultiTraitLabel(pName, trait, pCount)
    if pCount == 1 then
        return 'Explore '..firstToUpper(trait)
    end

    local prefix = 'Explore '..pName..' '
    if #prefix >18 then -- ~20 char limit (adjusted for abrv)
        --If its gonna look like sh*t either way, might as well have all the info
        return prefix..firstToUpper(trait)
    else
        local switch = {
            hazardous = '(H)',
            cultural = '(C)',
            industrial = '(I)',
        }
        return prefix..(switch[trait] or "")
    end
end

function applyExplorationGoodness(object)
    assert(type(object) == 'userdata')
    local objName = object.getName()
    if attachTokens[objName] and attachTokens[objName].planetToken then
        local pData = attachTokens[objName].planetToken
        local planetName = pData.name or objName
    
        if pData.trait then
            local function exploreTokenPlanet(asTrait)
                local system = _systemHelper.systemFromPosition(object.getPosition())
                if system then
                    _explorePlanet(system.guid, planetName, asTrait)
                else
                    printToAll(planetName ..' not attached to a system, cannot explore', 'Red')
                end
            end
            if type(pData.trait) == "string" then
                object.addContextMenuItem('Explore ' .. planetName, function() exploreTokenPlanet() end, false)
            else assert(type(pData.trait) == "table")
                for _,eachTrait in ipairs(pData.trait) do
                    object.addContextMenuItem('Explore '..firstToUpper(eachTrait), function() exploreTokenPlanet(eachTrait) end, false)
                end
            end
        end
    elseif objName == 'Titan Note Token' then
        local function exploreTitanNoteToken(traitOverride)
            local system = _systemHelper.systemFromPosition(object.getPosition())
            local planet = system and _systemHelper.planetFromPosition({
                systemGuid = system.guid,
                position = object.getPosition(),
                exact = false
            })
            if planet then
                local capitalized = string.gsub(traitOverride, "^%l", string.upper)
                printToAll('Titan Note Token using ' .. capitalized, 'Yellow')
                _explorePlanet(system.guid, planet.name, traitOverride)
            else
                printToAll('Titan Note Token not attached to a planet, cannot explore', 'Red')
            end
        end
        object.addContextMenuItem('Explore Cultural', function() exploreTitanNoteToken('cultural') end)
        object.addContextMenuItem('Explore Hazardous', function() exploreTitanNoteToken('hazardous') end)
        object.addContextMenuItem('Explore Industrial', function() exploreTitanNoteToken('industrial') end)
    else
        local systemList = _systemHelper.systems()
        local system = systemList[object.getGUID()]
        if system and system.planets then
            local _pCount = #system.planets
            for i, planet in ipairs(system.planets) do
                if planet.trait ~= nil then
                    if type(planet.trait) == "string" then
                        object.addContextMenuItem('Explore ' .. planet.name, function() _explorePlanet(object.getGUID(), planet.name) end, false)
                    elseif type(planet.trait) == "table" then
                        for _,each in ipairs(planet.trait) do
                            object.addContextMenuItem(getMultiTraitLabel(planet.name, each, _pCount), function() _explorePlanet(object.getGUID(), planet.name, each) end, false)
                        end
                    end
                end
            end
        end
    end
end

function applyFrontierGoodness(object)
    assert(type(object) == 'userdata')
    object.addContextMenuItem('Explore Frontier', function() exploreFrontier(object) end, false)
end

function _explorePlanet(tileGUID, planetName, traitOverride)
    local systemList = _systemHelper.systems()
    assert(systemList[tileGUID] and type(systemList[tileGUID].planets) == "table", "Error: Exploring a planet in a system with no planet data.")
    local planetTrait = false
    local deckType = false
    local tile = false
    local tilePos = false
    local planetPos = false
    local tileRot = false

    local traitToColor = {hazardous = "Red", cultural = "Blue", industrial = "Green"}
    local traitMap = {
        ['cultural'] = 'Cultural Exploration',
        ['hazardous'] = 'Hazardous Exploration',
        ['industrial'] = 'Industrial Exploration'
    }

    for i, planet in ipairs(systemList[tileGUID].planets) do
        if planet.name == planetName then
            planetTrait = traitOverride or planet.trait
            planetPos = planet.position
            break
        end
    end
    if not planetTrait then
        -- Stellar Converter can remove a planet but the tile might still have an explore option.
        printToAll('ERROR: Planet ' .. planetName .. ' has no trait.', 'Red')
        return
    end
    assert(planetTrait and type(planetTrait) == "string", "Exploration Error: Failed to find or provide a trait or specify a trait for a multi-trait planet.")

    deckType = traitMap[planetTrait]
    assert(deckType)

    local tile = assert(getObjectFromGUID(tileGUID))
    local tilePos = tile.getPosition()
    local tileRot = tile.getRotation()

    local exploreDeckGuid = _deckHelper.getDeckWithReshuffle(deckType)
    if not exploreDeckGuid then
        printToAll('ERROR: Unable to locate ' .. deckType .. ' deck.', 'Red')
        return
    end
    local exploreDeck = assert(getObjectFromGUID(exploreDeckGuid))

    planetPos.y = 0
    local position = tile.positionToWorld(planetPos)
    position.y = position.y + 3
    local rotation = { x = 0, y = tileRot.y, z = 0 }

    local card = false
    if exploreDeck.tag == 'Deck' then
        card = exploreDeck.takeObject({
          position = position,
          rotation = rotation,
          callback_function = function(obj) checkCardForToken(obj, planetName) end,
          smooth = true
        })
    elseif exploreDeck.tag == 'Card' then
        card = exploreDeck
        local collide = false
        local fast = true
        card.setPositionSmooth(position, collide, fast)
        card.setRotationSmooth(rotation, collide, fast)
    else
        error('exploreFrontier: bad "' .. deckType .. '" deck')
    end
    broadcastToAll('Exploring ' .. planetName .. ': ' .. card.getName(), traitToColor[planetTrait] or 'Yellow')
end

function exploreFrontier(token)
    assert(type(token) == 'userdata')

    local tokenPos = token.getPosition()
    local tokenRot = token.getRotation()

    local frontierDeckGuid = _deckHelper.getDeckWithReshuffle('Frontier Exploration')
    if not frontierDeckGuid then
        printToAll('ERROR: Unable to locate "Frontier Exploration" deck.', 'Red')
        return
    end
    local frontierDeck = assert(getObjectFromGUID(frontierDeckGuid))

    local position = { x = tokenPos.x, y = tokenPos.y + 3, z = tokenPos.z }
    local rotation = { x = 0, y = 0, z = 0 }
    local system = _systemHelper.systemFromPosition(tokenPos)
    local systemObject = system and getObjectFromGUID(system.guid)
    if systemObject then
        rotation.y = systemObject.getRotation().y
    end

    local card = false
    if frontierDeck.tag == 'Deck' then
        card = frontierDeck.takeObject({
            position = position,
            rotation = rotation,
            callback_function = function(obj) checkCardForToken(obj, false) end,
            smooth = true
        })
    elseif frontierDeck.tag == 'Card' then
        card = frontierDeck
        local collide = false
        local fast = true
        card.setPositionSmooth(position, collide, fast)
        card.setRotationSmooth(rotation, collide, fast)
    else
        error('exploreFrontier: bad "Frontier Exploration" deck')
    end

    local frontierTokenBag = assert(_getByName('Frontier Tokens Bag', 'Infinite'))
    frontierTokenBag.putObject(token)

    broadcastToAll('Exploring Frontier: ' .. card.getName(), 'Yellow')
end

function checkCardForToken(object_spawned, planetName)
    local cardName = object_spawned.getName()
    local tokensToRetrieveSet = {}
    local attrs = exploreCards[cardName]
    for _, item in ipairs(attrs and attrs.pull or {}) do
        tokensToRetrieveSet[item] = true
    end

    local explorationBag = _getByName('Exploration Bag', 'Bag')
    local deltaY = 1
    local result = false
    for _, entry in ipairs(explorationBag.getObjects()) do
        if tokensToRetrieveSet[entry.name] then
            -- Only get each token once.
            tokensToRetrieveSet[entry.name] = nil

            local position = object_spawned.getPosition()
            position.y = position.y + deltaY
            deltaY = deltaY + 0.3

            local rotation = object_spawned.getRotation()

            local function takeCallback(object)
                if AttachLib.isAttachToken(object) then
                    -- Attach will figure out if token should be face up/down.
                    if AttachLib.attach(object, true) then
                        AttachLib.anchor(object)  -- move beneath any units and lock
                    end
                end
            end

            local token = explorationBag.takeObject({
                position = position,
                rotation = rotation,
                guid = entry.guid,
                smooth = false,  -- move there quickly to reduce opportunity to grab it
                callback_function = takeCallback
            })

            -- Just in case the card is in hand, mark the token as use_hands
            -- so it will get added to the hand rather than fall through it.
            token.use_hands = true

            result = true
        end
    end
    return result
end

-------------------------------------------------------------------------------

local _explorablesThisFrame = false --caching systems permanetly will miss injected systems
function isExplorable(object)
    if not _explorablesThisFrame then
        _explorablesThisFrame = {}
        Wait.frames(function() _explorablesThisFrame = false end, 1)
        for guid, _ in pairs(_systemHelper.systems()) do
            _explorablesThisFrame[guid] = true
        end
    end
    local name = object.getName()
    if object.tag == 'Generic' and (_explorablesThisFrame[object.getGUID()] or attachTokens[name] and attachTokens[name].planetToken) then
        return true
    end
    if object.tag == 'Tile' and name == 'Titan Note Token' then
        return true
    end
end

function isFrontierToken(object)
    return object.tag == 'Generic' and object.getName() == 'Frontier Token'
end

function getAllFrontierTokens()
    local frontierTokens = {}

    for _, object in ipairs(getAllObjects()) do
        if isFrontierToken(object) then
            table.insert(frontierTokens, object)
        end
    end

    return frontierTokens
end

local _getByNameCache = {}
function _getByName(name, tag)
    local guid = _getByNameCache[name]
    local object = guid and getObjectFromGUID(guid)
    if object and ((not tag) or object.tag == tag) then
        return object
    end
    for _, object in ipairs(getAllObjects()) do
        if object.getName() == name and ((not tag) or object.tag == tag) then
            _getByNameCache[name] = object.getGUID()
            return object
        end
    end
    error('_getByName: missing "' .. name .. '"')
end

-------------------------------------------------------------------------------

-- Default position is slightly right of center
local DEFAULT_FRONTIER_TOKEN_POSITION = { x = -1, y = 0, z = 0 }

--Temporary fix for preventing frontier tokens from being placed into the fracture during settup
local _fractureIsInPlay, _fractureCacheFalse = false, false
local function isFractureInPlay()
    if _fractureIsInPlay then return true end
    if _fractureCacheFalse then return false end

    for _,each in ipairs(getAllObjects()) do
        if each.type == "Tile" and each.getName() == "Ingress Token" then
            _fractureIsInPlay = true
            return true
        end
    end

    --prevent Empyrean hero/Map tool for table searching a million times if the fracture is not in play
    _fractureCacheFalse = Wait.frames(function() _fractureCacheFalse = false end , 1)
    return false
end

function systemShouldGetFrontierToken(system)
    if system.planets then
        --Stations are coded as planets, but should not prevent frontiers
        for _,each in ipairs(system.planets or {}) do
            if not each.station then
                return false
            end
        end
    end
    if system.hyperlane == true then
        return false
    end
    if system.fracture and not isFractureInPlay() then
        return false
    end

    return true
end

function _placeFrontierTokensCoroutine()
    local frontierTokenBag = assert(_getByName('Frontier Tokens Bag'))

    local guidToSystem = _systemHelper.systems()
    local emptySystemGuidToTokenPositions = {}
    local emptySystemGuidToPosition = {}
    local frontierTokenObjectsToPosition = {}
    for _, object in ipairs(getAllObjects()) do
        local system = guidToSystem[object.getGUID()]
        -- Collect all system tiles that are 'empty', along with the position a frontier token would go
        if system and systemShouldGetFrontierToken(system) then
            local tokenPosition = object.positionToWorld(DEFAULT_FRONTIER_TOKEN_POSITION)
            emptySystemGuidToPosition[object.getGUID()] = object.getPosition()
            emptySystemGuidToTokenPositions[object.getGUID()] = tokenPosition
        -- Collect all current frontier token positions
        elseif isFrontierToken(object) then
            frontierTokenObjectsToPosition[object.getGUID()] = object.getPosition()
        end
    end
    coroutine.yield(0)

    -- Find set of hex coordinates containing frontier tokens
    local frontierTokenGuidToHex = _systemHelper.hexesFromPositions(frontierTokenObjectsToPosition)
    local hexesWithFrontierTokens = {}
    for _, hex in pairs(frontierTokenGuidToHex) do
        hexesWithFrontierTokens[hex] = true
    end

    -- Empty systems to hex coordinates
    local emptySystemGuidToHex = _systemHelper.hexesFromPositions(emptySystemGuidToPosition)

    -- For each empty system, if it's hex coordinate doesn't have a frontier token then place a new one.
    for systemGuid, tokenPosition in pairs(emptySystemGuidToTokenPositions) do
        if emptySystemGuidToHex[systemGuid] and not hexesWithFrontierTokens[emptySystemGuidToHex[systemGuid]] then
            frontierTokenBag.takeObject({
                position = { x = tokenPosition.x, y = tokenPosition.y + 3, z = tokenPosition.z },
                smooth   = true,
            })
            coroutine.yield(0)
        end
    end

    return 1
end

function placeFrontierTokens()
    startLuaCoroutine(self, '_placeFrontierTokensCoroutine')
end

function retrieveFrontierTokens()
    local frontierTokenBag = assert(_getByName('Frontier Tokens Bag'))

    -- Grab all frontier tokens, from everywhere.
    for _, object in ipairs(getAllObjects()) do
        if isFrontierToken(object) then
            frontierTokenBag.putObject(object)
        end
    end
end

-------------------------------------------------------------------------------

function AttachLib.isAttachToken(object)
    assert(type(object) == 'userdata')
    return attachTokens[object.getName()] and true or false
end

--- Attach token to system, return true on success.
function AttachLib.attach(attachTokenObject, setOrientation)
    assert(type(attachTokenObject) == 'userdata')
    local system, planetName = AttachLib._getSystemAndPlanetName(attachTokenObject.getPosition())
    if system then
        if setOrientation then
            AttachLib._orientToken(system, planetName, attachTokenObject)
        end
        local success, attachParent = AttachLib._injectAttachment(system, planetName, attachTokenObject)
        if success then
            if attachParent ~= nil then
                AttachLib.tryParentChild(attachTokenObject, attachParent)
            end

            local attrs = attachTokens[attachTokenObject.getName()] or {}
            if planetName and attrs.decal and attrs.attachTarget ~= "SYSTEM" then
                AttachLib._attachDecal(planetName, attachTokenObject)
            end
            local name = attrs.attachTarget ~= "SYSTEM" and planetName or system.string
            printToAll('Attaching "' .. attachTokenObject.getName() .. '" to "' .. name .. '"', 'Yellow')
            return true
        end
    end
end

--- Detach token from system, return true on success.
function AttachLib.detach(attachTokenObject)
    assert(type(attachTokenObject) == 'userdata')
    local system, planetName = AttachLib._getSystemAndPlanetName(attachTokenObject.getPosition())
    if system then
        local success = AttachLib._ejectAttachment(system, planetName, attachTokenObject)
        if success then
            AttachLib.unparentChild(attachTokenObject)
            local attrs = attachTokens[attachTokenObject.getName()] or {}
            if planetName and attrs.decal and attrs.attachTarget ~= "SYSTEM" then
                AttachLib._detachDecal(planetName, attachTokenObject)
            end
            local name = attrs.attachTarget ~= "SYSTEM" and planetName or system.string
            printToAll('Detaching "' .. attachTokenObject.getName() .. '" from "' .. name .. '"', 'Yellow')
            return true
        end
    end
end

--- Move beneath any units and lock.
function AttachLib.anchor(attachTokenObject)
    assert(type(attachTokenObject) == 'userdata')

    local tokenName = attachTokenObject.getName()
    local attrs = assert(attachTokens[tokenName])
    if attrs.noanchor then
        if not attrs.noLock then AttachLib._lockOnceResting(attachTokenObject) end
        return
    end

    local system, planetName = AttachLib._getSystemAndPlanetName(attachTokenObject.getPosition())

    local systemObject = system and getObjectFromGUID(system.guid)
    if systemObject == nil then
        return
    end

    -- Default to upper left area, override if planet.
    local localPosition = {
        x = 0.9, -- standard is 0.47,
        y = 0,--system.y,
        z = -1.1, -- standard is -0.81
    }

    local lock = not attrs.noLock
    local attachTarget = attrs.attachTarget or "PLANET"
    if attachTokenObject.is_face_down then
        attrs = attrs.faceDown or attrs.faceUpOrDown or attrs
    else
        attrs = attrs.faceUp or attrs.faceUpOrDown or attrs
    end

    -- If there is a planet, use planet position instead.
    if planetName and attachTarget ~= "SYSTEM" then

        attachTokenObject.setLock(false)
        for _, planet in ipairs(system.planets or {}) do
            if planet.name == planetName then
                localPosition = planet.position

                -- Offset in local space when multiple attachments.
                local slot = false
                for name, attachment in pairs(planet._attachments or {}) do
                    if name == tokenName then
                        slot = attachment.slot
                    end
                end
                if slot then
                    if (math.floor((slot - 1) / 5) % 2) == 1 then
                        slot = slot + 0.5
                    end
                    local phi = math.rad((slot * 360 / 5) - 52)
                    local r = 0.54
                    localPosition = {
                        x = localPosition.x + math.cos(phi) * r,
                        y = localPosition.y,
                        z = localPosition.z + math.sin(phi) * r
                    }
                end
                --lift onto token
                if planet.tokenObj ~= nil then
                    local bounds = planet.tokenObj.getBoundsNormalized()
                    localPosition.y = localPosition.y + bounds.size.y
                end
                break
            end
        end
    end

    if attrs.planetToken then
        localPosition = copyTable(attrs.planetToken.position)
    else --planet tokens have already accounted for their thinkness
        local myBounds = attachTokenObject.getBoundsNormalized()
        localPosition.y = localPosition.y + myBounds.size.y - myBounds.offset.y
    end

    if systemObject.is_face_down then
        localPosition.y = -localPosition.y
    end
    local position = systemObject.positionToWorld(localPosition)

    systemObject.setLock(true)
    local collide, fast = false, true
    attachTokenObject.setPositionSmooth(position, collide, fast)

    -- Lock (after things are stable).
    if lock then
        AttachLib._lockOnceResting(attachTokenObject)
    end
end

function AttachLib._lockOnceResting(obj)
    local function condition()
        return obj == nil or (not obj.held_by_color and obj.resting)
    end
    local function action()
        if obj == nil then return end
        obj.setLock(true)
        --[[Might revisit later, would be nice if planet attachments didnt collide
        if removeCollision then
            obj.use_gravity = false
            local hb = obj.getComponent("Collider")
            hb.set("enabled", false)
            if type(removeCollision) == "table" and removeCollision then
                --If the target position was provided, set it now (tokens usually fall on cards)
                obj.setPosition(removeCollision)
            end
        end--]]
    end
    local function timeout()
        if obj == nil then return end

        if obj.held_by_color then
            AttachLib._lockOnceResting(obj)
        else
            -- Did not come to rest?  Lock it anyhow.
            obj.setLock(true)
        end
    end
    --So apparently the object is resting for a few frames before it starts falling. lovely
    Wait.time(function()
        Wait.condition(action, condition, 6, timeout)
    end, 0.8)
end

function AttachLib._getSystemAndPlanetName(position)
    assert(type(position) == 'table')
    local system = _systemHelper.systemFromPosition(position)
    local planet = system and _systemHelper.planetFromPosition({
        systemGuid = system.guid,
        position = position,
        exact = false
    })
    local card = false
    if planet then
        -- Do NOT cache planet cards by guid, deck helper may change guids.
        for _, object in ipairs(getAllObjects()) do
            if object.tag == 'Card' and object.getName() == planet.name then
                card = object
                break
            end
        end
    end
    return system, (planet and planet.name), card
end

-- Tech ALWAYS applies unless the planet already has one (can be any).
function AttachLib._orientToken(system, planetName, attachTokenObject)
    assert(type(system) == 'table' and (not planetName or type(planetName) == 'string') and type(attachTokenObject) == 'userdata')

    local name = attachTokenObject.getName()
    local attrs = assert(attachTokens[name])

    if attrs.getOrientation then
        attrs.getOrientation(attachTokenObject, planetName, system)
        return
    end

    --No need to flip tokens that dont care about facing
    if not attrs.faceUp then return end

    local planetHasAnyTech = false
    if planetName then
        for _, planet in ipairs(system.planets or {}) do
            if planet.name == planetName then
                planetHasAnyTech = planet.tech ~= nil
                break
            end
        end
    end

    local systemObject = assert(getObjectFromGUID(system.guid))
    local rotation = systemObject.getRotation()
	local side = attachTokenObject.getRotation()
	if attrs.faceDown and attrs.faceDown.tech then
		rotation.z = (planetHasAnyTech and 0) or 180
	elseif side.z % 360 < 90 or side.z % 360 >= 270 then
		rotation.z = 0
	else
		rotation.z = 180
	end

    attachTokenObject.setRotation(rotation)
end

--- Add attachment to a system's planet entry.
--- @return boolean?, userdata? : injection success?, the object the attachment is attached to (defaults to system obj)
function AttachLib._injectAttachment(system, planetName, attachTokenObject)
    assert(type(system) == 'table' and (not planetName or type(planetName) == 'string') and type(attachTokenObject) == 'userdata')

    system = copyTable(system)
    local name = attachTokenObject.getName()
    local attrs = assert(attachTokens[name])

    -- Override standard injection?
    if attrs.injectFunction then
        local result, attachParent  = attrs.injectFunction(system, planetName, attachTokenObject)
        if result and type(result) == "table" then
            _systemHelper.modifySystem(result)
            return true, attachParent or getObjectFromGUID(system.guid)
        else
            return false
        end
    end

    --Get attributes bassed on facing
    --faceUpOrDown is no logger required, but is still supported
    -- Object.is_face_down might be wrong if rotation was changed this frame; Read rotation instead
    local attachTarget = attrs.attachTarget or "PLANET"
    local rotZ = (attachTokenObject.getRotation().z + 360) % 360
    if 90 < rotZ and rotZ < 270 then
        attrs = attrs.faceDown or attrs.faceUpOrDown or attrs
    else
        attrs = attrs.faceUp or attrs.faceUpOrDown or attrs
    end

    local function _attachToSystem()
        local _systemObj = getObjectFromGUID(system.guid)
        if attrs.planetToken then
            -- Add planet to system.
            system.planets = system.planets or {}
            attrs.planetToken.tokenObj = attachTokenObject
            attrs.planetToken.position = AttachLib._getTokenPlanetTargetPosition(attachTokenObject, _systemObj)
            table.insert(system.planets, attrs.planetToken)

            --If planet card(s) are in the deck, fetch them
            if not attrs.fetched then
                attrs.fetched = true --flag but don't care about saving between loads

                local position = attrs.planetToken.position
                position = getObjectFromGUID(system.guid).positionToWorld(position)
                position.y = position.y + 1.2
                local function _fetchFrom(card, deckGUID)
                    if not deckGUID then return end
                    local deck = getObjectFromGUID(deckGUID)
                    if not deck then return end

                    if deck.type == "Card" then
                        if deck.getName() == card then
                            deck.setRotation(attachTokenObject.getRotation())
                            deck.setPositionSmooth(position, false, true)
                            position.x = position.x + 0.4 --shift for next card
                        end
                    else
                        for _,each in ipairs(deck.getObjects() or {}) do
                            if each.name == card then
                                local c = deck.takeObject({
                                    index = each.index,
                                    smooth = true,
                                    position = position,
                                    rotation = attachTokenObject.getRotation()
                                })
                                position.x = position.x + 0.4 --shift for next card
                                break
                            end
                        end
                    end
                end

                _fetchFrom(attrs.planetToken.name, _deckHelper.getDeck('Planets'))
                if attrs.planetToken.legendaryCard then
                    _fetchFrom(attrs.planetToken.legendaryCard, _deckHelper.getDeck('Legendary Abilities'))
                end
            end
        end

        system._attachments = system._attachments or {}
        system._attachments[attachTokenObject.getGUID()] = copyTable(attrs)
        system = AttachLib._addAnomalies(system, attrs.anomaly)
        _systemHelper.modifySystem(system)
        return true, _systemObj
    end
    
    if attachTarget == "SYSTEM" or attrs.frontier then --attrs.frontier is depricated
        return _attachToSystem()
    end
    
    local planet = false
    for _, candidate in ipairs(system.planets or {}) do
        if candidate.name == planetName then
            planet = candidate
            break
        end
    end
    if not planet then
        if attachTarget == "PLANET_OR_SYSTEM" then
            return _attachToSystem()
        else
            print("Failed to attach ",name, " to ", planetName,": the planet could not be found.")
            return false
        end
    end
    --else: attachTarget == "PLANET"
    if not planet._attachments then
        planet._attachments = {}
    end

    -- Remove if already present.
    local dele = planet._attachments[name]
    if dele then
        planet.resources = (planet.resources or 0) - (dele.resources or 0)
        planet.influence = (planet.influence or 0) - (dele.influence or 0)
        if dele.tech then
            planet.tech = nil
        end
        planet._attachments[name] = nil
    end

    -- Assign a slot (for positioning).  If a middle entry gets removed it
    -- might lead to incorrect positions after a save/load.  Let it slide.
    local attachment = copyTable(attrs)
    local takenSet = {}
    for _, current in pairs(planet._attachments) do
        if current.slot then
            takenSet[current.slot] = true
        end
    end
    for i = 1, 100 do
        if not takenSet[i] then
            attachment.slot = i
            break
        end
    end
    assert(attachment.slot)

    -- Attach.
    planet._attachments[name] = attachment
    planet.resources = (planet.resources or 0) + (attachment.resources or 0)
    planet.influence = (planet.influence or 0) + (attachment.influence or 0)
    if attachment.tech then
        if not planet.tech then
            planet.tech = attachment.tech
        else
            printToAll('Warning: ' .. planet.name .. ' ' .. name .. ' ' .. rotZ)
        end
    end

    if planet.resources <= 0 then
        planet.resources = nil
    end
    if planet.influence <= 0 then
        planet.influence = nil
    end

    local attachParent = nil
    if planet.tokenObj ~= nil then
        attachParent = planet.tokenObj
        AttachLib.tryParentChild(attachTokenObject, planet.tokenObj)
    end

    system = AttachLib._addAnomalies(system, attrs.anomaly)
    _systemHelper.modifySystem(system)
    return true, attachParent or getObjectFromGUID(system.guid)
end

-- Remove attachment from a system's planet entry.  DO NOT USE CURRENT ORIENTATION,
-- token may have flipped, instead remove by name.
function AttachLib._ejectAttachment(system, planetName, attachTokenObject)
    assert(type(system) == 'table' and (not planetName or type(planetName) == 'string') and type(attachTokenObject) == 'userdata')

    system = copyTable(system)
    local name = attachTokenObject.getName()
    local attrs = assert(attachTokens[name])

    -- Override standard ejection?
    if attrs.ejectFunction then
        local result = attrs.ejectFunction(system, planetName, attachTokenObject)
        if result then
            _systemHelper.modifySystem(result)
            return true
        else return false
        end
    end

    local attachTarget = attrs.attachTarget or "PLANET"
    if attachTokenObject.is_face_down then
        attrs = attrs.faceDown or attrs.faceUpOrDown or attrs
    else
        attrs = attrs.faceUp or attrs.faceUpOrDown or attrs
    end

    if attachTarget == "SYSTEM" or (attachTarget == "PLANET_OR_SYSTEM" and not planetName) then
        if attrs.planetToken then
            -- Remove planet from system.
            local pName = attrs.planetToken.name
            local success = false
            for i, planet in ipairs(system.planets or {}) do
                if planet.name == pName then
                    --save attachments, the planet may be moving
                    attrs.planetToken._attachments = copyTable(planet._attachments)
                    table.remove(system.planets, i)
                    success = true
                    break
                end
            end
            if not success then
                print("Detach WARNING: Tried to detach ", name, " but ", pName, " was not found in the system's data.")
                return false
            end
    
            if system.planets and #system.planets == 0 then
                system.planets = nil
            end
        end

        if system._attachments then
            system._attachments[attachTokenObject.getGUID()] = nil
        end

        system = AttachLib._updateAnomalies(system)
        _systemHelper.modifySystem(system)
        return true
    end

    -- Otherwise MUST have a planet.
    if not planetName then
        return false
    end

    local planet = false
    for _, candidate in ipairs(system.planets or {}) do
        if candidate.name == planetName then
            planet = candidate
            break
        end
    end
    assert(planet, 'missing planet ' .. name)
    if not planet._attachments then
        planet._attachments = {}
    end

    local dele = planet._attachments[name]
    if dele then
        planet.resources = (planet.resources or 0) - (dele.resources or 0)
        planet.influence = (planet.influence or 0) - (dele.influence or 0)
        if dele.tech then
            planet.tech = nil
        end
        planet._attachments[name] = nil
    end

    system = AttachLib._updateAnomalies(system)
    _systemHelper.modifySystem(system)
    return true
end

--- Find the card object.
function AttachLib._getPlanetCard(planetName)
    assert((not planetName) or type(planetName) == 'string')
    -- Do NOT cache planet cards by guid, deck helper may change guids.
    if planetName then
        for _, object in ipairs(getAllObjects()) do
            if object.tag == 'Card' and object.getName() == planetName then
                return object
            end
        end
    end
end

--- Add a decal to the planet card, with layout.
function AttachLib._attachDecal(planetName, attachTokenObject)
    assert(type(planetName) == 'string')
    assert(type(attachTokenObject) == 'userdata')
    local decalImage = false

    -- Object.is_face_down might be wrong if rotation was changed this frame.
    -- Read rotation instead.
    local rotZ = attachTokenObject.getRotation().z
    if rotZ > 90 or rotZ < -90 then
        decalImage = attachTokenObject.getCustomObject().image_bottom
        if (not decalImage) or string.len(decalImage) == 0 then
            decalImage = attachTokenObject.getCustomObject().image
        end
    else
        decalImage = attachTokenObject.getCustomObject().image
    end
    if not decalImage then
        return  -- wrong object type with a different custom table?
    end
    local name = attachTokenObject.getName()
    local decals = AttachLib._planetNameToDecals[planetName] or {}

    -- Remove if already present.
    for i, decal in ipairs(decals) do
        if decal.name == name then
            table.remove(decals, i)
        end
    end

    -- Add decal.
    local scale = { x = 0.6, y = 0.6, z = 1 } -- scale is literal size here
    table.insert(decals, {
        name = name,
        url = decalImage,
        position = { x = 0, y = 0.4, z = 0 },
        rotation = { x = 90, y = 180, z = 0 },
        scale = scale,
    })
    table.insert(decals, {
        name = name,
        url = decalImage,
        position = { x = 0, y = -0.4, z = 0 },
        rotation = { x = 270, y = 0, z = 0 },
        scale = scale,
    })

    AttachLib._layoutDecals(decals)
    AttachLib._planetNameToDecals[planetName] = decals
    local card = AttachLib._getPlanetCard(planetName)
    if card then
        card.setDecals(decals)
    end
end

--- Remove a decal from the planet card, with layout.
function AttachLib._detachDecal(planetName, attachTokenObject)
    assert(type(planetName) == 'string')
    assert(type(attachTokenObject) == 'userdata')
    local name = attachTokenObject.getName()
    local decals = AttachLib._planetNameToDecals[planetName] or {}
    for i = #decals, 1, -1 do
        local decal = decals[i]
        if decal.name == name then
            table.remove(decals, i)
        end
    end
    AttachLib._layoutDecals(decals)
    AttachLib._planetNameToDecals[planetName] = decals
    local card = AttachLib._getPlanetCard(planetName)
    if card then
        card.setDecals(decals)
    end
end

--- Organize tokens for a grid layout, avoid planet res/inf and name areas.
function AttachLib._layoutDecals(decals)
    assert(type(decals) == 'table')
    local nextIndex = 0
    local nameToZeroBasedIndex = {}
    for _, decal in ipairs(decals) do
        if not nameToZeroBasedIndex[decal.name] then
            nameToZeroBasedIndex[decal.name] = nextIndex
            nextIndex = nextIndex + 1
        end
    end
    local x0 = 0.33
    local z0 = -1.1
    local dx = -0.66
    local dz = 0.65
    local numCols = 2
    for _, decal in ipairs(decals) do
        local zi = nameToZeroBasedIndex[decal.name]
        local row = math.floor(zi / numCols)
        local col = zi % numCols
        if row > 1 then
            row = row + 1.5 -- planet name area
        end
        decal.position = {
            x = x0 + dx * col,
            y = decal.position.y,
            z = z0 + dz * row
        }
        if decal.position.y < 0 then
            decal.position.x = -decal.position.x
        end
    end
end

--Called within AtttachLib._injectAttachment
---@return table : the modified system table
function AttachLib._addAnomalies(system, anomalies)
    if not system or not anomalies then return system end
    assert(type(anomalies) == "table" or type(anomalies) == "string")
    --should have already been converted to table, but convert in case
    local t = copyTable(type(anomalies) == "table" and anomalies or {anomalies})

    -- If not set already, store original system stats
    if not system._printedAnomalies then
        system._printedAnomalies = copyTable(system.anomalies or {})
    end

    -- Does system already have the injected anomaly?
    local existingAnomaliesSet = {}
    system.anomalies = system.anomalies or {}
    for _, anomaly in ipairs(system.anomalies) do
        existingAnomaliesSet[anomaly] = true
    end

    for _,eachAnomaly in ipairs(t) do
        if not existingAnomaliesSet[eachAnomaly] then
            -- Add anomaly to system and Notify players
            table.insert(system.anomalies, eachAnomaly)
            printToAll(system.string .. ' now has a '.. eachAnomaly ..'.', 'Yellow')
        end
    end

    -- Return updated system
    return system
end

--Called within AttachLib._ejectAttachment. Call AFTER an attachment is removed from _attachments table
---@return table : the modified system table
function AttachLib._updateAnomalies(system)
    assert(system)

    -- Build Pre-attachment state if it does not exist
    if not system._printedAnomalies then
        system._printedAnomalies = {}
    end

    -- Rebuild system anomalies, which may or may not have changed
    local fullAnomalySet = {}
    --get printed anomalies
    for _, anomaly in ipairs(system._printedAnomalies) do
        fullAnomalySet[anomaly] = true
    end
    --get system-attached anomalies
    for guid, each in pairs(system._attachments or {}) do
        for _, anomaly in ipairs(each.anomaly or {}) do
            fullAnomalySet[anomaly] = true
        end
    end
    --get planet-attached anomalies
    for _,each in ipairs(system.planets or {}) do
        for attachID,attachData in pairs(each._attachments or {}) do
            for _,eachAnomaly in ipairs(attachData.anomaly or {}) do
                fullAnomalySet[eachAnomaly] = true
            end
        end
    end

    if next(fullAnomalySet) then
        system.anomalies = {}
        for anomaly, _ in pairs(fullAnomalySet) do
            table.insert(system.anomalies, anomaly)
        end
    else
        system.anomalies = nil -- Can only have non-empty values
    end

    -- Return updated system
    return system
end

--- Determine the local-space position of a planet in a system
---@return vector? : a local position realative to the system the token is in
function AttachLib._getTokenPlanetTargetPosition(tokenObj, systemObj)
    
    local tokenBounds = tokenObj.getBoundsNormalized()
    --All attach tokens are placed using system.positionToWorld which accounts for the system's scale
    --In order for the token to drop where it is hovered, we also need to acount for this
    local position = systemObj.positionToLocal(tokenObj.getPosition())
        --Mirage model/hitbox is busted so maxe a min thickness
    position.y = math.max(0.12, tokenBounds.size.y- tokenBounds.offset.y)

    --Cap the magnitude such that the planet is at least half-in the system
    local systemBounds = systemObj.getBounds()
    local radius = math.min(systemBounds.size.x, systemBounds.size.z)*0.5 - math.max(tokenBounds.size.z, tokenBounds.size.x)*0.4
    local dist2 = ((position.x*position.x) + (position.z*position.z))
    if dist2 > radius*radius then
        local clamp = radius/ math.sqrt(dist2)
        position.x = position.x*clamp
        position.z = position.z*clamp
    end

    return position
end

--Attachment parenting extension--------------------------------------------------------------------------------------
--Functionality for letting attachments 'move' with their parent object, be that a system tile or planet token--

function AttachLib.tryParentChild(child, parent)
    --Prevent a parent from being attached to one of its children
    local function _recursiveIsChild(t, obj)
      for each,_ in pairs(t) do
        if each == obj or AttachParents[each] and _recursiveIsChild(AttachParents[each].children, obj) then return true end
      end
      return false
    end

    if AttachParents[child] then
        if _recursiveIsChild(AttachParents[child].children, parent) then
            local p, c = parent.getName(), child.getName()
            print("WARNING: Failed to attach ", c, " to ", p, ": ", p, " is a child or grandchild of ",c)
            return false
        end
        AttachParents[child].parent = parent
    end

    AttachParents[parent] = AttachParents[parent] or {children = {}}
    AttachParents[parent].children[child] = true
    return true
end

function AttachLib.unparentChild(child, parent)
    if child == nil then return end

    if parent == nil then
        for _,pData in pairs(AttachParents) do
            if pData.children[child] then
                pData.children[child] = nil
                return
            end
        end
        return --No parent found, maybe throw a warning
    end
    --else
    if AttachParents[parent] and AttachParents[parent].children[child] then
        AttachParents[parent].children[child] = nil
        if not next(AttachParents[parent].children) then
            AttachParents[parent] = nil
        end
    else --parent was not the parent, try and find the actual
        AttachLib.unparentChild(child)
    end
end

function AttachLib.suspendChildren(parent)
    if parent == nil or not AttachParents[parent] then return end
    --TTS attach destroys objects, so attach lowest level children first, then work up to the provided parent
    local function _depthFirstSuspend(_p)
        if not AttachParents[_p] then return {} end

        local _t = {}
        for each,_ in pairs(AttachParents[_p].children) do
            if each == nil then --purge dying objects
                AttachParents[_p].children[each] = nil
            else
                _t[each.getGUID()] = _depthFirstSuspend(each)
                AttachParents[each] = nil --All obj refs will become nil, rebuild this table in unsuspendChildren()
                _p.addAttachment(each) --'each' is now a dead obj
            end
        end
        return _t
    end

    SuspendedAttachments[parent] = _depthFirstSuspend(parent)
end

function AttachLib.unsuspendChildren(parent)
    if parent == nil or not SuspendedAttachments[parent] then return end
    --Wait until the object is resting
    if parent.isSmoothMoving() or not parent.resting then
        Wait.condition(function() AttachLib.unsuspendChildren(parent) end,
            function()
                return not parent.isSmoothMoving() and parent.resting
            end,
            3, function() AttachLib.unsuspendChildren(parent) end
        )
        return
    end

    --Work our way down the heirarchy unattaching objects
    --Objects are not gauranteed to unattach (respawn) with the same guid
    --Object references will also need to be rebuilt as detached objs are new, but otherwise identical objects
    ---@param t table : hash of guid -> table (empty or another t)
    local function _recursiveDetach(t, p)
        assert(p ~= nil, "Object not yet spawned in _recursiveDetach")
        local attachData = p.getAttachments()
        if not attachData then return end

        local spawns = {}
        for i = #attachData, 1, -1 do
            local guid = attachData[i].guid
            --Only detach objs that are identified for suspension (maybe the obj has other unrelated attachments)
            if t[guid] then
                --.index is 0 bassed (why god), using i will cause error
                local obj = p.removeAttachment(attachData[i].index) --not gauranteed to have the same guid anymore
                table.insert(spawns, obj)
                --Deteach any of this object's children
                _recursiveDetach(t[guid], obj)
            end
        end

        --Rebuild the parent's AttachParents table with new object refs
        if next(spawns) then
            AttachParents[parent] = AttachParents[parent] or {children = {}}
            for _,each in ipairs(spawns) do
                AttachParents[parent].children[each] = true
            end
        end
    end

    _recursiveDetach(SuspendedAttachments[parent], parent)
    SuspendedAttachments[parent] = nil
end

-------------------------------------------------------------------------------

local _stellarConverterTokenDestroyPlanetQueue = {}
function _stellarConverterTokenDestroyPlanet_coroutine()
    local params = assert(table.remove(_stellarConverterTokenDestroyPlanetQueue))
    local system = assert(params.system)
    local planetName = assert(params.planetName)
    local attachToken = assert(params.attachToken)

    local systemObject = assert(getObjectFromGUID(system.guid))
    local attachTokenObject = assert(getObjectFromGUID(attachToken))

    if system._stellarConverterPlanet then
        -- If there is some evidence of a previous stellar converter action,
        -- which wasn't undone by detach, we should assume we're in a buggy state
        -- and noop. Players can do this manually.
        return 1
    end

    local planet = false
    for _, systemPlanet in ipairs(system.planets or {}) do
        if planetName == systemPlanet.name then
            planet = systemPlanet
            break
        end
    end
    assert(planet)

    -- Save planet state (planet card name, current attachment tokens+cards)
    system._stellarConverterPlanet = copyTable(planet)

    -- Get set of attachment tokens to search for
    local attachmentCardByToken = {}
    for card, attrs in pairs(exploreCards) do
        for _, tokenName in ipairs(attrs and attrs.pull or {}) do
            -- Stellar Converter doesn't remove planet tokens, or itself.
            --If players want to SC a planet token, they should just remove that token
            if tokenName ~= 'Stellar Converter Token' and not (attachTokens[tokenName] and attachTokens[tokenName].planetToken) then
                attachmentCardByToken[tokenName] = card
            end
        end
    end

    -- Get all objects for purging
    local purgeBag = _getByName('Purge Bag')

    --   Table scan for objects:
    --   Nearest graveyard
    --   Attachment token objects on planet
    --   Attachment cards
    --   Owner tokens on planet
    --   Planet card for planet
    local graveyard = false
    local bestDistanceSq = false
    local p1 = attachTokenObject.getPosition()
    local attachmentTokensOnPlanet = {}
    local attachmentCardGuidByName = {}
    local ownerTokensOnPlanet = {}
    local planetCard = false
    for _, object in ipairs(getAllObjects()) do
        if object.tag == 'Bag' and string.match(object.getName(), '^TI4 Graveyard') then
            local p2 = object.getPosition()
            local dSq = (p1.x - p2.x) ^ 2 + (p1.z - p2.z) ^ 2
            if not bestDistanceSq or dSq < bestDistanceSq then
                graveyard = object
                bestDistanceSq = dSq
            end
        elseif attachmentCardByToken[object.getName()] then -- Checks if it's an attachment token (not Mirage)
            -- If it's on planet, keep track of attachment token.
            local pfpParams = {
                systemGuid = systemObject.getGUID(),
                position = object.getPosition(),
                exact = true
            }
            local pfp = _systemHelper.planetFromPosition(pfpParams)
            if pfp and pfp.name == planetName then
                table.insert(attachmentTokensOnPlanet, object.getGUID())
            end
        elseif exploreCards[object.getName()] then -- Checks if it's an attachment card
            attachmentCardGuidByName[object.getName()] = object.getGUID()
        elseif string.match(object.getName(), ' Owner Token$') then
            -- If it's on planet, keep track of owner token.
            local pfpParams = {
                systemGuid = systemObject.getGUID(),
                position = object.getPosition(),
                exact = true
            }
            local pfp = _systemHelper.planetFromPosition(pfpParams)
            if pfp and pfp.name == planetName then
                table.insert(ownerTokensOnPlanet, object.getGUID())
            end
        elseif object.getName() == planetName then
            planetCard = object.getGUID()
        end
    end
    assert(graveyard)
    coroutine.yield(0)

    -- Get ground forces on planet, and send them to the graveyard
    local systemHex = _systemHelper.hexFromPosition(systemObject.getPosition())
    local units = _unitHelper.getUnits()
    local removeUnits = {}
    for _, unit in ipairs(units) do
        if unit.hex == systemHex then
            -- Restrict to Ground Forces and Structures
            if unit.unitType == 'Infantry' or unit.unitType == 'Mech' or unit.unitType == 'Space Dock' or unit.unitType == 'PDS' then
                -- Check if it's on the planet (exactly)
                local pfpParams = {
                    systemGuid = systemObject.getGUID(),
                    position = unit.position,
                    exact = true
                }
                local pfp = _systemHelper.planetFromPosition(pfpParams)
                if pfp and pfp.name == planetName then
                    table.insert(removeUnits, unit)
                end
            end
        end
    end
    coroutine.yield(0)

    for _, unit in ipairs(removeUnits) do
        local unitObject = getObjectFromGUID(unit.guid)
        if unitObject then
            graveyard.putObject(unitObject)
            coroutine.yield(0)
        end
    end

    -- Get owner tokens on planet, and send them to the graveyard
    for _, ownerToken in ipairs(ownerTokensOnPlanet) do
        local object = getObjectFromGUID(ownerToken)
        if object then
            graveyard.putObject(object)
            coroutine.yield(0)
        end
    end

    if purgeBag then
        -- Get list of attachment tokens on planet, purge token and associated card
        for _, attachTokenOnPlanet in ipairs(attachmentTokensOnPlanet) do
            local attachTokenOnPlanetObject = getObjectFromGUID(attachTokenOnPlanet)
            if attachTokenOnPlanetObject then
                -- Does this token have an associated card?
                local attachCardName = attachmentCardByToken[attachTokenOnPlanetObject.getName()]
                if attachCardName then
                    -- Did we find the card, and therefore have it's GUID?
                    local attachCard = attachmentCardGuidByName[attachCardName]
                    if attachCard then
                        -- Is the card object still on the table?
                        local attachCardObject = getObjectFromGUID(attachCard)
                        if attachCardObject then
                            purgeBag.putObject(attachCardObject)
                            coroutine.yield(0)
                        end
                    end
                end

                attachTokenOnPlanetObject.setLock(false)
                purgeBag.putObject(attachTokenOnPlanetObject)
                coroutine.yield(0)
            end
        end

        -- Get planet card, and purge it.
        if planetCard then
            local planetCardObject = getObjectFromGUID(planetCard)
            if planetCardObject then
                purgeBag.putObject(planetCardObject)
                coroutine.yield(0)
            end
        end
    end

    -- Place token directly on planet, and lock it
    systemObject.setLock(true)
    attachTokenObject.setLock(false)
    local planetPosition = systemObject.positionToWorld(planet.position)
    local tokenPosition = { x = planetPosition.x, y = planetPosition.y + 0.5, z = planetPosition.z }
    local collide = false
    local fast = true
    attachTokenObject.setPositionSmooth(tokenPosition, collide, fast)

    local function condition()
        if attachTokenObject.isSmoothMoving() then
            return false
        end
        if not attachTokenObject.resting then
            return false
        end
        return true
    end
    local function action()
        attachTokenObject.setLock(true)
    end
    local function timeout() end
    Wait.condition(action, condition, 3, timeout)

    -- Clear context menu
    attachTokenObject.clearContextMenu()

    -- Inject planet with no stats
    planet.name = 'Shattered remains of ' .. planet.name
    planet.resources = 0
    planet.influence = 0
    planet.tech = nil
    planet._attachments = nil
    _systemHelper.modifySystem(system)

    return 1
end

function _stellarConverterTokenDestroyPlanet(system, planetName, attachToken)
    assert(system)
    assert(planetName)
    assert(attachToken)

    table.insert(_stellarConverterTokenDestroyPlanetQueue, {
        system = system,
        planetName = planetName,
        attachToken = attachToken
    })
    startLuaCoroutine(self, '_stellarConverterTokenDestroyPlanet_coroutine')
end

function _stellarConverterTokenInjectFunction(system, planetName, attachTokenObject)
    if not system then
        return false
    end

    if not planetName then
        printToAll('Stellar Converter must be placed on a planet.', 'Yellow')
        return false
    end

    if system.home then
        printToAll('Cannot use Stellar Converter on a home system planet.', 'Yellow')
        return false
    end

    local systemObject = assert(getObjectFromGUID(system.guid))
    local planet = false
    for _, systemPlanet in ipairs(system.planets or {}) do
        if planetName == systemPlanet.name then
            planet = systemPlanet
            break
        end
    end
    assert(planet)

    if planet.legendary then
        printToAll('Cannot use Stellar Converter on a Legendary planet.', 'Yellow')
        return false
    end

    -- Detect if we're attaching to planet that's already acted on (eg. onLoad after using Stellar Converter)
    -- Detection options...none are perfect.
    --  Is the token locked at hover height?
    --  Is the planet card in the Purge bag?
    --  Token is identical on each side, so faceup could be pre-purge, facedown could be post-purge.
    local purgeBag = _getByName('Purge Bag')
    if purgeBag then
        for _, entry in ipairs(purgeBag.getObjects()) do
            -- Planet has been purged. Token should just anchor down.
            if entry.name == planetName then
                -- Save planet state (onLoad will miss any attachments that are already in the Purge bag. Players will have to handle.)
                system._stellarConverterPlanet = copyTable(planet)
                -- Clear planet stats (leave a planet entry for zone / planet position computations to work for others in the sytem)
                planet.resources = 0
                planet.influence = 0
                planet.tech = nil
                planet._attachments = nil

                -- Place token directly on planet, and lock it
                attachTokenObject.setLock(false)
                local planetPosition = systemObject.positionToWorld(planet.position)
                local tokenPosition = { x = planetPosition.x, y = planetPosition.y + 0.5, z = planetPosition.z }
                local collide = false
                local fast = true
                attachTokenObject.setPositionSmooth(tokenPosition, collide, fast)

                local function condition()
                    if attachTokenObject.isSmoothMoving() then
                        return false
                    end
                    if not attachTokenObject.resting then
                        return false
                    end
                    return true
                end
                local function action()
                    attachTokenObject.setLock(true)
                end
                local function timeout() end
                Wait.condition(action, condition, 3, timeout)

                -- Return modified system. No further action required.
                return system
            end
        end
    end

    -- Edit context menu for available planets.  Serves as a confirmation step.
    -- Create for all to allow some sloppiness in token placement.
    local tokenGuid = attachTokenObject.getGUID()
    attachTokenObject.clearContextMenu()
    for _, planet in ipairs(system.planets or {}) do
        local planetName = planet.name
        local function wrapped()
            printToAll('Stellar Converter destroying ' .. planetName, 'Yellow')
            _stellarConverterTokenDestroyPlanet(system, planetName, tokenGuid)
        end
        attachTokenObject.addContextMenuItem('Destroy ' .. planetName, wrapped, false)
    end

    return system
end

function _stellarConverterTokenEjectFunction(system, planetName, attachTokenObject)
    -- Clear context menu
    attachTokenObject.clearContextMenu()

    if not system then
        return false
    end

    if not planetName then
        return false
    end

    -- Stellar Converter action wasn't ever confirmed
    if not system._stellarConverterPlanet then
        return false
    end

    -- Restore planet stats
    local restorePlanet = system._stellarConverterPlanet
    system._stellarConverterPlanet = nil

    local lookForName = 'Shattered remains of ' .. restorePlanet.name
    local destroyedPlanet = false
    for _, systemPlanet in ipairs(system.planets or {}) do
        if systemPlanet.name == lookForName then
            destroyedPlanet = systemPlanet
        end
    end
    -- This overwrites any changes players somehow made since the Stellar Converter happened...okay for now.
    destroyedPlanet.name = restorePlanet.name
    destroyedPlanet.resources = restorePlanet.resources
    destroyedPlanet.influence = restorePlanet.influence
    destroyedPlanet.tech = restorePlanet.tech
    destroyedPlanet._attachments = restorePlanet._attachments

    -- Find purge bag
    local purgeBag = _getByName('Purge Bag')
    if not purgeBag then
        return system
    end

    -- Restore purged items
    --   Planet card
    --   Attachment tokens on planet
    --   Attachment cards associated with tokens
    -- (Let players restore units themselves; the graveyard activity was reported.)
    if purgeBag then
        -- Get map of attach token name to card name
        local attachmentCardByToken = {}
        if restorePlanet._attachments then
            for card, attrs in pairs(exploreCards) do
                for _, tokenName in ipairs(attrs and attrs.pull or {}) do
                    -- Check if the token was on the planet when it was destroyed.
                    -- NOTE: This won't catch attachments after save/load. Consider reading planet card decals instead.
                    if restorePlanet._attachments[tokenName] then
                        attachmentCardByToken[tokenName] = card
                    end
                end
            end
        end

        local systemObject = getObjectFromGUID(system.guid)
        local unpurgePosition = systemObject.positionToWorld(restorePlanet.position)
        unpurgePosition = { x = unpurgePosition.x, y = unpurgePosition.y + 0.5, z = unpurgePosition.z }
        local unpurgeDz = -0.5

        for _, purgeObject in ipairs(purgeBag.getObjects()) do
            local unpurge = false
            if purgeObject.name == planetName then
                unpurge = true
            elseif attachmentCardByToken[purgeObject.name] then -- Check if attachment token which was on planet
                unpurge = true
            elseif exploreCards[purgeObject.name] then -- Check if attachment card
                -- Check if associated token was on the card
                local attrs = exploreCards[purgeObject.name]
                for _, cardToken in ipairs(attrs and attrs.pull or {}) do
                    if attachmentCardByToken[cardToken] then
                        unpurge = true
                        break
                    end
                end
            end

            if unpurge then
                purgeBag.takeObject({
                    guid = purgeObject.guid,
                    position = unpurgePosition,
                    smooth = true,
                })
                unpurgePosition = { x = unpurgePosition.x, y = unpurgePosition.y, z = unpurgePosition.z + unpurgeDz }
            end
        end
    end

    return system
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