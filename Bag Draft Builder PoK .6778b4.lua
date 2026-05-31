-- @Original Author Unknown
-- @Author Arinok (Jan 2021)

function onLoad()
    initializeGlobalVariables()
    createUI()
end

function initializeGlobalVariables()
    basebag = getObjectFromGUID("d89b89")
    factionBag =  getObjectFromGUID("f16a7a")
    blueTileBag = getObjectFromGUID("da323e")
    redTileBag = getObjectFromGUID("a22bfb")
    tile = {}
    bagList = nil

    numberOfPlayers = 6
    numberOfFactions = 4
    numberOfBlueTiles = 5
    numberOfRedTiles = 3
    
    useBestSixBlueTiles = true
    removeWorstBlueTiles = true
    includeAllBlueWormHoles = false
    includeAllRedWormHoles = false
end

function createUI()
    createButtonUI()
    createSettingsUI()
    updateDisplay()

end

function createButtonUI()
    self.createButton({
        click_function = "setUp",
        function_owner = self,
        label          = "Create\nBags",
        rotation       = {x = 0, y = 0, z = 180}, 
        width          = 1200,
        height         = 800,
        font_size      = 300,
        tooltip        = "Create Bags"
    })
end

function createSettingsUI()
    local y = 0.2
    local yRot = -90

    createNumberOfPlayersButtonUI(1.2, y, yRot)
    createNumberOfFactionsButtonUI(1.0, y, yRot)
    createNumberOfBlueTilesButtonUI(0.8, y, yRot)
    createNumberOfRedTilesButtonUI(0.6, y, yRot)

    self.createButton({
        click_function = "none",
        function_owner = self,
        label          = "-----------------------------",
        position       = {0.45, y, 0.05},
        rotation       = {x = 0, y = yRot, z = 0},
        width          = 0,
        height         = 0,
        font_size      = 80,
    })

    createTogglesUI(y, yRot)
    createBookSettingsButton(y, yRot)
end

function createNumberOfPlayersButtonUI(x, y, yRot)
    self.createButton({
        click_function = "none",
        function_owner = self,
        label          = "Number of Players:",
        position       = {x, y, -0.25},
        rotation       = {x = 0, y = yRot, z = 0},
        width          = 0,
        height         = 0,
        font_size      = 80,
    })

    self.createButton({
        click_function = "decreasePlayerCount",
        function_owner = self,
        label          = "-",
        position       = {x, y, 0.8},
        rotation       = {x = 0, y = yRot, z = 0},
        width          = 80,
        height         = 80,
        font_size      = 80,
        tooltip        = "Decrease Player Count",
    })

    self.createButton({
        click_function = "increasePlayerCount",
        function_owner = self,
        label          = "+",
        position       = {x, y, 0.5},
        rotation       = {x = 0, y = yRot, z = 0},
        width          = 80,
        height         = 80,
        font_size      = 80,
        tooltip        = "Increase Player Count",
    })

    self.createButton({
        click_function = "none",
        function_owner = self,
        label          = tostring(numberOfPlayers),
        position       = {x, y, 0.65},
        rotation       = {x = 0, y = yRot, z = 0},
        width          = 0,
        height         = 0,
        font_size      = 80,
    })
end

function createNumberOfFactionsButtonUI(x, y, yRot)
    self.createButton({
        click_function = "none",
        function_owner = self,
        label          = "Factions Per Bag:",
        position       = {x, y, -0.25},
        rotation       = {x = 0, y = yRot, z = 0},
        width          = 0,
        height         = 0,
        font_size      = 80,
    })

    self.createButton({
        click_function = "decreaseFactionCount",
        function_owner = self,
        label          = "-",
        position       = {x, y, 0.8},
        rotation       = {x = 0, y = yRot, z = 0},
        width          = 80,
        height         = 80,
        font_size      = 80,
        tooltip        = "Decrease the Number of Factions per bag",
    })

    self.createButton({
        click_function = "increaseFactionCount",
        function_owner = self,
        label          = "+",
        position       = {x, y, 0.5},
        rotation       = {x = 0, y = yRot, z = 0},
        width          = 80,
        height         = 80,
        font_size      = 80,
        tooltip        = "Increase the Number of Factions per bag",
    })

    self.createButton({
        click_function = "none",
        function_owner = self,
        label          = tostring(numberOfFactions),
        position       = {x, y, 0.65},
        rotation       = {x = 0, y = yRot, z = 0},
        width          = 0,
        height         = 0,
        font_size      = 80,
    })
end

function createNumberOfBlueTilesButtonUI(x, y, yRot)
    self.createButton({
        click_function = "none",
        function_owner = self,
        label          = "Blue Tiles Per Bag:",
        position       = {x, y, -0.25},
        rotation       = {x = 0, y = yRot, z = 0},
        width          = 0,
        height         = 0,
        font_size      = 80,
    })

    self.createButton({
        click_function = "decreaseBlueTileCount",
        function_owner = self,
        label          = "-",
        position       = {x, y, 0.8},
        rotation       = {x = 0, y = yRot, z = 0},
        width          = 80,
        height         = 80,
        font_size      = 80,
        tooltip        = "Decrease the Number of Blue Tiles per bag",
    })

    self.createButton({
        click_function = "increaseBlueTileCount",
        function_owner = self,
        label          = "+",
        position       = {x, y, 0.5},
        rotation       = {x = 0, y = yRot, z = 0},
        width          = 80,
        height         = 80,
        font_size      = 80,
        tooltip        = "Increase the Number of Blue Tiles per bag",
    })

    self.createButton({
        click_function = "none",
        function_owner = self,
        label          = tostring(numberOfBlueTiles),
        position       = {x, y, 0.65},
        rotation       = {x = 0, y = yRot, z = 0},
        width          = 0,
        height         = 0,
        font_size      = 80,
    })
end

function createNumberOfRedTilesButtonUI(x, y, yRot)
    self.createButton({
        click_function = "none",
        function_owner = self,
        label          = "Red Tiles Per Bag:",
        position       = {x, y, -0.25},
        rotation       = {x = 0, y = yRot, z = 0},
        width          = 0,
        height         = 0,
        font_size      = 80,
    })

    self.createButton({
        click_function = "decreaseRedTileCount",
        function_owner = self,
        label          = "-",
        position       = {x, y, 0.8},
        rotation       = {x = 0, y = yRot, z = 0},
        width          = 80,
        height         = 80,
        font_size      = 80,
        tooltip        = "Decrease the Number of Red Tiles per bag",
    })

    self.createButton({
        click_function = "increaseRedTileCount",
        function_owner = self,
        label          = "+",
        position       = {x, y, 0.5},
        rotation       = {x = 0, y = yRot, z = 0},
        width          = 80,
        height         = 80,
        font_size      = 80,
        tooltip        = "Increase the Number of Red Tiles per bag",
    })

    self.createButton({
        click_function = "none",
        function_owner = self,
        label          = tostring(numberOfRedTiles),
        position       = {x, y, 0.65},
        rotation       = {x = 0, y = yRot, z = 0},
        width          = 0,
        height         = 0,
        font_size      = 80,
    })
end

function createBookSettingsButton(y, yRot)
    self.createButton({
        click_function = "bookSettings",
        function_owner = self,
        label          = "Book Settings",
        position       = {-1.25, y, 0},
        rotation       = {x = 0, y = yRot, z = 0},
        width          = 900,
        height         = 40,
        font_size      = 60,
    })
end

function bookSettings()
    if numberOfPlayers == 8 then
        numberOfBlueTiles = 4
        numberOfRedTiles = 2
    end

    if numberOfPlayers == 7 then
        numberOfBlueTiles = 4
        numberOfRedTiles = 2
    end

    if numberOfPlayers == 6 then
        numberOfBlueTiles = 3
        numberOfRedTiles = 2
    end

    if numberOfPlayers == 5 then
        numberOfBlueTiles = 4
        numberOfRedTiles = 2
    end

    if numberOfPlayers == 4 then
        numberOfBlueTiles = 5
        numberOfRedTiles = 3
    end

    if numberOfPlayers == 3 then
        numberOfBlueTiles = 6
        numberOfRedTiles = 2
    end

    useBestSixBlueTiles = false
    removeWorstBlueTiles = false
    includeAllBlueWormHoles = false
    includeAllRedWormHoles = false

    updateDisplay()
end

function updateDisplay()
    self.editButton({index = 4, label = tostring(numberOfPlayers)})
    self.editButton({index = 8, label = tostring(numberOfFactions)})
    self.editButton({index = 12, label = tostring(numberOfBlueTiles)})
    self.editButton({index = 16, label = tostring(numberOfRedTiles)})

    updateToggles()
end

function createTogglesUI(y,yRot)
    local buttonWidth = 900
    local buttonHeight = 40
    local buttonFont = 60

    self.createButton({
        click_function = "none",
        function_owner = self,
        label          = "Toggle options below. Red is on.",
        position       = {0.25, y, 0},
        rotation       = {x = 0, y = yRot, z = 0},
        width          = 0,
        height         = 0,
        font_size      = buttonFont,
    })

    self.createButton({
        click_function = "toggleUseBestSixBlueTiles",
        function_owner = self,
        label          = "Use Best Six Blue Tiles",
        position       = {-0.05, y, 0},
        rotation       = {x = 0, y = yRot, z = 0},
        width          = buttonWidth,
        height         = buttonHeight,
        font_size      = buttonFont,
    })

    self.createButton({
        click_function = "toggleRemoveWorstBlueTiles",
        function_owner = self,
        label          = "Remove Worst 3 Blue Tiles",
        position       = {-0.35, y, 0},
        rotation       = {x = 0, y = yRot, z = 0},
        width          = buttonWidth,
        height         = buttonHeight,
        font_size      = buttonFont,
    })

    self.createButton({
        click_function = "toggleIncludeAllBlueWormHoles",
        function_owner = self,
        label          = "Force Include Blue Wormholes",
        position       = {-0.65, y, 0},
        rotation       = {x = 0, y = yRot, z = 0},
        width          = buttonWidth,
        height         = buttonHeight,
        font_size      = buttonFont,
    })

    self.createButton({
        click_function = "toggleIncludeAllRedWormHoles",
        function_owner = self,
        label          = "Force Include Red Wormholes",
        position       = {-0.95, y, 0},
        rotation       = {x = 0, y = yRot, z = 0},
        width          = buttonWidth,
        height         = buttonHeight,
        font_size      = buttonFont,
    })
end

function updateToggles()
    local toggleColors = {
        [1] = {r=1,g=0,b=0},
        [2] = {r=1,g=1,b=1},
    }

    if useBestSixBlueTiles then
        self.editButton({
            index = 19,
            color = toggleColors[1],
        })
    else
        self.editButton({
            index = 19,
            color = toggleColors[2],
        })
    end

    if removeWorstBlueTiles then
        self.editButton({
            index = 20,
            color = toggleColors[1],
        })
    else
        self.editButton({
            index = 20,
            color = toggleColors[2],
        })
    end
    
    if includeAllBlueWormHoles then
        self.editButton({
            index = 21,
            color = toggleColors[1],
        })
    else
        self.editButton({
            index = 21,
            color = toggleColors[2],
        })
    end

    if includeAllRedWormHoles then
        self.editButton({
            index = 22,
            color = toggleColors[1],
        })
    else
        self.editButton({
            index = 22,
            color = toggleColors[2],
        })
    end
end

function setUp()
    if checkSetup() then

        createBags()
        printToAll("Bags Created")

        factionTokens()
        printToAll("Factions Distributed")

        	blueTiles()
        printToAll("Blue Tiles Distributed")

        	redTiles()
        printToAll("Red Tiles Distributed")

        destroyObject(tempBag)
        destroyObject(trashBag)
        printToAll("Ready for draft")
    end


end

function checkSetup()
    if numberOfFactions * numberOfPlayers > factionBag.getQuantity() then
        print("Error: require " .. tostring(numberOfFactions * numberOfPlayers) .. " faction tokens, but found " .. tostring(factionBag.getQuantity()))
        return false
    end

    if numberOfBlueTiles * numberOfPlayers > blueTileBag.getQuantity() then
        print("Error: require " .. tostring(numberOfBlueTiles * numberOfPlayers) .. " blue tiles, but found " .. tostring(blueTileBag.getQuantity()))
        return false
    end

    if numberOfRedTiles * numberOfPlayers > redTileBag.getQuantity() then
        print("Error: require " .. tostring(numberOfRedTiles * numberOfPlayers) .. " red tiles, but found " .. tostring(redTileBag.getQuantity()))
        return false
    end

    return true
end

function increasePlayerCount()
    if numberOfPlayers < 8 then
        numberOfPlayers = numberOfPlayers + 1
        updateValues()
    end
end

function decreasePlayerCount()
    if numberOfPlayers > 2 then
        numberOfPlayers = numberOfPlayers - 1
        updateValues()
    end
end

function increaseFactionCount()
    numberOfFactions = numberOfFactions + 1
    updateValues()
end

function decreaseFactionCount()
    if numberOfFactions > 0 then
        numberOfFactions = numberOfFactions - 1
        updateValues()
    end
end


function increaseBlueTileCount()
    numberOfBlueTiles = numberOfBlueTiles + 1
    updateValues()
end

function decreaseBlueTileCount()
    if numberOfBlueTiles > 0 then
        numberOfBlueTiles = numberOfBlueTiles - 1
        updateValues()
    end
end


function increaseRedTileCount()
    numberOfRedTiles = numberOfRedTiles + 1
    updateValues()
end

function decreaseRedTileCount()
    if numberOfRedTiles > 0 then
        numberOfRedTiles = numberOfRedTiles - 1
        updateValues()
    end
end

function updateValues()
    if numberOfFactions * numberOfPlayers > factionBag.getQuantity() then
        numberOfFactions = numberOfFactions - 1
        updateValues()
    end

    if numberOfBlueTiles * numberOfPlayers > blueTileBag.getQuantity() then
        numberOfBlueTiles = numberOfBlueTiles - 1
        updateValues()
    end

    if numberOfRedTiles * numberOfPlayers > redTileBag.getQuantity() then
        numberOfRedTiles = numberOfRedTiles - 1
        updateValues()
    end

    if numberOfBlueTiles == 0 then
        useBestSixBlueTiles = false
    end
    
    if numberOfBlueTiles == 0 then
        includeAllBlueWormHoles = false
    end
    
    if numberOfRedTiles == 0 then
        includeAllRedWormHoles = false
    end

    if numberOfBlueTiles * numberOfPlayers == blueTileBag.getQuantity() then
        removeWorstBlueTiles = false
    end

    updateDisplay()
end

function toggleUseBestSixBlueTiles()
    useBestSixBlueTiles = not useBestSixBlueTiles
    updateDisplay()
end

function toggleRemoveWorstBlueTiles()
    removeWorstBlueTiles = not removeWorstBlueTiles
    updateDisplay()
end

function toggleIncludeAllBlueWormHoles()
    includeAllBlueWormHoles = not includeAllBlueWormHoles
    updateDisplay()
end

function toggleIncludeAllRedWormHoles()
    includeAllRedWormHoles = not includeAllRedWormHoles
    updateDisplay()
end




function createBags()
    local y = 1
    local top = 6
    local bot = -6
    local left = -5
    local right = 5

    local colors = {
                    "Grey", 
                    "Blue", 
                    	"Purple", 
                    	"Yellow", 
                    	"Red", 
                    	"Green", 
                    	"Orange", 
                    	"Pink", 
                    	"Brown", 
                    	"Black"
                    	}    
    
    local posRow = numberOfPlayers - 1
    local bagPosition = {
        {{0,y,bot}, {0,y,top}}, 
        {{0,y,bot}, {left,y,top}, {right,y,top}},
        {{right,y,bot}, {left,y,bot}, {left,y,top}, {right,y,top}},
        {{right,y,bot}, {left,y,bot}, {left,y,top}, {0,y,top}, {right,y,top}},
        {{right,y,bot}, {0,y,bot}, {left,y,bot}, {left,y,top}, {0,y,top}, {right,y,top}},
        {{right,y,bot}, {0,y,bot}, {left,y,bot}, {left*2,y,top}, {left,y,top}, {right,y,top}, {right*2,2,top}},
        {{right*2,y,bot}, {right,y,bot}, {left,y,bot}, {left*2,y,bot}, {left*2,y,top}, {left,y,top}, {right,y,top}, {right*2,y,top}},
    }

    local _baseName,_keepName = " draft bag", " keep bag" --color..baseName
    for i=1, numberOfPlayers, 1 do
        local pos = bagPosition[posRow][i]
        local bag = basebag.clone({position = pos})
        bag.setColorTint(stringColorToRGB(colors[i]))
        bag.setName(colors[i].._baseName)
        pos[2] = pos[2] + 0.75
        local keepBag = bag.clone({position = pos})
        keepBag.setName(colors[i].._keepName)
        keepBag.use_grid = true
        bag.use_grid = false
        bagList = {next = bagList, value = bag}
    end


    tempBag = basebag.clone({['position'] = {8,3,0} })
    trashBag = basebag.clone({['position'] = {-8,3,0} })


end

function factionTokens()
    factionBag.shuffle()

    for i=1, numberOfFactions, 1 do
        local list = bagList
        while list do
            list.value.putObject(factionBag.takeObject())
            list = list.next
        end
    end
end

function blueTiles()
    getBlueSystems()
    distributeTiles()
    emptyBag(trashBag, blueTileBag)
end

function getAndDistributeBestSystems()
    local bestTiles = {
        "69f885", -- abyz fria 
        "cae2ce", -- arinam meer
        "322174", -- bereg lirta4
        --"1154bc", -- hopes end (Swapped out for TE tripple)
        "35d7dc", -- starpoint newAlbion
        "40bc9e", -- accoen jeolJr
        "edc1e5", -- elnath (TE 3 planet)
    }

    for _,tile in ipairs(bestTiles) do
        if contains(tile, blueTileBag) then
            pullTileFromBag(tile, blueTileBag, tempBag)
        end
    end


    distributeTiles()
    emptyBag(tempBag, blueTileBag)
end

function getWorstBlueTiles()
    local worstTiles = {
        "387d24", -- saudor
        "e0b992", -- vefut II
        "0a93a9", -- perimeter
    }

   for _,tile in ipairs(worstTiles) do
        if contains(tile, blueTileBag) then
            pullTileFromBag(tile, blueTileBag, trashBag)
        end
    end
end

function getBlueSystems()
    local numberOfTiles = numberOfBlueTiles * numberOfPlayers

    if useBestSixBlueTiles then
        getAndDistributeBestSystems()
        numberOfTiles = numberOfTiles - numberOfPlayers
    end
    
    if removeWorstBlueTiles then
        getWorstBlueTiles()
    end

    if includeAllBlueWormHoles then
        getAllBlueWormHoles()
    end


    blueTileBag.shuffle()
    while tempBag.getQuantity() < numberOfTiles do
        tempBag.putObject(blueTileBag.takeObject())
    end
end

function getAllBlueWormHoles()
    local wormholeTiles = {
        "a28bb1", -- atlas
        "31e03b", -- lodor
        "5b1d07", -- quann
        "783d69", -- andeara TE
    }
    for _,tile in ipairs(wormholeTiles) do
        if contains(tile, blueTileBag) then
            pullTileFromBag(tile, blueTileBag, tempBag)
        end
    end 
end

function redTiles()
    gatherRedTiles()
    distributeTiles()
    emptyBag(trashBag, redTileBag)
end

function gatherRedTiles()
    local numberOfTiles = numberOfPlayers * numberOfRedTiles

    if includeAllRedWormHoles then
        getAllRedWormHoles()
    end



    redTileBag.shuffle()
    while tempBag.getQuantity() < numberOfTiles do
        tempBag.putObject(redTileBag.takeObject())
    end

end

function getAllRedWormHoles()
    local redWormholeTiles = {    
        "b0a6a6", -- betaHole
        "33520d", -- alphaHole
        "1a6583", -- alphaHoleAsteroids
        "1684ac", -- TE beta rift
    }
    for _,tile in ipairs(redWormholeTiles) do
        if contains(tile, redTileBag) then
            pullTileFromBag(tile, redTileBag, tempBag)
        end
    end 
end

function distributeTiles()
    tempBag.shuffle()
    while tempBag.getQuantity() > 0 do



        local list = bagList
        while list and tempBag.getQuantity() > 0 do
            list.value.putObject(tempBag.takeObject())
            list = list.next
        end
    end
end

function pullTileFromBag(tileUID, fromBag, toBag)
    tile.guid = tileUID
    toBag.putObject(fromBag.takeObject(tile))
end

function emptyBag(fromBag,toBag)
    while fromBag.getQuantity() > 0 do
        toBag.putObject(fromBag.takeObject())
    end
end

function contains(UID, container)
    local table = container.getObjects()
    for _, object in ipairs(table) do
        if object.guid == UID then
            return true
        end
    end
    return false
end