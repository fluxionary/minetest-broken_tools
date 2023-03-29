local S = broken_tools.S
local f = string.format

function broken_tools.break_tool(itemstack)
	itemstack:set_wear(65535)
	item_description_monoid.monoid:add_change(itemstack, minetest.colorize("#ff0000", S("BROKEN")), "broken_tool")
	toolcap_monoids.dig_speed:add_change(itemstack, "disable", "broken_tool")
	toolcap_monoids.damage:add_change(itemstack, "disable", "broken_tool")
	return itemstack
end

function broken_tools.fix_tool(itemstack)
	item_description_monoid.monoid:del_change(itemstack, "broken_tool")
	toolcap_monoids.dig_speed:del_change(itemstack, "broken_tool")
	toolcap_monoids.damage:del_change(itemstack, "broken_tool")
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
				itemstack = broken_tools.break_tool(itemstack)
			else
				itemstack:add_wear(digparams.wear)
			end

			return itemstack
		end,
	})
end
