extends Node
signal combatant_joined(creature)








const HerdScript: = preload("res://scripts/world/herd.gd")
const BossAdds: = preload("res://scripts/combat/boss_adds.gd")
const TargetRing: = preload("res://scripts/target_ring.gd")
const CastScale: = preload("res://scripts/combat/cast_scale.gd")
const FinaleAi: = preload("res://scripts/story/finale_ai.gd")
const SafariFightScript: = preload("res://scripts/safari_fight.gd")
const BattleVersus: = preload("res://scripts/ui/battle_versus.gd")
const PokemonSprites: = preload("res://scripts/pokemon_sprites.gd")
const CreatureDef: = preload("res://scripts/creature.gd")
const CaptureFX: = preload("res://scripts/capture_fx.gd")
const BattleArena: = preload("res://scripts/battle_arena.gd")
const ItemsData: = preload("res://scripts/items.gd")
const Growth: = preload("res://scripts/stats/growth.gd")
const DexData: = preload("res://scripts/dex.gd")
const MonScript: = preload("res://scripts/stats/mon.gd")
const TrainerLevel: = preload("res://scripts/stats/trainer_level.gd")
const UiKit: = preload("res://scripts/ui/kit/ui_kit.gd")
const Fields: = preload("res://scripts/fields.gd")
const DebugScript: = preload("res://scripts/debug.gd")


const WILD_OPENING_DELAY: = 0.5




const SPEED_FAST: = 1.0
const SPEED_SLOW: = 0.8

const ARENA_SIZE: = 12.0

const BATTLE_CAM_EXTRA: = 2.0



const FRAME_PAD: = 0.8

const ARENA_CAM_DIST: = 14.0


const WATER_LAND_BAR: = 0.4


const ARENA_BLOCK_LAYERS: = 1 | 2

const BATTLE_SIZE: = 2

const PICK_SLOWMO: = 0.12




var _slow_users: = 0
var _slow_base: = 1.0



func _slow_in(factor: float) -> void :
	_slow_users += 1
	if _slow_users == 1:
		_slow_base = Engine.time_scale
		Engine.time_scale = _slow_base * factor



func _slow_out() -> void :
	_slow_users = maxi(_slow_users - 1, 0)
	if _slow_users == 0:
		Engine.time_scale = _slow_base

const ALLY_TIER: = "mid"

const CALLOUT_COL: = Color(0.957, 0.922, 0.765)




func _zone_look() -> Dictionary:
	var s: = get_tree().get_first_node_in_group("zone_streamer")
	return s.active_look() if s and s.has_method("active_look") else {}


func _battle_cam_dist() -> float:
	var look: = _zone_look()
	if look.has("battle_camera_distance"):
		return float(look["battle_camera_distance"])
	var rig: = get_tree().get_first_node_in_group("camera_rig")
	if rig and rig.has_method("_base_dist"):
		return float(rig._base_dist()) + BATTLE_CAM_EXTRA
	return ARENA_CAM_DIST







const WIDE_CAMERA_PAD: = 3.0


func _cam_fighters() -> Array:
	if _wide_camera():
		return []
	return allies + guest_allies + [wild] + extra_foes


func _wide_camera() -> bool:
	return is_instance_valid(wild) and bool(wild.get("static_wide_camera"))


func _focus_fighters(cam: Node3D, a: Vector3, b: Vector3) -> void :
	var mid: = (a + b) * 0.5
	var box: = Vector2(absf(a.x - b.x), absf(a.z - b.z)) + Vector2.ONE * (FRAME_PAD * 2.0)
	cam.focus_fixed(mid, _fit_cam_dist(box))







func _fit_cam_dist(asz: Vector2, pad: = FRAME_PAD) -> float:
	var base: = _battle_cam_dist()
	var rig: = Dialogue.camera_rig()
	if rig == null or rig.camera == null:
		return base
	var ax: Array = rig._cam_axes()
	var unit: Vector2 = rig.visible_ground(1.0)
	var fwd_c: = maxf(minf(unit.x, - unit.y), 0.05)
	var vp: Vector2 = rig.get_viewport().get_visible_rect().size if rig.is_inside_tree() else Vector2(16, 9)
	var side_c: = tan(deg_to_rad(rig.camera.fov) * 0.5) * maxf(vp.x / maxf(vp.y, 1.0), 0.35)


	var fit: = func(hx: float, hz: float) -> float:
		var fwd: = absf(hx * ax[0].x) + absf(hz * ax[0].z)
		var side: = absf(hx * ax[1].x) + absf(hz * ax[1].z)
		return maxf(fwd / fwd_c, side / side_c)
	var half: = asz * 0.5


	if fit.call(half.x, half.y) <= base and pad <= FRAME_PAD:
		return base
	half += Vector2.ONE * (BattleArena.TRAINER_STAND_OFF + pad)
	return maxf(base, fit.call(half.x, half.y))

var in_battle: = false

var pay_day_money: = 0

var safari: Node = null


var speed: = SPEED_FAST

var trainer_battle: = {}



var online: = false
var online_guest: = false

var challenge: = false
var training: = false
var partner: CreatureDef
var no_capture: = false
var guest_queue: Array = []
var guest_trainer: Node3D


var guest_lines: Array = []


var boss_hook: Callable = Callable()

var field_type_mult: Dictionary = {}


var ai_hazard: Callable = Callable()

var guest_tier: = ""
var guest_item: = ""
var ally_acc_mult: = 1.0
var max_fighters: = 0
var guest_allies: Array = []
var no_whiteout: = false



var roster_lost: = false
var extra_foes: Array = []
var allies: Array = []
var wild: CreatureDef
var _ambush: = false

var _static_uid: = ""

var _adds_pending: Array = []

var _target_ring: Node = null
var _target_ring_for: Node = null
var _intro: = false
var _intro_skip: = false

var _battle_paused: = false

var _fight_tweens: Array = []
var _hidden: = {}
var _arena: Node3D

var _lead_spot: = Vector3.INF
var _lead_blocked: = Callable()

var arena_rect: = Rect2()

var _arena_cleared: Array = []


var _arena_deferred: Array = []

const TOMB_BODY_RADIUS: = 0.4


var wild_frame_pad: = FRAME_PAD

var grass_battle: = false

var _field_fx_ids: Array = []

var debug_field: = ""
var debug_wet: = false

var _room_field: = ""




var wild_music: = ""
var wild_arena: = Vector2.ZERO
var wild_arena_center: = Vector3.INF


var _wild_arena_from_body: = false


var thunder_border: = 0.0



var teleport_discs: Array = []
var disc_partners: Array = []
var disc_ready: Array = []
const DiscView: = preload("res://scripts/vfx_teleport_discs.gd")
var _disc_view: Node3D

var type_bonus: Array = []
var _combatants: Array = []
var _ending: = false
var _switching: = false

var _foe_switching: = false
var _ko_entry: = false


const FREE_SWITCH_WINDOW: = 10.0
var free_switch_t: = 0.0
var _free_entry: = false

var _participants: Array = []

var _exp_results: Array = []
var _ev_results: Dictionary = {}

var _foe_levels: Array = []

var _awaiting_confirm: = false

var autopilot: = false





var tut_locked: = false
var tut_move: = -1
var tut_walk: = false
var tut_hold_foe: = false


var tut_soft_hits: = false


var pause_for_evolution: = false




var _an_on: = false
var _an_started_ms: = 0
var _an_moves: = {}
var _an_hits_landed: = 0
var _an_hits_taken: = 0
var _an_switches: = 0
var _an_items: = 0
var _an_jumps: = 0
var _an_kind: = ""
var _an_trainer_id: = ""


var _an_static_uid: = ""
var _an_attempts: = {}



func clear_tut_lock() -> void :
	tut_locked = false
	tut_move = -1
	tut_walk = false
	tut_hold_foe = false
	tut_soft_hits = false


func _ready() -> void :
	Game.battle_started.connect(_an_battle_started)
	Game.battle_ended.connect(_an_battle_ended)
	Game.item_used.connect(_an_item_used)


	_connect_moves.call_deferred()


func _connect_moves() -> void :
	get_node("/root/Moves").knocked_out.connect(_on_knocked_out)





func _on_knocked_out(user, target) -> void :
	if not in_battle or not training or target != wild:
		return
	if not is_instance_valid(user) or not allies.has(user):
		return
	user.gain_evs_from(wild)





const MODAL_SLOW: = 0.2






func fight_speed() -> float:
	if in_battle and _picking:
		return 0.0
	if not in_battle or _intro or _ending:
		return 1.0
	if online or online_guest:
		return 1.0
	if _battle_paused:
		return 0.0
	if Progression._capturing:
		return 1.0
	if ( not challenge and Controls.items_page_held()) or ( not challenge and _ring_open()):
		return MODAL_SLOW
	return 1.0





func move_speed() -> float:
	var s: = fight_speed()
	if s <= 0.0:
		return 0.0

	if not in_battle or _intro or _ending or online or online_guest or Progression._capturing:
		return s
	return s * speed




var _swap_said: = ""




func request_loadout_swap(c: Node) -> bool:
	var lan = get_node_or_null("/root/LanCampaign")
	if lan != null and lan.coop_battle_active(): return false
	var why: = loadout_swap_blocked(c)
	if why != "":
		if why != "busy":
			_say_swap(why)
		return false
	var hud = Game.get_hud()
	var bh = hud.get("battle_hud") if hud != null else null
	if bh != null and bh.has_method("begin_loadout_flip") and not bh.flipping():
		bh.begin_loadout_flip()
		return true
	return commit_loadout_swap(c)



func loadout_swap_blocked(c: Node) -> String:
	if not is_instance_valid(c) or c.mon == null or c.combat == null:
		return "busy"
	if not TrainerLevel.second_loadout_unlocked(Game.state.trainer_level()):
		return "SECOND LOADOUT UNLOCKS AT TRAINER LV %d" % TrainerLevel.loadout2_level()
	if not c.combat.can_act() or not c.combat.cast_move.is_empty():
		return "busy"
	if c.mon.loadout(1 - int(c.combat.loadout)).is_empty():
		return "LOADOUT %d IS EMPTY" % (2 - int(c.combat.loadout))
	return ""



func commit_loadout_swap(c: Node) -> bool:
	var lan = get_node_or_null("/root/LanCampaign")
	if lan != null and lan.coop_battle_active(): return false
	if not is_instance_valid(c) or c.mon == null or c.combat == null:
		return false
	var mon = c.mon
	var other: = 1 - int(c.combat.loadout)
	if mon.loadout(other).is_empty():
		return false
	mon.active_loadout = other
	c.combat.set_loadout(other)
	c.combat.gcd_duration = c.combat.LOADOUT_SWAP_CD
	c.combat.gcd_t = c.combat.gcd_duration / maxf(c.combat.recovery_factor(), 0.01)
	Audio.play_at("sfx/ui/swap_control", c.global_position, 0.0)
	Analytics.track("loadout_swapped", {"species": mon.species, "loadout": other})
	return true



func swap_loadout(c: Node) -> bool:
	if loadout_swap_blocked(c) != "":
		return false
	return commit_loadout_swap(c)



func _say_swap(text: String) -> void :
	var hud = Game.get_hud()
	if hud == null or not hud.has_method("popup"):
		return
	if _swap_said == text:
		return
	_swap_said = text
	hud.popup(text, UiKit.AMBER)


func close_party_ring() -> void :
	var h: = Game.get_hud()
	if h == null:
		return
	var ring = h.get("party_ring")
	if ring != null:
		ring.close()



func _ring_open() -> bool:
	var h: = Game.get_hud()
	if h == null:
		return false
	var ring: = h.get_node_or_null("party_ring")
	return ring != null and ring.is_open







func fight_scale() -> float:
	var s: = fight_speed()
	return 1.0 / s if s > 0.0 else 1.0






func fight_timer(secs: float) -> SceneTreeTimer:
	return get_tree().create_timer(secs * fight_scale())







func fight_wait(secs: float) -> void :
	var left: = secs
	while left > 0.0:
		await get_tree().process_frame


		left -= get_process_delta_time() * fight_speed()







func fight_tween(n: Node) -> Tween:
	var s: = fight_speed()
	var tw: = n.create_tween().set_speed_scale(s if s > 0.0 else 1.0)
	if s <= 0.0:
		tw.pause()
	_fight_tweens.append(tw)

	tw.finished.connect( func() -> void : _fight_tweens.erase(tw))
	return tw




func set_paused(v: bool) -> void :
	if _battle_paused == v:
		return
	_battle_paused = v
	if v:
		_prune_fight_tweens()
		for tw in _fight_tweens:
			tw.pause()
	else:
		_play_fight_tweens()


func _play_fight_tweens() -> void :
	_prune_fight_tweens()
	for tw in _fight_tweens:
		tw.play()


func _prune_fight_tweens() -> void :
	var keep: Array = []
	for tw in _fight_tweens:
		if tw != null and tw.is_valid():
			keep.append(tw)
	_fight_tweens = keep





func can_pause_menu() -> bool:
	if not in_battle:
		return true
	return not (_ending or _intro or _switching or _foe_switching or Progression._capturing)









func _process(_delta: float) -> void :
	_sync_cast_scale(_delta)
	if free_switch_t > 0.0:
		free_switch_t = maxf(free_switch_t - _delta * fight_speed(), 0.0) if in_battle and not _ending else 0.0
	if online_guest:
		return
	if not _arena_deferred.is_empty():
		_tick_deferred_tombs()
	if not _adds_pending.is_empty() and in_battle and not _intro and not _ending:
		_check_boss_adds()
	_update_target_ring()



func _update_target_ring() -> void :
	var t: Node = null
	if in_battle and not _intro and not _ending and is_instance_valid(partner):
		var live: = foes()
		if live.size() >= 2 and live.has(partner.opponent):
			t = partner.opponent
	if t == _target_ring_for and (t == null or is_instance_valid(_target_ring)):
		return
	if is_instance_valid(_target_ring):
		_target_ring.queue_free()
	_target_ring = null
	_target_ring_for = t
	if t != null:
		_target_ring = TargetRing.make(t)




var cast_scale: = 1.0
var cast_scale_override: = 0.0
var _cast_bodies: Array = []
var _cast_sprites: Array = []
var _cast_props: Array = []



func cast_scale_target() -> float:
	if not in_battle or arena_rect.size.x <= 0.0:
		return 1.0
	return _cast_k_for(arena_rect.size)




func fit_cast(c: Node) -> void :
	if not is_instance_valid(c) or not c.has_method("set_cast_scale"):
		return
	var size: Vector2 = arena_rect.size if arena_rect.size.x > 0.0 else Vector2(trainer_battle.get("arena", Vector2.ZERO))
	if size.x <= 0.0:
		return
	c.set_cast_scale(_cast_k_for(size))
	if not _cast_bodies.has(c):
		_cast_bodies.append(c)



func _cast_k_for(size: Vector2) -> float:
	if online or online_guest:
		return 1.0
	return cast_scale_override if cast_scale_override > 0.0 else CastScale.factor(size)


func _sync_cast_scale(delta: float) -> void :
	var k: = cast_scale_target()


	DexData.set_dist_scale(k)
	if is_equal_approx(k, 1.0) and is_equal_approx(cast_scale, 1.0) and _cast_bodies.is_empty() and _cast_sprites.is_empty()\
	and _cast_props.is_empty():
		return

	cast_scale = lerpf(cast_scale, k, 1.0 - exp( - delta * CastScale.EASE_RATE))
	if absf(cast_scale - k) < 0.002:
		cast_scale = k

	RenderingServer.global_shader_parameter_set("cast_shrink", cast_scale if CastScale.SHRINK_WORLD else 1.0)
	if in_battle:
		for b in [partner, wild] + allies + extra_foes + guest_allies:
			if is_instance_valid(b) and not _cast_bodies.has(b):
				_cast_bodies.append(b)
	var a: = 1.0 - exp( - delta * CastScale.EASE_RATE)
	for b in _cast_bodies.duplicate():
		if not is_instance_valid(b):
			_cast_bodies.erase(b)
			continue
		var bk: float = lerpf(b.cast_scale, k, a)
		b.set_cast_scale(k if absf(bk - k) < 0.002 else bk)
	if is_equal_approx(cast_scale, 1.0) and is_equal_approx(k, 1.0):
		for b in _cast_bodies:
			b.set_cast_scale(1.0)
		_cast_bodies.clear()
		for n in _cast_sprites:
			if is_instance_valid(n):
				CastScale.restore_sprite(n)
		_cast_sprites.clear()
		for n in _cast_props:
			if is_instance_valid(n):
				CastScale.restore_node(n)
		_cast_props.clear()
		return
	for n in _cast_sprites:
		if is_instance_valid(n):
			CastScale.apply_sprite(n, cast_scale)
	if CastScale.SHRINK_WORLD and _cast_props.is_empty() and k < 1.0 and arena_rect.size.x > 0.0:
		var around: = arena_rect.grow(CastScale.PROP_MARGIN)
		for n in get_tree().get_nodes_in_group("cast_prop"):
			if n is Node3D and around.has_point(Vector2(n.global_position.x, n.global_position.z)):
				_cast_props.append(n)
	for n in _cast_props:
		if is_instance_valid(n):
			CastScale.apply_node(n, cast_scale)
	if _cast_sprites.is_empty() and k < 1.0:
		var near: = arena_rect.grow(CastScale.NPC_MARGIN)
		var people: Array = [Dialogue.player()]
		for n in get_tree().get_nodes_in_group("npc"):
			if n is Node3D and not (n is CreatureDef)\
			and near.has_point(Vector2(n.global_position.x, n.global_position.z)):
				people.append(n)
		for n in people:
			if is_instance_valid(n):
				CastScale.apply_sprite(n, cast_scale)
				_cast_sprites.append(n)




func _check_boss_adds() -> void :
	if not is_instance_valid(wild) or wild.mode == CreatureDef.Mode.FAINTED:
		return
	for spec in _adds_pending.duplicate():
		if extra_foes.size() >= 2:
			return
		if BossAdds.due(spec, int(wild.hp), int(wild.max_hp), false):
			_adds_pending.erase(spec)
			_join_add(spec)


func _join_add(spec: Dictionary) -> void :
	var p: = Dialogue.player()
	if p == null or not is_instance_valid(partner):
		return

	var center: Vector3 = wild_arena_center if wild_arena_center.is_finite() else wild.global_position
	var half: = (wild_arena * 0.5) if wild_arena.x > 0.0 else Vector2(5.0, 5.0)
	var away: = center - partner.global_position
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else Vector3.BACK
	var at: = center + away * minf(half.x, half.y) * 0.8
	if not extra_foes.is_empty():
		at += Vector3( - away.z, 0.0, away.x) * 2.0
	at.x = clampf(at.x, center.x - half.x + 0.6, center.x + half.x - 0.6)
	at.z = clampf(at.z, center.z - half.y + 0.6, center.z + half.y - 0.6)
	var ground: = Transitions.ground_y(at, wild.global_position.y)
	var e: CreatureDef
	if spec.has("moves") or spec.has("specimen"):

		var am = preload("res://scripts/stats/mon.gd").create(String(spec.species), int(spec.level))
		if spec.has("moves"):
			am.moves = Array(spec.moves)
		if spec.has("specimen"):
			am.ivs = spec.specimen.ivs.duplicate()
			am.nature = spec.specimen.nature
			am.recalc()
			am.heal_full()
		e = Encounters.spawn_mon(am, wild.get_parent(), Vector3(at.x, ground + 1.6, at.z), true, CreatureDef.Behaviour.PASSIVE)
	else:
		e = Encounters.spawn_creature({"species": spec.species, "level": int(spec.level), "behaviour": "passive"}, 
			wild.get_parent(), Vector3(at.x, ground + 1.6, at.z), true)
	e.set_meta("boss_add", true)
	e.set_meta("add_ai_tier", String(spec.get("tier", "")))
	fit_cast(e)
	extra_foes.append(e)
	_prep_extra_foe(e, p)
	var tw: Tween = create_tween()
	tw.tween_property(e, "global_position", Vector3(at.x, ground, at.z), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	if not in_battle or _ending or not is_instance_valid(e) or not extra_foes.has(e):
		return
	e.mode = _foe_mode()
	e.opponent = partner
	e.hold_attacks(WILD_OPENING_DELAY)
	var h = Game.get_hud()
	if h != null:
		h.show_notice("A wild %s joined!" % String(spec.species), "", String(spec.species))
		if not Controls.is_touch() and h.battle_hud != null:
			h.battle_hud.show_hint([["target_next", "next target"]], 3.5)
	var cam: = Dialogue.camera_rig()
	if cam:
		cam.focus_fighters(_cam_fighters())



func _drop_boss_adds() -> void :
	for e in extra_foes.duplicate():
		if is_instance_valid(e) and e.has_meta("boss_add"):
			_remove_boss_add(e)



func _remove_boss_add(e: CreatureDef) -> void :
	extra_foes.erase(e)
	_combatants.erase(e)
	if e.fainted.is_connected(_on_fainted):
		e.fainted.disconnect(_on_fainted)
	for a in allies:
		if is_instance_valid(a) and a.opponent == e:
			a.opponent = null
	_retarget_allies()
	var tw: Tween = e.create_tween()
	tw.tween_property(e, "scale", Vector3.ONE * 0.01, 0.25)
	tw.tween_callback(e.queue_free)







const PICK_SECS: = 10.0



var _picking: = false:
	set(v):
		_picking = v
		if not v and not _battle_paused:
			_play_fight_tweens()
var _pick_slot: = -1
var pick_left: = PICK_SECS


var _pick_sup: = -1
var pick_sup_ok: = false




var _arena_deep: = false



func arena_all_deep(center: Vector3, size: Vector2) -> bool:
	for ix in 5:
		for iz in 5:
			var x: = center.x + (float(ix) / 4.0 - 0.5) * size.x
			var z: = center.z + (float(iz) / 4.0 - 0.5) * size.y
			if Transitions.surface_at(x, z) != Water.Surface.DEEP:
				return false
	return true




func _surfing_afloat() -> bool:
	var p: = Dialogue.player()
	if p == null or not p.has_method("rides_water") or not p.rides_water():
		return false

	return String(p.mount.mode) == "water"\
	or Transitions.surface_at(p.global_position.x, p.global_position.z) != Water.Surface.GROUND



func _wild_arena_deep(p: Node3D, foe: Node3D) -> bool:
	var size: = wild_arena if wild_arena.x > 0.0 else Vector2(ARENA_SIZE, ARENA_SIZE)
	return _surfing_afloat() or arena_all_deep((p.global_position + foe.global_position) * 0.5, size)





func sea_barred(m) -> bool:
	if not _arena_deep:
		return false
	return _is_surf_mount(m)



func sea_fighters(ride: = -1) -> int:
	var n: = 0
	for i in Game.party.size():
		if i != ride and Game.party[i].hp > 0:
			n += 1
	return n



func _is_surf_mount(m) -> bool:
	var p: = Dialogue.player()
	if p == null or not p.has_method("riding_slot"):
		return false
	var i: int = p.riding_slot()
	return i >= 0 and i < Game.party.size() and Game.party[i] == m



func sea_ready() -> bool:
	for m in Game.party:
		if m.hp > 0 and not sea_barred(m):
			return true
	return false



func roster_ok(mon) -> bool:
	var n: = int(trainer_battle.get("roster", 0))
	if n <= 0:
		return true
	var used: Array = trainer_battle.get("used", [])
	return used.has(mon) or used.size() < n



func pick_eligible(i: int) -> bool:
	if is_spar() and i != int(trainer_battle.learner):
		return false
	if i >= 0 and i < Game.party.size() and not roster_ok(Game.party[i]):
		return false
	if i < 0 or i >= Game.party.size() or Game.party[i].hp <= 0 or Game._sending.has(i) or sea_barred(Game.party[i]):
		return false
	if Game.is_out(i) and Game.companions[i].evolving:
		return false
	return not allies.any( func(a): return is_instance_valid(a) and a.mon == Game.party[i])




func pick_resolve(i: int, shift: = false) -> void :
	if not _picking or not pick_eligible(i):
		return
	if shift:
		if pick_sup_ok:
			_pick_sup = -1 if _pick_sup == i else i
		return
	if i == _pick_sup:
		return
	_pick_slot = i
	_picking = false


func _first_pickable(excl: int) -> int:
	for i in Game.party.size():
		if i != excl and pick_eligible(i):
			return i
	return -1




func _pick_lead(default: int, sup_ok: = false, sup_preset: = -1) -> Dictionary:
	var h: = Game.get_hud()
	var ring = h.get("party_ring") if h else null
	var fallback: = {"lead": default, "sup": sup_preset}
	if Settings.first_mon or online or online_guest or _auto() or ring == null or _picking:
		return fallback
	var n: = 0
	for i in Game.party.size():
		if i != sup_preset and pick_eligible(i):
			n += 1
	if n <= 1:
		var only: = _first_pickable(sup_preset)
		return {"lead": only if only >= 0 else default, "sup": sup_preset}
	_pick_slot = -1
	_pick_sup = sup_preset
	pick_sup_ok = sup_ok and sup_preset < 0
	pick_left = PICK_SECS
	_picking = true
	ring.open_pick()


	var slow: = in_battle and not _intro
	if slow:
		_slow_in(PICK_SLOWMO)
	while _picking and in_battle and not _ending:
		await get_tree().process_frame
		if not _battle_paused:
			pick_left -= get_process_delta_time() / (maxf(Engine.time_scale, 0.01) if slow else 1.0)
		if pick_left <= 0.0:
			break
	if slow:
		_slow_out()
	_picking = false
	ring.close()
	var lead: = _pick_slot
	if lead < 0:
		lead = default if default != _pick_sup else _first_pickable(_pick_sup)
	var sup: = _pick_sup
	_pick_sup = -1
	pick_sup_ok = false
	return {"lead": lead, "sup": sup}






func _choose_leads(idx: int, idx2: int) -> Dictionary:
	if is_spar():
		return {"lead": int(trainer_battle.learner), "sup": -1}

	var wild_fight: = trainer_battle.is_empty() and BATTLE_SIZE > 1 and not (max_fighters > 0 and 1 + guest_allies.size() >= max_fighters)
	var d_lead: int = Game.state.default_slot(false) if trainer_battle.is_empty() else -1
	var d_sup: int = Game.state.default_slot(true) if wild_fight else -1
	if d_sup == d_lead:
		d_sup = -1
	if online or online_guest or _auto():
		return {"lead": idx, "sup": idx2}


	if _piloted_lead >= 0:
		return {"lead": _piloted_lead, "sup": d_sup if d_sup != _piloted_lead else -1}
	if d_lead >= 0:
		return {"lead": d_lead, "sup": d_sup}
	if Settings.first_mon:
		return {"lead": idx, "sup": d_sup if d_sup >= 0 else idx2}
	return await _pick_lead(idx, wild_fight, d_sup)




func _bring_out(i: int, control: bool, pending: Array) -> void :
	if Game.state.is_out(i):
		if control and _lead_spot.is_finite() and not Game.companions[i].has_meta("battle_deploy_at"):
			Game.companions[i].global_position = Vector3(_lead_spot.x, Transitions.ground_y(_lead_spot, _lead_spot.y), _lead_spot.z)
			Transitions.reset_interp(Game.companions[i])
		await _set_fighter(Game.companions[i], control)
	else:
		await _deploy_fighter(i, control)
	pending.erase(i)


func _next_healthy(prefer_out: = true) -> int:
	var busy: Array = allies.filter( func(a): return is_instance_valid(a)).map( func(a): return a.mon)
	for pass_out in ([true, false] if prefer_out else [false]):
		for i in Game.party.size():
			if is_spar() and i != int(trainer_battle.learner):
				continue
			if not roster_ok(Game.party[i]):
				continue
			if Game.party[i].hp > 0 and not sea_barred(Game.party[i]) and not busy.has(Game.party[i]) and not Game._sending.has(i) and ( not pass_out or Game.state.is_out(i)):
				return i
	return -1



func is_spar() -> bool:
	return int(trainer_battle.get("learner", -1)) >= 0




var _piloted_lead: = -1


func _driven_slot() -> int:
	var pl: = Dialogue.player()
	var driven = pl.get("pilot") if pl != null else null
	if driven == null or not is_instance_valid(driven):
		return -1
	var s: = int(driven.follow_slot)
	if s >= 0 and s < Game.party.size() and Game.party[s].hp > 0 and not sea_barred(Game.party[s]):
		return s
	return -1


func _battle_lead() -> int:
	if is_spar():
		return int(trainer_battle.learner)

	var s: = _driven_slot()
	if s >= 0:
		return s
	for i in Game.party.size():
		if Game.party[i].hp > 0 and not sea_barred(Game.party[i]):
			return i
	return Game.state.first_healthy()



func ai_ally() -> CreatureDef:
	for a in allies:
		if is_instance_valid(a) and a != partner and not guest_allies.has(a) and a.mode != CreatureDef.Mode.FAINTED:
			return a
	return null



func guest_ally() -> CreatureDef:
	for g in guest_allies:
		if is_instance_valid(g) and g.mode != CreatureDef.Mode.FAINTED and g.alive():
			return g
	return null


func _fighter_mode(c: CreatureDef) -> int:
	if c.has_meta("lan_remote"): return CreatureDef.Mode.REMOTE
	return CreatureDef.Mode.PLAYER if c == partner and not autopilot else CreatureDef.Mode.BATTLE_AI




func trainer_callout(t, text: String, ball: = "poke_ball") -> void :
	if not is_instance_valid(t):
		return
	get_node("/root/Vfx").popup(t.global_position + Vector3(0, 1.6, 0), text, CALLOUT_COL, 1.0, 
		"callout", 1, str(t.get_instance_id()), ball)





func announce(text: String, at = null) -> void :
	if not is_instance_valid(at):
		at = wild if is_instance_valid(wild) else Dialogue.player()
	if is_instance_valid(at):
		get_node("/root/Vfx").popup(at.global_position + Vector3(0, 1.6, 0), text, CALLOUT_COL, 1.0, 
			"callout", 1, "announce_" + str(at.get_instance_id()))



func swap_control() -> void :
	var lan = get_node_or_null("/root/LanCampaign")
	if lan != null and lan.coop_battle_active(): return
	if online_guest:
		return
	if not in_battle or _intro or _ending or _switching or Progression._capturing:
		return
	var other: = ai_ally()
	if other == null or other.evolving or (is_instance_valid(partner) and partner.evolving):
		return
	close_party_ring()
	var old: = partner
	partner = other
	_sync_board_level()
	Audio.ui("sfx/ui/swap_control")
	for c in [old, other]:
		if is_instance_valid(c) and c.mode != CreatureDef.Mode.FAINTED:
			c.mode = _fighter_mode(c)
			c.velocity = Vector3.ZERO
	Dialogue.msg("Go, %s!" % other.mon.display_name, 1.0, "info")
	trainer_callout(Dialogue.player(), "Go, %s!" % other.mon.display_name, other.mon.ball)
	Game.party_changed.emit()



func start_ally_ai(c: CreatureDef) -> void :
	var guest: = guest_allies.has(c)


	var unit: = ""
	if guest:
		unit = String(c.get_meta("tactic_unit", c.mon.get_meta("tactic_unit", "") if c.mon else ""))
	c.combat.auto_brain(guest_tier if guest_tier != "" and guest else ALLY_TIER, unit, "")
	if guest_item != "" and guest_allies.has(c):
		c.combat.is_trainer_mon = true
		c.combat.trainer_item = guest_item
	c.combat.set_role(String(c.mon.battle_role) if c.mon else "auto")




func cycle_ally_mode() -> void :
	var a: = ai_ally()
	if a == null:
		return
	var avail: Array = AiMatchup.roles_for(a.species, a.moves)
	var r: String = avail[(avail.find(a.combat.role) + 1) % avail.size()]
	a.combat.set_role(r)
	Audio.ui("sfx/ui/mode_attack")
	get_node("/root/Vfx").popup(a.global_position + Vector3(0, 1.4, 0), r.to_upper(), CreatureDef.ROLE_COLORS.get(r, Color.WHITE), 1.0, "info")
	print("[battle] ally role: ", r)







var _out_snap = null


func snapshot_out() -> void :
	_out_snap = []
	for c in Game.companions.values():
		if is_instance_valid(c) and c.mon != null:
			_out_snap.append(c.mon)


func start_battle(w: CreatureDef, training: = false) -> void :
	var lan = get_node_or_null("/root/LanCampaign")
	if lan != null and not lan.allow_solo_wild() and not launching_lan(): return

	if not in_battle and not training and trainer_battle.is_empty() and SafariFightScript.applies(w):
		await _safari_fight(w)
		return
	var prep_clock: = Time.get_ticks_usec()
	if in_battle or not is_instance_valid(w) or w.mode == CreatureDef.Mode.FAINTED:
		return
	pay_day_money = 0
	var p: = Dialogue.player()
	if p == null:
		return
	if Game.party.is_empty():
		w.peace_timer = 4.0
		w.mode = CreatureDef.Mode.IDLE if w.static_uid != "" else CreatureDef.Mode.WANDER
		if not Game.cutscene:
			p.controls_enabled = true
		Dialogue.msg("You don't have any Pokémon! Get one at the lab first.")
		return
	if trainer_battle.is_empty():
		_arena_deep = _wild_arena_deep(p, w)
	var idx: = _battle_lead()
	_piloted_lead = _driven_slot()

	PokemonSprites.want_full(w.look_species(), w.is_shiny())
	if idx >= 0 and idx < Game.party.size():
		PokemonSprites.want_full(String(Game.party[idx].species), bool(Game.party[idx].shiny))
	if idx < 0:
		w.peace_timer = 4.0
		w.mode = CreatureDef.Mode.IDLE if w.static_uid != "" else CreatureDef.Mode.WANDER
		if not Game.cutscene:
			p.controls_enabled = true
		_no_healthy_msg()
		return
	if _out_snap == null:
		snapshot_out()
	in_battle = true
	Game.talking = false



	p.controls_enabled = false
	Controls.set_battle_dpad(true)
	self.training = training
	allies.clear()
	_ending = false
	_intro = true

	speed = Settings.battle_speed_value()
	_intro_skip = false
	_participants.clear()
	_exp_results.clear()
	_ev_results.clear()
	_foe_levels.clear()
	wild = w
	_static_uid = String(w.static_uid)
	_adds_pending = w.boss_adds.duplicate(true)

	if trainer_battle.is_empty():
		_pull_herd(w)



	if wild_arena.x <= 0.0 and w.static_arena_size.x > 0.0 and w.static_arena_center.is_finite():
		wild_arena = w.static_arena_size
		wild_arena_center = w.static_arena_center
		_wild_arena_from_body = true
	if not challenge:
		Game.state.mark_seen(w.species)
	p.controls_enabled = false

	wild.mode = CreatureDef.Mode.IDLE
	wild.velocity = Vector3.ZERO
	wild.opponent = null
	wild.ai_uses_moves = true


	if trainer_battle.is_empty():
		var wild_tier: = AiBrains.wild_tier(Game.event_zone(p), int(w.level), String(w.static_uid) != "")
		if String(w.boss_ai_tier) != "":
			wild_tier = String(w.boss_ai_tier)
		if wild_tier != "":
			wild.combat.auto_brain(wild_tier, String(w.static_uid))
	_join_fight(wild)
	var to_p: = p.global_position - wild.global_position
	to_p.y = 0.0
	if to_p.length() > 0.01:
		wild.facing = to_p.normalized()
	if not wild.fainted.is_connected(_on_fainted):
		wild.fainted.connect(_on_fainted)
	for e in extra_foes:
		_prep_extra_foe(e, p)
	for g in guest_allies:
		_bind_guest(g)
	var keep: Array = [wild] + extra_foes
	if Game.state.is_out(idx):
		keep.append(Game.companions[idx])


	var idx2: = -1
	if BATTLE_SIZE > 1 and trainer_battle.is_empty() and Game.state.is_out(idx):
		for i in Game.party.size():
			if i != idx and Game.state.is_out(i) and Game.party[i].hp > 0 and not Game.companions[i].evolving\
			and i != p.riding_slot() and not sea_barred(Game.party[i]):
				idx2 = i
				break
	if idx2 >= 0 and Game.state.is_out(idx2):
		keep.append(Game.companions[idx2])
	_hide_others(keep)
	P1Prof.span("battle setup+hide", Time.get_ticks_usec() - prep_clock)
	prep_clock = Time.get_ticks_usec()


	var look: = _zone_look()
	var zone_arena: = float(look.get("arena_size", ARENA_SIZE))
	var asz: Vector2 = trainer_battle.get("arena", Vector2(zone_arena, zone_arena))
	if wild_arena.x > 0.0:
		asz = wild_arena
	var mid: Vector3
	var wild_spot = null
	var pl: = {}
	_lead_spot = Vector3.INF
	_lead_blocked = Callable()
	if trainer_battle.has("center"):
		mid = trainer_battle.center
		mid.y = Transitions.ground_y(mid, mid.y)
		arena_rect = Rect2(mid.x - asz.x * 0.5, mid.z - asz.y * 0.5, asz.x, asz.y)


		_clear_arena_props(arena_rect)



		var lead_who = Game.companions[idx] if Game.state.is_out(idx) else Game.party[idx]
		var to_mid: Vector3 = mid - p.global_position
		to_mid.y = 0.0
		var at_lead: Vector3 = p.global_position + (to_mid.normalized() * 1.5 if to_mid.length() > 0.01 else Vector3(0, 0, 1.5))



		var p_in_ring: = arena_rect.has_point(Vector2(p.global_position.x, p.global_position.z))
		if (bool(trainer_battle.get("keep_spots", false)) or not p_in_ring) and to_mid.length() > 0.01:



			at_lead = mid - to_mid.normalized() * ((maxf(asz.x, asz.y) * 0.5 + 0.3) * 0.4)
		_lead_blocked = _blocked_at(mid.y, false, _arena_clear_rids())
		_lead_spot = _off_tombs(nearest_ok(at_lead, lead_who, arena_rect, _lead_blocked), _lead_blocked)
	elif wild_arena.x > 0.0 and wild_arena_center.is_finite():


		mid = wild_arena_center
		mid.y = Transitions.ground_y(mid, mid.y)
		arena_rect = Rect2(mid.x - asz.x * 0.5, mid.z - asz.y * 0.5, asz.x, asz.y)
		var o_who = Game.companions[idx] if Game.state.is_out(idx) else Game.party[idx]


		_lead_blocked = _blocked_at(Transitions.ground_y(p.global_position, p.global_position.y))
		var axis: = BattleArena._axis(wild.global_position - p.global_position, p.facing_vector())
		var pair: = BattleArena._pair(mid, asz, axis, p.global_position, _lead_blocked, 
			wild.global_position, _lead_blocked, _place_pred(o_who), _place_pred(wild))
		if pair.is_empty():
			pair = BattleArena._pair(mid, asz, Vector3( - axis.z, 0, axis.x), p.global_position, 
				_lead_blocked, wild.global_position, _lead_blocked, _place_pred(o_who), _place_pred(wild))
		if not pair.is_empty():
			_lead_spot = pair.lead_spot
			wild_spot = pair.wild_spot
		else:

			var half: = BattleArena.BATTLE_START_GAP * 0.5
			_lead_spot = nearest_ok(mid - axis * half, o_who, arena_rect, _lead_blocked)
			wild_spot = nearest_ok(mid + axis * half, wild, arena_rect, _lead_blocked)


		if wild.static_arena_lead.is_finite():
			_lead_spot = wild.static_arena_lead
			wild_spot = wild.global_position
	else:




		var level: = Transitions.ground_y(p.global_position, p.global_position.y)


		var clear_rids: = _arena_clear_rids()
		var blocked: Callable = _blocked_at(level, false, clear_rids)



		var lead_who = Game.companions[idx] if Game.state.is_out(idx) else Game.party[idx]
		var lead_ok: = _place_pred(lead_who)
		var wild_ok: = _place_pred(wild)


		var wild_pref: = wild_ok
		if _wild_keeps_water(wild):
			wild_pref = func(x: float, z: float) -> bool:
				return bool(wild_ok.call(x, z)) and Transitions.surface_at(x, z) != Water.Surface.GROUND
		elif _prefers_ground(wild):
			wild_pref = func(x: float, z: float) -> bool:
				return Transitions.surface_at(x, z) == Water.Surface.GROUND


		var height_at: Callable = Transitions.ground_xz
		if Transitions.has_levelled_water():
			height_at = func(x: float, z: float) -> float:
				return level if Transitions.in_levelled_water(x, z) else Transitions.ground_xz(x, z)
		pl = BattleArena.plan(p.global_position, wild.global_position, asz, height_at, p.facing_vector(), blocked, lead_ok, wild_pref)
		if not bool(wild_pref.call(pl.wild_spot.x, pl.wild_spot.z)):
			pl = BattleArena.plan(p.global_position, wild.global_position, asz, height_at, p.facing_vector(), blocked, lead_ok, wild_ok)

		if wild_arena.x <= 0.0 and not _arena_deep and _land_fraction(pl.rect) < WATER_LAND_BAR:

			blocked = _blocked_at(level, true, clear_rids)
			pl = BattleArena.plan(p.global_position, wild.global_position, asz, height_at, p.facing_vector(), blocked, lead_ok, wild_ok)
		mid = pl.center
		asz = pl.rect.size
		arena_rect = pl.rect
		wild_spot = _off_tombs(pl.wild_spot, blocked)
		_lead_blocked = blocked
		_lead_spot = _off_tombs(nearest_ok(pl.lead_spot, lead_who, pl.rect, blocked), blocked)
		_clear_arena_props(arena_rect)
	P1Prof.span("battle arena plan", Time.get_ticks_usec() - prep_clock)
	prep_clock = Time.get_ticks_usec()
	if not trainer_battle.is_empty():
		fit_cast(wild)
	var cam: = Dialogue.camera_rig()
	if cam:
		if wild_spot != null or wild_arena.x > 0.0 or not trainer_battle.is_empty():




			var pad: float = float(trainer_battle.get("frame_pad", FRAME_PAD)) if not trainer_battle.is_empty() else wild_frame_pad
			if _wide_camera():
				pad = maxf(pad, WIDE_CAMERA_PAD)
			cam.focus_fixed(mid, _fit_cam_dist(asz, pad))
		else:
			_focus_fighters(cam, p.global_position, w.global_position)

	thunder_border = float(trainer_battle.get("thunder_border", 0.0))
	teleport_discs = trainer_battle.get("discs", [])
	disc_partners = trainer_battle.get("disc_partners", [])
	disc_ready = []
	disc_ready.resize(teleport_discs.size())
	disc_ready.fill(0.0)
	type_bonus = trainer_battle.get("type_bonus", [])
	_arena = BattleArena.new()
	p.get_parent().add_child(_arena)
	_arena.setup(mid, asz, trainer_battle.get("arena_color", BattleArena.COLOR), 
		thunder_border)
	if not teleport_discs.is_empty():
		_disc_view = DiscView.new()
		_arena.add_child(_disc_view)
		_disc_view.setup(teleport_discs)
	_field_start(p.global_position.y)
	if Debug.arena_debug and not pl.is_empty():
		_arena.add_child(BattleArena.debug_mesh(pl))
	var hud: = Dialogue.hud()
	if hud:
		hud.intro.bars(true)
	print("[battle] start vs %s Lv%d" % [wild.species, wild.level])


	if trainer_battle.is_empty():
		Audio.push_music("battle", wild_music if wild_music != "" else "music/battle_wild", 0.2)
	P1Prof.span("battle arena+field+music", Time.get_ticks_usec() - prep_clock)
	if w.has_meta("battle_deploy_at"):
		wild_spot = null
	await _wild_appears(w)
	if not _intro_ok(w):
		return
	if wild_spot != null:
		await _hop_to(w, wild_spot)
		_settle(w, wild)
		if not _intro_ok(w):
			return
		var face_p: = p.global_position - w.global_position
		face_p.y = 0.0
		if face_p.length() > 0.01:
			w.facing = face_p.normalized()
	var side: = Vector3.UP.cross((w.global_position - p.global_position).normalized()) * 2.5
	for i in extra_foes.size():
		var e: CreatureDef = extra_foes[i]
		if is_instance_valid(e) and wild_spot != null:
			var spot: Vector3 = wild_spot + side * ((1 if i % 2 == 0 else -1) * (1 + i / 2))
			await _hop_to(e, nearest_ok(spot, e, arena_rect, _lead_blocked))
			_settle(e, e)
			var face_e: = p.global_position - e.global_position
			face_e.y = 0.0
			if face_e.length() > 0.01:
				e.facing = face_e.normalized()
	if trainer_battle.is_empty():
		announce("A wild %s appeared!" % w.species, w)
	elif trainer_battle.get("versus", {}).is_empty():
		announce("%s sent out %s!" % [trainer_battle.name, w.species], w)
	await _intro_wait(1.2)
	if not _intro_ok(w):
		return


	var sel: = await _choose_leads(idx, idx2)
	if not _intro_ok(w):
		return
	var lead: int = sel.lead
	var sup: int = sel.sup
	if max_fighters > 0 and 1 + guest_allies.size() >= max_fighters:
		sup = -1
	var recalled: = false
	for k in [idx, idx2]:
		if k >= 0 and k != lead and k != sup and Game.state.is_out(k):
			Game.recall(k)
			recalled = true
	if recalled:
		await get_tree().create_timer(Game.RECALL_SECS).timeout
		if not _intro_ok(w):
			return


	var authored_lead: bool = is_instance_valid(wild) and wild.get("static_arena_lead") is Vector3\
	and (wild.static_arena_lead as Vector3).is_finite()
	if lead != idx and _lead_blocked.is_valid() and _lead_spot.is_finite() and not authored_lead:
		var who = Game.companions[lead] if Game.state.is_out(lead) else Game.party[lead]
		_lead_spot = _off_tombs(nearest_ok(_lead_spot, who, arena_rect, _lead_blocked), _lead_blocked)
	idx = lead
	idx2 = sup
	var pending: Array = [idx] if idx2 < 0 else [idx, idx2]
	_bring_out(idx, true, pending)
	if idx2 >= 0:
		_bring_out(idx2, false, pending)
	while not pending.is_empty() and in_battle and not _ending:
		await get_tree().process_frame
	if not _intro_ok(w):
		return

	for guest_index in guest_allies.size():
		var g = guest_allies[guest_index]
		if is_instance_valid(g) and is_instance_valid(partner) and arena_rect.size.x > 0.0 and not g.has_meta("battle_deploy_at"):
			var lane: = float(1 + guest_index / 2) * (1.0 if guest_index % 2 == 0 else -1.0)
			var off: Vector3 = Vector3.UP.cross((w.global_position - partner.global_position).normalized()) * 1.8 * lane
			var at: Vector3 = nearest_ok(partner.global_position + off, g, arena_rect, _lead_blocked)
			g.global_position = Vector3(at.x, Transitions.ground_y(at, g.global_position.y), at.z)
			Transitions.reset_interp(g)
			var gf: Vector3 = w.global_position - g.global_position
			gf.y = 0.0
			if gf.length() > 0.01:
				g.facing = gf.normalized()
			if get_node_or_null("/root/LanCampaign") != null:
				g.show()
				Vfx.send_out_reveal(g)

	for fighter in allies + [wild] + extra_foes:
		if is_instance_valid(fighter) and fighter.has_meta("battle_deploy_at"):
			fighter.global_position = fighter.get_meta("battle_deploy_at")
			Transitions.reset_interp(fighter)
			fighter.remove_meta("battle_deploy_at")
			fighter.facing = Vector3.FORWARD if allies.has(fighter) else Vector3.BACK

	var warm_started: = Time.get_ticks_msec()
	await Vfx.warm_combatants(allies + [wild] + extra_foes)
	if not _intro_ok(w):
		return
	await _intro_wait(maxf(0.35 - (Time.get_ticks_msec() - warm_started) / 1000.0, 0.0))
	if not _intro_ok(w):
		return



	var extra: Array = []
	if allies.size() > 1 and get_node_or_null("/root/LanCampaign") == null:
		extra = [["control_other", "control other fighter"], ["party_ring", "hold: 2nd fighter"]]
	if foes().size() > 1 and not Controls.is_touch():
		extra.append(["target_next", "next target"])
	if hud and not extra.is_empty():
		hud.battle_hud.show_hint(extra, 3.5)

	await get_tree().process_frame
	if not _intro_ok(w):
		return
	if hud:
		hud.intro.fight()
		hud.intro.bars(false)
	_intro = false
	_intro_skip = false
	for a in allies:
		if is_instance_valid(a):
			a.mode = _fighter_mode(a)

	w.mode = _foe_mode()
	w.hold_attacks(WILD_OPENING_DELAY)
	for e in extra_foes:
		if is_instance_valid(e):
			e.mode = _foe_mode()
			e.hold_attacks(WILD_OPENING_DELAY)
			e.opponent = partner
	if not extra_foes.is_empty() or not guest_allies.is_empty():
		_retarget_allies()



	if training:
		w.mode = CreatureDef.Mode.DUMMY
		w.dummy_style = 0
		w.ai_uses_moves = false
		w.immortal = true
	print("[battle] fight! (%s vs %s)" % [partner.species if is_instance_valid(partner) else "?", w.species])
	SpikeLog.mark("battle_start")
	Game.battle_started.emit(partner, wild)












func start_trainer_battle(trainer: Node3D, trainer_name: String, mons: Array, opts: = {}) -> String:
	var p: = Dialogue.player()
	if p == null or mons.is_empty() or in_battle or Game.state.first_healthy() < 0:
		return "aborted"
	var learner: = int(opts.get("learner", -1))
	if learner >= 0 and (learner >= Game.party.size() or Game.party[learner].hp <= 0):
		return "aborted"
	online = bool(opts.get("online", false))
	challenge = bool(opts.get("challenge", false))






	var plan: Dictionary = {}
	var center: Vector3
	var asz: Vector2 = opts.get("arena", Vector2(10, 6))
	if opts.has("center"):
		center = opts.center
	else:




		if not bool(opts.get("arena_exact", false)):
			var rig: = Dialogue.camera_rig()
			if rig and rig.camera:
				var near: float = rig.visible_ground(_battle_cam_dist()).x - BattleArena.TRAINER_STAND_OFF
				asz.x = clampf(floorf(near * 2.0), 6.0, asz.x)
		var level: = Transitions.ground_y(p.global_position, p.global_position.y)
		plan = BattleArena.plan_trainer(p.global_position, trainer.global_position, asz, 
			Transitions.ground_xz, p.facing_vector(), _blocked_at(level))
		center = plan.center
		asz = plan.size

	var vs_opts: Dictionary = {} if autopilot else opts.get("versus", {})
	trainer_battle = {"name": trainer_name, "node": trainer, "center": center, "arena": asz, "versus": vs_opts, 
		"axis": plan.get("axis", opts.get("axis", Vector3.RIGHT)), 
		"frame_pad": float(opts.get("frame_pad", FRAME_PAD)), 
		"player_spot": plan.get("player_spot", Vector3.INF), 
		"trainer_spot": plan.get("trainer_spot", Vector3.INF), 
		"arena_color": opts.get("arena_color", BattleArena.COLOR), 
		"class": String(opts.get("trainer_class", "")), "scripted": bool(opts.get("scripted", false)), 
		"lose": opts.get("lose", []), "learner": learner, 
		"defeat": opts.get("defeat", []), "face": String(opts.get("face", "")), 
		"roster": int(opts.get("roster", 0)), "used": [], 
		"mons": mons, "index": 0, "total": mons.size(), "fainted": 0, "spot": Vector3.INF, 
		"ai_scale": float(opts.get("ai_think_scale", 1.0)), "item": String(opts.get("item", "")), 
		"ai_tier": String(opts.get("ai_tier", "")), "trainer_id": String(opts.get("trainer_id", "")), 
		"field": String(opts.get("field", "")), "keep_spots": bool(opts.get("keep_spots", false))}
	_arena_deep = _surfing_afloat() or arena_all_deep(center, asz)

	trainer_battle["thunder_border"] = float(opts.get("thunder_border", 0.0))
	trainer_battle["discs"] = opts.get("discs", [])
	trainer_battle["disc_partners"] = opts.get("disc_partners", [])
	trainer_battle["type_bonus"] = opts.get("type_bonus", [])
	p.controls_enabled = false

	var battle_music: = "music/battle_trainer"
	if String(trainer_battle.get("class", "")) == "gym_leader":
		battle_music = Audio.resolve(["music/battle_gym_leader", "music/battle_trainer"])
	Audio.clear_jingles()
	Audio.push_music("battle", String(opts.get("music", battle_music)), 0.2)
	var hud: = Dialogue.hud()
	if hud:
		hud.intro.bars(true)

	await Transitions.fade(1.0, 0.25)


	var lead: = _battle_lead()
	for k in Game.companions.keys().duplicate():
		if Game.state.is_out(k) and k != lead and k != p.riding_slot():
			Game.recall(k)
	var axis: Vector3 = trainer_battle.get("axis", Vector3.RIGHT)
	var spread: = maxf(asz.x, asz.y) * 0.5 + 0.3


	var place_blocked: Callable = _blocked_at(Transitions.ground_y(p.global_position, p.global_position.y))


	if not bool(opts.get("keep_spots", false)):
		if opts.has("human_spots"):
			_place_trainer(p, opts.human_spots[0], axis)
			_place_trainer(trainer, opts.human_spots[1], - axis)
		elif plan.is_empty():
			_place_trainer(p, _off_tombs(center - axis * spread, place_blocked), axis)
			_place_trainer(trainer, _off_tombs(center + axis * spread, place_blocked), - axis)
		else:
			_place_trainer(p, _off_tombs(plan.player_spot, place_blocked), axis)
			_place_trainer(trainer, _off_tombs(plan.trainer_spot, place_blocked), - axis)
	for i in Game.companions.keys():
		if Game.state.is_out(i):
			Game.companions[i].global_position = p.global_position + Vector3(0.6, 0, 0.9)
			Transitions.reset_interp(Game.companions[i])
	var cam: = Dialogue.camera_rig()
	if cam:




		cam.focus_fixed(center, _fit_cam_dist(asz, float(trainer_battle.get("frame_pad", FRAME_PAD))))
		cam.global_position = center
	if not vs_opts.is_empty():
		var vs: = BattleVersus.new()
		get_tree().root.add_child(vs)
		var card: Dictionary = vs_opts.duplicate()
		card["foe_name"] = card.get("foe_name", trainer_name)
		var hn: = maxi(1, Game.party.size())
		if bool(card.get("light", false)):

			await Transitions.fade(0.0, 0.25)
			await vs.play(card, hn, mons.size())
			vs.dock()
			await get_tree().create_timer(0.3).timeout
		else:

			await vs.play(card, hn, mons.size())
			vs.dock()
			await Transitions.fade(0.0, 0.25)
			await get_tree().create_timer(0.35).timeout
	else:
		await Transitions.fade(0.0, 0.25)
		announce(String(opts.get("intro_text", "%s wants to battle!" % trainer_name)), trainer)
		await get_tree().create_timer(1.2).timeout


	var pre_fight: Callable = opts.get("pre_fight", Callable())
	if pre_fight.is_valid():
		await pre_fight.call(trainer)
		if not is_instance_valid(p) or not is_instance_valid(trainer):
			return "aborted"
	var foe_off: Vector2 = opts.get("foe_offset", Vector2.ZERO)
	var at: Vector3 = center + axis * (spread * 0.4) + Vector3(foe_off.x, 0.0, foe_off.y)


	at = nearest_ok(at, mons[0], _trainer_rect(trainer_battle), _blocked_at(at.y, false, _arena_clear_rids()))
	at = _off_tombs(at, _blocked_at(at.y, false, _arena_clear_rids()))
	at.y = Transitions.ground_y(at, trainer.global_position.y)
	trainer_battle["spot"] = at
	await _throw_pose(trainer, at)
	await Game._throw_ball(trainer.global_position + Vector3(0, 1.0, 0), at)
	await PokemonSprites.prepare_species(String(mons[0].species))
	await PokemonSprites.load_full(String(mons[0].species), bool(mons[0].shiny))
	if not is_instance_valid(p) or not is_instance_valid(trainer):
		return "aborted"
	var w: = Encounters.spawn_mon(mons[0], p.get_parent(), at, true)
	get_node("/root/Vfx").send_out_reveal(w)
	if not challenge:
		Game.state.mark_seen(w.species)
	w.remove_from_group("wild")
	w.ai_think_scale = float(opts.get("ai_think_scale", 1.0))
	_trainer_brain(w, String(opts.get("ai_tier", "")), String(opts.get("trainer_id", "")), String(opts.get("trainer_class", "")))

	w.combat.is_trainer_mon = true
	w.combat.trainer_item = String(opts.get("item", ""))
	Audio.cry(w.species, at)
	trainer_callout(trainer, "GO! %s!" % String(mons[0].species).to_upper(), String(mons[0].ball))
	var lan_duo = get_node_or_null("/root/LanCampaign")
	if lan_duo != null and lan_duo.allow_campaign_battle() and mons.size() > 1:
		await lan_duo.deploy_second_foe(trainer, mons[1], at)
	start_battle(w)
	var result: String = await Game.battle_ended
	if is_instance_valid(w):
		w.queue_free()
	trainer_battle = {}
	return result






func start_training_battle(attendant: Node3D, species: String, level: int, card_path: String) -> void :
	var p: = Dialogue.player()
	if p == null or in_battle or not is_instance_valid(attendant):
		return
	if Game.party.is_empty():
		Dialogue.msg("You don't have any Pokémon! Get one at the lab first.")
		return
	if Game.state.first_healthy() < 0:
		_no_healthy_msg()
		return

	var center: Vector3 = attendant.global_position
	var c = attendant.get("arena_center")
	if c is Vector3 and c.is_finite():
		center = c
	var arena: = Vector2(ARENA_SIZE, ARENA_SIZE)
	var a = attendant.get("arena_size")
	if a is Vector2 and a.x > 0.0:
		arena = a
	wild_arena = arena
	wild_arena_center = center
	var at: = center
	at.y = Transitions.ground_y(at, attendant.global_position.y)
	var w: = Encounters.spawn_mon(MonScript.create(species, level), p.get_parent(), at, true)
	if not challenge:
		Game.state.mark_seen(w.species)
	w.remove_from_group("wild")


	var card: Texture2D = load(card_path)
	if card != null:
		w.card_texture = card
		w.apply_look()
	Audio.cry(w.species, at)
	start_battle(w, true)
	await Game.battle_ended
	wild_arena = Vector2.ZERO
	wild_arena_center = Vector3.INF
	if is_instance_valid(w):
		w.queue_free()



func _throw_pose(t: Node3D, at: Vector3) -> void :
	if not is_instance_valid(t):
		return
	if t.has_method("face"):
		t.face(at - t.global_position)
	var spr: = t.get_node_or_null("Sprite3D") as Sprite3D
	if spr == null:
		return
	var f: = spr.frame
	spr.frame = (f / 3) * 3 + 1
	await get_tree().create_timer(0.25).timeout
	if is_instance_valid(spr):
		spr.frame = f







func _trainer_brain(w: CreatureDef, tier: String, trainer_id: String, klass: String) -> void :
	if tier != "":
		w.combat.auto_brain(tier, "%s/%s" % [trainer_id, w.species], klass)


func _send_next_trainer_mon() -> void :
	var next_i: = _next_trainer_mon()
	if next_i < 0:
		return
	await _send_trainer_mon(next_i, false)



func escape_blocked(fighter: Node) -> bool:
	if not is_instance_valid(fighter) or not fighter.combat.mean_look_active():
		return false
	if is_instance_valid(fighter.combat.mean_look_fx):
		fighter.combat.mean_look_fx.flash()
	get_node("/root/Vfx").popup(fighter.head_pos(0.15), "CAN'T ESCAPE!", Color("dcb9e5"), 1.0, "status")
	return true


func can_flee() -> bool:
	for fighter in allies:
		if escape_blocked(fighter):
			return false
	return not escape_blocked(partner)






func flee() -> void :
	if safari != null:
		safari.player_ran()
		return
	end_battle("fled")






func can_force_switch(target: Node) -> bool:
	if not is_instance_valid(target) or not in_battle or _ending or _intro or online or online_guest\
	or challenge or is_spar() or _switching or _foe_switching or Progression._capturing:
		return false
	if target == partner:
		return not _party_switch_candidates().is_empty()
	if target == wild or extra_foes.has(target):
		return trainer_battle.is_empty() or (target == wild and not _trainer_switch_candidates().is_empty())
	return false



func force_switch(target: Node) -> void :
	if not can_force_switch(target):
		return
	if target == partner:
		var c: = _party_switch_candidates()
		_switch_fighter(int(c.pick_random()), true)
		return
	if target.has_meta("boss_add"):
		_remove_boss_add(target)
		return
	if trainer_battle.is_empty():
		end_battle("fled")
		return
	var next: = _trainer_switch_candidates()
	_foe_switching = true
	await _send_trainer_mon(int(next.pick_random()))
	_foe_switching = false



func _party_switch_candidates() -> Array:
	var out: Array = []
	for i in Game.party.size():
		var m = Game.party[i]
		if m.hp <= 0 or (is_instance_valid(partner) and partner.mon == m):
			continue
		if Game.state.is_out(i) and allies.has(Game.companions[i]):
			continue
		out.append(i)
	return out



func _trainer_switch_candidates() -> Array:
	var out: Array = []
	var mons: Array = trainer_battle.get("mons", [])
	var cur: = int(trainer_battle.get("index", 0))
	for i in mons.size():
		if i != cur and int(mons[i].hp) > 0:
			out.append(i)
	return out



func _next_trainer_mon() -> int:
	var tb: = trainer_battle
	var mons: Array = tb.get("mons", [])
	var cur: = int(tb.get("index", 0))
	for i in mons.size():
		if i != cur and int(mons[i].hp) > 0:
			return i
	return -1



func _send_trainer_mon(index: int, entry_cd: = true) -> void :
	var old: = wild
	wild = null
	if is_instance_valid(old):
		var tb0: = trainer_battle

		for a in allies + guest_allies:
			if is_instance_valid(a) and a.opponent == old:
				a.opponent = null
		Dialogue.msg("Come back, %s!" % old.species, 1.2, "trainer")
		trainer_callout(tb0.get("node"), "Come back, %s!" % old.species, old.mon.ball if old.mon else "poke_ball")
		_combatants.erase(old)
		var p0: = Dialogue.player()
		if p0:
			CaptureFX.recall(self, p0.get_parent(), tb0.get("node"), old, old.mon.ball if old.mon else "poke_ball")
		else:
			old.recalling = true
			_fade_body(old, true)
		await get_tree().create_timer(Game.RECALL_SECS).timeout
		if is_instance_valid(old):
			old.queue_free()
	if not in_battle or _ending:
		return
	var tb: = trainer_battle
	var mons: Array = tb.get("mons", [])
	if index < 0 or index >= mons.size():
		return
	tb["index"] = index
	var trainer: Node3D = tb.get("node")
	var species: = String(mons[index].species)


	await get_tree().create_timer(1.4).timeout
	if not in_battle or _ending:
		return
	var at: Vector3 = tb.get("spot", tb.get("center", Vector3.ZERO))
	at = nearest_ok(at, mons[index], _trainer_rect(tb), _blocked_at(at.y))
	at = _off_tombs(at, _blocked_at(at.y))
	at.y = Transitions.ground_y(at, at.y)
	if is_instance_valid(trainer):
		await _throw_pose(trainer, at)
		await Game._throw_ball(trainer.global_position + Vector3(0, 1.0, 0), at)
	await PokemonSprites.prepare_species(String(mons[index].species))
	await PokemonSprites.load_full(String(mons[index].species), bool(mons[index].shiny))
	if not in_battle or _ending:
		return
	var p: = Dialogue.player()
	var w: = Encounters.spawn_mon(mons[index], p.get_parent(), at, true)
	fit_cast(w)
	get_node("/root/Vfx").send_out_reveal(w)
	if not challenge:
		Game.state.mark_seen(w.species)
	w.remove_from_group("wild")
	w.ai_think_scale = float(tb.get("ai_scale", 1.0))
	_trainer_brain(w, String(tb.get("ai_tier", "")), String(tb.get("trainer_id", "")), String(tb.get("class", "")))
	w.combat.is_trainer_mon = true
	w.combat.trainer_item = String(tb.get("item", ""))
	Audio.cry(w.species, at)
	trainer_callout(trainer, "GO! %s!" % species.to_upper(), String(mons[index].ball))
	w.mode = CreatureDef.Mode.IDLE
	await Vfx.warm_combatants([w])
	if not is_instance_valid(w) or not in_battle or _ending:
		return
	_bind_foe(w)


	var cam: = Dialogue.camera_rig()
	if cam and is_instance_valid(wild):
		cam.focus_fighters(_cam_fighters())
	if entry_cd:
		w.combat.entry_cooldown()




func switch_foe(slot: int) -> bool:
	if escape_blocked(wild):
		return false
	if not online or not in_battle or _ending or _intro or _foe_switching:
		return false
	var mons: Array = trainer_battle.get("mons", [])
	if slot < 0 or slot >= mons.size() or slot == int(trainer_battle.get("index", 0)):
		return false
	if int(mons[slot].hp) <= 0:
		return false
	_foe_switching = true
	_foe_switch_to(slot)
	return true


func _foe_switch_to(slot: int) -> void :
	await _send_trainer_mon(slot)
	_foe_switching = false



func _foe_mode() -> int:
	if get_node_or_null("/root/LanCampaign") != null and launching_lan(): return CreatureDef.Mode.BATTLE_AI
	return CreatureDef.Mode.REMOTE if online else CreatureDef.Mode.BATTLE_AI




func _pull_herd(w: CreatureDef) -> void :
	if not w.has_meta("herd"):
		return
	var h = w.get_meta("herd")
	if not is_instance_valid(h):
		return
	for m in h.members:
		if extra_foes.size() >= 2:
			break
		if not is_instance_valid(m) or m == w or m == wild or extra_foes.has(m):
			continue
		if not m.alive() or m.mode != CreatureDef.Mode.WANDER or m.leaving:
			continue
		extra_foes.append(m)
	HerdScript.alert(w, extra_foes)
	h.reform()



func _prep_extra_foe(e: CreatureDef, p: Node3D) -> void :
	e.mode = CreatureDef.Mode.IDLE
	e.velocity = Vector3.ZERO
	e.opponent = null
	e.ai_uses_moves = true
	var tier: = AiBrains.wild_tier(Game.event_zone(p), int(e.level), false)
	if e.has_meta("add_ai_tier") and String(e.get_meta("add_ai_tier")) != "":
		tier = String(e.get_meta("add_ai_tier"))
	if tier != "":
		e.combat.auto_brain(tier, "")
	_join_fight(e)
	var to_p: = p.global_position - e.global_position
	to_p.y = 0.0
	if to_p.length() > 0.01:
		e.facing = to_p.normalized()
	if not e.fainted.is_connected(_on_fainted):
		e.fainted.connect(_on_fainted)
	if not challenge:
		Game.state.mark_seen(e.species)
	e.refresh_label()




func _bind_guest(g: CreatureDef) -> void :
	if not allies.has(g):
		allies.append(g)
	g.ai_uses_moves = true
	start_ally_ai(g)
	_join_fight(g)
	g.mode = CreatureDef.Mode.IDLE
	g.velocity = Vector3.ZERO
	if not g.fainted.is_connected(_on_fainted):
		g.fainted.connect(_on_fainted)
	g.refresh_label()



func _send_next_guest(at: Vector3, line: Dictionary = {}, pick = null) -> void :
	await get_tree().create_timer(0.6).timeout
	if line.is_empty():
		line = {"queue": guest_queue, "trainer": guest_trainer}
	var queue: Array = line.queue
	if not in_battle or _ending or (queue.is_empty() and pick == null):
		return
	var mon = pick if pick != null else queue.pop_front()
	var trainer: Node3D = line.get("trainer")
	var parent: Node = trainer.get_parent() if is_instance_valid(trainer) else get_tree().current_scene
	var body: CreatureDef = Encounters.spawn_mon(mon, parent, at, false)
	fit_cast(body)
	body.set_meta("guest_line", line)
	if is_instance_valid(trainer):
		trainer_callout(trainer, "Go, %s!" % String(mon.species).to_upper())
	guest_allies.append(body)
	_bind_guest(body)
	body.mode = CreatureDef.Mode.BATTLE_AI
	_retarget_allies()



func _guest_line(g: Node) -> Dictionary:
	if is_instance_valid(g) and g.has_meta("guest_line"):
		return g.get_meta("guest_line")
	return {"queue": guest_queue, "trainer": guest_trainer}



func _guests_waiting() -> bool:
	if not guest_queue.is_empty():
		return true
	for l in guest_lines:
		if not (l.queue as Array).is_empty():
			return true
	return false


var _guest_swapping: = false



func swap_guest(old: CreatureDef, line: Dictionary, mon) -> void :
	if _guest_swapping or not in_battle or _ending or not is_instance_valid(old) or not guest_allies.has(old):
		return
	_guest_swapping = true
	print("[battle] guest swap: %s -> %s" % [old.species, mon.species])
	var trainer: Node3D = line.get("trainer")
	var at: Vector3 = old.global_position
	var ball: String = old.mon.ball if old.mon else "poke_ball"
	var queue: Array = line.queue
	queue.erase(mon)
	queue.append(old.mon)
	allies.erase(old)
	guest_allies.erase(old)
	for f in foes():
		if f.opponent == old:
			f.opponent = null
	if is_instance_valid(trainer):
		trainer_callout(trainer, "Come back, %s!" % old.species, ball)
		CaptureFX.recall(self, trainer.get_parent(), trainer, old, ball)
	await get_tree().create_timer(Game.RECALL_SECS).timeout
	if is_instance_valid(old):
		old.queue_free()
	if in_battle and not _ending:
		await _send_next_guest(at, line, mon)
	_guest_swapping = false




func swap_wild(body: CreatureDef) -> void :
	var old: = wild
	if is_instance_valid(old):
		_combatants.erase(old)
		old.remove_from_group("combatant")
		if old.fainted.is_connected(_on_fainted):
			old.fainted.disconnect(_on_fainted)
		for a in allies:
			if is_instance_valid(a) and a.opponent == old:
				a.opponent = null
	_bind_foe(body)



func foes() -> Array:
	var out: Array = []
	for f in [wild] + extra_foes:
		if is_instance_valid(f) and f.mode != CreatureDef.Mode.FAINTED and f.alive():
			out.append(f)
	return out



func _retarget_allies() -> void :
	var live: = foes()
	if live.is_empty():
		return
	for a in allies:
		if not is_instance_valid(a) or (is_instance_valid(a.opponent) and live.has(a.opponent)):
			continue
		var best = live[0]
		for f in live:
			if f.global_position.distance_to(a.global_position) < best.global_position.distance_to(a.global_position):
				best = f
		a.opponent = best



func cycle_target() -> void :
	var live: = foes()
	if not in_battle or _intro or live.size() < 2 or not is_instance_valid(partner):
		return
	set_target(live[(maxi(live.find(partner.opponent), -1) + 1) % live.size()])



func set_target(f: Node) -> bool:
	if not in_battle or _intro or not is_instance_valid(partner) or not foes().has(f) or partner.opponent == f:
		return false
	partner.opponent = f
	Audio.ui("sfx/ui/swap_control")
	return true




func _bind_foe(w: CreatureDef) -> void :
	wild = w
	w.mode = _foe_mode()
	w.velocity = Vector3.ZERO
	w.opponent = null
	w.ai_uses_moves = true
	_join_fight(w)
	var p: = Dialogue.player()
	if p:
		var to_p: Vector3 = p.global_position - w.global_position
		to_p.y = 0.0
		if to_p.length() > 0.01:
			w.facing = to_p.normalized()
	if not w.fainted.is_connected(_on_fainted):
		w.fainted.connect(_on_fainted)
	for a in allies:
		if is_instance_valid(a) and a.mode != CreatureDef.Mode.FAINTED:
			a.opponent = w
			a.last_hit_by = null
			var to_w: Vector3 = w.global_position - a.global_position
			to_w.y = 0.0
			if to_w.length() > 0.01:
				a.facing = to_w.normalized()
			if is_instance_valid(_arena):
				_arena.track(a, w)
	if is_instance_valid(partner) and partner.alive():
		w.opponent = partner
	else:
		var a: = ai_ally()
		if a:
			w.opponent = a
	w.hold_attacks(WILD_OPENING_DELAY)
	w.refresh_label()
	print("[battle] next trainer mon: %s Lv%d" % [w.species, w.level])



func _trainer_rect(tb: Dictionary) -> Rect2:
	var c: Vector3 = tb.get("center", Vector3.ZERO)
	var a: Vector2 = tb.get("arena", Vector2(10, 6))
	return Rect2(c.x - a.x * 0.5, c.z - a.y * 0.5, a.x, a.y)



func _place_trainer(t: Node3D, pos: Vector3, dir: Vector3) -> void :
	pos.y = t.global_position.y if "swim_sink" in t and t.swim_sink > 0.0 else Transitions.ground_y(pos, t.global_position.y)
	t.global_position = pos
	Transitions.reset_interp(t)
	if t.has_method("face"):
		t.face(dir)
	elif t.has_method("face_toward"):
		t.face_toward(pos + dir)





func _no_healthy_msg() -> void :
	Dialogue.msg(no_healthy_text())


func no_healthy_text() -> String:
	return "All your Pokémon have fainted!" + (" Press H to heal." if DebugScript.enabled
		else " They need a Pokémon Center.")






func whiteout_for(result: String) -> bool:
	if challenge or no_whiteout or result == "aborted":
		return false
	if Game.state.party.is_empty() or Game.state.first_healthy() >= 0:
		return false
	if int(trainer_battle.get("roster", 0)) > 0:
		return false
	return not bool(trainer_battle.get("scripted", false))



func engage(w: CreatureDef) -> void :
	if Game.is_busy() or not is_instance_valid(w) or not w.alive() or Game.night_prologue_active():
		return

	if w.flying or w.away:
		return
	var p: = Dialogue.player()
	if p == null:
		return
	if Game.party.is_empty():
		Dialogue.msg("You don't have any Pokémon! Get one at the lab first.")
		return
	var idx: = Game.state.first_healthy()
	if idx < 0:
		_no_healthy_msg()
		return
	_arena_deep = _wild_arena_deep(p, w)
	if not sea_ready():
		Dialogue.msg("The Pokémon you surf on can't fight out at sea — you need another one in your party.")
		return
	p.face_toward(w.global_position)
	start_battle(w)



func _safari_fight(w: CreatureDef) -> void :
	var f: = SafariFightScript.new()
	add_child(f)
	await f.run(w)




func _dynamic_rids() -> Array[RID]:
	var out: Array[RID] = []
	var p: = Dialogue.player()
	if p is CollisionObject3D:
		out.append(p.get_rid())
	for w in get_tree().get_nodes_in_group("wild"):
		if w is CollisionObject3D:
			out.append(w.get_rid())
	for n in get_tree().get_nodes_in_group("npc"):
		if n is CollisionObject3D:
			out.append(n.get_rid())
	return out



func _water_rects() -> Array:
	return Transitions.water_rects()



func _land_fraction(rect: Rect2) -> float:
	if rect.size.x <= 0.0:
		return 1.0
	var n: = 5
	var dry: = 0
	for i in n:
		for j in n:
			var x: = rect.position.x + rect.size.x * (i + 0.5) / n
			var z: = rect.position.y + rect.size.y * (j + 0.5) / n
			if Transitions.surface_at(x, z) != Water.Surface.DEEP:
				dry += 1
	return float(dry) / float(n * n)










func place_ok(who, x: float, z: float) -> bool:
	var f: = _flags_of(who)
	if f.is_empty() or String(f.locomotion) != "ground":
		return true

	if _on_pad(x, z):
		return true
	var s: = Transitions.surface_at(x, z)
	if bool(f.fish):
		return s != Water.Surface.GROUND
	if bool(f.swimmer):
		return true
	return s != Water.Surface.DEEP



func _flags_of(who) -> Dictionary:
	if who == null:
		return {}
	if who is String:
		return _species_flags(who)
	if not is_instance_valid(who):
		return {}
	if who.get("combat") != null:
		var c = who.combat
		return {"locomotion": c.locomotion, "swimmer": c.swimmer, "fish": c.fish, "pad": c.pad}
	if who.get("swimmer") != null:
		return {"locomotion": who.locomotion, "swimmer": who.swimmer, "fish": who.fish, "pad": who.pad}
	if who.get("species") != null:
		return _species_flags(String(who.species))
	return {}


func _species_flags(name: String) -> Dictionary:
	var sp: = DexData.species(name)
	if sp.is_empty():
		return {}
	return {"locomotion": DexData.locomotion(name), 
		"swimmer": bool(sp.get("swimmer", false)), "fish": bool(sp.get("fish", false)), 
		"pad": bool(sp.get("pad", false))}




func _is_water_type(who) -> bool:
	if who is String:
		return "water" in Array(DexData.species(who).get("types", []))
	if not is_instance_valid(who):
		return false
	if who.get("combat") != null:
		return "water" in Array(who.combat.types)
	if who.get("types") != null:
		return "water" in Array(who.types)
	if who.get("species") != null:
		return "water" in Array(DexData.species(String(who.species)).get("types", []))
	return false



func _place_pred(who) -> Callable:
	return func(x: float, z: float) -> bool: return place_ok(who, x, z)



func _wild_keeps_water(w: CreatureDef) -> bool:
	var f: = _flags_of(w)
	return bool(f.get("swimmer", false))\
	and Transitions.surface_at(w.global_position.x, w.global_position.z) != Water.Surface.GROUND






func nearest_ok(spot: Vector3, who, rect: Rect2, blocked: = Callable(), rings: = 8) -> Vector3:



	if _prefers_ground(who) and _spot_ok(spot, who, rect, blocked) and _want_ok(Water.Surface.GROUND, spot.x, spot.z)\
	and _shore_margin_ok(Water.Surface.GROUND, who, spot.x, spot.z):
		return spot
	for want in _surface_prefs(who, rect):
		var found: = _nearest_pass(spot, who, rect, blocked, rings, want)
		if found.is_finite():
			return found
	return spot



const WANT_ANY: = -1
const WANT_WATER: = -2
const WANT_PAD: = -3





func _surface_prefs(who, rect: Rect2) -> Array:
	var f: = _flags_of(who)
	if f.is_empty() or String(f.locomotion) != "ground":
		return [WANT_ANY]
	if bool(f.fish):
		return [WANT_WATER, WANT_ANY]
	if bool(f.swimmer):




		if not _is_water_type(who):
			return [Water.Surface.GROUND, WANT_ANY]
		return [Water.Surface.DEEP, WANT_WATER, WANT_ANY]
	if _arena_has_pad(rect):
		return [WANT_PAD, Water.Surface.GROUND, WANT_ANY]
	return [Water.Surface.GROUND, WANT_ANY]


func _want_ok(want: int, x: float, z: float) -> bool:
	if want == WANT_ANY:
		return true



	var s: = WANT_PAD if _on_pad(x, z) else Transitions.surface_at(x, z)
	if want == WANT_WATER:
		return s == Water.Surface.SHALLOW or s == Water.Surface.DEEP
	return s == want



func _on_pad(x: float, z: float) -> bool:
	for b in get_tree().get_nodes_in_group("water_platform"):
		if is_instance_valid(b) and b.has_method("covers") and b.covers(x, z):
			return true
	return false




func _arena_has_pad(rect: Rect2) -> bool:
	if rect.size.x <= 0.0:
		return false
	for b in get_tree().get_nodes_in_group("water_platform"):
		if is_instance_valid(b) and rect.has_point(Vector2(b.global_position.x, b.global_position.z)):
			return true
	return false


func _prefers_ground(who) -> bool:
	var f: = _flags_of(who)
	if f.is_empty() or String(f.locomotion) != "ground" or bool(f.fish):
		return false


	if bool(f.swimmer):
		return not _is_water_type(who)
	return true

func _nearest_pass(spot: Vector3, who, rect: Rect2, blocked: Callable, rings: int, want: int) -> Vector3:
	if _spot_ok(spot, who, rect, blocked)\
	and _want_ok(want, spot.x, spot.z) and _shore_margin_ok(want, who, spot.x, spot.z):
		return spot
	for r in range(1, rings + 1):
		for i in range( - r, r + 1):
			for j in range( - r, r + 1):
				if maxi(absi(i), absi(j)) != r:
					continue
				var p: = Vector3(spot.x + i, spot.y, spot.z + j)
				if not _spot_ok(p, who, rect, blocked):
					continue
				if not _want_ok(want, p.x, p.z) or not _shore_margin_ok(want, who, p.x, p.z):
					continue
				return p
	return Vector3.INF






const SHORE_MARGIN: = 1.0


func _shore_margin_ok(want: int, who, x: float, z: float) -> bool:
	if want != Water.Surface.GROUND:
		return true
	var f: = _flags_of(who)
	if f.is_empty() or String(f.locomotion) != "ground" or bool(f.get("fish", false)) or bool(f.get("swimmer", false)):
		return true
	var rects: Array = Transitions.water_rects()
	return rects.is_empty() or Water.distance_to_water(rects, x, z) >= SHORE_MARGIN


func _spot_ok(p: Vector3, who, rect: Rect2, blocked: Callable) -> bool:
	if rect.size.x > 0.0 and not rect.has_point(Vector2(p.x, p.z)):
		return false
	if blocked.is_valid() and bool(blocked.call(p.x, p.z)):
		return false
	return place_ok(who, p.x, p.z)



func _settle(c: CreatureDef, who) -> void :
	if not is_instance_valid(c) or arena_rect.size.x <= 0.0:
		return
	if place_ok(who, c.global_position.x, c.global_position.z):
		return
	var at: = nearest_ok(c.global_position, who, arena_rect, _blocked_at(c.global_position.y))
	c.global_position = Vector3(at.x, Transitions.ground_y(at, c.global_position.y), at.z)
	Transitions.reset_interp(c)








func _blocked_at(level: float, block_water: = false, ignore: = []) -> Callable:
	var world: = get_viewport().world_3d if get_viewport() else null
	var space: = world.direct_space_state if world else null
	var shape: = SphereShape3D.new()
	shape.radius = 0.35
	var water: = _water_rects() if block_water else []
	var exclude: = _dynamic_rids()
	exclude.append_array(ignore)
	return func(x: float, z: float) -> bool:
		for r in water:
			if r.has_point(Vector2(x, z)):
				return true
		if space == null:
			return false
		var params: = PhysicsShapeQueryParameters3D.new()
		params.shape = shape
		params.transform = Transform3D(Basis(), Vector3(x, level + 0.6, z))
		params.collision_mask = ARENA_BLOCK_LAYERS
		params.exclude = exclude
		params.collide_with_areas = false
		if not space.intersect_shape(params, 1).is_empty():
			return true


		var down: = PhysicsRayQueryParameters3D.create(Vector3(x, level + 1.0, z), 
			Vector3(x, level - 1.5, z), ARENA_BLOCK_LAYERS | Transitions.GROUND_LAYER)
		down.collide_with_areas = false
		return space.intersect_ray(down).is_empty()





func _arena_clear_rids() -> Array[RID]:
	var out: Array[RID] = []
	for n in get_tree().get_nodes_in_group("arena_clear"):
		if not is_instance_valid(n):
			continue
		for c in n.get_children():
			if c is CollisionObject3D:
				out.append((c as CollisionObject3D).get_rid())
	return out






func _clear_arena_props(rect: Rect2) -> void :
	var area: = rect.grow(1.0)
	for n in get_tree().get_nodes_in_group("arena_clear"):
		if not is_instance_valid(n) or not n.has_method("arena_hide"):
			continue
		if area.intersects(n.arena_rect()):
			n.arena_hide(true)
			_arena_cleared.append(n)





func _restore_arena_props() -> void :
	for n in _arena_cleared:
		if not is_instance_valid(n):
			continue
		if _tomb_overlaps_body(n):
			if not _arena_deferred.has(n):
				_arena_deferred.append(n)
		else:
			n.arena_hide(false)
	_arena_cleared.clear()




func _tomb_overlaps_body(n: Node3D) -> bool:
	if not n.has_method("arena_rect"):
		return false
	var r: Rect2 = n.arena_rect().grow(TOMB_BODY_RADIUS)
	for b in _arena_bodies():
		var p: Vector3 = b.global_position
		if r.has_point(Vector2(p.x, p.z)):
			return true
	return false


func _arena_bodies() -> Array:
	var out: Array = []
	var p: = Dialogue.player()
	if p != null:
		out.append(p)
	for c in Game.companions.values():
		if is_instance_valid(c):
			out.append(c)
	for c in allies:
		if is_instance_valid(c) and not out.has(c):
			out.append(c)
	return out



func _tick_deferred_tombs() -> void :
	for i in range(_arena_deferred.size() - 1, -1, -1):
		var n = _arena_deferred[i]
		if not is_instance_valid(n):
			_arena_deferred.remove_at(i)
			continue
		if not _tomb_overlaps_body(n):
			n.arena_hide(false)
			_arena_deferred.remove_at(i)




func _tomb_blocked(x: float, z: float) -> bool:
	for n in get_tree().get_nodes_in_group("arena_clear"):
		if is_instance_valid(n) and n.has_method("arena_rect")\
		and n.arena_rect().grow(TOMB_BODY_RADIUS).has_point(Vector2(x, z)):
			return true
	return false




func _off_tombs(spot: Vector3, blocked: = Callable(), step: = 0.45, rings: = 8) -> Vector3:
	if spot.is_finite() and not _tomb_blocked(spot.x, spot.z):
		return spot
	for r in range(1, rings + 1):
		for i in range( - r, r + 1):
			for j in range( - r, r + 1):
				if maxi(absi(i), absi(j)) != r:
					continue
				var q: = Vector3(spot.x + i * step, spot.y, spot.z + j * step)
				if _tomb_blocked(q.x, q.z):
					continue
				if blocked.is_valid() and bool(blocked.call(q.x, q.z)):
					continue
				return q
	return spot




func _checked_target(from: Vector3, to: Vector3) -> Vector3:
	var world: = get_viewport().world_3d if get_viewport() else null
	if world == null:
		return to
	var a: = Vector3(from.x, to.y + 0.6, from.z)
	var b: = Vector3(to.x, to.y + 0.6, to.z)
	var d: = b - a
	if d.length() < 0.05:
		return to
	var q: = PhysicsRayQueryParameters3D.create(a, b, ARENA_BLOCK_LAYERS)
	q.exclude = _dynamic_rids()
	var hit: = world.direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return to
	var land: Vector3 = hit.position - d.normalized() * 0.6
	land.y = Transitions.ground_y(land, to.y)
	return land



func _hop_to(c: Node3D, to: Vector3, secs: = 0.35) -> void :



	var checked: = _checked_target(c.global_position, to)
	if checked != to:
		var lvl: = Transitions.ground_y(checked, checked.y)
		var blk: Callable = _blocked_at(lvl)
		if bool(blk.call(checked.x, checked.z)):
			checked = to
	to = checked
	to.y = Transitions.ground_y(to, c.global_position.y)
	var from: = c.global_position
	var tw: = create_tween()
	tw.tween_method( func(t: float):
		if is_instance_valid(c):
			c.global_position = from.lerp(to, t) + Vector3(0, sin(t * PI) * 0.9, 0), 0.0, 1.0, secs)
	await tw.finished



func _join_fight(c: Node) -> void :
	c.combat.seed_meal()
	if not c.is_in_group("combatant"):
		c.add_to_group("combatant")
	if not _combatants.has(c):
		_combatants.append(c)
		combatant_joined.emit(c)

		if c.combat.can_fly():
			c.combat.flight = c.combat.Flight.AIRBORNE
			c.combat.flight_t = 0.0



func _intro_ok(w: CreatureDef) -> bool:
	if in_battle and not _ending and wild == w and is_instance_valid(w):
		return true
	if _intro and in_battle and not _ending:
		end_battle("aborted")
	return false



func _intro_wait(secs: float) -> void :
	var t: = 0.0
	while t < secs and not _intro_skip:
		await get_tree().process_frame
		t += get_process_delta_time()



func _wild_appears(w: CreatureDef) -> void :
	Audio.cry(w.species, w.global_position)
	if w.is_shiny():
		Vfx.shiny_sparkle(w)
	var spr: Node3D = w.get_node("Sprite3D")
	var lbl: Node3D = w.get_node_or_null("Label3D")
	var bang: = Label3D.new()
	bang.text = "!"
	bang.font_size = 110
	bang.outline_size = 20
	bang.modulate = Color(1.0, 0.35, 0.25)
	bang.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bang.no_depth_test = true
	bang.position = Vector3(0, (lbl.position.y if lbl else 1.8) + 0.7, 0)
	w.add_child(bang)
	var base: = spr.position
	var tw: = create_tween()
	tw.tween_property(bang, "scale", Vector3.ONE, 0.15).from(Vector3.ONE * 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(spr, "position", base + Vector3(0, 0.45, 0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(spr, "position", base, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(spr, "position", base + Vector3(0, 0.25, 0), 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(spr, "position", base, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var cam: = Dialogue.camera_rig()
	if cam:
		cam.shake(0.08)
	await tw.finished
	await _intro_wait(0.25)
	if is_instance_valid(bang):
		bang.queue_free()






func _hide_others(keep: Array) -> void :
	var list: Array = get_tree().get_nodes_in_group("wild")
	var rider: = Dialogue.player()
	var ride: int = rider.riding_slot() if rider != null and rider.has_method("riding_slot") else -1
	for k in Game.companions.keys():
		if k != ride:
			list.append(Game.companions[k])
	for c in list:
		if not is_instance_valid(c) or keep.has(c) or _hidden.has(c) or c.evolving:
			continue
		_hidden[c] = [c.collision_layer, c.collision_mask, c.process_mode]
		c.velocity = Vector3.ZERO
		c.collision_layer = 0
		c.collision_mask = 0
		c.process_mode = Node.PROCESS_MODE_DISABLED
		if c.is_wild:
			c.hide_nameplate_now()
		_fade_body(c, true)


func _unhide(c: Node) -> void :
	if not _hidden.has(c):
		return
	var s: Array = _hidden[c]
	_hidden.erase(c)
	if not is_instance_valid(c):
		return
	c.collision_layer = s[0]
	c.collision_mask = s[1]
	c.process_mode = s[2]
	c.visible = true
	if c.is_wild:
		c.peace_timer = maxf(c.peace_timer, 3.0)
		c.refresh_label()
	_fade_body(c, false)


func _show_hidden() -> void :
	for c in _hidden.keys():
		if is_instance_valid(c):
			_unhide(c)
		else:
			_hidden.erase(c)





func _fade_body(c: Node3D, out: bool) -> void :
	var tw: = create_tween().set_parallel(true)
	for g in c.find_children("*", "GeometryInstance3D", true, false):
		tw.tween_property(g, "transparency", 1.0 if out else 0.0, 0.3).from(0.0 if out else 1.0)
	if out:
		tw.chain().tween_callback( func():
			if is_instance_valid(c) and _hidden.has(c):
				c.visible = false)


func _deploy_fighter(i: int, control: = true) -> void :
	_free_entry = _ko_entry or free_switch_t > 0.0
	if not _ko_entry:
		free_switch_t = 0.0
	var p: = Dialogue.player()
	var at: Vector3
	if _lead_spot.is_finite():
		at = _lead_spot
		if not control:

			var side: = Vector3(_lead_spot.z - p.global_position.z, 0, p.global_position.x - _lead_spot.x)
			at += side.normalized() * 1.6 if side.length() > 0.01 else Vector3(1.6, 0, 0)
	else:
		at = p.global_position
		if is_instance_valid(wild):
			var to_w: = wild.global_position - p.global_position
			to_w.y = 0.0
			at += to_w.normalized() * minf(1.5, to_w.length() * 0.5) if to_w.length() > 0.01 else Vector3(0, 0, -1.2)
		if not control and is_instance_valid(wild):
			var to_w2: = wild.global_position - p.global_position
			to_w2.y = 0.0
			if to_w2.length() > 0.01:
				at += Vector3( - to_w2.z, 0.0, to_w2.x).normalized() * 1.6
	if p and p.has_method("riding_slot") and p.riding_slot() == i:
		p.dismount(true)
	Dialogue.msg("Go, %s!" % Game.party[i].species, 1.5, "info")
	trainer_callout(Dialogue.player(), "Go, %s!" % Game.party[i].species, Game.party[i].ball)


	if p and not (control and _lead_spot.is_finite()):
		at = _checked_target(p.global_position + Vector3(0, 1.2, 0), at)
	var c: = await Game.send_out(i, at)
	if c and in_battle and not _ending:
		await _set_fighter(c, control)




func _sync_board_level() -> void :
	if not training or not is_instance_valid(wild) or not is_instance_valid(partner):
		return
	var lv: int = partner.level
	if wild.level == lv:
		return
	wild.level = lv
	wild.mon.level = lv
	wild.mon.recalc()
	wild.mon.heal_full()
	wild.sync_from_mon()


func _set_fighter(c: CreatureDef, control: = true) -> void :
	if control:
		partner = c
		_sync_board_level()
	if not allies.has(c):
		allies.append(c)
	if c.mon and not _participants.has(c.mon):
		_participants.append(c.mon)
	if c.mon and int(trainer_battle.get("roster", 0)) > 0 and not (trainer_battle.used as Array).has(c.mon):
		(trainer_battle.used as Array).append(c.mon)
	_unhide(c)
	c.ai_uses_moves = true
	start_ally_ai(c)
	_join_fight(c)
	if not c.moves.is_empty() and not c.moves.has(c.selected_move):
		c.selected_move = String(c.moves[0])
	if _intro:
		c.mode = CreatureDef.Mode.IDLE
		c.velocity = Vector3.ZERO
	else:
		c.mode = _fighter_mode(c)
	if is_instance_valid(wild):
		c.opponent = wild
		if not is_instance_valid(wild.opponent) or not wild.opponent.alive():
			wild.opponent = c
		var to_w: = wild.global_position - c.global_position
		to_w.y = 0.0
		if to_w.length() > 0.01:
			c.facing = to_w.normalized()
		if is_instance_valid(_arena):
			_arena.track(c, wild)
	if not c.fainted.is_connected(_on_fainted):
		c.fainted.connect(_on_fainted)
	c.refresh_label()
	var cam: = Dialogue.camera_rig()
	if cam and is_instance_valid(wild):


		cam.focus_fighters(_cam_fighters())
	if not _intro:
		c.mode = CreatureDef.Mode.IDLE
		await Vfx.warm_combatants([c])
		if not is_instance_valid(c) or not in_battle or _ending or not allies.has(c) or not c.alive():
			return
		c.mode = _fighter_mode(c)
		if not _free_entry:
			c.combat.entry_cooldown()
	Game.party_changed.emit()


func _switch_fighter(i: int, forced: = false) -> void :
	var lan = get_node_or_null("/root/LanCampaign")
	if lan != null and lan.coop_battle_active(): return
	if not forced and escape_blocked(partner):
		return
	if is_spar():
		Dialogue.msg("Only the Pokémon learning the move may fight this spar.")
		return
	if i >= 0 and i < Game.party.size() and not roster_ok(Game.party[i]):
		Dialogue.msg("Only %d Pokémon may fight here!" % int(trainer_battle.get("roster", 0)), 2.0, "info")
		return
	if online_guest:
		return
	close_party_ring()
	_switching = true
	_an_switches += 1
	var old: = partner
	partner = null
	allies.erase(old)
	if is_instance_valid(wild) and wild.opponent == old:
		wild.opponent = null
	if is_instance_valid(old):
		for k in Game.companions.keys():
			if Game.companions[k] == old:
				Game.recall(k)
	await _deploy_fighter(i)
	_switching = false




func _ally_slot(i: int) -> void :
	if BATTLE_SIZE < 2 or _switching or Progression._capturing or _ending or _intro:
		return
	if max_fighters > 0 and ai_ally() == null and allies.size() >= max_fighters:
		Dialogue.msg("No room for a second fighter!", 1.5, "info")
		return
	if escape_blocked(ai_ally()):
		return
	close_party_ring()
	if not trainer_battle.is_empty():
		return
	if Game.state.is_out(i) and allies.has(Game.companions[i]):
		return
	if Game.party[i].egg:
		Game._ball_notice(null, "Egg", "An Egg can't battle yet.")
		return
	if Game.party[i].hp <= 0:
		Dialogue.msg("%s has fainted and can't battle!" % Game.party[i].species, 2.5, "faint")
		return
	_an_switches += 1
	var old: = ai_ally()
	_switching = true
	if old:
		allies.erase(old)
		if is_instance_valid(wild) and wild.opponent == old:
			wild.opponent = null
		for k in Game.companions.keys():
			if Game.companions[k] == old:
				Game.recall(k)
	await _deploy_fighter(i, not is_instance_valid(partner))
	_switching = false




func _faint_beat(c: CreatureDef) -> void :
	var species: String = c.species
	var head: Vector3 = c.head_pos(1.1)
	var owner_id: = str(c.get_instance_id())
	await get_tree().create_timer(Combatant.KO_PAUSE, true, false, true).timeout
	if not in_battle or _ending:
		return
	get_node("/root/Vfx").popup(head, "%s FAINTED!" % species.to_upper(), CALLOUT_COL, 1.2, "callout", 1, owner_id)
	_slow_in(0.25)
	await get_tree().create_timer(0.7, true, false, true).timeout
	_slow_out()
	await get_tree().create_timer(1.0).timeout


func _on_fainted(c: CreatureDef) -> void :
	var lan = get_node_or_null("/root/LanCampaign")
	if lan != null and launching_lan():
		lan.fainted(c)
		return
	if not in_battle or _ending or Progression._capturing:
		return
	if challenge and not get_node("/root/BattleTower").is_rental(get_node("/root/BattleTower").current):
		get_node("/root/BattleTower").stop_timer()
	if c == wild:
		_drop_boss_adds()
	var foe_mon = c.mon
	var ev_recipient: RefCounted
	var earned_evs: Dictionary = {}

	if c == wild or extra_foes.has(c):
		var killer = c.last_hit_by
		if not online and not challenge and not is_spar() and is_instance_valid(killer) and allies.has(killer) and not guest_allies.has(killer):
			var evs: Dictionary = killer.gain_evs_from(c, false)
			ev_recipient = killer.mon
			earned_evs = evs
			if not _ev_results.has(killer.mon):
				_ev_results[killer.mon] = {}
			for stat in evs:
				_ev_results[killer.mon][stat] = int(_ev_results[killer.mon].get(stat, 0)) + int(evs[stat])
			print("[ev] %s landed the last hit: %s" % [killer.species, evs])
	if c == wild and not online and not trainer_battle.is_empty() and _next_trainer_mon() >= 0:
		free_switch_t = FREE_SWITCH_WINDOW
	await _faint_beat(c)
	if not in_battle or _ending:
		return
	if (c == wild or extra_foes.has(c)) and foes().size() > 0:

		if not online and not challenge and not is_spar():

			_exp_results.append_array(Progression.award_exp(foe_mon, false, false))
			_foe_levels.append(int(foe_mon.level))
			var rec: = Progression._body_of(ev_recipient) if ev_recipient != null else null
			if rec:
				rec.combat.show_ev_popup(earned_evs)
		extra_foes.erase(c)
		if c == wild:
			wild = foes()[0]
			extra_foes.erase(wild)
		_retarget_allies()
		for f in foes():
			if f.opponent == c:
				f.opponent = null
		Game.party_changed.emit()
		return
	if c == wild and boss_hook.is_valid() and await boss_hook.call(c):
		return
	if c == wild:
		var is_trainer: = not trainer_battle.is_empty()
		var has_next: = is_trainer and _next_trainer_mon() >= 0
		if not online and not challenge and not is_spar():



			_exp_results.append_array(Progression.award_exp(foe_mon, is_trainer, not has_next))
			_foe_levels.append(int(foe_mon.level))
			var recipient: = Progression._body_of(ev_recipient) if ev_recipient != null else null
			if recipient:
				recipient.combat.show_ev_popup(earned_evs)
		if has_next:

			Game.party_changed.emit()
			trainer_battle["fainted"] = int(trainer_battle.get("fainted", 0)) + 1
			await _send_next_trainer_mon()
			return
		Audio.clear_jingles()

		var holds: bool = is_trainer and not (trainer_battle.get("defeat", []) as Array).is_empty()
		Audio.jingle("music/victory" if not is_trainer else "music/victory_trainer", false, holds)
		Game.party_changed.emit()
		end_battle("won")
		return
	if guest_allies.has(c):
		allies.erase(c)
		guest_allies.erase(c)
		Dialogue.msg("%s fainted!" % c.species, 2.0, "faint")
		for f in foes():
			if f.opponent == c:
				f.opponent = null
		var gpos: Vector3 = c.global_position
		var line: Dictionary = _guest_line(c)
		c.queue_free()
		if not (line.get("queue", []) as Array).is_empty():
			await _send_next_guest(gpos, line)
			return
		if not is_instance_valid(partner) and ai_ally() == null and guest_ally() == null and _next_healthy(false) < 0 and not _guests_waiting():
			end_battle("lost")
		return
	if not allies.has(c):
		return
	var was_controlled: = c == partner




	if not _picking:
		close_party_ring()
	allies.erase(c)
	if c.mon != null and not is_spar():
		c.mon.set_friend(c.mon.friend - Game.FAINT_LOSS)
	if was_controlled:
		partner = null
	if is_instance_valid(wild) and wild.opponent == c:
		wild.opponent = null
	Dialogue.msg("%s fainted!" % c.species, 2.0, "faint")
	if not online:
		Analytics.count_faint()
	Game.party_changed.emit()
	for k in Game.companions.keys():
		if Game.companions[k] == c:
			Game.recall(k)

	await get_tree().create_timer(Game.RECALL_SECS).timeout
	if not in_battle or _ending:
		return
	var a: = ai_ally()
	if was_controlled and a:
		partner = a
		a.mode = _fighter_mode(a)
		Dialogue.msg("Go, %s!" % a.mon.display_name, 1.2, "info")
		trainer_callout(Dialogue.player(), "Go, %s!" % a.mon.display_name, a.mon.ball)
		Game.party_changed.emit()
		return
	if is_instance_valid(partner) or a:
		return
	var nxt: = _next_healthy(false)
	if nxt >= 0:
		nxt = ( await _pick_lead(nxt)).lead
		if not in_battle or _ending:
			return
		_switching = true
		_ko_entry = true
		await _deploy_fighter(nxt)
		_ko_entry = false
		_switching = false
	elif guest_ally() == null and not _guests_waiting():
		end_battle("lost")



func _auto() -> bool:
	return Debug.auto_dialog or autopilot



func wait_confirm() -> void :
	UiKit.setup_input()
	if _auto():
		await get_tree().create_timer(0.35).timeout
		return
	await get_tree().process_frame
	while not Input.is_action_just_pressed("pk_ok"):
		await get_tree().process_frame




func disc_flash(from: Vector3, to: Vector3) -> void :
	if is_instance_valid(_disc_view):
		_disc_view.blink(from, to)


func thunder_flash(at: Vector3) -> void :
	if is_instance_valid(_arena):
		_arena.thunder_flash(at)
	var seq: = get_tree().get_first_node_in_group("gym_sequence") if get_tree() != null else null
	if seq != null and seq.has_method("wire_touch"):
		seq.wire_touch(at)




func _prize_level() -> int:
	if not _foe_levels.is_empty():
		return int(_foe_levels.back())
	var mons: Array = trainer_battle.get("mons", [])
	if not mons.is_empty():
		return int(mons[mons.size() - 1].level)
	return 1



func _trainer_exp_reward() -> int:
	var kind: = "wild"
	if not trainer_battle.is_empty():
		match String(trainer_battle.get("class", "")):
			"gym_leader": kind = "gym_leader"
			"rival": kind = "rival"
			"rocket_executive": kind = "boss"
			_: kind = "trainer"
	var lv: = 0.0
	for m in Game.state.party:
		lv += float(m.level)
	return TrainerLevel.reward(_foe_levels, lv / maxf(Game.state.party.size(), 1.0), kind)




func _drop_battle_sheets() -> void :
	var keep: = PokemonSprites.party_keys(Game.party)
	for c in get_tree().get_nodes_in_group("wild"):
		if c is CreatureDef and c.mode in CreatureDef.FIGHT_MODES:
			keep[PokemonSprites._key(c.look_species(), c.is_shiny())] = true
	PokemonSprites.drop_full(keep)


func end_battle(result: String) -> void :
	if not in_battle or _ending:
		return
	Controls.close_items_page()
	close_party_ring()
	clear_move_fields()
	_field_clear()
	Vfx.clear_dig_marks()
	_ending = true

	if _slow_users > 0:
		_slow_users = 0
		Engine.time_scale = _slow_base
	if result == "fled" or result == "lost" or result == "aborted":
		Audio.clear_jingles()
	match result:
		"lost": Audio.jingle("music/defeat")
		"fled": Audio.play("sfx/battle/flee")
	Audio.pop_music("battle", 1.0 if result == "fled" or result == "aborted" else 0.6)
	print("[battle] end: ", result)

	var defeat: Array = trainer_battle.get("defeat", [])
	var dhud: = Dialogue.hud()
	if result == "won" and not defeat.is_empty() and dhud and not online and not challenge and not is_spar():
		dhud.open_dialog(String(trainer_battle.get("name", "")), PackedStringArray(defeat), 
			String(trainer_battle.get("face", "")))
		await dhud.dialog_closed
		Audio.clear_jingles()
	var w_name: String = wild.species if is_instance_valid(wild) else "The wild creature"
	var show_results: = result == "won" and not online and not challenge and not is_spar()
	var trainer_levels: Array = []
	var trainer_gain: = 0
	if show_results:
		trainer_gain = _trainer_exp_reward()
		trainer_levels = Game.state.add_trainer_exp(trainer_gain)
	var whiteout: = whiteout_for(result)


	if _static_uid != "":
		if result == "won" or result == "caught":
			Game.flags["static_" + _static_uid] = true
		elif (result == "fled" or result == "lost") and is_instance_valid(wild):
			if wild.mon:
				wild.mon.heal_full()
			wild.sync_from_mon()
	var payout: = 0
	var text: = {}
	if trainer_battle.is_empty():
		text = {"caught": "", "won": "Wild %s fainted!" % w_name, "lost": "", "fled": "Got away safely!"}
	else:
		var t_name: String = String(trainer_battle.get("name", "The trainer"))
		text = {"caught": "", "won": "%s's %s fainted!" % [t_name, w_name], "lost": "You lost to %s..." % t_name, "fled": ""}
	if whiteout:
		text["lost"] = ""
	elif result == "won" and not trainer_battle.is_empty() and not online and not challenge and not is_spar():


		payout = Game.state.trainer_payout(String(trainer_battle.get("class", "")), _prize_level())
		Game.state.money += payout
	roster_lost = false
	if result == "lost" and int(trainer_battle.get("roster", 0)) > 0 and not whiteout:

		roster_lost = true
		var forfeit: = mini(Game.state.money, Game.state.trainer_payout(String(trainer_battle.get("class", "")), _prize_level()))
		Game.state.money -= forfeit
		if forfeit > 0:
			text["lost"] = "You lost to %s...\nYou paid %s." % [String(trainer_battle.get("name", "the trainer")), Game.GameStateScript.format_money(forfeit)]
	if result == "won" and not online and not challenge and not is_spar() and pay_day_money > 0:
		payout += pay_day_money
		Game.state.money += pay_day_money
	pay_day_money = 0
	if result != "won" and text.get(result, "") != "":
		Dialogue.msg(text[result], 2.5, "trainer" if not trainer_battle.is_empty() else "info")
	if result != "fled" and result != "caught":
		await get_tree().create_timer(1.0).timeout
	for b in allies + [wild] + extra_foes:
		if is_instance_valid(b):
			b.reset_battle_mods()
	for a in allies:
		if guest_allies.has(a):
			continue
		if is_instance_valid(a) and a.mode != CreatureDef.Mode.FAINTED:
			a.opponent = null
			a.last_hit_by = null
			a.mode = CreatureDef.Mode.FOLLOW
			a.refresh_label()





			if not whiteout and _out_snap != null and not _out_snap.has(a.mon):
				if a.mon != null and a.mon.evo_pending:
					Game.party_changed.emit()
					continue
				for k in Game.companions.keys():
					if Game.companions[k] == a:
						Game.recall(k)
						break
	if is_instance_valid(wild) and wild.mode != CreatureDef.Mode.FAINTED:
		wild.opponent = null
		if trainer_battle.is_empty():

			wild.mode = CreatureDef.Mode.IDLE if wild.static_uid != "" else CreatureDef.Mode.WANDER
			wild.peace_timer = 4.0
		else:
			wild.mode = CreatureDef.Mode.IDLE
			wild.velocity = Vector3.ZERO
			if roster_lost:

				var tnode: Node3D = trainer_battle.get("node")
				var p1: = Dialogue.player()
				var old_w: = wild
				_combatants.erase(old_w)
				if p1 and is_instance_valid(tnode):
					CaptureFX.recall(self, p1.get_parent(), tnode, old_w, old_w.mon.ball if old_w.mon else "poke_ball")
					await get_tree().create_timer(Game.RECALL_SECS).timeout
				if is_instance_valid(old_w):
					old_w.queue_free()
		if is_instance_valid(wild):
			wild.refresh_label()
	_drop_boss_adds()
	for e in extra_foes:
		if is_instance_valid(e) and e.mode != CreatureDef.Mode.FAINTED:
			e.opponent = null
			e.mode = CreatureDef.Mode.WANDER
			e.peace_timer = 4.0
			e.refresh_label()

	var herders: Array = []
	for f in [wild] + extra_foes:
		if is_instance_valid(f) and f.has_meta("herd"):
			var h = f.get_meta("herd")
			if is_instance_valid(h) and not herders.has(h):
				herders.append(h)
	extra_foes = []
	_adds_pending = []
	for h in herders:
		h.reform()
	for g in guest_allies:
		if is_instance_valid(g):
			g.queue_free()
	guest_allies = []
	guest_queue = []
	guest_lines = []
	guest_trainer = null
	boss_hook = Callable()
	ai_hazard = Callable()
	guest_tier = ""
	guest_item = ""
	field_type_mult = {}
	ally_acc_mult = 1.0
	max_fighters = 0
	no_capture = false
	for b in _combatants:
		if is_instance_valid(b):
			b.remove_from_group("combatant")
	_combatants.clear()
	partner = null
	allies.clear()
	wild = null
	_out_snap = null

	if _static_uid != "" or _wild_arena_from_body:
		wild_arena = Vector2.ZERO
		wild_arena_center = Vector3.INF
	_wild_arena_from_body = false
	_static_uid = ""
	_intro = false
	_intro_skip = false
	_show_hidden()
	if is_instance_valid(_arena):
		_arena.close()
	_arena = null
	_restore_arena_props()
	arena_rect = Rect2()
	grass_battle = false
	thunder_border = 0.0
	teleport_discs = []
	disc_partners = []
	disc_ready = []
	_disc_view = null
	type_bonus = []
	_lead_spot = Vector3.INF
	clear_tut_lock()
	pause_for_evolution = false
	var hud: = Dialogue.hud()
	if hud:
		hud.intro.reset()
	var p: = Dialogue.player()
	if p:
		if not Game.cutscene:
			p.controls_enabled = true
		var cam: = Dialogue.camera_rig()
		if cam:
			cam.focus_follow(p)
	in_battle = false
	_drop_battle_sheets()
	Controls.set_battle_dpad(false)
	training = false
	online = false
	_ending = false
	if show_results and hud:
		hud.battle_log.dismiss()
		hud.results_log.show_results(_exp_results, _ev_results, payout)
	if trainer_gain > 0:
		Game.trainer_xp_feedback(trainer_gain, trainer_levels)
	Game.party_changed.emit()
	Game.battle_ended.emit(result)
	challenge = false
	if whiteout:

		var lose: Array = trainer_battle.get("lose", [])
		if not lose.is_empty() and hud:
			hud.open_dialog(String(trainer_battle.get("name", "")), PackedStringArray(Dialogue.fill_lines(lose)))
			await hud.dialog_closed
		await Game.whiteout()





func note_jump(c) -> void :
	if in_battle and allies.has(c):
		_an_jumps += 1


func _an_item_used(_slot: int) -> void :
	if in_battle:
		_an_items += 1




func _an_battle_started(fighter, foe) -> void :
	if online:
		_an_on = false
		return
	_an_on = not _an_lab_scene()
	if not _an_on:
		return
	_an_kind = _an_kind_of()
	_an_trainer_id = _an_trainer_id_of()
	_an_static_uid = _static_uid
	if _an_trainer_id != "":
		_an_attempts[_an_trainer_id] = int(_an_attempts.get(_an_trainer_id, 0)) + 1
	if not battle_events_wanted(_an_kind, _an_static_uid):
		return
	_an_started_ms = Time.get_ticks_msec()
	_an_moves.clear()
	_an_hits_landed = 0
	_an_hits_taken = 0
	_an_switches = 0
	_an_items = 0
	_an_jumps = 0
	var moves: = get_node("/root/Moves")
	moves.move_used.connect(_an_on_move)
	moves.hit_landed.connect(_an_on_hit)
	Analytics.track("battle_started", {
		"kind": _an_kind, 
		"foe_species": foe.species if is_instance_valid(foe) else "", 
		"foe_level": foe.level if is_instance_valid(foe) else 0, 
		"trainer_id": _an_trainer_id, 
		"terrain": _an_terrain(), 
		"weather": _an_weather(), 
		"fighter_species": fighter.species if is_instance_valid(fighter) else "", 
		"fighter_level": fighter.level if is_instance_valid(fighter) else 0, 
		"static_uid": _an_static_uid}.merged(get_node("/root/BattleTower").props() if challenge else {}))


func _an_battle_ended(result: String) -> void :
	var moves: = get_node("/root/Moves")
	if moves.move_used.is_connected(_an_on_move):
		moves.move_used.disconnect(_an_on_move)
	if moves.hit_landed.is_connected(_an_on_hit):
		moves.hit_landed.disconnect(_an_on_hit)
	if not _an_on:
		return
	_an_on = false
	Analytics.count_battle(_an_kind, result)
	if not battle_events_wanted(_an_kind, _an_static_uid):
		return
	if result == "aborted":
		return
	Analytics.track("battle_ended", {
		"result": result, 
		"static_uid": _an_static_uid, 
		"duration_s": (Time.get_ticks_msec() - _an_started_ms) / 1000.0, 
		"party_hp_pct_end": _an_party_hp_pct(), 
		"switches": _an_switches, 
		"items_used": _an_items, 
		"jumps": _an_jumps, 
		"moves_used": _an_moves.duplicate(), 
		"hits_landed": _an_hits_landed, 
		"hits_taken": _an_hits_taken, 
		"ally_mode": String(ai_ally().combat.role) if ai_ally() else "none", 
		"battle_speed": Settings.BATTLE_SPEED_NAMES[clampi(Settings.battle_speed, 0, Settings.BATTLE_SPEED_NAMES.size() - 1)].to_lower()}.merged(get_node("/root/BattleTower").props() if challenge else {}))
	if result == "won" and _an_kind != "challenge" and _an_kind != "wild" and _an_trainer_id != "":
		Analytics.track("trainer_defeated", {"trainer_id": _an_trainer_id, 
			"attempts": int(_an_attempts.get(_an_trainer_id, 0))})
		if _an_trainer_id == "brock":
			AnalyticsBeats.beat_once("brock_defeated")


func _an_on_move(user: Node, move: Dictionary) -> void :
	if not allies.has(user):
		return
	var id: = String(move.get("id", ""))
	if id != "":
		_an_moves[id] = int(_an_moves.get(id, 0)) + 1


func _an_on_hit(user: Node, target: Node, _info: Dictionary) -> void :
	if allies.has(user):
		_an_hits_landed += 1
	if allies.has(target):
		_an_hits_taken += 1





static func battle_events_wanted(kind: String, static_uid: String) -> bool:
	return kind != "wild" or static_uid != ""


func _an_kind_of() -> String:
	if challenge:
		return "challenge"
	if trainer_battle.is_empty():
		return "wild"
	match String(trainer_battle.get("class", "")):
		"rival":
			return "rival"
		"gym_leader":
			return "gym"
	return "trainer"


func _an_trainer_id_of() -> String:
	var t = trainer_battle.get("node")
	if not is_instance_valid(t):
		return ""
	var id = t.get("trainer_id")
	return String(id) if id != null else ""


func _an_party_hp_pct() -> int:
	var hp: = 0
	var mx: = 0
	for m in Game.party:
		hp += maxi(int(m.hp), 0)
		mx += maxi(int(m.max_hp), 1)
	return int(round(100.0 * hp / mx)) if mx > 0 else 0


func _an_terrain() -> String:
	if arena_rect.size.x <= 0.0:
		return "ground"
	var c: = arena_rect.get_center()
	match Transitions.surface_at(c.x, c.y):
		Water.Surface.SHALLOW:
			return "shallow"
		Water.Surface.DEEP:
			return "deep"
	return "ground"


func _an_weather() -> String:
	var w: = get_tree().get_first_node_in_group("weather")
	if w == null or not w.has_method("camera_cover"):
		return "clear"
	var c: Dictionary = w.camera_cover()
	var best: = ""
	var v: = 0.4
	for k in ["wet", "snow", "fog"]:
		if float(c.get(k, 0.0)) > v:
			v = float(c[k])
			best = {"wet": "rain", "snow": "snow", "fog": "fog"}[k]
	if best != "":
		return best
	return "overcast" if float(c.get("cloud", 0.0)) > 0.4 else "clear"



func _an_lab_scene() -> bool:
	var sc: = get_tree().current_scene
	return sc != null and String(sc.scene_file_path).begins_with("res://scenes/tests/")


var _move_fields: Node

func move_fields() -> Node:
	if not is_instance_valid(_move_fields):
		_move_fields = load("res://scripts/combat/battle_fields.gd").new()
		add_child(_move_fields)
	return _move_fields


func clear_move_fields() -> void :
	indoor_sun = false
	for c in get_tree().get_nodes_in_group("smoke_cloud"):
		c.queue_free()
	if is_instance_valid(_move_fields):
		_move_fields.clear()



func smoke_penalty(body: Node) -> int:
	var worst: = 0
	for c in get_tree().get_nodes_in_group("smoke_cloud"):
		if is_instance_valid(c) and c.owner_side != body.side and c.covers(body.global_position):
			worst = maxi(worst, int(c.acc_penalty))
	return worst




var indoor_sun: = false




func rain_at(pos: Vector3) -> bool:
	var w: = get_tree().get_first_node_in_group("weather")
	if w == null or not w.has_method("type_at"):
		return false
	return maxf(w.type_at("rain", pos), w.type_at("thunderstorm", pos)) > 0.15




func sun_active(pos: Vector3) -> bool:
	if indoor_sun:
		return true
	var w: = get_tree().get_first_node_in_group("weather")
	return w != null and w.has_method("sun_at") and w.sun_at(pos) > 0.5


func field_power(type: String, at: Vector3) -> float:
	return Fields.mults_for(active_fields(at), type)




func field_sources(at: Vector3) -> Dictionary:
	var out: = {}
	if grass_battle:
		out["tall_grass"] = "patch"
	var declared: = _declared_field()
	if not declared.is_empty():
		out[String(declared.id)] = String(declared.source)
	return out


func active_fields(at: Vector3) -> Array:
	return field_sources(at).keys()




func _declared_field() -> Dictionary:
	if debug_field != "":
		return {"id": debug_field, "source": "lab"}
	if not trainer_battle.is_empty():
		var tf: = String(trainer_battle.get("field", ""))
		if tf != "":
			return {"id": tf, "source": "trainer"}
	var s: = get_tree().get_first_node_in_group("zone_streamer")
	if s != null and s.has_method("active_field"):
		var zf: = String(s.active_field())
		if zf != "":
			return {"id": zf, "source": "zone"}
	if _room_field != "":
		return {"id": _room_field, "source": "room"}
	return {}





func _field_start(ground_y: float) -> void :
	var p: = Dialogue.player()
	_room_field = Game.room_field(p) if p != null else ""
	grass_battle = arena_rect.has_area() and _arena_in_tall_grass()
	if not arena_rect.has_area():
		return
	var center: = arena_rect.get_center()
	var at: = Vector3(center.x, ground_y, center.y)
	for id in field_sources(at).keys():
		var f: = Fields.field(String(id))
		if f.is_empty():
			continue
		_field_fx_ids.append(id)
		Fields.add_badge(self, String(f.get("label", id)), String(f.get("badge_line", "")), _field_fx_ids.size() - 1)
		if bool(f.get("visual", false)):
			Fields.add_leaves(self, center, ground_y)


func _arena_in_tall_grass() -> bool:
	for g in get_tree().get_nodes_in_group("tall_grass"):
		if not (g is Node3D):
			continue
		var size: Vector2 = g.size
		var at: Vector3 = g.global_position
		if Rect2(at.x - size.x * 0.5, at.z - size.y * 0.5, size.x, size.y).intersects(arena_rect):
			return true
	return false


func _field_clear() -> void :
	_field_fx_ids.clear()
	_room_field = ""
	for child in get_children():
		if String(child.name).begins_with("Field"):
			child.queue_free()

func launching_lan() -> bool:
	var lan = get_node_or_null("/root/LanCampaign")
	return lan != null and lan.allow_campaign_battle()
