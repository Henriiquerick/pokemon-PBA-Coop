extends "res://scripts/npc.gd"




const Trainers: = preload("res://scripts/trainers.gd")
const MonScript: = preload("res://scripts/stats/mon.gd")
const Items: = preload("res://scripts/items.gd")
const CapeFx: = preload("res://scripts/world/cape_fx.gd")
const BattleArena: = preload("res://scripts/battle_arena.gd")
const Rematch: = preload("res://scripts/rematch.gd")


const SIGHT_BLOCK_LAYERS: = 1 | 2

const SIGHT_HALF: = 0.9

const STOP_SHORT: = 1.2


const EYES_MEET: = {
	"team_rocket": "music/eyes_meet_bad_guy", 
	"lass": "music/eyes_meet_girl", "picnicker": "music/eyes_meet_girl", 
	"youngster": "music/eyes_meet_boy", "bug_catcher": "music/eyes_meet_boy", 
	"camper": "music/eyes_meet_boy", "super_nerd": "music/eyes_meet_boy", 
	"hiker": "music/eyes_meet_boy", "swimmer": "music/eyes_meet_boy", 
}



@export var trainer_id: = ""

@export var sight: = 5.0

var _def: = {}
var _alert: Label3D
var _spot_home: = Vector3.ZERO
var _spot_facing: = 0
var _spotting: = false
var _sight_cd: = 0.0


var _rm_icon: Label3D
var _rm_tier: = 0
var _rm_cd: = 0.0


func _ready() -> void :
	super._ready()
	if not is_inside_tree():
		return
	_def = Trainers.get_def(trainer_id)
	if not _def.is_empty():


		var hd: = String(_def.get("hidden_by_flag", ""))
		if hd != "" and Game.flags.get(hd, false):
			queue_free()
			return
		npc_name = Trainers.display_name(trainer_id)
		lines = PackedStringArray(_def.get("intro", []))
		if sight <= 0.0:
			sight = float(_def.get("sight", 5.0))
		_apply_disguise()
		if _def.get("astral", false):
			_apply_astral()
	_spot_home = global_position
	_spot_facing = start_facing
	_alert = Label3D.new()
	_alert.name = "Alert"
	_alert.text = "!"
	_alert.font_size = 96
	_alert.outline_size = 18
	_alert.modulate = Color(1.0, 0.85, 0.2)
	_alert.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_alert.no_depth_test = true


	var frame_h: = 0.0
	if sprite.texture:
		frame_h = float(sprite.texture.get_height()) / float(maxi(sprite.vframes, 1)) * sprite.pixel_size * 0.6
	_alert.position = Vector3(0, frame_h + 0.4, 0)
	_alert.visible = false
	add_child(_alert)
	if _def.has("rematch"):
		_rm_icon = _alert.duplicate() as Label3D
		_rm_icon.name = "RematchIcon"
		_rm_icon.text = "⚔"
		_rm_icon.font_size = 72
		_rm_icon.modulate = Color(0.55, 0.85, 1.0)
		add_child(_rm_icon)
		_refresh_rematch_icon()



func _advance(delta: float) -> void :
	super._advance(delta)
	if _sight_cd > 0.0:
		_sight_cd -= delta
	if _rm_icon != null:
		_rm_cd -= delta
		if _rm_cd <= 0.0:
			_refresh_rematch_icon()
	if _walk_target != null:
		return
	var p: = Dialogue.player()
	if p != null and can_see(p):
		_spot_sequence()






func can_see(p: Node3D) -> bool:
	var lan = get_node_or_null("/root/LanCampaign")
	if lan != null and lan.blocks_trainer(self): return false
	if _def.is_empty() or _spotting or talking or _beaten() or not _gate_open():
		return false
	if _sight_cd > 0.0 or Game.is_busy() or Battle.in_battle or Game.cutscene:
		return false
	if Debug.no_trainers:
		return false

	if p.has_method("is_flying") and p.is_flying():
		return false
	if Game.state.first_healthy() < 0:
		return false
	return _in_corridor(p) and _sight_clear(p)


func _in_corridor(p: Node3D) -> bool:
	var f: Vector3 = ROW_VEC[row]
	var to: Vector3 = p.global_position - global_position
	to.y = 0.0
	var along: = to.dot(f)
	if along <= 0.0 or along > sight:
		return false
	return absf(to.dot(Vector3( - f.z, 0.0, f.x))) <= SIGHT_HALF


func _sight_clear(p: Node3D) -> bool:
	var world: = get_viewport().world_3d if get_viewport() else null
	if world == null:
		return true
	var q: = PhysicsRayQueryParameters3D.create(
		global_position + Vector3(0, 1.0, 0), p.global_position + Vector3(0, 1.0, 0), SIGHT_BLOCK_LAYERS)
	var ex: Array[RID] = [get_rid()]
	if p is CollisionObject3D:
		ex.append(p.get_rid())
	q.exclude = ex
	return world.direct_space_state.intersect_ray(q).is_empty()




func _beaten() -> bool:
	var lan = get_node_or_null("/root/LanCampaign")
	if lan != null and trainer_id in lan.route_trainers: return false
	if trainer_id == "":
		return false
	if Game.flags.get("trainer_%s" % trainer_id, false):
		return true
	var off: = String(_def.get("disabled_by_flag", ""))
	return off != "" and bool(Game.flags.get(off, false))





func _gate_open() -> bool:
	var rq: = String(_def.get("requires_flag", ""))
	if rq != "" and not Game.flags.get(rq, false):
		return false
	for f in _def.get("gate", []):
		if not Game.flags.get(String(f), false):
			return false
	return true






func _spot_sequence() -> void :
	if _spotting:
		return
	_spotting = true
	var p: = Dialogue.player()
	if p == null:
		_spotting = false
		return
	Game.cutscene = true
	p.controls_enabled = false
	p.velocity = Vector3.ZERO
	p.face_toward(global_position)
	face(p.global_position - global_position)
	_alert.visible = true


	var sting: = String(EYES_MEET.get(String(_def.get("class", "")), "music/eyes_meet"))
	Audio.jingle(Audio.resolve([sting, "music/eyes_meet", "music/encounter"]))
	await get_tree().create_timer(0.7).timeout
	_alert.visible = false
	var to: Vector3 = p.global_position - global_position
	to.y = 0.0
	if to.length() > STOP_SHORT:
		await walk_to(global_position + to.normalized() * (to.length() - STOP_SHORT), 6.0)
	face(p.global_position - global_position)
	await _battle_sequence(true)



func talk_to(p: Node3D) -> PackedStringArray:
	talking = true
	_rm_tier = 0
	face(p.global_position - global_position)
	if _beaten():
		_rm_tier = _rematch_open()
		var rm: Dictionary = _def.get("rematch", {})
		if _rm_tier > 0:
			return PackedStringArray(rm.get("offer", ["..."]))
		if _rematches_won() > 0:
			return PackedStringArray(rm.get("after", _def.get("after", ["..."])))
		return PackedStringArray(_def.get("after", ["..."]))
	if not _gate_open():
		return PackedStringArray(_def.get("gate_line", lines))
	return lines



func finish_talk() -> void :
	talking = false
	if _rm_tier > 0 and not _spotting:
		await _offer_rematch()
		return
	if _beaten() or _spotting or not _gate_open():
		return
	await _battle_sequence(false)


func _battle_sequence(show_intro: bool) -> String:
	var lan = get_node_or_null("/root/LanCampaign")
	if lan != null:
		if lan.can_trigger(self): return await lan.trainer_encounter(self)
		_spotting = false
		Game.cutscene = false
		if Dialogue.player() != null: Dialogue.player().controls_enabled = true
		return "aborted"
	var p: = Dialogue.player()
	if p == null or (_beaten() and _rm_tier == 0):
		return "aborted"
	Game.cutscene = true
	p.controls_enabled = false
	if bool(_def.get("walk_in", false)):
		await _walk_in(p)
	var hud: = Game.get_hud()
	if _rm_tier > 0:
		return await _rematch_battle(p, hud)




	var ch: Dictionary = _def.get("challenge", {})
	var cflag: = String(ch.get("done_flag", ""))
	var in_challenge: bool = cflag != "" and not bool(Game.flags.get(cflag, false))
	if in_challenge:
		await _say(hud, ch.get("start", []), "", _face())
		for tid in ch.get("order", []):
			var other: = _find_trainer(String(tid))
			if other != null and not other._beaten():
				var child: String = await other._battle_sequence(false)



				if child != "won":
					return child

		Game.cutscene = true
		p.controls_enabled = false
		if _def.has("disguise_sprite"):

			await _turn_and_change(hud)
			show_intro = false
		else:
			_reveal()
			show_intro = true


	var seq: = _gym_sequence()


	var sequenced: = seq != null and _def.has("sequence_intro")\
	and (_def.has("thunder_border") or _def.has("pool_sequence"))
	if sequenced:
		show_intro = false
		if _def.has("pre_lines"):
			await _say(hud, _def["pre_lines"], "", _face())
		if not _def.has("pool_sequence"):
			await seq.pre_battle(self, _def)

	if show_intro and hud:
		hud.open_dialog(npc_name, lines, _face())
		await hud.dialog_closed
	var roster: = int(_def.get("roster", 0))
	if roster > 0 and hud and not Battle.autopilot:
		hud.open_dialog("", PackedStringArray([
			"GYM RULE: only %d of your POKéMON may fight here." % roster, 
			"Pick them as you go. If both are knocked out,\nyou lose and forfeit the prize money."]))
		await hud.dialog_closed
	var scripted: = bool(_def.get("scripted", false))
	if _def.has("reward"):
		Game.state.reward_override = int(_def["reward"])
	var opts: = _battle_opts(p)
	if sequenced and is_instance_valid(seq):
		opts = seq.battle_opts(opts)
	var result: String = await Battle.start_trainer_battle(self, npc_name, _mons(), opts)
	Game.state.reward_override = -1
	if sequenced and is_instance_valid(seq):


		await seq.post_battle(result)
	if result == "lost" and not scripted and not Battle.roster_lost:


		return result
	if result == "won":
		Game.flags["trainer_%s" % trainer_id] = true



		var meet: = _meet_targets()
		if not meet.is_empty():
			_start_meet(meet[0], meet[1])

		if not meet.is_empty():
			await _meet_arrive(meet[0], meet[1])
		if _def.has("badge"):
			await _award_badge(hud, String(_def["badge"]))
		if _def.has("gift"):
			await _award_gift(hud, String(_def["gift"]))

		if not _def.get("post_speech", []).is_empty():
			await _say(hud, _def.get("post_speech", []))
		if _def.has("post_gift"):
			await _award_gift(hud, String(_def["post_gift"]), "post_gift_speech")
		if bool(_def.get("vanish", false)):
			await _vanish_in_flare()
		if _def.has("after_event"):
			Story.trigger(String(_def["after_event"]), null)
	elif not _def.get("lose", []).is_empty():
		await _say(hud, _def.get("lose", []))
	if result == "lost" and Battle.roster_lost and hud:
		hud.open_dialog("", PackedStringArray([
			"Both of your POKéMON were knocked out!", 
			"The prize money is forfeit. Heal up, pick\nyour %d fighters wisely and try again." % int(_def.get("roster", 0))]))
		await hud.dialog_closed
	if in_challenge:
		Game.flags[cflag] = true
	if _def.has("done_flag"):
		Game.flags[String(_def["done_flag"])] = true
	if result == "won" and _def.has("won_flag"):
		Game.flags[String(_def["won_flag"])] = true
	if bool(_def.get("leave_after", false)):
		await _leave_and_free()
		return result


	_spotting = false
	Game.cutscene = false
	var np: = Dialogue.player()
	if np:
		np.controls_enabled = true
	_return_home()
	return result




func _battle_opts(_p: Node3D) -> Dictionary:
	var opts: = {"trainer_class": String(_def.get("class", ""))}
	var vs: = Trainers.versus_opts(trainer_id)
	if not vs.is_empty():
		opts["versus"] = vs

	opts["defeat"] = _def.get("defeat", [])
	opts["face"] = _face()


	var marker: = String(_def.get("center", ""))
	if marker != "":
		var sc: = get_tree().current_scene
		var m: Node = sc.find_child(marker, true, false) if sc else null
		if m is Node3D:
			opts["center"] = (m as Node3D).global_position


	var hs = _def.get("human_spots")
	if hs is Array and hs.size() >= 2:
		var hsc: = get_tree().current_scene
		var m0: Node = hsc.find_child(String(hs[0]), true, false) if hsc else null
		var m1: Node = hsc.find_child(String(hs[1]), true, false) if hsc else null
		if m0 is Node3D and m1 is Node3D:
			opts["human_spots"] = [(m0 as Node3D).global_position, (m1 as Node3D).global_position]


	var dd = _def.get("discs")
	if dd is Dictionary and dd.get("markers") is Array:
		var dsc: = get_tree().current_scene
		var pos: Array = []
		for mn in dd.markers:
			var dm: Node = dsc.find_child(String(mn), true, false) if dsc else null
			if dm is Node3D:
				pos.append(Vector2((dm as Node3D).global_position.x, (dm as Node3D).global_position.z))
		if pos.size() == (dd.markers as Array).size():
			opts["discs"] = pos
			opts["disc_partners"] = dd.get("partners", [])
	var ar = _def.get("arena")
	if ar is Array and ar.size() >= 2:
		opts["arena"] = Vector2(float(ar[0]), float(ar[1]))


	var ax = _def.get("axis")
	if ax is Array and ax.size() >= 2:
		opts["axis"] = Vector3(float(ax[0]), 0.0, float(ax[1]))
	if _def.has("ai_think_scale"):
		opts["ai_think_scale"] = float(_def["ai_think_scale"])
	if _def.has("roster"):
		opts["roster"] = int(_def["roster"])
	if _def.has("ai_tier"):


		opts["ai_tier"] = String(_def["ai_tier"])
		if _rm_tier > 0:
			opts["ai_tier"] = Rematch.ai_tier(opts["ai_tier"], _rm_tier)
		opts["trainer_id"] = trainer_id
	if _def.has("item"):
		opts["item"] = String(_def["item"])
	if _def.has("frame_pad"):


		opts["frame_pad"] = float(_def["frame_pad"])
	if _def.has("field"):

		opts["field"] = String(_def["field"])
	if _def.has("foe_offset"):
		var fo: Array = _def["foe_offset"]
		opts["foe_offset"] = Vector2(float(fo[0]), float(fo[1]))
	if _def.has("arena_color"):

		opts["arena_color"] = Color(String(_def["arena_color"]))
	if _def.has("type_bonus"):
		opts["type_bonus"] = _def["type_bonus"]
	if _def.has("thunder_border"):

		var tb = _def["thunder_border"]
		opts["thunder_border"] = float(tb) if (tb is float or tb is int) else (
			BattleArena.BORDER_WIDTH if bool(tb) else 0.0)
	if bool(_def.get("scripted", false)):
		opts["scripted"] = true
	if _def.has("lose"):

		opts["lose"] = _def.get("lose", [])
	if _def.has("intro_text"):
		opts["intro_text"] = String(_def["intro_text"])
	return opts




func _rematches_won() -> int:
	return int(Game.flags.get("rematch_%s" % trainer_id, 0))



func _team_avg() -> int:
	var lv: Array = []
	for m in Game.state.party:
		if not m.egg:
			lv.append(m.level)
	return Rematch.team_avg(lv)



func _rematch_open() -> int:
	if not _def.has("rematch") or not _beaten():
		return 0
	return Rematch.open_tier(_def, _rematches_won(), _team_avg())




func current_party() -> Array:
	var t: = _rematch_open()
	if t > 0:
		return Rematch.party(_def, t, _team_avg())
	if _rematches_won() > 0:
		return Rematch.party(_def, _rematches_won(), 999)
	return _def.get("party", [])


func _refresh_rematch_icon() -> void :
	_rm_cd = 1.0
	if _rm_icon != null:
		_rm_icon.visible = _rematch_open() > 0 and not Battle.in_battle



func _offer_rematch() -> void :
	var hud: = Game.get_hud()
	var rm: Dictionary = _def.get("rematch", {})
	if hud == null or not await hud.ask_yes_no(npc_name, String(rm.get("ask", "Rematch?"))):
		_rm_tier = 0
		return
	await _battle_sequence(false)



func _rematch_battle(p: Node3D, hud) -> String:
	var rm: Dictionary = _def.get("rematch", {})
	var tier: = _rm_tier
	_rm_icon.visible = false
	var intro: Array = rm.get("intro_final", []) if tier >= Rematch.max_tiers(_def) else []
	if intro.is_empty():
		intro = rm.get("intro", [])


	var it: Dictionary = rm.get("intro_tier", {})
	for k in it:
		var parts: = String(k).split("@")
		if int(parts[0]) == tier and (parts.size() == 1 or bool(Game.flags.get(parts[1], false))):
			intro = it[k]
			if parts.size() > 1:
				break
	if not intro.is_empty():
		await _say(hud, intro, "", _face())

	var roster: = int(Rematch.by_tier(rm.get("roster", {}), tier, _def.get("roster", 0)))
	if roster > 0 and hud and not Battle.autopilot:
		await _say(hud, ["GYM RULE: only %d of your POKéMON may fight here." % roster])
	var ropts: = _battle_opts(p)
	ropts["defeat"] = rm.get("defeat", _def.get("defeat", []))
	if roster > 0:
		ropts["roster"] = roster

	var seq: = _gym_sequence() if _def.has("pool_sequence") else null
	if seq != null:
		ropts = seq.battle_opts(ropts)
	var result: String = await Battle.start_trainer_battle(self, npc_name, _mons(), ropts)
	if seq != null and is_instance_valid(seq):
		await seq.post_battle(result)
	_rm_tier = 0
	if result == "lost" and not bool(_def.get("scripted", false)) and not Battle.roster_lost:
		return result
	if result == "won":
		Game.flags["rematch_%s" % trainer_id] = tier
	elif result == "lost" and Battle.roster_lost and hud:
		await _say(hud, ["Your %d POKéMON were knocked out!" % roster if roster > 1 else "Your POKéMON was knocked out!", 
			"The prize money is forfeit. Heal up, pick\nyour fighters wisely and try again."])
	_spotting = false
	Game.cutscene = false
	var np: = Dialogue.player()
	if np:
		np.controls_enabled = true
	_refresh_rematch_icon()
	_return_home()
	return result



func _gym_sequence() -> Node:
	if get_tree() == null:
		return null
	return get_tree().get_first_node_in_group("gym_sequence")



func _find_trainer(tid: String) -> Node:
	if get_tree() == null:
		return null
	for n in get_tree().get_nodes_in_group("npc"):
		if n != self and n.get("trainer_id") == tid:
			return n
	return null






const ASTRAL_TINT: = Color(0.62, 0.52, 1.0)


func _apply_astral() -> void :
	CapeFx.serum_on(self, ASTRAL_TINT)
	bob_height = 0.14
	bob_speed = 2.2
	if sprite == null:
		return
	sprite.modulate = Color(0.86, 0.82, 1.0, 0.72)
	var tw: = create_tween().set_loops()
	tw.tween_property(sprite, "modulate:a", 0.52, 0.9).set_trans(Tween.TRANS_SINE)
	tw.tween_property(sprite, "modulate:a", 0.82, 1.1).set_trans(Tween.TRANS_SINE)
	tw.tween_property(sprite, "modulate:a", 0.66, 0.15)
	tw.tween_property(sprite, "modulate:a", 0.78, 0.2)






func _apply_disguise() -> void :
	var dis: = String(_def.get("disguise_sprite", ""))
	if dis == "" or sprite == null:
		return
	var done: = String(_def.get("challenge", {}).get("done_flag", ""))
	if done != "" and bool(Game.flags.get(done, false)):
		return
	var tex: Texture2D = load("res://assets/sprites/%s" % dis)
	if tex:
		sprite.texture = tex



func _reveal() -> void :
	var real: = String(_def.get("sprite", ""))
	if real == "" or sprite == null:
		return
	var tex: Texture2D = load("res://assets/sprites/%s" % real)
	if tex:
		sprite.texture = tex




func _walk_in(p: Node3D) -> void :
	var sc: = get_tree().current_scene
	var m: Node = sc.find_child(String(_def.get("center", "")), true, false) if sc else null
	if not m is Node3D:
		return
	var c: Vector3 = (m as Node3D).global_position
	await p.walk_to(Vector3(c.x, p.global_position.y, c.z), 4.0)
	if is_inside_tree():
		p.face_toward(global_position)
		face(p.global_position - global_position)






func _meet_targets() -> Array:
	if not _def.has("meet"):
		return []
	var p: = Dialogue.player()
	var sc: = get_tree().current_scene
	var m: Node = sc.find_child(String(_def.get("center", "")), true, false) if sc else null
	if p == null or not m is Node3D:
		return []
	var c: Vector3 = (m as Node3D).global_position
	return [Vector3(c.x, global_position.y, c.z - 0.9), Vector3(c.x, p.global_position.y, c.z + 0.9)]




func _start_meet(mine: Vector3, theirs: Vector3) -> void :
	var p: = Dialogue.player()
	if p != null and p.global_position.distance_to(theirs) > 0.15:
		p.walk_to(theirs, 6.0, 3.0)
	await walk_to(mine, 8.0)
	if is_inside_tree():
		face(theirs - mine)



func _meet_arrive(mine: Vector3, theirs: Vector3) -> void :
	var p: = Dialogue.player()
	var t: = 0.0
	while is_inside_tree() and t < 8.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		var p_here: bool = p == null or \
		Vector2(p.global_position.x - theirs.x, p.global_position.z - theirs.z).length() < 0.3
		if _walk_target == null and p_here:
			break
	if not is_inside_tree():
		return
	face(theirs - mine)
	if p != null:
		p.face_toward(mine)





func _turn_and_change(hud) -> void :
	var p: = Dialogue.player()
	var to_p: Vector3 = p.global_position - global_position if p != null else Vector3(0, 0, 1)
	to_p.y = 0.0
	await _say(hud, _def.get("intro", []))
	await _say(hud, [String(_def.get("refuse", "No thanks."))], Game.state.player_name)
	if _def.has("refuse_answer"):
		await _say(hud, _def["refuse_answer"])
	face( - to_p)
	await get_tree().create_timer(0.25).timeout
	_reveal()
	await get_tree().create_timer(0.2).timeout
	face(to_p)






func _face() -> String:
	return String(Trainers.versus_opts(trainer_id).get("foe", ""))


func _say(hud, lines, speaker: = "", face: = "") -> void :
	if hud == null:
		return
	hud.open_dialog(speaker if speaker != "" else npc_name, PackedStringArray(lines), face)
	await hud.dialog_closed




func _award_badge(hud, badge: String) -> void :
	var first: = not Game.state.badges.has(badge)
	if first:
		Game.state.badges.append(badge)
	Game.flags["%s_badge" % badge] = true

	if first:
		AnalyticsBeats.beat("badge_earned", {"badge": badge, "leader": trainer_id, 
			"badges": Game.state.badges.size()})
	Audio.jingle("music/badge_get")
	var nm: = String(_def.get("name", npc_name)).to_upper()
	await _say(hud, ["%s received the %s BADGE from %s!" % [Game.state.player_name, badge.to_upper(), nm]])

	if not _def.get("badge_speech", []).is_empty():
		await _say(hud, _def.get("badge_speech", []))



func _award_gift(hud, id: String, speech_key: = "gift_speech") -> void :


	var key: = "gift_" + id
	if bool(Game.flags.get(key, false)):
		return
	Game.flags[key] = true
	Game.state.add_item(id, 1)
	Audio.jingle("music/key_item")
	await _say(hud, ["%s received %s!" % [Game.state.player_name, Items.item_name(id)]])
	if not _def.get(speech_key, []).is_empty():
		await _say(hud, _def.get(speech_key, []))




func _vanish_in_flare() -> void :
	_spotting = false
	for i in 5:
		var at: Vector3 = global_position + Vector3(randf_range(-0.5, 0.5), 0.55, randf_range(-0.5, 0.5))
		Vfx.pmd_fx("smoke_black", at, Vector3(0, 0, 1), {"scale": 0.9 + float(i) * 0.15})
	var spr: = get("sprite") as Sprite3D
	if spr != null:
		var tw: = create_tween()
		tw.tween_property(spr, "modulate", Color(1.0, 0.35, 0.2, 0.0), 0.7)
		await tw.finished
	if _def.has("won_flag"):
		Game.flags[String(_def["won_flag"])] = true
	queue_free()




func _leave_and_free() -> void :
	_spotting = false


	if not bool(_def.get("leave_locked", false)):
		Game.cutscene = false
		var np: = Dialogue.player()
		if np:
			np.controls_enabled = true
	var path = _def.get("leave_path")
	if path is Array and not path.is_empty():
		for point in path:
			await walk_to(Vector3(float(point[0]), global_position.y, float(point[1])), 10.0)
			if not is_inside_tree(): return
		queue_free()
		return
	var local = _def.get("leave_local")
	if local is Array and not local.is_empty():
		await _leave_by_hidden_door(local)
		return
	var to = _leave_target()
	if to is Array and to.size() >= 2:
		await walk_to(Vector3(float(to[0]), global_position.y, float(to[1])), 10.0)
	queue_free()





func _leave_by_hidden_door(local: Array) -> void :
	var room: = get_parent() as Node3D
	if room == null:
		queue_free()
		return
	var doors: Array = []
	for c in room.get_node("Props").get_children():
		if String(c.name).begins_with(String(_def.get("leave_door", "�"))):
			doors.append(c)
	for i in local.size():
		var wp = local[i]
		await walk_to(room.global_position + Vector3(float(wp[0]), 0.0, float(wp[1])), 10.0)
		if not is_inside_tree():
			return
		if i == int(_def.get("leave_press", -1)):
			await get_tree().create_timer(0.35).timeout
			Audio.play("sfx/world/door")
			for d in doors:
				if is_instance_valid(d):
					d.visible = false
	await get_tree().create_timer(0.3).timeout
	for d in doors:
		if is_instance_valid(d):
			d.visible = true
	Audio.play("sfx/world/door")
	queue_free()





func _leave_target() -> Variant:
	var br = _def.get("leave_branch")
	var p: = Dialogue.player()
	if br is Dictionary and p != null:
		var tx: = int(floor((p.global_position.x - float(br.get("ox", 0.0))) / float(br.get("s", 1.0))))
		if br.has(str(tx)):
			return br[str(tx)]
	return _def.get("leave_to")


func _return_home() -> void :
	if global_position.distance_to(_spot_home) > 0.2:
		await walk_to(_spot_home, 8.0)
	if not is_inside_tree():
		return
	_sight_cd = 1.0
	row = _spot_facing
	if is_instance_valid(sprite):
		sprite.frame = display_row() * 3


static func apply_specimen(m, spec: Dictionary) -> void :
	if spec.has("nature"):
		m.nature = String(spec.nature)
	for key in ["ivs", "evs"]:
		var d = spec.get(key)
		if d is Dictionary:
			var out: Dictionary = m.get(key)
			for s in d:
				out[String(s)] = int(d[s])
	m.recalc()
	m.heal_full()





func _mons() -> Array:
	var out: Array = []
	var party: Array = _def.get("party", [])
	var by_flag: Dictionary = _def.get("parties", {})
	if _rm_tier > 0:
		party = Rematch.party(_def, _rm_tier, _team_avg())
	elif not by_flag.is_empty():
		party = by_flag.get(String(Game.flags.get(String(_def.get("party_flag", "")), "")), party)
	var slot: = -1
	for e in party:
		slot += 1
		if e is Array and e.size() >= 2:
			var sp: = String(e[0])
			if sp.begins_with("@"):
				sp = String(Game.flags.get(sp.substr(1), ""))
			if sp == "":
				continue






			var rng: = RandomNumberGenerator.new()
			rng.seed = hash("%s:%d" % [trainer_id, slot])
			var m = MonScript.create(sp, int(e[1]), rng)
			var rng2: = RandomNumberGenerator.new()
			rng2.seed = hash("%s:%d:ability" % [trainer_id, slot])
			m.ability_slot = 1 if rng2.randf() < 0.5 and m._sp().get("abilities", []).size() >= 2 else 0


			if e.size() >= 3 and e[2] is Array and not (e[2] as Array).is_empty():
				m.moves = (e[2] as Array).duplicate()


			if e.size() >= 4 and e[3] is Dictionary:
				apply_specimen(m, e[3])
			m.owner = npc_name
			out.append(m)
	return out
