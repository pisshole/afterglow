SUBSYSTEM_DEF(npcpool)
	name = "NPC Pool"
	flags = SS_KEEP_TIMING | SS_NO_INIT
	priority = FIRE_PRIORITY_NPC
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	wait = 10 // currently defines how often mobs attack and flip out
	// wait = 1 DECISECOND makes retreat/approach mobs just wiggle around in place and cheesegrate people

	var/list/currentrun = list()

/datum/controller/subsystem/npcpool/stat_entry(msg)
	var/list/activelist = GLOB.simple_animals[AI_ON]
	msg = "NPCS:[length(activelist)]"
	return ..()

/datum/controller/subsystem/npcpool/fire(resumed = FALSE)

	if (!resumed)
		var/list/activelist = GLOB.simple_animals[AI_ON]
		src.currentrun = activelist.Copy()

	//cache for sanic speed (lists are references anyways)
	var/list/currentrun = src.currentrun

	while(currentrun.len)
		var/mob/living/simple_animal/SA = currentrun[currentrun.len]
		--currentrun.len
		if(QDELETED(SA)) //sanity
			break
		if(!SA.ckey && !SA.mob_transforming)
			if(SA.stat != DEAD)
				SA.handle_automated_movement()
			if(SA.stat != DEAD)
				SA.handle_automated_action()
			if(SA.stat != DEAD)
				SA.handle_automated_speech()
		if (MC_TICK_CHECK)
			return
