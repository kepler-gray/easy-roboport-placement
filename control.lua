-- Initializes the storage table on a new game.
script.on_init(function()
    if not storage.roboport_ghosts then
        storage.roboport_ghosts = {}
    end
end)

-- This event handler is called when a game is loaded.
-- It ensures the table is available in case of a corrupted save.
script.on_load(function()
    if not storage.roboport_ghosts then
        storage.roboport_ghosts = {}
    end
end)

-- This event handler is called every game tick. It iterates through all tracked
-- roboport ghosts and redraws the logistic range polygons around them.
script.on_event(defines.events.on_tick, function(event)
    -- Check if storage.roboport_ghosts exists to prevent errors on a new save
    if storage.roboport_ghosts then
        for index, ghost in pairs(storage.roboport_ghosts) do
            -- Check if the ghost entity is still valid.
            if ghost and ghost.valid then
                -- Check for the existence of the entity prototype before trying to access it
                if prototypes.entity[ghost.ghost_name] and prototypes.entity[ghost.ghost_name].logistic_radius then
                    local rad = prototypes.entity[ghost.ghost_name].logistic_radius
                    local player_surface = ghost.surface.index

                    -- Draw the two polygons to create the square shape around the ghost
                    rendering.draw_polygon({
                        draw_on_ground = true,
                        color = { r = 0.15, g = 0.08, b = 0.02, a = 0.02 },
                        target = ghost,
                        surface = player_surface,
                        only_in_alt_mode = true,
                        vertices = {
                            { rad, rad },
                            { -rad, rad },
                            { -rad, -rad }
                        },
                        time_to_live = 1 -- Redraw every tick to maintain visibility
                    })

                    rendering.draw_polygon({
                        draw_on_ground = true,
                        color = { r = 0.15, g = 0.08, b = 0.02, a = 0.02 },
                        target = ghost,
                        surface = player_surface,
                        only_in_alt_mode = true,
                        vertices = {
                            { rad, rad },
                            { rad, -rad },
                            { -rad, -rad }
                        },
                        time_to_live = 1 -- Redraw every tick to maintain visibility
                    })
                end
            else
                -- If a ghost is no longer valid, remove it from the table
                storage.roboport_ghosts[index] = nil
            end
        end
    end
end)

-- The `on_built_entity` event now simply adds a newly placed roboport ghost
-- to the storage table for the `on_tick` handler to track.
script.on_event(defines.events.on_built_entity, function(event)
    local setting_value = settings.get_player_settings(event.player_index)["draw-roboport-ghost-range"]
    local entity = event.entity

    if setting_value.value and entity.type == "entity-ghost" and entity.ghost_type == "roboport" then
        if not storage.roboport_ghosts then
            storage.roboport_ghosts = {}
        end
        table.insert(storage.roboport_ghosts, entity)
    end
end)

-- These events are used to clean up the `storage.roboport_ghosts` table when a ghost is removed from the game
script.on_event(defines.events.on_robot_mined_entity, function(event)
    if storage.roboport_ghosts then
        for index, ghost in pairs(storage.roboport_ghosts) do
            if ghost == event.entity then
                storage.roboport_ghosts[index] = nil
                break
            end
        end
    end
end)

script.on_event(defines.events.on_entity_died, function(event)
    if storage.roboport_ghosts then
        for index, ghost in pairs(storage.roboport_ghosts) do
            if ghost == event.entity then
                storage.roboport_ghosts[index] = nil
                break
            end
        end
    end
end)

script.on_event("toggle-ghost-logistic-range", function(event)
    settings.get_player_settings(event.player_index)["draw-roboport-ghost-range"] = {
        value = not settings.get_player_settings(event.player_index)["draw-roboport-ghost-range"].value
    }
end)
