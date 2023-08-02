Set = {}
Set.__index = function(self, item)
    -- First check if the key exists in the metatable
    if Set[item] ~= nil then
        return Set[item]
    end

    -- If it doesn't, check the items table
    return self.items[item] ~= nil and item
end

Set.__newindex = function(self, item, value)
    if value and self.items[item] == nil then
        self.items[item] = true
        self.size = self.size + 1
    end
end

-- Get the number of items in the set
function Set:get_size()
    return self.size
end

-- Create a new set
function Set.new()
    return setmetatable({ items = {}, size = 0 }, Set)
end

function Set:get_all_items()
    local items = {}
    for item in pairs(self.items) do
        add(items, item)
    end
    return items
end