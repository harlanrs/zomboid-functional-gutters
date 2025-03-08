local gutterEnums = require("FG_Enums")
local gutterUtils = require("FG_Utils")
local gutterOptions = require("FG_Options")

require "FG_TA_ConnectContainer"
require "FG_TA_DisconnectContainer"

local showContextUI = false

local function DoConnectContainer(playerObject, collectorObject)
    local wrench = gutterUtils:playerGetItem(playerObject:getInventory(), "PipeWrench")

    if luautils.walkAdj(playerObject, collectorObject:getSquare(), true) then
        if gutterOptions:getRequireWrench() then
            if wrench then
                ISWorldObjectContextMenu.equip(playerObject, playerObject:getPrimaryHandItem(), wrench, true)
                ISTimedActionQueue.add(FG_TA_ConnectContainer:new(playerObject, collectorObject, wrench))
            else
                -- pipe wrench is missing
            end
        else
            ISTimedActionQueue.add(FG_TA_ConnectContainer:new(playerObject, collectorObject, wrench))
        end
    end
end

local function DoDisconnectContainer(playerObject, collectorObject)
    local wrench = gutterUtils:playerGetItem(playerObject:getInventory(), "PipeWrench")

    if luautils.walkAdj(playerObject, collectorObject:getSquare(), true) then
        if gutterOptions:getRequireWrench() then
            if wrench then
                ISWorldObjectContextMenu.equip(playerObject, playerObject:getPrimaryHandItem(), wrench, true)
                ISTimedActionQueue.add(FG_TA_DisconnectContainer:new(playerObject, collectorObject, wrench))
            else
                -- pipe wrench is missing
            end
        else
            ISTimedActionQueue.add(FG_TA_DisconnectContainer:new(playerObject, collectorObject, wrench))
        end
    end
end

local function AddWaterContainerContext(player, context, worldobjects, test)
    for i,v in ipairs(worldobjects) do
        local worldObject = v
        local square = worldObject:getSquare()
        local fluidContainer = worldObject:getFluidContainer()
        if fluidContainer and square then
            -- Build general gutter context menu
            local squareModData = square:getModData()
            local containerName = fluidContainer:getContainerName()
            local playerObject = getSpecificPlayer(player)
            if squareModData["hasGutter"] then
                -- Include the plumbing context menu options
                local gutterSubMenu = context:getNew(context)
                local gutterSubMenuOption = context:addOption("Gutter Drain", playerObject, nil);
                context:addSubMenu(gutterSubMenuOption, gutterSubMenu)

                local requireWrench = gutterOptions:getRequireWrench()
                local notAvailable = false
                if requireWrench then
                    local wrench = gutterUtils:playerGetItem(playerObject:getInventory(), "PipeWrench")
                    if not wrench then
                        notAvailable = true
                    end
                end

                local isGutterConnected = gutterUtils:isGutterConnectedModData(worldObject)
                if isGutterConnected then
                    local disconnectGutterOption = gutterSubMenu:addOption("Disconnect "..tostring(containerName), playerObject, DoDisconnectContainer, worldObject);
                    disconnectGutterOption.notAvailable = notAvailable
                    if notAvailable then
                        disconnectGutterOption.toolTip = ISWorldObjectContextMenu.addToolTip()
                        disconnectGutterOption.toolTip.description = getText("Requires Pipe Wrench") -- TODO translate
                    end
                else
                    local connectGutterOption = gutterSubMenu:addOption("Connect "..tostring(containerName), playerObject, DoConnectContainer, worldObject);
                    connectGutterOption.notAvailable = notAvailable
                    if notAvailable then
                        connectGutterOption.toolTip = ISWorldObjectContextMenu.addToolTip()
                        connectGutterOption.toolTip.description = getText("Requires Pipe Wrench")
                    end
                end
            end

            -- Build additional context menu for displaying container data
            if showContextUI then
                -- Include the container context menu options
                local containerSubMenuOption = context:addOption("["..gutterEnums.modName.."] "..containerName, playerObject, nil);
                local containerSubMenu = context:getNew(context)
                context:addSubMenu(containerSubMenuOption, containerSubMenu)

                local rainFactor = fluidContainer:getRainCatcher()
                containerSubMenu:addOption("Rain Factor: " .. tostring(rainFactor), playerObject, nil)

                containerSubMenu:addOption("Has Gutter: " .. tostring(squareModData["hasGutter"]), playerObject, nil)

                local isGutterConnected = gutterUtils:isGutterConnectedModData(worldObject)
                containerSubMenu:addOption("Is Connected: " .. tostring(isGutterConnected), playerObject, nil)
            end
            
            break
        end
    end
end


local function checkShowContextUI()
    local options = PZAPI.ModOptions:getOptions(gutterEnums.modName)
    local showContextUIOption = options:getOption("ShowContextUI")
    showContextUI = showContextUIOption:getValue()
end

Events.OnLoad.Add(checkShowContextUI)

Events.OnFillWorldObjectContextMenu.Add(AddWaterContainerContext)