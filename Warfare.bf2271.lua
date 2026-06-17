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

local activationToken, tokenName = 'f52711', 'Activation Token'

function onLoad(saveState)
    activationToken = getObjectFromGUID(activationToken)
    local strategyCardHelper = getHelperClient('TI4_STRATEGY_CARD_HELPER')
    strategyCardHelper.register({
        guid = self.getGUID(),
        ui = 'warfare',
        onPlayCallback = 'clickedPlay'  -- gets clicking player color as argument
    })
end

local posOffset = {x = 0.27, y = 0.24, z = 0.63}
function clickedPlay(clickerColor)
    if activationToken == nil then
        for _,each in ipairs(getAllObject()) do
            if each.getName() == tokenName then
                activationToken = each
                break
            end
        end
        if activationToken == nil then return end
    end

    local pos = self.getPosition()
    pos.x = pos.x + posOffset.x
    pos.y = pos.y + posOffset.y
    pos.z = pos.z + posOffset.z
    activationToken.setPosition(pos)
    activationToken.setRotation(self.getRotation())
    activationToken.addForce({x =0, y = 12, z = 0})
end