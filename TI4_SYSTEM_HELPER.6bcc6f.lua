--- Shared system (and generic resource/influence cards) helper object.
-- @author GarnetBear added the original influence/resource list.
-- @author Darrell June 2020 more attributes, planet positions.
-- #include <~/TI4-TTS/TI4/Helpers/TI4_SystemHelper>

-- Users should copy this getHelperClient function, and use via:
--
-- local systemHelper = getHelperClient('TI4_SYSTEM_HELPER')
-- local system = systemHelper.systemFromPosition({x,y,z})
--
-- Where one can call any main function in this file via the helper.
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
local _deckHelper = getHelperClient('TI4_DECK_HELPER')
local _factionHelper = getHelperClient('TI4_FACTION_HELPER')
local _unitHelper = getHelperClient('TI4_UNIT_HELPER')
local _zoneHelper = getHelperClient('TI4_ZONE_HELPER')
local _exploreHelper = getHelperClient('TI4_EXPLORE_HELPER')

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

-- Systems table, from guid to systems.
--
-- System attributes:
-- - tile: number (0 for homebrew).
-- - home: boolean, true if a home system.
-- - planets: list of planet tables.
-- - wormholes: list of strings.
-- - anomalies: list of strings.
-- - rotate: override, degrees number.
-- - localY: override tile height (ghosts home system).
-- - hyperlane: boolean, true if a hyperlane.
-- - offMap: boolean: if true, tile is not part of the system map (e.g. do not count for slice r/i).
--
-- Planet attributes:
-- - name: string.
-- - resources: number.
-- - influence: number.
-- - trait: string or array of strings {cultural|industrial|hazardous}.
-- - tech: string --*Support is WIP for array of strings {red|green|yellow|blue}.
-- - position: table with {xz}: override, local space.
-- - radius: number: override, local space.
-- - legendary: boolean.
-- - station: boolean|number: If a number is provided, that station boosts comms by that amount (instead of 1)
-- - stationTokenName: *string: If you wish to provide a custom name for the token. Default is (planet.name.." Token")
--
-- Also computed:
-- - system.guid: tile GUID.
-- - system.zoneEdgePositions: local edge positions carving per-planet zones.
-- - system.planets[].position: local {xyz} position.
-- - system.planets[].radius: local space.
--
local _systems = {
    ['e06224'] = { tile = 1, home = true, planets = {
        { name = 'Jord', resources = 4, influence = 2 },
    }},
    ['aa880a'] = { tile = 2, home = true, planets = {
        { name = 'Moll Primus', resources = 4, influence = 1 },
    }},
    ['3972ec'] = { tile = 3, home = true, planets = {
        { name = 'Darien', resources = 4, influence = 4 },
    }},
    ['9930d6'] = { tile = 4, home = true, planets = {
        { name = 'Muaat', resources = 4, influence = 1 },
    }},
    ['7e95d2'] = { tile = 5, home = true, planets = {
        { name = 'Nestphar', resources = 3, influence = 2 },
    }},
    ['6a93ea'] = { tile = 6, home = true, planets = {
        { name = '[0.0.0]', resources = 5, influence = 0 },
    }},
    ['aeda64'] = { tile = 7, home = true, planets = {
        { name = 'Winnu', resources = 3, influence = 4 },
    }},
    ['3ec552'] = { tile = 8, home = true, planets = {
        { name = 'Mordai II', resources = 4, influence = 0 },
    }},
    ['f5a2d6'] = { tile = 9, home = true, planets = {
        { name = 'Maaluuk', resources = 0, influence = 2 },
        { name = 'Druaa', resources = 3, influence = 1 },
    }},
    ['ef90b2'] = { tile = 10, home = true, planets = {
        { name = 'Arc Prime', resources = 4, influence = 0 },
        { name = 'Wren Terra', resources = 2, influence = 1 },
    }},
    ['7b343b'] = { tile = 11, home = true, planets = {
        { name = 'Lisis II', resources = 1, influence = 0 },
        { name = 'Ragh', resources = 2, influence = 1 },
    }},
    ['5cb889'] = { tile = 12, home = true, planets = {
        { name = 'Nar', resources = 2, influence = 3 },
        { name = 'Jol', resources = 1, influence = 2 },
    }},
    ['275148'] = { tile = 13, home = true, planets = {
        { name = "Tren'Lak", resources = 1, influence = 0 },
        { name = 'Quinarra', resources = 3, influence = 1 },
    }},
    ['c9db03'] = { tile = 14, home = true, planets = {
        { name = 'Archon Ren', resources = 2, influence = 3 },
        { name = 'Archon Tau', resources = 1, influence = 1 },
    }},
    ['8c72e3'] = { tile = 15, home = true, planets = {
        { name = 'Retillion', resources = 2, influence = 3 },
        { name = 'Shalloq', resources = 1, influence = 2 },
    }},
    ['2fcfd0'] = { tile = 16, home = true, planets = {
        { name = 'Hercant', resources = 1, influence = 1 },
        { name = 'Arretze', resources = 2, influence = 0 },
        { name = 'Kamdorn', resources = 0, influence = 1 },
    }},
    ['98369f'] = { tile = 17, home = true, wormholes = { 'delta' } }, -- not precisely a home, but tied to faction
    ['3442d7'] = { tile = 18, planets = {
        { name = 'Mecatol Rex', resources = 1, influence = 6, radius = 1.7 },
    }},
    ['105fad'] = { tile = 19, planets = {
        { name = 'Wellon', resources = 1, influence = 2, trait = 'industrial', tech = 'yellow' },
    }},
    ['e0b992'] = { tile = 20, planets = {
        { name = 'Vefut II', resources = 2, influence = 2, trait = 'hazardous' },
    }},
    ['b1f9fb'] = { tile = 21, planets = {
        { name = 'Thibah', resources = 1, influence = 1, trait = 'industrial', tech = 'blue' },
    }},
    ['d9bdc7'] = { tile = 22, planets = {
        { name = "Tar'Mann", resources = 1, influence = 1, trait = 'industrial', tech = 'green' },
    }},
    ['387d24'] = { tile = 23, planets = {
        { name = 'Saudor', resources = 2, influence = 2, trait = 'industrial' },
    }},
    ['a59f2c'] = { tile = 24, planets = {
        { name = 'Mehar Xull', resources = 1, influence = 3, trait = 'hazardous', tech = 'red' },
    }},
    ['5b1d07'] = { tile = 25, wormholes = { 'beta' }, planets = {
        { name = 'Quann', resources = 2, influence = 1, trait = 'cultural' },
    }},
    ['31e03b'] = { tile = 26, wormholes = { 'alpha' }, planets = {
        { name = 'Lodor', resources = 3, influence = 1, trait = 'cultural' },
    }},
    ['35d7dc'] = { tile = 27, planets = {
        { name = 'New Albion', resources = 1, influence = 1, trait = 'industrial', tech = 'green' },
        { name = 'Starpoint', resources = 3, influence = 1, trait = 'hazardous' },
    }},
    ['1b163e'] = { tile = 28, planets = {
        { name = "Tequ'Ran", resources = 2, influence = 0 , trait = 'hazardous' },
        { name = 'Torkan', resources = 0, influence = 3, trait = 'cultural' },
    }},
    ['9be0b1'] = { tile = 29, planets = {
        { name = "Qucen'n", resources = 1, influence = 2, trait = 'industrial' },
        { name = 'Rarron', resources = 0, influence = 3, trait = 'cultural' },
    }},
    ['dad8f9'] = { tile = 30, planets = {
        { name = 'Mellon', resources = 0, influence = 2, trait = 'cultural' },
        { name = 'Zohbat', resources = 3, influence = 1, trait = 'hazardous' },
    }},
    ['de7dec'] = { tile = 31, planets = {
        { name = 'Lazar', resources = 1, influence = 0, trait = 'industrial', tech = 'yellow' },
        { name = 'Sakulag', resources = 2, influence = 1, trait = 'hazardous' },
    }},
    ['1c0625'] = { tile = 32, planets = {
        { name = 'Dal Bootha', resources = 0, influence = 2, trait = 'cultural' },
        { name = 'Xxehan', resources = 1, influence = 1, trait = 'cultural' },
    }},
    ['dcd17c'] = { tile = 33, planets = {
        { name = 'Corneeq', resources = 1, influence = 2, trait = 'cultural' },
        { name = 'Resculon', resources = 2, influence = 0, trait = 'cultural' },
    }},
    ['350970'] = { tile = 34, planets = {
        { name = 'Centauri', resources = 1, influence = 3, trait = 'cultural' },
        { name = 'Gral', resources = 1, influence = 1, trait = 'industrial', tech = 'blue' },
    }},
    ['322174'] = { tile = 35, planets = {
        { name = 'Bereg', resources = 3, influence = 1, trait = 'hazardous' },
        { name = 'Lirta IV', resources = 2, influence = 3, trait = 'hazardous' },
    }},
    ['e97aac'] = { tile = 36, planets = {
        { name = 'Arnor', resources = 2, influence = 1, trait = 'industrial' },
        { name = 'Lor', resources = 1, influence = 2, trait = 'industrial' },
    }},
    ['cae2ce'] = { tile = 37, planets = {
        { name = 'Arinam', resources = 1, influence = 2, trait = 'industrial' },
        { name = 'Meer', resources = 0, influence = 4, trait = 'hazardous', tech = 'red' },
    }},
    ['69f885'] = { tile = 38, planets = {
        { name = 'Abyz', resources = 3, influence = 0, trait = 'hazardous' },
        { name = 'Fria', resources = 2, influence = 0, trait = 'hazardous' },
    }},
    ['33520d'] = { tile = 39, wormholes = { 'alpha' } },
    ['b0a6a6'] = { tile = 40, wormholes = { 'beta' } },
    ['3ea35d'] = { tile = 41, anomalies = { 'gravity rift' } },
    ['4d6424'] = { tile = 42, anomalies = { 'nebula' } },
    ['0b360f'] = { tile = 43, anomalies = { 'supernova' } },
    ['006abc'] = { tile = 44, anomalies = { 'asteroid field' } },
    ['120e40'] = { tile = 45, anomalies = { 'asteroid field' } },
    ['b50950'] = { tile = 46 },
    ['faec50'] = { tile = 47 },
    ['12a49a'] = { tile = 48 },
    ['8f40b4'] = { tile = 49 },
    ['d83cd4'] = { tile = 50 },
    ['e3be37'] = { tile = 51, home = true, wormholes = { 'delta' }, offMap = true, planets = {
        { name = 'Creuss', resources = 4, influence = 2, position = { x = -0.05, z = -0.4 }, radius = 0.8 },
    }},

    -- PoK systems.
    ['2bc02a'] = { tile = 52, source = 'PoK', home = true, planets = {
        { name = 'Ixth', resources = 3, influence = 5 },
    }},
    ['811df5'] = { tile = 53, source = 'PoK', home = true, planets = {
        { name = 'Arcturus', resources = 4, influence = 4 },
    }},
    ['8e0645'] = { tile = 54, source = 'PoK', home = true, planets = {
        { name = 'Acheron', resources = 4, influence = 0 },
    }},
    ['98d4c2'] = { tile = 55, source = 'PoK', home = true, planets = {
        { name = 'Elysium', resources = 4, influence = 1, radius = 1.5 },
    }},
    ['110112'] = { tile = 56, source = 'PoK', home = true, anomalies = { 'nebula' }, planets = {
        { name = 'The Dark', resources = 3, influence = 4 },
    }},
    ['49318b'] = { tile = 57, source = 'PoK', home = true, planets = {
        { name = 'Naazir', resources = 2, influence = 1 },
        { name = 'Rokha', resources = 1, influence = 2 },
    }},
    ['6f20aa'] = { tile = 58, source = 'PoK', home = true, planets = {
        { name = 'Valk', resources = 2, influence = 0 },
        { name = 'Ylir', resources = 0, influence = 2 },
        { name = 'Avar', resources = 1, influence = 1 },
    }},
    ['6b5ed1'] = { tile = 59, source = 'PoK', planets = {
        { name = 'Archon Vail', resources = 1, influence = 3, trait = 'hazardous', tech = 'blue' },
    }},
    ['0a93a9'] = { tile = 60, source = 'PoK', planets = {
        { name = 'Perimeter', resources = 2, influence = 1, trait = 'industrial' },
    }},
    ['780b2f'] = { tile = 61, source = 'PoK', planets = {
        { name = 'Ang', resources = 2, influence = 0, trait = 'industrial', tech = 'red' },
    }},
    ['4c1e0a'] = { tile = 62, source = 'PoK', planets = {
        { name = 'Sem-Lore', resources = 3, influence = 2, trait = 'cultural', tech = 'yellow' },
    }},
    ['8064e3'] = { tile = 63, source = 'PoK', planets = {
        { name = 'Vorhal', resources = 0, influence = 2, trait = 'cultural', tech = 'green' },
    }},
    ['a28bb1'] = { tile = 64, source = 'PoK', wormholes = { 'beta' }, planets = {
        { name = 'Atlas', resources = 3, influence = 1, trait = 'hazardous', },
    }},
    ['b642cd'] = { tile = 65, source = 'PoK', planets = {
        { name = 'Primor', resources = 2, influence = 1, trait = 'cultural', radius = 1.5,
         legendary = true, legendaryCard = 'The Atrament' },
    }},
    ['1154bc'] = { tile = 66, source = 'PoK', planets = {
        { name = "Hope's End", resources = 3, influence = 0, trait = 'hazardous', radius = 1.5,
        legendary = true, legendaryCard = 'Imperial Arms Vault' },
    }},
    ['834e88'] = { tile = 67, source = 'PoK', anomalies = { 'gravity rift' }, planets = {
        { name = 'Cormund', resources = 2, influence = 0, trait = 'hazardous', position = { x = 0.45, z = -0.25 } },
    }},
    ['8bc917'] = { tile = 68, source = 'PoK', anomalies = { 'nebula' }, planets = {
        { name = 'Everra', resources = 3, influence = 1, trait = 'cultural', position = { x = 0.45, z = -0.25 } },
    }},
    ['40bc9e'] = { tile = 69, source = 'PoK', planets = {
        { name = 'Accoen', resources = 2, influence = 3, trait = 'industrial' },
        { name = 'Jeol Ir', resources = 2, influence = 3, trait = 'industrial' },
    }},
    ['0fb4f5'] = { tile = 70, source = 'PoK', planets = {
        { name = 'Kraag', resources = 2, influence = 1, trait = 'hazardous' },
        { name = 'Siig', resources = 0, influence = 2, trait = 'hazardous' },
    }},
    ['14a065'] = { tile = 71, source = 'PoK', planets = {
        { name = "Ba'kal", resources = 3, influence = 2, trait = 'industrial' },
        { name = 'Alio Prima', resources = 1, influence = 1, trait = 'cultural' }
    }},
    ['c8d135'] = { tile = 72, source = 'PoK', planets = {
        { name = 'Lisis', resources = 2, influence = 2, trait = 'industrial' },
        { name = 'Velnor', resources = 2, influence = 1, trait = 'industrial', tech = 'red' },
    }},
    ['a931d3'] = { tile = 73, source = 'PoK', planets = {
        { name = 'Cealdri', resources = 0, influence = 2, trait = 'cultural', tech = 'yellow' },
        { name = 'Xanhact', resources = 0, influence = 1, trait = 'hazardous' }
    }},
    ['c763de'] = { tile = 74, source = 'PoK', planets = {
        { name = 'Vega Major', resources = 2, influence = 1, trait = 'cultural' },
        { name = 'Vega Minor', resources = 1, influence = 2, trait = 'cultural', tech = 'blue' },
    }},
    ['9c6682'] = { tile = 75, source = 'PoK', planets = {
        { name = 'Loki', resources = 1, influence = 2, trait = 'cultural' },
        { name = 'Abaddon', resources = 1, influence = 0, trait = 'cultural' },
        { name = 'Ashtroth', resources = 2, influence = 0, trait = 'hazardous' },
    }},
    ['9a3731'] = { tile = 76, source = 'PoK', planets = {
        { name = 'Rigel III', resources = 1, influence = 1, trait = 'industrial', tech = 'green' },
        { name = 'Rigel II', resources = 1, influence = 2, trait = 'industrial' },
        { name = 'Rigel I', resources = 0, influence = 1, trait = 'hazardous' },
    }},
    ['75bd47'] = { tile = 77, source = 'PoK', },
    ['b8dff6'] = { tile = 78, source = 'PoK', },
    ['1a6583'] = { tile = 79, source = 'PoK', anomalies = { 'asteroid field' }, wormholes = { 'alpha' } },
    ['015a9f'] = { tile = 80, source = 'PoK', anomalies = { 'supernova' } },
    ['33c12d'] = { tile = 81, source = 'PoK', anomalies = { 'supernova' }, faction = 'muaat' },
    ['82bf35'] = { tile = 82, source = 'PoK',
        wormholes_faceUp = { 'gamma', 'alpha', 'beta' },
        wormholes_faceDown = { 'gamma' },
        offMap = true, planets = {
            {
                name = 'Mallice', resources = 0, influence = 3,
                legendary = true, legendaryCard = 'Exterrix Headquarters', trait = 'cultural',
                position = { x = -0.45, z = -0.47 }, radius = 0.8, -- position is face up
            }
        }
    },
	
	----- Thunder's Edge Home Systems
	['d454a6'] = { tile = 92, source = 'TE', home = true, planets = {
        { name = 'Ordinian', resources = 0, influence = 0, legendary = true, legendaryCard = '4X41D "Hyperion" VI' },
		{ name = 'Revelation', resources = 1, influence = 2, station = true },
    }},
	['a1d0b3'] = { tile = 93, source = 'TE', home = true, planets = {
        { name = 'Mez Lo Orz Fei Zsha', resources = 2, influence = 1 },
		{ name = 'Rep Lo Orz Qet', resources = 1, influence = 3 },
    }},
	['393cc3'] = { tile = 94, source = 'TE', home = true, wormholes = { 'epsilon' } },
	['eb41e6'] = { tile = 95, home = true, planets = {
        { name = 'Ikatena', resources = 4, influence = 4 },
    }},
	['94c84d'] = { tile = 96, source = 'TE', home = true, planets = {
        { name = 'Cronos', resources = 2, influence = 1 },
		{ name = 'Tallin', resources = 1, influence = 2 },
    }},
	-----  Thunder's Edge Systems
    ['58b55e'] = { tile = 97, source = 'TE', planets = {
        { name = 'Faunus', resources = 1, influence = 3, trait = 'industrial', tech = 'green', radius = 1.5, legendary = true, legendaryCard = 'Maxis Central Control' },
    }},
    ['620587'] = { tile = 98, source = 'TE', planets = {
        { name = 'Garbozia', resources = 2, influence = 1, trait = 'hazardous', radius = 1.5, legendary = true, legendaryCard = "Dok 'N Pic's Salvage Yard" },
    }},
    ['0c56eb'] = { tile = 99, source = 'TE', planets = {
        { name = 'Emelpar', resources = 0, influence = 2, trait = 'cultural', radius = 1.5, legendary = true, legendaryCard = 'The Acropolis' },
    }},
    ['468490'] = { tile = 100, source = 'TE', planets = {
        { name = "Tempesta", resources = 1, influence = 1, trait = 'hazardous', tech = 'blue', radius = 1.5, legendary = true, legendaryCard = 'Ionian Fuel Refinery' },
    }},
    ['9c3347'] = { tile = 101, source = 'TE', planets = {
        { name = 'Olergodt', resources = 2, influence = 1, trait = {'cultural', 'hazardous'}, tech = 'yellow' },
    }},
    ['783d69'] = { tile = 102, source = 'TE', wormholes = { 'alpha' }, planets = {
        { name = 'Andeara', resources = 1, influence = 1, trait = 'industrial', tech = 'blue' },
    }},
	['e4baf0'] = { tile = 103, source = 'TE', planets = {
        { name = 'Vira Pics III', resources = 2, influence = 3, trait = {'hazardous','cultural'} },
    }},
	['1f2ded'] = { tile = 104, source = 'TE', planets = {
        { name = 'Lesab', resources = 2, influence = 1, trait = {'industrial', 'hazardous'} },
    }},
    ['5ac3db'] = { tile = 105, source = 'TE', planets = {
        { name = 'New Terra', resources = 1, influence = 1, trait = 'industrial', tech = 'green' },
        { name = 'Tinnes', resources = 2, influence = 1, trait = {'industrial', 'hazardous'}, tech = 'green' },
    }},
    ['441dd0'] = { tile = 106, source = 'TE', planets = {
        { name = 'Cresius', resources = 0, influence = 1 , trait = 'hazardous' },
        { name = 'Lazul Rex', resources = 2, influence = 2, trait = {'cultural', 'industrial'} },
    }},
    ['6bd06b'] = { tile = 107, source = 'TE', planets = {
        { name = 'Tiamat', resources = 1, influence = 2, trait = 'cultural', tech = 'yellow' },
        { name = 'Hercalor', resources = 1, influence = 0, trait = 'industrial' },
    }},
    ['2b9dde'] = { tile = 108, source = 'TE', planets = {
        { name = 'Kostboth', resources = 0, influence = 1, trait = 'cultural' },
        { name = 'Capha', resources = 3, influence = 0, trait = 'hazardous' },
    }},
    ['8a71d9'] = { tile = 109, source = 'TE', planets = {
        { name = 'Bellatrix', resources = 1, influence = 2, trait = 'cultural' },
        { name = 'Tsion Station', resources = 1, influence = 1, station = true },
    }},
    ['edc1e5'] = { tile = 110, source = 'TE', planets = {
        { name = 'Elnath', resources = 2, influence = 0, trait = 'hazardous' },
        { name = 'Horizon', resources = 1, influence = 2, trait = 'cultural' },
        { name = 'Luthien VI', resources = 3, influence = 1, trait = 'hazardous' },
    }},
	['a2b6ba'] = { tile = 111, source = 'TE', planets = {
        { name = 'Tarana', resources = 1, influence = 2, trait = {'cultural', 'industrial'} },
        { name = 'Oluz Station', resources = 1, influence = 1, station = true },
    }},
	['71a41f'] = { tile = 112, source = 'TE', planets = {
        { name = 'Mecatol Rex', resources = 1, influence = 6, radius = 1.7, legendary = true, legendaryCard = 'The Galactic Council' }, 
	}},
    ['1684ac'] = { tile = 113, source = 'TE', anomalies = { 'gravity rift' }, wormholes = { 'beta' } },
    ['82db8b'] = { tile = 114, source = 'TE', anomalies = { 'entropic scar' } },
    ['4d99d0'] = { tile = 115, source = 'TE', anomalies = { 'astroid field' }, planets = {
        { name = 'Industrex', resources = 2, influence = 0, trait = 'industrial', tech = 'red', legendary = true, legendaryCard = 'Aeurex Mechanica' }
	}},
	['2c570b'] = { tile = 116, source = 'TE', anomalies = { 'entropic scar' }, planets = {
        { name = 'Lemox', resources = 0, influence = 3, trait = 'industrial' }
	}},
	['e1f04c'] = { tile = 117, source = 'TE', anomalies = { 'astroid field' , 'gravity rift' }, planets = {
        { name = 'The Watchtower', resources = 1, influence = 1, station = true, position = { x = -.57, z = 0.58 }, radius = .8 }
	}},
	['987aa2'] = { tile = 118, source = 'TE', home = true, wormholes = { 'epsilon' }, offMap = true, planets = {
		{ name = 'Ahk Creuxx', resources = 4, influence = 2, position = { x = -0.05, z = -0.4 }, radius = 0.8 }
	}},
	----- The Fracture Systems
	['6e69cb'] = { tile = 901, source = 'TE', fracture = true, wormholes = { 'egress' } },
	['5a91ee'] = { tile = 902, source = 'TE', fracture = true, wormholes = { 'egress' } },
	['1e7722'] = { tile = 903, source = 'TE', fracture = true },
	['bf2378'] = { tile = 904, source = 'TE', fracture = true },
	['ada29d'] = { tile = 905, source = 'TE', fracture = true, planets = {
        { name = 'Styx', resources = 4, influence = 0, radius = 1.5, legendary = true, legendaryCard = 'A Song Like Marrow' },
    }},
	['d12964'] = { tile = 906, source = 'TE', fracture = true, planets = {
        { name = 'Cocytus', resources = 3, influence = 0 },
    }},
	['8d90cf'] = { tile = 907, source = 'TE', fracture = true, planets = {
        { name = 'Lethe', resources = 0, influence = 2 },
        { name = 'Phlegethon', resources = 1, influence = 2 },
    }},
	----- Twilight Fall Home Systems
    ['370d1c'] = { tile = 601, source = 'TF', home = true},
    ['63062b'] = { tile = 602, source = 'TF', home = true},
    ['487e79'] = { tile = 603, source = 'TF', home = true},
    ['98cd74'] = { tile = 604, source = 'TF', home = true},
    ['bc8634'] = { tile = 605, source = 'TF', home = true},
    ['398533'] = { tile = 606, source = 'TF', home = true},
    ['8b81e4'] = { tile = 607, source = 'TF', home = true},
    ['860763'] = { tile = 608, source = 'TF', home = true},

    -- Hyperlane tiles
    -- hyperlanes is an array of 6 indices, representing hyperlane connexion. Indices are zero-based (0 to 6)
    -- Using _fillMissingSystemData to automatically fill 'hyperlanes' with the right data depending if the tile is flipped or not
    -- 0 is top right side, when the tile is rotated at -180° on Y axis (Y rotation of zero)
    ['81a64a'] = { tile = 83, hyperlane = true,
        hyperlanes_faceUp = { {3}, {}, {}, {0}, {}, {} },
        hyperlanes_faceDown = { {}, {5}, {4,5}, {}, {2}, {1,2} }
    },
    ['bed0e0'] = { tile = 84, hyperlane = true,
        hyperlanes_faceUp = { {}, {4}, {}, {}, {1}, {} },
        hyperlanes_faceDown = { {2}, {}, {0,5}, {5}, {}, {2,3} }
    },
    ['a64a36'] = { tile = 85, hyperlane = true,
        hyperlanes_faceUp = { {}, {3}, {}, {1}, {}, {} },
        hyperlanes_faceDown = { {}, {5}, {4,5}, {}, {2}, {1,2} }
    },
    ['b34afa'] = { tile = 86, hyperlane = true,
        hyperlanes_faceUp = { {}, {3}, {}, {1}, {}, {} },
        hyperlanes_faceDown = { {2}, {}, {0,5}, {5}, {}, {2,3} }
    },
    ['3ccc62'] = { tile = 87, hyperlane = true,
        hyperlanes_faceUp = { {4}, {4}, {4}, {}, {0,1,2}, {} },
        hyperlanes_faceDown = { {}, {}, {4,5}, {}, {2}, {2} }
    },
    ['ee4bf1'] = { tile = 88, hyperlane = true,
        hyperlanes_faceUp = { {2,3,4}, {}, {0}, {0}, {0}, {} },
        hyperlanes_faceDown = { {}, {5}, {4,5}, {}, {2}, {1,2} }
    },
    ['33e49a'] = { tile = 89, hyperlane = true,
        hyperlanes_faceUp = { {2,4}, {}, {0,4}, {}, {0,2}, {} },
        hyperlanes_faceDown = { {2}, {}, {0,5}, {}, {}, {2} }
    },
    ['7e7ee1'] = { tile = 90, hyperlane = true,
        hyperlanes_faceUp = { {4}, {3}, {}, {1}, {0}, {} },
        hyperlanes_faceDown = { {2}, {}, {0,5}, {}, {}, {2} }
    },
    ['565980'] = { tile = 91, hyperlane = true,
        hyperlanes_faceUp = { {2}, {}, {0,5}, {5}, {}, {2,3} },
        hyperlanes_faceDown = { {}, {}, {4,5}, {}, {2}, {2} }
    },
	-- Thunder's Edge Hyperlanes
	['7d26a6'] = { tile = 119, hyperlane = true,
        hyperlanes_faceUp = { {3}, {}, {}, {0}, {}, {} },
        hyperlanes_faceDown = { {3}, {}, {5}, {0}, {}, {2} }
    },
    ['ead20d'] = { tile = 120, hyperlane = true,
        hyperlanes_faceUp = { {}, {4}, {}, {}, {1}, {} },
        hyperlanes_faceDown = { {}, {}, {4,5}, {5}, {2}, {2,3} }
    },
    ['5e9791'] = { tile = 121, hyperlane = true,
        hyperlanes_faceUp = { {4}, {}, {}, {}, {0}, {} },
        hyperlanes_faceDown = { {}, {}, {4,5}, {5}, {2}, {2,3} }
    },
    ['acfb9b'] = { tile = 122, hyperlane = true,
        hyperlanes_faceUp = { {4}, {}, {}, {}, {0}, {} },
        hyperlanes_faceDown = { {}, {5}, {}, {5}, {}, {1,3} }
    },
    ['6f94e2'] = { tile = 123, hyperlane = true,
        hyperlanes_faceUp = { {}, {3,4,5}, {}, {1}, {1}, {1} },
        hyperlanes_faceDown = { {}, {5}, {}, {5}, {}, {1,3} }
    },
    ['840061'] = { tile = 124, hyperlane = true,
        hyperlanes_faceUp = { {3}, {3}, {}, {0,1,5}, {}, {3} },
        hyperlanes_faceDown = { {2,3}, {}, {0,5}, {0,5}, {}, {2,3} }
    },

    -- Keleres
    ['d05172'] = { tile = 202, source = 'TE', home = true, planets = {
        { name = 'Moll Primus', resources = 4, influence = 1 },
    }},
    ['feae10'] = { tile = 214, source = 'TE', home = true, planets = {
        { name = 'Archon Ren', resources = 2, influence = 3 },
        { name = 'Archon Tau', resources = 1, influence = 1 },
    }},
    ['badf4c'] = { tile = 258, source = 'TE', home = true, planets = {
        { name = 'Valk', resources = 2, influence = 0 },
        { name = 'Ylir', resources = 0, influence = 2 },
        { name = 'Avar', resources = 1, influence = 1 },
    }},


    -- Phil's warp zones.
    ['3830ca'] = { tile = 1001, hyperlane = true }, -- A
    ['5dbaf9'] = { tile = 1002, hyperlane = true }, -- A
    ['e604ce'] = { tile = 1003, hyperlane = true }, -- B
    ['902424'] = { tile = 1004, hyperlane = true }, -- B
    ['903187'] = { tile = 1005, hyperlane = true }, -- G
    ['507cb6'] = { tile = 1006, hyperlane = true }, -- G
    ['35b72d'] = { tile = 1007, hyperlane = true, hyperlanes = {
        {3}, {}, {}, {0}, {}, {}
    } },
    ['b41a78'] = { tile = 1008, hyperlane = true, hyperlanes = {
        {2}, {}, {0}, {}, {}, {}
    } },
    ['1000e9'] = { tile = 1009, hyperlane = true, hyperlanes = {
        {2,4}, {}, {0,4}, {}, {0,2}, {}
    } },
    ['9a71c7'] = { tile = 1010, hyperlane = true, hyperlanes = {
        {2}, {}, {0,5}, {5}, {}, {2,3}
    } },
    ['204530'] = { tile = 1011, hyperlane = true, hyperlanes = {
        {2,3}, {}, {0}, {0,5}, {}, {3}
    } },
    ['b74682'] = { tile = 1012, hyperlane = true, hyperlanes = {
        {2}, {}, {0}, {}, {}, {}
    } },
    ['1ffd34'] = { tile = 1013, hyperlane = true, hyperlanes = {
        {3}, {3}, {}, {0,1,5}, {}, {3}
    } },
    ['bdf753'] = { tile = 1014, hyperlane = true, hyperlanes = {
        {2,4}, {}, {0,4}, {}, {0,2}, {}
    } },
    ['a35ea3'] = { tile = 1015, hyperlane = true, hyperlanes = {
        {2}, {}, {0}, {}, {}, {}
    } },
    ['613593'] = { tile = 1016, hyperlane = true, hyperlanes = {
        {3}, {}, {}, {0}, {}, {}
    } },
    ['2c5e05'] = { tile = 1017, hyperlane = true, hyperlanes = {
        {2}, {}, {0}, {5}, {}, {3}
    } },
    ['c131ce'] = { tile = 1018, hyperlane = true, hyperlanes = {
        {3}, {}, {}, {0}, {}, {}
    } },
    ['bb11c7'] = { tile = 1019, hyperlane = true, hyperlanes = {
        {3}, {3}, {}, {0,1,5}, {}, {3}
    } },
    ['34cbfd'] = { tile = 1020, hyperlane = true, hyperlanes = {
        {2}, {}, {0}, {5}, {}, {3}
    } },

    -- Pick-A-Planet systems.
    ['0dcdee'] = { tile = 2001, planets = {{ name = 'A' }} },
    ['c68187'] = { tile = 2002, planets = {{ name = 'A' }} },
    ['3c3949'] = { tile = 2003, planets = {{ name = 'A' }} },
    ['8e69fb'] = { tile = 2004, planets = {{ name = 'A' }} },
    ['75d1cd'] = { tile = 2005, planets = {{ name = 'A' }} },
    ['ea61c5'] = { tile = 2006, planets = {{ name = 'A' }} },
    ['8518e6'] = { tile = 2007, planets = {{ name = 'A' }} },
    ['eda114'] = { tile = 2008, planets = {{ name = 'A' }} },
    ['1300b8'] = { tile = 2009, planets = {{ name = 'A' }} },
    ['fd8349'] = { tile = 2010, planets = {{ name = 'A' }} },
    ['941405'] = { tile = 2011, planets = {{ name = 'A' }} },
    ['ef89f5'] = { tile = 2012, planets = {{ name = 'A' }} },
    ['eb1837'] = { tile = 2013, planets = {{ name = 'A' }} },
    ['8e7edf'] = { tile = 2014, planets = {{ name = 'A' }} },
    ['ffb0d9'] = { tile = 2015, planets = {{ name = 'A' }} },
    ['26820b'] = { tile = 2016, planets = {{ name = 'A' }} },
    ['9b66db'] = { tile = 2017, planets = {{ name = 'A' }} },
    ['943567'] = { tile = 2018, planets = {{ name = 'A' }} },
    ['ea6aa3'] = { tile = 2019, planets = {{ name = 'A' }, { name = 'B' }} },
    ['b81d49'] = { tile = 2020, planets = {{ name = 'A' }, { name = 'B' }} },
    ['042a91'] = { tile = 2021, planets = {{ name = 'A' }, { name = 'B' }} },
    ['3d388c'] = { tile = 2022, planets = {{ name = 'A' }, { name = 'B' }} },
    ['652379'] = { tile = 2023, planets = {{ name = 'A' }, { name = 'B' }} },
    ['636039'] = { tile = 2024, planets = {{ name = 'A' }, { name = 'B' }} },
    ['26d4e0'] = { tile = 2025, planets = {{ name = 'A' }, { name = 'B' }} },
    ['78011d'] = { tile = 2026, planets = {{ name = 'A' }, { name = 'B' }} },
    ['862968'] = { tile = 2027, planets = {{ name = 'A' }, { name = 'B' }} },
    ['a4a6bb'] = { tile = 2028, planets = {{ name = 'A' }, { name = 'B' }} },
    ['7679a9'] = { tile = 2029, planets = {{ name = 'A' }, { name = 'B' }} },
    ['ce4179'] = { tile = 2030, planets = {{ name = 'A' }, { name = 'B' }} },
    ['8ef29f'] = { tile = 2031, planets = {{ name = 'A' }, { name = 'B' }} },
    ['cfd3f1'] = { tile = 2032, planets = {{ name = 'A' }, { name = 'B' }} },
    ['cae6b7'] = { tile = 2033, planets = {{ name = 'A' }, { name = 'B' }} },
    ['ca6044'] = { tile = 2034, planets = {{ name = 'A' }, { name = 'B' }} },
    ['517d73'] = { tile = 2035, planets = {{ name = 'A' }, { name = 'B' }} },
    ['8c22eb'] = { tile = 2036, planets = {{ name = 'A' }, { name = 'B' }} },
}

local _nonPlanetResourceInfluenceCards = {
    -- Keep base game agendas here?  Are they gone?  XXX TODO

    { name = 'Core Mining', resources = 2, influence = 0 },
    { name = 'Senate Sanctuary', resources = 0, influence = 2 },
    { name = 'Terraforming Initiative', resources = 1, influence = 1 },

    { name = 'Custodia Vigilia', resources = 2, influence = 2 },
	{ name = 'Brine Pool', resources = 1, influence = 1 },
	{ name = 'Coral Reef', resources = 1, influence = 1 },
	{ name = 'Ice Shelf', resources = 1, influence = 1 },
	{ name = 'Lost Fleet', resources = 1, influence = 1 },
	{ name = 'Deep Abyss', resources = 1, influence = 1 },
	{ name = 'Cronos Hollow', resources = 3, influence = 0 },
	{ name = 'Tallin Hollow', resources = 3, influence = 0 },
    { name = 'The Triad' , resources = 3, influence = 3, get = function(obj) return getTriadValue(obj) end},--getTriadValue}

    -- Attachment tokens are the new way to do things.
    -- { name = 'Rich World', resources = 1, influence = 0 },
    -- { name = 'Mining World', resources = 2, influence = 0 },
    -- { name = 'Lazax Survivors', resources = 1, influence = 2 },
    -- { name = 'Tomb of Emphidia', resources = 0, influence = 1 },
    -- { name = 'Paradise World', resources = 0, influence = 2 },
    -- { name = 'Dyson Sphere', resources = 2, influence = 1 },
    -- { name = 'Biotic Research Facility', resources = 1, influence = 1 },
    -- { name = 'Cybernetic Research Facility', resources = 1, influence = 1 },
    -- { name = 'Warfare Research Facility', resources = 1, influence = 1 },
    -- { name = 'Propulsion Research Facility', resources = 1, influence = 1 },
    -- { name = 'Terraform', resources = 1, influence = 1 },
    -- { name = 'Ul the Progenitor', resources = 3, influence = 3, requireFaceUp = true },

    -- Technology
    -- Predictive Intelligence: Increase minimum available votes by 3.
    -- ... but for each vote, see Zeal comment below why this is problematic.
    -- Comment out for now, reintroduce once there's a better way to do these.
    --{ name = 'Predictive Intelligence', resources = 0, influence = 3, requireFaceUp = true },
}

local TYPE = {
    MUTATE = 'mutate', -- adds or removes attribute(s), do first.
    ADJUST = 'adjust',  -- adjusts existing attribute(s).
    CHOOSE = 'choose',  -- picks from available unit(s), do after all others.
}

local LEADER = {
    AGENT = 'agent',
    COMMANDER = 'commander',
    HERO = 'hero'
}

local _resInfModifiers = {
    ['Elder Qanoj'] = {
        description = 'Each planet you exhaust to cast votes provides 1 additional vote',
        type = TYPE.ADJUST,
        leader = LEADER.COMMANDER, -- Xxcha
        apply = function(resInfCards)
            for _, resInfCard in ipairs(resInfCards) do
                -- Technically this adds a *vote* and not influence.
                resInfCard.influence = resInfCard.influence + 1
            end
        end
    },

    ['Xxekir Grom Ω'] = {
        description = 'When you exhaust planets, combine the value of their resources and influence. Treat the combined value as if it were both resources and influence.',
        type = TYPE.ADJUST,
        leader = LEADER.HERO, -- Xxchaa
        apply = function(resInfCards)
            for _, resInfCard in ipairs(resInfCards) do
                resInfCard.influence = resInfCard.influence + resInfCard.resources
            end
        end
    },
	
	["Archon's Gift"] = {
        description = 'You can spend influence as if it were resources. You can spend resources as if it were influence.',
        type = TYPE.MUTATE,
        apply = function(resInfCards)
            for _, resInfCard in ipairs(resInfCards) do
				if resInfCard.influence > resInfCard.resources then
					resInfCard.resources = resInfCard.influence
				elseif resInfCard.resources > resInfCard.influence then
					resInfCard.influence = resInfCard.resources
				end
            end
        end
    },
    -- This modifier isn't quite right, get N votes for EACH time voting.
    -- Comment this out for now (players can manage) until figuring a better way.
    -- ['Zeal'] = {
    --     description = 'When you cast at least 1 vote, cast 1 additional vote for each player in the game, including you',
    --     type = TYPE.CHOOSE,
    --     apply = function(resInfCards)
    --         -- Only applies if votes would otherwise be >0
    --         local votesAvailable = false
    --         for _, resInfCard in ipairs(resInfCards) do
    --             votesAvailable = votesAvailable or (resInfCard.influence > 0)
    --         end
    --
    --         if votesAvailable then
    --             local seatedPlayerZones = _zoneHelper.zones()
    --
    --             table.insert( resInfCards, { name = 'Zeal', resources = 0, influence = #seatedPlayerZones } )
    --         end
    --     end
    -- },
}

local LOCAL_DISTANCE_TO_PLANET = 1.1
local LOCAL_PLANET_RADIUS = 0.8
local LOCAL_SYSTEM_TILE_RADIUS = 2.26
local LOCAL_SYSTEM_TILE_Y = 0.094 -- mesh Y is -0.1062 to 0.0937

--- Get all systems.
-- @return table: map from tile GUID to system table.
function systems()
    for guid, system in pairs(_systems) do
        _fillMissingSystemData(guid, system)
    end
    return _systems
end

--- Get all planets.
-- @return table: map from LOWERCASE planet name to planet table.
function planets()
    local result = {}
    for _, system in pairs(_systems) do
        for _, planet in ipairs(system.planets or {}) do
            result[string.lower(planet.name)] = planet
        end
    end
    return result
end

--- Get system at position.
-- @param postition (table): {xyz} position.
-- @return system table.
function systemFromPosition(position)
    assert(type(position) == 'table' and type(position.x) == 'number')
    -- Ray cast not always reliable, use box.
    local hits = Physics.cast({
        origin = { x = position.x, y = position.y, z = position.z },
        direction = { x = 0, y = -1, z = 0 },
        type = 3, -- box
        size = { 0.1, 10, 0.1 }
    })
    for _, hit in ipairs(hits) do
        local guid = hit.hit_object.getGUID()
        local system = systemFromGuid(guid)
        if system then
            return system
        end
    end
end

-- Get systems at positions. Does NOT use ray-casting like "systemFromPosition".
-- @param Map of arbitrary key to {xyz} position
-- @return Map of same arbitrary key to system attributes or false
function systemsFromPositions(keysToPositions)
    assert(type(keysToPositions) == 'table')

    -- Fill in extra system data
    local systems = systems()

    -- Get position of each system
    local systemGuidToPosition = {}
    for _, object in ipairs(getAllObjects()) do
        local guid = object.getGUID()
        if systems[guid] then
            systemGuidToPosition[guid] = object.getPosition()
        end
    end

    -- Get hex of each system
    local systemGuidToHexes = hexesFromPositions(systemGuidToPosition)
    -- Build reverse map (of system GUID to hex)
    local systemHexToGuid = {}
    for systemGuid, hex in pairs(systemGuidToHexes) do
        if hex then
            -- Warn (without failing) when a system already occupies this hex position (meaning the tiles are overlapping).
            if systemHexToGuid[hex] then
                print('WARNING: System tiles are overlapping at hex coordinate ' .. hex .. ' (' .. _systems[systemGuid].string .. ' and ' .. _systems[systemHexToGuid[hex]].string .. '). Some functions may be affected.')
            else
                systemHexToGuid[hex] = systemGuid
            end
        end
    end

    -- Get hex of each input key
    local inputKeyToHexes = hexesFromPositions(keysToPositions)

    -- Get system for each input key, using hex coordinate maps as a bridge
    local keysToSystems = {}
    for inputKey, hex in pairs(inputKeyToHexes) do
        local systemGuid = systemHexToGuid[hex]

        if systemGuid then
            keysToSystems[inputKey] = assert(systems[systemGuid])
        else
            keysToSystems[inputKey] = false
        end
    end

    return keysToSystems
end

--- Get system with the given tile number.
-- @param tile (number).
-- @return system table.
function systemFromTile(tile)
    for guid, system in pairs(_systems) do
        if system.tile == tile then
            _fillMissingSystemData(guid, system)
            return system
        end
    end
end

--- Get system from tile guid.
-- @param guid (string): system tile guid.
-- @return system table.
function systemFromGuid(guid)
    local system = _systems[guid]
    if system then
        _fillMissingSystemData(guid, system)
        return system
    end
end

--- Get planet at position.
-- Normally finds the closest planet after carving the system tile into zones,
-- optionally require position to be inside planet radius (via params.exact).
-- @params table: { systemGuid, position{xyz}, exact boolean }
-- @return planet table.
function planetFromPosition(params)
    assert(type(params) == 'table')
    local systemGuid = assert(params.systemGuid)
    local position = assert(params.position)
    local exact = params.exact
    assert(type(systemGuid) == 'string')
    assert(type(position) == 'table' and type(position.x) == 'number')
    local system = systemFromGuid(systemGuid)
    local best = false
    if system then
        local object = getObjectFromGUID(system.guid)
        local p1 = object.positionToLocal(position)
        local bestDistanceSq = false
        for _, planet in ipairs(system.planets or {}) do
            local p2 = assert(planet.position)
            local distanceSq = (p1.x - p2.x) ^ 2 + (p1.z - p2.z) ^ 2
            if not bestDistanceSq or distanceSq < bestDistanceSq then
                best = planet
                bestDistanceSq = distanceSq
            end
        end
        if best and exact and math.sqrt(bestDistanceSq) > best.radius then
            best = false
        end
    end
    return best
end

--- Get map from wormhole type to object guids.
-- @param playerColor (string) : player color or nil
function wormholes(playerColor)
    assert(not playerColor or type(playerColor) == 'string')
    local result = {
        ['alpha'] = {
            guids = {},
            connected = { 'alpha' }
        },
        ['beta'] = {
            guids = {},
            connected = { 'beta' }
        },
        ['delta'] = {
            guids = {},
            connected = { 'delta' }
        },
        ['gamma'] = {
            guids = {},
            connected = { 'gamma' }
        },
		['epsilon'] = {
            guids = {},
            connected = { 'epsilon' }
        },
		['ingress'] = {
            guids = {},
            connected = { 'egress' }
        },
		['egress'] = {
            guids = {},
            connected = { 'ingress' }
        },
		['breach'] = {
            guids = {},
            connected = { 'breach' }
        },
    }

    local function addGuid(wormhole, guid)
        table.insert(result[wormhole].guids, guid)
    end

    local function addConnection(src, dst)
        for _, existing in ipairs(result[src].connected) do
            if existing == dst then
                return
            end
        end
        table.insert(result[src].connected, dst)
    end

    -- Ghosts (or Franken with the ability) connect A/B.
    local faction = playerColor and _factionHelper.fromColor(playerColor)
    for _, ability in ipairs(faction and faction.abilities or {}) do
        if ability == 'Quantum Entanglement' then
            addConnection('alpha', 'beta')
            addConnection('beta', 'alpha')
        end
    end

    -- Non-system wormhole objects.
    local objectNameToNonSystemWormholes = {
        ['Alpha Wormhole Token'] = { 'alpha' },
        ['Beta Wormhole Token'] = { 'beta' },
        ['Hil Colish'] = { 'delta' },
        ['Gamma Wormhole Token'] = { 'gamma' },
		['Ingress Token'] = { 'ingress' },
    }

    for _, object in ipairs(getAllObjects()) do
        if object.tag ~= 'Bag' then
            local guid = object.getGUID()
            local name = object.getName()

            local system = systemFromGuid(guid)
            local nonSystemWormholes = objectNameToNonSystemWormholes[name]

            if system then
                for _, wormhole in ipairs(system.wormholes or {}) do
                    addGuid(wormhole, guid)
                end
            elseif nonSystemWormholes then
                for _, wormhole in ipairs(nonSystemWormholes) do
                    addGuid(wormhole, guid)
                end
            end

            if name == 'Ion Storm Token' then
                local wormholeSide = 'alpha'
                if object.is_face_down then
                    wormholeSide = 'beta'
                end
                addGuid(wormholeSide, guid)
            end
			
			if name == 'Breach Token' then
                if not object.is_face_down then
                    addGuid('breach', guid)
                end
            end

            if name == 'Wormhole Reconstruction' and (not object.is_face_down) and (not _deckHelper.isDiscard(guid)) then
                addConnection('alpha', 'beta')
                addConnection('beta', 'alpha')
            end

            if name == 'Lost Star Chart' and (not object.is_face_down) and (not _deckHelper.isDiscard(guid)) then
                addConnection('alpha', 'beta')
                addConnection('beta', 'alpha')
            end

            -- Ghosts agent.
            if name == 'Emissary Taivra' and (not object.is_face_down) and _unitHelper._isToggleActiveCardActive(object) then
                local activeSystem = getActivatedSystem()
                if activeSystem then
                    _fillMissingSystemData(activeSystem.guid, activeSystem)
                    for _, wormhole in ipairs(activeSystem.wormholes or {}) do
                        if wormhole ~= 'delta' then
                            addConnection('alpha', 'beta')
                            addConnection('alpha', 'gamma')
                            addConnection('alpha', 'delta')
                            addConnection('beta', 'gamma')
                            addConnection('beta', 'delta')
                            addConnection('gamma', 'delta')
                            break
                        end
                    end
                end
            end
        end
    end

    return result
end

--- Get non-planet items that affect resources and/or influence.
-- DEPRECATED.  PLEASE USE getColorToResInfCards, getColorToResInfModifiers, applyResInfModifiers.
-- @return table: map from LOWERCASE object name to {name,resources,influence} table.
function nonPlanetResourceInfluenceCards()
    local result = {}
    for _, item in ipairs(_nonPlanetResourceInfluenceCards) do
        if item.get then
            item = copyTable(item)
            item.influence, item.resources = item.get()
            item.get = nil --dont pass functions to other scripts
        end
        result[string.lower(item.name)] = item
    end
    return result
end

--- Get resource/influence cards.
-- @param includeFaceDown (boolean): include face down cards.
-- @return table: map from color list of { name, res, inf } tables.
function getColorToResInfCards(includeFaceDown)
    assert((not includeFaceDown) or type(includeFaceDown) == 'boolean')

    local cardToValues = {}
    for _, system in pairs(_systems) do
        for _, planet in ipairs(system.planets or {}) do
            cardToValues[planet.name] = { -- only res/inf fields
                name = planet.name,
                resources = planet.resources or 0,
                influence = planet.influence or 0
            }
        end
    end
    for _, entry in ipairs(_nonPlanetResourceInfluenceCards) do
        cardToValues[entry.name] = entry
    end

    local guidToPosition = {}
    local guidToValues = {}
    local inHandGuidSet = _zoneHelper.inHand()
    local function getValues(object)
        if object.tag ~= 'Card' then
            return false
        elseif inHandGuidSet[object.getGUID()] then
            return false
        end
        local values = cardToValues[object.getName()]
        if not values then
            return false
        end
        if object.is_face_down then
            if values.requireFaceUp or (not includeFaceDown) then
                return false
            end
        end
        if values.get then
            values.influence, values.resources = values.get(object)
            values = copyTable(values)--sending functions to other scripts will cause an error
            values.get = nil
        end
        return values
    end
    for _, object in ipairs(getAllObjects()) do
        local values = getValues(object)
        if values then
            local guid = object.getGUID()
            guidToPosition[guid] = object.getPosition()
            guidToValues[guid] = values
        end
    end

    local colorToResInfCards = {}
    for _, color in ipairs(_zoneHelper.zones()) do
        colorToResInfCards[color] = {}
    end
    local guidToColor = _zoneHelper.zonesFromPositions(guidToPosition)
    for guid, color in pairs(guidToColor) do
        local values = guidToValues[guid]
        local entry = colorToResInfCards[color]
        table.insert(entry, values)
    end
    return colorToResInfCards
end

--- Get non-trivial modifiers.
-- @return table: map from color to list of modifier names.
function getColorToResInfModifiers()
    local guidToPosition = {}
    local guidToName = {}
    local inHandGuidSet = _zoneHelper.inHand()
    for _, object in ipairs(getAllObjects()) do
        local guid = object.getGUID()
        if object.tag == 'Card' and (not inHandGuidSet[guid]) and (not object.is_face_down) then
            local name = object.getName()
            local modifier = _resInfModifiers[name]
            if modifier then
                local position = object.getPosition()
                guidToPosition[guid] = position
                guidToName[guid] = name
            end
        end
    end

    local colorToResInfModifiers = {}
    local function addModifier(color, modifier)
        local entry = colorToResInfModifiers[color]
        if not entry then
            entry = {}
            colorToResInfModifiers[color] = entry
        end
        for _, value in ipairs(entry) do
            if value == modifier then
                return
            end
        end
        table.insert(entry, modifier)
    end

    for _, color in ipairs(_zoneHelper.zones()) do
        colorToResInfModifiers[color] = {}
    end
    local guidToColor = _zoneHelper.zonesFromPositions(guidToPosition)
    for guid, color in pairs(guidToColor) do
        local name = guidToName[guid]
        addModifier(color, name)
    end

    -- Add faction abilities
    for color, faction in pairs(_factionHelper.allFactions()) do
        for _, ability in ipairs(faction and faction.abilities or {}) do
            if _resInfModifiers[ability] then
                addModifier(color, ability)
            end
        end
    end

    -- Apply alliances, imperia.
    local colorToCommanders = _factionHelper.getColorToCommanders()
    for color, commanders in pairs(colorToCommanders) do
        for _, commander in ipairs(commanders) do
            if _resInfModifiers[commander] then
                addModifier(color, commander)
            end
        end
    end

    return colorToResInfModifiers
end

--- Return modifier descriptions.
-- @param resInfModifiers (table) : list of modifier names.
-- @return (table) : map from name to description.
function getResInfModifierDescriptions(resInfModifiers)
    assert(type(resInfModifiers) == 'table')
    local result = {}
    for _, name in ipairs(resInfModifiers) do
        local modifier = _resInfModifiers[name]
        if modifier then
            result[name] = assert(modifier.description)
        end
    end
    return result
end

--- Compute resource/influcence.
-- @return {resource=#,influence=#} table.
function applyResInfModifiers(params)
    assert(type(params) == 'table')
    assert(type(params.cards) == 'table')
    assert(type(params.modifiers) == 'table')

    local cards = copyTable(params.cards)  -- do not modify in place

    -- Apply MUTATE first to add/remove attributes.
    for _, modifier in ipairs(params.modifiers) do
        assert(type(modifier) == 'string')
        local modifier = _resInfModifiers[modifier]
        if modifier and modifier.type == TYPE.MUTATE then
            modifier.apply(cards)
        end
    end

    -- Apply ADJUST to update (but not add/remove) values.
    for _, modifier in ipairs(params.modifiers) do
        assert(type(modifier) == 'string')
        local modifier = _resInfModifiers[modifier]
        if modifier and modifier.type == TYPE.ADJUST then
            modifier.apply(cards)
        end
    end

    -- Apply CHOOSE to apply effects based on adjusted attributes.
    for _, modifier in ipairs(params.modifiers) do
        assert(type(modifier) == 'string')
        local modifier = _resInfModifiers[modifier]
        if modifier and modifier.type == TYPE.CHOOSE then
            modifier.apply(cards)
        end
    end

    return cards
end

function verifyAllSystems()
    local errors = false
    for guid, system in pairs(_systems) do
        local success, errorMessage = _systemIsValid(system)
        if not success then
            errors = errors or {}
            table.insert(errors, guid .. ': ' .. errorMessage)
        end
    end
    if errors then
        error('verifyAllSystems ' .. table.concat(errors, ', '))
    end
    print('verifyAllSystems: success')
end

--- Verify system follows expectations.
-- @parameters table: system.
-- @return success boolean, string error message.
function _systemIsValid(system)
    local tile = system.tile
    if not tile or type(tile) ~= 'number' then
        return false, 'system.tile must be a number (zero can be used for homebrew)'
    end
    local home = system.home
    if home and type(home) ~= 'boolean' then
        return false, 'system.home must be nil or a boolean'
    end

    local planets = system.planets
    if planets and (type(planets) ~= 'table') then
        return false, 'system.planets must be nil or a list'
    elseif planets then
        for _, planet in ipairs(planets) do
            local name = planet.name
            if not name or type(name) ~= 'string' or string.len(name) == 0 then
                return false, 'planet.name must be a non-empty string'
            end
            local radius = planet.radius
            if radius and (type(radius) ~= 'number' or radius <= 0) then
                return false, 'planet.radius must be nil or a positive number'
            end
            local position = planet.position
            if position and (type(position) ~= 'table' or type(position.x) ~= 'number' or type(position.x) ~= 'number') then
                return false, 'planet.position must be nil or a local {x, z} table'
            end
            local resources = planet.resources
            if resources and (type(resources) ~= 'number' or resources < 0) then
                return false, 'planet.resources must be nil or a non-negative number'
            end
            local influence = planet.influence
            if influence and (type(influence) ~= 'number' or influence < 0) then
                return false, 'planet.influence must be nil or a non-negative number'
            end
            local techs = type(planet.tech) == "string" and {planet.tech} or planet.tech or {}
            for _,eachTech in ipairs(techs) do
                if eachTech ~= 'red' and eachTech ~= 'green' and eachTech ~= 'yellow' and eachTech ~= 'blue' then
                    return false, planet.name"'s .tech must be {red|green|yellow|blue}"
                end
            end
            local traits = type(planet.trait) == "string" and {planet.trait} or planet.trate or {}
            for _,eachTrait in ipairs(traits) do
                if eachTrait ~= 'cultural' and eachTrait ~= 'industrial' and eachTrait ~= 'hazardous' then
                    return false, planet.name.."'s .trait must be {cultural|industrial|hazardous}"
                end
            end
            local legendary = planet.legendary
            if legendary and (type(legendary) ~= 'boolean') then
                return false, 'planet.legendary must be {true|false}'
            end
        end
    end

    local wormholes = system.wormholes
    if wormholes then
        if type(wormholes) ~= 'table' or not wormholes[1] then
            return false, 'system.wormholes must be nil or a non-empty list'
        end
        for _, wormhole in ipairs(wormholes) do
            if not type(wormhole) == 'string' or string.len(wormhole) == 0 then
                return false, 'wormhole must be a non-empty string'
            end
        end
    end

    local anomalies = system.anomalies
    if anomalies then
        if type(anomalies) ~= 'table' or not anomalies[1] then
            return false, 'system.anomalies must be nil or a non-empty list'
        end
        for _, anomaly in ipairs(anomalies) do
            if not type(anomaly) == 'string' or string.len(anomaly) == 0 then
                return false, 'anomaly must be a non-empty string'
            end
        end
    end

    return true
end

--- Get system as printable string (stored in system.string)
-- @param system table.
-- @return string.
function _systemToString(system)
    assert(type(system) == 'table' and system.tile)
    local function capitalizeWords(words)
        local words, _ = words:gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
        return words
    end
    local message = {
        'System ' .. system.tile
    }
    for _, planet in ipairs(system.planets or {}) do
        table.insert(message, #message == 1 and ': ' or ', ')
        table.insert(message, '“' .. planet.name .. '”')
    end
    for _, wormhole in ipairs(system.wormholes or {}) do
        table.insert(message, #message == 1 and ': ' or ', ')
        table.insert(message, capitalizeWords(wormhole) .. ' Wormhole')
    end
    for _, anomaly in ipairs(system.anomalies or {}) do
        table.insert(message, #message == 1 and ': ' or ', ')
        table.insert(message, capitalizeWords(anomaly))
    end
    if system.hyperlane then
        table.insert(message, #message == 1 and ': ' or ', ')
        table.insert(message, 'Hyperlane')
    end
    return table.concat(message, '')
end

--- Convert local bearing coordinate to local XYZ.
function _bearingToPosition(bearing, distance, y)
    assert(type(bearing) == 'number' and 0 <= bearing and bearing < 360 and type(distance) == 'number')
    local bearing = -bearing * math.pi / 180.0
    return {
        x = distance * math.sin(bearing),
        y = y or 0,
        z = -distance * math.cos(bearing)
    }
end

--- Split a system into zones, one for each planet/wormhole.
function _getZoneBorders(system)
    assert(type(system) == 'table' and system.tile)
    local numPlanets = system.planets and #system.planets or 0
    local numWormholes = system.wormholes and #system.wormholes or 0
    local numZones = numPlanets + numWormholes

    -- The local coordinate space for a tile shows {x=1,z=1} to be lower left.
    -- Set zone borders to track planets starting left going clockwise.
    local zoneBorders
    if numZones <= 1 then
        zoneBorders = { 0, 360 }
    elseif numZones == 2 then
        zoneBorders = { 240, 60, 240 }
    elseif numZones == 3 then
        zoneBorders = { 210, 330, 90, 210 }
    else
        -- Mallice has a planet plus three wormholes.  Treat excessive as one zone.
        zoneBorders = { 0, 360 }
    end

    -- Support non-standard rotations (applies to a TI3 tile).
    for i, v in ipairs(zoneBorders) do
        zoneBorders[i] = (v + (system.rotate or 0)) % 360
    end
    return zoneBorders
end

--- Get planet location in local space.  Account for tile variations.
function _planetPosition(system, zoneBorders, planetIndex)
    assert(type(system) == 'table' and system.tile)
    local planet = system.planets[planetIndex]
    local localRadius = planet.radius or LOCAL_PLANET_RADIUS
    local localY = system.localY or LOCAL_SYSTEM_TILE_Y

    -- If planet already has a position, use it.
    if planet.position then
        return { x = planet.position.x, y = localY, z = planet.position.z }, localRadius
    end

    -- Compute the default bearing and distance.
    local distanceToPlanet = 0
    local bearingToPlanet = 0
    if #zoneBorders > 2 then
        local a = zoneBorders[planetIndex]
        local b = zoneBorders[planetIndex + 1]
        if a < b then
            bearingToPlanet = (a + b) / 2
        else
            bearingToPlanet = ((a + 360 + b) / 2) % 360
        end
        distanceToPlanet = LOCAL_DISTANCE_TO_PLANET
    end

    -- Planets bearings are almost but not exactly in the center of their zones.
    -- Home system planets are slightly offset.  Different same-number-of-planets
    -- systems vary slightly, so unless want to hard code each tile this is close.
    local numZones = #zoneBorders - 1
    if numZones == 1 then
        if system.home then
            distanceToPlanet = 0.25
            bearingToPlanet = 0
        else
            distanceToPlanet = 0.1
            bearingToPlanet = 180
        end
    elseif numZones == 2 then
        if planetIndex == 1 then
            if system.home then
                distanceToPlanet = distanceToPlanet - 0.05
                bearingToPlanet = bearingToPlanet + 2
            else
                distanceToPlanet = distanceToPlanet - 0.17
                bearingToPlanet = bearingToPlanet - 0
            end
        elseif planetIndex == 2 then
            if system.home then
                distanceToPlanet = distanceToPlanet - 0
                bearingToPlanet = bearingToPlanet - 17
            else
                distanceToPlanet = distanceToPlanet - 0.07
                bearingToPlanet = bearingToPlanet - 1
            end
        end
    elseif numZones == 3 then
        if planetIndex == 1 then  -- hercant
            if system.home then
                distanceToPlanet = distanceToPlanet + 0.1
                bearingToPlanet = bearingToPlanet + 5
            else
                distanceToPlanet = distanceToPlanet + 0.3
                bearingToPlanet = bearingToPlanet + 8
            end
        elseif planetIndex == 2 then
            if system.home then
                distanceToPlanet = distanceToPlanet + 0.01
                bearingToPlanet = bearingToPlanet - 0
            else
                distanceToPlanet = distanceToPlanet - 0.02
                bearingToPlanet = bearingToPlanet + 4
            end
        elseif planetIndex == 3 then
            if system.home then
                distanceToPlanet = distanceToPlanet + 0.22
                bearingToPlanet = bearingToPlanet - 7
            else
                distanceToPlanet = distanceToPlanet + 0.22
                bearingToPlanet = bearingToPlanet - 2
            end
        end
    end

    return _bearingToPosition(bearingToPlanet, distanceToPlanet, localY), localRadius
end

--- Fill in system fields (only done on the first access, then reused).
function _fillMissingSystemData(guid, system)
    assert(type(guid) == 'string' and type(system) == 'table' and system.tile)
    if not system.guid then
        system.guid = guid
        system.string = _systemToString(system)
        system.y = system.localY or LOCAL_SYSTEM_TILE_Y

        -- Fill zone edge positions, points on edge diving per-planet zones.
        local zoneBorders = _getZoneBorders(system)
        if #zoneBorders > 2 then
            system.zoneEdgePositions = {}
            local r = LOCAL_SYSTEM_TILE_RADIUS
            local y = system.localY or LOCAL_SYSTEM_TILE_Y
            for i = 1, #zoneBorders - 1 do
                local bearing = zoneBorders[i]
                table.insert(system.zoneEdgePositions, _bearingToPosition(bearing, r, y))
            end
        end

        -- Fill in local planet position, radius.
        for i, planet in ipairs(system.planets or {}) do
            planet.position, planet.radius = _planetPosition(system, zoneBorders, i)
        end
    end

    -- If a system has face-up/face-down attributes, reset based on state.
    for k, v in pairs(system) do
        local attrName, side = string.match(k, '^(.*)_face(.*)$')
        local systemObject = attrName and getObjectFromGUID(guid)
        if attrName and systemObject then
            if systemObject.is_face_down then
                if side == 'Down' then
                    system[attrName] = v
                end
            else
                if side == 'Up' then
                    system[attrName] = v
                end
            end
        end
    end
end

-----------------------------------------------------------------------------

--Objects that have some effect when dropped in a system (Diplo/Warfare token, ect, injectable)
local DropUtils = {
    _activeDrops = {},
    animate = function(col, system, obj)
        local base = obj.getScale()
        obj.interactable = false
        obj.use_gravity = false
        obj.setPosition(obj.getPosition()) --kill momentum
        obj.setLock(true)
        local hb = obj.getComponent("Collider")
        hb.set("enabled", false)
        local scaleMod = 1.75
        for i = 0, 30 do
            coroutine.yield()
            if obj == nil then print("escaped on ",i) return end
            local rad = math.sin((i*6*math.pi)/180)
            local scale = {x = base.x+(scaleMod*rad), z = base.z+(scaleMod*rad), y = base.y}
            obj.setScale(scale)
        end
        obj.setScale(base)
        obj.interactable = true
        obj.use_gravity = true
        obj.setLock(false)
        hb.set("enabled", true)
    end,
    doNothing = function() end
}
local _systemDroppables = {
    ["Diplomacy Token"] = {
        requireTurn = false,
        onDrop = {function(color,system) _diploSystem(color, system) end},
        returnInfo = {position = {x=6.43,y = 3, z=-2.47}, rotation = {y = -30}, parent = "4ffb3b"},
        onConsume = {DropUtils.animate, function(color, system, obj) DropUtils.returnComponent(color, system, obj) end}
    },
    ["Activation Token"] = {
        requireTurn = false,
        onDrop = {function(color,system) _activateSystem(color,system) end},
        returnInfo = {position = {x=-6.33,z=-2.3}, rotation = {y = 27}, parent = "4ffb3b"},
        onConsume = {DropUtils.animate, function(color,system,obj) DropUtils.returnComponent(color,system,obj) end}
    },
    ["Scepter of Dominion"] = {
        requireTurn = false,
        onDrop = {function(color,system) _scepterDiplo(color,system) end},
        returnInfo = {position = {y=4}, parent = "TI4 Graveyard"},
        onConsume = {DropUtils.animate, function(color,system,obj) DropUtils.returnComponent(color,system,obj) end}
    }
}

DropUtils.onDrop = function(color, obj, objName)
    if DropUtils._activeDrops[obj] then
        printToColor(("Drop effect failed: "..objName.."'s drop effect is already being resolved."), color, "Red")
        return
    end

    local dropData = assert(_systemDroppables[(objName or obj.getName())])
    if dropData.requireTurn and color ~= Turns.turn_color then
        return
    end
    local system = systemFromPosition(obj.getPosition())
    if not system then return end

    DropUtils._activeDrops[obj] = true
    resolveDropCo = function()
        for i,each in ipairs(dropData.onDrop or {}) do
            each(color, system, obj)
        end
        coroutine.yield()
        for i,each in ipairs(dropData.onConsume or {}) do
            each(color, system, obj)
        end
        coroutine.yield()
        DropUtils._activeDrops[obj] = nil
        return 1
    end
    startLuaCoroutine(self, "resolveDropCo")
end

DropUtils.returnComponent = function(col,system, obj)
    if obj == nil then return end
    local dropData = _systemDroppables[obj.getName()]
    if not dropData or not dropData.returnInfo then return end

    position = dropData.returnInfo.position or {}
    local pos = {x = position.x or 0, y = position.y or 1, z = position.z or 0}

    local parent = dropData.returnInfo.parent
    if parent then
        if type(parent) == "string" then
            --guid?
            local pObj = getObjectFromGUID(parent)
            if not pObj then --find by name
                for _,each in ipairs(getAllObjects()) do
                    if each.getName() == parent then
                        pObj = each
                        break
                    end
                end
            end
            parent = pObj
        end
        if type(parent) == "userdata" then
            pos = parent.positionToWorld(pos)
        end
    end
    obj.setPosition(pos)

    if(dropData.returnInfo.rotation) then
        local pRot = parent and parent.getRotation() or {x = 0, y = 0, z = 0}
        obj.setRotation({
            x = pRot.x + (dropData.returnInfo.rotation.x or 0),
            y = pRot.y + (dropData.returnInfo.rotation.y or 0),
            z = pRot.z + (dropData.returnInfo.rotation.z or 0),
        })
    end
end

--Injection-----------------------------------------------------------------------------

--Previous iterations of the TI4_EXPLORE_HELPER usded injectSystem to modify systems; redirecting those calls here
--func is error-advers, makes assumptions that the caller is passing a valid system, applies less checks, and does not auto-inject Space Station data
function modifySystem(system)
    if not system or not type(system) == "table" or not system.guid then return end

    _systems[system.guid] = copyTable(system)
end

--- Let brew add custom systems via runtime injection.
-- @param system: system table.
function injectSystem(system)
    assert(type(system) == 'table')

    -- Unclear if the systems are shared with the caller, make a copy to be
    -- sure any later mutations to the caller's version does not change this.
    system = copyTable(system)

    local guid = system.guid
    if not guid or type(guid) ~= 'string' then
        error('injectSystem: missing guid')
    end
    local success, errorMessage = _systemIsValid(system)
    if not success then
        error('injectSystem: ' .. guid .. ' ' .. errorMessage)
    end
    system.guid = nil  -- force rebuild of any auto-generated fields
    system._homebrew = true
    _systems[guid] = system
    _fillMissingSystemData(guid, system)

    --Auto-inject any stations for commodity modifiers
    for _,each in ipairs(system.planets or {}) do
        if each.station then
            _exploreHelper.injectAttachmentToken({name = each.stationTokenName or (each.name.." Token"), fetchedBy = each.name})
            _factionHelper.injectCommodityModifier({name = each.name, value = type(each.station) == "number" and each.station or 1})
        end
    end
end

--Create a card or object that can be spent as resources or influence
---@param params.name string : Name should match the card object's name
---@param params.resources number? : The resource value
---@param params.influence number? : The influence value
---@param params.get table? : A CallData table that points to a function that returns the resource and influence value
    --CallData table: {guid = 'guid of the script object that owns your function', func = 'function name to call'}
    --Your function will recieve the object reference of the card object as the only param. Return 2 values (influence, resources)
function injectResourceInfluenceModifier(params)
    assert(type(params.name) == 'string', 'bad name')
    assert((not params.resource) or type(params.resource) == 'number', 'bad resource')
    assert((not params.influence) or type(params.influence) == 'number' , 'bad influence')
    
    local mod = copyTable(params)
    if mod.get then
        assert(mod.get.guid and type(mod.get.guid) == "string", 'Invalid CallData table for '..mod.name..': non-string guid')
        assert(mod.get.func and type(mod.get.func) == "string", "Invalid CallData table for "..mod.name..": non-string .func")
        mod.callData = mod.get
        mod.get = function(card)
            local script = mod.callData.obj ~= nil and mod.callData.obj or getObjectFromGUID(mod.callData.guid)
            if not script then return 0,0 end
            mod.callData.obj = script
            assert(script.getVar(mod.callData.func), script.getName().." does not have a global function called: "..mod.callData.func)
            local i,r = script.call(mod.callData.func, card)
            return i or 0, r or 0
        end
    end
    
    for i, entry in ipairs(_nonPlanetResourceInfluenceCards) do
        if entry.name == mod.name then
            _nonPlanetResourceInfluenceCards[i] = mod
            return
        end
    end
    table.insert(_nonPlanetResourceInfluenceCards, mod)
end

--Create an object that resolves some effect when dropped into a system (like Diplo/Activation tokens)
---@param params.name string : Name should match the physical object
---@param params.requireTurn boolean? : Does the dropping player need to be the active player? *defaults false
---@param params.returnInfo table? : Optional table for defining where the token returns to {position = {}, parent = "guid"|"ObjName"|objRef}
---@param params.onDrop table : Funtions that will run when the object is dropped: array of strings and CallData tables. *details below
---Available strings for onDrop are "ACTIVATE" and "DIPLO", all other values must be a CallData table *defined below
---@param params.onConsume table : What happens after the effect is resolved : array of strings and CallData tables. *details below
---Available strings for onConsume are "ANIMATE" and "RETURN", all other values must be a CallData table *defined below
---onDrop and onConsume resolves each function in the order they are listed in the array; these functions can be coroutines spanning multiple frames
    --To pass your own function, insert a CallData table into the array
    --CallData table: {func = "nameOfYourFunc", guid = "scriptOwnerGUID"}
    --param: Your functions will recieve the following table: {color = "WhoDroppedTheToken", obj = tokenObjReference, system}
    --return: If you return anything other than a thread, the process will imediately call the next func
        --for advanced async functions(perhaps multi-frame animation) return a thread
        --When the thread(coroutine) ends, that tells the process that your func is done.
        --Use the following return line in your function where "isDone" is defined in your coroutine and is set to true when completed
        --return coroutine.create(function() while not isDone do coroutine.yield() end return end)
function injectSystemDroppable(params)
    assert(params, "Missing params to injectSystemDroppable")
    assert(type(params.name) == "string", "injectSystemDroppable() requires a 'string' params.name field")
    local newDrop = {
        requireTurn = params.requireTurn,
        returnInfo = params.returnInfo,
        onDrop = {},
        onConsume = {}
    }

    --Wrap drop/consume function calls
    local function newCall(callData, callStep)
        assert(type(callData) == "table", "Invalid type provided to injectSystemDroppable."..callStep..": "..type(callData))
        local prefix = "Invalid CallaData table provided to injectSystemDroppable."..callStep..": "
        assert(type(callData.func) == "string", prefix.."CallData.func must be the string name of your function")
        assert(type(callData.guid) == "string", prefix.."CallData.guid must be the string guid of your script object")
        local func, guid, callObj = callData.func, callData.guid, getObjectFromGUID(callData.guid)
        return function(color, system, obj)
            if callObj == nil then callObj = getObjectFromGUID(guid) end
            if callObj == nil or not callObj.getVar(func) then return end

            local result = callObj.call(func, {obj = obj, color = color, system = system})
            if result and type(result) == "thread" then
                local timeout = Time.time
                local status = coroutine.status(result)
                while status ~= "dead" and Time.time - timeout < 60 do
                    if status == "suspended" then
                        coroutine.resume(result)
                        status = coroutine.status(result)
                    end
                    coroutine.yield()
                end
            end
        end
    end

    local DropOptions = {ACTIVATE = _activateSystem, DIPLO = _diploSystem}
    for _,each in ipairs(params.onDrop or {}) do
        if type(each) == "string" then
            assert(DropOptions[each], "Unsupported preset in injectSystemDroppable.onDrop: "..each)
            table.insert(newDrop.onDrop, DropOptions[each])
        else
            table.insert(newDrop.onDrop, newCall(each, "onDrop"))
        end
    end

    local ConsumeOptions = {ANIMATE = DropUtils.animate, RETURN = DropUtils.returnComponent}
    for _,each in ipairs(params.onConsume or {}) do
        if type(each) == "string" then
            assert(ConsumeOptions[each], "Unsupported preset in injectSystemDroppable.onConsume: "..each)
            table.insert(newDrop.onConsume, ConsumeOptions[each])
        else
            table.insert(newDrop.onConsume, newCall(each, "onConsume"))
        end
    end

    _systemDroppables[params.name] = newDrop
end

-------------------------------------------------------------------------------

--- Make sure system tile is grid aligned and laying flat.
function lockSystemTile(tileGuid)
    assert(type(tileGuid) == 'string')
    local object = getObjectFromGUID(tileGuid)
    if object then
        -- Get grid position.
        local hex = hexFromPosition(object.getPosition())
        local pos = hexToPosition(hex)

        -- Place so laying flat on table surface.
        local h = object.getBoundsNormalized().size.y
        pos.y = _zoneHelper.getTableY() + (h / 2) - 0.01

        -- Rotation (expect y = 0 or 180).
        local rot = object.getRotation()
        rot = {
            x = math.floor(rot.x + 0.5),
            y = math.floor(rot.y + 0.5),
            z = math.floor(rot.z + 0.5)
        }

        object.setPosition(pos)
        object.setRotation(rot)
        object.setLock(true)
    end
end

function summarizeTiles(tiles)
    assert(type(tiles) == 'table')
    local r = 0
    local i = 0
    local tech = {}
    local legendary = 0
    local wormholes = {}

    -- local wormholeToSymbol = {
    --     ['alpha'] = '\u{03B1}',
    --     ['beta'] = '\u{03B2}',
    --     ['delta'] = '\u{03B3}',
    --     ['gamma'] = '\u{03B4}',
    -- }
    local wormholeToSymbol = {
        ['alpha'] = 'α',
        ['beta'] = 'β',
        ['delta'] = 'δ',
        ['gamma'] = 'γ',
    }
    for _, tile in ipairs(tiles) do
        local system = systemFromTile(tile)
        if not system then
            error('summarizeTiles: bad tile ' .. tile)
        end
        for _, planet in ipairs(system.planets or {}) do
            r = r + (planet.resources or 0)
            i = i + (planet.influence or 0)
            if planet.tech then
                local _techs = type(planet.tech) == "string" and {planet.tech} or planet.tech
                for _,each in ipairs(_techs) do
                    table.insert(tech, string.sub(each, 1, 1):upper())
                end
            end
            if planet.legendary then
                legendary = legendary + 1
            end
        end
        for _, wormhole in ipairs(system.wormholes or {}) do
            local symbol = wormholeToSymbol[wormhole]
            if symbol then
                table.insert(wormholes, symbol)
            end
        end
    end
    local items = {
        r .. '/' .. i
    }
    if #tech > 0 then
        table.sort(tech)
        table.insert(items, table.concat(tech, '|'))
    end
    if legendary > 0 then
        local n = legendary
        table.insert(items, ((n > 1) and n or '') .. 'L')
    end
    if #wormholes > 0 then
        table.sort(wormholes)
        table.insert(items, table.concat(wormholes, ''))
    end
    return table.concat(items, ' ')
end

-------------------------------------------------------------------------------

-- Heavily distilled hex math based on RedBlobGames excellent hex math.
local _M = {
    -- F matrix translates hex to position.
    f0 = 3.0 / 2.0,
    f1 = 0.0,
    f2 = math.sqrt(3.0) / 2.0,
    f3 = math.sqrt(3.0),
    -- B matrix translates position to hex.
    b0 = 2.0 / 3.0,
    b1 = 0.0,
    b2 = -1.0 / 3.0,
    b3 = math.sqrt(3.0) / 3.0,
    -- Angle to first corner (0 for flat top hex).
    start_angle = 0.0
}

local _LAYOUT = {
    size = { x = (Grid.sizeX or 7) / 2.0, z = (Grid.sizeY or 7) / 2.0 },
    origin = { x = 0, z = 0 }
}

--- Get a hex id from a position.
-- @param position table : {xyz} position.
-- @return hex string.
function hexFromPosition(position)
    assert(type(position) == 'table')

    -- Fractional hex position.
    local p = {
        x = (position.x - _LAYOUT.origin.x) / _LAYOUT.size.x,
        z = (position.z - _LAYOUT.origin.z) / _LAYOUT.size.z
    }
    local q = _M.b0 * p.x + _M.b1 * p.z
    local r = _M.b2 * p.x + _M.b3 * p.z
    local s = -q - r

    -- Round to grid aligned hex.
    local qi = math.floor(0.5 + q)
    local ri = math.floor(0.5 + r)
    local si = math.floor(0.5 + s)
    local q_diff = math.abs(qi - q)
    local r_diff = math.abs(ri - r)
    local s_diff = math.abs(si - s)
    if q_diff > r_diff and q_diff > s_diff then
        qi = -ri - si
    else
        if r_diff > s_diff then
            ri = -qi - si
        else
            si = -qi - ri
        end
    end

    return '<' .. qi .. ',' .. ri .. ',' .. si .. '>'
end

--- Bulk hexFromPosition.
function hexesFromPositions(guidToPosition)
    assert(type(guidToPosition) == 'table')
    local result = {}
    for guid, position in pairs(guidToPosition) do
        result[guid] = hexFromPosition(position)
    end
    return result
end

--- Get a position from a hex.
-- @param hex : hex encoded as string.
-- @return table : position {xyz}.
function hexToPosition(hex)
    assert(type(hex) == 'string')
    local q, r, s = string.match(hex, '<(%-?%d+),(%-?%d+),(%-?%d+)>')
    assert(not (math.floor (0.5 + q + r + s) ~= 0), 'q + r + s must be 0')
    local x = (_M.f0 * q + _M.f1 * r) * _LAYOUT.size.x
    local z = (_M.f2 * q + _M.f3 * r) * _LAYOUT.size.z
    return { x = x + _LAYOUT.origin.x, y = 0, z = z + _LAYOUT.origin.z }
end

-- Bulk hexToPosition
function hexesToPosition(guidToHex)
    assert(type(guidToHex) == 'table')
    local result = {}
    for guid, hex in pairs(guidToHex) do
        result[guid] = hexToPosition(hex)
    end
    return result
end

--- Get clockwise winding corners about a hex.
-- @param hex : hex encoded as string.
-- @return table : list of {xyz} positions.
function hexCorners(hex)
    local center = hexToPosition(hex)
    local function hexCornerOffset(corner)
        local angle = 2.0 * math.pi * (_M.start_angle - corner) / 6.0
        return {
            x = center.x + _LAYOUT.size.x * math.cos(angle),
            y = center.y,
            z = center.z + _LAYOUT.size.z * math.sin(angle)
        }
    end
    local corners = {}
    for i = 0, 5 do
        table.insert(corners, hexCornerOffset(i))
    end
    return corners
end

--- Get clockwise winding neighbors about a hex.
-- @param hex : hex encoded as string.
-- @return table : list of neighbor hex strings.
function hexNeighbors(hex)
    assert(type(hex) == 'string')
    local q, r, s = string.match(hex, '<(%-?%d+),(%-?%d+),(%-?%d+)>')
    local function makeHex(q, r, s)
        return '<' .. q .. ',' .. r .. ',' .. s .. '>'
    end
    return {
        makeHex(q + 1, r + 0, s - 1),
        makeHex(q + 1, r - 1, s + 0),
        makeHex(q + 0, r - 1, s + 1),
        makeHex(q - 1, r + 0, s + 1),
        makeHex(q - 1, r + 1, s + 0),
        makeHex(q + 0, r + 1, s - 1)
    }
end

--- Get wormhole-adjacent hexes.
-- @param params : {hex=string, isGhosts=boolean} table.
-- @return table : list of wormhole-adjacent hex strings.
function hexAdjacentWormholes(params)
    assert(type(params) == 'table')
    assert(type(params.hex) == 'string')
    assert(not params.playerColor or type(params.playerColor) == 'string')
    local hex = params.hex

    local wormholes = wormholes(params.playerColor)
    local wormholesInThisHexSet = {}
    local wormholeToHexSet = {}
    for wormhole, state in pairs(wormholes) do
        wormholeToHexSet[wormhole] = {}
        for _, guid in ipairs(state.guids) do
            local object = getObjectFromGUID(guid)
            local wormholeHex = hexFromPosition(object.getPosition())
            if hex == wormholeHex then
                wormholesInThisHexSet[wormhole] = true
            else
                -- Only include wormholes in other hexes.
                wormholeToHexSet[wormhole][wormholeHex] = true
            end
        end
    end

    local adjacentSet = {}
    for wormhole, _ in pairs(wormholesInThisHexSet) do
        for _, connected in ipairs(wormholes[wormhole].connected) do
            for wormholeHex, _ in pairs(wormholeToHexSet[connected]) do
                adjacentSet[wormholeHex] = true
            end
        end
    end

    local result = {}
    for adjacentHex, _ in pairs(adjacentSet) do
        if adjacentHex ~= hex then
            table.insert(result, adjacentHex)
        end
    end
    return result
end

--- Get neighbors through an hyperlane system
-- @param scrHex (hex) : source hex
-- @param hyperlaneSystem (system) : hyperlane system
-- @return table : list of neighbor hex strings. Will not return hyperlanes hexes.
function getHyperlaneNeighbors(srcHex, hyperlaneSystem, visitedHexSet)
    local hyperlaneObj = getObjectFromGUID(hyperlaneSystem.guid)
    local hyperlaneHex = hexFromPosition(hyperlaneObj.getPosition())
    local hyperlaneNeighbors = hexNeighbors(hyperlaneHex)
    visitedHexSet[srcHex] = true

    local hyperlaneRotation = hyperlaneObj.getRotation().y % 360
    local rotationOffset = math.floor(hyperlaneRotation / 60 + 0.5)
    local idxSrc = 0

    -- Find on which side of the hyperlane the source hex is
    for idx, value in pairs(hyperlaneNeighbors) do
        if value and value == srcHex then
            idxSrc = ((idx - 1 - rotationOffset) % 6) + 1
        end
    end

    local result = {}
    if idxSrc < 1 and idxSrc > 12 then
        log("WARNING getHyperlaneNeighbors : source hex is not adjacent to hyperlane")
        return result
    end

    -- get the list of hexes connected throuh the hyperlane
    local connectedNeighborsIdx = hyperlaneSystem.hyperlanes[idxSrc]
    for _, connectedNeighbor in pairs(connectedNeighborsIdx) do
        local updatedIdx = (connectedNeighbor + rotationOffset) % 6 + 1
        local connectedHex = hyperlaneNeighbors[updatedIdx]

        if connectedHex ~= hyperlaneHex then
            local neighborSystem = systemFromPosition(hexToPosition(connectedHex))
            -- if the connected hex is an hyperlane, keep processing the path
            if neighborSystem and neighborSystem.hyperlanes then
                if not visitedHexSet[connectedHex] then
                    local allConnected = getHyperlaneNeighbors(hyperlaneHex, neighborSystem, visitedHexSet)
                    for _, allConnectedHex in pairs(allConnected) do
                        table.insert(result, allConnectedHex)
                    end
                end
            else
                table.insert(result, connectedHex)
            end
        end
    end
    return result
end

--- Get all adjacent hexes, including hyperlane-connected hexes
-- @param hex : hex encoded as string.
-- @return table : list of neighbor hex strings.
function hexNeighborsWithHyperlanes(hex)

    local allHexesNeighbors = hexNeighbors(hex)
	local currentSystem = systemFromPosition(hexToPosition(hex))
    local connectedNeighbors = {}
    for _, neighborHex in pairs(allHexesNeighbors) do
        local neighborSystem = systemFromPosition(hexToPosition(neighborHex))
        if neighborSystem and neighborSystem.hyperlanes then
            local allConnectedNeighbors = getHyperlaneNeighbors(hex, neighborSystem, {})
            for _, connectedHex in pairs(allConnectedNeighbors) do
                table.insert(connectedNeighbors, connectedHex)
            end
		elseif currentSystem and neighborSystem and (currentSystem.fracture or neighborSystem.fracture) then
			if currentSystem.fracture and neighborSystem.fracture then
				table.insert(connectedNeighbors, neighborHex)
			end
        else
            table.insert(connectedNeighbors, neighborHex)
        end
    end

    -- remove duplicates and self
    local finalResult = {}
    local hash = {}
    for _,v in ipairs(connectedNeighbors) do
        if not hash[v] and v ~= hex then
            table.insert(finalResult, v)
            hash[v] = true
        end
    end

    return finalResult
end

-------------------------------------------------------------------------------

local _activatedSystem = false
local _lastActivatedSystem = false  -- rememeber even when turn changes

--- Get the currently activated system.
-- Objects may declare an 'onSystemActivation(system)' called on activation.
function getActivatedSystem()
    return _activatedSystem
end

function getLastActivatedSystem()
    return _lastActivatedSystem
end

-------------------------------------------------------------------------------

function getTriadValue(card)
    if card == nil then
        for _,each in ipairs(getAllObjects()) do
            if each.type == "Card" and each.getName() == "The Triad" then
                card = each
                break
            end
        end
        if card == nil then return 3, 3 end
    end

    local color = _zoneHelper.zoneFromPosition(card.getPosition())
    if not color then return 3,3 end

    local bonus = 0
    local objsToFind = {
        ['Hazardous Relic Fragment'] = true,
        ['Cultural Relic Fragment'] = true,
        ['Industrial Relic Fragment'] = true,
        ['Unknown Relic Fragment'] = true,
    }
    for _,each in ipairs(getAllObjects()) do
        local match, i = string.find(each.getName(), "Relic Fragment")
        if match and each.type == "Card" then
            local trait = string.sub(each.getName(), 1, i)
            if objsToFind[trait] and _zoneHelper.zoneFromPosition(each.getPosition()) == color then
                objsToFind[trait] = nil
                bonus = bonus + 1
                if not next(objsToFind) then break end
            end
        end
    end

    return 3 + bonus, 3 + bonus
end

-------------------------------------------------------------------------------

function _moveTokenFromReinforcements(systemObject, colors)
    assert(type(systemObject) == 'userdata' and type(colors) == 'table')
    local bagNameSet = {}
    for _, color in ipairs(colors) do
        local faction = _factionHelper.fromColor(color)
        if faction then
            bagNameSet[faction.tokenName .. ' Command Tokens Bag'] = true
        end
    end
    local bags = {}
    for _, object in ipairs(getAllObjects()) do
        if object.tag == 'Bag' and bagNameSet[object.getName()] then
            table.insert(bags, object)
        end
    end
    local r = 1
    local p0 = systemObject.getPosition()
    local success = true
    for i, bag in ipairs(bags) do
        local phi = math.rad(360 * i / #bags)
        if bag.getQuantity() > 0 then
            bag.takeObject({
                position = {
                    x = p0.x + math.cos(phi) * r,
                    y = p0.y + 3 + i * 0.2,
                    z= p0.z + math.sin(phi) * r,
                },
                rotation = {
                    x = 0,
                    y = -math.deg(phi),
                    z = 0
                },
                smooth = true,
            })
        else
            broadcastToAll(bag.getName() .. ' empty, please assign token manually', 'Red')
            success = false
        end
    end
    return success
end

function _moveTokenFromCommandSheet(systemObject, color, section)
    assert(type(systemObject) == 'userdata' and type(color) == 'string' and type(section) == 'string')
    local faction = _factionHelper.fromColor(color)
    local commandSheet = faction and getObjectFromGUID(faction.commandSheetGuid)
    local commandTokenName = faction and faction.tokenName .. ' Command Token'
    local function isToken(commandToken)
        local p = commandSheet.positionToLocal(commandToken.getPosition())
        local dSq = p.x * p.x + p.z * p.z
        if dSq > 15 then
            return false
        end
        local degrees = (math.deg(math.atan2(p.z, p.x)) + 360) % 360
        if section == 'tactics' and 300 > degrees and degrees > 240 then
            return true
        elseif section == 'fleet' and 240 > degrees and degrees > 180 then
            return true
        elseif section == 'strategy' and 180 > degrees and degrees > 120 then
            return true
        end
    end
    local commandToken = false
    if commandSheet and commandTokenName then
        for _, object in ipairs(getAllObjects()) do
            if object.getName() == commandTokenName and isToken(object) then
                commandToken = object
                break
            end
        end
    end
    local success = true
    if commandToken then
        -- Off-center, near the tile number.
        local p0 = systemObject.positionToWorld({
            x = 1.8,
            y = 0,
            z = 0
        })
        local position = {
            x = p0.x,
            y = p0.y + 3,
            z = p0.z
        }
        local collide = false
        local fast = false
        commandToken.setPositionSmooth(position, collide, fast)

        -- Rotate if a stack.
        local hits = Physics.cast({
            origin = { x = p0.x, y = p0.y, z = p0.z },
            direction = { x = 0, y = -1, z = 0 },
            type = 3, -- box
            size = { 0.1, 5, 0.1 }
        })
        local count = 0
        for _, hit in ipairs(hits) do
            local hitName = hit.hit_object.getName()
            if string.match(hitName, 'Command Token$') then
                count = count + 1
            end
        end
        local rotation = {
            x = 0,
            y = (count * 20) % 360,
            z = 0
        }
        commandToken.setRotationSmooth(rotation, collide, fast)
    else
        broadcastToAll(color .. ' ' .. section .. ' pool is empty', 'Red')
        success = false
    end
    return success
end

function _moveOwnerToken(systemObject, color)
    assert(type(systemObject) == 'userdata' and type(color) == 'string')
    local faction = _factionHelper.fromColor(color)
    local ownerTokensBagName = faction and faction.tokenName .. ' Owner Tokens Bag'
    local ownerTokensBag = false
    if ownerTokensBagName then
        for _, object in ipairs(getAllObjects()) do
            if object.tag == 'Infinite' and object.getName() == ownerTokensBagName then
                ownerTokensBag = object
                break
            end
        end
    end
    if ownerTokensBag then
        -- Off-center, near the tile number.
        local p0 = systemObject.positionToWorld({
            x = 1.8,
            y = 0,
            z = 0
        })
        ownerTokensBag.takeObject({
            position = {
                x = p0.x,
                y = p0.y + 3,
                z = p0.z
            },
            smooth = true
        })
    end
end

function onClickDiplomacySystem(clickerColor, systemObject)
    assert(type(clickerColor) == 'string' and type(systemObject) == 'userdata')
    local system = systemFromGuid(systemObject.getGUID())
    printToAll(clickerColor .. ' applying Diplomacy to ' .. system.string)
    local colors = {}
    for _, faction in pairs(_factionHelper.allFactions()) do
        if faction.color ~= clickerColor then
            table.insert(colors, faction.color)
        end
    end
    _moveTokenFromReinforcements(systemObject, colors)
end

function onClickActivateSystem(clickerColor, systemObject)
    assert(type(clickerColor) == 'string' and type(systemObject) == 'userdata')
    local system = systemFromGuid(systemObject.getGUID())
    -- No need to announce, _activateSystem will do that.
    if (not Turns.enable) or Turns.turn_color ~= clickerColor then
        printToColor('Activate system: ' .. clickerColor .. ' is not the active player, ignoring', clickerColor, 'Red')
        return
    end
    if _moveTokenFromCommandSheet(systemObject, clickerColor, 'tactics') then
        _activateSystem(clickerColor, system)
    end
end

function onClickStrategyToken(clickerColor, systemObject)
    assert(type(clickerColor) == 'string' and type(systemObject) == 'userdata')
    local system = systemFromGuid(systemObject.getGUID())
    if _moveTokenFromCommandSheet(systemObject, clickerColor, 'strategy') then
        printToAll(clickerColor .. ' placing command token from strategy in ' .. system.string)
    end
end

function onClickReinforcementsToken(clickerColor, systemObject)
    assert(type(clickerColor) == 'string' and type(systemObject) == 'userdata')
    local system = systemFromGuid(systemObject.getGUID())
    if _moveTokenFromReinforcements(systemObject, { clickerColor }) then
        printToAll(clickerColor .. ' placing command token from reinforcements in ' .. system.string)
    end
end

function onClickOwnerToken(clickerColor, systemObject)
    assert(type(clickerColor) == 'string' and type(systemObject) == 'userdata')
    local system = systemFromGuid(systemObject.getGUID())
    _moveOwnerToken(systemObject, clickerColor)
    printToAll(clickerColor .. ' placing owner token in ' .. system.string)
end

function _addContextMenuItems(systemObject)
    assert(type(systemObject) == 'userdata')
    assert(_systems[systemObject.getGUID()])
    systemObject.addContextMenuItem('Activate System', function(clickerColor) onClickActivateSystem(clickerColor, systemObject) end, false)
    systemObject.addContextMenuItem('Owner Token', function(clickerColor) onClickOwnerToken(clickerColor, systemObject) end, false)
    systemObject.addContextMenuItem('Strategy Token', function(clickerColor) onClickStrategyToken(clickerColor, systemObject) end, false)
    systemObject.addContextMenuItem('Reinforcements Tkn', function(clickerColor) onClickReinforcementsToken(clickerColor, systemObject) end, false)
    systemObject.addContextMenuItem('Diplomacy System', function(clickerColor) onClickDiplomacySystem(clickerColor, systemObject) end, false)
end

function onObjectSpawn(object)
    if _systems[object.getGUID()] and not _systems[object.getGUID()].hyperlane then
        _addContextMenuItems(object)
    end
end

-------------------------------------------------------------------------------

function onLoad(saveState)
    self.setColorTint({ r = 0.25, g = 0.25, b = 0.25 })
    self.setScale({ x = 2, y = 0.01, z = 2 })
    self.setName('TI4_SYSTEM_HELPER')
    self.setDescription('Shared helper functions used by other objects, PLEASE LEAVE ON TABLE! This object is only visible to the black (GM) player.')

    self.addContextMenuItem('Verify', verifyAllSystems)

    -- Not for full releases, exists for map builders who want to find tiles easily.
    self.addContextMenuItem('Rename Tiles', function() startLuaCoroutine(self, '_renameSystemTilesCoroutine') end)

    -- Only the GM/black player can see this object.  Others can still interact!
    local invisibleTo = {}
    for _, color in ipairs(Player.getColors()) do
        if color ~= 'Black' then
            table.insert(invisibleTo, color)
        end
    end
    self.setInvisibleTo(invisibleTo)

    local function delayedAddContextMenuItems()
        for _, object in ipairs(getAllObjects()) do
            if _systems[object.getGUID()] then
                _addContextMenuItems(object)
            end
        end
    end
    Wait.frames(delayedAddContextMenuItems, 9)
end

function onPlayerTurnEnd(player_color_end, player_color_next)
    _activatedSystem = false
end

function onObjectDrop(playerColor, object)
    local name = object.getName()
    if _systemDroppables[name] then
        DropUtils.onDrop(playerColor, object, name)
    end
    --No else here, allow injected effects to use command tokens

    --Is it a command token?
    if playerColor ~= Turns.turn_color then
        return
    end

    local tokenName = string.match(name, '^(.*) Command Token')
    if not tokenName then
        return
    end

    -- In addition to "FACTION Command Token" accept "COLOR Command Token".
    local faction = _factionHelper.fromTokenName(tokenName)
    local matchesFaction = faction and faction.color == playerColor
    local matchesColor = tokenName == playerColor
    if (not matchesFaction) and (not matchesColor) then
        return
    end

    local system = systemFromPosition(object.getPosition())
    if not system then
        return
    end

    _activateSystem(playerColor, system)
end

--Activate from other scripts
function activateSystem(params)
    assert(params, "Missing params for call to TI4_SYSTEM_HELPER.acitvateSystem()")
    local prefix = "Invalid params for TI4_SYSTEM_HELPER.acitvateSystem(): "
    assert(type(params) == "table", prefix.."params should be a table with .color and .guid or .position fields")
    assert(type(params.color) == "string",prefix.."params.color needs to be a string.")
    assert(type(params.guid) == "string" or type(params.position) == "table", prefix.."params requires a .guid or .position field")
    local system = params.guid and _systems[params.guid] or params.position and systemFromPosition(params.position)
    if not system then return end

    _activateSystem(params.color, system)
end

function _activateSystem(playerColor, system)
    assert(type(playerColor) == 'string' and type(system) == 'table')

    _fillMissingSystemData(system.guid, system)

    _activatedSystem = system
    _lastActivatedSystem = system

    local faction = _factionHelper.fromColor(playerColor)
    local factionName = (faction and faction.name) or playerColor
    broadcastToAll(factionName .. ' activated ' .. system.string, playerColor)
    local systemObject = getObjectFromGUID(system.guid)
    systemObject.highlightOn(playerColor, 30)

    -- Tell any interested parties.
    local reportTo = {}
    for _, object in ipairs(getAllObjects()) do
        if object.getVar('onSystemActivation') then
            table.insert(reportTo, object)
        end
    end
    for i, object in ipairs(reportTo) do
        -- Wrap each in a separate 'Wait' instance so if one fails the rest go ahead.
        -- Since that is happening, also spread out over N frames.
        Wait.frames(function() object.call('onSystemActivation', system) end, i)
    end
end

function diploSystem(params)
    assert(params, "Missing params for call to TI4_SYSTEM_HELPER.diploSystem()")
    local prefix = "Invalid params for TI4_SYSTEM_HELPER.diploSystem(): "
    assert(type(params) == "table", prefix.."params should be a table with .color and .guid or .position fields")
    assert(type(params.color) == "string",prefix.."params.color needs to be a string.")
    assert(type(params.guid) == "string" or type(params.position) == "table", prefix.."params requires a .guid or .position field")
    local system = params.guid and _systems[params.guid] or params.position and systemFromPosition(params.position)
    if not system then return end

    _diploSystem(params.color, system)
end

function _diploSystem(playerColor, system)
    assert(playerColor and type(playerColor) == "string")
    assert(system)

    local colors = {}
    for _, faction in pairs(_factionHelper.allFactions()) do
        if faction.color ~= playerColor then
            table.insert(colors, faction.color)
        end
    end
    _moveTokenFromReinforcements(getObjectFromGUID(system.guid), colors)
end

--Mahact Prommisory Note
function _scepterDiplo(usingPlayer, system)
    local function getFleetTokens(commandSheet)
        assert(commandSheet, "Missing sheet")
        if not commandSheet then return {} end

        local tokenHash = {}
        local tokens = {}
        local pattern = " Command Token"
        for _,each in ipairs(getAllObjects()) do
            if string.match(each.getName(), pattern) then
                table.insert(tokens, each)
            end
        end

        local bounds = commandSheet.getBoundsNormalized()
        local pos = commandSheet.getPosition()
        local rad = math.max(bounds.size.x, bounds.size.z) + 1
        for _,token in ipairs(tokens) do
            local name = token.getName()
            if not tokenHash[name] then
                local tPos = token.getPosition()
                if tPos.x < pos.x+rad and tPos.x > pos.x-rad and tPos.z > pos.z-rad and tPos.z < pos.z+rad then
                    tokenHash[name] = true
                end
            end
        end

        return tokenHash
    end

    local fleetHash = {}
    for _,each in pairs(_factionHelper.allFactions() or {}) do
        for _,proms in ipairs(each.promissoryNotes or {}) do
            if proms == 'Scepter of Dominion' then
                if not each.color or each.color == usingPlayer then return end --Players can't use their own notes
                fleetHash = getFleetTokens(getObjectFromGUID(each.commandSheetGuid))
                break
            end
        end
    end
    
    --convert token names to colors
    local colors = {}
    for each,_ in pairs(fleetHash) do
        local faction = _factionHelper.fromTokenName(each)
        if faction and faction.color and faction.color ~= usingPlayer then
            table.insert(colors, faction.color)
        end
    end

    _moveTokenFromReinforcements(getObjectFromGUID(system.guid), colors)
end

-------------------------------------------------------------------------------

function _renameSystemTilesCoroutine()
    local bagAndGuidEntries = {} -- allow multiple copies of a tile in different bags
    for _, object in ipairs(getAllObjects()) do
        if _systems[object.getGUID()] then
            table.insert(bagAndGuidEntries, { bag = false, guid = object.getGUID() })
        elseif object.tag == 'Bag' then
            for _, entry in ipairs(object.getObjects()) do
                if _systems[entry.guid] then
                    table.insert(bagAndGuidEntries, { bag = object, guid = entry.guid })
                end
            end
        end
    end
    coroutine.yield(0)
    for i, bagAndGuidEntry in ipairs(bagAndGuidEntries) do
        local bag = bagAndGuidEntry.bag
        local guid = assert(bagAndGuidEntry.guid)
        local system = assert(_systems[guid])
        local name = _systemToString(system)
        local object = false
        if bag then
            local pos = bag.getPosition()
            object = bag.takeObject({
                guid = guid,
                position = { x = pos.x, y = pos.y + 5 + i * 0.3, z = pos.z }
            })
            while object.spawning do
                coroutine.yield(0)
            end
            coroutine.yield(0)
        else
            object = getObjectFromGUID(guid)
        end
        assert(object)
        object.setRotation({ x = 0, y = 180, z = 0 })
        object.use_hands = true
        if string.len(object.getName()) == 0 then
            object.setName(name)
        end
        if bag then
            bag.putObject(object)
            for _ = 1, 20 do
                coroutine.yield(0)
            end
        end
        coroutine.yield(0)
    end
    return 1
end

--[[
--Commented out to enabled DropUtils to create coroutines at runtime
--Comment back in to test code (Drop Tokens like the Diplo Token will error)

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
--]]