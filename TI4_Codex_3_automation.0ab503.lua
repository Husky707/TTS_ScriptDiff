function onLoad()
    createButton()
end

function createButton()
    self.createButton({
        click_function = "Setup_Codex_3",
        function_owner = self,
        label          = "Setup",
        position       = {0, .2, 0},
        rotation       = {0, 0, 0},
        width          = 1000,
        height         = 500,
        font_size      = 250
    })
end

function Setup_Codex_3()
    local box = getObjectFromGUID("c600b0")
    local pokbox = "c600b0"
    local secrets = getObjectFromGUID("e4d66b")
    local frontier = getObjectFromGUID("a3ba86")
    local factions = "09b393"
    local xxcha = "a3c157"
    local xxchaLBag = "5cc04c"
    local gromOmega = {"724f7b"}
    local grom = {"ab4da8"}
    local newPosition = {x = 10, y = 3, z = 2}

    local c3YIN = {"6018c1", "3def41","420104"}
    local yin = "92153b"
    local yinLeader = {"fcf5a9", "6def37","fa1879"}
    local yinLbag = "68372e"

    local naluu = "3a36f7"
    local naluuLbag = "3a631d"
    local naluuLeader = {"ed976f", "cb2ab1","4779e4"}
    local c3Naluu = {"692f11", "5ff356", "83ed04"}

    -- Remove secrets from the deck
    startCardDeletionProcess(secrets, {"048ca8", "be84c0", "08bed5"}, function()
        -- Add frontier to the deck
        takeAndAddObjectToDeck(box, frontier, "8e4ccc", function()
            -- Add secrets to the deck
            takeAndAddObjectToDeck(box, secrets, "206f6a", Wait.frames(function()
                secrets.shuffle()
                frontier.shuffle()
                print("Decks shuffled.")
            end,300))
        end)
    end)


    deleteNestedObjects(factions, xxcha, xxchaLBag, grom, function()
      moveCardsBetweenBoxes(pokbox, gromOmega, xxchaLBag, function()
            putNestedObjects(factions, xxcha, xxchaLBag, function()
                deleteNestedObjects(factions, yin, yinLbag, yinLeader, function()
                    moveCardsBetweenBoxes(pokbox, c3YIN, yinLbag, function()
                        putNestedObjects(factions, yin, yinLbag, function()
                            deleteNestedObjects(factions, naluu, naluuLbag, naluuLeader, function()
                                moveCardsBetweenBoxes(pokbox, c3Naluu, naluuLbag, function()
                                    putNestedObjects(factions, naluu, naluuLbag)
                                end)  -- end for moveCardsBetweenBoxes
                            end)      -- end for deleteNestedObjects (naluu)
                        end)          -- end for putNestedObjects (yin)
                    end)              -- end for moveCardsBetweenBoxes (yin)
                end)                  -- end for deleteNestedObjects (yin)
            end)                      -- end for putNestedObjects (xxcha)
        end)                          -- end for moveCardsBetweenBoxes (xxcha)
    end)                              -- end for deleteNestedObjects (xxcha)







end

function putNestedObjects(outerMostBagGUID, outerBagGUID, boxGUID, callback)
    local outerMostBag = getObjectFromGUID(outerMostBagGUID)
    local outerBag = getObjectFromGUID(outerBagGUID)
    local box = getObjectFromGUID(boxGUID)

    if not outerMostBag or not outerBag or not box then
        print("One or more objects could not be found.")
        return
    end

    -- First, put the box into the outer bag
    outerBag.putObject(box)

    -- Wait a bit before placing the outer bag into the outermost bag
    -- to ensure the box has been properly nested
    Wait.frames(function()
        outerMostBag.putObject(outerBag)

        -- Execute the callback function after the nesting is complete
        if callback then
            callback()
        end
    end, 60)  -- Wait for 60 frames, adjust if needed
end


function moveCardsBetweenBoxes(originalBoxGUID, cardGUIDs, targetBoxGUID, callback)
    local originalBox = getObjectFromGUID(originalBoxGUID)
    local targetBox = getObjectFromGUID(targetBoxGUID)

    if not originalBox or not targetBox then
        print("One or more boxes could not be found.")
        return
    end

    -- Index to track the current card being moved
    local index = 1

    local function moveNextCard()
        if index > #cardGUIDs then
            -- All cards have been moved, execute callback if provided
            if callback then
                callback()
            end
            return
        end

        -- Get the current card's GUID
        local cardGUID = cardGUIDs[index]

        -- Take and move the card
        originalBox.takeObject({
            guid = cardGUID,
            smooth = false,  -- Set to false for immediate relocation
            callback_function = function(takenCard)
                -- Optionally, set a new position for the taken card
                -- local newPosition = {x = 0, y = 3, z = 0}
                -- takenCard.setPosition(newPosition)

                -- Place the card into the target box
                targetBox.putObject(takenCard)

                -- Increment the index and wait before moving the next card
                index = index + 1
                Wait.frames(moveNextCard, 30)  -- Wait for 30 frames before next iteration
            end
        })
    end

    -- Start the loop
    moveNextCard()
end




function startCardDeletionProcess(deck, cardGUIDs, callback)
    if #cardGUIDs > 0 then
        deleteNextCard(deck, cardGUIDs, 1, callback)
    else
        callback()
    end
end

function deleteNextCard(deck, cardGUIDs, index, callback)
    if index > #cardGUIDs then
        callback()
        return -- Exit if all cards have been processed
    end

    local guid = cardGUIDs[index]
    deck.takeObject({
        guid = guid,
        callback_function = function(obj)
            destroyObject(obj)
            Wait.frames(function()
                deleteNextCard(deck, cardGUIDs, index + 1, callback)
            end, 30) -- Short wait before next deletion
        end
    })
end

function takeAndAddObjectToDeck(box, deck, objectGUID, callback)
    local object = box.takeObject({ guid = objectGUID })

    if object then
        deck.putObject(object)
        if callback then
            callback()
        end
    else
        print("Object with GUID " .. objectGUID .. " not found in the box.")
    end
end


function deleteNestedObjects(outerMostBagGUID, outerBagGUID, boxGUID, objectGUIDs, callbackFunction)
    local outerMostBag = getObjectFromGUID(outerMostBagGUID)


    outerMostBag.takeObject({
        guid = outerBagGUID,
        callback_function = function(outerBag)

            outerBag.takeObject({
                guid = boxGUID,
                callback_function = function(innerBox)


                    local count = 0
                    for _, guid in ipairs(objectGUIDs) do
                        innerBox.takeObject({
                            guid = guid,
                            smooth = false,
                            callback_function = function(targetObject)
                                destroyObject(targetObject)

                                count = count + 1
                                if count == #objectGUIDs and callbackFunction then
                                    callbackFunction()
                                end
                            end
                        })
                    end
                end
            })
        end
    })
end