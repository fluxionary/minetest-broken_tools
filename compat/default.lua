if not broken_tools.has.default then
	return
end

local f = string.format

local kinds = { "axe", "pick", "shovel", "sword" }
local materials = { "bronze", "diamond", "mese", "steel", "stone", "wood" }

for _, kind in ipairs(kinds) do
	for _, material in ipairs(materials) do
		broken_tools.register(f("default:%s_%s", kind, material))
	end
end
