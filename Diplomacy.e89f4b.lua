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
        return function(parameters) return helperObject.call(functionName, parameters) end
    end
    return setmetatable({}, { __index = function(t, k) return getCallWrapper(k) end })
end

local diploToken, tokenName = '636075', 'Diplomacy Token'

function onLoad(saveState)
    diploToken = getObjectFromGUID(diploToken)
    local strategyCardHelper = getHelperClient('TI4_STRATEGY_CARD_HELPER')
    strategyCardHelper.register({
        guid = self.getGUID(),
        ui = 'diplomacy',
        onPlayCallback = 'clickedPlay'  -- gets clicking player color as argument
    })
end

local posOffset = {x = 0.26, y = 0.12, z = 0.70}
function clickedPlay(clickerColor)
    if diploToken == nil then
        for _,each in ipairs(getAllObjects()) do
            if each.getName() == tokenName then
                diploToken = each
                break
            end
        end
        if diploToken == nil then return end
    end

    local pos = self.getPosition()
    pos.x = pos.x + posOffset.x
    pos.y = pos.y + posOffset.y
    pos.z = pos.z + posOffset.z
    diploToken.setPosition(pos)
    diploToken.setRotation(self.getRotation())
    diploToken.addForce({x =0, y = 12, z = 0})
end