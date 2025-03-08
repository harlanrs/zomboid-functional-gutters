local gutterService = require("FG_Service")

local ISBuildIsoEntity_setInfo = ISBuildIsoEntity.setInfo
function ISBuildIsoEntity:setInfo(square, north, sprite, openSprite)
    -- React to the creation of a new iso entity object from the build menu
    -- NOTE: using ISBuildIsoEntity:setInfo instead of ISBuildIsoEntity:create as it is possible for the create function to exit early unsuccessfully
    ISBuildIsoEntity_setInfo(self, square, north, sprite, openSprite)

    gutterService:handleObjectBuiltOnTile(square)
end

Events.OnObjectAdded.Add(function(object)
    return gutterService:handleObjectPlacedOnTile(object)
end)

Events.OnTileRemoved.Add(function(object)
    return gutterService:handleObjectRemovedFromTile(object)
end)