--Overwrite all dice to be this color (table or false). Overrules diePlayerColor
dieColorOverwrite = false     --ex. {1,0,0} for red
--If a die is colored to match the player who pressed the button for it
diePlayerColor = false       --true or false


--What type of die will be rolled by this tool (only works with 1)
dieType = "Die_10"
--Dice type options (quotes required)
--  Die_4
--  Die_6
--  Die_6_Rounded
--  Die_8
--  Die_10
--  Die_12
--  Die_20
--  Custom_Dice --REQUIRES ADDITIONAL ENTRIES BELOW

--If Custom_Dice is the dice type used, then you must enter info below
    --URL for the die image goes in the quotes
    dieImage = ""
    --Number of sides on die. Options are 4, 6, 8 10, 12, 20
    dieSides = 4

--Time before dice disappear. -1 means they do not (until next roll)
removalDelay = 10

--If dice are added together for announcement (true or false)
announce_total = true
--If individual results are displayed (true or false)
announce_each = true
--If last player to click button before roll happens gets their name announced
announce_player = true

--Distance dice are placed from the tool's center
radialOffset = 2.2
--Distance die gets moved up
heightOffset = 2
--Die size, default of 1
dieSize = 1

--How long to wait before rolling the spawned dice
waitBeforeRoll = 1.5

--How many dice can be spawned. 0 is infinite
dieLimit = 20

--END OF VARIABLES TO EDIT
--Beyond here, there be Lua!

--Save to track currently active dice for disposal on load
function onSave()
    if #currentDice > 0 then
        local currentDiceGUIDs = {}
        for _, obj in ipairs(currentDice) do
            if obj ~= nil then
                table.insert(currentDiceGUIDs, obj.getGUID())
            end
        end
        saved_data = JSON.encode(currentDiceGUIDs)
    else
        saved_data = ""
    end
    return saved_data
end

function onload(saved_data)
    --Loads the save of any active dice and deletes them
    if saved_data ~= "" then
        local loaded_data = JSON.decode(saved_data)
        for _, guid in ipairs(loaded_data) do
            local obj = getObjectFromGUID(guid)
            if obj ~= nil then
                destroyObject(obj)
            end
        end
        currentDice = {}
    else
        currentDice = {}
    end

    --Makes the roll button
    self.createButton({
        click_function="click_roll", function_owner=self,
        position={0,0.1,0}, height=550, width=550, color={0,0,0,0}
    })

    --Makes the hit vale buttons
    local object, distance = self, 0.85 * self.getScale().x
    local oRot = object.getRotation()

    for i = 1, 10 do
        if i == 1 then
            lbl = "X"
        else
            lbl = i
        end
        local posX = math.sin( math.rad(36*(i-1)+oRot.y) ) * distance
        local posY = 0.1
        local posZ = math.cos( math.rad(36*(i-1)+oRot.y) ) * distance
        local pos = {x=posX, y=posY, z=posZ}
        local rot = {0,180,0}
        self.createButton({
            click_function="click_num"..i, function_owner=self,
            position=pos, rotation=rot, label = lbl, height=100, width=100, font_size = 100
        })
        local func = function(_,color) numberButtonPressed(i) end
        self.setVar("click_num"..i, func)
    end
end

hitValue = 0

function numberButtonPressed(i)
    for i = 1, 10 do
        self.editButton({index=i, color="White"})
    end
    if i == 1 or i == hitValue then
        hitValue = 0
    else
        hitValue = i
        self.editButton({index=i, color="Green"})
    end
end


--Die spawning and positioning



--Click function, spawns new dice and waits for a pause to do the rolling
function click_roll(_, color)
    --Dice spam protection, can be disabled up at top of script
    local diceCount = 0
    for _ in pairs(currentDice) do
        diceCount = diceCount + 1
    end
    local denyRoll = false
    if dieLimit > 0 and diceCount >= dieLimit then
        denyRoll = true
    end
    --Check for if click is allowed
    if rollInProgress == nil and denyRoll == false then
        self.AssetBundle.playTriggerEffect(0)

        --Find dice positions, moving previously spawned dice if needed
        local angleStep = 360 / (#currentDice+1)
        for i, die in ipairs(currentDice) do
            local pos = findGlobalPosWithLocalDirection(angleStep*(i-1))
            die.setPositionSmooth(pos, false, true)
        end

        --Spawns dice
        local spawnedDie = spawnObject({
            type=dieType,
            position = findGlobalPosWithLocalDirection(360-angleStep),
            rotation = randomRotation(), scale={dieSize,dieSize,dieSize}
        })
        if dieType == "Custom_Dice" then
            spawnedDie.setCustomObject({
                image = dieImage,
                type = ref_customDieSides[tostring(dieSides)]
            })
        end
        table.insert(currentDice, spawnedDie)
        spawnedDie.interactable = false
        spawnedDie.setLock(true)
        if dieColorOverwrite ~= false then
            spawnedDie.setColorTint(dieColorOverwrite)
        elseif diePlayerColor == true then
            spawnedDie.setColorTint(stringColorToRGB(color))
        end

        --Timer starting
        Timer.destroy("clickRoller_"..self.getGUID())
        Timer.create({
            identifier="clickRoller_"..self.getGUID(), delay=waitBeforeRoll,
            function_name="rollDice", function_owner=self,
            parameters = {color = color}
        })
    elseif rollInProgress == false then
        cleanupDice()
        click_roll(_, color)
    else
        Player[color].broadcast("Roll in progress.", {0.8, 0.2, 0.2})
    end
end



--Die rolling



--Rolls all the dice and then launches monitoring
function rollDice(p)
    rollInProgress = true
    function coroutine_rollDice()
        for _, die in ipairs(currentDice) do
            die.setLock(false)
            die.randomize()
            wait(0.1)
        end

        monitorDice(p.color)

        return 1
    end
    startLuaCoroutine(self, "coroutine_rollDice")
end

--Monitors dice to come to rest
function monitorDice(color)
    function coroutine_monitorDice()
        repeat
            local allRest = true
            for _, die in ipairs(currentDice) do
                if die ~= nil and die.resting == false then
                    allRest = false
                end
            end
            coroutine.yield(0)
        until allRest == true

        --Announcement
        if announce_total==true or announce_each==true then
            displayResults(color)
        end

        wait(0.1)
        rollInProgress = false

        for _, die in ipairs(currentDice) do
            die.interactable = true
        end

        --Auto die removal
        if removalDelay ~= -1 then
            --Timer starting
            Timer.destroy("clickRoller_cleanup_"..self.getGUID())
            Timer.create({
                identifier="clickRoller_cleanup_"..self.getGUID(),
                function_name="cleanupDice", function_owner=self,
                delay=removalDelay,
            })
        end

        return 1
    end
    startLuaCoroutine(self, "coroutine_monitorDice")
end



--After roll broadcasting and cleanup



function displayResults(color)
    local total = 0
    local resultTable = {}

    --Tally result info
    for _, die in ipairs(currentDice) do
        if die ~= nil then
            local value = die.getValue()
            if value >= hitValue then total = total + 1 end
            table.insert(resultTable, value)
        end
    end

    --String assembly
    local s = ""
    if announce_each == true then
        for i, v in ipairs(resultTable) do
            if not (s == "") then
                s = s .. ", "
            end
            s = s .. v
            if hitValue > 0 and v >= hitValue then
                s = s .. "#"
            end
        end
    end
    if hitValue > 0 then
        if s ~= "" then
            s = "Hitting on: " .. hitValue .. "  |  " .. s .. "  |  "
        end
        if total ~= 1 then plural = "s." else plural = "." end
        s = s .. "[b]" .. total .. " hit" .. plural .. "[/b]"
    end
    if announce_player == true then
        s = Player[color].steam_name .. "  |  " .. s
    end

    broadcastToAll(s, stringColorToRGB(color))
end



--Die cleanup



function cleanupDice()
    for _, die in ipairs(currentDice) do
        if die ~= nil then
            destroyObject(die)
        end
    end

    Timer.destroy("clickRoller_cleanup_"..self.getGUID())
    rollInProgress = nil
    currentDice = {}
end




--Utility functions to obtain info



--Finds a position, rotated around the Y axis, using distance you want + angle
--oPos is object pos, oRot=object rotation, distance = how far, angle = angle in degrees
function findGlobalPosWithLocalDirection(angle)
    local object, distance = self, radialOffset * self.getScale().x
    local oPos, oRot = object.getPosition(), object.getRotation()
	local posX = oPos.x + math.sin( math.rad(angle+oRot.y) ) * distance
	local posY = oPos.y + heightOffset
	local posZ = oPos.z + math.cos( math.rad(angle+oRot.y) ) * distance
	return {x=posX, y=posY, z=posZ}
end

--Gets a random rotation vector
function randomRotation()
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

--Coroutine delay, in seconds
function wait(time)
    local start = os.time()
    repeat coroutine.yield(0) until os.time() > start + time
end




--Data tables



ref_customDieSides = {["4"]=0, ["6"]=1, ["8"]=2, ["10"]=3, ["12"]=4, ["20"]=5}