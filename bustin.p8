pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

-- a bubble is a table with x, y, and color properties
-- example bubble: { x = 32, y = 32, color = 3 }

#include bustin/set.lua

radius = 5
diameter = radius * 2

walls = {
    left = {
        x0 = 21, y0 = 6,
        x1 = 23, y1 = 123
    },
    right = {
        x0 = 104, y0 = 6,
        x1 = 106, y1 = 123
    },
    top = {
        x0 = 21, y0 = 3,
        x1 = 106, y1 = 5
    },
    bottom = {
        x0 = 24, y0 = 106,
        x1 = 104, y1 = 108
    }
}

cell_start = {
    x = walls.left.x1 - radius + 1,
    y = walls.top.y1 - diameter + 2
}

cell_end = {
    x = walls.right.x0 - 1,
    y = walls.bottom.y0 - 1
}

cannon = {
    center_x = 64,
    center_y = 112,
    length = 15,
    angle = 68,
    speed = 0.5
}

frozen_count = 0

frozen = {}

colors = { 12, 10, 11, 8 }

level_one = "11,12,8:13,14,9:15,16,12:17,18,11:"
        .. "21,22,8:23,24,9:25,26,12:27,11:"
        .. "31,32,12:33,34,11:35,36,8:37,38,9:"
        .. "41,12:42,43,11:44,45,8:46,47,9"

active_bubble = {
    speed = 4
}

falling_check = nil

falling = {}

function _init()
    printh("", "bustin.txt", true)

    cls()

    -- Set up frozen table
    -- -1 means off the board
    -- nil means empty
    local off_board = true
    for i = 0, 10 * 13 do
        off_board = i % 10 == 0 or i % 10 == 9
                or flr(i / 10) == 0
                or flr(i / 10) % 2 == 0 and i % 10 == 8

        if off_board then
            log(i .. " off board")
        end

        frozen[i] = off_board and -1 or nil
    end

    for chunk in all(split(level_one, ":")) do
        chunk = split(chunk, ",")
        color = deli(chunk)

        for i in all(chunk) do
            freeze_cell(i, color)
        end
    end

    reset_active()
end

function _update60()
    -- start new bubble when player presses space
    if btnp(5) then
        active_bubble.vx = cos(cannon.angle / 90) * active_bubble.speed
        active_bubble.vy = -sin(cannon.angle / 90) * active_bubble.speed
    end

    -- rotate cannon
    if btn(0) then
        cannon.angle = cannon.angle - cannon.speed
    elseif btn(1) then
        cannon.angle = cannon.angle + cannon.speed
    end

    -- apply gravity to falling bubbles
    for _, bubble in pairs(falling) do
        bubble.vy = min(bubble.vy + 0.1, 4)

        bubble.y += bubble.vy

        if bubble.y > 130 then
            log("bubble fell off screen")
            del(falling, bubble)
        end
    end

    check_falling()

    local collision = collide_frozen()

    if collision ~= nil then
        log("collision: " .. collision)

        falling_check = {
            cell = freeze_closest_neighbor(collision),
            color = active_bubble.color
        }

        reset_active()
    else
        new_x = active_bubble.x + active_bubble.vx
        new_y = active_bubble.y + active_bubble.vy

        -- bounce off walls
        if new_x <= walls.left.x1 or new_x >= cell_end.x - radius then
            new_x = mid(cell_start.x, new_x, cell_end.x - radius)
            active_bubble.vx = -active_bubble.vx
        end

        -- freeze at top
        if new_y <= walls.top.y1 then
            log("freeze at top " .. active_bubble.x .. ", " .. active_bubble.y)

            freeze_cell(
                flr(abs(active_bubble.x - cell_start.x) / diameter) + 11,
                active_bubble.color
            )

            reset_active()
        else
            active_bubble.x = new_x
            active_bubble.y = new_y
        end
    end
end

function _draw()
    cls(13)
    -- draw background

    -- walls
    for _, wall in pairs(walls) do
        rectfill(wall.x0, wall.y0, wall.x1, wall.y1, 6)
    end

    -- floor
    rectfill(0, 124, 128, 128, 4)

    -- draw cannon
    line(
        cannon.center_x, cannon.center_y,
        cannon.center_x + cos(cannon.angle / 90) * cannon.length,
        cannon.center_y - sin(cannon.angle / 90) * cannon.length,
        0
    )

    -- bubble draws should all happen at the same time
    -- so that the palette changes don't affect other draws

    -- draw falling bubbles
    for bubble in all(falling) do
        pal(1, bubble.color)
        sspr(0, 0, diameter, diameter, bubble.x, bubble.y)
    end

    -- draw frozen bubbles

    for cell, bubble in pairs(frozen) do
        if is_bubble(bubble) then
            pal(1, bubble.color)
            sspr(0, 0, diameter, diameter, bubble.x, bubble.y)
        end
    end

    -- draw active bubble

    pal(1, active_bubble.color)
    sspr(0, 0, diameter, diameter, active_bubble.x, active_bubble.y)

    --reset palette from bubble draws
    pal(1, 1)

    -- Debug cell numbers
    -- for i = 0, 10 * 13 - 1 do
    --     local x = i % 10 * diameter
    --             - flr(i / 10) % 2 * radius
    --             + cell_start.x
    --     local y = flr(i / 10) * (diameter - 1)
    --             + cell_start.y
    --     local color = frozen[i] == -1 and 8 or 3
    --     rect(x, y, x + diameter, y + diameter - 1, color)
    --     print(i % 100, x + 1, y + 1, 1)
    -- end
end

function is_bubble(bubble)
    return type(bubble) == "table"
            and bubble.x ~= nil
            and bubble.y ~= nil
            and bubble.color ~= nil
end

function cell_to_bubble(cell, color)
    log("cell_to_bubble: " .. cell)

    if frozen[cell] ~= nil then
        log("cell_to_bubble: " .. cell .. " frozen")

        return frozen[cell]
    end

    log("cell_to_bubble: " .. cell .. " not frozen")

    return {
        x = cell % 10 * diameter
                - flr(cell / 10) % 2 * radius
                + cell_start.x,
        y = flr(cell / 10) * (diameter - 1)
                + cell_start.y,
        color = color
    }
end

function freeze_cell(cell, color)
    -- log("freeze_cell: " .. cell)
    frozen[cell] = cell_to_bubble(cell, color)
    -- log("freeze_cell: " .. frozen[cell].x .. "," .. frozen[cell].y)
    frozen_count += 1
end

function thaw_cell(cell)
    if is_bubble(frozen[cell]) then
        -- log("freeze_cell: " .. cell)
        frozen[cell] = nil
        frozen_count -= 1
    end
end

function log(str)
    printh(str .. "\n", "bustin.txt")
end

function reset_active()
    -- choose a random color from the frozen colors
    local colors = Set.new()
    for _, bubble in pairs(frozen) do
        if is_bubble(bubble) then
            log("adding: " .. bubble.color)
            colors[bubble.color] = true
        end
    end

    log("size: " .. colors:get_size())

    colors = colors:get_all_items()
    log("colors: " .. #colors)

    local color = rnd(colors)

    log("chosen color: " .. color)

    active_bubble.x = cannon.center_x - 4
    active_bubble.y = cannon.center_y - 4
    active_bubble.vx = 0
    active_bubble.vy = 0
    active_bubble.color = color
end

function collide_frozen()
    for cell, bubble in pairs(frozen) do
        if is_bubble(bubble)
                and distance(active_bubble, bubble) <= diameter then
            return cell
        end
    end
end

function get_neighbor_cells(cell)
    local offset = flr(cell / 10) % 2

    return {
        cell - 1, -- left
        cell + 1, -- right
        cell - 10 - offset, -- above
        cell - 9 - offset,
        cell + 10 - offset, -- below
        cell + 11 - offset
    }
end

function freeze_closest_neighbor(cell)
    local closest = {
        cell = nil,
        bubble = nil,
        dist = 1000
    }
    local dist = nil
    local neighbor_bubble = nil
    local col_max = nil

    log("freeze_closest_neighbor: " .. cell)

    for neighbor_cell in all(get_neighbor_cells(cell)) do
        log("neighbor: " .. neighbor_cell)
        -- Only check neighbors that are on the board and not frozen
        if frozen[neighbor_cell] == nil then
            neighbor_bubble = cell_to_bubble(neighbor_cell, active_bubble.color)
            dist = distance(active_bubble, neighbor_bubble)

            if dist < closest.dist then
                closest = {
                    cell = neighbor_cell,
                    bubble = neighbor_bubble,
                    dist = dist
                }
            end
        end
    end

    frozen[closest.cell] = closest.bubble
    frozen_count += 1

    return closest.cell
end

fall_seen = {}

function check_falling()
    if falling_check ~= nil then
        log("check_falling: " .. falling_check.cell .. ", color:" .. falling_check.color)

        local filter = function(bubble)
            return bubble.color == falling_check.color
        end
        local fall_candidates = walk_frozen(
            falling_check.cell,
            Set.new(),
            filter
        )

        log("fall candidates: " .. fall_candidates:get_size())

        falling_check = nil

        if fall_candidates:get_size() >= 3 then
            for cell in pairs(fall_candidates.items) do
                log("falling: " .. cell)
                add(
                    falling, {
                        x = frozen[cell].x,
                        y = frozen[cell].y,
                        color = frozen[cell].color,
                        timer = 0,
                        vy = 0
                    }
                )
                thaw_cell(cell)
            end
        end

        local rooted = Set.new()

        for i = 10, 19 do
            if is_bubble(frozen[i]) then
                rooted = walk_frozen(i, rooted)
            end
        end

        for cell in pairs(frozen) do
            if is_bubble(frozen[cell]) and not rooted[cell] then
                log("falling unrooted: " .. cell)

                add(
                    falling, {
                        x = frozen[cell].x,
                        y = frozen[cell].y,
                        color = frozen[cell].color,
                        timer = 0,
                        vy = 0
                    }
                )

                thaw_cell(cell)
            end
        end
    end
end

function walk_frozen(cell, seen, filter)
    if not seen[cell] then
        if type(filter) ~= "function" then
            filter = function() return true end
        end

        seen[cell] = true

        for neighbor_cell in all(get_neighbor_cells(cell)) do
            if is_bubble(frozen[neighbor_cell])
                    and filter(frozen[neighbor_cell]) then
                seen = walk_frozen(neighbor_cell, seen, filter)
            end
        end
    end

    return seen
end

function distance(obj1, obj2)
    local x1 = obj1.x or obj1.col
    local y1 = obj1.y or obj1.row
    local x2 = obj2.x or obj2.col
    local y2 = obj2.y or obj2.row

    return sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2)
end

__gfx__
00011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01177111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01771111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
