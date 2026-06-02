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

function onLoad(saveState)
    local strategyCardHelper = getHelperClient('TI4_STRATEGY_CARD_HELPER')
    strategyCardHelper.register({
        guid = self.getGUID(),
        ui = 'warfare',
        onPlayCallback = 'clickedPlay'  -- gets clicking player color as argument
    })
end

function clickedPlay(clickerColor)
end