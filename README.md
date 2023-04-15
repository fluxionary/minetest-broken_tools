# broken_tools

when a tool breaks, instead of it disappearing, it turns into an unusable "broken" version. the broken version
can be repaired on an anvil. however, currently, only the anvil in flux's fork of cottages is compatible.

broken_tools automatically integrates w/ "normal" tools (wear applied when breaking nodes). other tools may be
registered through the API. note that some wear from unusual sources, e.g. punching mobs from mobs_redo, may break
tools in a way that this mod cannot detect or handle.



#### API

* `broken_tools.register(name)`

  registers a tool to behave according to the broken tool mechanic.

* `broken_tools.is_broken(toolstack)`

  returns true if the tool is broken, otherwise false.

* `broken_tools.break_tool(toolstack, user)`

  transforms a tool into a broken version. wear will be set to 65535.

* `broken_tools.fix_tool(toolstack)`

  repair a broken tool. note that this does *not* change the wear. that is the responsibility of the calling mod.
