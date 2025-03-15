local function loadTileDefs(manager)
    -- Register gutter sprites
    local sprites = {
        "roofs_06_6", -- roof gutter south
        "roofs_06_7", -- roof gutter east
        "roofs_06_21", -- roof south east corner small
        "roofs_06_20" -- roof north west corner large
    }

    for _, sprite in ipairs(sprites) do
        local props = manager:getSprite(sprite):getProperties();
        props:Set("MaterialType", "Metal", false)
        props:CreateKeySet();
    end
end

Events.OnLoadedTileDefinitions.Add(loadTileDefs)


