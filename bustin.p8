pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

walls = {
    left = {
        x0 = 21, y0 = 6,
        x1 = 23, y1 = 123
    },
    right = {
        x0 = 105, y0 = 6,
        x1 = 107, y1 = 123
    },
    top = {
        x0 = 21, y0 = 3,
        x1 = 107, y1 = 5
    },
    bottom = {
        x0 = 24, y0 = 106,
        x1 = 104, y1 = 108
    }
}

cannon = {
    center_x = 64,
    center_y = 112,
    length = 15,
    angle = 68,
    speed = 0.5
}

radius = 5
diameter = radius * 2

frozen = {}

active_bubble = {
    x = cannon.center_x - 4,
    y = cannon.center_y - 4,
    color = 11,
    speed = 2,
    vx = nil,
    vy = nil
}

debug = ""

function _init()
    cls()
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

    if active_bubble.vx != nil then
        local collision = collide_frozen()

        if collision then
            freeze_closest_neighbor(collision)

            reset_active()
        else
            new_x = active_bubble.x + active_bubble.vx
            new_y = active_bubble.y + active_bubble.vy

            if new_x <= walls.left.x1 or new_x >= walls.right.x0 - radius then
                new_x = mid(walls.left.x1 + 1, new_x, walls.right.x0 - radius - 1)
                active_bubble.vx = -active_bubble.vx
            end

            if new_y <= walls.top.y1 then
                local to_freeze = {
                    x = round((active_bubble.x - walls.left.x1 + 1) / diameter) * diameter + walls.left.x1 + 1,
                    y = walls.top.y1 + 1,
                    color = active_bubble.color
                }

                -- freeze bubble at top
                add(frozen, to_freeze)

                reset_active()
            else
                active_bubble.x = new_x
                active_bubble.y = new_y
            end
        end
    end
end

function log(str)
    if #debug > 0 then
        debug = debug .. "\n"
    end

    debug = debug .. str
end

function round(num)
    return flr(num + 0.5)
end

function _draw()
    cls(13)
    draw_background()
    draw_cannon()

    -- bubble draws should all happen at the same time
    -- so that the palette changes don't affect other draws

    for _cell, bubble in pairs(frozen) do
        -- print("frozen " .. bubble.x .. ", " .. bubble.y, 7)
        draw_bubble(bubble)
    end

    draw_bubble(active_bubble)

    --reset palette from bubble draws
    pal(1, 1)

    if debug then
        print(debug, 0, 0, 0)
    end
end

function draw_background()
    for _, wall in pairs(walls) do
        draw_wall(wall)
    end

    -- floor
    rectfill(0, 124, 128, 128, 4)
end

function draw_wall(wall)
    rectfill(wall.x0, wall.y0, wall.x1, wall.y1, 6)
end

function draw_bubble(bubble)
    pal(1, bubble.color)
    sspr(0, 0, diameter, diameter, bubble.x, bubble.y)
end

function reset_active()
    active_bubble.x = cannon.center_x - 4
    active_bubble.y = cannon.center_y - 4
    active_bubble.vx = nil
    active_bubble.vy = nil
end

function collide_frozen()
    for bubble in all(frozen) do
        if distance(active_bubble, bubble) <= diameter then
            return bubble
        end
    end
end

function add_frozen(cell, color)
    add(frozen, update_from_cell({ color = color }, cell), cell)
end

function update_from_cell(bubble, cell)
    bubble.x = walls.left.x1 + 1
            + cell.col * diameter + cell.row % 2 * radius
    bubble.y = walls.top.y1 + 1
            + cell.row * (diameter - 1)
end

neighbor_directions = {
    { x = -diameter, y = 0 }, --left
    { x = diameter, y = 0 }, -- right
    { x = radius, y = 1 - diameter }, --up and right
    { x = -radius, y = 1 - diameter }, --up and left
    { x = -radius, y = diameter - 1 }, -- down and left
    { x = radius, y = diameter - 1 } -- down and right
}

function freeze_closest_neighbor(bubble)
    local closest = nil
    local closest_dist = 1000
    local dist = nil

    for direction in all(neighbor_directions) do
        local neighbor = {
            x = bubble.x + direction.x,
            y = bubble.y + direction.y,
            color = bubble.color
        }

        -- Only check neighbors that are on the board and not frozen
        if neighbor.x >= walls.left.x1
                and neighbor.x <= walls.right.x0 - diameter
                and neighbor.y >= walls.top.y1
                and frozen[neighbor] == nil then
            dist = distance(active_bubble, neighbor)

            if dist < closest_dist then
                closest = neighbor
                closest_dist = dist
            end
        end
    end

    add(frozen, closest)
end

function distance(bubble1, bubble2)
    return sqrt((bubble1.x - bubble2.x) ^ 2
            + (bubble1.y - bubble2.y) ^ 2)
end

function draw_cannon()
    -- draw cannon
    line(
        cannon.center_x, cannon.center_y,
        cannon.center_x + cos(cannon.angle / 90) * cannon.length,
        cannon.center_y - sin(cannon.angle / 90) * cannon.length,
        0
    )
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
