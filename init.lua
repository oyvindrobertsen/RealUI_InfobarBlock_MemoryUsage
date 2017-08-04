local UPDATEPERIOD, elapsed = 2, 0
local LDB = LibStub:GetLibrary("LibDataBroker-1.1")
local qTip = LibStub:GetLibrary("LibQTip-1.0")
local totalMemoryUsage = 0
local addons = {}

local function InitAddonList()
    UpdateAddOnMemoryUsage()
	for i = 1, GetNumAddOns() do
		local u = GetAddOnMemoryUsage(i)
		totalMemoryUsage = totalMemoryUsage + u
		addons[i] = {name = GetAddOnMetadata(i, "Title"), used = u}
	end
end

InitAddonList()

local function UpdateAddonList()
    UpdateAddOnMemoryUsage()
	totalMemoryUsage = 0
	for i = 1, GetNumAddOns() do
		local u = GetAddOnMemoryUsage(i)
		totalMemoryUsage = totalMemoryUsage + u
		addons[i].used = u
	end
end

local function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end


LDB:NewDataObject("memoryusage", {
    name = "Memory Usage",
    type = "data source",
    label = "Memory Usage",
    text = "Calculating Memory Usage",
    OnEnter = function(block, ...)
        if qTip:IsAcquired(block) then return end

        local tooltip = qTip:Acquire(block, 2, "LEFT", "RIGHT")
        tooltip:SmartAnchorTo(block)
    	tooltip:SetAutoHideDelay(0.10, block)
    	tooltip:UpdateScrolling()
    	block.tooltip = tooltip

        tooltip:AddHeader("Memory Usage")

        for i, addon in spairs(addons, function(t, a, b) return t[a].used > t[b].used end) do
        	if addon.used >= 1 then
        		if addon.used > 1000 then
	        		tooltip:AddLine(addon.name, string.format("%d MB", addon.used/1000))
	        	else
	        		tooltip:AddLine(addon.name, string.format("%d KB", addon.used))
	        	end
        	end
        end

        tooltip:Show()
    end,
    OnUpdate = function(block, timedelta)
        elapsed = elapsed + timedelta
        if elapsed < UPDATEPERIOD then return end
        elapsed = 0
        UpdateAddonList()
        block.dataObj.text = string.format("%d MB", totalMemoryUsage/1000)
    end,
})