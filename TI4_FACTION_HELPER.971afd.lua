--- Faction attributes.
-- @author Darrell
-- #include <~/TI4-TTS/TI4/Helpers/TI4_FactionHelper>
--
-- Get faction tables with:
-- - factionName string, matches a key in the faction attributes table.
-- - tokenName string, "TOKEN_NAME Command Token" or "TOKEN_NAME Owner Token".
-- - color string (from command sheet in case no seated player).
-- - actionCards number.
-- - commandTokens number.

-- Users should copy this getHelperClient function, and use via:
--
-- local factionHelper = getHelperClient('TI4_FACTION_HELPER')
-- local faction = factionHelper.fromColor('Red')
-- print(faction.name)
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
local _exploreHelper = getHelperClient('TI4_EXPLORE_HELPER')
local _strategyCardHelper = getHelperClient('TI4_STRATEGY_CARD_HELPER')
local _systemHelper = getHelperClient('TI4_SYSTEM_HELPER')
local _unitHelper = getHelperClient('TI4_UNIT_HELPER')
local _zoneHelper = getHelperClient('TI4_ZONE_HELPER')

function _exportFaction(f)
    local function scrub(s)
        if type(s) ~= 'string' then
            return
        end
        s = string.gsub(s, '[^%w %(%)]', '')
        s = string.lower(s):gsub(' ', '_')
        while(string.match(s, '^_')) do
            s = s:sub(2)
        end
        while(string.match(s, '_$')) do
            s = s:sub(1, -2)
        end
        s = s:gsub('__', '_')
        return s
    end
    local function scrubList(tbl)
        local result = {}
        for _, v in ipairs(tbl) do
            table.insert(result, scrub(v))
        end
        return result
    end

    local techs = {}
    for _, v in ipairs(f.factionTech or {}) do
        if not _unitHelper.getUnitOverrides()[v] then
            table.insert(techs, v)
        end
    end

    local units = { f.flagship }
    for _, v in ipairs(f.units or {}) do
        v = v:gsub(' I$', '')
        v = v:gsub(' II$', ' 2')
        table.insert(units, v)
    end

    local startingUnits = {}
    for k, v in pairs(f.startingUnits) do
        startingUnits[scrub(k)] = v
    end

    return {
        faction = scrub(f.shortName or f.frankenName),
        source = scrub(f.source),
        abilities = scrubList(f.abilities),
        commodities = f.commodities,
        home = f.home,
        leaders = {
            agents = { 'UNKNOWN_XXX'},
            commanders = { scrub(f.commander) },
            heroes = { scrub(f.hero) },
        },
        promissoryNotes = scrubList(f.promissoryNotes),
        techs = scrubList(techs),
        units = scrubList(units),
        startingTech = scrubList(f.startingTech),
        startingUnits = startingUnits,
    }
end

-- Per-faction attributes.  This helper will also add the following fields:
-- - color (string) or nil if not in use.
-- - commandSheetGuid (string) or nil if not in use.
-- - factionSheetGuid (string) or nil if not in use.
local _factionAttributes = {

    ['The Arborec'] = {
        source = 'base',
        tokenName = 'Arborec',
        frankenName = 'Arborec',
        home = 5,
        startingUnits = { Infantry = 4, Fighter = 2, Cruiser = 1, Carrier = 1, Space_Dock = 1, PDS = 1 },
        startingTech = { 'Magen Defense Grid' },
        factionTech = { "Letani Warrior II", "Bioplasmosis" },
        flagship = 'Duha Menaimon',
        flagshipDescription = 'After you activate this system, you may produce up to 5 units in this system.',
        abilities = { 'Mitosis' },
        units = { 'Letani Warrior I', 'Letani Warrior II', 'Letani Behemoth' },
        commander = 'Dirzuga Rophal',
        hero = 'Letani Miasmiala',
        commodities = 3,
        promissoryNotes = { 'Stymie', 'Stymie Ω' },
        breakthrough = 'Psychospore'
    },

    ['The Barony Of Letnev'] = {
        source = 'base',
        tokenName = 'Barony of Letnev',
        frankenName = 'Letnev',
        home = 10,
        startingUnits = { Infantry = 3, Fighter = 1, Destroyer = 1, Carrier = 1, Dreadnought = 1, Space_Dock = 1 },
        startingTech = { 'Antimass Deflectors', 'Plasma Scoring' },
        factionTech = { "L4 Disruptors", "Non-Euclidean Shielding" },
        flagship = 'Arc Secundus',
        flagshipDescription = "Other players’ units in this system lose PLANETARY SHIELD.  At the start of each space combat round, repair this ship.  BOMBARDMENT 5 (X3)",
        abilities = { 'Munitions Reserves', 'Armada' },
        units = { 'Dunlain Reaper' },
        commander = 'Rear Admiral Farran',
        hero = 'Darktalon Treilla',
        commodities = 2,
        promissoryNotes = { 'War Funding', 'War Funding Ω' },
        breakthrough = 'Gravleash Maneuvers'
    },

    ['The Clan Of Saar'] = {
        source = 'base',
        tokenName = 'Clan of Saar',
        frankenName = 'Saar',
        home = 11,
        startingUnits = { Infantry = 4, Fighter = 2, Cruiser = 1, Carrier = 2, Space_Dock = 1 },
        startingTech = { 'Antimass Deflectors' },
        factionTech = { "Chaos Mapping", "Floating Factory II" },
        flagship = 'Son of Ragh',
        flagshipDescription = 'ANTI-FIGHTER BARRAGE 6 (X4)',
        abilities = { 'Scavenge', 'Nomadic' },
        units = { 'Floating Factory I', 'Floating Factory II', 'Scavenger Zeta' },
        commander = 'Rowl Sarrig',
        hero = 'Gurno Aggero',
        commodities = 3,
        promissoryNotes = { "Ragh's Call" },
        breakthrough = 'Deorbit Barrage'
    },

    ['The Embers Of Muaat'] = {
        source = 'base',
        tokenName = 'Embers of Muaat',
        frankenName = 'Muaat',
        home = 4,
        startingUnits = { Infantry = 4, Fighter = 2, War_Sun = 1, Space_Dock = 1 },
        startingTech = { 'Plasma Scoring' },
        factionTech = { "Prototype War Sun II", "Magmus Reactor" },
        flagship = 'The Inferno',
        flagshipDescription = "ACTION: Spend 1 token from your strategy pool to place 1 cruiser in this unit’s system.",
        abilities = { 'Star Forge', 'Gashlai Physiology' },
        units = { 'Prototype War Sun I', 'Prototype War Sun II', 'Ember Colossus' },
        commander = 'Magmus',
        hero = "Adjudicator Ba'al",
        commodities = 4,
        promissoryNotes = { 'Fires of the Gashlai' },
        breakthrough = 'Stellar Genesis'
    },

    ['The Emirates Of Hacan'] = {
        source = 'base',
        tokenName = 'Emirates of Hacan',
        frankenName = 'Hacan',
        home = 16,
        startingUnits = { Infantry = 4, Fighter = 2, Cruiser = 1, Carrier = 2, Space_Dock = 1 },
        startingTech = { 'Antimass Deflectors', 'Sarween Tools' },
        factionTech = { "Quantum Datahub Node", "Production Biomes" },
        flagship = 'Wrath of Kenara',
        flagshipDescription = 'After you roll a die during a space combat in this system, you may spend 1 trade good to apply +1 to the result.',
        abilities = { 'Masters of Trade', 'Guild Ships', 'Arbiters' },
        units = { 'Pride of Kenara' },
        commander = 'Gila the Silvertongue',
        hero = 'Harrugh Gefhara',
        commodities = 6,
        promissoryNotes = { 'Trade Convoys' },
        breakthrough = 'Auto-Factories'
    },

    ['The Federation Of Sol'] = {
        source = 'base',
        tokenName = 'Federation of Sol',
        frankenName = 'Sol',
        home = 1,
        startingUnits = { Infantry = 5, Fighter = 3, Destroyer = 1, Carrier = 2, Space_Dock = 1 },
        startingTech = { 'Antimass Deflectors', 'Neural Motivator' },
        factionTech = { "Spec Ops II", "Advanced Carrier II" },
        flagship = 'Genesis',
        flagshipDescription = "At the end of the status phase, place 1 infantry from your reinforcements in this system’s space area.",
        abilities = { 'Orbital Drop', 'Versatile' },
        units = { 'Advanced Carrier I', 'Advanced Carrier II', 'Spec Ops I', 'Spec Ops II', 'ZS Thunderbolt M2' },
        commander = 'Claire Gibson',
        hero = 'Jace X, 4th Air Legion',
        commodities = 4,
        promissoryNotes = { 'Military Support' },
        breakthrough = 'Bellum Gloriosum'
    },

    ['The Ghosts Of Creuss'] = {
        source = 'base',
        tokenName = 'Ghosts of Creuss',
        frankenName = 'Creuss',
        home = 51,
        offMapHome = 'Creuss Gate Tile',
        startingUnits = { Infantry = 4, Fighter = 2, Destroyer = 2, Carrier = 1, Space_Dock = 1 },
        startingTech = { 'Gravity Drive' },
        factionTech = { "Wormhole Generator", "Dimensional Splicer" },
        flagship = 'Hil Colish',
        flagshipDescription = "This ship’s system contains a delta wormhole.  During movement, this ship may move before or after your other ships.",
        abilities = { 'Quantum Entanglement', 'Slipstream', 'Creuss Gate' },
        units = { 'Icarus Drive' },
        commander = 'Sai Seravus',
        hero = 'Riftwalker Meian',
        commodities = 4,
        promissoryNotes = { 'Creuss Iff' },
        breakthrough = 'Particle Synthesis'
    },

    ['The L1Z1X Mindnet'] = {
        source = 'base',
        tokenName = 'L1Z1X Mindnet',
        frankenName = 'L1Z1X',
        home = 6,
        startingUnits = { Infantry = 5, Fighter = 3, Carrier = 1, Dreadnought = 1, Space_Dock = 1, PDS = 1 },
        startingTech = { 'Neural Motivator', 'Plasma Scoring' },
        factionTech = { "Super-Dreadnought II", "Inheritance Systems" },
        flagship = '[0.0.1]',
        flagshipDescription = 'During a space combat, hits produced by this ship and by your dreadnoughts in this system must be assigned to non-fighter ships if able.',
        abilities = { 'Assimilate', 'Harrow' },
        units = { 'Super-Dreadnought I', 'Super-Dreadnought II', 'Annihilator' },
        commander = '2RAM',
        hero = 'The Helmsman',
        commodities = 2,
        promissoryNotes = { 'Cybernetic Enhancements', 'Cybernetic Enhancements Ω' },
        breakthrough = 'Fealty Uplink'
    },

    ['The Mentak Coalition'] = {
        source = 'base',
        tokenName = 'Mentak Coalition',
        frankenName = 'Mentak',
        home = 2,
        startingUnits = { Infantry = 4 ,Fighter = 3, Cruiser = 2, Carrier = 1, Space_Dock = 1, PDS = 1 },
        startingTech = { 'Sarween Tools', 'Plasma Scoring' },
        factionTech = { "Mirror Computing", "Salvage Operations" },
        flagship = 'Fourth Moon',
        flagshipDescription = "Other players’ ships in this system cannot use SUSTAIN DAMAGE.",
        abilities = { 'Ambush', 'Pillage' },
        units = { 'Moll Terminus' },
        commander = "S'ula Mentarion",
        hero = 'Ipswitch, Loose Cannon',
        commodities = 2,
        promissoryNotes = { 'Promise of Protection' },
        breakthrough = 'Corsair'
    },

    ['The Naalu Collective'] = {
        source = 'base',
        tokenName = 'Naalu Collective',
        frankenName = 'Naalu',
        home = 9,
        startingUnits = { Infantry = 4, Fighter = 3, Destroyer = 1, Cruiser = 1, Carrier = 1, Space_Dock = 1, PDS = 1 },
        startingTech = { 'Neural Motivator', 'Sarween Tools' },
        factionTech = { "Hybrid Crystal Fighter II", "Neuroglaive" },
        flagship = 'Matriarch',
        flagshipDescription = 'During an invasion in this system, you may commit fighters to planets as if they were ground forces.  When combat ends, return those units to the space area.',
        abilities = { 'Telepathic', 'Foresight' },
        units = { 'Hybrid Crystal Fighter I', 'Hybrid Crystal Fighter II', 'Iconoclast' },
        commander = "M'aban",
        hero = 'The Oracle',
        commodities = 3,
        promissoryNotes = { 'Gift of Prescience' },
        breakthrough = 'Mindsieve'
    },

    ['The Nekro Virus'] = {
        source = 'base',
        tokenName = 'Nekro Virus',
        frankenName = 'Nekro',
        home = 8,
        startingUnits = { Infantry = 2, Fighter = 2, Cruiser = 1, Carrier = 1, Dreadnought = 1, Space_Dock = 1 },
        startingTech = { 'Dacxive Animators', 'Valefar Assimilator X', 'Valefar Assimilator Y' },
        factionTech = { "Valefar Assimilator X", "Valefar Assimilator Y" },
        flagship = 'The Alastor',
        flagshipDescription = 'At the start of space combat, choose any number of your ground forces in this system to participate in that combat as is they were ships.  These ground forces do not count against fleet supply.',
        abilities = { 'Galactic Threat', 'Technological Singularity', 'Propagation' },
        startMessage = 'If the Vuil\'raith Cabal isn\'t in your game, purge your Dimensional Tear tokens.',
        units = { 'Mordred' },
        commander = 'Nekro Acidos',
        hero = 'Unit.dsgn.FLAYESH',
        commodities = 3,
        promissoryNotes = { 'Antivirus' },
        breakthrough = 'Valefar Assimilator Z'
    },

    ["The Sardakk N'orr"] = {
        source = 'base',
        tokenName = "Sardakk N'orr",
        frankenName = 'Sardakk',
        shortName = "N'orr",
        home = 13,
        startingUnits = { Infantry = 5, Cruiser = 1, Carrier = 2, Space_Dock = 1, PDS = 1 },
        startingTech = {},
        factionTech = { "Exotrireme II", "Valkyrie Particle Weave" },
        flagship = "C'morran N'orr",
        flagshipDescription = "Apply +1 to the result of each of your other ship’s combat rolls in this system.",
        abilities = { 'Unrelenting' },
        units = { 'Exotrireme I', 'Exotrireme II', 'Valkyrie Exoskeleton' },
        commander = "G'hom Sek'kus",
        hero = "Sh'val, Harbinger",
        commodities = 3,
        promissoryNotes = { 'Tekklar Legion' },
        breakthrough = "N'orr Supremacy"
    },

    ['The Universities of Jol-Nar'] = {
        source = 'base',
        tokenName = 'Universities of Jol-Nar',
        frankenName = 'Jol-Nar',
        home = 12,
        startingUnits = { Infantry = 2, Fighter = 1, Carrier = 2, Dreadnought = 1, Space_Dock = 1, PDS = 2 },
        startingTech = { 'Antimass Deflectors', 'Neural Motivator', 'Sarween Tools', 'Plasma Scoring' },
        factionTech = { "Spacial Conduit Cylinder", "E-res Siphons" },
        flagship = 'J.N.S. Hylarim',
        flagshipDescription = 'When making a combat roll for this ship, each result of 9 or 10 (before applying modifiers) produces 2 extra hits.',
        abilities = { 'Fragile', 'Brilliant', 'Analytical' },
        units = { 'Shield Paling' },
        commander = 'Ta Zern',
        hero = "Rin, the Master's Legacy",
        commodities = 4,
        promissoryNotes = { 'Research Agreement' },
        breakthrough = 'Specialist Enclave'
    },

    ['The Winnu'] = {
        source = 'base',
        tokenName = 'Winnu',
        frankenName = 'Winnu',
        home = 7,
        startingUnits = { Infantry = 2, Fighter = 2, Cruiser = 1, Carrier = 1, Space_Dock = 1, PDS = 1 },
        startingTech = {},
        factionTech = { "Lazax Gate Folding", "Hegemonic Trade Policy" },
        flagship = 'Salai Sai Corian',
        flagshipDescription = "When this unit makes a combat roll, it rolls a number of dice equal to the number of your opponent’s non-fighter ships in this system.",
        startMessage = 'Choose any 1 technology that has no prerequisites.',
        abilities = { 'Blood Ties', 'Reclamation' },
        units = { 'Reclaimer' },
        commander = 'Rickar Rickani',
        hero = 'Mathis Mathinus',
        commodities = 3,
        promissoryNotes = { 'Acquiescence', 'Acquiescence Ω' },
        breakthrough = 'Imperator'
    },

    ['The Xxcha Kingdom'] = {
        source = 'base',
        tokenName = 'Xxcha Kingdom',
        frankenName = 'Xxcha',
        home = 14,
        startingUnits = { Infantry = 4, Fighter = 3, Cruiser = 2, Carrier = 1, Space_Dock = 1, PDS = 1 },
        startingTech = { 'Graviton Laser System' },
        factionTech = { "Instinct Training", "Nullification Field" },
        flagship = 'Loncara Ssodu',
        flagshipDescription = "You may use this unit’s SPACE CANNON against ships that are in adjacent systems.  SPACE CANNON 5 (X3)",
        abilities = { 'Peace Accords', 'Quash' },
        units = { 'Indomitus' },
        commander = 'Elder Qanoj',
        hero = 'Xxekir Grom',
        commodities = 4,
        promissoryNotes = { 'Political Favor' },
        breakthrough = "Archon's Gift"
    },

    ['The Yin Brotherhood'] = {
        source = 'base',
        tokenName = 'Yin Brotherhood',
        frankenName = 'Yin',
        home = 3,
        startingUnits = { Infantry = 4, Fighter = 4, Destroyer = 1, Carrier = 2, Space_Dock = 1 },
        startingTech = { 'Sarween Tools' },
        factionTech = { "Yin Spinner", "Impulse Core" },
        flagship = 'Van Hauge',
        flagshipDescription = 'When this ship is destroyed, destroy all ships in this system.',
        abilities = { 'Indoctrination', 'Devotion' },
        units = { "Moyin's Ashes" },
        commander = 'Brother Omar',
        hero = 'Dannel of the Tenth',
        commodities = 2,
        promissoryNotes = { 'Greyfire Mutagen', 'Greyfire Mutagen Ω' },
        breakthrough = 'Yin Ascendant'
    },

    ['The Yssaril Tribes'] = {
        source = 'base',
        tokenName = 'Yssaril Tribes',
        frankenName = 'Yssaril',
        home = 15,
        startingUnits = { Infantry = 5, Fighter = 2, Cruiser = 1, Carrier = 2, Space_Dock = 1, PDS = 1 },
        startingTech = { 'Neural Motivator' },
        factionTech = { "Mageon Implants", "Transparasteel Plating" },
        flagship = "Y'sia Y'ssrila",
        flagshipDescription = "This ship can move through systems that contain another players’ ships.",
        abilities = { 'Stall Tactics', 'Scheming', 'Crafty' },
        units = { 'Blackshade Infiltrator' },
        commander = 'So Ata',
        hero = 'Kyver, Blade and Key',
        commodities = 3,
        promissoryNotes = { 'Spy Net' },
        breakthrough = 'Deepgloom Executable'
    },

    -- PoK Factions
    ['The Nomad'] = {
        source = 'PoK',
        tokenName = 'Nomad',
        frankenName = 'Nomad',
        home = 53,
        startingUnits = { Infantry = 4, Fighter = 3, Destroyer = 1, Carrier = 1, Flagship = 1, Space_Dock = 1 },
        startingTech = { 'Sling Relay' },
        factionTech = { "Temporal Command Suite", "Memoria II" },
        flagship = "Memoria I",
        flagshipDescription = "You may treat this unit as if it were adjacent to systems that contain 1 or more of your mechs.",
        abilities = { 'The Company', 'Future Sight' },
        units = { 'Memoria II', 'Quantum Manipulator' },
        commander = 'Navarch Feng',
        hero = 'Ahk-Syl Siven',
        commodities = 4,
        promissoryNotes = { 'The Cavalry' },
        breakthrough = "Thunder's Paradox"
    },

    ["The Vuil'raith Cabal"] = {
        source = 'PoK',
        tokenName = "Vuil'raith Cabal",
        frankenName = "Vuil'raith",
        home = 54,
        startingUnits = { Infantry = 3, Fighter = 3, Cruiser = 1, Carrier = 1, Dreadnought = 1, Space_Dock = 1 },
        startingTech = { 'Self Assembly Routines' },
        factionTech =  { "Vortex", "Dimensional Tear II" },
        flagship = "The Terror Between",
        flagshipDescription = "Capture all other non-structure units that are destroyed in this system, including your own.",
        abilities = { 'Devour', 'Amalgamation', 'Riftmeld' },
        units = { 'Dimensional Tear I', 'Dimensional Tear II', 'Reanimator' },
        commander = 'That Which Molds Flesh',
        hero = 'It Feeds on Carrion',
        commodities = 2,
        promissoryNotes = { 'Crucible' },
        breakthrough = "Al'Riath Ix Ianovar"
    },

    ['The Argent Flight'] = {
        source = 'PoK',
        tokenName = 'Argent Flight',
        frankenName = 'Argent',
        home = 58,
        startingUnits = { Infantry = 5, Fighter = 2, Destroyer = 2, Carrier = 1, Space_Dock = 1, PDS = 1 },
        startingTech = { 'Sarween Tools', 'Neural Motivator', 'Plasma Scoring' },
        factionTech = { "Aerie Hololattice", "Strike Wing Alpha II" },
        flagship = "Quetzecoatl",
        flagshipDescription = "Other players cannot use SPACE CANNON against your ships in this system.",
        abilities = { 'Zeal', 'Raid Formation' },
        startMessage = 'Pick 2 technologies and return the other to your deck.',
        units = { 'Strike Wing Alpha I', 'Strike Wing Alpha II', 'Aerie Sentinel' },
        commander = 'Trrakan Aun Zulok',
        hero = 'Mirik Aun Sissiri',
        commodities = 3,
        promissoryNotes = { 'Strike Wing Ambuscade' },
        breakthrough = 'Wing Transfer'
    },

    ['The Titans of Ul'] = {
        source = 'PoK',
        tokenName = 'Titans of Ul',
        frankenName = 'Titans',
        shortName = 'Ul',
        home = 55,
        startingUnits = { Infantry = 3, Fighter = 2, Cruiser = 2, Dreadnought = 1, Space_Dock = 1 },
        startingTech = { 'Antimass Deflectors', 'Scanlink Drone Network' },
        factionTech = { "Saturn Engine II", "Hel-Titan II" },
        flagship = "Ouranos",
        flagshipDescription = "DEPLOY: After you activate a system that contains 1 or more of your PDS, you may replace 1 of those PDS with this unit.",
        abilities = { 'Terragenesis', 'Awaken', 'Coalescence' },
        units = { 'Saturn Engine I', 'Saturn Engine II', 'Hel-Titan I', 'Hel-Titan II', 'Hecatoncheires' },
        commander = 'Tungstantus',
        hero = 'Ul the Progenitor',
        commodities = 2,
        promissoryNotes = { 'Terraform' },
        breakthrough = 'Slumberstate Computing'
    },

    ['The Empyrean'] = {
        source = 'PoK',
        tokenName = 'Empyrean',
        frankenName = 'Empyrean',
        home = 56,
        startingUnits = { Infantry = 4, Fighter = 2, Destroyer = 1, Carrier = 2, Space_Dock = 1 },
        startingTech = { 'Dark Energy Tap' },
        factionTech = { "Aetherstream", "Voidwatch" },
        flagship = "Dynamo",
        flagshipDescription = "After any player's unit in this system or an adjacent system uses SUSTAIN DAMAGE, you may spend 2 influence to repair that unit.",
        abilities = { 'Voidborn', 'Aetherpassage', 'Dark Whispers' },
        units = { 'Watcher' },
        commander = 'Xuange',
        hero = 'Conservator Procyon',
        commodities = 4,
        promissoryNotes = { 'Blood Pact', 'Dark Pact' },
        breakthrough = 'Void Tether'
    },

    ['The Mahact Gene-Sorcerers'] = {
        source = 'PoK',
        tokenName = 'Mahact Gene-Sorcerers',
        frankenName = 'Mahact',
        home = 52,
        startingUnits = { Infantry = 3, Fighter = 2, Cruiser = 1, Carrier = 1, Dreadnought = 1, Space_Dock = 1 },
        startingTech = { 'Predictive Intelligence', 'Bio-Stims' },
        startMessage = 'Purge your Alliance promissory note.',
        factionTech = { "Crimson Legionnaire II", "Genetic Recombination" },
        flagship = "Arvicon Rex",
        flagshipDescription = "During combat against an opponent whose command token is not in your fleet pool, apply +2 to the results of this unit's combat rolls.",
        abilities = { 'Edict', 'Imperia', 'Hubris' },
        units = { 'Crimson Legionnaire I', 'Crimson Legionnaire II', 'Starlancer' },
        commander = 'Il Na Viroset',
        hero = 'Airo Shir Aur',
        commodities = 3,
        promissoryNotes = { 'Scepter of Dominion' },
        breakthrough = 'Vaults of the Heir'
    },

    ['The Naaz-Rokha Alliance'] = {
        source = 'PoK',
        tokenName = 'Naaz-Rokha Alliance',
        frankenName = 'Naaz-Rokha',
        home = 57,
        startingUnits = { Infantry = 3, Fighter = 2, Carrier = 2, Destroyer = 1, Mech = 1, Space_Dock = 1 },
        startingTech = { 'Psychoarchaeology', 'AI Development Algorithm' },
        factionTech = { "Supercharge", "Pre-Fab Arcologies" },
        flagship = "Visz El Vir",
        flagshipDescription = "Your mechs in this system roll 1 additional die during combat.",
        abilities = { 'Distant Suns', 'Fabrication' },
        units = { 'Eidolon' },
        commander = 'Dart and Tai',
        hero = 'Hesh and Prit',
        commodities = 3,
        promissoryNotes = { 'Black Market Forgery' },
        breakthrough = 'Eidolon Maximum'
    },

    ['The Council Keleres ~ Argent'] = {
        source = 'Codices',
        tokenName = 'Keleres ~ Argent',
        frankenName = 'Keleres ~ Argent',
        home = 258,
        startingUnits = { Infantry = 2, Fighter = 2, Carrier = 2, Cruiser = 1, Space_Dock = 1 },
        startingTech = { },
        factionTech = { "Supercharge", "Pre-Fab Arcologies" },
        flagship = "Artemiris",
        flagshipDescription = "",
        abilities = { 'The Tribunii', 'Council Patronage', "Law's order" },
        units = { 'Omniopiares' },
        commander = 'Suffi An',
        hero = 'Kuuasi Aun Jalatai',
        commodities = 2,
        promissoryNotes = { 'Keleres Rider' },
        breakthrough = 'I.I.H.Q. Modernization'
    },
    ['The Council Keleres ~ Mentak'] = {
        source = 'Codices',
        tokenName = 'Keleres ~ Mentak',
        frankenName = 'Keleres ~ Mentak',
        home = 202,
        startingUnits = { Infantry = 2, Fighter = 2, Carrier = 2, Cruiser = 1, Space_Dock = 1 },
        startingTech = { },
        factionTech = { "Supercharge", "Pre-Fab Arcologies" },
        flagship = "Artemiris",
        flagshipDescription = "",
        abilities = { 'The Tribunii', 'Council Patronage', "Law's order" },
        units = { 'Omniopiares' },
        commander = 'Suffi An',
        hero = 'Harka Leeds',
        commodities = 2,
        promissoryNotes = { 'Keleres Rider' },
        breakthrough = 'I.I.H.Q. Modernization'
    },
    ['The Council Keleres ~ Xxcha'] = {
        source = 'Codices',
        tokenName = 'Keleres ~ Xxcha',
        frankenName = 'Keleres ~ Xxcha',
        home = 214,
        startingUnits = { Infantry = 2, Fighter = 2, Carrier = 2, Cruiser = 1, Space_Dock = 1 },
        startingTech = { },
        factionTech = { "Supercharge", "Pre-Fab Arcologies" },
        flagship = "Artemiris",
        flagshipDescription = "",
        abilities = { 'The Tribunii', 'Council Patronage', "Law's order" },
        units = { 'Omniopiares' },
        commander = 'Suffi An',
        hero = 'Odlynn Myrr',
        commodities = 2,
        promissoryNotes = { 'Keleres Rider' },
        breakthrough = 'I.I.H.Q. Modernization'
    },
	
	---- Thunder's Edge Factions 
	 ['Last Bastion'] = {
        source = 'TE',
        tokenName = 'Last Bastion',
        frankenName = 'Bastion',
        home = 92,
        startingUnits = { Dreadnought = 1, Carrier = 1, Cruiser = 1, Fighter = 2, Infantry = 3, Space_Dock = 1 },
        startingTech = { },
		factionTech = { "Proxima Targetting VI", "4X4IC Helios VII" },
        flagship = 'The Egeiro',
        flagshipDescription = 'Apply +1 to the results of each of this units combat rolls for each non-homesystem that contains a planet you control.',
		startMessage = 'Choose 1 blue or yellow technology that has no prerequisites.',
        abilities = { 'Liberate', 'Galvanize', 'Pheonix Standard' },
        units = { '4X4IC "Helios" VI', '4X4IC "Helios" V2', 'A3 Valiance' },
        commander = 'Nip And Tuck',
        hero = 'Entity 4X41A "Apollo"',
        commodities = 1,
        promissoryNotes = { 'Raise The Standard' },
        breakthrough = 'The Icon'
	},
	
	['The Ral-Nel Consortium'] = {
        source = 'TE',
        tokenName = 'Ral-Nel Consortium',
        frankenName = 'Ral-Nel',
        home = 93,
        startingUnits = { Dreadnought = 1, Carrier = 1, Destroyer = 1, Fighter = 2, Infantry = 4, Space_Dock = 1, PDS = 2 },
        startingTech = { },
		factionTech = { "Nanomachines", "Linkship II" },
        flagship = 'Last Dispatch',
        flagshipDescription = 'When this unit retreats, you may destroy 1 ship in the active system that does not have SUSTAIN DAMAGE.',
		startMessage = 'Choose 1 red or green technology that has no prerequisites.',
        abilities = { 'Survival Instinct', 'Miniaturize' },
        units = { 'Linkship I', 'Linkship II', 'Alarum' },
        commander = 'Watchful Ojz',
        hero = 'Signal Intrusion',
        commodities = 4,
        promissoryNotes = { 'Nano Link Permit' },
        breakthrough = 'Data Skimmer'
	},
	
	['The Crimson Rebellion'] = {
        source = 'TE',
        tokenName = 'Crimson Rebellion',
        frankenName = 'Rebellion',
        home = 118,
        offMapHome = "The Sorrow Tile",
        startingUnits = { Carrier = 1, Destroyer = 2, Fighter = 3, Infantry = 4, Space_Dock = 1, PDS = 1 },
        startingTech = { },
		factionTech = { "Subatomic Splicer", "Exile II" },
        flagship = 'Quietus',
        flagshipDescription = 'While this unit is in a system that contains an active breach, other players units in systems with active breaches lose all of their unit abilities.',
		startMessage = 'Choose 1 blue or red technology that has no prerequisites. Gain breakthrough and roll for The Fracture.',
        abilities = { 'Sundered', 'Incursion', 'Sea of Tears', 'Quietus' },
        units = { 'Exile I', 'Exile II', 'Revenant' },
        commander = 'Ahk Siever',
        hero = 'Fragment Reality',
        commodities = 2,
        promissoryNotes = { 'Sever' },
        breakthrough = 'Resonance Generator'
	},
	
	['The Deepwrought Scholarate'] = {
        source = 'TE',
        tokenName = 'Deepwrought Scholarate',
        frankenName = 'Deepwrought',
        home = 95,
        startingUnits = { Dreadnought = 1, Carrier = 1, Fighter = 4, Infantry = 3, Space_Dock = 1 },
        startingTech = { },
		factionTech = { "Hypothermal Mining", "Radical Advancement" },
        flagship = 'DWS Luminous',
        flagshipDescription = 'This ship can move through systems that contain your units, even if other players units are present; it if would, apply +1 to its move value for each of those systems.',
		startMessage = 'Research 2 technology.',
        abilities = { 'Research Team', 'Oceanbound' },
        units = { 'Eanautic' },
        commander = 'Aello',
        hero = 'Wave Function Collapse',
        commodities = 3,
        promissoryNotes = { 'Share Knowledge' },
        breakthrough = 'Visionaria Select'
    },
	
	['The Firmament/Obsidian'] = {
        source = 'TE',
        tokenName = 'Firmament/Obsidian',
        frankenName = 'Firmament/Obsidian',
        home = 96,
        startingUnits = { Carrier = 1, Cruiser = 1, Destroyer = 1, Fighter = 3, Infantry = 3, Space_Dock = 1 },
        startingTech = { },
		factionTech = { "Neural Parasite", "Planesplitter" },
        flagship = "Heaven's Eye",
        flagshipDescription = 'If the active system contains units that belong to a player who has a control token on 1 of your plots apply +1 to this ships move value and repair it at the end of every round of combat.',
		startMessage = 'Choose 1 green or yellow technology that has no prerequisites.',
        abilities = { 'Plots Within Plots', 'Puppets Of The Blade' },
        units = { 'Viper EX-23' },
        commander = 'Captain Aroz',
        hero = 'The Blade Beckons',
        commodities = 3,
        promissoryNotes = { 'Black Ops', 'Manevolency' },
        breakthrough = 'The Sowing/The Reaping'
	},
	
	['The Obsidian'] = {
        source = 'TE',
        tokenName = 'Firmament/Obsidian',
        frankenName = 'Firmament/Obsidian',
        home = 96,
        startingUnits = { Carrier = 1, Cruiser = 1, Destroyer = 1, Fighter = 3, Infantry = 3, Space_Dock = 1 },
        startingTech = { },
		factionTech = { "Neural Parasite", "Planesplitter" },
        flagship = "Heaven's Eye",
        flagshipDescription = 'If the active system contains units that belong to a player who has a control token on 1 of your plots apply +1 to this ships move value and repair it at the end of every round of combat.',
		startMessage = 'Choose 1 green or yellow technology that has no prerequisites.',
        abilities = { 'Plots Within Plots', 'Puppets Of The Blade' },
        units = { "Heaven's Hollow", 'Viper EX-23' },
        commander = 'Aroz Hollow',
        hero = 'The Blade Revealed',
        commodities = 3,
        promissoryNotes = { 'Black Ops', 'Manevolency' },
        breakthrough = 'The Sowing/The Reaping'
	},
	
	    ----- Twilight Fall
    ['A Sickening Lurch'] = {
        source = "TF",
        tokenName = 'A Sickening Lurch',
        frankenName = 'A Sickening Lurch',
        home = 601,
        startingUnits = {  },
        startingTech = {  },
        flagship = 'A Strangled Whisper',
        flagshipDescription = "This ship can transport any number of infantry and fighters, and they do not count against this ship's capacity.",
        abilities = {  },
        units = { 'TF War Sun', 'Bone Picked Clean' },
        commander = 'Twilight Fall',
        hero = 'Twilight Fall',
        commodities = 2,
        promissoryNotes = { '' },
    },
    ['Il Na Viroset'] = {
        source = "TF",
        tokenName = 'Il Na Viroset',
        frankenName = 'Il Na Viroset',
        home = 602,
        startingUnits = {  },
        startingTech = {  },
        flagship = 'Enigma',
        flagshipDescription = "This unit ignores the effects of all anomalies. Its MOVE value is reduced by 1 for each unit it would transport.",
        abilities = { 'Starlancer XI' },
        units = { 'TF War Sun', 'Starlancer XI' },
        commander = 'Twilight Fall',
        hero = 'Twilight Fall',
        commodities = 4,
        promissoryNotes = { 'Twilight Fall' },
    },
    ['The Saint of Swords'] = {
        source = "TF",
        tokenName = 'Saint of Swords',
        frankenName = 'Saint of Swords',
        home = 603,
        startingUnits = {  },
        startingTech = { },
        flagship = 'Tizona',
        flagshipDescription = "Apply +1 to the MOVE value of this ship if it would transport 4 units.",
        abilities = { 'Colada' },
        units = { 'TF War Sun', 'Colada' },
        commander = 'Twilight Fall',
        hero = 'Twilight Fall',
        commodities = 3,
        promissoryNotes = { 'Twilight Fall' },
    },
    ['Avarice Rex'] = {
        source = "TF",
        tokenName = 'Avarice Rex',
        frankenName = 'Avarice Rex',
        home = 604,
        startingUnits = {  },
        startingTech = {  },
        flagship = 'Scintilla',
        flagshipDescription = "When you splice, gain 2 commodities or convert 2 of your commodities to trade goods.",
        abilities = { 'Twilight Fall' },
        units = { 'TF War Sun', 'Delver' },
        commander = 'Twilight Fall',
        hero = 'Twilight Fall',
        commodities = 6,
        promissoryNotes = { 'Twilight Fall' },
    },
    ['El Nen Janovet'] = {
        source = "TF",
        tokenName = 'El Nen Janovet',
        frankenName = 'El Nen Janovet',
        home = 605,
        startingUnits = {  },
        startingTech = {  },
        flagship = 'The Faces of Janovet',
        flagshipDescription = "This unit gains the unit abilities and text abilities of your destroyer, cruiser, and dreadnought unit upgrade technologies.",
        abilities = {  },
        units = { 'TF War Sun', 'Analyzer' },
        commander = 'Twilight Fall',
        hero = 'Twilight Fall',
        commodities = 3,
        promissoryNotes = { 'Twilight Fall' },
    },
    ['Il Sai Lakoe, Herald of Thorns'] = {
        source = "TF",
        tokenName = 'Il Sai Lakoe, Herald of Thorns',
        frankenName = 'Il Sai Lakoe, Herald of Thorns',
        home = 606,
        startingUnits = {  },
        startingTech = {  },
        flagship = 'Nightbloom',
        flagshipDescription = "When this unit moves, you may resolve the PRODUCTION abilities of your units in the system it stated in and each system it moved through.",
        abilities = {  },
        units = { 'TF War Sun', "Lakoe's Roots" },
        commander = 'Twilight Fall',
        hero = 'Twilight Fall',
        commodities = 3,
        promissoryNotes = { 'Twilight Fall' },
    },
    ['The Ruby Monarch'] = {
        source = "TF",
        tokenName = 'The Ruby Monarch',
        frankenName = 'The Ruby Monarch',
        home = 607,
        startingUnits = {  },
        startingTech = {  },
        flagship = 'The Scarlet Knife',
        flagshipDescription = "DEPLOY: At the start of your tun, you may discard a card from 1 of your abilities or genomes to place this unit from your reinforcements into a system that contains your ships.",
        abilities = {  },
        units = { 'TF War Sun', 'The Sharpened Edge' },
        commander = 'Twilight Fall',
        hero = 'Twilight Fall',
        commodities = 2,
        promissoryNotes = { 'Twilight Fall' },
    },
    ['Radiant Aur'] = {
        source = "TF",
        tokenName = 'Radiant Aur',
        frankenName = 'Radiant Aur',
        home = 608,
        startingUnits = {  },
        startingTech = {  },
        flagship = 'Airo Shir Rex',
        flagshipDescription = "This unit rolls dice for ANTI-FIGHTER Barrage equal to the number of different technology colors among ability you own.",
        abilities = {  },
        units = { 'TF War Sun', 'Starlancer II' },
        commander = 'Twilight Fall',
        hero = 'Twilight Fall',
        commodities = 4,
        promissoryNotes = { 'Twilight Fall' },
    },
	
}

local _colorToFaction = {}
local _lowerTokenNameToFaction = {}

local _update = {
    time = false,
    periodicUpdateSeconds = 30,
}

local _state = {
    frankenEnabled = false
}

function isFrankenEnabled()
    return _state.frankenEnabled
end

function allFactions(includeFactionsNotAtTable)
    assert(not includeFactionsNotAtTable or type(includeFactionsNotAtTable) == 'boolean')
    if includeFactionsNotAtTable then
        return _factionAttributes
    else
        _maybeUpdateFactions()
        return _colorToFaction
    end
end

function fromColor(color)
    assert(type(color) == 'string')
    _maybeUpdateFactions()
    return _colorToFaction[color]
end

--- Get faction from token name (strips off any "owner token" or "command token" suffix, if present)
function fromTokenName(tokenName)
    assert(type(tokenName) == 'string')
    tokenName = string.match(tokenName, '^(.*) .* Token$') or tokenName
    if string.len(tokenName) > 0 then
        _maybeUpdateFactions()
        return _lowerTokenNameToFaction[string.lower(tokenName)]
    end
end

--- Return map from player color to list of commander names.
function getColorToCommanders()
    local commanderNameSet = {}  -- some may still be face down!
    local colorToFactionCommander = {}
    local commandTokenNameToColor = {}
    local allianceCardNameToColor = {}
    local imperiaColorSet = false
    for color, faction in pairs(allFactions()) do
        if faction.commander then
            commanderNameSet[faction.commander] = true
            colorToFactionCommander[color] = faction.commander
        end
        commandTokenNameToColor[faction.tokenName .. ' Command Token'] = color
        allianceCardNameToColor['Alliance (' .. color .. ')'] = color
        if faction.frankenName then
            allianceCardNameToColor[faction.frankenName .. ' Alliance'] = color
        end
        if faction.shortName then
            allianceCardNameToColor[faction.shortName .. ' Alliance'] = color
        end
        for _, ability in ipairs(faction.abilities or {}) do
            if ability == 'Imperia' then
                imperiaColorSet = imperiaColorSet or {}
                imperiaColorSet[color] = true
            end
        end
    end

    -- If not using imperia do not bother finding command tokens.
    if not imperiaColorSet then
        commandTokenNameToColor = {}
    end

    -- Find alliance cards and command tokens (for imperia).
    local availableCommanderNameSet = {}
    local activeCommanderNameSet = {}  -- also track toggleActive state, when present
    local guidToAllianceColor = {}
    local guidToCommandTokenColor = {}
    local guidToPosition = {}
    local inHandGuidSet = _zoneHelper.inHand()
    for _, object in ipairs(getAllObjects()) do
        local guid = object.getGUID()
        if not inHandGuidSet[guid] then
            local name = object.getName()
            if commanderNameSet[name] and (not object.is_face_down) then
                availableCommanderNameSet[name] = true
                -- Also track if idle/active
                local isActive = true
                if _unitHelper._isToggleActiveCard(object) then
                    isActive = _unitHelper._isToggleActiveCardActive(object)
                end
                activeCommanderNameSet[name] = isActive
            end
            local color = (object.tag == 'Card') and (not object.is_face_down) and allianceCardNameToColor[name]
            if color then
                guidToAllianceColor[guid] = color
                guidToPosition[guid] = object.getPosition()
            end
            local color = commandTokenNameToColor[name]
            if color then
                guidToCommandTokenColor[guid] = color
                guidToPosition[guid] = object.getPosition()
            end
        end
    end
    local guidToZoneColor = _zoneHelper.zonesFromPositions(guidToPosition)

    local colorToCommanders = {}
    local function addCommanderIfUnlocked(color, commander, requireActive)
        assert(type(color) == 'string' and type(commander) == 'string')
        if not availableCommanderNameSet[commander] then
            return  -- locked
        end
        if requireActive and (not activeCommanderNameSet[commander]) then
            return  -- idle
        end
        local commanders = colorToCommanders[color]
        if not commanders then
            commanders = {}
            colorToCommanders[color] = commanders
        end
        for _, entry in ipairs(commanders) do
            if entry == commander then
                return -- already have this one
            end
        end
        table.insert(commanders, commander)
    end

    -- Add native.
    for color, commander in pairs(colorToFactionCommander) do
        addCommanderIfUnlocked(color, commander, true)
    end

    -- Reject any alliances if a card is toggle and idle.  There may be several
    -- ways an alliance is added (imperia, promissory, etc) so reject those too.
    local zoneColorToRejectAllianceColorSet = {}
    for guid, allianceColor in pairs(guidToAllianceColor) do
        local card = getObjectFromGUID(guid)
        local zoneColor = guidToZoneColor[guid]
        if zoneColor and _unitHelper._isToggleActiveCard(card) and not _unitHelper._isToggleActiveCardActive(card) then
            local rejectAllianceColorSet = zoneColorToRejectAllianceColorSet[zoneColor]
            if zoneColor and not rejectAllianceColorSet then
                rejectAllianceColorSet = {}
                zoneColorToRejectAllianceColorSet[zoneColor] = rejectAllianceColorSet
            end
            rejectAllianceColorSet[allianceColor] = true
        end
    end

    -- Add alliances.
    for guid, allianceColor in pairs(guidToAllianceColor) do
        -- If the alliance card has toggle active, only add it if active.
        local considerCard = true
        local requireActive = true
        local card = getObjectFromGUID(guid)
        local zoneColor = guidToZoneColor[guid]

        -- If card is active, do not require commander to be active.
        if _unitHelper._isToggleActiveCard(card) then
            if _unitHelper._isToggleActiveCardActive(card) then
                requireActive = false  -- alliance marked active
            else
                considerCard = false  -- alliace marked idle, disregard completely
            end
        end

        -- If card is idle, reject all alliances to that commander.
        local rejectAllianceColorSet = zoneColorToRejectAllianceColorSet[zoneColor]
        if rejectAllianceColorSet and rejectAllianceColorSet[allianceColor] then
            considerCard = false
        end

        if considerCard and zoneColor and (zoneColor ~= allianceColor) then
            local commander = colorToFactionCommander[allianceColor]
            if commander then
                addCommanderIfUnlocked(zoneColor, commander, requireActive)
            end
        end
    end

    -- Add Imperia.
    for guid, commandTokenColor in pairs(guidToCommandTokenColor) do
        local zoneColor = guidToZoneColor[guid]
        if zoneColor and (zoneColor ~= commandTokenColor) and imperiaColorSet[zoneColor] then
            local commander = colorToFactionCommander[commandTokenColor]
            if commander then
                addCommanderIfUnlocked(zoneColor, commander, true)
            end
        end
    end

    return colorToCommanders
end

-------------------------------------------------------------------------------

function verifyAllFactions()
    local errors = false
    for name, faction in pairs(_factionAttributes) do
        local success, errorMessage = _factionIsValid(faction)
        if not success then
            errors = errors or {}
            table.insert(errors, name .. ': ' .. errorMessage)
        end
    end
    if errors then
        error('verifyAllFactions ' .. table.concat(errors, ', '))
    end
    print('verifyAllFactions: success')
end

--- Let homebrew add custom factions via runtime injection.
-- @param faction: faction table.
function injectFaction(faction)
    assert(type(faction) == 'table')

    -- Unclear if the faction is shared with the caller, make a copy to be
    -- sure any later mutations to the caller's version does not change this.
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
    faction = copyTable(faction)

    local success, errorMessage = _factionIsValid(faction)
    if not success then
        error('injectFaction: ' .. errorMessage)
    end

    if _factionAttributes[faction.name] then
        print('injectFaction: WARNING, already have "' .. faction.name ..'", replacing with new attributes.')
    end

    _factionAttributes[faction.name] = faction
    _lowerTokenNameToFaction[string.lower(faction.name)] = faction  -- index by all name flavors
    if faction.tokenName then
        _lowerTokenNameToFaction[string.lower(faction.tokenName)] = faction
    end
    if faction.frankenName then
        _lowerTokenNameToFaction[string.lower(faction.frankenName)] = faction
    end
    if faction.shortName then
        _lowerTokenNameToFaction[string.lower(faction.shortName)] = faction
    end

    -- Tell deck helper about promissory notes (for discard back to player).
    for _, cardName in ipairs(faction.promissoryNotes or {}) do
        _deckHelper.injectCard({
            cardName = cardName,
            factionName = faction.name
        })
    end

    -- Add hero to hero name set for purge menu item, apply now if card exists.
    if faction.hero then
        local cardName = faction.hero
        if _heroNameSet then
            _heroNameSet[cardName] = true
        end
        if _hasContextMenuCardNameSet then
            _hasContextMenuCardNameSet[cardName] = true
        end
        for _, object in ipairs(getAllObjects()) do
            if object.getName() == cardName then
                _applyContextMenuItems(object)
            end
        end
    end
end

function _factionIsValid(faction)
    local name = faction.name
    if not name or type(name) ~= 'string' or string.len(name) == 0 then
        return false, 'faction.name must be a non-empty string'
    end

    local tokenName = faction.tokenName
    if not tokenName or type(tokenName) ~= 'string' or string.len(tokenName) == 0 then
        return false, 'faction.tokenName must be a non-empty string'
    end

    local frankenName = faction.frankenName
    if not frankenName or type(frankenName) ~= 'string' or string.len(frankenName) == 0 then
        return false, 'faction.frankenName must be a non-empty string'
    end

    local home = faction.home
    if not home or type(home) ~= 'number' then
        return false, 'faction.home must be a number'
    end

    local startingUnits = faction.startingUnits
    if not startingUnits or type(startingUnits) ~= 'table' then
        return false, 'faction.startingUnits must be a table'
    end

    local startingTech = faction.startingTech
    if not startingTech or type(startingTech) ~= 'table' then
        return false, 'faction.startingTech must be a table'
    end

    local flagship = faction.flagship
    if not flagship or type(flagship) ~= 'string' or string.len(flagship) == 0 then
        return false, 'faction.flagship must be a non-empty string'
    end

    local flagshipDescription = faction.flagshipDescription
    if not flagshipDescription or type(flagshipDescription) ~= 'string' or string.len(flagshipDescription) == 0 then
        return false, 'faction.flagshipDescription must be a non-empty string'
    end

    local abilities = faction.abilities
    if not abilities or type(abilities) ~= 'table' then
        return false, 'faction.abilities must be a table'
    end

    local units = faction.units
    if not units or type(units) ~= 'table' then
        return false, 'faction.units must be a table'
    end

    return true
end

-------------------------------------------------------------------------------

--[[
Commodity_modifier_fields = {
    requiredFacing = "", --true == face_up, false == face_down, nil == any facing
    order = "ADD", --"SET_BASE"|"MUTATE"|"ADD"|"SET_FINAL"
    target = "OWNER", --"ALL"|"OTHERS"|"GLOBAL" (GLOBAL means the card does not need to be in a play area; it applies to everyone)
    value = 0,
    get = function(baseValue, currentValue, obj, color) return 0 end,--For determining variable values
}--]]
local _commodityModifiers = {
    --Support for generic tokens
    ['$$ Commodities'] = {
        get = function(base, current, obj, color)
            if obj == nil then return 0 end

            local num = string.match(obj.getName(), "^[-+]%d+")
            return num and tonumber(num) or 0
        end,
        order = "ADD",
        target = "OWNER"
    },
    ['+1 Commodity'] = {
        value = 1,
        order = "ADD",
        target = "OWNER"
    },
    ['-1 Commodity'] = {
        value = -1,
        order = "ADD",
        target = "OWNER"
    },
    ['Dynamis Core'] = {
        value = 2,
        requiredFacing = true,
        order = "ADD",
        target = "OWNER"
    },
    ['The Watchtower'] = {
        value = 1,
        order = "ADD",
        target = "OWNER"
    },
    ['Oluz Station'] = {
        value = 1,
        order = "ADD",
        target = "OWNER"
    },
    ['Tsion Station'] = {
        value = 1,
        order = "ADD",
        target = "OWNER"
    },
    ['Revelation'] = {
        value = 1,
        order = "ADD",
        target = "OWNER"
    },
}

--Add your own custom commodity mods (Station cards are auto-injected with their system and generic +/- modifiers are available)
--Default param values indicated with a *
---@param params.name string : The name of the object to be detected
---@param params.order string? : *"ADD" At what stage is this mod applied "SET_BASE"|"MUTATE"|"ADD"|"SET_FINAL"
---@param params.target string? : *"OWNER" How is the target determined "OWNER"|"OTHERS"|"GLOBAL"
---@param params.value number? : *0
---@param params.get table? : *nil For a value that can change (like The Triad) {guid = scriptGUID, func = "funcName"}
---your get function will recieve 4 params: (baseValue, currentValue, obj, color)
---Return a number (used as value of THIS modifier; not the new comm value unless .order == SET_BASE or SET_FINAL)
function injectCommodityModifier(params)
    assert(params and type(params) == "table")
    assert(params.name)
    local mod = {
        value = params.value or 0,
        target = params.target or "OWNER",
        order = params.order or "ADD",
    }
    if params.get then
        local errHeader = "ERROR injecting "..params.name..": "
        assert(type(params.get) == "table", errHeader.."Table expected for .get = {guid, func")
        assert(type(params.get.guid) == "string", errHeader..".get.guid must be the (string) guid of your script object" )
        assert(type(params.get.func) == "string", errHeader..".get.func must be the (string) name of the function you wish to call")
        mod.callData = {guid = params.get.guid, func = params.get.func}
        mod.get = function(_base,_current, _obj,_color)
            local script = mod.callData.obj ~= nil and mod.callData.obj or getObjectFromGUID(mod.callData.guid)
            if not script or not script.getVar(mod.callData.func) then return 0 end
            mod.callData.obj = script
            
            return script.call(mod.callData.func, {baseValue = _base, currentValue = _current, obj = _obj, color = _color}) or 0
        end
    end

    _commodityModifiers[params.name] = mod
end

local _commModsThisFrame = nil --Cache per-frame
---@return table : Map of [color] to final commodity value
function _updateCommodities()
    if _commModsThisFrame then return _commModsThisFrame end
    Wait.frames(function() _commModsThisFrame = nil end, 1)

    if not next(_colorToFaction) then return {} end
    local result, _colorHash = {}, {}
    for color,base in pairs(_colorToFaction) do
        _colorHash[color] = true
        base._baseCommodities = base._baseCommodities or base.commodities or 0
        result[color] = base._baseCommodities
    end

    --Find Modifier Objects
    local modObjs = {}
    for _,each in ipairs(getAllObjects()) do
        --When getting the name, see if it is a generic commodity modifier. If the sub finds no match, it returns the original string anyway
        local name = string.gsub(each.getName(), "^[-+]%d+", "$$")
        if _commodityModifiers[name] then
            modObjs[each] = _commodityModifiers[name]
        end
    end

    --Get the target players of each mod
    local targetMap = {} for color,_ in pairs(_colorHash) do targetMap[color] = {SET_BASE = {}, MUTATE = {}, ADD = {}, SET_FINAL = {}} end
    for obj,mod in pairs(modObjs) do
        if mod.requiredFacing == nil or (obj.is_face_down == not mod.requiredFacing) then
            if mod.target == "GLOBAL" then
                for each,_ in pairs(_colorHash) do
                    targetMap[each][mod.order][obj] = mod
                end
            else
                local color = _zoneHelper.zoneFromPosition(obj.getPosition())
                if color then
                    if mod.target == "OWNER" then
                        targetMap[color][mod.order][obj] = mod
                    else --OTHERS
                        for each,_ in pairs(_colorHash) do
                            if each ~= color then
                                targetMap[each][mod.order][obj] = mod
                            end
                        end
                    end
                end
            end
        end
    end

    --Might go back and use meta tables for this
    local function _getValue(mod, base, current, obj, color)
        return mod.get and mod.get(base, current, obj, color) or mod.value or 0
    end
    --Apply mods for each color
    for eachColor,mods in pairs(targetMap) do
        local _base = result[eachColor]
        for each,mod in pairs(mods.SET_BASE) do
            result[eachColor] = _getValue(mod, _base, result[eachColor], each, eachColor)
        end
        for each,mod in pairs(mods.MUTATE) do
            result[eachColor] = result[eachColor] + _getValue(mod, _base, result[eachColor], each, eachColor)
        end
        for each,mod in pairs(mods.ADD) do
            result[eachColor] = result[eachColor] + _getValue(mod, _base, result[eachColor], each, eachColor)
        end
        for each,mod in pairs(mods.SET_FINAL) do
            result[eachColor] = _getValue(mod, _base, result[eachColor], each, eachColor)
        end

        result[eachColor] = math.max(0, result[eachColor])
        _colorToFaction[eachColor].commodities = result[eachColor]
    end

    _commModsThisFrame = result
    return result
end

-------------------------------------------------------------------------------

function _maybeUpdateFactions()
    if not _update.time or (Time.time - _update.time) > _update.periodicUpdateSeconds then
        updateFactions()
    end
    _updateCommodities()
end

function updateFactions()
    _update.time = Time.time

    local factionLowerToFactionName = {}
    for factionName, _ in pairs(_factionAttributes) do
        factionLowerToFactionName[string.lower(factionName)] = factionName
    end

    local frankenSet = {}
    local flagshipSet = {}
    local abilitySet = {}
    local commanderSet = {}
    local heroSet = {}
    if _state.frankenEnabled then
        for _, faction in pairs(_factionAttributes) do
            frankenSet[faction.flagship] = true
            flagshipSet[faction.flagship] = true
            for _, ability in ipairs(faction.abilities) do
                frankenSet[ability] = true
                abilitySet[ability] = true
            end
            if faction.commander then
                frankenSet[faction.commander] = true
                commanderSet[faction.commander] = true
            end
            if faction.hero then
                frankenSet[faction.hero] = true
                heroSet[faction.hero] = true
            end
        end
    end

    -- Find command sheets (indexed by color), faction sheets (indexed by
    -- faction name), and command token bags (indexed by "token faction" name,
    -- which may differ slightly from the faction sheet faction name).
    local colorToCommandSheet = {}
    local colorToLeaderSheet = {}
    local factionSheetGuidToFactionSheet = {}
    local factionSheetGuidToFactionName = {}
    local guidToName = {}
    local guidToPosition = {}
    local commanderGuidToPosition = {}
    local heroGuidToPosition = {}
    local commodityTileGuidToFactionTokenName = {}
    local colorToCommodityBonus = {}
    for _, object in ipairs(getAllObjects()) do
        local name = object.getName()
        local guid = object.getGUID()

        -- "Command Sheet (COLOR)"
        local color = string.match(name, '^Command Sheet %((%a+)%)$')
        if color then
            colorToCommandSheet[color] = object
        end

        -- "Leader Sheet (COLOR)"
        local color = string.match(name, '^Leader Sheet %((%a+)%)$')
        if color then
            colorToLeaderSheet[color] = object
        end

        -- "FACTION Sheet" (only accept if FACTION in whitelist!)
        -- Replace name with "expected" case, sometimes "of" vs "Of" depending on object.
        local factionName = string.match(name, '^(.+) Sheet$')
        factionName = factionName and factionLowerToFactionName[string.lower(factionName)]
        if factionName then
            factionSheetGuidToFactionSheet[guid] = object
            factionSheetGuidToFactionName[guid] = factionName
        end

        -- Pick up any Franken abilities.
        if _state.frankenEnabled then
            if object.tag == 'Tile' and frankenSet[name] then
                guidToName[guid] = name
                guidToPosition[guid] = object.getPosition()
            end
            if (object.tag == 'Tile' or object.tag == 'Card') and commanderSet[name] then
                commanderGuidToPosition[guid] = object.getPosition()
            end
            if (object.tag == 'Tile' or object.tag == 'Card') and heroSet[name] then
                heroGuidToPosition[guid] = object.getPosition()
            end
            local tileFactionName = string.match(name, '^(.*) Commodities$')
            if tileFactionName then
                guidToName[guid] = name
                guidToPosition[guid] = object.getPosition()
                commodityTileGuidToFactionTokenName[guid] = tileFactionName
                -- do not attempt to get faction, that table is updated later
            end
        end
    end

    -- Given a key/object-value table, return a map from command sheet color
    -- to the key whose object is closest to the command sheet AND VICE VERSA.
    -- For example, consider a table with an empty seat that has a command sheet
    -- but no faction sheet.  In that case, that orphaned command sheet does
    -- have a closest faction sheet, but that faction sheet is closer to another.
    -- Likewise consider an extra faction sheet placed on the table for some
    -- reason.  That faction sheet has a closest command sheet, but that
    -- command sheet is closer to another.
    local function distanceSq(p1, p2)
        return (p1.x - p2.x) ^ 2 + (p1.z - p2.z) ^ 2
    end
    local function minKV(map, f)
        local bestF = false
        local bestK = false
        for k, v in pairs(map) do
            local thisF = f(v)
            if not bestF or thisF < bestF then
                bestF = thisF
                bestK = k
            end
        end
        return bestK, map[bestK]
    end
    local function colorToClosestKey(keyToObjectTable)
        local result = {}
        -- Assign each object to its closest command sheet.
        local colorToKeys = {}
        for key, object in pairs(keyToObjectTable) do
            local objectPosition = object.getPosition()
            local function distance(commandSheet)
                local commandSheetPosition = commandSheet.getPosition()
                return distanceSq(objectPosition, commandSheetPosition)
            end
            local color, _ = minKV(colorToCommandSheet, distance)
            if color then
                local entry = colorToKeys[color]
                if not entry then
                    entry = {}
                    colorToKeys[color] = entry
                end
                table.insert(entry, key)
            end
        end
        -- For each color, get the closest candidate object.
        for color, keys in pairs(colorToKeys) do
            local colorPosition = colorToCommandSheet[color].getPosition()
            local function distance(key)
                local objectPosition = keyToObjectTable[key].getPosition()
                return distanceSq(objectPosition, colorPosition)
            end
            local _, key = minKV(keys, distance)
            result[color] = key
        end
        return result
    end

    -- Map command sheet color to nearest faction, tokenFaction, and seated player.
    local colorToFactionSheetGuid = colorToClosestKey(factionSheetGuidToFactionSheet)

    _colorToFaction = {}
    _lowerTokenNameToFaction = {}
    for color, factionSheetGuid in pairs(colorToFactionSheetGuid) do
        local factionName = factionSheetGuidToFactionName[factionSheetGuid]
        local attributes = {
            color = color,
            commandSheetGuid = colorToCommandSheet[color].getGUID(),
            factionSheetGuid = colorToFactionSheetGuid[color],
        }
        for k, v in pairs(_factionAttributes[factionName]) do
            attributes[k] = v
        end

        _colorToFaction[color] = attributes
        _lowerTokenNameToFaction[string.lower(attributes.name)] = attributes
        if attributes.tokenName then
            _lowerTokenNameToFaction[string.lower(attributes.tokenName)] = attributes
        end
        if attributes.frankenName then
            _lowerTokenNameToFaction[string.lower(attributes.frankenName)] = attributes
        end
        if attributes.shortName then
            _lowerTokenNameToFaction[string.lower(attributes.shortName)] = attributes
        end
    end
    
    -- Add any missing factions to token name map.
    for factionName, attributes in pairs(_factionAttributes) do
        if not _lowerTokenNameToFaction[string.lower(attributes.tokenName)] then
            _lowerTokenNameToFaction[string.lower(attributes.name)] = attributes
            if attributes.tokenName then
                _lowerTokenNameToFaction[string.lower(attributes.tokenName)] = attributes
            end
            if attributes.frankenName then
                _lowerTokenNameToFaction[string.lower(attributes.frankenName)] = attributes
            end
            if attributes.shortName then
                _lowerTokenNameToFaction[string.lower(attributes.shortName)] = attributes
            end
        end
    end

    -- If franken is enabled, reset flagship, abilities, etc based on franken tiles.
    if _state.frankenEnabled then
        local function getLeader(color, guidToPosition)
            local leaderSheet = colorToLeaderSheet[color]
            if not leaderSheet then
                return nil
            end
            local p0 = leaderSheet.getPosition()
            local best = nil
            local bestDSq = false
            for guid, p1 in ipairs(guidToPosition) do
                local p1 = getObjectFromGUID(guid).getPosition()
                local dSq = (p0.x - p1.x) ^ 2 + (p0.z - p1.z) ^ 2
                if (not bestDSq) or dSq < bestDSq then
                    best = guid
                    bestDSq = dSq
                end
            end
            local leaderObject = getObjectFromGUID(best)
            return leaderObject and leaderObject.getName() or nil
        end
        local guidToColor = _zoneHelper.zonesFromPositions(guidToPosition)
        for color, faction in pairs(_colorToFaction) do
            faction.flagship = '?'
            faction.abilities = {}
            faction.units = {}
            faction.commodities = false
            for guid, tileColor in pairs(guidToColor) do
                local name = guidToName[guid]
                if color == tileColor then
                    if flagshipSet[name] then
                        faction.flagship = name
                    elseif abilitySet[name] then
                        table.insert(faction.abilities, name)
                    elseif commodityTileGuidToFactionTokenName[guid] then
                        local tileFactionTokenName = commodityTileGuidToFactionTokenName[guid]
                        local tileFaction = fromTokenName(tileFactionTokenName)
                        faction.commodities = _factionAttributes[tileFaction.name].commodities
                    end
                end
            end
            -- Leaders.
            faction.commander = getLeader(color, commanderGuidToPosition)
            faction.hero = getLeader(color, heroGuidToPosition)
        end
    end

    _updateCommodities()
end

-------------------------------------------------------------------------------

local DEFAULT_TINT = {
    White = '8C8C8C',
    Blue = '0C98D7',
    Purple = '7500B7',
    Yellow = 'A5A300',
    Red = 'CB0000',
    Green = '007406',
    Orange = 'F3631C',
    Brown = '703A16',
    Pink = 'F46FCD',
    --Grey = '7F7F7F',
    --Black = '050505',
}

function tintTokens(params)
    _maybeUpdateFactions()

    -- No color means do all colors.
    if not params then
        for color, _ in pairs(_colorToFaction) do
            tintTokens({ color = color })
        end
        return
    end
    assert(type(params.color) == 'string')
    assert(not params.tint or type(params.tint) == 'string')

    local tintColor = assert(params.tint or DEFAULT_TINT[params.color], 'no tint color for "' .. params.color .. '"')
    assert(string.match(tintColor, '^%x%x%x%x%x%x$'), 'bad tint color "' .. tintColor .. '"')
    tintColor = Color.fromHex('#' .. tintColor .. 'ff')  -- RGBA

    local faction = _colorToFaction[params.color]
    if not faction then
        return
    end

    local tintSet = {
        [faction.tokenName .. ' Command Token'] = true,
        [faction.tokenName .. ' Owner Token'] = true,
        [faction.tokenName .. ' Command Tokens Bag'] = true,
        [faction.tokenName .. ' Owner Tokens Bag'] = true,
    }

    local function tintCommandTokensBag(bag)
        local p = bag.getPosition()
        local function takeCallback(object)
            object.setColorTint(tintColor)
            bag.putObject(object)
        end
        for i, entry in ipairs(bag.getObjects()) do
            bag.takeObject({
                guid = entry.guid,
                position = { x = p.x, y = p.y + 5 + i, z = p.z },
                callback_function = takeCallback
            })
        end
    end

    local function tintOwnerTokensBag(bag)
        local p = bag.getPosition()
        local function takeCallback(object)
            object.setColorTint(tintColor)
            bag.reset()
            bag.putObject(object)
        end
        bag.takeObject({
            position = { x = p.x, y = p.y + 5, z = p.z },
            callback_function = takeCallback
        })
    end

    for _, object in ipairs(getAllObjects()) do
        if tintSet[object.getName()] then
            object.setColorTint(tintColor)
            if object.tag == 'Bag' then
                tintCommandTokensBag(object)
            elseif object.tag == 'Infinite' then
                tintOwnerTokensBag(object)
            end
        end
    end
end

-------------------------------------------------------------------------------

local _animatingGuids = {}
function onObjectPickUp(_, pickedUpObject)
    assert(type(pickedUpObject) == 'userdata')

    _animatingGuids[pickedUpObject.getGUID()] = nil
end

function onObjectDestroy(dyingObject)
    local guid = dyingObject.getGUID()
    if guid and _animatingGuids[guid] then
        _animatingGuids[guid] = nil
    end
end


local _purgeBagGuid = nil
function getPurgeBag()
    local purgeBagObject = getObjectFromGUID(_purgeBagGuid)
    if purgeBagObject then
        return purgeBagObject
    end

    local purgeBagName = 'Purge Bag'
    for _, object in ipairs(getAllObjects()) do
        if object.tag == 'Bag' and object.getName() == purgeBagName then
            _purgeBagGuid = object.getGUID()
            return object
        end
    end

    assert(false, 'Unable to locate bag with name "' .. purgeBagName .. '"')
end

local _factionCardNameToAbilityFunc = false
local _purgeCardQueue = {}

function purgeCard(cardObject)
    assert(cardObject.tag == 'Card')

    local inHandGuidSet = _zoneHelper.inHand()
    assert(not inHandGuidSet[cardObject.getGUID()], 'Cannot purge cards that are in a player\'s hand.')

    local purgeBagObject = assert(getPurgeBag())

    --TODO: Maybe deck related stuff? Object deletion checks? Card locked stuff?

    purgeBagObject.putObject(cardObject)
end

local function _heroCardCanBeUsed(cardObject, usingColor)
    assert(type(cardObject) == 'userdata' and type(usingColor) == 'string')

    if cardObject.tag ~= 'Card' then
        printToColor('Cannot use ' .. cardObject.getName() .. '. Hero abilities can only be used from cards.', usingColor)
        return false
    end

    if cardObject.is_face_down then
        printToColor('Cannot use ' .. cardObject.getName() .. '. Card is facedown; did you unlock it?', usingColor)
        return false
    end

    local inHandGuidSet = _zoneHelper.inHand()
    if inHandGuidSet[cardObject.getGUID()] then
        printToColor('Cannot use ' .. cardObject.getName() .. '. Hero cards cannot be used while in your hand.', usingColor)
        return false
    end

    local factionColor = false
    for color, faction in pairs(allFactions(false)) do
        if faction.hero == cardObject.getName() then
            factionColor = color
            break
        end
    end
    if not factionColor then
        printToColor('Cannot use ' .. cardObject.getName() .. '. No seated faction has this Hero.', usingColor)
        return false
    end

    if factionColor ~= usingColor and usingColor ~= 'Black' then
        printToColor('Cannot use ' .. cardObject.getName() .. '. ' .. usingColor .. ' cannot use ' .. factionColor .. '\'s Hero card.', usingColor)
        return false
    end

    -- Any other technical conditions that would prevent us from purging the card or executing the ability?
    -- Any other gameplay situations that should prevent the Hero card from being used?

    return true
end
local function _paradigmCardCanBeUsed(cardObject, usingColor)
    assert(type(cardObject) == 'userdata' and type(usingColor) == 'string')

    if cardObject.tag ~= 'Card' then
        printToColor('Cannot use ' .. cardObject.getName() .. '. Paradigm abilities can only be used from cards.', usingColor)
        return false
    end

    if cardObject.is_face_down then
        printToColor('Cannot use ' .. cardObject.getName() .. '. Card is facedown; did you unlock it?', usingColor)
        return false
    end

    local inHandGuidSet = _zoneHelper.inHand()
    if inHandGuidSet[cardObject.getGUID()] then
        printToColor('Cannot use ' .. cardObject.getName() .. '. Paradigm cards cannot be used while in your hand.', usingColor)
        return false
    end
	
	local factionColor = _zoneHelper.zoneFromPosition(cardObject.getPosition())
	if factionColor ~= usingColor and usingColor ~= 'Black' then
        printToColor('Cannot use ' .. cardObject.getName() .. '. ' .. usingColor .. ' cannot use ' .. factionColor .. '\'s Paradigm card.', usingColor)
        return false
    end

    -- Any other technical conditions that would prevent us from purging the card or executing the ability?
    -- Any other gameplay situations that should prevent the Hero card from being used?

    return true
end

local function _purgeHeroCard(owningObject, clickingColor)
    if not _heroCardCanBeUsed(owningObject, clickingColor) then
        -- Function will print why card cannot be used
        return
    end

    purgeCard(owningObject)
end

local function _purgeParadigmCard(owningObject, clickingColor)
    if not _paradigmCardCanBeUsed(owningObject, clickingColor) then
        -- Function will print why card cannot be used
        return
    end

    purgeCard(owningObject)
end

-- Hero
-- Faction: Federation of Sol
-- Card Name: Jace X, 4th Air Legion
-- Ability Name: Helio Command Array
-- Ability Text:
-- ACTION: Remove each of your command tokens from the game board
-- and return them to your reinforcements. Then, purge this card.
local function _jacexHeroAbility(owningObject, clickingColor)
    if not _heroCardCanBeUsed(owningObject, clickingColor) then
        -- Function will print why card cannot be used
        return
    end

    local factionTokenName = false
    for _, faction in pairs(allFactions(false)) do
        if faction.hero == owningObject.getName() then
            factionTokenName = faction.tokenName
            break
        end
    end

    assert(factionTokenName, 'Trying to invoke Jace X Hero Ability, but no faction with "Jace X, 4th Air Legion" is at the table.')

    _strategyCardHelper.returnCommandTokensForFaction(factionTokenName)

    if owningObject.tag == 'Card' then
        purgeCard(owningObject)
    end
end
local function _federationParadigmAbility(owningObject, clickingColor)
	if not _paradigmCardCanBeUsed(owningObject, clickingColor) then
        -- Function will print why card cannot be used
        return
    end

    local factionTokenName = false
	local myColor = _zoneHelper.zoneFromPosition(owningObject.getPosition())
	if myColor then
		factionTokenName = fromColor(myColor).tokenName
	end
	
	assert(factionTokenName, 'Trying to invoke Twilight Directive, but no faction with "Twilight Directive" is at the table.')

    _strategyCardHelper.returnCommandTokensForFaction(factionTokenName)

    if owningObject.tag == 'Card' then
        purgeCard(owningObject)
    end
end

local _procynHeroAbilityOwningObjectQueue = {}
function _procynHeroAbilityCoroutine()
    local owningObject = assert(table.remove(_procynHeroAbilityOwningObjectQueue))

    -- Purge card before any wait loops
    if owningObject.tag == 'Card' then
        purgeCard(owningObject)
    end

    -- Place frontier tokens on systems that need one
    _exploreHelper.placeFrontierTokens()

    -- Wait for frontier tokens to land before exploring them.
    local waitUntil = Time.time + 3
    while Time.time < waitUntil do
        coroutine.yield(0)
    end

    --Find faction owning this hero ability (and it's color)
    local factionTokenName = false
    local factionColor = false
    for color, faction in pairs(allFactions(false)) do
        if faction.hero == owningObject.getName() then
            factionTokenName = faction.tokenName
            factionColor = color
            break
        end
    end
    assert(factionTokenName and factionColor, 'Multiverse Shift: Placed Frontier Tokens, but cannot explore them with missing owning faction.')

    --Map frontier tokens to system they're sitting on
    local frontierTokens = _exploreHelper.getAllFrontierTokens()
    local frontierTokenGuidToPosition = {}
    for _, token in ipairs(frontierTokens) do
        frontierTokenGuidToPosition[token.getGUID()] = token.getPosition()
    end
    coroutine.yield(0)

    local frontierTokenGuidToSystem = _systemHelper.systemsFromPositions(frontierTokenGuidToPosition)
    coroutine.yield(0)

    --Find all units
    local allUnits = _unitHelper.getUnits()
    coroutine.yield(0)

    --Filter down to owning faction ships
    --NOTE: Can skip units lacking faction/color; they'll be alongside other units.
    local factionShipToPosition = {}
    for _, unit in ipairs(allUnits) do
        if unit.unitType ~= 'Infantry' and unit.unitType ~= 'Mech' and unit.unitType ~= 'Space Dock' and unit.unitType ~= 'PDS' then --ships only
            if (unit.factionTokenName and unit.factionTokenName == factionTokenName) or (unit.color and unit.color == factionColor) then
                factionShipToPosition[unit.guid] = unit.position
            end
        end
    end

    --Find each system containing owning faction ship
    local shipToSystem = _systemHelper.systemsFromPositions(factionShipToPosition)
    local systemsWithFactionShipsSet = {}
    for ship, system in pairs(shipToSystem) do
        if system then
            systemsWithFactionShipsSet[system.guid] = true
        end
    end
    coroutine.yield(0)

    --For each system containing a frontier token AND owning faction ship, highlight the system tile
    local explorableTokenGuidToSystemGuid = {}
    local systemsToExplore = false
    for tokenGuid, system in pairs(frontierTokenGuidToSystem) do
        if system and systemsWithFactionShipsSet[system.guid] then
            explorableTokenGuidToSystemGuid[tokenGuid] = system.guid
            systemsToExplore = true

            -- Blinking system tiles are tied to the frontier token, NOT the system tile object.
            _animatingGuids[tokenGuid] = true
        end
    end

    -- While there are still systems to explore, blink those system tiles with the player color (2 minute timeout)
    local timeout = Time.time + 120
    while Time.time < timeout and systemsToExplore do
        systemsToExplore = false
        for tokenGuid, systemGuid in pairs(explorableTokenGuidToSystemGuid) do
            -- See if token is still on table
            local systemObject = getObjectFromGUID(systemGuid)
            if systemObject and _animatingGuids[tokenGuid] and getObjectFromGUID(tokenGuid) then
                systemObject.highlightOn(factionColor, 1)
                systemsToExplore = true
            elseif not systemObject or not getObjectFromGUID(tokenGuid) then
                _animatingGuids[tokenGuid] = nil
            end
        end

        -- Wait 2 seconds before repeating (1 sec on, 1 sec off)
        local blinkWait = Time.time + 2
        while Time.time < blinkWait do
            coroutine.yield(0)
        end
    end

    -- Ensure we're not tracking frontier tokens anymore
    for tokenGuid, _ in pairs(explorableTokenGuidToSystemGuid) do
        _animatingGuids[tokenGuid] = nil
    end

    return 1
end
local _empyreanParadigmAbilityOwningObjectQueue = {}
function _empyreanParadigmAbilityCoroutine()
    local owningObject = assert(table.remove(_empyreanParadigmAbilityOwningObjectQueue))
	local factionColor = nil

    -- Purge card before any wait loops
    if owningObject.tag == 'Card' then
		factionColor = _zoneHelper.zoneFromPosition(owningObject.getPosition())
        purgeCard(owningObject)
    end

    -- Place frontier tokens on systems that need one
    _exploreHelper.placeFrontierTokens()

    -- Wait for frontier tokens to land before exploring them.
    local waitUntil = Time.time + 3
    while Time.time < waitUntil do
        coroutine.yield(0)
    end

    --Find faction owning this hero ability (and it's color)
    local factionTokenName = false
    if factionColor then
		factionTokenName = fromColor(factionColor).tokenName
	end
    assert(factionTokenName and factionColor, 'Multiverse Shift: Placed Frontier Tokens, but cannot explore them with missing owning faction.')

    --Map frontier tokens to system they're sitting on
    local frontierTokens = _exploreHelper.getAllFrontierTokens()
    local frontierTokenGuidToPosition = {}
    for _, token in ipairs(frontierTokens) do
        frontierTokenGuidToPosition[token.getGUID()] = token.getPosition()
    end
    coroutine.yield(0)

    local frontierTokenGuidToSystem = _systemHelper.systemsFromPositions(frontierTokenGuidToPosition)
    coroutine.yield(0)

    --Find all units
    local allUnits = _unitHelper.getUnits()
    coroutine.yield(0)

    --Filter down to owning faction ships
    --NOTE: Can skip units lacking faction/color; they'll be alongside other units.
    local factionShipToPosition = {}
    for _, unit in ipairs(allUnits) do
        if unit.unitType ~= 'Infantry' and unit.unitType ~= 'Mech' and unit.unitType ~= 'Space Dock' and unit.unitType ~= 'PDS' then --ships only
            if (unit.factionTokenName and unit.factionTokenName == factionTokenName) or (unit.color and unit.color == factionColor) then
                factionShipToPosition[unit.guid] = unit.position
            end
        end
    end

    --Find each system containing owning faction ship
    local shipToSystem = _systemHelper.systemsFromPositions(factionShipToPosition)
    local systemsWithFactionShipsSet = {}
    for ship, system in pairs(shipToSystem) do
        if system then
            systemsWithFactionShipsSet[system.guid] = true
        end
    end
    coroutine.yield(0)

    --For each system containing a frontier token AND owning faction ship, highlight the system tile
    local explorableTokenGuidToSystemGuid = {}
    local systemsToExplore = false
    for tokenGuid, system in pairs(frontierTokenGuidToSystem) do
        if system and systemsWithFactionShipsSet[system.guid] then
            explorableTokenGuidToSystemGuid[tokenGuid] = system.guid
            systemsToExplore = true

            -- Blinking system tiles are tied to the frontier token, NOT the system tile object.
            _animatingGuids[tokenGuid] = true
        end
    end

    -- While there are still systems to explore, blink those system tiles with the player color (2 minute timeout)
    local timeout = Time.time + 120
    while Time.time < timeout and systemsToExplore do
        systemsToExplore = false
        for tokenGuid, systemGuid in pairs(explorableTokenGuidToSystemGuid) do
            -- See if token is still on table
            local systemObject = getObjectFromGUID(systemGuid)
            if systemObject and _animatingGuids[tokenGuid] and getObjectFromGUID(tokenGuid) then
                systemObject.highlightOn(factionColor, 1)
                systemsToExplore = true
            elseif not systemObject or not getObjectFromGUID(tokenGuid) then
                _animatingGuids[tokenGuid] = nil
            end
        end

        -- Wait 2 seconds before repeating (1 sec on, 1 sec off)
        local blinkWait = Time.time + 2
        while Time.time < blinkWait do
            coroutine.yield(0)
        end
    end

    -- Ensure we're not tracking frontier tokens anymore
    for tokenGuid, _ in pairs(explorableTokenGuidToSystemGuid) do
        _animatingGuids[tokenGuid] = nil
    end

    return 1
end

-- Hero
-- Faction: The Empyrean
-- Card Name: Conservator Procyon
-- Ability Name: Multiverse Shift
-- Ability Text:
-- ACTION: Place 1 frontier token in each system that does not contain any
-- planets and does not already have a frontier token. Then, explore each
-- frontier token that is in a system that contains 1 or more of your ships.
-- Then, purge this card.
local function _procynHeroAbility(owningObject, clickingColor) --Empyrean Hero
    if not _heroCardCanBeUsed(owningObject, clickingColor) then
        -- Function will print why card cannot be used
        return
    end

    table.insert(_procynHeroAbilityOwningObjectQueue, owningObject)
    startLuaCoroutine(self, '_procynHeroAbilityCoroutine')
end
local function _empyreanParadigmAbility(owningObject, clickingColor)
    if not _paradigmCardCanBeUsed(owningObject, clickingColor) then
        -- Function will print why card cannot be used
        return
    end

    table.insert(_empyreanParadigmAbilityOwningObjectQueue, owningObject)
    startLuaCoroutine(self, '_empyreanParadigmAbilityCoroutine')
end

local _carrionHeroAbilityOwningObjectQueue = {}
local _diceToBeRolled = {}
function _carrionHeroAbilityCoroutine()
    local owningObject = assert(table.remove(_carrionHeroAbilityOwningObjectQueue))
    if #_diceToBeRolled > 0 then
        printToAll('Remove previously devoured ships before re-using Dimensional Anchor.')
        return 1
    end

    --Find faction owning this hero ability (and it's color)
    local factionTokenName = false
    local factionColor = false
    for color, faction in pairs(allFactions(false)) do
        if faction.hero == owningObject.getName() then
            factionTokenName = faction.tokenName
            factionColor = color
            break
        end
    end
    assert(factionTokenName and factionColor, 'Dimensional Anchor: Trying to invoke Hero Ability, but no faction with "It Feeds on Carrion" is at the table.')

    --Find each dimensional tear token (Cabal and Nekro)
    local dimTokenToPosition = {}
    local anyDimensionalTears = false
    for _, object in ipairs(getAllObjects()) do
        if object.tag == 'Tile' then
            local objname = object.getName()
            if objname == 'Dimensional Tear' or objname == 'Assimilated Tear' then
                dimTokenToPosition[object.getGUID()] = object.getPosition()
                anyDimensionalTears = true
            end
        end
    end
    coroutine.yield(0)

    if not anyDimensionalTears then
        printToAll('Dimensional Anchor: No Dimensional Tear tokens found on the table. Won\'t use Hero Ability.')
        return 1
    end

    --Find hex those tokens are on
    local dimensionalTearToHex = _systemHelper.hexesFromPositions(dimTokenToPosition)

    --Find set of hexes adjacent to above (including wormholes)
    local hexToNeighboringHexes = {}
    for _, hex in pairs(dimensionalTearToHex) do
        local directlyAdjacentHexes = _systemHelper.hexNeighborsWithHyperlanes(hex)
        local wormholeAdjacentHexes = _systemHelper.hexAdjacentWormholes({hex = hex, playerColor = factionColor})

        local neighboringHexSet = {}
        for _, adjHex in ipairs(directlyAdjacentHexes) do
            neighboringHexSet[adjHex] = true
        end
        for _, adjHex in ipairs(wormholeAdjacentHexes) do
            neighboringHexSet[adjHex] = true
        end

        local neighboringHexes = {}
        for adjHex, _ in pairs(neighboringHexSet) do
            table.insert(neighboringHexes, adjHex)
        end

        hexToNeighboringHexes[hex] = neighboringHexes

        coroutine.yield(0)
    end

    -- Get map of hex to system tile. Used to confirm a hex is actually placed on the table.
    -- (neighboring hexes can be computed from math, regardless of the presence of a system tile)
    local allHexesAsMap = {}
    for _, hex in pairs(dimensionalTearToHex) do
        allHexesAsMap[hex] = hex
        for _, adjHex in ipairs(hexToNeighboringHexes[hex]) do
            allHexesAsMap[adjHex] = adjHex
        end
    end

    local allHexesToPosition = _systemHelper.hexesToPosition(allHexesAsMap)
    local allHexesToSystemTiles = _systemHelper.systemsFromPositions(allHexesToPosition)
    coroutine.yield(0)

    --Find all units on those hexes
    local opponentShipToHex = {}
    local unitByGuid = {}
    local allUnits = _unitHelper.getUnits()
    for _, unit in ipairs(allUnits) do
        if unit.unitType ~= 'Infantry' and unit.unitType ~= 'Mech' and unit.unitType ~= 'Fighter' and unit.unitType ~= 'Space Dock' and unit.unitType ~= 'PDS' then --non-fighter ships only
            if (unit.factionTokenName and unit.factionTokenName ~= factionTokenName) or (unit.color and unit.color ~= factionColor) then
                opponentShipToHex[unit.guid] = unit.hex
                unitByGuid[unit.guid] = unit
            end
        end
    end

    local anchoredShipsCount = 0
    local systemToAnchoredShips = {}
    for shipGuid, hex in pairs(opponentShipToHex) do
        local system = allHexesToSystemTiles[hex]
        if system then
            local systemShips = systemToAnchoredShips[system]
            if not systemShips then
                systemShips = {}
                systemToAnchoredShips[system] = systemShips
            end

            table.insert(systemShips, shipGuid)
            anchoredShipsCount = anchoredShipsCount + 1
        end
    end

    if anchoredShipsCount == 0 then
        printToAll('Dimensional Anchor: No non-fighter ships adjacent to Dimensional Tear systems. Won\'t use Hero Ability.')
        return 1
    end

    -- Safe to commit to acting at this point, so purge the Hero card.
    if owningObject.tag == 'Card' then
        purgeCard(owningObject)
    end

    -- Function spawns dice for each ship, sets a dice cleanup on a 2 minute timeout,
    -- and prints a guide for the dice color for auditability.
    local function _prepareDice(systemToAnchoredShips)
        -- Data and methods for dice handling copied from multiroller.

        local dieType = "Die_10"
        local removalDelay = 5
        local radialOffset = 1.2
        local heightOffset = 5
        local dieSize = 1

        --Finds a position, rotated around the Y axis, using distance you want + angle
        --oPos is object pos, oRot=object rotation, distance = how far, angle = angle in degrees
        local function _findGlobalPosWithLocalDirection(spawn_object, angle)
            local object, distance = spawn_object, radialOffset * self.getScale().x
            local oPos, oRot = object.getPosition(), object.getRotation()
            local posX = oPos.x + math.sin( math.rad(angle+oRot.y) ) * distance
            local posY = oPos.y + heightOffset
            local posZ = oPos.z + math.cos( math.rad(angle+oRot.y) ) * distance
            return {x=posX, y=posY, z=posZ}
        end

        --Gets a random rotation vector
        local function _randomRotation()
            --Credit for this function goes to Revinor (forums)
            --Get 3 random numbers
            local u1 = math.random();
            local u2 = math.random();
            local u3 = math.random();
            --Convert them into quats to avoid gimbal lock
            local u1sqrt = math.sqrt(u1);
            local u1m1sqrt = math.sqrt(1-u1);
            local qx = u1m1sqrt *math.sin(2*math.pi*u2);
            local qy = u1m1sqrt *math.cos(2*math.pi*u2);
            local qz = u1sqrt *math.sin(2*math.pi*u3);
            local qw = u1sqrt *math.cos(2*math.pi*u3);
            --Apply rotation
            local ysqr = qy * qy;
            local t0 = -2.0 * (ysqr + qz * qz) + 1.0;
            local t1 = 2.0 * (qx * qy - qw * qz);
            local t2 = -2.0 * (qx * qz + qw * qy);
            local t3 = 2.0 * (qy * qz - qw * qx);
            local t4 = -2.0 * (qx * qx + ysqr) + 1.0;
            --Correct
            if t2 > 1.0 then t2 = 1.0 end
            if t2 < -1.0 then ts = -1.0 end
            --Convert back to X/Y/Z
            local xr = math.asin(t2);
            local yr = math.atan2(t3, t4);
            local zr = math.atan2(t1, t0);
            --Return result
            return {math.deg(xr),math.deg(yr),math.deg(zr)}
        end

        -- Use different color dice for manual auditability; copy from Multiroller
        local unitTypeToDiceColor = {
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

        local diceToShip = {}
        local unitTypesUsed = {}
        _diceToBeRolled = {}

        -- Spawn a die for each ship, around the system tile the ship is on.
        for system, ships in pairs(systemToAnchoredShips) do
            local shipCount = #ships
            local angleStep = (360 / shipCount)

            local systemObject = getObjectFromGUID(system.guid)

            for i, ship in ipairs(ships) do
                local shipAttrs = unitByGuid[ship]

                local dieObject = spawnObject({
                    type=dieType,
                    position = _findGlobalPosWithLocalDirection(systemObject, angleStep*(i-1)),
                    rotation = _randomRotation(), scale={dieSize,dieSize,dieSize},
                    callback_function = function(obj) --GUID is not available right away
                        diceToShip[obj.getGUID()] = ship
                        table.insert(_diceToBeRolled, obj.getGUID())
                     end,
                })
                dieObject.setLock(true)
                dieObject.setColorTint(stringColorToRGB(unitTypeToDiceColor[shipAttrs.unitType]))

                unitTypesUsed[shipAttrs.unitType] = true
            end
        end

        -- Print guide showing the dice color for each ship.
        printToAll('DICE COLOR GUIDE')
        for unitType, color in pairs(unitTypeToDiceColor) do
            if unitTypesUsed[unitType] then
                printToAll('* ' .. unitType .. ': ' .. color)
            end
        end

        -- Remove dice from board no matter what after 2 minutes
        local function destroyDice()
            for _, die in ipairs(_diceToBeRolled) do
                local dieObject = getObjectFromGUID(die)
                if dieObject then
                    destroyObject(dieObject)
                end
            end
            _diceToBeRolled = {}
        end
        Wait.time(destroyDice, 120)

        return diceToShip
    end

    -- For each system, do rolls. Track results, print them by system+unitType.
    -- eg. 'Bereg / Lirta IV: Cruiser has 1 capture (2#, 4, 9); Dreadnought has 0 captures (6).'
    local diceToShip = _prepareDice(systemToAnchoredShips)

    -- Wait for all dice to spawn and receive a GUID
    local diceToShipCount = 0
    while diceToShipCount < anchoredShipsCount do
        coroutine.yield(0)

        diceToShipCount = 0
        for die, _ in pairs(diceToShip) do
            diceToShipCount = diceToShipCount + 1
        end
    end

    -- Start rolling dice.
    -- Separate coroutine, so 'self' can animate hexes while the dice are being rolled.
    startLuaCoroutine(self, 'dimensionalanchor_rollDiceCoroutine')

    -- Function checks if dice are all still, and if they are maps their values to the ship they rolled for.
    -- If dice are NOT still, just return an object with "waitingOnResults = true"
    local function _processRollResults(diceToShip)
        -- Wait for all dice to be settled
        local waitingOnResults = false
        for die, _ in pairs(diceToShip) do
            local dieObject = getObjectFromGUID(die)
            if dieObject and not dieObject.resting then
                waitingOnResults = true
                break
            end
        end

        -- ALWAYS report a value even if dice aren't resting, in case of timeout.
        local shipToResult = {}
        for die, ship in pairs(diceToShip) do
            local dieObject = getObjectFromGUID(die)
            shipToResult[ship] = dieObject and dieObject.getValue() or 0
        end

        return { waitingOnResults = waitingOnResults, shipToResult = shipToResult }
    end

    -- For blinking hexes.
    -- blinkMode == 0: Set a highlight on hexes containing dimensional tear tokens
    -- blinkMode == 1: Set a highlight only on hexes adjacent to dimensional tear tokens
    -- blinkMode == 2: Do nothing (let highlights fade)
    local function _setHexBlinkMode(dimTearHexToNeighboringHexes, allHexesToSystemTiles, blinkMode, blinkDuration)
        if blinkMode > 1 then
            return
        end

        if blinkMode == 0 then
            for hex, _ in pairs(dimTearHexToNeighboringHexes) do
                local system = allHexesToSystemTiles[hex]
                if system and not system.hyperlane then
                    local systemObject = getObjectFromGUID(system.guid)
                    if systemObject then
                        systemObject.highlightOn(factionColor, blinkDuration)
                    end
                end
            end
        end

        if blinkMode == 1 then
            for _, adjHexes in pairs(dimTearHexToNeighboringHexes) do
                for _, hex in ipairs(adjHexes) do
                    local system = allHexesToSystemTiles[hex]
                    if system and not system.hyperlane then
                        local systemObject = getObjectFromGUID(system.guid)
                        if systemObject then
                            systemObject.highlightOn(factionColor, blinkDuration)
                        end
                    end
                end
            end
        end
    end

    -- Check for results,
    -- and trigger system tile highlighting until results are ready
    local rollResults = { waitingOnResults = true }
    local rollTimeout = Time.time + 10
    local rollMinimumWait = Time.time + 3
    local blinkMode = 2 -- 0 = dim tear hexes; 1 = adj hexes; 2 = no hexes
    local blinkTransitionTime = 0
    while (rollResults.waitingOnResults or Time.time < rollMinimumWait) and Time.time < rollTimeout do
        -- Animation 1: Alternating dimensional tear and adjacent hex blinking
        --blinkMode = (blinkMode + 1) % 3
        --blinkTransitionTime = Time.time + 0.25 + (blinkMode == 2 and 0.25 or 0)
        --_setHexBlinkMode(hexToNeighboringHexes, allHexesToSystemTiles, blinkMode, 0.5)

        -- Animation 2: Highlight all relevant hexes, then just the dimensional tear ones.
        -- Gives the impression of ships being sucked towards the dimensional tears
        blinkTransitionTime = Time.time + 1.5
        _setHexBlinkMode(hexToNeighboringHexes, allHexesToSystemTiles, 0, 1)
        _setHexBlinkMode(hexToNeighboringHexes, allHexesToSystemTiles, 1, 0.5)

        -- Animation 3: Highlight all on, then all off. Simplest visually. Probably best from a gameplay
        -- perspective and sticking to the "soul" of the physical game. But less cool, and less obvious why a
        -- a system is adjacent when it's a random wormhole token or something across the board.
        --blinkTransitionTime = Time.time + 2
        --_setHexBlinkMode(hexToNeighboringHexes, allHexesToSystemTiles, 0, 1)
        --_setHexBlinkMode(hexToNeighboringHexes, allHexesToSystemTiles, 1, 1)

        while blinkTransitionTime > Time.time do
            coroutine.yield(0)
        end

        rollResults = _processRollResults(diceToShip)
        coroutine.yield(0)
    end

    -- Get results
    local shipToResult = rollResults.shipToResult

    -- Print results
    for system, ships in pairs(systemToAnchoredShips) do
        local unitTypeToResultRolls = {}

        for _, ship in ipairs(ships) do
            local shipAttrs = assert(unitByGuid[ship])
            local descriptiveUnitType = shipAttrs.unitType
            if shipAttrs.factionTokenName then
                descriptiveUnitType = shipAttrs.factionTokenName .. '\'s ' .. descriptiveUnitType
            elseif shipAttrs.color then
                descriptiveUnitType = shipAttrs.color .. ' ' .. descriptiveUnitType
            end

            local resultsForType = unitTypeToResultRolls[descriptiveUnitType]
            if not resultsForType then
                resultsForType = {}
                unitTypeToResultRolls[descriptiveUnitType] = resultsForType
            end

            table.insert(resultsForType, assert(shipToResult[ship]))
        end

        printToAll('Results for ' .. system.string .. ':')
        for unitType, results in pairs(unitTypeToResultRolls) do
            local resultString = ''
            local first = true
            for _, result in ipairs(results) do
                if not first then
                    resultString  = resultString .. ', '
                end

                resultString = resultString .. result
                if result < 4 then
                    resultString = resultString .. '#'
                end

                first = false
            end

            printToAll('* ' .. unitType .. ': ' .. resultString)
        end
    end

    -- Create list of dying ships.
    -- Only includes ships whose roll was 1-3 (failing)
    local dyingShips = {}
    for ship, result in pairs(shipToResult) do
        if result < 4 then
            local shipObject = getObjectFromGUID(ship)
            if shipObject then
                table.insert(dyingShips, ship)
                _animatingGuids[ship] = true
            end
        end
    end

    -- Loop and highlight dead ships until they're removed from their hex.
    local anchoredUnitsUnmoved = true
    local anchoredUnitsTimeout = Time.time + 120
    while Time.time < anchoredUnitsTimeout and anchoredUnitsUnmoved do
        anchoredUnitsUnmoved = false

        local currentTileToDeathTile = {}
        local shipStateToPosition = {}

        for _, ship in ipairs(dyingShips) do
            if _animatingGuids[ship] then
                local shipObject = getObjectFromGUID(ship)
                if shipObject then
                    anchoredUnitsUnmoved = true
                    shipObject.highlightOn(factionColor, 0.75)
                else
                    _animatingGuids[ship] = nil
                end
            end
        end

        -- Wait 2 seconds before repeating (1 sec on, 1 sec off)
        local blinkWait = Time.time + 1.5
        while Time.time < blinkWait do
            coroutine.yield(0)
        end
    end

    -- Stop tracking all GUIDs from this animation
    for _, ship in ipairs(dyingShips) do
        _animatingGuids[ship] = nil
    end

    -- At this point, all dying ships have been handled. Destroy dice.
    for _, die in ipairs(_diceToBeRolled) do
        local dieObject = getObjectFromGUID(die)
        if dieObject then
            destroyObject(dieObject)
        end
    end
    _diceToBeRolled = {}

    return 1
end
local _vuilraithParadigmAbilityOwningObjectQueue = {}
local _vuilraithParadigmAbilityDice = {}
function _vuilraithParadigmAbilityCoroutine()
    local owningObject = assert(table.remove(_vuilraithParadigmAbilityOwningObjectQueue))
    if #_vuilraithParadigmAbilityDice > 0 then
        printToAll('Remove previous ships before re-using Event Horizon.')
        return 1
    end

    --Find faction owning this hero ability (and it's color)
    local factionColor = _zoneHelper.zoneFromPosition(owningObject.getPosition())
    local factionTokenName = false
    if factionColor then
		factionTokenName = fromColor(factionColor).tokenName
	end
    assert(factionTokenName and factionColor, 'Event Horizon: Trying to invoke Paradigm Ability, but no faction with "Event Horizon" is at the table.')

    --Find each gravity rift system
    local gravityRiftToPosition = {}
    local anyGravityRifts = false
	local _systems = _systemHelper.systems()
    for _, object in pairs(getAllObjects()) do
		if _systems[object.getGUID()] then
			local system = _systems[object.getGUID()]
			local hasGravityRift = false
			if system.anomalies then
				for _, anomaly in ipairs(system.anomalies) do
					if anomaly == 'gravity rift' then
						hasGravityRift = true
					end
				end
			end
			if hasGravityRift then
				gravityRiftToPosition[object.getGUID()] = object.getPosition()
				anyGravityRifts = true
			end
		end
	end
    coroutine.yield(0)

    if not anyGravityRifts then
        printToAll('Event Horizon: No Gravity Rift systems found. Won\'t use Paradigm Ability.')
        return 1
    end

    --Find hex those tokens are on
    local gravityRiftToHex = _systemHelper.hexesFromPositions(gravityRiftToPosition)

    --Find set of hexes adjacent to above (including wormholes)
    local hexToNeighboringHexes = {}
    for _, hex in pairs(gravityRiftToHex) do
        local directlyAdjacentHexes = _systemHelper.hexNeighborsWithHyperlanes(hex)
        local wormholeAdjacentHexes = _systemHelper.hexAdjacentWormholes({hex = hex, playerColor = factionColor})

        local neighboringHexSet = {}
        for _, adjHex in ipairs(directlyAdjacentHexes) do
            neighboringHexSet[adjHex] = true
        end
        for _, adjHex in ipairs(wormholeAdjacentHexes) do
            neighboringHexSet[adjHex] = true
        end

        local neighboringHexes = {}
        for adjHex, _ in pairs(neighboringHexSet) do
            table.insert(neighboringHexes, adjHex)
        end

        hexToNeighboringHexes[hex] = neighboringHexes

        coroutine.yield(0)
    end

    -- Get map of hex to system tile. Used to confirm a hex is actually placed on the table.
    -- (neighboring hexes can be computed from math, regardless of the presence of a system tile)
    local allHexesAsMap = {}
    for _, hex in pairs(gravityRiftToHex) do
        allHexesAsMap[hex] = hex
        for _, adjHex in ipairs(hexToNeighboringHexes[hex]) do
            allHexesAsMap[adjHex] = adjHex
        end
    end

    local allHexesToPosition = _systemHelper.hexesToPosition(allHexesAsMap)
    local allHexesToSystemTiles = _systemHelper.systemsFromPositions(allHexesToPosition)
    coroutine.yield(0)

    --Find all units on those hexes
    local opponentShipToHex = {}
    local unitByGuid = {}
    local allUnits = _unitHelper.getUnits()
    for _, unit in ipairs(allUnits) do
        if unit.unitType ~= 'Infantry' and unit.unitType ~= 'Mech' and unit.unitType ~= 'Fighter' and unit.unitType ~= 'Space Dock' and unit.unitType ~= 'PDS' then --non-fighter ships only
            if (unit.factionTokenName and unit.factionTokenName ~= factionTokenName) or (unit.color and unit.color ~= factionColor) then
                opponentShipToHex[unit.guid] = unit.hex
                unitByGuid[unit.guid] = unit
            end
        end
    end

    local anchoredShipsCount = 0
    local systemToAnchoredShips = {}
    for shipGuid, hex in pairs(opponentShipToHex) do
        local system = allHexesToSystemTiles[hex]
        if system then
            local systemShips = systemToAnchoredShips[system]
            if not systemShips then
                systemShips = {}
                systemToAnchoredShips[system] = systemShips
            end

            table.insert(systemShips, shipGuid)
            anchoredShipsCount = anchoredShipsCount + 1
        end
    end

    if anchoredShipsCount == 0 then
        printToAll('Event Horizon: No non-fighter ships adjacent to Gravity Rift systems. Won\'t use Paradigm Ability.')
        return 1
    end

    -- Safe to commit to acting at this point, so purge the Hero card.
    if owningObject.tag == 'Card' then
        purgeCard(owningObject)
    end

    -- Function spawns dice for each ship, sets a dice cleanup on a 2 minute timeout,
    -- and prints a guide for the dice color for auditability.
    local function _prepareDice(systemToAnchoredShips)
        -- Data and methods for dice handling copied from multiroller.

        local dieType = "Die_10"
        local removalDelay = 5
        local radialOffset = 1.2
        local heightOffset = 5
        local dieSize = 1

        --Finds a position, rotated around the Y axis, using distance you want + angle
        --oPos is object pos, oRot=object rotation, distance = how far, angle = angle in degrees
        local function _findGlobalPosWithLocalDirection(spawn_object, angle)
            local object, distance = spawn_object, radialOffset * self.getScale().x
            local oPos, oRot = object.getPosition(), object.getRotation()
            local posX = oPos.x + math.sin( math.rad(angle+oRot.y) ) * distance
            local posY = oPos.y + heightOffset
            local posZ = oPos.z + math.cos( math.rad(angle+oRot.y) ) * distance
            return {x=posX, y=posY, z=posZ}
        end

        --Gets a random rotation vector
        local function _randomRotation()
            --Credit for this function goes to Revinor (forums)
            --Get 3 random numbers
            local u1 = math.random();
            local u2 = math.random();
            local u3 = math.random();
            --Convert them into quats to avoid gimbal lock
            local u1sqrt = math.sqrt(u1);
            local u1m1sqrt = math.sqrt(1-u1);
            local qx = u1m1sqrt *math.sin(2*math.pi*u2);
            local qy = u1m1sqrt *math.cos(2*math.pi*u2);
            local qz = u1sqrt *math.sin(2*math.pi*u3);
            local qw = u1sqrt *math.cos(2*math.pi*u3);
            --Apply rotation
            local ysqr = qy * qy;
            local t0 = -2.0 * (ysqr + qz * qz) + 1.0;
            local t1 = 2.0 * (qx * qy - qw * qz);
            local t2 = -2.0 * (qx * qz + qw * qy);
            local t3 = 2.0 * (qy * qz - qw * qx);
            local t4 = -2.0 * (qx * qx + ysqr) + 1.0;
            --Correct
            if t2 > 1.0 then t2 = 1.0 end
            if t2 < -1.0 then ts = -1.0 end
            --Convert back to X/Y/Z
            local xr = math.asin(t2);
            local yr = math.atan2(t3, t4);
            local zr = math.atan2(t1, t0);
            --Return result
            return {math.deg(xr),math.deg(yr),math.deg(zr)}
        end

        -- Use different color dice for manual auditability; copy from Multiroller
        local unitTypeToDiceColor = {
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

        local diceToShip = {}
        local unitTypesUsed = {}
        _vuilraithParadigmAbilityDice = {}

        -- Spawn a die for each ship, around the system tile the ship is on.
        for system, ships in pairs(systemToAnchoredShips) do
            local shipCount = #ships
            local angleStep = (360 / shipCount)

            local systemObject = getObjectFromGUID(system.guid)

            for i, ship in ipairs(ships) do
                local shipAttrs = unitByGuid[ship]

                local dieObject = spawnObject({
                    type=dieType,
                    position = _findGlobalPosWithLocalDirection(systemObject, angleStep*(i-1)),
                    rotation = _randomRotation(), scale={dieSize,dieSize,dieSize},
                    callback_function = function(obj) --GUID is not available right away
                        diceToShip[obj.getGUID()] = ship
                        table.insert(_vuilraithParadigmAbilityDice, obj.getGUID())
                     end,
                })
                dieObject.setLock(true)
                dieObject.setColorTint(stringColorToRGB(unitTypeToDiceColor[shipAttrs.unitType]))

                unitTypesUsed[shipAttrs.unitType] = true
            end
        end

        -- Print guide showing the dice color for each ship.
        printToAll('DICE COLOR GUIDE')
        for unitType, color in pairs(unitTypeToDiceColor) do
            if unitTypesUsed[unitType] then
                printToAll('* ' .. unitType .. ': ' .. color)
            end
        end

        -- Remove dice from board no matter what after 2 minutes
        local function destroyDice()
            for _, die in ipairs(_vuilraithParadigmAbilityDice) do
                local dieObject = getObjectFromGUID(die)
                if dieObject then
                    destroyObject(dieObject)
                end
            end
            _vuilraithParadigmAbilityDice = {}
        end
        Wait.time(destroyDice, 120)

        return diceToShip
    end

    -- For each system, do rolls. Track results, print them by system+unitType.
    -- eg. 'Bereg / Lirta IV: Cruiser has 1 capture (2#, 4, 9); Dreadnought has 0 captures (6).'
    local diceToShip = _prepareDice(systemToAnchoredShips)

    -- Wait for all dice to spawn and receive a GUID
    local diceToShipCount = 0
    while diceToShipCount < anchoredShipsCount do
        coroutine.yield(0)

        diceToShipCount = 0
        for die, _ in pairs(diceToShip) do
            diceToShipCount = diceToShipCount + 1
        end
    end

    -- Start rolling dice.
    -- Separate coroutine, so 'self' can animate hexes while the dice are being rolled.
    startLuaCoroutine(self, 'eventhorizon_rollDiceCoroutine')

    -- Function checks if dice are all still, and if they are maps their values to the ship they rolled for.
    -- If dice are NOT still, just return an object with "waitingOnResults = true"
    local function _processRollResults(diceToShip)
        -- Wait for all dice to be settled
        local waitingOnResults = false
        for die, _ in pairs(diceToShip) do
            local dieObject = getObjectFromGUID(die)
            if dieObject and not dieObject.resting then
                waitingOnResults = true
                break
            end
        end

        -- ALWAYS report a value even if dice aren't resting, in case of timeout.
        local shipToResult = {}
        for die, ship in pairs(diceToShip) do
            local dieObject = getObjectFromGUID(die)
            shipToResult[ship] = dieObject and dieObject.getValue() or 0
        end

        return { waitingOnResults = waitingOnResults, shipToResult = shipToResult }
    end

    -- For blinking hexes.
    -- blinkMode == 0: Set a highlight on hexes containing dimensional tear tokens
    -- blinkMode == 1: Set a highlight only on hexes adjacent to dimensional tear tokens
    -- blinkMode == 2: Do nothing (let highlights fade)
    local function _setHexBlinkMode(dimTearHexToNeighboringHexes, allHexesToSystemTiles, blinkMode, blinkDuration)
        if blinkMode > 1 then
            return
        end

        if blinkMode == 0 then
            for hex, _ in pairs(dimTearHexToNeighboringHexes) do
                local system = allHexesToSystemTiles[hex]
                if system and not system.hyperlane then
                    local systemObject = getObjectFromGUID(system.guid)
                    if systemObject then
                        systemObject.highlightOn(factionColor, blinkDuration)
                    end
                end
            end
        end

        if blinkMode == 1 then
            for _, adjHexes in pairs(dimTearHexToNeighboringHexes) do
                for _, hex in ipairs(adjHexes) do
                    local system = allHexesToSystemTiles[hex]
                    if system and not system.hyperlane then
                        local systemObject = getObjectFromGUID(system.guid)
                        if systemObject then
                            systemObject.highlightOn(factionColor, blinkDuration)
                        end
                    end
                end
            end
        end
    end

    -- Check for results,
    -- and trigger system tile highlighting until results are ready
    local rollResults = { waitingOnResults = true }
    local rollTimeout = Time.time + 10
    local rollMinimumWait = Time.time + 3
    local blinkMode = 2 -- 0 = dim tear hexes; 1 = adj hexes; 2 = no hexes
    local blinkTransitionTime = 0
    while (rollResults.waitingOnResults or Time.time < rollMinimumWait) and Time.time < rollTimeout do
        -- Animation 1: Alternating dimensional tear and adjacent hex blinking
        --blinkMode = (blinkMode + 1) % 3
        --blinkTransitionTime = Time.time + 0.25 + (blinkMode == 2 and 0.25 or 0)
        --_setHexBlinkMode(hexToNeighboringHexes, allHexesToSystemTiles, blinkMode, 0.5)

        -- Animation 2: Highlight all relevant hexes, then just the dimensional tear ones.
        -- Gives the impression of ships being sucked towards the dimensional tears
        blinkTransitionTime = Time.time + 1.5
        _setHexBlinkMode(hexToNeighboringHexes, allHexesToSystemTiles, 0, 1)
        _setHexBlinkMode(hexToNeighboringHexes, allHexesToSystemTiles, 1, 0.5)

        -- Animation 3: Highlight all on, then all off. Simplest visually. Probably best from a gameplay
        -- perspective and sticking to the "soul" of the physical game. But less cool, and less obvious why a
        -- a system is adjacent when it's a random wormhole token or something across the board.
        --blinkTransitionTime = Time.time + 2
        --_setHexBlinkMode(hexToNeighboringHexes, allHexesToSystemTiles, 0, 1)
        --_setHexBlinkMode(hexToNeighboringHexes, allHexesToSystemTiles, 1, 1)

        while blinkTransitionTime > Time.time do
            coroutine.yield(0)
        end

        rollResults = _processRollResults(diceToShip)
        coroutine.yield(0)
    end

    -- Get results
    local shipToResult = rollResults.shipToResult

    -- Print results
    for system, ships in pairs(systemToAnchoredShips) do
        local unitTypeToResultRolls = {}

        for _, ship in ipairs(ships) do
            local shipAttrs = assert(unitByGuid[ship])
            local descriptiveUnitType = shipAttrs.unitType
            if shipAttrs.factionTokenName then
                descriptiveUnitType = shipAttrs.factionTokenName .. '\'s ' .. descriptiveUnitType
            elseif shipAttrs.color then
                descriptiveUnitType = shipAttrs.color .. ' ' .. descriptiveUnitType
            end

            local resultsForType = unitTypeToResultRolls[descriptiveUnitType]
            if not resultsForType then
                resultsForType = {}
                unitTypeToResultRolls[descriptiveUnitType] = resultsForType
            end

            table.insert(resultsForType, assert(shipToResult[ship]))
        end

        printToAll('Results for ' .. system.string .. ':')
        for unitType, results in pairs(unitTypeToResultRolls) do
            local resultString = ''
            local first = true
            for _, result in ipairs(results) do
                if not first then
                    resultString  = resultString .. ', '
                end

                resultString = resultString .. result
                if result < 6 then
                    resultString = resultString .. '#'
                end

                first = false
            end

            printToAll('* ' .. unitType .. ': ' .. resultString)
        end
    end

    -- Create list of dying ships.
    -- Only includes ships whose roll was 1-5 (failing)
    local dyingShips = {}
    for ship, result in pairs(shipToResult) do
        if result < 6 then
            local shipObject = getObjectFromGUID(ship)
            if shipObject then
                table.insert(dyingShips, ship)
                _animatingGuids[ship] = true
            end
        end
    end

    -- Loop and highlight dead ships until they're removed from their hex.
    local anchoredUnitsUnmoved = true
    local anchoredUnitsTimeout = Time.time + 120
    while Time.time < anchoredUnitsTimeout and anchoredUnitsUnmoved do
        anchoredUnitsUnmoved = false

        local currentTileToDeathTile = {}
        local shipStateToPosition = {}

        for _, ship in ipairs(dyingShips) do
            if _animatingGuids[ship] then
                local shipObject = getObjectFromGUID(ship)
                if shipObject then
                    anchoredUnitsUnmoved = true
                    shipObject.highlightOn(factionColor, 0.75)
                else
                    _animatingGuids[ship] = nil
                end
            end
        end

        -- Wait 2 seconds before repeating (1 sec on, 1 sec off)
        local blinkWait = Time.time + 1.5
        while Time.time < blinkWait do
            coroutine.yield(0)
        end
    end

    -- Stop tracking all GUIDs from this animation
    for _, ship in ipairs(dyingShips) do
        _animatingGuids[ship] = nil
    end

    -- At this point, all dying ships have been handled. Destroy dice.
    for _, die in ipairs(_vuilraithParadigmAbilityDice) do
        local dieObject = getObjectFromGUID(die)
        if dieObject then
            destroyObject(dieObject)
        end
    end
    _vuilraithParadigmAbilityDice = {}

    return 1
end

function dimensionalanchor_rollDiceCoroutine()
    assert(_diceToBeRolled and type(_diceToBeRolled) == 'table')

    local waitToStart = Time.time + 1.5
    while Time.time < waitToStart do
        coroutine.yield(0)
    end

    for _, die in ipairs(_diceToBeRolled) do
        local dieObject = getObjectFromGUID(die)
        if dieObject then
            dieObject.setLock(false)
            dieObject.randomize()
            local rollDelay = Time.time + 0.25
            while Time.time < rollDelay do
                coroutine.yield(0)
            end
        end
    end

    return 1
end
function eventhorizon_rollDiceCoroutine()
    assert(_vuilraithParadigmAbilityDice and type(_vuilraithParadigmAbilityDice) == 'table')

    local waitToStart = Time.time + 1.5
    while Time.time < waitToStart do
        coroutine.yield(0)
    end

    for _, die in ipairs(_vuilraithParadigmAbilityDice) do
        local dieObject = getObjectFromGUID(die)
        if dieObject then
            dieObject.setLock(false)
            dieObject.randomize()
            local rollDelay = Time.time + 0.25
            while Time.time < rollDelay do
                coroutine.yield(0)
            end
        end
    end

    return 1
end

-- Hero
-- Faction: The Vuil'raith Cabal
-- Card Name: It Feeds on Carrion
-- Ability Name: Dimensional Anchor
-- Ability Text:
-- ACTION: Each other player rolls a die for each of their non-fighter ships
-- that are in or adjacent to a system that contains a dimensional tear; on
-- a 1-3, capture that unit. If this causes a player's ground forces or fighters
-- to be removed, also capture those units. Then, purge this card.
local function _carrionHeroAbility(owningObject, clickingColor) --Vuil'raith Hero
    if not _heroCardCanBeUsed(owningObject, clickingColor) then
        -- Function will print why card cannot be used
        return
    end

    table.insert(_carrionHeroAbilityOwningObjectQueue, owningObject)
    startLuaCoroutine(self, '_carrionHeroAbilityCoroutine')
end
local function _vuilraithParadigmAbility(owningObject, clickingColor)
    if not _paradigmCardCanBeUsed(owningObject, clickingColor) then
        -- Function will print why card cannot be used
        return
    end

    table.insert(_vuilraithParadigmAbilityOwningObjectQueue, owningObject)
    startLuaCoroutine(self, '_vuilraithParadigmAbilityCoroutine')
end

local function _replaceTitanSleeperToken(sleeperTokenObject, clickingColor, replacements)
    assert(type(sleeperTokenObject) == 'userdata' and type(clickingColor) == 'string' and type(replacements) == 'table')

    -- Can the clicking player replace the token?
    local canReplace = false
    local faction = fromColor(clickingColor) or {}
    for _, ability in ipairs(faction.abilities or {}) do
        if ability == 'Awaken' then
            canReplace = true
        end
    end
    if not canReplace then
        printToColor(clickingColor .. ' does not have the "Awaken" ability, ignoring replace', clickingColor, 'Red')
        return
    end

    printToAll('Replacing ' .. sleeperTokenObject.getName() .. ' with ' .. table.concat(replacements, ', '), 'Yellow')

    -- Find bags (set true to search for them, search replaces with the bag).
    local replacementNameToBagName = {}
    local bagNameToBag = {
        ['Titan Sleeper Tokens Bag'] = true,
        ['x1 Infantry Tokens Bag'] = true
    }
    for _, replacement in ipairs(replacements) do
        local bagName = clickingColor .. ' ' .. replacement
        replacementNameToBagName[replacement] = bagName
        bagNameToBag[bagName] = true
    end
    for _, object in ipairs(getAllObjects()) do
        local tag = object.tag
        local name = object.getName()
        if (tag == 'Bag' or tag == 'Infinite') and (bagNameToBag[name] == true) then
            bagNameToBag[name] = object
        end
    end

    -- Use infantry tokens if infanty bag is empty.
    if replacementNameToBagName['Infantry'] then
        local bagName = replacementNameToBagName['Infantry']
        local bag = bagNameToBag[bagName]
        if (not bag) or (bag == true) or (bag.getQuantity() == 0) then
            replacementNameToBagName['Infantry'] = 'x1 Infantry Tokens Bag'
        end
    end

    -- Verify unit availability.
    local takeFromBags = {}
    for i, replacement in ipairs(replacements) do
        local bagName = assert(replacementNameToBagName[replacement])
        local bag = bagNameToBag[bagName]
        if (not bag) or (bag == true) then
            printToAll('Warning: missing ' .. bagName .. ', aborting', 'Yellow')
            return
        elseif bag.tag == 'Bag' and bag.getQuantity() == 0 then
            printToAll('Warning: no ' .. replacement .. ' available, aborting', 'Yellow')
            return
        else
            table.insert(takeFromBags, bag)
        end
    end

    -- All units are available, proceed with replacment(s).
    for i, bag in ipairs(takeFromBags) do
        local p = sleeperTokenObject.getPosition()
        p.x = p.x + (i - 1) * 1.1
        p.y = p.y + 3
        bag.takeObject({
            position          = p,
            smooth            = true
        })
    end
    local sleeperTokensBag = assert(bagNameToBag['Titan Sleeper Tokens Bag'])
    sleeperTokensBag.putObject(sleeperTokenObject)
end

local _entityApolloAbilityOwningObjectQueue = {}
local _entityApolloAbilityDice = {}
function _entityApolloAbilityCoroutine()
    local owningObject = assert(table.remove(_entityApolloAbilityOwningObjectQueue))
    if #_entityApolloAbilityDice > 0 then
        printToAll('Remove previous ships before re-using Entity 4X4IC "Apollo".')
        return 1
    end

    --Find faction owning this hero ability (and it's color)
    local factionTokenName = false
    local factionColor = false
    for color, faction in pairs(allFactions(false)) do
        if faction.hero == owningObject.getName() then
            factionTokenName = faction.tokenName
            factionColor = color
            break
        end
    end
    assert(factionTokenName and factionColor, 'Entity 4X4IC "Apollo": Trying to invoke Hero Ability, but no faction with "Entity 4X4IC "Apollo"" is at the table.')
	
	--Find unit combat value for unit on the Hero Card
	local bbToOwningObject = {}
	local bounds = owningObject.getBounds()
	table.insert(bbToOwningObject, {
	min = {x = bounds.center.x - bounds.size.x / 2, z = bounds.center.z - bounds.size.z / 2},
	max = {x = bounds.center.x + bounds.size.x / 2, z = bounds.center.z + bounds.size.z / 2},
	})
	local catalystUnit = nil
	local diceThreshold = nil

    --Find the active system
	local activeSystem = _systemHelper.getActivatedSystem()
	 if not activeSystem then
        printToAll('Entity 4X4IC "Apollo": No Active System Detected. Won\'t use Hero Ability.')
        return 1
    end
	
	local activeSystemObject = getObjectFromGUID(activeSystem.guid)
    coroutine.yield(0)

    --Find hex of the active system
    local activeSystemToHex = _systemHelper.hexFromPosition(getObjectFromGUID(activeSystem.guid).getPosition())
	
	--Check for the arena
	local arenaObject = nil
    for _, obj in ipairs(getAllObjects()) do
        if obj.getName() == "TI4 Auto-fill MultiRoller Arena" then
            arenaObject = obj
            break
        end
    end
    --Find all units in the active system or arena
	local opponentUnitToHex = {}
    local unitByGuid = {}
	local fighterSet = {}
	local infantrySet = {}
    local allUnits = _unitHelper.getUnits()
    for _, unit in ipairs(allUnits) do
		local p = unit.position
        if unit.unitType ~= 'Infantry' and unit.unitType ~= 'Fighter' then --save fighters in infantry for to count methods
            if (unit.factionTokenName and unit.factionTokenName ~= factionTokenName) or (unit.color and unit.color ~= factionColor) then
                opponentUnitToHex[unit.guid] = unit.hex
                unitByGuid[unit.guid] = unit
				if arenaObject then
					local bounds = arenaObject.getBounds()
					local bb = {
					min = {x = bounds.center.x - bounds.size.x / 2, z = bounds.center.z - bounds.size.z / 2},
					max = {x = bounds.center.x + bounds.size.x / 2, z = bounds.center.z + bounds.size.z / 2}
					}
					if p.x >= bb.min.x and p.x <= bb.max.x and p.z >= bb.min.z and p.z <= bb.max.z then
						-- Treat as if this unit is in the active system
						opponentUnitToHex[unit.guid] = activeSystemToHex
						unitByGuid[unit.guid] = unit
					end
				end
            end
        elseif unit.unitType == 'Fighter' then
			if arenaObject then
				local bounds = arenaObject.getBounds()
				local bb = {
				min = {x = bounds.center.x - bounds.size.x / 2, z = bounds.center.z - bounds.size.z / 2},
				max = {x = bounds.center.x + bounds.size.x / 2, z = bounds.center.z + bounds.size.z / 2}
				}
				if p.x >= bb.min.x and p.x <= bb.max.x and p.z >= bb.min.z and p.z <= bb.max.z then
					-- Treat as if this unit is in the active system
					table.insert(fighterSet, unit)
				end
			end
			if unit.hex == activeSystemToHex then
				table.insert(fighterSet, unit)
			end
		elseif unit.unitType == 'Infantry' then
			if arenaObject then
				local bounds = arenaObject.getBounds()
				local bb = {
				min = {x = bounds.center.x - bounds.size.x / 2, z = bounds.center.z - bounds.size.z / 2},
				max = {x = bounds.center.x + bounds.size.x / 2, z = bounds.center.z + bounds.size.z / 2}
				}
				if p.x >= bb.min.x and p.x <= bb.max.x and p.z >= bb.min.z and p.z <= bb.max.z then
					-- Treat as if this unit is in the active system
					table.insert(infantrySet, unit)
				end
			end
			if unit.hex == activeSystemToHex then
				table.insert(infantrySet, unit)
			end
		end
		if not catalystUnit then
			for _, bbData in ipairs(bbToOwningObject) do
				local bb = bbData
				if p.x >= bb.min.x and p.x <= bb.max.x and p.z >= bb.min.z and p.z <= bb.max.z then
					catalystUnit = unit
				end
			end
		end
    end
	local fighterColorSet = _unitHelper.fillUnitColors(fighterSet)
	local infantryColorSet = _unitHelper.fillUnitColors(infantrySet)
	local opponentFighter = {}
	local opponentInfantry = {}
	local opponentInfantryToZones = {}
	local opponentInfantryToCount = {}
	local opponentFighterToCount = 0
	opponentInfantryToZones['Space Area'] = {}
	if activeSystem.planets then
		for _, planet in ipairs(activeSystem.planets) do
			opponentInfantryToZones[planet.name] = {}
		end
	end
	for _, unit in ipairs(fighterColorSet) do
		if unit.color ~= factionColor then
			table.insert(opponentFighter, unit)
		end
	end
	for _, unit in ipairs(infantryColorSet) do
		if unit.color ~= factionColor then
			table.insert(opponentInfantry, unit)
		end
	end
	for _, unit in ipairs(opponentInfantry) do
		local p = unit.position
		if arenaObject then
					local bounds = arenaObject.getBounds()
					local bb = {
					min = {x = bounds.center.x - bounds.size.x / 2, z = bounds.center.z - bounds.size.z / 2},
					max = {x = bounds.center.x + bounds.size.x / 2, z = bounds.center.z + bounds.size.z / 2}
					}
					if p.x >= bb.min.x and p.x <= bb.max.x and p.z >= bb.min.z and p.z <= bb.max.z then
						p = activeSystemObject.positionToWorld(arenaObject.positionToLocal(p))
					end
		end
		local infantryPlanet = _systemHelper.planetFromPosition({ systemGuid = activeSystem.guid, position = p, exact = true })
		if infantryPlanet then
			table.insert(opponentInfantryToZones[infantryPlanet.name], unit)
		else
			table.insert(opponentInfantryToZones['Space Area'], unit)
		end
	end
	for zone, unitSet in pairs(opponentInfantryToZones) do
		opponentInfantryToCount[zone] = 0
		for _, unit in ipairs(unitSet) do
			opponentInfantryToCount[zone] = opponentInfantryToCount[zone] + unit.count
		end
	end
	for _, unit in ipairs(opponentFighter) do
		opponentFighterToCount = opponentFighterToCount + unit.count
	end
	if not catalystUnit then
		printToAll('Entity 4X4IC "Apollo": Cannot find galvanized unit. Is it on this card? Won\'t use Hero Ability.')
		return 1
	else
		local colorToUnitOverrides = _unitHelper.getColorToUnitOverrides()
		local unitOverrides = colorToUnitOverrides[catalystUnit.color] or {}
        local unitAttrs = _unitHelper.getUnitAttributes(unitOverrides)
		local catalystUnitToAttrs = unitAttrs[catalystUnit.unitType]
		if catalystUnitToAttrs and catalystUnitToAttrs.spaceCombat and catalystUnitToAttrs.spaceCombat.hit then
			diceThreshold = catalystUnitToAttrs.spaceCombat.hit
		elseif catalystUnitToAttrs and catalystUnitToAttrs.groundCombat and catalystUnitToAttrs.groundCombat.hit then
			diceThreshold = catalystUnitToAttrs.groundCombat.hit
		else
			printToAll('Entity 4X4IC "Apollo": Cannot find galavnized units combat value. Won\'t use Hero Ability.')
		end
		if diceThreshold and catalystUnitToAttrs and catalystUnitToAttrs.groundCombat and catalystUnitToAttrs.groundCombat.hit and diceThreshold < catalystUnitToAttrs.groundCombat.hit then
			diceThreshold = catalystUnitToAttrs.groundCombat.hit
		end
	end

    local anchoredShipsCount = 0
    local systemToAnchoredShips = {}
    for shipGuid, hex in pairs(opponentUnitToHex) do
        local system = activeSystem
        if activeSystemToHex == hex then
            local systemShips = systemToAnchoredShips[system]
            if not systemShips then
                systemShips = {}
                systemToAnchoredShips[system] = systemShips
            end

            table.insert(systemShips, shipGuid)
            anchoredShipsCount = anchoredShipsCount + 1
        end
    end

    if anchoredShipsCount == 0 then
        printToAll('Entity 4X4IC "Apollo": No units found in the active system. Won\'t use Hero Ability.')
        return 1
    end

    -- Safe to commit to acting at this point, so purge the Hero card.
    if owningObject.tag == 'Card' then
        purgeCard(owningObject)
    end

    -- Function spawns dice for each ship, sets a dice cleanup on a 2 minute timeout,
    -- and prints a guide for the dice color for auditability.
    local function _prepareDice(systemToAnchoredShips)
        -- Data and methods for dice handling copied from multiroller.

        local dieType = "Die_10"
        local removalDelay = 5
        local radialOffset = 1.2
        local heightOffset = 5
        local dieSize = 1

        --Finds a position, rotated around the Y axis, using distance you want + angle
        --oPos is object pos, oRot=object rotation, distance = how far, angle = angle in degrees
        local function _findGlobalPosWithLocalDirection(spawn_object, angle)
            local object, distance = spawn_object, radialOffset * self.getScale().x
            local oPos, oRot = object.getPosition(), object.getRotation()
            local posX = oPos.x + math.sin( math.rad(angle+oRot.y) ) * distance
            local posY = oPos.y + heightOffset
            local posZ = oPos.z + math.cos( math.rad(angle+oRot.y) ) * distance
            return {x=posX, y=posY, z=posZ}
        end

        --Gets a random rotation vector
        local function _randomRotation()
            --Credit for this function goes to Revinor (forums)
            --Get 3 random numbers
            local u1 = math.random();
            local u2 = math.random();
            local u3 = math.random();
            --Convert them into quats to avoid gimbal lock
            local u1sqrt = math.sqrt(u1);
            local u1m1sqrt = math.sqrt(1-u1);
            local qx = u1m1sqrt *math.sin(2*math.pi*u2);
            local qy = u1m1sqrt *math.cos(2*math.pi*u2);
            local qz = u1sqrt *math.sin(2*math.pi*u3);
            local qw = u1sqrt *math.cos(2*math.pi*u3);
            --Apply rotation
            local ysqr = qy * qy;
            local t0 = -2.0 * (ysqr + qz * qz) + 1.0;
            local t1 = 2.0 * (qx * qy - qw * qz);
            local t2 = -2.0 * (qx * qz + qw * qy);
            local t3 = 2.0 * (qy * qz - qw * qx);
            local t4 = -2.0 * (qx * qx + ysqr) + 1.0;
            --Correct
            if t2 > 1.0 then t2 = 1.0 end
            if t2 < -1.0 then ts = -1.0 end
            --Convert back to X/Y/Z
            local xr = math.asin(t2);
            local yr = math.atan2(t3, t4);
            local zr = math.atan2(t1, t0);
            --Return result
            return {math.deg(xr),math.deg(yr),math.deg(zr)}
        end

        -- Use different color dice for manual auditability; copy from Multiroller
        local unitTypeToDiceColor = {
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

        local diceToShip = {}
        local unitTypesUsed = {}
        _entityApolloAbilityDice = {}

        -- Spawn a die for each ship, around the system tile the ship is on.
        for system, ships in pairs(systemToAnchoredShips) do
            local shipCount = #ships
            local angleStep = (360 / shipCount)

            local systemObject = getObjectFromGUID(system.guid)

            for i, ship in ipairs(ships) do
                local shipAttrs = unitByGuid[ship]

                local dieObject = spawnObject({
                    type=dieType,
                    position = _findGlobalPosWithLocalDirection(systemObject, angleStep*(i-1)),
                    rotation = _randomRotation(), scale={dieSize,dieSize,dieSize},
                    callback_function = function(obj) --GUID is not available right away
                        diceToShip[obj.getGUID()] = ship
                        table.insert(_entityApolloAbilityDice, obj.getGUID())
                     end,
                })
                dieObject.setLock(true)
                dieObject.setColorTint(stringColorToRGB(unitTypeToDiceColor[shipAttrs.unitType]))

                unitTypesUsed[shipAttrs.unitType] = true
            end
        end

        -- Print guide showing the dice color for each ship.
        printToAll('DICE COLOR GUIDE')
        for unitType, color in pairs(unitTypeToDiceColor) do
            if unitTypesUsed[unitType] then
                printToAll('* ' .. unitType .. ': ' .. color)
            end
        end

        -- Remove dice from board no matter what after 2 minutes
        local function destroyDice()
            for _, die in ipairs(_entityApolloAbilityDice) do
                local dieObject = getObjectFromGUID(die)
                if dieObject then
                    destroyObject(dieObject)
                end
            end
            _entityApolloAbilityDice = {}
        end
        Wait.time(destroyDice, 120)

        return diceToShip
    end

    -- For each system, do rolls. Track results, print them by system+unitType.
    -- eg. 'Bereg / Lirta IV: Cruiser has 1 capture (2#, 4, 9); Dreadnought has 0 captures (6).'
    local diceToShip = _prepareDice(systemToAnchoredShips)

    -- Wait for all dice to spawn and receive a GUID
    local diceToShipCount = 0
    while diceToShipCount < anchoredShipsCount do
        coroutine.yield(0)

        diceToShipCount = 0
        for die, _ in pairs(diceToShip) do
            diceToShipCount = diceToShipCount + 1
        end
    end

    -- Start rolling dice.
    -- Separate coroutine, so 'self' can animate hexes while the dice are being rolled.
    startLuaCoroutine(self, 'entityApollo_rollDiceCoroutine')

    -- Function checks if dice are all still, and if they are maps their values to the ship they rolled for.
    -- If dice are NOT still, just return an object with "waitingOnResults = true"
    local function _processRollResults(diceToShip)
        -- Wait for all dice to be settled
        local waitingOnResults = false
        for die, _ in pairs(diceToShip) do
            local dieObject = getObjectFromGUID(die)
            if dieObject and not dieObject.resting then
                waitingOnResults = true
                break
            end
        end

        -- ALWAYS report a value even if dice aren't resting, in case of timeout.
        local shipToResult = {}
        for die, ship in pairs(diceToShip) do
            local dieObject = getObjectFromGUID(die)
            shipToResult[ship] = dieObject and dieObject.getValue() or 0
        end

        return { waitingOnResults = waitingOnResults, shipToResult = shipToResult }
    end

    -- For blinking hexes.
    local function _setHexBlinkMode(systemToAnchoredShips, factionColor, blinkDuration)
		for system, _ in pairs(systemToAnchoredShips) do
			local systemObject = getObjectFromGUID(system.guid)
			if systemObject then
				systemObject.highlightOn(factionColor, blinkDuration)
			end
		end
	end

    -- Check for results,
    -- and trigger system tile highlighting until results are ready
    local rollResults = { waitingOnResults = true }
    local rollTimeout = Time.time + 10
    local rollMinimumWait = Time.time + 3
    local blinkTransitionTime = 0
    while (rollResults.waitingOnResults or Time.time < rollMinimumWait) and Time.time < rollTimeout do
        blinkTransitionTime = Time.time + 1.5
        _setHexBlinkMode(systemToAnchoredShips, factionColor, 1)

        while blinkTransitionTime > Time.time do
            coroutine.yield(0)
        end

        rollResults = _processRollResults(diceToShip)
        coroutine.yield(0)
    end
	for system, _ in pairs(systemToAnchoredShips) do
        local systemObject = getObjectFromGUID(system.guid)
        if systemObject then
            systemObject.highlightOff()
        end
    end

    -- Get results
    local shipToResult = rollResults.shipToResult

    -- Print results
    for system, ships in pairs(systemToAnchoredShips) do
        local unitTypeToResultRolls = {}

        for _, ship in ipairs(ships) do
            local shipAttrs = assert(unitByGuid[ship])
            local descriptiveUnitType = shipAttrs.unitType
            if shipAttrs.factionTokenName then
                descriptiveUnitType = shipAttrs.factionTokenName .. '\'s ' .. descriptiveUnitType
            elseif shipAttrs.color then
                descriptiveUnitType = shipAttrs.color .. ' ' .. descriptiveUnitType
            end

            local resultsForType = unitTypeToResultRolls[descriptiveUnitType]
            if not resultsForType then
                resultsForType = {}
                unitTypeToResultRolls[descriptiveUnitType] = resultsForType
            end

            table.insert(resultsForType, assert(shipToResult[ship]))
        end

        printToAll('Results for ' .. system.string .. ':')
        for unitType, results in pairs(unitTypeToResultRolls) do
            local resultString = ''
            local first = true
            for _, result in ipairs(results) do
                if not first then
                    resultString  = resultString .. ', '
                end

                resultString = resultString .. result
                if result >= diceThreshold then
                    resultString = resultString .. '#'
                end

                first = false
            end

            printToAll('* ' .. unitType .. ': ' .. resultString)
        end
    end
	local function rollSmallDice(unitType, zoneName, count, activeSystemObject)
		if count <= 0 then return end

		local dieType = "Die_10"
		local smallScale = {x = 0.35, y = 0.35, z = 0.35}
		local heightOffset = 3
		local radialOffset = 2.5
		local basePos = activeSystemObject.getPosition() + vector(0, heightOffset, 0)
		local angleStep = 360 / math.max(count, 6)
		local dice = {}
		local results = {}

		-- Spawn dice in a fan around the system, smaller scale
		for i = 1, count do
			local angle = math.rad(angleStep * (i - 1))
			local offset = vector(math.cos(angle) * radialOffset, 0, math.sin(angle) * radialOffset)
			local spawnPos = basePos + offset

			local die = spawnObject({
				type = dieType,
				position = spawnPos,
				rotation = {x = 0, y = math.random(0, 360), z = 0},
				scale = smallScale,
			})

			die.randomize()
			table.insert(dice, die)
		end

		-- Wait for dice to settle, collect values, print results, cleanup
		Wait.time(function()
			for _, die in ipairs(dice) do
				if die and die.getValue then
					table.insert(results, die.getValue())
				end
			end

			-- Sort by roll order (optional: keeps visual order)
			local resultStr = ""
			local first = true
			local destroyedCount = 0
			for _, value in ipairs(results) do
				if not first then resultStr = resultStr .. ", " end
				if value >= diceThreshold then
					resultStr = resultStr .. tostring(value) .. "#"
					destroyedCount = destroyedCount + 1
				else
					resultStr = resultStr .. tostring(value)
				end
				first = false
			end
			
			local inOn = 'on'
			if zoneName == 'Space Area' then
				inOn = 'in'
			end
			printToAll(zoneName .. " " .. unitType .. ": " .. resultStr)
			printToAll("Destroyed " .. tostring(destroyedCount) .. " " .. unitType .. " " .. inOn .. " " .. zoneName, {r=1, g=1, b=0})
			
			-- Remove dice after a short delay
			Wait.time(function()
				for _, die in ipairs(dice) do
					if die and die.getGUID() then
						destroyObject(die)
					end
				end
			end, 5)
		end, 2)
	end

	-- Infantry rolls per zone
	for zoneName, count in pairs(opponentInfantryToCount) do
		if count > 0 then
			rollSmallDice("Infantry", zoneName, count, activeSystemObject)
		end
	end

	-- Fighter rolls (all counted together)
	if opponentFighterToCount > 0 then
		rollSmallDice("Fighter", "Space Area", opponentFighterToCount, activeSystemObject)
	end

    -- Create list of dying ships.
    -- Only includes ships whose roll was greater than the diceThreshold (failing)
    local dyingShips = {}
    for ship, result in pairs(shipToResult) do
        if result >= diceThreshold then
            local shipObject = getObjectFromGUID(ship)
            if shipObject then
                table.insert(dyingShips, ship)
                _animatingGuids[ship] = true
            end
        end
    end

    -- Loop and highlight dead ships until they're removed from their hex.
    local anchoredUnitsUnmoved = true
    local anchoredUnitsTimeout = Time.time + 120
    while Time.time < anchoredUnitsTimeout and anchoredUnitsUnmoved do
        anchoredUnitsUnmoved = false

        local currentTileToDeathTile = {}
        local shipStateToPosition = {}

        for _, ship in ipairs(dyingShips) do
            if _animatingGuids[ship] then
                local shipObject = getObjectFromGUID(ship)
                if shipObject then
                    anchoredUnitsUnmoved = true
                    shipObject.highlightOn(factionColor, 0.75)
                else
                    _animatingGuids[ship] = nil
                end
            end
        end

        -- Wait 2 seconds before repeating (1 sec on, 1 sec off)
        local blinkWait = Time.time + 1.5
        while Time.time < blinkWait do
            coroutine.yield(0)
        end
    end

    -- Stop tracking all GUIDs from this animation
    for _, ship in ipairs(dyingShips) do
        _animatingGuids[ship] = nil
    end

    -- At this point, all dying ships have been handled. Destroy dice.
    for _, die in ipairs(_entityApolloAbilityDice) do
        local dieObject = getObjectFromGUID(die)
        if dieObject then
            destroyObject(dieObject)
        end
    end
    _entityApolloAbilityDice = {}

    return 1
end

function entityApollo_rollDiceCoroutine()
    assert(_entityApolloAbilityDice and type(_entityApolloAbilityDice) == 'table')

    local waitToStart = Time.time + 1.5
    while Time.time < waitToStart do
        coroutine.yield(0)
    end

    for _, die in ipairs(_entityApolloAbilityDice) do
        local dieObject = getObjectFromGUID(die)
        if dieObject then
            dieObject.setLock(false)
            dieObject.randomize()
            local rollDelay = Time.time + 0.25
            while Time.time < rollDelay do
                coroutine.yield(0)
            end
        end
    end

    return 1
end

local _bastionParadigmAbilityOwningObjectQueue = {}
local _bastionParadigmAbilityDice = {}
function _bastionParadigmAbilityCoroutine()
    local owningObject = assert(table.remove(_bastionParadigmAbilityOwningObjectQueue))
    if #_bastionParadigmAbilityDice > 0 then
        printToAll('Remove previous ships before re-using Intelligence Unshackeled.')
        return 1
    end

    --Find faction owning this hero ability (and it's color)
    local factionColor = _zoneHelper.zoneFromPosition(owningObject.getPosition())
    local factionTokenName = false
    if factionColor then
		factionTokenName = fromColor(factionColor).tokenName
	end
    assert(factionTokenName and factionColor, 'Intelligence Unshackeled: Trying to invoke Paradigm Ability, but no faction with "Intelligence Unshackeled" is at the table.')
	
	--Find unit combat value for unit on the Hero Card
	local bbToOwningObject = {}
	local bounds = owningObject.getBounds()
	table.insert(bbToOwningObject, {
	min = {x = bounds.center.x - bounds.size.x / 2, z = bounds.center.z - bounds.size.z / 2},
	max = {x = bounds.center.x + bounds.size.x / 2, z = bounds.center.z + bounds.size.z / 2},
	})
	local catalystUnit = nil
	local diceThreshold = nil

    --Find the active system
	local activeSystem = _systemHelper.getActivatedSystem()
	if not activeSystem then
        printToAll('Intelligence Unshackeled: No Active System Detected. Won\'t use Hero Ability.')
        return 1
    end

	local activeSystemObject = getObjectFromGUID(activeSystem.guid)
    coroutine.yield(0)
    --Find hex of the active system
    local activeSystemToHex = _systemHelper.hexFromPosition(getObjectFromGUID(activeSystem.guid).getPosition())
	
	--Check for the arena
	local arenaObject = nil
    for _, obj in ipairs(getAllObjects()) do
        if obj.getName() == "TI4 Auto-fill MultiRoller Arena" then
            arenaObject = obj
            break
        end
    end
    --Find all units in the active system or arena
	local opponentUnitToHex = {}
    local unitByGuid = {}
	local fighterSet = {}
	local infantrySet = {}
    local allUnits = _unitHelper.getUnits()
    for _, unit in ipairs(allUnits) do
		local p = unit.position
        if unit.unitType ~= 'Infantry' and unit.unitType ~= 'Fighter' then --save fighters in infantry for to count methods
            if (unit.factionTokenName and unit.factionTokenName ~= factionTokenName) or (unit.color and unit.color ~= factionColor) then
                opponentUnitToHex[unit.guid] = unit.hex
                unitByGuid[unit.guid] = unit
				if arenaObject then
					local bounds = arenaObject.getBounds()
					local bb = {
					min = {x = bounds.center.x - bounds.size.x / 2, z = bounds.center.z - bounds.size.z / 2},
					max = {x = bounds.center.x + bounds.size.x / 2, z = bounds.center.z + bounds.size.z / 2}
					}
					if p.x >= bb.min.x and p.x <= bb.max.x and p.z >= bb.min.z and p.z <= bb.max.z then
						-- Treat as if this unit is in the active system
						opponentUnitToHex[unit.guid] = activeSystemToHex
						unitByGuid[unit.guid] = unit
					end
				end
            end
        elseif unit.unitType == 'Fighter' then
			if arenaObject then
				local bounds = arenaObject.getBounds()
				local bb = {
				min = {x = bounds.center.x - bounds.size.x / 2, z = bounds.center.z - bounds.size.z / 2},
				max = {x = bounds.center.x + bounds.size.x / 2, z = bounds.center.z + bounds.size.z / 2}
				}
				if p.x >= bb.min.x and p.x <= bb.max.x and p.z >= bb.min.z and p.z <= bb.max.z then
					-- Treat as if this unit is in the active system
					table.insert(fighterSet, unit)
				end
			end
			if unit.hex == activeSystemToHex then
				table.insert(fighterSet, unit)
			end
		elseif unit.unitType == 'Infantry' then
			if arenaObject then
				local bounds = arenaObject.getBounds()
				local bb = {
				min = {x = bounds.center.x - bounds.size.x / 2, z = bounds.center.z - bounds.size.z / 2},
				max = {x = bounds.center.x + bounds.size.x / 2, z = bounds.center.z + bounds.size.z / 2}
				}
				if p.x >= bb.min.x and p.x <= bb.max.x and p.z >= bb.min.z and p.z <= bb.max.z then
					-- Treat as if this unit is in the active system
					table.insert(infantrySet, unit)
				end
			end
			if unit.hex == activeSystemToHex then
				table.insert(infantrySet, unit)
			end
		end
		if not catalystUnit then
			for _, bbData in ipairs(bbToOwningObject) do
				local bb = bbData
				if p.x >= bb.min.x and p.x <= bb.max.x and p.z >= bb.min.z and p.z <= bb.max.z then
					catalystUnit = unit
				end
			end
		end
    end
	local fighterColorSet = _unitHelper.fillUnitColors(fighterSet)
	local infantryColorSet = _unitHelper.fillUnitColors(infantrySet)
	local opponentFighter = {}
	local opponentInfantry = {}
	local opponentInfantryToZones = {}
	local opponentInfantryToCount = {}
	local opponentFighterToCount = 0
	opponentInfantryToZones['Space Area'] = {}
	if activeSystem.planets then
		for _, planet in ipairs(activeSystem.planets) do
			opponentInfantryToZones[planet.name] = {}
		end
	end
	for _, unit in ipairs(fighterColorSet) do
		if unit.color ~= factionColor then
			table.insert(opponentFighter, unit)
		end
	end
	for _, unit in ipairs(infantryColorSet) do
		if unit.color ~= factionColor then
			table.insert(opponentInfantry, unit)
		end
	end
	for _, unit in ipairs(opponentInfantry) do
		local p = unit.position
		if arenaObject then
					local bounds = arenaObject.getBounds()
					local bb = {
					min = {x = bounds.center.x - bounds.size.x / 2, z = bounds.center.z - bounds.size.z / 2},
					max = {x = bounds.center.x + bounds.size.x / 2, z = bounds.center.z + bounds.size.z / 2}
					}
					if p.x >= bb.min.x and p.x <= bb.max.x and p.z >= bb.min.z and p.z <= bb.max.z then
						p = activeSystemObject.positionToWorld(arenaObject.positionToLocal(p))
					end
		end
		local infantryPlanet = _systemHelper.planetFromPosition({ systemGuid = activeSystem.guid, position = p, exact = true })
		if infantryPlanet then
			table.insert(opponentInfantryToZones[infantryPlanet.name], unit)
		else
			table.insert(opponentInfantryToZones['Space Area'], unit)
		end
	end
	for zone, unitSet in pairs(opponentInfantryToZones) do
		opponentInfantryToCount[zone] = 0
		for _, unit in ipairs(unitSet) do
			opponentInfantryToCount[zone] = opponentInfantryToCount[zone] + unit.count
		end
	end
	for _, unit in ipairs(opponentFighter) do
		opponentFighterToCount = opponentFighterToCount + unit.count
	end
	if not catalystUnit then
		printToAll('Intelligence Unshackeled: Cannot find catalyst unit. Is it on this card? Won\'t use Paradigm Ability.')
		return 1
	else
		local colorToUnitOverrides = _unitHelper.getColorToUnitOverrides()
		local unitOverrides = colorToUnitOverrides[catalystUnit.color] or {}
        local unitAttrs = _unitHelper.getUnitAttributes(unitOverrides)
		local catalystUnitToAttrs = unitAttrs[catalystUnit.unitType]
		if catalystUnitToAttrs and catalystUnitToAttrs.spaceCombat and catalystUnitToAttrs.spaceCombat.hit then
			diceThreshold = catalystUnitToAttrs.spaceCombat.hit
		elseif catalystUnitToAttrs and catalystUnitToAttrs.groundCombat and catalystUnitToAttrs.groundCombat.hit then
			diceThreshold = catalystUnitToAttrs.groundCombat.hit
		else
			printToAll('Intelligence Unshackeled: Cannot find catalyst units combat value. Won\'t use Paradigm Ability.')
		end
		if diceThreshold and catalystUnitToAttrs and catalystUnitToAttrs.groundCombat and catalystUnitToAttrs.groundCombat.hit and diceThreshold < catalystUnitToAttrs.groundCombat.hit then
			diceThreshold = catalystUnitToAttrs.groundCombat.hit
		end
	end

    local anchoredShipsCount = 0
    local systemToAnchoredShips = {}
    for shipGuid, hex in pairs(opponentUnitToHex) do
        local system = activeSystem
        if activeSystemToHex == hex then
            local systemShips = systemToAnchoredShips[system]
            if not systemShips then
                systemShips = {}
                systemToAnchoredShips[system] = systemShips
            end

            table.insert(systemShips, shipGuid)
            anchoredShipsCount = anchoredShipsCount + 1
        end
    end

    if anchoredShipsCount == 0 then
        printToAll('Intelligence Unshackeled: No units found in the active system. Won\'t use Paradigm Ability.')
        return 1
    end

    -- Safe to commit to acting at this point, so purge the Hero card.
    if owningObject.tag == 'Card' then
        purgeCard(owningObject)
    end

    -- Function spawns dice for each ship, sets a dice cleanup on a 2 minute timeout,
    -- and prints a guide for the dice color for auditability.
    local function _prepareDice(systemToAnchoredShips)
        -- Data and methods for dice handling copied from multiroller.

        local dieType = "Die_10"
        local removalDelay = 5
        local radialOffset = 1.2
        local heightOffset = 5
        local dieSize = 1

        --Finds a position, rotated around the Y axis, using distance you want + angle
        --oPos is object pos, oRot=object rotation, distance = how far, angle = angle in degrees
        local function _findGlobalPosWithLocalDirection(spawn_object, angle)
            local object, distance = spawn_object, radialOffset * self.getScale().x
            local oPos, oRot = object.getPosition(), object.getRotation()
            local posX = oPos.x + math.sin( math.rad(angle+oRot.y) ) * distance
            local posY = oPos.y + heightOffset
            local posZ = oPos.z + math.cos( math.rad(angle+oRot.y) ) * distance
            return {x=posX, y=posY, z=posZ}
        end

        --Gets a random rotation vector
        local function _randomRotation()
            --Credit for this function goes to Revinor (forums)
            --Get 3 random numbers
            local u1 = math.random();
            local u2 = math.random();
            local u3 = math.random();
            --Convert them into quats to avoid gimbal lock
            local u1sqrt = math.sqrt(u1);
            local u1m1sqrt = math.sqrt(1-u1);
            local qx = u1m1sqrt *math.sin(2*math.pi*u2);
            local qy = u1m1sqrt *math.cos(2*math.pi*u2);
            local qz = u1sqrt *math.sin(2*math.pi*u3);
            local qw = u1sqrt *math.cos(2*math.pi*u3);
            --Apply rotation
            local ysqr = qy * qy;
            local t0 = -2.0 * (ysqr + qz * qz) + 1.0;
            local t1 = 2.0 * (qx * qy - qw * qz);
            local t2 = -2.0 * (qx * qz + qw * qy);
            local t3 = 2.0 * (qy * qz - qw * qx);
            local t4 = -2.0 * (qx * qx + ysqr) + 1.0;
            --Correct
            if t2 > 1.0 then t2 = 1.0 end
            if t2 < -1.0 then ts = -1.0 end
            --Convert back to X/Y/Z
            local xr = math.asin(t2);
            local yr = math.atan2(t3, t4);
            local zr = math.atan2(t1, t0);
            --Return result
            return {math.deg(xr),math.deg(yr),math.deg(zr)}
        end

        -- Use different color dice for manual auditability; copy from Multiroller
        local unitTypeToDiceColor = {
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

        local diceToShip = {}
        local unitTypesUsed = {}
        _bastionParadigmAbilityDice = {}

        -- Spawn a die for each ship, around the system tile the ship is on.
        for system, ships in pairs(systemToAnchoredShips) do
            local shipCount = #ships
            local angleStep = (360 / shipCount)

            local systemObject = getObjectFromGUID(system.guid)

            for i, ship in ipairs(ships) do
                local shipAttrs = unitByGuid[ship]

                local dieObject = spawnObject({
                    type=dieType,
                    position = _findGlobalPosWithLocalDirection(systemObject, angleStep*(i-1)),
                    rotation = _randomRotation(), scale={dieSize,dieSize,dieSize},
                    callback_function = function(obj) --GUID is not available right away
                        diceToShip[obj.getGUID()] = ship
                        table.insert(_bastionParadigmAbilityDice, obj.getGUID())
                     end,
                })
                dieObject.setLock(true)
                dieObject.setColorTint(stringColorToRGB(unitTypeToDiceColor[shipAttrs.unitType]))

                unitTypesUsed[shipAttrs.unitType] = true
            end
        end

        -- Print guide showing the dice color for each ship.
        printToAll('DICE COLOR GUIDE')
        for unitType, color in pairs(unitTypeToDiceColor) do
            if unitTypesUsed[unitType] then
                printToAll('* ' .. unitType .. ': ' .. color)
            end
        end

        -- Remove dice from board no matter what after 2 minutes
        local function destroyDice()
            for _, die in ipairs(_bastionParadigmAbilityDice) do
                local dieObject = getObjectFromGUID(die)
                if dieObject then
                    destroyObject(dieObject)
                end
            end
            _bastionParadigmAbilityDice = {}
        end
        Wait.time(destroyDice, 120)

        return diceToShip
    end

    -- For each system, do rolls. Track results, print them by system+unitType.
    -- eg. 'Bereg / Lirta IV: Cruiser has 1 capture (2#, 4, 9); Dreadnought has 0 captures (6).'
    local diceToShip = _prepareDice(systemToAnchoredShips)

    -- Wait for all dice to spawn and receive a GUID
    local diceToShipCount = 0
    while diceToShipCount < anchoredShipsCount do
        coroutine.yield(0)

        diceToShipCount = 0
        for die, _ in pairs(diceToShip) do
            diceToShipCount = diceToShipCount + 1
        end
    end

    -- Start rolling dice.
    -- Separate coroutine, so 'self' can animate hexes while the dice are being rolled.
    startLuaCoroutine(self, 'bastionParadigm_rollDiceCoroutine')

    -- Function checks if dice are all still, and if they are maps their values to the ship they rolled for.
    -- If dice are NOT still, just return an object with "waitingOnResults = true"
    local function _processRollResults(diceToShip)
        -- Wait for all dice to be settled
        local waitingOnResults = false
        for die, _ in pairs(diceToShip) do
            local dieObject = getObjectFromGUID(die)
            if dieObject and not dieObject.resting then
                waitingOnResults = true
                break
            end
        end

        -- ALWAYS report a value even if dice aren't resting, in case of timeout.
        local shipToResult = {}
        for die, ship in pairs(diceToShip) do
            local dieObject = getObjectFromGUID(die)
            shipToResult[ship] = dieObject and dieObject.getValue() or 0
        end

        return { waitingOnResults = waitingOnResults, shipToResult = shipToResult }
    end

    -- For blinking hexes.
    local function _setHexBlinkMode(systemToAnchoredShips, factionColor, blinkDuration)
		for system, _ in pairs(systemToAnchoredShips) do
			local systemObject = getObjectFromGUID(system.guid)
			if systemObject then
				systemObject.highlightOn(factionColor, blinkDuration)
			end
		end
	end

    -- Check for results,
    -- and trigger system tile highlighting until results are ready
    local rollResults = { waitingOnResults = true }
    local rollTimeout = Time.time + 10
    local rollMinimumWait = Time.time + 3
    local blinkTransitionTime = 0
    while (rollResults.waitingOnResults or Time.time < rollMinimumWait) and Time.time < rollTimeout do
        blinkTransitionTime = Time.time + 1.5
        _setHexBlinkMode(systemToAnchoredShips, factionColor, 1)

        while blinkTransitionTime > Time.time do
            coroutine.yield(0)
        end

        rollResults = _processRollResults(diceToShip)
        coroutine.yield(0)
    end
	for system, _ in pairs(systemToAnchoredShips) do
        local systemObject = getObjectFromGUID(system.guid)
        if systemObject then
            systemObject.highlightOff()
        end
    end

    -- Get results
    local shipToResult = rollResults.shipToResult

    -- Print results
    for system, ships in pairs(systemToAnchoredShips) do
        local unitTypeToResultRolls = {}

        for _, ship in ipairs(ships) do
            local shipAttrs = assert(unitByGuid[ship])
            local descriptiveUnitType = shipAttrs.unitType
            if shipAttrs.factionTokenName then
                descriptiveUnitType = shipAttrs.factionTokenName .. '\'s ' .. descriptiveUnitType
            elseif shipAttrs.color then
                descriptiveUnitType = shipAttrs.color .. ' ' .. descriptiveUnitType
            end

            local resultsForType = unitTypeToResultRolls[descriptiveUnitType]
            if not resultsForType then
                resultsForType = {}
                unitTypeToResultRolls[descriptiveUnitType] = resultsForType
            end

            table.insert(resultsForType, assert(shipToResult[ship]))
        end

        printToAll('Results for ' .. system.string .. ':')
        for unitType, results in pairs(unitTypeToResultRolls) do
            local resultString = ''
            local first = true
            for _, result in ipairs(results) do
                if not first then
                    resultString  = resultString .. ', '
                end

                resultString = resultString .. result
                if result >= diceThreshold then
                    resultString = resultString .. '#'
                end

                first = false
            end

            printToAll('* ' .. unitType .. ': ' .. resultString)
        end
    end
	local function rollSmallDice(unitType, zoneName, count, activeSystemObject)
		if count <= 0 then return end

		local dieType = "Die_10"
		local smallScale = {x = 0.35, y = 0.35, z = 0.35}
		local heightOffset = 3
		local radialOffset = 2.5
		local basePos = activeSystemObject.getPosition() + vector(0, heightOffset, 0)
		local angleStep = 360 / math.max(count, 6)
		local dice = {}
		local results = {}

		-- Spawn dice in a fan around the system, smaller scale
		for i = 1, count do
			local angle = math.rad(angleStep * (i - 1))
			local offset = vector(math.cos(angle) * radialOffset, 0, math.sin(angle) * radialOffset)
			local spawnPos = basePos + offset

			local die = spawnObject({
				type = dieType,
				position = spawnPos,
				rotation = {x = 0, y = math.random(0, 360), z = 0},
				scale = smallScale,
			})

			die.randomize()
			table.insert(dice, die)
		end

		-- Wait for dice to settle, collect values, print results, cleanup
		Wait.time(function()
			for _, die in ipairs(dice) do
				if die and die.getValue then
					table.insert(results, die.getValue())
				end
			end

			-- Sort by roll order (optional: keeps visual order)
			local resultStr = ""
			local first = true
			local destroyedCount = 0
			for _, value in ipairs(results) do
				if not first then resultStr = resultStr .. ", " end
				if value >= diceThreshold then
					resultStr = resultStr .. tostring(value) .. "#"
					destroyedCount = destroyedCount + 1
				else
					resultStr = resultStr .. tostring(value)
				end
				first = false
			end
			
			local inOn = 'on'
			if zoneName == 'Space Area' then
				inOn = 'in'
			end
			printToAll(zoneName .. " " .. unitType .. ": " .. resultStr)
			printToAll("Destroyed " .. tostring(destroyedCount) .. " " .. unitType .. " " .. inOn .. " " .. zoneName, {r=1, g=1, b=0})
			
			-- Remove dice after a short delay
			Wait.time(function()
				for _, die in ipairs(dice) do
					if die and die.getGUID() then
						destroyObject(die)
					end
				end
			end, 5)
		end, 2)
	end

	-- Infantry rolls per zone
	for zoneName, count in pairs(opponentInfantryToCount) do
		if count > 0 then
			rollSmallDice("Infantry", zoneName, count, activeSystemObject)
		end
	end

	-- Fighter rolls (all counted together)
	if opponentFighterToCount > 0 then
		rollSmallDice("Fighter", "Space Area", opponentFighterToCount, activeSystemObject)
	end

    -- Create list of dying ships.
    -- Only includes ships whose roll was greater than the diceThreshold (failing)
    local dyingShips = {}
    for ship, result in pairs(shipToResult) do
        if result >= diceThreshold then
            local shipObject = getObjectFromGUID(ship)
            if shipObject then
                table.insert(dyingShips, ship)
                _animatingGuids[ship] = true
            end
        end
    end

    -- Loop and highlight dead ships until they're removed from their hex.
    local anchoredUnitsUnmoved = true
    local anchoredUnitsTimeout = Time.time + 120
    while Time.time < anchoredUnitsTimeout and anchoredUnitsUnmoved do
        anchoredUnitsUnmoved = false

        local currentTileToDeathTile = {}
        local shipStateToPosition = {}

        for _, ship in ipairs(dyingShips) do
            if _animatingGuids[ship] then
                local shipObject = getObjectFromGUID(ship)
                if shipObject then
                    anchoredUnitsUnmoved = true
                    shipObject.highlightOn(factionColor, 0.75)
                else
                    _animatingGuids[ship] = nil
                end
            end
        end

        -- Wait 2 seconds before repeating (1 sec on, 1 sec off)
        local blinkWait = Time.time + 1.5
        while Time.time < blinkWait do
            coroutine.yield(0)
        end
    end

    -- Stop tracking all GUIDs from this animation
    for _, ship in ipairs(dyingShips) do
        _animatingGuids[ship] = nil
    end

    -- At this point, all dying ships have been handled. Destroy dice.
    for _, die in ipairs(_bastionParadigmAbilityDice) do
        local dieObject = getObjectFromGUID(die)
        if dieObject then
            destroyObject(dieObject)
        end
    end
    _bastionParadigmAbilityDice = {}

    return 1
end
function bastionParadigm_rollDiceCoroutine()
    assert(_bastionParadigmAbilityDice and type(_bastionParadigmAbilityDice) == 'table')

    local waitToStart = Time.time + 1.5
    while Time.time < waitToStart do
        coroutine.yield(0)
    end

    for _, die in ipairs(_bastionParadigmAbilityDice) do
        local dieObject = getObjectFromGUID(die)
        if dieObject then
            dieObject.setLock(false)
            dieObject.randomize()
            local rollDelay = Time.time + 0.25
            while Time.time < rollDelay do
                coroutine.yield(0)
            end
        end
    end

    return 1
end
-- Hero
-- Faction: The Last Bastion
-- Card Name: Entity 4X4IC "Apollo"
-- Ability Name: Entity 4X4IC "Apollo"
-- Ability Text:
-- When one of your galvanized units is destryoed, 
-- You may purge this card to roll 1 die for each units
-- in its system that belongs to another player. If the 
--result of the die is equal to or greather than
-- the galvnaized unit's combat value, destroy that unit.
local function _entityApolloAbility(owningObject, clickingColor) --Last Bastion Hero
    if not _heroCardCanBeUsed(owningObject, clickingColor) then
        -- Function will print why card cannot be used
        return
    end

    table.insert(_entityApolloAbilityOwningObjectQueue, owningObject)
    startLuaCoroutine(self, '_entityApolloAbilityCoroutine')
end
local function _bastionParadigmAbility(owningObject, clickingColor) --Last Bastion Hero
    if not _paradigmCardCanBeUsed(owningObject, clickingColor) then
        -- Function will print why card cannot be used
        return
    end

    table.insert(_bastionParadigmAbilityOwningObjectQueue, owningObject)
    startLuaCoroutine(self, '_bastionParadigmAbilityCoroutine')
end

_heroNameSet = false
_paradigmNameSet = false
_hasContextMenuCardNameSet = false
function _hasContextMenuItems(object)
    if not _hasContextMenuCardNameSet then
        _heroNameSet = {}
		_paradigmNameSet = {}
        _hasContextMenuCardNameSet = {}
		local _paradigmCards = _deckHelper.getCardsWithSource({ deckName = "Paradigm" })
        for name, _ in pairs(_factionCardNameToAbilityFunc) do
            _hasContextMenuCardNameSet[name] = true
        end
        for _, faction in pairs(allFactions(true)) do
            if faction.hero then
                _heroNameSet[faction.hero] = true
                _hasContextMenuCardNameSet[faction.hero] = true
            end
        end
		for _, paradigm in ipairs(_paradigmCards) do
			_paradigmNameSet[paradigm] = true
			_hasContextMenuCardNameSet[paradigm] = true
		end
    end

    local name = object.getName()
    if object.tag == 'Card' and _hasContextMenuCardNameSet[name] then
        return true
    elseif object.tag == 'Tile' and name == 'Titan Sleeper Token' then
        return true
    end
end

function _applyContextMenuItems(object)
    local name = object.getName()

    local factionCardAbilityFunc = _factionCardNameToAbilityFunc and _factionCardNameToAbilityFunc[name] or false
    if factionCardAbilityFunc then
        object.addContextMenuItem(factionCardAbilityFunc.name, function(clickingColor) factionCardAbilityFunc.method(object, clickingColor) end, false)
    end

    if name == 'Titan Sleeper Token' then
        object.addContextMenuItem('Replace PDS', function(clickingColor) _replaceTitanSleeperToken(object, clickingColor, {'PDS'}) end, false)
        object.addContextMenuItem('Replace Mech/Inf', function(clickingColor) _replaceTitanSleeperToken(object, clickingColor, {'Mech', 'Infantry'}) end, false)
    end

    -- Most heroes are manually handled, and even the automated ones could be manually handled.
    -- Offer a simple Purge option on all faction hero cards.
	if _paradigmNameSet and _paradigmNameSet[name] then
		object.addContextMenuItem("Purge", function(clickingColor) _purgeParadigmCard(object, clickingColor) end, false)
	end
    if not _heroNameSet then
        _hasContextMenuItems(self) -- force build
    end
    if _heroNameSet[name] then
        object.addContextMenuItem("Purge", function(clickingColor) _purgeHeroCard(object, clickingColor) end, false)
    end
end

function onObjectSpawn(object)
    if object and _hasContextMenuItems(object) then
        _applyContextMenuItems(object)
    end
end

function onLoad(saveState)
    self.setColorTint({ r = 0.25, g = 0.25, b = 0.25 })
    self.setScale({ x = 2, y = 0.01, z = 2 })
    self.setName('TI4_FACTION_HELPER')
    self.setDescription('Shared helper functions used by other objects, PLEASE LEAVE ON TABLE! This object is only visible to the black (GM) player.')

    self.addContextMenuItem('Verify Factions', verifyAllFactions)
    self.addContextMenuItem('Report Factions', reportFactions)

    local function export()
        local input = allFactions(true)
        --local input = {_factionAttributes['The Arborec']}
        local result = {}
        for _, faction in pairs(input) do
            table.insert(result, _exportFaction(faction))
        end
        error('\n' .. JSON.encode(result))
    end
    self.addContextMenuItem('export', export)

    -- Only the GM/black player can see this object.  Others can still interact!
    local invisibleTo = {}
    for _, color in ipairs(Player.getColors()) do
        if color ~= 'Black' then
            table.insert(invisibleTo, color)
        end
    end
    self.setInvisibleTo(invisibleTo)

    _state = saveState and string.len(saveState) > 0 and JSON.decode(saveState) or _state

    -- Add faction names to attributes.
    for factionName, attributes in pairs(_factionAttributes) do
        attributes.name = factionName
    end

    _factionCardNameToAbilityFunc = {}
    _factionCardNameToAbilityFunc['Jace X, 4th Air Legion'] = { name = 'Helio Cmd. Array', method = _jacexHeroAbility }
    _factionCardNameToAbilityFunc['Conservator Procyon'] = { name = 'Multiverse Shift', method = _procynHeroAbility }
    _factionCardNameToAbilityFunc['It Feeds on Carrion'] = { name = 'Dimensional Anchor', method = _carrionHeroAbility }
	-- Thunders Edge Heroes
	_factionCardNameToAbilityFunc['Entity 4X41A "Apollo"'] = { name = 'Entity 4X41A "Apollo"', method = _entityApolloAbility }
	-- Twilight Fall Abilities
	_factionCardNameToAbilityFunc['TF Twilight Directive'] = { name = 'Twilight Directive', method = _federationParadigmAbility }
	_factionCardNameToAbilityFunc['TF Opening The Eye'] = { name = 'Opening The Eye', method = _empyreanParadigmAbility }
	_factionCardNameToAbilityFunc['TF Event Horizon'] = { name = 'Event Horizon', method = _vuilraithParadigmAbility }
	_factionCardNameToAbilityFunc['TF Intelligence Unshackled'] = { name = 'Intelligence Unshackeled', method = _bastionParadigmAbility }
	

    local function delayedApplyContextMenuItems()
        for _, object in ipairs(getAllObjects()) do
            if _hasContextMenuItems(object) then
                _applyContextMenuItems(object)
            end
        end
    end
    Wait.frames(delayedApplyContextMenuItems, 7)
end

function onSave()
    return JSON.encode(_state)
end

function onFrankenEnabled(value)
    _state.frankenEnabled = value or false
    updateFactions()
end

function reportFactions()
    _maybeUpdateFactions()
    local message = { 'FactionHelper.reportFactions: Franken=' .. tostring(_state.frankenEnabled)}
    for _, color in ipairs(_zoneHelper.zones()) do
        local faction = _colorToFaction[color]
        if faction then
            local hex = Color.fromString(color):toHex()
            table.insert(message, table.concat({
                '[' .. hex .. ']' .. color,
                'name={' .. (faction.name or '-') .. '}',
                'flagship={' .. (faction.flagship or '-') .. '}',
                'abilities={' .. table.concat(faction.abilities or {}, ', ') .. '}',
                'units={' .. table.concat(faction.units or {}, ', ') .. '}',
                'commander={' .. (faction.commander or '-') .. '}',
                'hero={' .. (faction.hero or '-') .. '}',
                'commodities={' .. (faction.commodities or '-') .. '}',
                'promissoryNotes={' .. table.concat(faction.promissoryNotes or {}, ', ') .. '}',
            }, ' '))
        end
    end
    printToAll(table.concat(message, '\n'))
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