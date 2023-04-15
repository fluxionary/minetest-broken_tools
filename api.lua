local S = broken_tools.S
local f = string.format

local function play_breaking_sound(tool, user)
	local definition = tool:get_definition()
	local sound_breaks = (definition.sound or {}).breaks or "default_tool_breaks"

	minetest.sound_play(sound_breaks, {
		pos = user:get_pos(),
		gain = 0.5,
	}, true)
end

function broken_tools.is_broken(toolstack)
	return description_monoids.description:value(toolstack, "broken_tool")
end

function broken_tools.break_tool(toolstack, user)
	assert(toolstack:is_known() and not toolstack:is_empty())
	if broken_tools.is_broken(toolstack) then
		return toolstack
	end
	local definition = toolstack:get_definition()
	assert(definition.type == "tool")
	local short_description = futil.get_safe_short_description(toolstack)
	toolstack:set_wear(65535)
	description_monoids.description:add_change(toolstack, {
		prefix = minetest.colorize("#000000", S("BROKEN")),
		colorize = "#000000",
		bgcolor = "#FF0000",
	}, "broken_tool")
	toolcap_monoids.dig_speed:add_change(toolstack, "disable", "broken_tool")
	toolcap_monoids.damage:add_change(toolstack, "disable", "broken_tool")
	if user then
		play_breaking_sound(toolstack, user)
		broken_tools.chat_send_player(
			user,
			"your @1 has broken! but it can be repaired on an anvil.",
			short_description
		)
	end
	return toolstack
end

function broken_tools.fix_tool(toolstack)
	assert(toolstack:is_known() and not toolstack:is_empty())
	if not broken_tools.is_broken(toolstack) then
		return toolstack
	end
	local definition = toolstack:get_definition()
	assert(definition.type == "tool")
	description_monoids.description:del_change(toolstack, "broken_tool")
	toolcap_monoids.dig_speed:del_change(toolstack, "broken_tool")
	toolcap_monoids.damage:del_change(toolstack, "broken_tool")
	return toolstack
end

function broken_tools.register(name)
	local def = minetest.registered_tools[name]
	if not def then
		error(f("attempt to register unknown tool %s", name))
	end
	local groups = table.copy(def.groups or {})
	groups.breakable_tool = 1
	local after_use = def.after_use
	local new_def = {
		groups = groups,
		after_use = function(itemstack, user, node, digparams)
			local broken = false
			if after_use then
				local rv = after_use(ItemStack(itemstack), user, node, digparams)
				if not rv then
					return
				elseif rv:is_empty() then
					broken = true
				else
					itemstack = rv
				end
			end
			local wear = itemstack:get_wear()
			broken = broken or (65536 - wear) <= digparams.wear
			if broken then
				itemstack = broken_tools.break_tool(itemstack, user)
			else
				itemstack:add_wear(digparams.wear)
			end

			return itemstack
		end,
	}
	local on_use = def.on_use
	if on_use then
		function new_def.on_use(itemstack, user, pointed_thing)
			if broken_tools.is_broken(itemstack) then
				play_breaking_sound(itemstack, user)
				return
			end
			local rv = on_use(ItemStack(itemstack), user, pointed_thing)
			if rv and rv:is_empty() then
				return broken_tools.break_tool(itemstack, user)
			else
				return rv
			end
		end
	end
	local on_place = def.on_place
	if on_place then
		function new_def.on_place(itemstack, placer, pointed_thing, param2)
			if pointed_thing.type == "node" and placer and not placer:get_player_control().sneak then
				local pos = pointed_thing.under
				local n = minetest.get_node(pos)
				local nn = n.name
				local node_def = minetest.registered_nodes[nn] or {}
				if node_def.on_rightclick then
					return node_def.on_rightclick(pos, n, placer, itemstack, pointed_thing) or itemstack, nil
				end
			end

			if broken_tools.is_broken(itemstack) then
				play_breaking_sound(itemstack, placer)
				return
			end

			if itemstack:get_definition().type == "node" then
				return minetest.item_place_node(itemstack, placer, pointed_thing, param2)
			end

			local rv = on_place(ItemStack(itemstack), placer, pointed_thing)

			if rv and rv:is_empty() then
				return broken_tools.break_tool(itemstack, placer)
			else
				return rv
			end
		end
	end
	local on_secondary_use = def.on_secondary_use
	if on_secondary_use then
		function new_def.on_secondary_use(itemstack, user, pointed_thing)
			if broken_tools.is_broken(itemstack) then
				play_breaking_sound(itemstack, user)
				return
			end
			local rv = on_secondary_use(ItemStack(itemstack), user, pointed_thing)
			if rv and rv:is_empty() then
				return broken_tools.break_tool(itemstack, user)
			else
				return rv
			end
		end
	end
	minetest.override_item(name, new_def)
end

minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
	local tool = puncher:get_wielded_item()
	if broken_tools.is_broken(tool) then
		if tool:get_wear() == 65535 then
			play_breaking_sound(tool, puncher)
		else
			-- in case the player fixed it somehow
			broken_tools.fix_tool(tool)
		end
	end
end)
