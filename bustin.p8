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

cell_start = {
    x = walls.left.x1 + 1,
    y = walls.top.y1 + 1
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

radius = 5
diameter = radius * 2

frozen_count = 0
frozen = {}

colors = { 3, 4, 8, 9, 10, 14 }

active_bubble = {
    x = cannon.center_x - 4,
    y = cannon.center_y - 4,
    color = rnd(colors),
    speed = 2,
    vx = 0,
    vy = 0
}

falling_check = nil

falling_bubbles = {}

debug = ""

function _init()
    cls()

    freeze_cell({ col = 0, row = 0 }, 3)
    freeze_cell({ col = 0, row = 1 }, 3)
    freeze_cell({ col = 0, row = 2 }, 3)
    freeze_cell({ col = 1, row = 0 }, 3)
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

    check_falling()

    local collision = collide_frozen()

    if collision then
        falling_check = { cell = collision, color = active_bubble.color }

        freeze_closest_neighbor(collision)

        reset_active()
    else
        new_x = active_bubble.x + active_bubble.vx
        new_y = active_bubble.y + active_bubble.vy

        if new_x <= walls.left.x1 or new_x >= cell_end.x - radius then
            new_x = mid(cell_start.x, new_x, cell_end.x - radius)
            active_bubble.vx = -active_bubble.vx
        end

        if new_y <= walls.top.y1 then
            freeze_cell(bubble_to_cell(active_bubble), active_bubble.color)

            reset_active()
        else
            active_bubble.x = new_x
            active_bubble.y = new_y
        end
    end
end

function cell_to_ball(cell, color)
    return {
        x = cell_start.x
                + cell.col * diameter + cell.row % 2 * radius,
        y = cell_start.y
                + cell.row * (diameter - 1),
        color = color
    }
end

function bubble_to_cell(ball)
    return {
        col = round(abs(ball.x - cell_start.x) / diameter),
        row = round(abs(ball.y - cell_start.y) / (diameter - 1))
    }
end

function freeze_cell(cell, color)
    frozen[cell] = cell_to_ball(cell, color)
    frozen_count += 1
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
    active_bubble.vx = 0
    active_bubble.vy = 0
    active_bubble.color = rnd(colors)
end

function collide_frozen()
    for cell, bubble in pairs(frozen) do
        if distance(active_bubble, bubble) <= diameter then
            return cell
        end
    end
end

function add_frozen(cell, color)
    add(frozen, update_from_cell({ color = color }, cell), cell)
end

function update_from_cell(bubble, cell)
    bubble.x = cell_start.x
            + cell.col * diameter + cell.row % 2 * radius
    bubble.y = cell_start.y
            + cell.row * (diameter - 1)
end

neighbor_cells = {
    { col = -1, row = 0 }, --left
    { col = 1, row = 0 }, -- right
    { col = 1, row = -1 }, --up and right
    { col = -1, row = -1 }, --up and left
    { col = -1, row = 1 }, -- down and left
    { col = 1, row = 1 } -- down and right
}

function freeze_closest_neighbor(cell)
    local closest = nil
    local closest_dist = 1000
    local dist = nil
    local active_cell = bubble_to_cell(active_bubble)

    for direction in all(neighbor_cells) do
        local neighbor = {
            col = cell.col + direction.col,
            row = cell.row + direction.row
        }

        -- Only check neighbors that are on the board and not frozen
        if neighbor.col >= 0
                and neighbor.col <= 7
                and neighbor.row >= 0
                and frozen[neighbor] == nil then
            dist = distance(active_cell, neighbor)

            if dist < closest_dist then
                closest = neighbor
                closest_dist = dist
            end
        end
    end

    freeze_cell(closest, active_bubble.color)
end

function check_falling()
    if falling_check then
        local cells = { falling_check.cell }
        local i = 1

        while i <= #cells do
            for direction in all(neighbor_cells) do
                local neighbor = {
                    col = cells[i].col + direction.col,
                    row = cells[i].row + direction.row
                }

                if neighbor.col >= 0
                        and neighbor.col <= 7
                        and neighbor.row >= 0
                        and frozen[neighbor] ~= nil
                        and frozen[neighbor].color == falling_check.color then
                    add(cells, neighbor)
                end
            end

            i += 1
        end

        if #cells >= 3 then
            for cell in all(cells) do
                add(falling_bubbles, frozen[cell])

                frozen[cell] = nil
            end
        end

        falling_check = nil

        log("falling " .. #falling_bubbles)
    end
end

function distance(obj1, obj2)
    local x1 = obj1.x or obj1.col
    local y1 = obj1.y or obj1.row
    local x2 = obj2.x or obj2.col
    local y2 = obj2.y or obj2.row

    return sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2)
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
