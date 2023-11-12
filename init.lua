item_monoids.check_version({ year = 2023, month = 3, day = 30 })

broken_tools = fmod.create()

broken_tools.dofile("api")
broken_tools.dofile("automatic_registration")

local blacklist_patterns = (broken_tools.settings.blacklist_patterns or ""):split("[, ]", false, -1, true)

for i = 1, #blacklist_patterns do
	broken_tools.blacklist(blacklist_patterns[i]:trim())
end
