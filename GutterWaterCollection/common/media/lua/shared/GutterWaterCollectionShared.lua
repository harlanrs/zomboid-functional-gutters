-- TODO define & grab from global mod object for gutterWaterCollection
local function hasGutterModData(object)
    if not object:hasModData() then return false end
    return object:getModData()["hasGutter"]
end

local function AddWaterContainerContext(player, context, worldobjects, test)
    for i,v in ipairs(worldobjects) do
        local fluidContainer = v:getFluidContainer()
        if fluidContainer then
            local subMenuOption = context:addDebugOption("[gutterWaterCollection] "..v:getName(), worldobjects, nil);
			local subMenu = context:getNew(context)
			context:addSubMenu(subMenuOption, subMenu)

            local rainFactor = fluidContainer:getRainCatcher()
            subMenu:addDebugOption("Rain Factor: " .. tostring(rainFactor))

            local hasGutter = hasGutterModData(v)
            subMenu:addDebugOption("Has Gutter: " .. tostring(hasGutter))
            break
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(AddWaterContainerContext)