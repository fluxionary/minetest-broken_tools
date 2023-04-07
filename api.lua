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

function broken_tools.break_tool(toolstack, user)
	assert(toolstack:is_known() and not toolstack:is_empty())
	local definition = toolstack:get_definition()
	assert(definition.type == "tool")
	local short_description = futil.get_safe_short_description(toolstack)
	toolstack:set_wear(65535)
	description_monoids.description:add_change(toolstack, {
		prefix = S("BROKEN"),
		colorize = "#FFFFFF",
		bgcolor = "#FF0000",
	}, "broken_tool")
	description_monoids.short_description:add_change(toolstack, {
		prefix = S("BROKEN"),
		colorize = "#FFFFFF",
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
	local definition = toolstack:get_definition()
	assert(definition.type == "tool")
	description_monoids.monoid:del_change(toolstack, "broken_tool")
	toolcap_monoids.dig_speed:del_change(toolstack, "broken_tool")
	toolcap_monoids.damage:del_change(toolstack, "broken_tool")
	return toolstack
end

function broken_tools.register(name)
	local def = minetest.registered_items[name]
	if not def then
		error(f("attempt to register unknown tool %s", name))
	end
	local groups = table.copy(def.groups or {})
	groups.breakable_tool = 1
	local after_use = def.after_use
	minetest.override_item(name, {
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
	})
end

minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
	local tool = puncher:get_wielded_item()
	if description_monoids.monoid:value(tool, "broken_tool") then
		if tool:get_wear() == 65535 then
			play_breaking_sound(tool, puncher)
		else
			broken_tools.fix_tool(tool)
		end
	end
end)
