local S = broken_tools.S
local f = string.format

local function play_breaking_sound(tool, pos)
	local definition = tool:get_definition()
	local sound_breaks = (definition.sound or {}).breaks or "default_tool_breaks"
	if pos then
		minetest.sound_play(sound_breaks, {
			pos = pos,
			gain = 0.5,
		}, true)
	end
end

function broken_tools.break_tool(toolstack, pos)
	assert(toolstack:is_known() and not toolstack:is_empty())
	local definition = toolstack:get_definition()
	assert(definition.type == "tool")
	toolstack:set_wear(65535)
	item_description_monoid.monoid:add_change(toolstack, minetest.colorize("#ff0000", S("BROKEN")), "broken_tool")
	toolcap_monoids.dig_speed:add_change(toolstack, "disable", "broken_tool")
	toolcap_monoids.damage:add_change(toolstack, "disable", "broken_tool")
	play_breaking_sound(toolstack, pos)
	return toolstack
end

function broken_tools.fix_tool(toolstack)
	assert(toolstack:is_known() and not toolstack:is_empty())
	local definition = toolstack:get_definition()
	assert(definition.type == "tool")
	item_description_monoid.monoid:del_change(toolstack, "broken_tool")
	toolcap_monoids.dig_speed:del_change(toolstack, "broken_tool")
	toolcap_monoids.damage:del_change(toolstack, "broken_tool")
	return toolstack
end

function broken_tools.register(name)
	local def = minetest.registered_items[name]
	if not def then
		error(f("attempt to register unknown tool %s", name))
	end
	local after_use = def.after_use
	minetest.override_item(name, {
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
				itemstack = broken_tools.break_tool(itemstack, user:get_pos())
			else
				itemstack:add_wear(digparams.wear)
			end

			return itemstack
		end,
	})
end

minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
	local tool = puncher:get_wielded_item()
	if item_description_monoid.monoid:value(tool, "broken_tool") then
		play_breaking_sound(tool, puncher:get_pos())
	end
end)
