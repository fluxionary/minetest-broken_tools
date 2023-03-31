local function is_finite_uses(def)
	local toolcaps = def.tool_capabilities or {}
	if toolcaps.punch_attack_uses and toolcaps.punch_attack_uses > 0 then
		return true
	end
	for group, caps in pairs(toolcaps.groupcaps or {}) do
		if caps.uses and caps.uses > 0 then
			return true
		end
	end
	return false
end

minetest.register_on_mods_loaded(function()
	for name, def in pairs(minetest.registered_tools) do
		if minetest.get_item_group(name, "breakable_tool") == 0 and is_finite_uses(def) then
			broken_tools.register(name)
		end
	end
end)
