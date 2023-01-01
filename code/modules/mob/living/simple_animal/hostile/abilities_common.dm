#define TOO_LOW_POP_FOR_MOB_HECK 10
#define RTS_GHOUL_ALLOWED list(\
		/mob/living/simple_animal/hostile/ghoul,\
		/mob/living/simple_animal/hostile/ghoul/reaver,\
		/mob/living/simple_animal/hostile/ghoul/zombie/glowing)
#define RTS_SMALLCRITTER_ALLOWED list(\
		/mob/living/simple_animal/hostile/gecko,\
		/mob/living/simple_animal/hostile/molerat,\
		/mob/living/simple_animal/hostile/bloatfly,\
		/mob/living/simple_animal/hostile/radroach)
#define RTS_ROBOT_ALLOWED list(\
		/mob/living/simple_animal/hostile/handy,\
		/mob/living/simple_animal/hostile/handy/protectron,\
		/mob/living/simple_animal/hostile/eyebot)



/datum/action/innate/ghostify
	name = "Ghostize"
	desc = "Leave this creature and return to your ghostly state."

/datum/action/innate/ghostify/IsAvailable(silent = FALSE)
	if(..())
		return TRUE

/datum/action/innate/ghostify/Activate()
	if(!isliving(owner))
		return
	var/mob/living/liver = owner
	liver.ghost()
	return TRUE

/obj/effect/proc_holder/mob_common
	name = "Mob Common Ability"
	desc = "Direct nearby mobs to go to a tile."
	panel = "Player Mob"
	active = FALSE
	action = null
	action_icon = 'icons/mob/actions.dmi'
	action_icon_state = "Chevron_State_0"

	var/list/allowed_mobs = list()
	var/banned_from_lowpop = FALSE

/obj/effect/proc_holder/mob_common/Initialize()
	. = ..()
	action = new(src)

/obj/effect/proc_holder/mob_common/Trigger(mob/user)
	if(!istype(user))
		return FALSE
	if(banned_from_lowpop && living_player_count() < TOO_LOW_POP_FOR_MOB_HECK)
		user.show_message(span_alert("There needs to be at least [TOO_LOW_POP_FOR_MOB_HECK] living players on to do this!"))
		return FALSE
	if(!is_available(user))
		return FALSE
	activate(user)
	return TRUE

/obj/effect/proc_holder/mob_common/proc/is_lowpop()
	return living_player_count() < TOO_LOW_POP_FOR_MOB_HECK

/// Toggles active and inactive
/obj/effect/proc_holder/mob_common/proc/activate(mob/living/user)
	return

/// Is it available?
/obj/effect/proc_holder/mob_common/proc/is_available(mob/living/user)
	if(user.stat != CONSCIOUS)
		return FALSE
	if(user.incapacitated())
		return FALSE
	return TRUE

/* 
 * Summons mobs to your side!
 */
/obj/effect/proc_holder/mob_common/summon_backup
	name = "Summon Backup"
	desc = "Draws friendly mobs nearby."
	action_icon = 'icons/mob/actions.dmi'
	action_icon_state = "velvet_chords"

/obj/effect/proc_holder/mob_common/summon_backup/ghoul
	allowed_mobs = RTS_GHOUL_ALLOWED
	banned_from_lowpop = TRUE

/obj/effect/proc_holder/mob_common/summon_backup/small_critter
	allowed_mobs = RTS_SMALLCRITTER_ALLOWED

/obj/effect/proc_holder/mob_common/summon_backup/robot
	allowed_mobs = RTS_ROBOT_ALLOWED
	banned_from_lowpop = TRUE

/obj/effect/proc_holder/mob_common/summon_backup/activate(mob/user)
	if(!istype(user, /mob/living/simple_animal))
		return
	if(user.incapacitated())
		return
	var/mob/living/simple_animal/owner = user

	var/turf/the_turf = get_turf(owner)
	if(!the_turf)
		return

	//playsound(get_turf(owner), 'sound/machines/chime.ogg', 50, 1, -1)
	owner.do_alert_animation(owner)
	var/list/who_to_check = list()
	var/allmobs = FALSE
	if(!LAZYLEN(allowed_mobs))
		allmobs = TRUE
	else if(is_lowpop())
		who_to_check = list(owner.type)
	else
		who_to_check = allowed_mobs
	for(var/mob/living/simple_animal/hostile/M in orange(6, get_turf(owner)))
		if(allmobs || (M.type in who_to_check))
			if(M.AIStatus == AI_OFF || M.stat == DEAD || M.ckey)
				continue
			M.Goto(user,M.move_to_delay,1)
			M.do_alert_animation(M)
	return TRUE

/* 
 * Directs mobs to where you click!
 */
/obj/effect/proc_holder/mob_common/direct_mobs
	name = "Send Mobs"
	desc = "Direct nearby mobs to go to a tile."
	panel = "Player Mob"
	active = FALSE
	action = null
	action_icon = 'icons/mob/actions.dmi'
	action_icon_state = "Chevron_State_0"

/obj/effect/proc_holder/mob_common/direct_mobs/update_icon()
	action.button_icon_state = "Chevron_State_[active]"
	action.UpdateButtonIcon()

/obj/effect/proc_holder/mob_common/direct_mobs/ghoul
	allowed_mobs = RTS_GHOUL_ALLOWED
	banned_from_lowpop = TRUE

/obj/effect/proc_holder/mob_common/direct_mobs/small_critter
	allowed_mobs = RTS_SMALLCRITTER_ALLOWED

/obj/effect/proc_holder/mob_common/direct_mobs/robot
	allowed_mobs = RTS_ROBOT_ALLOWED
	banned_from_lowpop = TRUE

/obj/effect/proc_holder/mob_common/direct_mobs/Trigger(mob/user)
	if(!..())
		return
	var/message
	if(active)
		user.show_message(span_notice("You decide not to direct any mobs."))
		remove_ranged_ability(message)
	else
		user.show_message(span_notice("You get ready to direct nearby mobs somewhere. <b>Click on a tile to send them!</b>"))
		add_ranged_ability(user, message, TRUE)
		return 1

/obj/effect/proc_holder/mob_common/direct_mobs/InterceptClickOn(mob/living/caller, params, atom/target)
	if(..())
		return
	if(ranged_ability_user.incapacitated())
		remove_ranged_ability()
		return

	var/mob/living/simple_animal/user = ranged_ability_user

	var/turf/the_turf = get_turf(target)
	if(!the_turf)
		remove_ranged_ability()
		return

	//playsound(get_turf(user), 'sound/machines/chime.ogg', 50, 1, -1)
	user.do_alert_animation(user)
	var/list/who_to_check = list()
	var/allmobs = FALSE
	if(!LAZYLEN(allowed_mobs))
		allmobs = TRUE
	else if(is_lowpop())
		who_to_check = list(user.type)
	else
		who_to_check = allowed_mobs
	for(var/mob/living/simple_animal/hostile/M in orange(6, get_turf(user)))
		if(allmobs || (M.type in who_to_check))
			if(M.AIStatus == AI_OFF || M.stat == DEAD || M.ckey)
				continue
			M.Goto(target,M.move_to_delay,1)
			M.do_alert_animation(M)
	remove_ranged_ability()
	return TRUE

/obj/effect/proc_holder/mob_common/direct_mobs/on_lose(mob/living/carbon/user)
	remove_ranged_ability()


/* 
 * Makes a nest!
 */
/obj/effect/proc_holder/mob_common/make_nest
	name = "Dig Nest"
	desc = "Dig down and tap into the endless underground resource that is monsters."
	var/obj/structure/nest/nest_to_spawn
	action_icon = 'icons/mob/nest_new.dmi'
	action_icon_state = "hole"
	COOLDOWN_DECLARE(nest_cooldown)

/obj/effect/proc_holder/mob_common/make_nest/gecko
	nest_to_spawn = /obj/structure/nest/gecko

/// Is it available?
/obj/effect/proc_holder/mob_common/make_nest/is_available(mob/living/user)
	if(!..())
		return FALSE
	if(COOLDOWN_TIMELEFT(src, nest_cooldown))
		user.show_message(span_alert("You can't do this for another <u>[(nest_cooldown-world.time)*0.1] seconds</u>."))
		return FALSE
	if(user.ckey && LAZYLEN(GLOB.player_made_nests[user.ckey]) >= 3)
		user.show_message(span_alert("You already have 3 active nests! Go remove some of them if you want more."))
		return FALSE
	return TRUE

/obj/effect/proc_holder/mob_common/make_nest/Trigger(mob/user)
	if(!..())
		return

	if(!istype(user))
		return

	if(user.incapacitated())
		return

	var/mob/living/simple_animal/owner = user
	if(!owner.ckey)
		return

	var/turf/the_turf = get_turf(owner)
	if(!the_turf)
		return
	
	var/obj/structure/nest/herenest = locate(/obj/structure/nest) in the_turf
	if(herenest)
		owner.show_message(span_alert("There's a nest here!"))
		return

	playsound(the_turf, 'sound/effects/shovel_dig.ogg', 50, 1)
	owner.visible_message(span_alert("[owner] starts to dig a hole..."))
	if(!do_after(owner, 10 SECONDS, FALSE, owner))
		owner.show_message(span_alert("You were interrupted!"))
		return

	var/obj/structure/nest/makenest = new nest_to_spawn(the_turf)
	makenest.register_ckey(owner.ckey)
	owner.visible_message(span_alert("[owner] digs a gross hole in the ground!"))
	playsound(the_turf, 'sound/effects/shovel_dig.ogg', 50, 1)
	COOLDOWN_START(src, nest_cooldown, 30 SECONDS)
	return TRUE


