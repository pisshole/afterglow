/**
  * CLICKDELAY HANDLING SYSTEM
  * How this works is mobs can never do actions until their next_action is at or below world.time, but things can specify extra cooldown
  * to check for either from the time of last_action or from the end of next_action.
  *
  * Clickdelay should always be checked via [CheckActionCooldown()], never manually!
  */

/mob
	// CLICKDELAY AND RELATED
	/// Generic clickdelay variable. Marks down the last world.time we did something that should cause or impact generic clickdelay. This should be directly set or set using [DelayNextAction()]. This should only be checked using [CheckActionCooldown()].
	var/last_action = 0
	/// Generic clickdelay variable. Next world.time we should be able to do something that respects generic clickdelay. This should be set using [DelayNextAction()] This should only be checked using [CheckActionCooldown()].
	var/next_action = 0
	/// Simple modification variable added to next action on adjust. This should only be manually modified via addition.
	var/next_action_adjust = 0
	/// Simple modification variable multiplied to next action modifier on adjust. This should only be manually modified using multipliers.
	var/next_action_mult = 1
	/// Simple modification variable added to amount when checking time since last action using [CheckActionCooldown()]. This should only be manually modified via addition.
	var/last_action_adjust = 0
	/// Simple modification variable multiplied to amount when checking time since last action using [CheckActionCooldown()]. This should only be manually modified using multipliers.
	var/last_action_mult = 1
	
	/// Special clickdelay variable for resisting. Last time we did a special action like resisting. This should be directly set.  This should only be checked using [CheckResistCooldown()].
	var/last_resist = 0
	/// How long we should wait before allowing another resist. This should only be manually modified using multipliers.
	var/resist_cooldown = CLICK_CD_RESIST

/**
  * Applies a delay to next_action before we can do our next action.
  *
  * @params
  * * amount - Amount to delay by
  * * ignore_mod - ignores next action adjust and mult
  * * considered_action - Defaults to TRUE - If TRUE, sets last_action to world.time.
  */
/mob/proc/DelayNextAction(amount = 0, ignore_mod = FALSE, considered_action = TRUE)
	if(considered_action)
		last_action = world.time
	next_action = max(next_action, world.time + (ignore_mod? amount : (amount * next_action_mult + next_action_adjust)))

/**
  * Checks if we can do another action.
  * Returns TRUE if we can and FALSE if we cannot.
  *
  * @params
  * * cooldown - Time required since last action. Defaults to 0.5
  * * from_next_action - Defaults to FALSE. Should we check from the tail end of next_action instead of last_action?
  * * ignore_mod - Defaults to FALSE. Ignore all adjusts and multipliers. Do not use this unless you know what you are doing and have a good reason.
  * * ignore_next_action - Defaults to FALSE. Ignore next_action and only care about cooldown param and everything else. Generally unused.
  */
/mob/proc/CheckActionCooldown(cooldown = 0.5, from_next_action = FALSE, ignore_mod = FALSE, ignore_next_action = FALSE)
	return (ignore_next_action || (world.time >= next_action)) && (world.time >= ((from_next_action? next_action : last_action) + max(0, ignore_mod? cooldown : (cooldown * last_action_mult + last_action_adjust))))

/**
  * Checks if we can resist again.
  */
/mob/proc/CheckResistCooldown()
	return (world.time >= (last_resist + resist_cooldown))

/atom
	// Standard clickdelay variables
	/// Amount of time to check for from a mob's last attack to allow an attack_hand().
	var/clickdelay_attack_hand_preattack_cooldown = CLICK_CD_MELEE
	/// Should we set last action before or after attack hand passes?
	var/clickdelay_attack_hand_set_preattack = FALSE
	/// Should we set last action for attack hand?
	var/clickdelay_attack_hand_is_action = FALSE

/obj/item
	// Standard clickdelay variables
	/// Amount of time to check for from a mob's last attack, checked before an attack happens
	var/preattack_cooldown_check = CLICK_CD_MELEE
	/// Amount of time to delay a mob's next attack, added after an attack happens
	var/postattack_cooldown_penalty = 0
	/// This item bypasses any click delay mods
	var/clickdelay_mod_bypass = FALSE
	/// This item checks clickdelay from a user's delayed next action variable rather than the last time they attacked.
	var/clickdelay_from_next_action = FALSE
	/// This item ignores next action delays.
	var/clickdelay_ignores_next_action = FALSE
	/// This item sets clickdelay in preattack rather than post attack. This means it's set in a melee attack even if the user doesn't bash or bop it against something.
	var/clickdelay_set_on_pre_attack = FALSE

/**
  * Checks if a user's clickdelay is met for a standard attack
  */
/obj/item/proc/PreattackClickdelayCheck(mob/user, atom/target)
	return user.CheckActionCooldown(action_cooldown_preattack, clickdelay_from_next_action, clickdelay_mod_bypass, clickdelay_ignores_next_action)

/**
  * Called if check is successful before the attack happens.
  */
/obj/item/proc/PreattackClickdelaySet(mob/user, atom/target)
	if(clickdelay_set_on_pre_attack)
		user.DelayNextAction(0, FALSe, TRUE)

/**
  * Called after a successful attack to set a mob's clickdelay.
  */
/obj/item/proc/PostattackClickdelaySet(mob/user, atom/target)
	user.DelayNextAction(postattack_cooldown_penalty, clickdelay_mod_bypass, FALSE)
