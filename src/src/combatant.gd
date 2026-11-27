class_name Combatant
extends RefCounted

const CookingRules: = preload("res://scripts/world/cooking.gd")








const Dex: = preload("res://scripts/dex.gd")
const StatCalc: = preload("res://scripts/stats/stat_calc.gd")
const DashRun: = preload("res://scripts/combat/dash_run.gd")
const DashClash: = preload("res://scripts/dash_clash.gd")
const ItemsData: = preload("res://scripts/items.gd")
const BattleArena: = preload("res://scripts/battle_arena.gd")
const StatusRoll: = preload("res://scripts/status_roll.gd")
const Flail: = preload("res://scripts/flail.gd")
const TrainerLevel: = preload("res://scripts/stats/trainer_level.gd")
const BodySize: = preload("res://scripts/combat/body_size.gd")

const LUNGE_SPEED: = 10.0
const LUNGE_TIME: = 0.2

const ARC_STEP_SPEED: = 5.0
const ARC_STEP_MAX: = 2.0
const ATTACK_CD: = 0.8



const HIT_RANGE: = 0.5

const PP_REGEN: = 0.1







const AI_THINK_MIN: = 1.2
const AI_THINK_MAX: = 2.0
const AI_RECOVER: = 0.5



const AI_THINK_RETRY: = 0.25

const AI_SPRINT_REACT: = 0.35

const AI_LOW_HP: = 0.35
const AI_KITE_MULT: = 1.5



const AI_TACTIC_MISS_MULT: = 1.5

const AI_DODGE_TIME: = 0.35

const AI_TELL: = 0.145

const AI_WAIT_STRAFE: = 0.6
const AI_WAIT_RADIAL: = 0.35





const AI_JUMP_SHARP: = 0.8
const AI_JUMP_ERR: = 0.44
const AI_JUMP_ERR_SLOPE: = 0.28
const AI_JUMP_MISS_LIN: = 0.54
const AI_JUMP_MISS_QUAD: = 0.475
const AI_JUMP_MISS_MAX: = 0.52


const AI_JUMP_LATE: = 0.25


const AI_JUMP_CLEAR: = 0.95
const AI_JUMP_RESERVE: = 0.1


const AI_FLIGHT_MIN: = 0.35
const AI_FLIGHT_KEEP: = 0.12
const AI_FLIGHT_IDLE: = 2.5

const AI_SWIM_ARRIVE: = 0.7



const AI_SWIM_ORBIT: = 1.6
const AI_SWIM_ORBIT_MIN: = 2.6
const AI_SWIM_ORBIT_W: = 0.7
const AI_SWIM_ORBIT_FLIP: = 0.25

const AI_PAD_EDGE: = 0.6


const QUAKE_TAIL: = 0.11

const KNOCKBACK_SCALE: = 0.5

const BLOCK_LAYERS: = 1 | 2

const STAGGER_TIME: = 2.0

const BATTLE_MOVE_SPEED: = 4.5


const SPRINT_MULT: = 1.6


const EVADE_TOTAL: = 0.46


const ENTRY_COOLDOWN: = 2.0

const LOADOUT_SWAP_CD: = 2.0
const EVADE_COOLDOWN: = 0.5
const EVADE_DISTANCE: = 1.6

const EVADE_BURST: = 0.23
const EVADE_FATIGUE: = 1.0 / 5.0
const TELEPORT_DISTANCE: = 3.0
const TELEPORT_FATIGUE: = 1.0 / 8.0
const EVADE_INVULN: = 0.2
const EVADE_INVULN_MAX: = 0.3
const EVADE_INVULN_MIN: = 0.1
const EVADE_INVULN_STAT: = 0.25

const EVADE_REGEN_HOLD: = 0.5

const EVADE_ANIMS: = ["Tumble", "Rotate", "Hop"]



const JUMP_HEIGHT_DEFAULT: = 0.9



const PAD_JUMP_BOOST: = 1.8



const PAD_HOP_SPEED: = 1.6
const PAD_HOP_LAND: = 0.12




const PAD_HOP_GAP: = 3.2
const PAD_HOP_CONE: = 0.866
const PAD_HOP_RIM: = 0.3
const PAD_HOP_INSET: = 0.5
const PAD_HOP_ARC: = 0.9
const PAD_HOP_REARM: = 0.35
const PAD_HOP_DODGE: = Vector2(0.3, 0.7)
const PAD_STAND_GAP: = 0.3


const JUMP_G: = 23.8


const JUMP_MAX_KG: = 95.0

const DASH_REACH_FACTOR: = 0.9









const HOVER_HEIGHT: = 0.35
const HOVER_SCALE: = 0.8
const HOVER_MIN: = 0.45
const HOVER_MAX: = 1.1
const FLY_HEIGHT: = 1.4
const SWOOP_HEIGHT: = 0.2
const ALT_SPRING: = 12.0
const ALT_MAX_VY: = 18.0
const FAINT_FALL_SPEED: = 6.0



const FLY_SPEED_MULT: = 1.25



const FLIGHT_TAKEOFF: = 0.1
const FLIGHT_DRAIN: = 0.1
const FLIGHT_MIN: = 0.15
const FLIGHT_FLOOR: = 0.1
const FLIGHT_LAND: = 0.25

const JUMP_STAMINA: = 0.15

const JUMP_LAND: = 0.3


const AIRBORNE_FRACTION: = 0.4
const AIRBORNE_FLOOR: = 0.12

const JUMP_STRETCH: = 0.28
const JUMP_SQUASH: = -0.24
const JUMP_DUST: = Color(0.55, 0.48, 0.38)


const PREPARE_STUN: = 0.25

const LUNGE_PREPARE: = 0.15


const STRUGGLE: = {"id": "struggle", "name": "Struggle", "type": "none", "category": "physical", "power": 50, "knockback": 5, "allowed_midair": false}

const LUNGE: = {"allowed_midair": false}

var body: Creature


var types: Array = ["normal"]
var stats: = {"atk": 10, "def": 10, "spa": 10, "spd": 10, "spe": 10}


var screens: Dictionary = {}

var guard: = false


func screen_mult(mv: Dictionary, crit: = false) -> float:
	if crit or bool(mv.get("break_screens", false)):
		return 1.0
	var screen: = "reflect" if mv.get("category", "") == "physical" else "light_screen"
	return 0.5 if screens.has(screen) else 1.0


var stages: = {"atk": 0, "def": 0, "spa": 0, "spd": 0, "spe": 0, "acc": 0}
var moves: Array = []

var loadout: = 0
var move_cd: = {}

var taunt_by: Node = null
var taunt_t: = 0.0

var stockpile: = 0

var torment_t: = 0.0
var torment_fx: Node = null

var snatch_t: = 0.0
var snatch_fx: Node = null

var follow_me_t: = 0.0
var follow_me_stamp: int = 0
var imprison_t: = 0.0
var grudge: = false
var grudge_t: = 0.0
var grudge_fx: Node = null

var grudge_empty: Dictionary = {}
var foresight: = false
var ingrained: = false
var _ingrain_t: = 0.0
var ingrain_fx: Node = null
const INGRAIN_BREAK: = 8.0
const INGRAIN_TICK: = 2.0
const INGRAIN_FRAC: = 1.0 / 16.0
var sleep_act_t: = 0.0
var uproar_t: = 0.0
var since_enter: = 0.0
var mean_look_t: = 0.0
var mean_look_source: Node3D = null
var mean_look_fx: Node = null
var disable_t: = 0.0
var disable_move: = ""
var disable_fx: Node = null
var encore_t: = 0.0
var encore_move: = ""
var encore_fx: Node = null

var gcd_t: = 0.0

var gcd_duration: = Dex.GLOBAL_COOLDOWN

var evade_cd_t: = 0.0

var cooldown_move: = ""
var cooldown_gen: = 0
var cooldown_clash: = false


var sprinting: = false
var evade_t: = 0.0
var _evade_motion_u: = 0.0
var _evade_dist: = EVADE_DISTANCE
var evade_invuln_t: = 0.0
var evade_dir: = Vector3.ZERO
var _evade_last: = ""
var _evade_exhausted: = false
var _whiff_pending: = false
var _whiff_dir: = Vector3.ZERO
var _dash_saw_evade: = false
var _evade_regen_t: = 0.0

var _intent_sprint_was: = false


var remote_intent: = {"move": Vector2.ZERO, "sprint": false, "jump": false, "slot": -1}


enum Flight{GROUNDED, AIRBORNE, LANDING}
var flight: = Flight.GROUNDED
var flight_t: = 0.0


var air_t: = 0.0
var air_h: = 0.0
var jump_height: = JUMP_HEIGHT_DEFAULT
var jump_time: = 0.55


var jump_boost: = 1.0


var jump_speed: = 1.0
var pad_hop: = false
var _pad_hop_ready_ms: = 0

var locomotion: = "ground"

var weight_kg: = 50.0

var fly_height: = FLY_HEIGHT


var swimmer: = false
var fish: = false

var pad: = false


var overboard: = false

var _drown_t: = 0.0

var swim_sink: = -1.0


var underground: = false
var _dig_goal: = Vector3.ZERO



var _dig_sink: = 0.0
var _dig_rise: = 0.0
var _dig_vis: = 0.0


var alt_override: = 0.0
var alt_override_t: = 0.0

var land_t: = 0.0

var selected_move: = ""

var mimic_slot: = -1
var mimic_move: = ""

var ai_uses_moves: = false

var ai_think_scale: = 1.0


static var ai_difficulty_mult: = 1.0
const AI_SCALE_MAX: = 1.8




func _ai_scale() -> float:
	if not is_trainer_mon:
		return ai_think_scale
	return minf(ai_think_scale * ai_difficulty_mult, maxf(AI_SCALE_MAX, ai_think_scale))

var brain: AiBrain = AiBrain.new()


var auto_tier: = ""
var role: = "auto"
var ai_stance: = ""
var _auto_t: = 0.0
var _auto_swap_ms: = -100000
var _seen_foe: = {}
var _seen_for: = 0
var auto_class: = ""
var auto_unit: = ""
var tactic: = {}
var tactic_last: = ""
var fight_t: = 0.0
var _tactic_sig: = ""
const AUTO_EVERY: = 1.0
const AUTO_SWAP_GAP: = 3.0

var side: = 1



var pp_base: = 100.0
var pp_max: = 100.0
var stamina: = 100.0


var fly_pp_base: = 100.0
var fly_pp: = 100.0
var crit_stage: = 0
var stagger_t: = 0.0
var status: = ""
var status_t: = 0.0



const STATUS_TIME: = {"burn": 15.0, "poison": 15.0, "paralysis": 6.0, "sleep": 5.0, "leech": 15.0}

const STATUS_TICK: = 2.5


const TOXIC_CAP: = 4
var toxic: = false
var toxic_n: = 0

const PARALYSIS_SPEED: = 0.25
const PARALYSIS_SKIP: = 0.25

const CONFUSION_SELF: = 0.5
const CONFUSION_POWER: = 40.0


const SLEEP_WAKE_HIT: = 0.25
const SLEEP_WAKE_TICK: = 0.5
const FREEZE_THAW_TICK: = 0.2

var confusion_t: = 0.0

const INFATUATION_SKIP: = 0.5
var infatuation_source: Node = null
var substitute: Node3D = null
var leech_source: Creature
var stun_t: = 0.0




var impact_t: = 0.0
var impact_role: = ""
var impact_total: = 0.0

var impact_shaking: = false
var _off_base_x: = 0.0
var _shake_sign: = 1.0
var _impact_knock: = Vector3.ZERO
var _launch_v: = 0.0
var _launch_total: = 0.0

var consumed_item: = ""

var perish_n: = 0
var perish_t: = 0.0
const PERISH_TICK: = 4.0
var _impact_launch: = 0.0

var _border_lock: = 0.0
const TeleportDiscs: = preload("res://scripts/teleport_discs.gd")
var _disc_invuln: = 0.0
var _disc_state: = {}
var _border_stuck: = 0.0
var _border_shove: = Vector2.ZERO
var root_t: = 0.0
var prepare_t: = 0.0
var prepare_total: = 0.0
var prepare_move: Dictionary = {}
var prepare_id: = ""
var prepare_gen: = 0
var revenge_bonus: = false
var prepare_interrupted: = false
var comet_fx: Control = null
var _prepare_fx: Node
const OTHER_SELF_BUFFS: = ["aromatherapy", "imprison", "grudge", "focus_energy", "charge", "growth", "agility", "meditate", "curse", "helping_hand", "rain_dance", "sweet_scent", "water_sport", "mud_sport", "foresight", "odor_sleuth", "bulk_up", "belly_drum", "amnesia", "dragon_dance", "psych_up", "ingrain", "splash", "substitute", "hail", "sandstorm"]
const DEFENSE_BUFFS: = ["harden", "defense_curl", "withdraw", "reflect", "light_screen"]
const WIND_MOVES: = ["gust", "sand_attack", "silver_wind"]

const SWEEP_MOVES: = ["sand_attack"]
const STATUS_GESTURES: = ["attract", "growl", "tail_whip", "leer", "scary_face", "screech", "metal_sound", "feather_dance", "taunt"]

var trap_t: = 0.0
var evasion_t: = 0.0

var lock_target: Node = null

var fury_n: = 0
var fury_t: = -100.0
var lock_t: = 0.0

var endure_t: = 0.0

var destiny_bond: = false
var bond_fx: Node = null

var nightmare: = false
var minimized: = false

const REST_STEPS: = 6
var rest_t: = 0.0
var rest_total: = 0.0
var rest_chunk: = 0
var rest_steps_done: = 0

var mist_t: = 0.0

var last_hit_type: = ""
var protect_t: = 0.0


var decoys: Array = []
var decoy_speed: = 0
var evasion: = 0.0

var dummy_style: = 0
var dash_t: = 0.0




const SA_TRAVEL_EXP: = 2.2
const DASH_GHOSTS: = 5
var dash_total: = 0.0
var dash_range: = 0.0



var dash_plan: = 0.0
var dash_contact_p: = 0.0


var dash_splits: Dictionary = {}
var _dash_coasting: = false
var _dash_settle: = false
var _dash_coast: = 0.0
var _dash_style_a: = false
var _sa: Dictionary = StyleA.params({})
var _dash_hop: = false
var _dash_hop_h: = 0.0



func _dash_speed_factor() -> float:
	return speed_factor() * terrain_speed_mult()

var _dash_run: Dictionary = {}
var _dash_from: = Vector3.ZERO
var _ghost_n: = 0
var _ghost_t: = 0.0
var dash_dir: = Vector3.ZERO
var dash_speed: = 0.0

var _dash_running: = false

var _dash_budget: = 0.0

var _dash_lunge_u: = -1.0
var dash_move: Dictionary = {}
var dash_miss: Node
var _dash_hit: = false

var dash_power_scale: = 1.0

var dash_slow: = 1.0

var _ace_active: = false
var _ace_target: PhysicsBody3D
var _ace_from: = Vector3.ZERO
var _ace_end: = Vector3.ZERO
var _ace_total: = 0.26

var _dash_fist: = false

var _dash_fx_done: = false


var _dash_dodged: = {}
var _status_tick: = 0.0
var _ai_think: = 0.0

var _ai_react_t: = 0.0
var _ai_sprint_seen: = false


var _ai_jump_threat: = ""
var _ai_jump_at: = 0.0
var _ai_jump_done: = false



var _ai_dodge_t: = 0.0
var _ai_punished: = false
var _ai_tell_t: = 0.0
var _ai_tell_dir: = Vector3.ZERO

var _ai_tactic_on: = true



var cast_move: Dictionary = {}
var cast_n: = 0
var last_hit_by: Creature

var ai_target_pool: Array = []
var _retarget_t: = 0.0
var _struggling: = false
var _cd: = 0.0
var _lunge_t: = 0.0
var _lunge_dir: = Vector3.ZERO

var _leaping: = false
var _leap_u: = 0.0
var _leap_total: = 0.6
var _leap_hold: = 0.0
var _leap_f1: = 0.5
var _leap_h: = 1.0
var _leap_from: = Vector3.ZERO
var _leap_apex: = Vector3.ZERO
var _leap_land: = Vector3.ZERO
var _leap_miss_land: = Vector3.ZERO
var _leap_hit_apex: = Vector3.ZERO
var _leap_hit_land: = Vector3.ZERO
var _leap_v: = 1.0

const WATER_LEAP_LUNGES: = 2.0
const WATER_LEAP_H: = 0.45
const WATER_LEAP_TELL: = 0.1
var _leap_charge_t: = 0.0
const WATER_LEAP_SPEED: = 1.0
var _leap_mv: Dictionary = {}
var _leap_hit: = false
var _leap_hit_possible: = true
var _leap_target: Node = null


var _pad_leaping: = false


var _dash_water: = false
var _pad_leap_t: = 0.0
var _pad_leap_total: = 0.5
var _pad_leap_from: = Vector3.ZERO
var _pad_leap_to: = Vector3.ZERO
var _pad_leap_mask: = 0
var _pad_leap_kind: = "exit"
var _water_entry_t: = 0.0
const LEAP_OUT_H: = 0.32
const WATER_ENTRY_TIME: = 0.6


var _leap_mult: = 1.0


var _leap_mask: = 0

var _arc_step_t: = 0.0
var _arc_step_dir: = Vector3.ZERO
var _hit_done: = false
var _knock: = Vector3.ZERO
var _recover_t: = 0.0
var opponent: Creature


var ai_legacy_pick: = false


var is_trainer_mon: = false


var trainer_item: = ""
var _item_used: = false


func _init(b: Creature) -> void :
	body = b





func _in_duel() -> bool:
	var fighting: = body.mode == Creature.Mode.BATTLE_AI or body.mode == Creature.Mode.PLAYER\
	or body.mode == Creature.Mode.REMOTE or body.mode == Creature.Mode.DUMMY
	return fighting and is_instance_valid(opponent) and opponent.alive()






func speed_factor() -> float:
	if _in_duel():
		var f: = StatCalc.battle_speed_factor(stat("spe"), opponent.stat("spe"))
		if status == "paralysis":
			f *= PARALYSIS_SPEED
		return f
	return 1.0




func recovery_factor() -> float:
	return PARALYSIS_SPEED if _in_duel() and status == "paralysis" else 1.0




func battle_speed() -> float:
	var b: Node = body._battle()
	if b == null:
		return 1.0
	return b.fight_speed()




func move_speed() -> float:
	var b: Node = body._battle()
	if b == null:
		return 1.0
	return b.move_speed()



func battle_move_speed() -> float:
	return BATTLE_MOVE_SPEED * speed_factor()



func gain_evs_from(defeated: Node, show_popup: = true) -> Dictionary:
	if body.mon == null or defeated == null or defeated.mon == null:
		return {}
	var old_max: = body.max_hp
	var gain: Dictionary = defeated.mon.ev_yield().duplicate()
	var mult: int = Game.state.ev_multiplier() if Game.state != null else 1
	for k in gain:
		gain[k] = int(gain[k]) * mult
	var got: Dictionary = body.mon.add_evs(gain)
	if got.is_empty():
		return got
	for k in StatCalc.BATTLE_STATS:
		stats[k] = int(body.mon.stats.get(k, 10))
	body.max_hp = body.mon.max_hp
	body.hp = clampi(body.hp + (body.max_hp - old_max), 0, body.max_hp)
	body.mon.hp = body.hp
	if show_popup:
		show_ev_popup(got)
	body.refresh_label()
	return got


func show_ev_popup(got: Dictionary) -> void :
	if got.is_empty():
		return
	var parts: Array = Game.state.ev_gain_parts(got)
	body._vfx().popup(body.head_pos(1.1), "  ".join(parts), Color(0.6, 1.0, 0.8), 0.8)




func min_move_cost() -> float:
	var best: = INF
	for id in moves + ([selected_move] if selected_move != "" else []):
		if grudge_empty.has(id):
			continue
		var mv: = Dex.move_for(id, body.species)
		if not mv.is_empty():
			best = minf(best, Dex.pp_cost(mv))
	return best if best < INF or not grudge_empty.is_empty() else 1.0


func out_of_pp() -> bool:
	return pp_max < min_move_cost()



func stagger() -> void :
	Audio.play_at("sfx/battle/stagger", body.global_position)
	stagger_t = STAGGER_TIME
	stamina = 0.0
	print("[pp] %s staggered for %.1fs (PP left %.1f)" % [body.species, STAGGER_TIME, pp_max])
	body.sprite.modulate = body.base_tint() * Color(0.7, 0.7, 0.85)
	body._vfx().popup(body.head_pos(1.1), "Exhausted!", Color(1, 0.75, 0.35))
	body._vfx().burst(body.head_pos(0.4), Color(1, 0.95, 0.5), 8, 1.2, 0.8, 0.1, 30.0, Vector3.UP, Vector3.ZERO, 0.4)
	body.refresh_label()


func restore_pp() -> void :
	stagger_t = 0.0
	pp_max = pp_base
	stamina = pp_base
	fly_pp = fly_pp_base
	if body.mon:
		body.mon.pp = pp_max




func crit_stat(k: String, attacking: bool) -> float:
	var st: = int(stages.get(k, 0))
	st = maxi(st, 0) if attacking else mini(st, 0)
	var v: = float(stats.get(k, 10)) * StatCalc.stage_mult(st)
	if k == "atk" and status == "burn":
		v *= 0.5
	return v


func stat(k: String) -> float:
	var v: = float(stats.get(k, 10)) * StatCalc.stage_mult(int(stages.get(k, 0)))
	if k == "atk" and status == "burn":
		v *= 0.5
	return v



var binding: Node = null

var extra_bindings: Array = []



func grip_binder() -> Node:
	if is_instance_valid(binding) and binding.foe == body and binding.ranged and not binding.released:
		return binding.user
	return null



func holder() -> Node:
	if is_instance_valid(binding) and binding.foe == body and not binding.released and not binding.reaching:
		return binding.user
	return null


const SLOWED_SPEED: = 0.5


func held_slowed() -> bool:
	return is_instance_valid(binding) and binding.foe == body and not binding.released\
	and binding.grip == preload("res://scripts/bind_hold.gd").Grip.SLOWED

func cancel_binding() -> void :
	if is_instance_valid(binding):
		binding.cancel()
	binding = null
	for h in extra_bindings.duplicate():
		if is_instance_valid(h):
			h.cancel()
	extra_bindings.clear()
	if is_instance_valid(body) and body.is_inside_tree():
		for fx in body.get_tree().get_nodes_in_group("bind_hold"):
			if fx.released and not fx.ranged and (fx.user == body or fx.foe == body):
				fx.cancel()

var seismic_throw: Node = null

func cancel_seismic_throw() -> void :
	if is_instance_valid(seismic_throw):
		seismic_throw.cancel()
	seismic_throw = null


func can_act(allow_attacker_hitstop: = false) -> bool:

	return not (is_instance_valid(binding) and binding.user == body and binding.reaching) and not is_instance_valid(seismic_throw) and not body.evolving and body.mode != Creature.Mode.FAINTED and stun_t <= 0.0\
	and stagger_t <= 0.0 and (impact_t <= 0.0 or (allow_attacker_hitstop and impact_role == "attacker")) and (status != "sleep" or sleep_act_t > 0.0) and status != "freeze"









const KO_PAUSE: = 0.55


static func impact_secs(hp_pct: float, crit: bool, eff: float, ko: bool, final_hit: bool, has_dir: bool, base: = 0.07) -> float:
	if not has_dir:
		return 0.0
	if not final_hit:
		return 0.05
	if ko:
		return KO_PAUSE
	if not (crit or eff > 1.0) and hp_pct < 0.05:
		return 0.0


	return base * StyleA.impact_mult(crit, eff)





const KNOCK_NEUTRAL: = 2.2
const KNOCK_SUPER: = 3.1




static func knock_distance(k: float, eff: float) -> float:
	var v: = k * type_knockback_mult(eff) * KNOCKBACK_SCALE
	return v * v / 60.0 * Dex.dist_scale


static func type_knockback_mult(eff: float) -> float:
	if eff <= 0.0:
		return 0.0
	if eff < 1.0:
		return 1.0
	return KNOCK_SUPER if eff > 1.0 else KNOCK_NEUTRAL


func in_impact() -> bool:
	return impact_t > 0.0




func enter_impact(secs: float, role: = "target") -> void :
	if secs <= 0.0:
		return
	impact_t = maxf(impact_t, secs)
	impact_total = impact_t
	impact_role = role



func queue_knock(v: Vector3) -> void :
	_impact_knock += v



func _perish_tick() -> void :
	perish_n -= 1
	perish_t = PERISH_TICK
	body._vfx().popup(body.head_pos(0.9), "PERISH %d" % perish_n if perish_n > 0 else "PERISH 0", Color("d8b4fe"), 1.2, "status")
	if perish_n > 0 or not body.alive():
		return
	endure_t = 0.0
	body.take_damage(body.hp, Vector3.ZERO, 0.0, {"kind": "perish"})




func launch_up(speed: float) -> void :
	if in_impact():
		_impact_launch = maxf(_impact_launch, speed)
		return
	if speed <= 0.0 or floats():
		return
	_launch_v = speed
	_launch_total = 2.0 * speed / JUMP_G
	air_t = _launch_total
	air_h = 0.0
	body.squash = JUMP_STRETCH



func cancel_knock() -> void :
	_impact_knock = Vector3.ZERO


func _end_impact() -> void :
	impact_t = 0.0
	impact_total = 0.0
	if _impact_knock != Vector3.ZERO:
		_knock += _impact_knock
		_impact_knock = Vector3.ZERO
	if _impact_launch > 0.0:
		var sp: = _impact_launch
		_impact_launch = 0.0
		launch_up(sp)



func tick_impact(delta: float) -> void :
	_border_lock = maxf(_border_lock - delta, 0.0)
	if _border_stuck > 0.0:
		_border_stuck -= delta
		if _border_stuck <= 0.0:
			_border_stuck = 0.0
			body.global_position += Vector3(_border_shove.x, 0.0, _border_shove.y)
			_border_shove = Vector2.ZERO
	if impact_t > 0.0:
		impact_t = maxf(impact_t - delta, 0.0)
		if impact_t <= 0.0:
			_end_impact()



func check_held_berry() -> void :
	if not Battle.in_battle or Battle.online_guest or Battle.is_spar() or body.mon == null:
		return
	if body != Battle.partner and not Battle.allies.has(body) and not (Battle.online and body == Battle.wild):
		return
	var id: = String(body.mon.held)
	if id == "":
		return
	var trigger: = ItemsData.held_trigger(id, body.hp, body.max_hp, status, confusion_t > 0.0, 0.0 if out_of_pp() else pp_max)
	if trigger == "":
		return
	body.mon.held = ""
	consumed_item = id
	var e: Dictionary = ItemsData.item(id).get("effect", {})
	match trigger:
		"hp":
			var gained: = mini(int(e.hp), body.max_hp - body.hp)
			body.heal(gained, {"kind": "held_berry", "item": id, 
				"popup_text": "+%d %s" % [gained, ItemsData.item_name(id)]})
		"cure", "confusion":
			if trigger == "cure" and status in body.mon.PERSIST_STATUS:
				clear_status()
			if confusion_t > 0.0 and String(e.cure) in ["all", "confusion"]:
				confusion_t = 0.0
				body._vfx().status_cure_attempt(body, "confusion", true)
		"pp":
			var before: = pp_max
			pp_max = minf(pp_base, pp_max + float(e.pp))
			body.mon.pp = pp_max
			body._vfx().popup(body.head_pos(0.9), "+%d PP %s" % [int(pp_max - before), ItemsData.item_name(id)], Color(0.5, 1.0, 0.5), 1.0, "heal")
	if trigger in ["cure", "confusion"]:
		body._vfx().popup(body.head_pos(0.9), ItemsData.item_name(id), Color(0.5, 1.0, 0.5), 1.0, "heal")
	body._vfx().moon_heal(body)
	body.heal_bounce()
	Audio.play_at("sfx/battle/berry", body.global_position)
	Dialogue.msg("%s ate its %s!" % [body.mon.display_name, ItemsData.item_name(id)], 1.2, "item")
	Game.party_changed.emit()




func apply_status(s: String, source: Creature = null, restoring: = false) -> bool:
	if body.mode == Creature.Mode.FAINTED or body.evolving:
		return false
	if s == "flinch":
		stun_t = maxf(stun_t, 0.5)
		Audio.play_at("sfx/status/" + s, body.global_position)
		return true
	if s == "confusion":
		return confuse()
	if status != "":
		return false
	if s == "sleep" and not restoring:
		for n in body.get_tree().get_nodes_in_group("combatant"):
			if is_instance_valid(n) and n.combat.uproar_t > 0.0:
				return false
	if not restoring and _meal_blocks(s):
		return false

	if not restoring and screens.has("safeguard"):
		return false
	status = s

	status_t = 0.0 if s == "freeze" else STATUS_TIME.get(s, 4.0)
	_status_tick = STATUS_TICK
	if s == "leech":
		leech_source = source
	if body.mon and body.mon.PERSIST_STATUS.has(s):
		body.mon.status = s
	body.refresh_label()
	Audio.play_at("sfx/status/" + s, body.global_position)
	body._vfx().status_fx(body)
	check_held_berry()
	return true



func confuse() -> bool:
	if confusion_t > 0.0 or body.mode == Creature.Mode.FAINTED or body.evolving:
		return false
	if _meal_blocks("confusion"):
		return false
	if screens.has("safeguard"):
		return false
	confusion_t = 4.0
	Audio.play_at("sfx/status/flinch", body.global_position)
	body._vfx().status_fx(body)
	check_held_berry()
	return true



func entomb(secs: float, zone: = {}) -> void :
	trap_t = maxf(secs, 0.0)
	trap_zone = zone if trap_t > 0.0 else {}




var trap_zone: Dictionary = {}




var counter_state: Dictionary = {}


func start_ingrain() -> void :
	ingrained = true
	_ingrain_t = INGRAIN_TICK
	trap_t = maxf(trap_t, 0.25)
	if not is_instance_valid(ingrain_fx):
		ingrain_fx = body._vfx().style_a_ingrain(body, body.look_height())


func unroot() -> void :
	if not ingrained:
		return
	ingrained = false
	trap_t = 0.0
	if is_instance_valid(ingrain_fx):
		ingrain_fx.queue_free()
	ingrain_fx = null


func _tick_ingrain(delta: float) -> void :
	if not body.alive() or not Battle.in_battle or body.recalling:
		unroot()
		return
	trap_t = maxf(trap_t, 0.25)
	_ingrain_t -= delta
	if _ingrain_t <= 0.0:
		_ingrain_t = INGRAIN_TICK
		if body.hp < body.max_hp:
			body.heal(maxi(1, int(ceil(float(body.max_hp) * INGRAIN_FRAC))), {"move": "ingrain", "kind": "heal"})
			if is_instance_valid(ingrain_fx):
				ingrain_fx.pulse()


func _break_trap() -> void :
	var z: = trap_zone
	trap_t = 0.0
	trap_zone = {}
	if z.is_empty() or bool(z.get("released", false)):
		return
	z["released"] = true
	var cost: = maxi(1, int(ceil(float(body.max_hp) * float(z.frac) * float(z.mult) * float(maxi(int(z.left), 0)))))
	cost = mini(cost, maxi(body.hp - 1, 0))
	body._vfx().popup(body.head_pos(0.6), "BROKE FREE -%d" % cost if cost > 0 else "BROKE FREE", Color(1.0, 0.75, 0.35), 1.0, "status")
	if cost > 0:
		body.take_damage(cost, Vector3.ZERO, 0.0, {"kind": "trap"})



func make_toxic(source: Creature = null) -> bool:
	if status == "poison":
		if toxic:
			return false
		toxic = true
		toxic_n = 0
		body.refresh_label()
		return true
	if apply_status("poison", source):
		toxic = true
		toxic_n = 0
		return true
	return false



func live_decoys() -> Array:
	var out: Array = []
	for d in decoys:
		if is_instance_valid(d) and not d.popped:
			out.append(d)
	return out



func decoy_gone() -> void :
	if not live_decoys().is_empty():
		return
	decoys.clear()
	if decoy_speed != 0 and is_instance_valid(body):
		body._moves()._change_stage(body, "spe", - decoy_speed, "double_team")
	decoy_speed = 0



func clear_decoys() -> void :
	for d in decoys:
		if is_instance_valid(d):
			d.queue_free()
	decoys.clear()
	decoy_speed = 0


func clear_status() -> void :
	var had: = status != ""
	var was: = status
	status = ""
	toxic = false
	toxic_n = 0
	status_t = 0.0
	rest_t = 0.0
	leech_source = null
	if body.mon:
		body.mon.status = ""
	body.sprite.modulate = body.base_tint()
	body.refresh_label()
	if had:
		Audio.play_at("sfx/battle/cure", body.global_position)
		if was == "sleep" or was == "freeze":
			body._vfx().status_cure_attempt(body, was, true)




func begin_rest(secs: float) -> bool:
	if status == "sleep" or body.hp >= body.max_hp or body.mode == Creature.Mode.FAINTED:
		return false
	clear_status()
	if not apply_status("sleep", null, true):
		return false
	status_t = secs
	rest_t = secs
	rest_total = secs
	rest_chunk = int(ceil(float(body.max_hp - body.hp) / float(REST_STEPS)))
	rest_steps_done = 0
	return true



func _rest_step(delta: float) -> void :
	if rest_t <= 0.0:
		return
	rest_t = maxf(rest_t - delta, 0.0)
	var due: = int((rest_total - rest_t) / (rest_total / float(REST_STEPS)) + 0.0001)
	while rest_steps_done < due:
		rest_steps_done += 1
		body.heal(rest_chunk)




func on_damaging_hit(type: String) -> void :
	if status == "sleep" and rest_t <= 0.0 and StatusRoll.chance(SLEEP_WAKE_HIT):
		clear_status()
	if status == "freeze" and type == "fire":
		clear_status()




func confuse_self_hit() -> int:
	var base: float = ((2.0 * float(body.level) / 5.0 + 2.0) * CONFUSION_POWER
		* stat("atk") / maxf(stat("def"), 1.0)) / 50.0 + 2.0
	var dmg: = maxi(1, int(base * StatusRoll.range(0.85, 1.0)))
	body._vfx().status_self_hit(body)
	body._vfx().popup(body.head_pos(0.6), "-%d" % dmg, Dex.type_color("psychic"))
	body.take_damage(dmg, Vector3.ZERO, 0.0, {"kind": "confusion"})
	return dmg




func sync_status_from_mon() -> void :
	if body.mon == null:
		return
	var want: = String(body.mon.status)
	if want == "":
		if status != "" and status != "leech":
			clear_status()
	elif status == "":
		apply_status(want, null, true)


func _tick_status(delta: float) -> void :
	if status == "":
		return
	_rest_step(delta)

	if status != "freeze":
		status_t -= delta
	_status_tick -= delta
	if _status_tick <= 0.0:
		_status_tick = STATUS_TICK
		match status:
			"burn":
				_dot(maxi(1, int(body.max_hp / 16.0)), "burn")
			"poison":
				if toxic:
					toxic_n = mini(toxic_n + 1, TOXIC_CAP)
					_dot(maxi(1, int(body.max_hp * toxic_n / 16.0)), "poison")
				else:
					_dot(maxi(1, int(body.max_hp / 12.0)), "poison")
			"leech":
				var d: = maxi(1, int(body.max_hp / 16.0))
				_dot(d, "leech")
				if is_instance_valid(leech_source) and leech_source.mode != Creature.Mode.FAINTED:
					body._moves()._drain_flow(leech_source, body, d, "leech_seed")
			"sleep":


				if rest_t > 0.0:
					pass
				elif StatusRoll.chance(SLEEP_WAKE_TICK):
					clear_status()
				else:
					body._vfx().status_cure_attempt(body, "sleep", false)
			"freeze":

				if StatusRoll.chance(FREEZE_THAW_TICK):
					clear_status()


	if status != "freeze" and status_t <= 0.0:
		clear_status()


func _dot(amount: int, why: String) -> void :
	Audio.play_at("sfx/status/tick_" + why, body.global_position)
	body._vfx().popup(body.head_pos(0.6), "-%d %s" % [amount, why], Dex.type_color({"burn": "fire", "poison": "poison", "leech": "grass"}.get(why, "normal")))
	body._vfx().status_tick(body, why)
	body.take_damage(amount, Vector3.ZERO, 0.0, {"kind": why})




var rage_active: = false
var rage_builds: = 0
var rage_fx: Control

func note_rage_move(id: String) -> void :
	if id != "rage":
		clear_rage()
	elif not rage_active:
		rage_active = true
		rage_fx = body._vfx().style_a_rage(body)

func clear_rage() -> void :
	rage_active = false
	rage_builds = 0
	if is_instance_valid(rage_fx):
		rage_fx.queue_free()
	rage_fx = null






func can_be_infatuated_by(source: Node) -> bool:
	if not is_instance_valid(source) or source == body or body.has_meta("substitute_decoy") or not source.alive() or not body.alive() or source.mon == null or body.mon == null:
		return false
	var a: = String(source.mon.gender)
	var b: = String(body.mon.gender)
	return source.side != side and ((a == "male" and b == "female") or (a == "female" and b == "male"))


func infatuate(source: Node) -> bool:
	if not can_be_infatuated_by(source) or is_infatuated():
		return false
	infatuation_source = source
	body._vfx().status_fx(body)
	return true


func is_infatuated() -> bool:
	if infatuation_source == null:
		return false
	var active_modes: = [Creature.Mode.BATTLE_AI, Creature.Mode.PLAYER, Creature.Mode.DUMMY, Creature.Mode.REMOTE, Creature.Mode.PUPPET]
	if not is_instance_valid(infatuation_source) or not body.alive() or body.recalling\
	or not infatuation_source.alive() or infatuation_source.recalling\
	or body.mode not in active_modes or infatuation_source.mode not in active_modes\
	or infatuation_source.side == side:
		infatuation_source = null
		return false
	return true


func clear_infatuation_links() -> void :
	infatuation_source = null
	for other in body.get_tree().get_nodes_in_group("combatant"):
		if is_instance_valid(other) and other != body and other.combat.infatuation_source == body:
			other.combat.infatuation_source = null


func is_mimic_slot(index: int) -> bool:
	return index == mimic_slot and index >= 0 and index < moves.size()\
	and mimic_move != "" and String(moves[index]) == mimic_move



const NO_COPY: = ["mimic", "mirror_move", "sketch", "struggle", "metronome"]



static func copyable_move(target: Node, side: int) -> String:
	if not is_instance_valid(target) or not target.alive() or target.recalling or target.side == side:
		return ""
	var copied: = String(target.combat.cast_move.get("id", ""))
	if copied == "" or copied in NO_COPY or Dex.move(copied).get("kind", "") == "":
		return ""
	return copied



func _tick_lingering(delta: float) -> void :
	if Battle.in_battle and body.alive() and not body.recalling:
		since_enter += delta
	else:
		since_enter = 0.0
	if not body.alive() or body.recalling:
		foresight = false
	uproar_t = maxf(uproar_t - delta, 0.0)
	sleep_act_t = maxf(sleep_act_t - delta, 0.0)
	if ingrained:
		_tick_ingrain(delta)
	torment_t = maxf(torment_t - delta, 0.0)
	snatch_t = maxf(snatch_t - delta, 0.0)
	follow_me_t = maxf(follow_me_t - delta, 0.0)
	imprison_t = maxf(imprison_t - delta, 0.0)
	if imprison_t > 0.0 and body.alive() and not body.recalling:
		body._vfx().imprison_seals(body)
	grudge_t = maxf(grudge_t - delta, 0.0)
	if grudge_t <= 0.0:
		grudge = false
	mean_look_t = maxf(mean_look_t - delta, 0.0)
	if not mean_look_active():
		mean_look_t = 0.0
		mean_look_source = null
	disable_t = maxf(disable_t - delta, 0.0)
	if disable_t <= 0.0 or not body.alive() or body.recalling:
		disable_t = 0.0
		disable_move = ""
	encore_t = maxf(encore_t - delta, 0.0)
	if encore_t <= 0.0:
		encore_move = ""
	if encore_t <= 0.0 and is_instance_valid(encore_fx):
		encore_fx.queue_free()
		encore_fx = null
	if torment_t <= 0.0 and is_instance_valid(torment_fx):
		torment_fx.queue_free()
		torment_fx = null
	if snatch_t <= 0.0 and is_instance_valid(snatch_fx):
		snatch_fx.queue_free()
		snatch_fx = null



func imprisoned(id: String) -> bool:
	for n in body.get_tree().get_nodes_in_group("combatant"):
		if n.side != side and n.alive() and not n.recalling and n.combat.imprison_t > 0.0 and id in n.combat.moves:
			return true
	return false




func resolve_destiny_bond() -> void :
	if not destiny_bond:
		return
	destiny_bond = false
	if is_instance_valid(bond_fx):
		bond_fx.trigger()
	bond_fx = null
	var foe = body.opponent
	if not Battle.in_battle or not is_instance_valid(foe) or not foe.alive() or foe.recalling or foe == body:
		return
	body._vfx().popup(foe.head_pos(0.2), "DESTINY BOND!", Color("b68cde"))
	foe.take_damage(foe.hp, Vector3.ZERO, 0.0, {"source": body, "move": "destiny_bond", "kind": "destiny_bond"})


func resolve_grudge(opts: Dictionary) -> void :
	if not grudge or grudge_t <= 0.0:
		return
	grudge = false
	var source = opts.get("source")
	var id: = String(opts.get("move", ""))
	if not is_instance_valid(source) or source == body or source.side == side or id == "" or String(opts.get("kind", "")) != "move":
		return
	source.combat.grudge_empty[id] = true
	if is_instance_valid(grudge_fx):
		grudge_fx.trigger(source)
	body._vfx().popup(source.head_pos(0.2), "GRUDGE! " + Dex.move(id).get("name", id) + ": 0 PP", Color("b68cde"))



func mean_look_active() -> bool:
	return mean_look_t > 0.0 and body.alive() and not body.recalling and is_instance_valid(mean_look_source) and mean_look_source.alive() and not mean_look_source.recalling



func disabled_move(id: String) -> bool:
	return disable_t > 0.0 and id != "" and id == disable_move and body.alive() and not body.recalling



func encored(id: String) -> bool:
	return encore_t > 0.0 and id != "" and id != encore_move



func tormented(id: String) -> bool:
	return torment_t > 0.0 and id != "" and id == String(cast_move.get("id", ""))



func _tick_taunt(delta: float) -> void :
	if taunt_t <= 0.0:
		return
	taunt_t = maxf(taunt_t - delta, 0.0)
	if not is_instance_valid(taunt_by) or not taunt_by.alive() or taunt_by.recalling:
		taunt_t = 0.0
		taunt_by = null
		return
	var t: Node = taunt_by
	if is_instance_valid(taunt_by.combat.substitute) and taunt_by.combat.substitute.alive():
		t = taunt_by.combat.substitute
	if opponent != t:
		opponent = t



static func follow_me_target(attacker: Node) -> Node:
	var best: Node = null
	if not is_instance_valid(attacker) or not attacker.is_inside_tree():
		return null
	for n in attacker.get_tree().get_nodes_in_group("combatant"):
		if n.side == attacker.side or not n.alive() or n.recalling or n.combat.follow_me_t <= 0.0:
			continue
		if best == null or n.combat.follow_me_stamp > best.combat.follow_me_stamp:
			best = n
	return best



func copy_mimic(target: Node) -> bool:
	if mimic_slot >= 0 or not is_instance_valid(target) or not target.alive() or target.recalling or target.side == side:
		return false
	var slot: = moves.find("mimic")
	var copied: = String(target.combat.cast_move.get("id", ""))
	if slot < 0 or copied == "" or copied in NO_COPY or Dex.move(copied).get("kind", "") == "":
		return false
	mimic_slot = slot
	mimic_move = copied
	moves[slot] = copied
	if selected_move == "mimic":
		selected_move = copied
	return true


func restore_mimic() -> void :
	if is_mimic_slot(mimic_slot):
		moves[mimic_slot] = "mimic"
		if selected_move == mimic_move:
			selected_move = "mimic"
	mimic_slot = -1
	mimic_move = ""


func reset_battle_mods() -> void :
	foresight = false
	consumed_item = ""
	mist_t = 0.0
	last_hit_type = ""
	fury_n = 0
	perish_n = 0
	if body != null and body.get("mon") != null and body.mon != null and not Dex.species(body.species).is_empty():
		types = Dex.species(body.species).get("types", ["normal"]).duplicate()
	clear_decoys()
	protect_t = 0.0
	rest_t = 0.0
	restore_mimic()
	taunt_t = 0.0
	taunt_by = null
	if stockpile > 0:
		stockpile = 0
		body._vfx().stockpile_glow(body)
	torment_t = 0.0
	snatch_t = 0.0
	imprison_t = 0.0
	grudge = false
	grudge_t = 0.0
	grudge_fx = null
	grudge_empty.clear()
	mean_look_t = 0.0
	mean_look_source = null
	disable_t = 0.0
	disable_move = ""
	encore_t = 0.0
	follow_me_t = 0.0
	_tick_lingering(0.0)
	cast_move = {}
	if is_instance_valid(substitute):
		substitute.dismiss()
	clear_infatuation_links()
	_meal_seed.clear()
	_meal_seeded = false
	body.clear_transform()
	reset_move_cooldown()
	if dash_move.get("id", "") == "comet_punch":
		dash_t = 0.0
		_dash_coasting = false
		_dash_settle = false
	if is_instance_valid(comet_fx):
		comet_fx.queue_free()
	cancel_binding()
	if prepare_id in ["revenge", "comet_punch"]:
		cancel_prepare()
	revenge_bonus = false
	cancel_seismic_throw()
	clear_rage()
	screens.clear()
	guard = false
	_finish_ace()
	for k in stages:
		stages[k] = 0
	evasion_t = 0.0
	minimized = false
	evasion = 0.0
	crit_stage = 0
	confusion_t = 0.0
	trap_t = 0.0
	trap_zone = {}
	counter_state = {}
	gcd_t = 0.0
	evade_cd_t = 0.0
	evade_t = 0.0
	evade_invuln_t = 0.0
	sprinting = false
	_evade_exhausted = false
	_evade_regen_t = 0.0
	_ai_tell_t = 0.0
	flight = Flight.GROUNDED
	flight_t = 0.0
	_dig_reset()





func _arena() -> Rect2:
	var g: Node = body._battle()
	if g == null or not g.in_battle or g.arena_rect.size.x <= 0.0:
		return Rect2()
	if not g.allies.has(body) and body != g.wild and not (g.get_node_or_null("/root/LanCampaign") != null and g.extra_foes.has(body)):
		return Rect2()
	return g.arena_rect



func clamp_arena() -> void :
	var r: = _arena()
	if r.size.x <= 0.0:
		return
	r = r.grow(-0.5)
	var p: = body.global_position
	var cx: = clampf(p.x, r.position.x, r.end.x)
	var cz: = clampf(p.z, r.position.y, r.end.y)
	if cx != p.x or cz != p.z:



		if not water_ok(cx, cz):
			return
		body.global_position = Vector3(cx, p.y, cz)
		Transitions.reset_interp(body)




func arena_push() -> Vector3:
	var r: = _arena()
	if r.size.x <= 0.0:
		return Vector3.ZERO
	var p: = Vector2(body.global_position.x, body.global_position.z)
	var push: = Vector2.ZERO
	var m: = 2.0
	push.x += maxf(0.0, m - (p.x - r.position.x)) - maxf(0.0, m - (r.end.x - p.x))
	push.y += maxf(0.0, m - (p.y - r.position.y)) - maxf(0.0, m - (r.end.y - p.y))
	push += _obstacle_push()
	push += _border_push(r, p)
	return Vector3(push.x, 0.0, push.y) / m




func _border_push(r: Rect2, p: Vector2) -> Vector2:
	var w: = border_width()
	if w <= 0.0:
		return Vector2.ZERO
	var m: = w * 2.0
	var push: = Vector2.ZERO
	push.x -= maxf(0.0, m - (p.x - r.position.x)) - maxf(0.0, m - (r.end.x - p.x))
	push.y -= maxf(0.0, m - (p.y - r.position.y)) - maxf(0.0, m - (r.end.y - p.y))
	return push





func border_width() -> float:
	var g: Node = body._battle()
	if g == null or not g.in_battle:
		return 0.0
	var w = g.get("thunder_border")
	return float(w) if w != null else 0.0






func thunder_border_touch() -> bool:
	var g: Node = body._battle()
	if g == null or border_width() <= 0.0:
		return false
	if not g.allies.has(body) and body != g.wild:
		return false
	if not thunder_border_at(g.arena_rect, border_width()):
		return false
	if g.has_method("thunder_flash"):
		g.thunder_flash(body.global_position)
	return true



func thunder_border_at(rect: Rect2, width: float) -> bool:
	if _border_lock > 0.0 or width <= 0.0 or rect.size.x <= 0.0:
		return false
	var p: = Vector2(body.global_position.x, body.global_position.z)
	var hit: Dictionary = BattleArena.thunder_touch(rect, p, width, body.max_hp, types, _border_lock)
	if hit.is_empty():
		return false
	_border_lock = float(hit.lock)
	if int(hit.damage) > 0:
		body.take_damage(int(hit.damage), Vector3.ZERO, 0.0, {"kind": "arena"})
		body._vfx().popup(body.head_pos(0.6), "-%d" % int(hit.damage), Dex.type_color("electric"))
	var push: Vector2 = hit.push
	if bool(hit.paralysis):


		apply_status("paralysis")
		stun_t = maxf(stun_t, BattleArena.BORDER_STUCK)
		entomb(BattleArena.BORDER_STUCK)
		_border_stuck = BattleArena.BORDER_STUCK
		_border_shove = push
	elif push != Vector2.ZERO:

		body.global_position += Vector3(push.x, 0.0, push.y)
	Audio.play_at("sfx/moves/pack/thundershock", body.global_position)
	return true






func teleport_disc_touch(delta: = 0.016) -> bool:


	if _disc_invuln > 0.0:
		_disc_invuln = maxf(_disc_invuln - delta, 0.0)
		if _disc_invuln <= 0.0 and evade_t <= 0.0:
			evade_invuln_t = 0.0
	var g: Node = body._battle()
	if g == null or not g.in_battle:
		return false
	var discs: Array = g.get("teleport_discs")
	if discs == null or discs.is_empty():
		return false
	if not g.allies.has(body) and body != g.wild:
		return false
	var here: = Vector2(body.global_position.x, body.global_position.z)

	var grounded: bool = air_t <= 0.0 and not _leaping and not _pad_leaping and (body.is_on_floor() or floats())
	var now: = Time.get_ticks_msec() / 1000.0
	var r: Dictionary = TeleportDiscs.tick(_disc_state, now, here, grounded, types, discs, g.disc_partners, g.disc_ready, randf())
	if not r.has("to"):
		return false
	var to: Vector2 = discs[int(r.to)]
	var from_pos: = body.global_position

	var src_floor: = Transitions.ground_y(Vector3(from_pos.x, from_pos.y + 1.0, from_pos.z), from_pos.y)
	var dst_floor: = Transitions.ground_y(Vector3(to.x, src_floor + 4.0, to.y), src_floor)
	var y: = dst_floor + ((from_pos.y - src_floor) if floats() else 0.0)
	body.global_position = Vector3(to.x, y, to.y)
	body.velocity = Vector3.ZERO
	Transitions.reset_interp(body)
	_disc_invuln = TeleportDiscs.BLINK_INVULN
	evade_invuln_t = maxf(evade_invuln_t, TeleportDiscs.BLINK_INVULN)
	if g.has_method("disc_flash"):
		g.disc_flash(from_pos, body.global_position)
	Audio.play_at("sfx/battle/dodge", body.global_position, -2.0, 1.4, true)
	return true




func border_blocks_dash(dir: Vector3, reach: float) -> bool:
	var g: Node = body._battle()
	var w: = border_width()
	if g == null or w <= 0.0 or g.arena_rect.size.x <= 0.0:
		return false
	var from: = Vector2(body.global_position.x, body.global_position.z)
	return BattleArena.on_border(g.arena_rect, from + Vector2(dir.x, dir.z) * reach, w)



func _obstacle_push() -> Vector2:
	var world: = body.get_world_3d()
	var space: = world.direct_space_state if world else null
	if space == null:
		return Vector2.ZERO
	var origin: = body.global_position + Vector3(0, 0.6, 0)
	var exclude: = _dynamic_rids()
	var push: = Vector2.ZERO
	for i in 8:
		var a: = i * TAU / 8.0
		var dir: = Vector3(cos(a), 0.0, sin(a))
		var q: = PhysicsRayQueryParameters3D.create(origin, origin + dir, BLOCK_LAYERS)
		q.exclude = exclude
		var hit: = space.intersect_ray(q)
		if not hit.is_empty():
			push += Vector2( - dir.x, - dir.z) * (1.0 - origin.distance_to(hit.position))
	return push




func _dynamic_rids() -> Array:
	var out: Array = [body.get_rid()]
	var tree: = body.get_tree()
	if tree == null:
		return out
	var b: Node = body._battle()
	if b:
		for c in b.allies + [b.wild]:
			if is_instance_valid(c) and c is CollisionObject3D and not out.has(c.get_rid()):
				out.append(c.get_rid())
	var game: Node = body._game()
	var p: Node = game.get_player() if game else null
	if p is CollisionObject3D and not out.has(p.get_rid()):
		out.append(p.get_rid())
	for grp in ["wild", "npc"]:
		for n in tree.get_nodes_in_group(grp):
			if n is CollisionObject3D and not out.has(n.get_rid()):
				out.append(n.get_rid())
	return out



func hold_attacks(secs: float) -> void :
	_cd = maxf(_cd, secs)
	_ai_think = maxf(_ai_think, secs)



func _is_ally() -> bool:
	var b: Node = body._battle()
	return not body.is_wild and b != null and b.in_battle and b.allies.has(body)





const TARGET_FINISH_HP: = 0.35
const TARGET_STICKY: = 0.5


func _pick_target(delta: float) -> void :
	if is_instance_valid(opponent) and is_instance_valid(opponent.combat.substitute):
		opponent = opponent.combat.substitute
	_retarget_t -= delta
	var allowed: = ai_target_pool.is_empty() or ai_target_pool.has(opponent) or (is_instance_valid(opponent) and opponent.has_meta("substitute_decoy") and ai_target_pool.has(opponent.caster))
	if is_instance_valid(opponent) and allowed and opponent.alive() and _retarget_t > 0.0:
		return
	_retarget_t = randf_range(2.0, 4.0)
	var targets: Array = body._moves().targets_of(body)
	if not ai_target_pool.is_empty():
		targets = targets.filter( func(target): return ai_target_pool.has(target) or (target.has_meta("substitute_decoy") and ai_target_pool.has(target.caster)))
	var best: Creature = null
	var best_w: = - INF
	for t in targets:
		if not t.alive():
			continue
		var w: = 2.0 / maxf(body.global_position.distance_to(t.global_position), 1.0)
		if t == last_hit_by:
			w += 1.5
		if float(t.hp) / maxf(t.max_hp, 1) <= TARGET_FINISH_HP:
			w += 1.0
		if t == opponent:
			w += TARGET_STICKY
		w += randf() * 0.2
		if w > best_w:
			best_w = w
			best = t
	if best or not ai_target_pool.is_empty():
		opponent = best



func _stat_move_maxed(id: String) -> bool:
	var mv: = Dex.move_for(id, body.species)
	if mv.has("screen"):
		return screens.has(String(mv.screen))
	match mv.get("kind", ""):
		"self_buff":
			if mv.get("stats") is Dictionary:
				for k in mv.stats:
					if int(stages.get(String(k), 0)) < 6:
						return false
				return true
			return int(stages.get(String(mv.get("stat", "")), 0)) >= 6
		"debuff_aoe":
			return is_instance_valid(opponent) and int(opponent.stages.get(String(mv.get("stat", "")), 0)) <= -6
	return false




func stockpile_fails(id: String) -> bool:
	match id:
		"stockpile":
			return stockpile >= 3
		"spit_up":
			return stockpile <= 0
		"swallow":
			return stockpile <= 0 or body.hp >= body.max_hp
	return false





const AI_SLOP_BASE: = 0.8
const AI_SLOP_MAX: = 1.0
const AI_SLOP_KNEE: = 1.3
const AI_SLOP_KNEE_VALUE: = 0.8



const KIT_LOW_HP: = 0.5
const KIT_STAT_DEPTH: = 2


const KIT_STAT_SLOP: = 0.4

const TRAINER_ITEM_HP: = 0.35

const SELF_DESTRUCT_HP: = 0.25





func _ai_pick(avail: Array) -> String:
	var live: Array = avail.filter( func(id): return not stockpile_fails(String(id)) and not tormented(String(id)) and not disabled_move(String(id)) and not encored(String(id)) and not imprisoned(String(id)) and not grudge_empty.has(String(id)))
	if not live.is_empty():
		avail = live
	if _is_ally():

		var no_roar: Array = avail.filter( func(id): return not (Dex.move_for(String(id), body.species).get("effect", {}) as Dictionary).has("force_switch"))
		if not no_roar.is_empty():
			avail = no_roar
		var useful: Array = avail.filter( func(id): return not _stat_move_maxed(id))
		if not useful.is_empty():
			avail = useful

	if ai_legacy_pick:
		return String(avail.pick_random())


	if float(body.hp) / maxf(float(body.max_hp), 1.0) > SELF_DESTRUCT_HP:
		var no_boom: Array = avail.filter( func(id): return not bool(Dex.move_for(String(id), body.species).get("self_destruct", false)))
		if not no_boom.is_empty():
			avail = no_boom



	var dmg: = {}
	for id in avail:
		var mv: = Dex.move_for(id, body.species)
		if float(mv.get("power", 0.0)) > 0.0:
			dmg[id] = body._moves().expected_damage(body, opponent, mv)
	var usable: Array = avail.filter( func(id): return not dmg.has(id) or dmg[id] > 0.0)
	var pool: Array = usable if not usable.is_empty() else avail
	var best: = _best_move(pool, dmg)

	if best != "" and is_instance_valid(opponent) and dmg.get(best, 0.0) >= float(opponent.hp):
		return best
	if not tactic.is_empty() and not tactic.rules.is_empty():
		var res: = AiTactics.decide(tactic.rules, _tactic_ctx(pool))
		tactic_last = String(res.rule)
		if String(res.pick) != "":
			return String(res.pick)
		if not res.pool.is_empty() and res.pool.size() != pool.size():
			pool = res.pool
			best = _best_move(pool, dmg)
	var brain_pick: String = brain.pick_move(self, pool, dmg, best)
	if brain_pick != "":
		return brain_pick
	if randf() < ai_error_chance():
		return String(pool.pick_random())

	var has_hit: = not dmg.values().filter( func(v): return v > 0.0).is_empty()
	var kit: Array = pool.filter( func(id): return _worth_status(id, has_hit))
	if not kit.is_empty():
		return String(kit.pick_random())
	return best if best != "" else String(pool.pick_random())



func ai_error_chance() -> float:
	if _ai_scale() <= AI_SLOP_BASE:
		return 0.0
	if _ai_scale() <= AI_SLOP_KNEE:
		var t: = (_ai_scale() - AI_SLOP_BASE) / (AI_SLOP_KNEE - AI_SLOP_BASE)
		return AI_SLOP_KNEE_VALUE * t * t * (3.0 - 2.0 * t)
	var u: = clampf((_ai_scale() - AI_SLOP_KNEE) / (1.6 - AI_SLOP_KNEE), 0.0, 1.0)
	return lerpf(AI_SLOP_KNEE_VALUE, AI_SLOP_MAX, u)





func _worth_status(id: String, has_damage: bool) -> bool:
	var mv: = Dex.move_for(id, body.species)
	if String(mv.get("kind", "")) == "transform":
		return body.transformed_species == "" and is_instance_valid(opponent)\
		and opponent.transformed_species == ""
	if float(mv.get("power", 0.0)) > 0.0 or _stat_move_maxed(id) or bool(mv.get("blink", false)):
		return false
	if float(body.hp) / maxf(body.max_hp, 1) < KIT_LOW_HP:
		return false


	if mv.has("screen"):
		return not screens.has(String(mv.screen))
	var stack_ok: = not has_damage or ai_error_chance() >= KIT_STAT_SLOP
	match mv.get("kind", ""):
		"self_buff":
			var stat: = String(mv.get("stat", ""))
			var delta: = int(mv.get("stages", 1))
			if stat == "" and mv.get("stats") is Dictionary and not mv.stats.is_empty():
				stat = String(mv.stats.keys()[0])
				delta = int(mv.stats[stat])
			var cur: = crit_stage if stat == "crit" else int(stages.get(stat, 0))
			var moved: = cur * signi(delta)
			return delta != 0 and (moved <= 0 or stack_ok) and moved < KIT_STAT_DEPTH
		"debuff_aoe":
			if not is_instance_valid(opponent):
				return false
			var cur2: = int(opponent.stages.get(String(mv.get("stat", "")), 0))
			return (cur2 >= 0 or stack_ok) and cur2 > - KIT_STAT_DEPTH
	var ef = mv.get("effect")
	if ef is Dictionary and ef.has("status"):
		var st: = String(ef.status)
		if not is_instance_valid(opponent) or opponent.status != "":
			return false
		return body._moves().STATUS_IMMUNE.get(st, "") not in opponent.types
	return false



func _want_trainer_item() -> bool:
	if not is_trainer_mon or trainer_item == "" or _item_used:
		return false
	if not body.alive():
		return false
	var e: Dictionary = ItemsData.item(trainer_item).get("effect", {})
	if e.has("hp"):
		return float(body.hp) / maxf(body.max_hp, 1) <= TRAINER_ITEM_HP
	if e.has("cure"):
		return body.status != "" and (String(e.cure) == "all" or body.status == String(e.cure))
	return false




func _use_trainer_item() -> void :
	_item_used = true
	var e: Dictionary = ItemsData.item(trainer_item).get("effect", {})
	if e.has("hp"):
		var amount: int = body.max_hp if str(e.hp) == "full" else int(e.hp)
		body.heal(mini(amount, body.max_hp - body.hp))
	elif e.has("cure") and (String(e.cure) == "all" or body.status == String(e.cure)):
		body.clear_status()
	var dlg: Node = body.get_node_or_null("/root/Dialogue")
	if dlg:
		dlg.msg("%s used a %s!" % ["The trainer", ItemsData.item_name(trainer_item)], 1.4, "item")
	Debug.log("[item] trainer: %s on %s" % [trainer_item, body.species])





func _best_move(pool: Array, dmg: Dictionary) -> String:
	var best: = ""
	var best_turns: = INF
	var best_dmg: = 0.0
	var hp: = maxf(float(opponent.hp), 1.0) if is_instance_valid(opponent) else 1.0


	var border: = _border_line()
	for id in pool:
		var d: float = dmg.get(id, 0.0)
		if d <= 0.0:
			continue
		var turns: = ceilf(hp / d)
		if border != Rect2() and _knocks_to_border(id, border):
			turns = maxf(turns - 1.0, 1.0)
		if turns < best_turns or (turns == best_turns and d > best_dmg):
			best = id
			best_turns = turns
			best_dmg = d
	return best if best != "" else String(pool.pick_random())



func _border_line() -> Rect2:
	var g: Node = body._battle()
	if border_width() <= 0.0 or g == null or g.arena_rect.size.x <= 0.0:
		return Rect2()
	return g.arena_rect



func _knocks_to_border(id: String, rect: Rect2) -> bool:
	if not is_instance_valid(opponent):
		return false
	var kb: = float(Dex.move_for(id, body.species).get("knockback", 4.0)) * KNOCKBACK_SCALE
	var from: = Vector2(body.global_position.x, body.global_position.z)
	var foe: = Vector2(opponent.global_position.x, opponent.global_position.z)
	return BattleArena.knock_hits_border(rect, from, foe, kb)



func _tactic_ctx(pool: Array) -> Dictionary:
	var foe_hp: = 1.0
	var foe_status: = ""
	var dist: = 0.0
	var opening: = false
	var foe_types: Array = []
	var prep_type: = ""
	var on_pad: = false
	var edge: = 99.0
	var rim: = 99.0
	if is_instance_valid(opponent):
		foe_hp = float(opponent.hp) / maxf(opponent.max_hp, 1)
		foe_status = String(opponent.status)
		foe_types = opponent.types
		var off: Vector3 = opponent.global_position - body.global_position
		off.y = 0.0
		dist = off.length()
		var oc: Combatant = opponent.combat
		opening = opponent.stagger_t > 0.0 or oc._recover_t > 0.0 or oc.gcd_t > 0.0
		prep_type = String(oc.prepare_move.get("type", ""))
		var pad: = _platform_at(opponent.global_position)
		if pad != null:
			on_pad = true
			var offset: = Vector2(opponent.global_position.x - pad.global_position.x, 
				opponent.global_position.z - pad.global_position.z)
			edge = _pad_radius(pad, offset) - offset.length()
		var g: Node = body._battle()
		if g != null and border_width() > 0.0 and g.arena_rect.size.x > 0.0:
			rim = BattleArena.border_gap(g.arena_rect, Vector2(opponent.global_position.x, opponent.global_position.z))
	return {"fight_t": fight_t, "hp": float(body.hp) / maxf(body.max_hp, 1), "foe_hp": foe_hp, 
		"speed_ratio": foe_speed_ratio(), "foe_status": foe_status, "foe_types": foe_types, 
		"dist": dist, "opening": opening, "foe_prep_type": prep_type, "foe_on_pad": on_pad, "foe_edge": edge, "foe_rim": rim, "seen": _seen_foe.keys(), "pool": pool, "kit": moves}




const RESTRAINT_MOVES: = ["bind", "wrap", "clamp"]




func restraint_moves(pool: Array) -> Array:
	var out: Array = []
	if not is_instance_valid(opponent) or Dex.too_big_to_coil(body, opponent):
		return out
	for id in pool:
		if id in RESTRAINT_MOVES:
			out.append(id)
	return out



func foe_speed_ratio() -> float:
	return opponent.stat("spe") / maxf(stat("spe"), 1.0) if is_instance_valid(opponent) else 1.0



func hold_ticks_estimate() -> float:
	return float(preload("res://scripts/bind_hold.gd").MAX_SQUEEZES)




const WATER_REACH: = 10.0
const SHORE_DANGER: = 3.5



func water_edge() -> Vector3:
	var g: Node = body._game()
	if g == null:
		return Vector3.INF
	var rects: Array = g.water_rects()
	if rects.is_empty():
		return Vector3.INF
	var t: Vector2 = Water.nearest_point(rects, body.global_position.x, body.global_position.z)
	if not t.is_finite():
		return Vector3.INF
	var q: = Vector3(t.x, body.global_position.y, t.y)
	if Vector2(q.x - body.global_position.x, q.z - body.global_position.z).length() > WATER_REACH:
		return Vector3.INF
	return q



func surface_at_point(x: float, z: float) -> int:
	var g: Node = body._game()
	return g.surface_at(x, z) if g != null else Water.Surface.GROUND



func on_dry_land() -> bool:
	return surface() == Water.Surface.GROUND



func foe_swims() -> bool:
	return is_instance_valid(opponent) and opponent.combat.swimmer



func super_effective_moves(pool: Array) -> Array:
	var out: Array = []
	if not is_instance_valid(opponent):
		return out
	for id in pool:
		var mv: = Dex.move_for(id, body.species)
		if float(mv.get("power", 0.0)) > 0.0 and Dex.effectiveness(String(mv.get("type", "")), opponent.types) >= 2.0:
			out.append(id)
	return out




func super_coming(max_wait: float) -> bool:
	if max_wait <= 0.0 or not is_instance_valid(opponent):
		return false
	var soon: = false
	for id in super_effective_moves(moves):
		var cd: = float(move_cd.get(id, 0.0))
		if cd <= 0.0:
			return false
		soon = soon or cd <= max_wait
	return soon



func auto_brain(tier: String, unit: = "", klass: = "") -> void :
	auto_tier = tier
	auto_unit = unit
	auto_class = klass
	fight_t = 0.0
	_tactic_sig = ""
	if tier == "":
		return
	var mv_node: Node = body._moves()
	if not mv_node.move_used.is_connected(_on_seen_move):
		mv_node.move_used.connect(_on_seen_move)
	ai_auto_update(true)


func _on_seen_move(user, mv) -> void :
	if user != opponent or not is_instance_valid(opponent) or float(mv.get("power", 0.0)) <= 0.0:
		return
	_seen_foe[String(mv.get("id", ""))] = true



func ai_auto_update(force: = false) -> void :
	if auto_tier == "" or not is_instance_valid(opponent):
		return
	if opponent.get_instance_id() != _seen_for:
		_seen_for = opponent.get_instance_id()
		_seen_foe.clear()
	var mine: Array = []
	var tool_melee: = false
	var tool_ranged: = false
	for id in moves:
		var mv: = Dex.move_for(id, body.species)
		if float(mv.get("power", 0.0)) <= 0.0:
			continue
		var r: = AiMatchup.is_ranged(mv)
		mine.append({"power": float(mv.power), "ranged": r})
		tool_melee = tool_melee or not r
		tool_ranged = tool_ranged or r
	var seen: Array = []
	for id in _seen_foe:
		seen.append({"ranged": AiMatchup.is_ranged(Dex.move_for(id, opponent.species))})
	var eff_foe: = 0.0
	for t in opponent.types:
		eff_foe = maxf(eff_foe, Dex.effectiveness(String(t), body.types))
	var eff_me: = 0.0
	for t in body.types:
		eff_me = maxf(eff_me, Dex.effectiveness(String(t), opponent.types))
	ai_stance = AiMatchup.stance(auto_tier, seen, opponent.types, eff_foe, eff_me, tool_melee, tool_ranged)

	var kit_group: = AiMatchup.group(mine, can_fly())
	tactic = AiTactics.resolve(kit_group, body.species, auto_unit, auto_class)
	var group_name: String = String(tactic.group) if String(tactic.group) != "" else kit_group
	if String(tactic.stance) != "":
		ai_stance = String(tactic.stance)
	if role != "auto":
		group_name = role
		ai_stance = ""
	var id: = AiMatchup.brain_id(group_name, ai_stance, auto_tier)
	var sig: = id + "|" + auto_unit
	if id == brain.id and sig == _tactic_sig:
		return
	if id != brain.id:
		if not force and (Time.get_ticks_msec() - _auto_swap_ms) / 1000.0 < AUTO_SWAP_GAP:
			return
		_auto_swap_ms = Time.get_ticks_msec()
		var scale_before: = ai_think_scale
		set_brain(id)
		if not brain.p.has("scale"):
			ai_think_scale = scale_before
	brain.p.merge(tactic.params, true)
	if tactic.params.has("scale"):
		ai_think_scale = float(tactic.params.scale)
	_tactic_sig = sig



func set_role(r: String) -> void :
	role = AiMatchup.resolve_role(r, AiMatchup.roles_for(body.species, moves))
	if auto_tier != "":
		ai_auto_update(true)



func set_brain(id: String) -> void :
	brain = AiBrains.make(id)
	if brain.p.has("scale"):
		ai_think_scale = float(brain.p.scale)


func battle_ai(delta: float) -> Vector3:
	if auto_tier != "":
		fight_t += delta
		_auto_t -= delta
		if _auto_t <= 0.0:
			_auto_t = AUTO_EVERY
			ai_auto_update()
	if evade_t <= 0.0:
		sprinting = false
	if _ai_tell_t > 0.0:
		_ai_tell_t -= delta
		if _ai_tell_t <= 0.0:
			evade(_ai_tell_dir)
		return Vector3.ZERO
	if Battle.tut_hold_foe:
		return Vector3.ZERO
	if body.is_wild:
		_pick_target(delta)
	if not is_instance_valid(opponent) or opponent.mode == Creature.Mode.FAINTED:
		return Vector3.ZERO
	if _want_trainer_item():
		_use_trainer_item()
		_recover_t = AI_RECOVER
		return Vector3.ZERO
	if _recover_t > 0.0:
		_recover_t -= delta
		_ai_think -= delta
		return Vector3.ZERO
	var to_o: = opponent.global_position - body.global_position
	to_o.y = 0.0
	var d: = to_o.length()
	var dir: = to_o / maxf(d, 0.001)
	if ai_uses_moves and not moves.is_empty():
		var punish: = _ai_punish(d)
		if not punish:
			_ai_punished = false
		_ai_think -= delta
		var may_fire: = brain.may_fire(self, _ai_move_ready(d), delta)
		var counter: = brain.counter(self, _ai_move_ready(d), delta)
		var fire: = (_ai_think <= 0.0 and may_fire) or counter

		if punish and not _ai_punished and _ai_tactic_on:
			fire = true
			_ai_punished = true
		if fire and can_act():
			_ai_tactic_on = _ai_tactic_ok()
			var used: bool = _ai_use_best_move(d)
			var base: = randf_range(AI_THINK_MIN, AI_THINK_MAX) if used else AI_THINK_RETRY
			_ai_think = brain.think_delay(self, used, base * _ai_scale())
	elif _cd <= 0.0 and _lunge_t <= 0.0 and gcd_t <= 0.0 and d < 3.2 and may_start(LUNGE) and randf() < 0.04:
		_start_lunge(dir)
		return Vector3.ZERO
	if ai_uses_moves and out_of_pp() and d > 1.4:
		return dir

	var back: = _water_retreat()
	if back != Vector3.ZERO:
		_ai_evade(delta, true, back)
		return back
	if randf() < 0.002:
		body._strafe *= -1.0
	var side_v: = Vector3( - dir.z, 0.0, dir.x) * body._strafe
	var band: = brain.band(self, _ai_band())
	var reach: = _ai_reach()
	var low_hp: = body.max_hp > 0 and float(body.hp) <= float(body.max_hp) * AI_LOW_HP
	var kite: = band
	if low_hp:
		kite = Vector2(band.x * 1.2, band.y * AI_KITE_MULT)
	var slip: = _windup_slip(d, band)



	var swim: = _swim_want(d)
	var want: Vector3
	if swim != Vector3.INF:
		want = swim
	elif slip:
		want = (side_v - dir * 0.4).normalized()
	elif d > kite.y:
		want = (dir + side_v * 0.3).normalized()
	elif d < kite.x:

		want = ( - dir + side_v * 0.5).normalized() * (1.0 if low_hp else 0.8)
	else:


		if _ai_move_ready(d) and _ai_tactic_on:
			want = Vector3.ZERO
		elif _ai_tactic_on:
			var centre: = (band.x + band.y) * 0.5
			var radial: = dir * clampf((centre - d) / maxf(band.y - band.x, 0.1), -1.0, 1.0)
			want = (side_v * AI_WAIT_STRAFE + radial * AI_WAIT_RADIAL).normalized()
		else:
			want = side_v * 0.35
	if swim == Vector3.INF:
		want = brain.steer(self, d, dir, side_v, band, low_hp, want, delta)
		want = brain.water_steer(self, d, dir, want, delta)

	want = _pad_edge(want)
	var hazard: Dictionary = Battle.ai_hazard.call(body, want) if Battle.ai_hazard.is_valid() else {}
	if not hazard.is_empty():
		want = hazard.get("want", want)

	_ai_flight(delta, want)




	var quake_pending: = _jump_threat(d).begins_with("quake")
	var reason: = brain.evade_reason(self, not quake_pending and (slip or (low_hp and d < band.y) or bool(hazard.get("evade", false))))

	var dodge: = _ai_dodge(delta, d, side_v)
	if dodge != Vector3.ZERO:
		_ai_evade(delta, true, dodge)
		return dodge

	if _ai_try_threat(delta, d):
		return want
	_ai_evade(delta, reason, want)
	return want




func _ai_try_threat(delta: float, d: float) -> bool:
	var threat: = _jump_threat(d)
	if threat == "":
		_ai_jump_threat = ""
		_ai_jump_done = false
		return false
	var flyer: = can_fly() and flight == Flight.GROUNDED
	if threat != _ai_jump_threat:
		_ai_jump_threat = threat
		_ai_jump_done = false


		var window: = jump_time if flyer and jump_time > 0.0 else EVADE_INVULN
		var err: = randf_range(-1.0, 1.0) * _ai_jump_error() * window
		_ai_jump_at = maxf(_jump_lead(threat, d) - window * 0.5 + err, 0.0)
		if randf() < _ai_jump_miss():
			_ai_jump_at += AI_JUMP_LATE + _ai_jump_error() * window

	if _ai_jump_done or air_t > 0.0 or land_t > 0.0 or dash_t > 0.0 or _lunge_t > 0.0:
		return false
	_ai_jump_at -= delta

	if _ai_jump_at > (0.0 if flyer else AI_TELL):
		return false
	if flyer:
		if stamina < pp_max * (JUMP_STAMINA + AI_JUMP_RESERVE):
			return false
		if take_flight():
			_ai_jump_done = true
			return true
		return false
	if not _ai_leave(Vector3.ZERO):
		return false
	_ai_jump_done = true
	return true






func _jump_threat(d: float) -> String:
	if not is_instance_valid(opponent) or not can_act():
		return ""
	var sig: = "@%d" % opponent.combat.cast_n
	var mv: Dictionary = opponent.combat.cast_move
	if opponent.root_t > 0.0 and String(mv.get("kind", "")) == "aoe_self"\
	and String(mv.get("type", "")) == "ground" and d <= float(mv.get("radius", 0.0)):
		return "quake" + sig
	if can_fly() and flight == Flight.GROUNDED and _incoming_body_attack(d) != Vector3.ZERO and _can_clear(opponent):
		return "dash" + sig
	return ""




func _ai_jump_error() -> float:
	return maxf(AI_JUMP_ERR + AI_JUMP_ERR_SLOPE * (_ai_scale() - AI_JUMP_SHARP), 0.0)





func _ai_jump_miss() -> float:
	var d: = maxf(_ai_scale() - AI_JUMP_SHARP, 0.0)
	return minf(AI_JUMP_MISS_MAX, AI_JUMP_MISS_LIN * d + AI_JUMP_MISS_QUAD * d * d)




func _incoming_body_attack(d: float) -> Vector3:
	var oc: Combatant = opponent.combat
	var reach: = reach_to(opponent)
	if oc.dash_t > 0.0 and d - reach <= float(oc.dash_move.get("range", 0.0)):
		return oc.dash_dir if _aimed_at_me(oc.dash_dir) else Vector3.ZERO
	if oc._lunge_t > 0.0 and d - reach <= LUNGE_SPEED * LUNGE_TIME:
		return oc._lunge_dir if _aimed_at_me(oc._lunge_dir) else Vector3.ZERO


	if not oc.prepare_move.is_empty():
		var pk: = String(oc.prepare_move.get("kind", ""))
		if pk in ["arc", "multi_arc"] and d - reach <= float(oc.prepare_move.get("range", 2.0)) + 0.3:
			return oc.aim_dir() if _aimed_at_me(oc.aim_dir()) else Vector3.ZERO


		if pk in ["projectile", "homing", "stream"] and d <= float(oc.prepare_move.get("range", 6.0)) + 0.5:
			return oc.aim_dir() if _aimed_at_me(oc.aim_dir()) else Vector3.ZERO
	return Vector3.ZERO


func _aimed_at_me(dir: Vector3) -> bool:
	var to_me: = body.global_position - opponent.global_position
	to_me.y = 0.0
	if to_me.length() < 0.01:
		return true
	return to_me.normalized().dot(Vector3(dir.x, 0.0, dir.z).normalized()) > 0.6





func _can_clear(att: Node) -> bool:
	if can_fly() and flight == Flight.GROUNDED:
		return true
	return jump_height * AI_JUMP_CLEAR >= att.look_height() * DASH_REACH_FACTOR



func _jump_lead(threat: String, d: float) -> float:
	if threat.begins_with("quake"):
		return maxf(opponent.root_t - QUAKE_TAIL, 0.0)
	var oc: Combatant = opponent.combat
	var reach: = reach_to(opponent)
	if oc.dash_t > 0.0:
		return maxf((d - reach) / maxf(oc.dash_speed, 1.0), 0.0)
	return maxf((d - reach) / LUNGE_SPEED, 0.0)




func _windup_slip(d: float, band: Vector2) -> bool:
	return is_instance_valid(opponent) and opponent.root_t > 0.0 and d < band.y + 1.0





func _ai_evade(delta: float, reason: bool, dir: Vector3) -> bool:
	if not reason:
		_ai_sprint_seen = false
		return false
	if not can_evade() or not brain.evade_ok(self):
		return false
	if not _ai_sprint_seen:
		_ai_sprint_seen = true
		_ai_react_t = brain.react_time(self, AI_SPRINT_REACT * maxf(_ai_scale(), 0.05))
	_ai_react_t -= delta
	if _ai_react_t > 0.0:
		return false
	_ai_react_t = brain.react_time(self, AI_SPRINT_REACT * maxf(_ai_scale(), 0.05))
	return _ai_leave(dir)




func _ai_leave(dir: Vector3) -> bool:
	if _ai_tell_t > 0.0 or not can_evade():
		return false
	_ai_tell_t = AI_TELL
	_ai_tell_dir = dir
	body.evade_tell(AI_TELL)
	Audio.play_at("sfx/battle/dodge_tell", body.global_position, -6.0, 1.0, true)
	return true




func _ai_tactic_ok() -> bool:
	return brain.tactic_ok(self, randf() >= minf(1.0, _ai_jump_miss() * AI_TACTIC_MISS_MULT))




func max_move_fatigue() -> float:
	var worst: = 0.0
	for id in moves:
		worst = maxf(worst, Dex.fatigue(Dex.move_for(id, body.species)))
	return worst



func ai_move_cooled() -> bool:
	if not ai_uses_moves or moves.is_empty() or gcd_t > 0.0:
		return false
	for id in moves:
		if float(move_cd.get(id, 0.0)) <= 0.0 and stamina >= Dex.fatigue(Dex.move_for(id, body.species)):
			return true
	return false



func _ai_move_ready(d: float) -> bool:
	if not ai_uses_moves or moves.is_empty() or gcd_t > 0.0:
		return false
	for id in moves:
		if float(move_cd.get(id, 0.0)) <= 0.0 and _in_range(id, d) and stamina >= Dex.fatigue(Dex.move_for(id, body.species)):
			return true
	return false




func _ai_use_best_move(d: float) -> bool:
	if out_of_pp():
		if d < 2.2:
			struggle()
			return true
		return false
	var avail: Array = moves.filter( func(id): return not disabled_move(String(id)) and not encored(String(id)) and not imprisoned(String(id)) and not grudge_empty.has(String(id)) and gcd_t <= 0.0 and move_cd.get(id, 0.0) <= 0.0 and _in_range(id, d) and body._moves().can_afford(body, id) and brain.cast_ok(self, id))



	if not avail.is_empty() and _immune_only(avail) and _has_connecting_move():
		return false
	if not avail.is_empty():
		var pick: = _ai_pick(avail)
		if pick == "-":
			return false
		if body._moves().use(body, pick):
			_recover_t = AI_RECOVER
			return true
	return false




func _immune_only(avail: Array) -> bool:
	for id in avail:
		var mv: = Dex.move_for(id, body.species)
		if float(mv.get("power", 0.0)) <= 0.0:
			return false
		if body._moves().expected_damage(body, opponent, mv) > 0.0:
			return false
	return true



func _has_connecting_move() -> bool:
	for id in moves:
		var mv: = Dex.move_for(id, body.species)
		if float(mv.get("power", 0.0)) > 0.0 and body._moves().expected_damage(body, opponent, mv) > 0.0:
			return true
	return false






func _ai_dodge(delta: float, d: float, side_v: Vector3) -> Vector3:


	var incoming: = is_instance_valid(opponent) and _incoming_body_attack(d) != Vector3.ZERO
	if not incoming or not can_act():
		_ai_dodge_t = 0.0
		return Vector3.ZERO
	if _ai_dodge_t <= 0.0:
		if not _ai_tactic_on:
			return Vector3.ZERO
		_ai_dodge_t = AI_DODGE_TIME
	_ai_dodge_t -= delta
	return side_v.normalized()




func _ai_flight(delta: float, want: Vector3) -> void :
	if not can_fly():
		return

	var pool: = fly_pp / maxf(fly_pp_base, 0.001)
	match flight:
		Flight.AIRBORNE:
			if pool < brain.flight_keep(self, AI_FLIGHT_KEEP)\
			or (want.length() < 0.1 and flight_t > brain.flight_idle(self, AI_FLIGHT_IDLE))\
			or brain.land_now(self, flight_t):
				begin_landing()
		Flight.GROUNDED:



			if pool > brain.flight_min(self, AI_FLIGHT_MIN) and want.length() > 0.1 and can_take_flight()\
			and brain.takeoff_ok(self, delta):
				take_flight()




func _ai_punish(d: float) -> bool:
	if not is_instance_valid(opponent) or not can_act():
		return false
	var oc: Combatant = opponent.combat
	if oc == null or (oc._recover_t <= 0.0 and oc.gcd_t <= 0.0):
		return false
	return _ai_move_ready(d)






const AI_BAND_MAX: = 3.5
const AI_BAND_NEAR_RATIO: = 0.7




func _ai_reach() -> float:
	if not ai_uses_moves or moves.is_empty():
		return 0.0
	var reach: = 0.0
	for id in moves:
		var mv: = Dex.move_for(id, body.species)
		if float(mv.get("power", 0)) <= 0.0:
			continue
		match mv.get("kind", ""):
			"dash":
				reach = maxf(reach, float(mv.get("range", 2.0)) + 0.6)
			"arc", "multi_arc":


				reach = maxf(reach, float(mv.get("range", 2.0)))
			"whip":


				reach = maxf(reach, Dex.whip_reach(body.species, mv))
			"aoe_self":
				reach = maxf(reach, float(mv.get("radius", 3.0)))
			_:
				reach = maxf(reach, minf(float(mv.get("range", 10.0)), 6.0))
	return reach


func _ai_band() -> Vector2:
	var reach: = _ai_reach()
	if reach <= 0.0:
		return Vector2(1.8, 3.0)
	var far: = minf(reach * 0.9, AI_BAND_MAX)
	return Vector2(far * AI_BAND_NEAR_RATIO, far)






func _nearest_open_water(p: Vector3) -> Vector3:
	var g: Node = body._game()
	if g == null:
		return Vector3.INF
	var rects: Array = g.water_rects()
	if rects.is_empty():
		return Vector3.INF
	var t: Vector2 = Water.nearest_point(rects, p.x, p.z)
	if not t.is_finite():
		return Vector3.INF
	var q: = Vector3(t.x, body.global_position.y, t.y)
	var pad: = _platform_at(q)
	if pad == null:
		return q
	var out: = Vector2(body.global_position.x - pad.global_position.x, 
		body.global_position.z - pad.global_position.z)
	if out.length() < 0.05:
		out = Vector2(1.0, 0.0)
	out = out.normalized()
	var rim: = _pad_radius(pad, out) + AI_SWIM_ARRIVE
	q = Vector3(pad.global_position.x + out.x * rim, q.y, pad.global_position.z + out.y * rim)
	for i in 24:
		if _platform_at(q) == null:
			break
		q += Vector3(out.x, 0.0, out.y) * 0.3
	return q



func _platform_at(p: Vector3) -> Node:
	for b in body.get_tree().get_nodes_in_group("water_platform"):
		if is_instance_valid(b) and b.has_method("covers") and b.covers(p.x, p.z):
			return b
	return null





func _pad_holds(pad: Node) -> bool:
	var cap: Variant = pad.get("capacity_kg")
	return cap == null or float(cap) >= weight_kg



func _pad_radius(pad: Node, direction: = Vector2.RIGHT) -> float:
	if pad.has_method("edge_radius"):
		return pad.edge_radius(direction)
	var r: Variant = pad.get("radius")
	return float(r) if r != null else 1.4






func _swim_want(d: float) -> Vector3:
	if not swimmer or locomotion != "ground" or floats() or not body.is_on_floor():
		return Vector3.INF
	if surface() == Water.Surface.GROUND:
		return Vector3.INF
	if not is_instance_valid(opponent) or opponent.combat.surface() != Water.Surface.GROUND:
		return Vector3.INF


	var foe_pad: = _platform_at(opponent.global_position)
	if pad and foe_pad != null and d < 3.0:
		var at: = Vector3(foe_pad.global_position.x - body.global_position.x, 0.0, 
			foe_pad.global_position.z - body.global_position.z)
		if try_pad_climb(at):
			return Vector3.INF
		return at.normalized()
	var goal: = _swim_orbit_goal(foe_pad)
	if not goal.is_finite():
		return Vector3.INF
	var to: = Vector3(goal.x - body.global_position.x, 0.0, goal.z - body.global_position.z)
	if to.length() < 0.05:
		return Vector3.ZERO
	return _around_pads(to.normalized())




var _orbit_a: = INF
func _swim_orbit_goal(foe_pad: Node) -> Vector3:
	var o: = opponent.global_position
	var r: = AI_SWIM_ORBIT_MIN
	if foe_pad != null:
		r = maxf(r, _pad_radius(foe_pad) + AI_SWIM_ORBIT)
	var dt: = body.get_physics_process_delta_time()
	if not is_finite(_orbit_a):
		_orbit_a = atan2(body.global_position.z - o.z, body.global_position.x - o.x)
	if randf() < AI_SWIM_ORBIT_FLIP * dt:
		body._strafe *= -1.0
	var lead: = 0.6
	for attempt in 2:
		var a: = _orbit_a + body._strafe * (AI_SWIM_ORBIT_W * dt)
		var aim: = Vector3(o.x + cos(a + body._strafe * lead) * r, body.global_position.y, 
			o.z + sin(a + body._strafe * lead) * r)
		var q: = _nearest_open_water(aim)
		if q.is_finite() and Vector2(q.x - aim.x, q.z - aim.z).length() < 1.2:

			_orbit_a = atan2(body.global_position.z - o.z, body.global_position.x - o.x) + body._strafe * AI_SWIM_ORBIT_W * dt
			return q
		body._strafe *= -1.0
	return _nearest_open_water(o)






func _around_pads(want: Vector3) -> Vector3:
	var p: = body.global_position + want.normalized() * (AI_PAD_EDGE + 0.4)
	var b: = _platform_at(p)
	if b == null:
		return want
	if is_instance_valid(opponent) and _platform_at(opponent.global_position) == b:
		return want
	var out: = Vector2(body.global_position.x - b.global_position.x, 
		body.global_position.z - b.global_position.z)
	if out.length() < 0.01:
		return want
	out = out.normalized()
	var tangent: = Vector2( - out.y, out.x)
	if tangent.dot(Vector2(want.x, want.z)) < 0.0:
		tangent = - tangent
	return (Vector3(tangent.x, 0.0, tangent.y) + want * 0.3).normalized()






func _pad_edge(want: Vector3) -> Vector3:
	if want.length() < 0.01 or swimmer or locomotion != "ground" or floats() or air_t > 0.0 or _pad_leaping:
		return want
	var pad: = _platform_at(body.global_position)
	if pad == null or surface() != Water.Surface.GROUND:
		return want
	var step: = body.global_position + want.normalized() * AI_PAD_EDGE
	if _platform_covers(step):
		return want

	var foe: = opponent.global_position if is_instance_valid(opponent) else body.global_position
	if _platform_at(foe) != pad and _ai_gap_jump(want):
		return want
	var out: = Vector2(body.global_position.x - pad.global_position.x, 
		body.global_position.z - pad.global_position.z)
	if out.length() < 0.01:
		return Vector3.ZERO
	out = out.normalized()
	var tangent: = Vector2( - out.y, out.x)
	var along: = Vector2(want.x, want.z).normalized().dot(tangent)
	if absf(along) < 0.05:
		return Vector3.ZERO
	return Vector3(tangent.x, 0.0, tangent.y) * signf(along)





func _ai_gap_jump(want: Vector3) -> bool:

	if not can_jump() or not is_instance_valid(opponent):
		return false
	if not pad_hop_landing(want).is_finite():
		return false
	try_pad_hop(want)
	return true





func can_take_pad() -> bool:
	return pad and swimmer and locomotion == "ground" and surface() == Water.Surface.DEEP\
	and can_leap_out() and can_act() and root_t <= 0.0 and trap_t <= 0.0 and stamina > 0.0\
	and air_t <= 0.0 and land_t <= 0.0 and dash_t <= 0.0 and _lunge_t <= 0.0\
	and not _pad_leaping and not _leaping





const PAD_CLIMB_RIM: = 0.3
func try_pad_climb(dir: Vector3) -> bool:
	dir.y = 0.0
	if dir.length() < 0.01 or not can_take_pad() or Time.get_ticks_msec() < _pad_hop_ready_ms:
		return false
	var g: Node = body._game()
	if g == null:
		return false
	dir = dir.normalized()
	var here: = body.global_position
	for b in body.get_tree().get_nodes_in_group("water_platform"):
		if not is_instance_valid(b) or not b.has_method("covers") or not _pad_holds(b):
			continue
		var to: = Vector3(b.global_position.x - here.x, 0.0, b.global_position.z - here.z)
		var d: = to.length()
		if d < 0.01 or dir.dot(to / d) < PAD_HOP_CONE:
			continue
		var r: = _pad_radius(b, Vector2( - to.x, - to.z))
		if d - r > body_radius() + PAD_CLIMB_RIM:
			continue
		var land: Vector3 = b.global_position - (to / d) * maxf(r - PAD_HOP_INSET, 0.0)
		land.y = g.ground_y(land + Vector3.UP * 3.0, body.ground_y())
		_start_pad_hop_arc(land, to / d)
		return true
	return false




func start_climb_leap(to: Vector3, entering: = false) -> bool:
	if not to.is_finite() or not _can_launch_climb():
		return false
	_pad_leap_from = body.global_position
	_pad_leap_to = to
	_pad_leap_kind = "enter" if entering else "exit" if swimmer else "climb"
	var run: = Vector2(to.x - _pad_leap_from.x, to.z - _pad_leap_from.z).length()
	_pad_leap_total = clampf(0.3 + run * 0.06, 0.35, 0.6)
	if _pad_leap_kind == "climb":
		_pad_leap_total += 0.2
	_pad_leap_t = 0.0
	_pad_leaping = true
	_pad_leap_mask = body.collision_mask
	body.collision_mask = 0
	var dir: = Vector3(to.x - _pad_leap_from.x, 0.0, to.z - _pad_leap_from.z)
	if dir.length() > 0.05:
		body.facing = dir.normalized()
	if not entering:
		stamina = maxf(stamina - pp_max * JUMP_STAMINA, 0.0)
	body.squash = -0.18 if _pad_leap_kind == "climb" else JUMP_STRETCH
	if entering and surface() == Water.Surface.GROUND:
		body._vfx().turn_dust(body, 1.0, 0.9)

	return true



func _can_launch_climb() -> bool:
	return locomotion == "ground" and can_act() and root_t <= 0.0 and trap_t <= 0.0\
	and air_t <= 0.0 and land_t <= 0.0 and dash_t <= 0.0\
	and _lunge_t <= 0.0 and evade_t <= 0.0 and body.is_on_floor() and not _pad_leaping and not _leaping



func is_pad_leaping() -> bool:
	return _pad_leaping



func _tick_pad_leap(d: float) -> void :
	_pad_leap_t = minf(_pad_leap_t + d / _pad_leap_total, 1.0)
	var u: = _pad_leap_t
	var progress: = smoothstep(0.25, 1.0, u) if _pad_leap_kind == "climb" else u
	var pos: = _pad_leap_from.lerp(_pad_leap_to, progress)
	if _pad_leap_kind != "climb":
		var apex: = 0.22 if _pad_leap_kind == "enter" else PAD_HOP_ARC if _pad_leap_kind == "hop" else LEAP_OUT_H
		pos.y += apex * sin(PI * u)
	body.global_position = pos
	body.velocity = Vector3.ZERO
	if u >= 1.0:
		_pad_leaping = false
		body.collision_mask = _pad_leap_mask
		body.global_position = _pad_leap_to
		body.velocity = Vector3.ZERO
		overboard = false
		land_t = JUMP_LAND
		body.squash = JUMP_SQUASH
		if _pad_leap_kind == "enter":
			_water_entry_t = WATER_ENTRY_TIME
			root_t = maxf(root_t, 0.2)
		elif _pad_leap_kind == "climb":
			root_t = maxf(root_t, 0.18)
		elif _pad_leap_kind == "hop":
			land_t = PAD_HOP_LAND
			pad_hop = false
			_pad_hop_thump()
			_pad_hop_ready_ms = Time.get_ticks_msec() + int(PAD_HOP_REARM * 1000.0)
			Audio.play_at("sfx/world/land", body.global_position, -7.0)
		else:
			Audio.play_at("sfx/world/land", body.global_position, -7.0)



func water_entry_sink() -> float:
	if _water_entry_t <= 0.0:
		return 0.0
	var p: = 1.0 - _water_entry_t / WATER_ENTRY_TIME
	return smoothstep(0.0, 0.3, p) * (1.0 - smoothstep(0.55, 1.0, p))


func water_contact() -> bool:
	return surface() != Water.Surface.GROUND and not floats() and air_t <= 0.0\
	and not _pad_leaping and not _leaping and dash_hop_m() <= 0.001



func _try_shore_transition(want: Vector3) -> bool:
	if want.length_squared() < 0.0001 or not _can_launch_climb():
		return false
	var g: Node = body._game()
	var from: = surface()
	var dir: = want.normalized()
	var to: = body.global_position + dir * 0.7
	var dest: int = g.surface_at(to.x, to.z)
	var entering: = swimmer and from == Water.Surface.GROUND and dest == Water.Surface.DEEP
	var leaving: = from == Water.Surface.DEEP and dest == Water.Surface.GROUND
	if not entering and not leaving:
		return false
	if _platform_covers(to) or not water_ok(to.x, to.z):
		return false
	var inset: = to + dir * 0.35
	if g.surface_at(inset.x, inset.z) == dest and water_ok(inset.x, inset.z):
		to = inset
	to.y = g.ground_y(to + Vector3.UP * 3.0, body.ground_y())
	if absf(to.y - body.global_position.y) > 0.75:
		return false
	return start_climb_leap(to, entering)


func _in_range(id: String, d: float) -> bool:
	var mv: = Dex.move_for(id, body.species)
	if contact_out_of_reach(mv):
		return false
	match mv.get("kind", ""):
		"dash":
			return d < float(mv.get("range", 2.0)) + 0.6
		"arc", "multi_arc":
			return d < float(mv.get("range", 2.0)) + 0.1
		"whip":
			return d < Dex.whip_reach(body.species, mv) + 0.6
		"aoe_self", "debuff_aoe":
			return d < float(mv.get("radius", 3.0))
		"stream":
			return d < float(mv.get("range", 5.0))
		"self_buff", "clones":
			return true
		_:
			return d < float(mv.get("range", 10.0))


func dummy_logic() -> Vector3:
	if not is_instance_valid(opponent):
		return Vector3.ZERO
	var to_o: = opponent.global_position - body.global_position
	to_o.y = 0.0
	var d: = to_o.length()
	var dir: = to_o / maxf(d, 0.001)
	match dummy_style:
		1:
			return Vector3( - dir.z, 0.0, dir.x) * body._strafe
		2:
			if randf() < 0.01:
				body._strafe *= -1.0
			return dir * (0.8 if body._strafe > 0.0 else -0.8) if d > 2.0 or body._strafe < 0.0 else - dir * 0.8
	return Vector3.ZERO


func aim_dir() -> Vector3:
	if is_instance_valid(opponent):
		var d: = opponent.global_position - body.global_position
		d.y = 0.0
		if d.length() > 0.01:
			return d.normalized()
	return body.facing




func can_substitute() -> bool:
	return not is_instance_valid(substitute) and body.hp > maxi(1, body.max_hp / 4)\
	and evade_t <= 0.0 and dash_t <= 0.0 and air_t <= 0.0 and land_t <= 0.0\
	and not _leaping and not _pad_leaping and not is_instance_valid(binding)\
	and _evade_clear( - aim_dir(), EVADE_DISTANCE * Dex.dist_scale)



func substitute_backstep() -> void :
	evade_dir = - aim_dir()
	_evade_dist = EVADE_DISTANCE * Dex.dist_scale
	evade_t = EVADE_TOTAL
	_evade_motion_u = 0.0
	evade_invuln_t = EVADE_INVULN
	sprinting = true
	_evade_exhausted = false
	_evade_regen_t = EVADE_REGEN_HOLD
	_play_evade_anim()
	Audio.play_at("sfx/battle/dodge", body.global_position, -2.0, 1.0, true)


func can_evade() -> bool:
	return not is_instance_valid(binding) and can_act() and root_t <= 0.0 and evade_cd_t <= 0.0 and evade_t <= 0.0\
	and (trap_t <= 0.0 or ( not trap_zone.is_empty() and body.mode == Creature.Mode.PLAYER))\
	and dash_t <= 0.0 and _lunge_t <= 0.0 and air_t <= 0.0 and land_t <= 0.0\
	and not _leaping and not _pad_leaping



static func evade_progress(u: float) -> float:
	return clampf(u / EVADE_BURST, 0.0, 1.0)





func evade(want_dir: Vector3) -> bool:
	if not can_evade():
		return false
	var dir: = Vector3(want_dir.x, 0.0, want_dir.z)
	if dir.length() > 0.1:
		dir = dir.normalized()
	else:
		dir = _evade_auto_dir()
	if dir == Vector3.ZERO:
		return false
	if trap_t > 0.0:
		_break_trap()
	evade_dir = dir
	_evade_dist = EVADE_DISTANCE * Dex.dist_scale
	evade_t = EVADE_TOTAL
	_evade_motion_u = 0.0
	evade_invuln_t = clampf(EVADE_INVULN + EVADE_INVULN_STAT * evasion, EVADE_INVULN_MIN, EVADE_INVULN_MAX)
	sprinting = true
	stamina = minf(stamina - pp_max * EVADE_FATIGUE, pp_max)
	_evade_exhausted = stamina < 0.0
	_evade_regen_t = EVADE_REGEN_HOLD
	evade_cd_t = EVADE_COOLDOWN / recovery_factor()
	if gcd_t <= evade_cd_t:
		gcd_duration = EVADE_COOLDOWN
		gcd_t = evade_cd_t
	_play_evade_anim()


	var mine: = body.mode == Creature.Mode.PLAYER
	Audio.play_at("sfx/battle/dodge", body.global_position, -2.0 if mine else -7.0, 1.0 if mine else 0.85, true)
	return true






func teleport_blink() -> Vector3:
	if is_instance_valid(binding) or trap_t > 0.0 or evade_t > 0.0 or dash_t > 0.0 or _lunge_t > 0.0\
	or air_t > 0.0 or land_t > 0.0 or _leaping or _pad_leaping:
		return Vector3.INF
	var dir: = _evade_auto_dir(TELEPORT_DISTANCE)
	if dir == Vector3.ZERO:
		return Vector3.INF
	evade_dir = dir
	_evade_dist = TELEPORT_DISTANCE * Dex.dist_scale
	evade_t = EVADE_TOTAL
	_evade_motion_u = 0.0
	evade_invuln_t = clampf(EVADE_INVULN + EVADE_INVULN_STAT * evasion, EVADE_INVULN_MIN, EVADE_INVULN_MAX)
	sprinting = true
	stamina = minf(stamina - pp_max * TELEPORT_FATIGUE, pp_max)
	_evade_exhausted = stamina < 0.0
	_evade_regen_t = EVADE_REGEN_HOLD
	var mine: = body.mode == Creature.Mode.PLAYER
	Audio.play_at("sfx/battle/dodge", body.global_position, -2.0 if mine else -7.0, 1.4, true)
	return dir * TELEPORT_DISTANCE




func _evade_auto_dir(dist: = -1.0) -> Vector3:
	if dist < 0.0:
		dist = EVADE_DISTANCE * Dex.dist_scale
	var to_o: = - body.facing
	if is_instance_valid(opponent):
		to_o = opponent.global_position - body.global_position
	to_o.y = 0.0
	var base: = to_o.normalized() if to_o.length() > 0.01 else body.facing
	var side: = Vector3( - base.z, 0.0, base.x)
	var left_ok: = _evade_clear( - side, dist)
	var right_ok: = _evade_clear(side, dist)
	if left_ok and right_ok:
		return - side if randf() < 0.5 else side
	if left_ok:
		return - side
	return side if right_ok else Vector3.ZERO




func _evade_clear(dir: Vector3, dist: = EVADE_DISTANCE) -> bool:
	var to: = body.global_position + dir * (dist + 0.4)
	var r: = _arena()
	if r.size.x > 0.0 and not r.grow(-0.4).has_point(Vector2(to.x, to.z)):
		return false
	if not water_ok(to.x, to.z):
		return false
	var world: = body.get_world_3d()
	var space: = world.direct_space_state if world else null
	if space == null:
		return true
	var origin: = body.global_position + Vector3(0, 0.6, 0)
	var q: = PhysicsRayQueryParameters3D.create(origin, origin + dir * (dist + 0.4), BLOCK_LAYERS)
	q.exclude = _dynamic_rids()
	return space.intersect_ray(q).is_empty()





func whiff_stumble(dir: Vector3) -> void :
	_whiff_pending = true
	_whiff_dir = dir




func _play_evade_anim() -> void :
	var avail: Array = body.evade_anims() if body.has_method("evade_anims") else []
	if avail.size() > 1 and avail.has(_evade_last):
		avail.erase(_evade_last)
	if avail.is_empty():
		return
	var pick: = String(avail.pick_random())
	if body.play_evade_anim(pick):
		_evade_last = pick



func locomotion_speed_mult() -> float:
	return FLY_SPEED_MULT if is_flying() else 1.0




func terrain_speed_mult() -> float:
	if not walks():
		return 1.0
	if overboard:
		return Water.OVERBOARD_SPEED
	match surface():
		Water.Surface.DEEP:
			return Water.SWIM_SPEED if swimmer else 1.0
		Water.Surface.SHALLOW:
			return 1.0 if swimmer else Water.WADE_SPEED
		_:
			return Water.FISH_LAND_SPEED if fish else 1.0





func surface() -> int:
	var g: Node = body._game()
	if g == null:
		return Water.Surface.GROUND

	if body.has_method("on_water_platform") and body.on_water_platform():
		return Water.Surface.GROUND




	var pad: = _platform_at(body.global_position)
	if pad != null and not _leaping and not _pad_leaping:
		var top: = (pad as Node3D).global_position.y + float(pad.get("thickness") if pad.get("thickness") != null else 0.0) * 0.5
		var dy: float = body.global_position.y - top
		if dy > -0.15 and dy < PAD_STAND_GAP:
			return Water.Surface.GROUND
	return g.surface_at(body.global_position.x, body.global_position.z)




func is_underground() -> bool:
	return (underground or _dig_sink > 0.0) and dash_t > 0.0






func water_ok(x: float, z: float) -> bool:
	if not walks():
		return true


	if _platform_covers(Vector3(x, 0.0, z)):
		return true
	if overboard:
		return true
	var g: Node = body._game()
	if g == null:
		return true
	var s: int = g.surface_at(x, z)




	if fish and _in_fight() and surface() != Water.Surface.GROUND and s == Water.Surface.GROUND:
		return false
	if fish and body.is_wild and not _in_fight():
		return s != Water.Surface.GROUND\
		or Water.distance_to_beach(g.water_rects(), g.water_banks(), x, z) <= Water.FISH_LEASH
	if swimmer:
		return s != Water.Surface.GROUND or not body.is_wild or _in_fight()
	return s != Water.Surface.DEEP



func _in_fight() -> bool:
	var b: Node = body._battle()
	if b == null or not b.in_battle:
		return false
	return b.allies.has(body) or body == b.wild







func water_clamp(prev: Vector3) -> Vector3:
	var p: = body.global_position
	if water_ok(p.x, p.z):
		return p
	if _knock.length() >= Water.OVERBOARD_KNOCK:
		return p
	var a: = Vector3(p.x, p.y, prev.z)
	if water_ok(a.x, a.z):
		return a
	var b: = Vector3(prev.x, p.y, p.z)
	if water_ok(b.x, b.z):
		return b
	return Vector3(prev.x, p.y, prev.z)




func water_clamp_from(prev: Vector3, to: Vector3) -> Vector3:
	if water_ok(to.x, to.z):
		return to
	var a: = Vector3(to.x, to.y, prev.z)
	if water_ok(a.x, a.z):
		return a
	var b: = Vector3(prev.x, to.y, to.z)
	if water_ok(b.x, b.z):
		return b
	return prev



func drowns() -> bool:
	if swimmer:
		return false
	for t in types:
		if Water.DROWN_TYPES.has(t):
			return true
	return false






func update_water_state() -> void :

	if can_fly() and flight == Flight.GROUNDED and surface() == Water.Surface.DEEP\
	and body.is_on_floor() and can_take_flight():
		take_flight()
	if not walks() or can_fly() or swimmer or floats():
		overboard = false
		_set_wet(false)
		return



	if body.is_on_floor() and body.get_slide_collision_count() == 0:
		return
	var s: = surface()
	_set_wet(s != Water.Surface.GROUND)
	if s != Water.Surface.DEEP:
		overboard = false
		return
	overboard = true



var wet: = false


func _set_wet(w: bool) -> void :
	if wet == w:
		return
	wet = w
	body.refresh_label()





func _tick_water(delta: float) -> void :
	if not overboard:
		_drown_t = 0.0
		return
	if not drowns() or Battle.tut_soft_hits:
		return
	_drown_t += delta
	if _drown_t < Water.DROWN_TICK:
		return
	_drown_t -= Water.DROWN_TICK
	_water_tick()




func _water_tick() -> void :
	var amount: = maxi(1, int(body.max_hp / Water.DROWN_FRACTION))
	Audio.play_at("sfx/world/splash_in", body.global_position, -5.0)
	body._water_splash(1.6)
	body._vfx().popup(body.head_pos(0.9), "-%d drowning" % amount, Dex.type_color("water"))
	body.take_damage(amount, Vector3.ZERO, 0.0, {"kind": "drowning"})




func climb_target() -> Vector3:
	if not overboard:
		return Vector3.INF
	var g: Node = body._game()
	if g == null:
		return Vector3.INF
	var here: = Vector2(body.global_position.x, body.global_position.z)
	var best: = Vector3.INF
	var best_d: = INF
	var ground: = Water.nearest_ground(g.water_rects(), here.x, here.y)
	if ground.is_finite() and g.surface_at(ground.x, ground.y) == Water.Surface.GROUND:
		var gy: float = g.ground_y(Vector3(ground.x, body.global_position.y + 3.0, ground.y), body.global_position.y)
		var p: = Vector3(ground.x, gy, ground.y)
		best = p
		best_d = Vector2(p.x - here.x, p.z - here.y).length()
	for b in body.get_tree().get_nodes_in_group("water_platform"):
		if not is_instance_valid(b) or not b.has_method("covers") or not _pad_holds(b):
			continue
		var c: = Vector2(b.global_position.x, b.global_position.z)
		var out: = here - c
		if out.length() < 0.05:
			out = Vector2(1.0, 0.0)
		out = out.normalized()
		var rim: = c + out * _pad_radius(b, out)
		var p: = Vector3(rim.x, b.global_position.y + 0.45, rim.y)
		var d: = Vector2(p.x - here.x, p.z - here.y).length()
		if d < best_d:
			best_d = d
			best = p
	return best



func _toward_climb() -> Vector3:
	var target: = climb_target()
	if not target.is_finite():
		return Vector3.ZERO
	var v: = Vector3(target.x - body.global_position.x, 0.0, target.z - body.global_position.z)
	return v.normalized() if v.length() > 0.2 else Vector3.ZERO




func _try_climb() -> void :
	if not overboard or _pad_leaping or _leaping or body.mode == Creature.Mode.FAINTED:
		return

	if body.has_method("on_sunk_pad") and body.on_sunk_pad():
		return
	var target: = climb_target()
	if not target.is_finite():
		return
	var d: = Vector2(target.x - body.global_position.x, target.z - body.global_position.z).length()
	if d <= Water.CLIMB_REACH:
		start_climb_leap(target)



func clamp_to_water(p: Vector3) -> Vector3:
	var g: Node = body._game()
	if g == null:
		return p
	var t: = Water.nearest_point(g.water_rects(), p.x, p.z)
	if not t.is_finite():
		return p
	return Vector3(t.x, p.y, t.y)




func _water_retreat() -> Vector3:
	if locomotion != "ground":
		return Vector3.ZERO
	if overboard:
		return _toward_climb()
	var s: = surface()
	if fish and s == Water.Surface.GROUND:
		return _toward_water(false)
	if swimmer and not fish and s != Water.Surface.DEEP\
	and body.max_hp > 0 and float(body.hp) <= float(body.max_hp) * AI_LOW_HP:
		return _toward_water(true)
	return Vector3.ZERO



func _toward_water(deep: bool) -> Vector3:
	var g: Node = body._game()
	if g == null:
		return Vector3.ZERO
	var p: = Vector2(body.global_position.x, body.global_position.z)
	var target: Vector2 = Water.nearest_point(g.water_rects(), p.x, p.y, deep)
	if not target.is_finite():
		return Vector3.ZERO
	var v: = Vector3(target.x - p.x, 0.0, target.y - p.y)
	return v.normalized() if v.length() > 0.2 else Vector3.ZERO



func airborne_min() -> float:
	return maxf(AIRBORNE_FLOOR, jump_height * AIRBORNE_FRACTION)



func can_fly() -> bool:
	return locomotion == "fly"



func is_flying() -> bool:
	return can_fly() and flight == Flight.AIRBORNE and body.mode != Creature.Mode.FAINTED


func is_hovering() -> bool:
	return locomotion == "hover"




func walks() -> bool:
	return locomotion == "ground" or (can_fly() and flight == Flight.GROUNDED)




func floats() -> bool:
	return body.mode != Creature.Mode.FAINTED and (is_hovering() or flight != Flight.GROUNDED)




func hover_height() -> float:
	if body == null:
		return HOVER_HEIGHT
	var k: = _cast_k()
	return clampf(body.look_height() * HOVER_SCALE, HOVER_MIN * k, HOVER_MAX * k)


func _cast_k() -> float:
	var k = body.get("cast_scale") if body != null else null
	return float(k) if k != null else 1.0







func float_target_height() -> float:
	if is_flying():
		if alt_override_t > 0.0:
			return alt_override
		if dash_t > 0.0 or _lunge_t > 0.0:
			return SWOOP_HEIGHT * _cast_k()
		return fly_height
	if flight == Flight.LANDING:
		return 0.0
	return hover_height()



func lift_for(to: float, secs: float) -> void :
	alt_override = to
	alt_override_t = maxf(secs, 0.0)



func hold_altitude(delta: float) -> void :
	var bsp: = move_speed()
	var d: = delta * bsp
	alt_override_t = maxf(alt_override_t - d, 0.0)
	var target: = body.ground_y() + float_target_height()
	body.velocity.y = clampf((target - body.global_position.y) * ALT_SPRING, - ALT_MAX_VY, ALT_MAX_VY) * bsp
	air_h = maxf(body.global_position.y - body.ground_y(), 0.0)


	if flight == Flight.LANDING and body.global_position.y <= body.ground_y() + 0.03:
		_touch_down()




func is_airborne() -> bool:
	if floats():
		return true
	return air_t > 0.0 and air_h > airborne_min()



static func jump_time_for(h: float) -> float:
	return sqrt(8.0 * h / JUMP_G) if h > 0.0 else 0.0



func jump_vy() -> float:
	return sqrt(2.0 * JUMP_G * jump_height)





func start_slam_jump(apex: = 1.7, speed: = 1.5) -> bool:
	if not _can_launch_jump():
		return false
	jump_boost = sqrt(maxf(apex, 1.0))
	jump_speed = maxf(speed, 0.1)
	air_t = jump_time * jump_boost / jump_speed
	air_h = 0.0
	stamina = maxf(stamina - pp_max * JUMP_STAMINA, 0.0)
	body.squash = JUMP_STRETCH
	body._vfx().burst(body.global_position + Vector3(0, 0.05, 0), JUMP_DUST, 6, 0.3, 1.4, 0.12, 180.0, Vector3.UP, Vector3(0, -2.5, 0))
	Audio.play_at("sfx/world/jump", body.global_position, -6.0)
	return true



func _pad_hop_thump() -> void :
	var w: = clampf(weight_kg / 40.0, 0.4, 1.6)
	body.squash = JUMP_SQUASH * (1.0 + w)
	body._vfx().burst(body.global_position + Vector3(0, 0.05, 0), Color(0.8, 0.93, 1.0), int(10 + 10 * w), 0.45, 2.4 * w, 0.14, 200.0, Vector3.UP, Vector3(0, -3, 0))
	var rig: Node = body.get_tree().get_first_node_in_group("camera_rig")
	if rig != null and rig.has_method("shake"):
		rig.shake(0.05 * w)





func try_pad_hop(dir: Vector3) -> bool:
	dir.y = 0.0
	if dir.length() < 0.01 or not can_jump() or _pad_leaping or _leaping\
	or Time.get_ticks_msec() < _pad_hop_ready_ms or surface() != Water.Surface.GROUND:
		return false
	var g: Node = body._game()
	if g == null:
		return false
	dir = dir.normalized()
	var rim: = body.global_position + dir * PAD_HOP_RIM
	if _platform_covers(rim) or g.surface_at(rim.x, rim.z) != Water.Surface.DEEP:
		return false
	var to: = pad_hop_landing(dir)
	if not to.is_finite():
		return false
	_start_pad_hop_arc(to, dir)
	return true





func pad_hop_landing(dir: Vector3) -> Vector3:
	var g: Node = body._game()
	if g == null:
		return Vector3.INF
	dir = Vector3(dir.x, 0.0, dir.z).normalized()
	var here: = body.global_position
	var on: = _platform_at(here)
	var best: = Vector3.INF
	var best_d: = INF
	for b in body.get_tree().get_nodes_in_group("water_platform"):
		if not is_instance_valid(b) or not b.has_method("covers") or b == on:
			continue
		var to: = Vector3(b.global_position.x - here.x, 0.0, b.global_position.z - here.z)
		var d: = to.length()
		if d < 0.01 or d >= best_d or dir.dot(to / d) < PAD_HOP_CONE:
			continue
		var r: = _pad_radius(b, Vector2( - to.x, - to.z))
		if d - r - PAD_HOP_RIM > PAD_HOP_GAP:
			continue
		var land: Vector3 = b.global_position - (to / d) * maxf(r - PAD_HOP_INSET, 0.0)
		land.y = g.ground_y(land + Vector3.UP * 3.0, body.ground_y())
		best = land
		best_d = d
	if best.is_finite():
		return best
	var rim: = here + dir * PAD_HOP_RIM
	var step: = 0.1
	while step <= PAD_HOP_GAP + 0.05:
		var p: = rim + dir * step
		if g.surface_at(p.x, p.z) != Water.Surface.DEEP and not _platform_covers(p):
			var land: = p + dir * PAD_HOP_INSET
			if g.surface_at(land.x, land.z) == Water.Surface.DEEP:
				return Vector3.INF
			land.y = g.ground_y(land + Vector3.UP * 3.0, body.ground_y())
			if absf(land.y - here.y) > 0.75:
				return Vector3.INF
			return land
		step += 0.1
	return Vector3.INF


func _start_pad_hop_arc(to: Vector3, dir: Vector3) -> void :
	_pad_leap_from = body.global_position
	_pad_leap_to = to
	_pad_leap_kind = "hop"
	var run: = Vector2(to.x - _pad_leap_from.x, to.z - _pad_leap_from.z).length()
	_pad_leap_total = clampf(0.32 + run * 0.07, 0.35, 0.65)
	_pad_leap_t = 0.0
	_pad_leaping = true
	_pad_leap_mask = body.collision_mask
	body.collision_mask = 0
	body.facing = dir
	pad_hop = true
	stamina = maxf(stamina - pp_max * JUMP_STAMINA, 0.0)
	body.squash = JUMP_STRETCH
	Audio.play_at("sfx/world/jump", body.global_position, -6.0)



func pad_hop_dodging() -> bool:
	if _pad_leaping and _pad_leap_kind == "hop":
		return _pad_leap_t >= PAD_HOP_DODGE.x and _pad_leap_t <= PAD_HOP_DODGE.y
	if not pad_hop or air_t <= 0.0:
		return false
	var total: = jump_time * jump_boost / jump_speed
	var u: = 1.0 - air_t / maxf(total, 0.001)
	return u >= PAD_HOP_DODGE.x and u <= PAD_HOP_DODGE.y



func slam_air_time(apex: = 1.7, speed: = 1.5) -> float:
	return jump_time * sqrt(maxf(apex, 1.0)) / maxf(speed, 0.1) if _can_launch_jump() else 0.0




func dash_reach() -> float:
	return body.look_height() * DASH_REACH_FACTOR












func _flat_dist(t: Node) -> float:
	var d: Vector3 = t.global_position - body.global_position
	return Vector2(d.x, d.z).length()


func passes_under(t: Node) -> bool:
	if t.combat.is_underground():
		return true


	if t.combat.is_hovering():
		return false
	if bool(cast_move.get("reach_air", false)):
		return false
	return t.is_airborne() and (t.combat.air_h - air_h) >= dash_reach()






func hop_to_reach(t: Node) -> void :
	if not is_instance_valid(t) or not t.combat.is_airborne() or not passes_under(t):
		return
	if not can_jump():
		return
	if t.combat.air_h - jump_height >= dash_reach():
		return
	start_jump()




func dodge_tell(t: Node, id: = "") -> void :
	body._moves().dodge_tell(t, id)




func _may_jump_here() -> bool:
	if overboard:
		return false
	var s: = surface()
	if s == Water.Surface.DEEP:


		return not swimmer or can_leap_out()
	if s == Water.Surface.SHALLOW:
		return swimmer
	return not fish





const LEAP_REACH: = 1.5
func can_leap_out() -> bool:
	if not swimmer or surface() != Water.Surface.DEEP or not body.is_on_floor():
		return false
	for b in body.get_tree().get_nodes_in_group("water_platform"):
		if is_instance_valid(b) and b.has_method("covers") and _pad_holds(b)\
		and b.covers(body.global_position.x, body.global_position.z, LEAP_REACH):
			return true

	var g: Node = body._game()
	if g == null:
		return false
	var dry: = Water.nearest_ground(g.water_rects(), body.global_position.x, body.global_position.z)
	return dry.is_finite() and Vector2(dry.x - body.global_position.x, 
		dry.y - body.global_position.z).length() <= LEAP_REACH






func should_water_leap() -> bool:
	if not swimmer or surface() != Water.Surface.DEEP:
		return false
	if not is_instance_valid(opponent):
		return false
	return opponent.combat.surface() != Water.Surface.DEEP


func is_leaping() -> bool:
	return _leaping



const LAND_SWIMMER_PENALTY: = 0.8
func terrain_damage_mult() -> float:
	return _type_bonus_mult() * _swim_terrain_mult()



const GYM_TYPE_BONUS: = 1.25
func _type_bonus_mult() -> float:
	var g: Node = body._battle()
	if g == null or not g.in_battle:
		return 1.0
	var bt = g.get("type_bonus")
	return gym_type_bonus(types, bt if bt != null else [])



static func gym_type_bonus(mon_types: Array, bonus_types: Array) -> float:
	for t in mon_types:
		if t in bonus_types:
			return GYM_TYPE_BONUS
	return 1.0


func _swim_terrain_mult() -> float:
	if not swimmer:
		return 1.0
	if _leaping:
		return _leap_mult


	match surface():
		Water.Surface.DEEP:
			return 1.0
		Water.Surface.SHALLOW:
			return 1.0
		_:
			return LAND_SWIMMER_PENALTY




func start_water_leap(mv: Dictionary, target: Node, dir: Vector3) -> void :





	_leap_mv = mv
	_leap_target = target
	var base_y: = body.ground_y()
	_leap_from = Vector3(body.global_position.x, base_y, body.global_position.z)
	var foe: Vector3 = target.global_position if is_instance_valid(target) else body.global_position + dir * 2.0
	_leap_mult = terrain_damage_mult()
	_sa = StyleA.params(mv, body.species)
	if String(mv.get("id", "")) in ["flail", "reversal"]:
		_sa["leap_spin"] = float(Flail.turns(Flail.power(int(body.hp), int(body.max_hp))))
	_leap_mask = body.collision_mask
	body.collision_mask = 0
	var to_foe: = Vector2(foe.x - _leap_from.x, foe.z - _leap_from.z)
	var dist: = to_foe.length()
	var u2: = to_foe / maxf(dist, 0.001) if dist > 0.001 else Vector2(dir.x, dir.z).normalized()
	var reach: = reach_to(target) if is_instance_valid(target) else 0.0
	var leap_len: = water_leap_len()
	_leap_hit_possible = is_instance_valid(target) and dist - reach <= leap_len + 0.05

	var apex_dist: = clampf(dist - reach * 0.5, 0.0, leap_len)
	_leap_hit_apex = Vector3(_leap_from.x + u2.x * apex_dist, base_y, _leap_from.z + u2.y * apex_dist)
	_leap_hit_land = _water_beyond(_leap_from, foe, leap_len)


	var foe_pad: = _platform_at(foe) if is_instance_valid(target) else null
	if foe_pad != null:
		var g: Node = body._game()
		var far: Vector3 = foe_pad.global_position + Vector3(u2.x, 0.0, u2.y) * (_pad_radius(foe_pad, u2) + 0.7)
		if g != null and not _platform_covers(far) and g.surface_at(far.x, far.z) != Water.Surface.GROUND:
			_leap_hit_land = Vector3(far.x, base_y, far.z)
	if _leap_hit_land == _leap_from and is_instance_valid(target):
		var near_w: = _nearest_open_water(foe)
		if near_w.is_finite():
			_leap_hit_land = Vector3(near_w.x, base_y, near_w.z)
	_leap_miss_land = _leap_miss_point(u2, maxf(leap_len, apex_dist + 0.6), base_y)


	var gnd: Node = body._game()
	var top: = base_y
	if gnd != null and is_instance_valid(target):
		top = maxf(top, target.global_position.y)
	_leap_h = WATER_LEAP_H + (top - base_y)
	_leap_v = maxf(float(_dash_run.get("v", 0.0)), 0.5) if not _dash_run.is_empty()\
	else DashRun.BASE_RUN * DashRun.DEFAULT_RUN * _dash_speed_factor() * Dex.dist_scale
	_leap_aim(_leap_hit_possible)
	_leap_u = 0.0
	_leap_hold = 0.0
	_leap_hit = false
	_leaping = true
	body.facing = dir
	body.squash = JUMP_STRETCH





func _water_dash_leap_due() -> bool:
	if not is_instance_valid(opponent) or surface() != Water.Surface.DEEP:
		return true
	if _water_dash_rem() <= water_leap_len():
		return true

	var g: Node = body._game()
	var ahead: = body.global_position + dash_dir * (body.body_radius() + 0.1)
	return _platform_covers(ahead) or (g != null and g.surface_at(ahead.x, ahead.z) == Water.Surface.GROUND)





func contact_out_of_reach(mv: Dictionary) -> bool:
	if String(mv.get("kind", "")) not in ["dash", "multi_arc"] or swimmer or floats():
		return false
	if not is_instance_valid(opponent) or opponent.combat.floats() or opponent.combat.air_t > 0.0:
		return false
	return opponent.combat.surface() == Water.Surface.DEEP and not opponent.on_water_platform()



func _water_dash_rem() -> float:
	if not is_instance_valid(opponent):
		return INF
	var to: = opponent.global_position - body.global_position
	to.y = 0.0
	return to.length() - reach_to(opponent)



func water_leap_len() -> float:
	return WATER_LEAP_LUNGES * DashRun.DEFAULT_LUNGE * Dex.dist_scale




func begin_water_dash(mv: Dictionary, dir: Vector3, miss: Node = null) -> void :
	start_dash(mv, dir, miss)
	_dash_water = true
	_dash_running = dash_miss == null
	_dash_budget = maxf(dash_range - water_leap_len(), 0.0)




func _water_dash_leap() -> void :
	_dash_water = false
	_dash_running = false
	_dash_lunge_u = -1.0
	_dash_coast = 0.0
	_dash_coasting = false
	_dash_fx_done = true
	dash_t = 0.0
	body.velocity.x = 0.0
	body.velocity.z = 0.0
	if _water_dash_rem() > water_leap_len() + 0.05:
		_water_dash_fail()
		return


	_leap_charge_t = WATER_LEAP_TELL

	body.squash = JUMP_SQUASH
	body._vfx().turn_dust(body, 1.0, 0.9, true)




func _tick_leap_tell(d: float) -> void :
	body.velocity = Vector3.ZERO
	_leap_charge_t -= d
	if _leap_charge_t > 0.0:
		return
	_leap_charge_t = 0.0
	if not is_instance_valid(opponent):
		return
	var dir: = dash_dir
	var to: = opponent.global_position - body.global_position
	to.y = 0.0
	if to.length() > 0.01:
		dir = to.normalized()
	body._vfx().water_splash(body, false, 0.7, 0.9)
	start_water_leap(dash_move, opponent, dir)



func water_leap_busy() -> bool:
	return _leaping or _leap_charge_t > 0.0



func _water_dash_fail() -> void :
	var id: = String(dash_move.get("id", ""))
	var mv: = Dex.move(id)
	if not mv.is_empty():
		body.pp_max = body.pp_max + Dex.pp_cost(mv)
		body.stamina = minf(body.stamina + Dex.fatigue(mv), body.pp_max)
		if body.mon:
			body.mon.pp = body.pp_max
	move_cd.erase(id)
	gcd_t = 0.0
	evade_cd_t = 0.0
	reset_move_cooldown()
	body._vfx().popup(body.global_position + Vector3(0, 0.8, 0), "Out of reach!", Color(0.75, 0.88, 1.0), 1.0, "status")





func _leap_aim(hit: bool) -> void :
	if hit:
		_leap_apex = _leap_hit_apex
		_leap_land = _leap_hit_land
	else:
		_leap_apex = _leap_from.lerp(_leap_miss_land, 0.5)
		_leap_apex.y = _leap_from.y
		_leap_land = _leap_miss_land
	var l1: = Vector2(_leap_from.x - _leap_apex.x, _leap_from.z - _leap_apex.z).length()
	var l2: = Vector2(_leap_apex.x - _leap_land.x, _leap_apex.z - _leap_land.z).length()
	var spd: = _leap_v * WATER_LEAP_SPEED
	var t1: = maxf(l1 / spd, 0.08)
	var t2: = maxf(l2 / spd, 0.08)
	_leap_total = t1 + t2
	_leap_f1 = t1 / _leap_total



func _leap_carry_on() -> void :
	var t1: = _leap_f1 * _leap_total
	_leap_land = _leap_miss_land
	var l2: = Vector2(_leap_apex.x - _leap_land.x, _leap_apex.z - _leap_land.z).length()
	var t2: = maxf(l2 / (_leap_v * WATER_LEAP_SPEED), 0.08)
	_leap_total = t1 + t2
	_leap_f1 = t1 / _leap_total
	_leap_u = _leap_f1




func _leap_miss_point(dir2: Vector2, length: float, base_y: float) -> Vector3:
	var p: = Vector3(_leap_from.x + dir2.x * length, base_y, _leap_from.z + dir2.y * length)
	var r: = _arena()
	if r.size.x > 0.0:
		var inner: = r.grow(-0.5)
		p.x = clampf(p.x, inner.position.x, inner.end.x)
		p.z = clampf(p.z, inner.position.y, inner.end.y)
	var g: Node = body._game()
	if g != null and g.surface_at(p.x, p.z) == Water.Surface.GROUND:
		p.y = g.ground_y(p + Vector3.UP * 3.0, base_y)
	return p





func _water_beyond(from: Vector3, foe: Vector3, reach: float) -> Vector3:
	var dir: = Vector3(foe.x - from.x, 0.0, foe.z - from.z)
	if dir.length() < 0.01:
		return from
	dir = dir.normalized()
	var g: Node = body._game()
	var shallow: = Vector3.INF
	var d: = 0.0
	while d <= reach:
		d += 0.2
		var p: = Vector3(foe.x + dir.x * d, from.y, foe.z + dir.z * d)
		if _platform_covers(p):
			continue
		var s: int = g.surface_at(p.x, p.z)
		if s == Water.Surface.DEEP:
			return p
		if s == Water.Surface.SHALLOW and shallow == Vector3.INF:
			shallow = p
	return shallow if shallow != Vector3.INF else from


func _platform_covers(p: Vector3) -> bool:
	for b in body.get_tree().get_nodes_in_group("water_platform"):
		if is_instance_valid(b) and b.has_method("covers") and b.covers(p.x, p.z, 0.1):
			return true
	return false



func _tick_leap(delta: float) -> void :
	if not _leaping:
		return
	if _leap_hold > 0.0:
		_leap_hold -= delta
		_apply_leap(_leap_u)
		return
	_leap_u = minf(_leap_u + delta / _leap_total, 1.0)
	_apply_leap(_leap_u)
	if not _leap_hit and _leap_u >= _leap_f1:
		_leap_hit = true
		var landed: = false
		if _leap_hit_possible and is_instance_valid(_leap_target) and _leap_target.alive():


			landed = body._moves().hit(body, _leap_target, _leap_mv, body.facing)
		if not landed and _leap_land != _leap_miss_land:


			_leap_carry_on()
		return
	if _leap_u >= 1.0:
		_leaping = false
		body.global_position = _leap_land
		body.velocity = Vector3.ZERO
		body.collision_mask = _leap_mask
		body.squash = JUMP_SQUASH


func _apply_leap(u: float) -> void :
	var pos: Vector3
	if u <= _leap_f1:
		var t: = u / maxf(_leap_f1, 0.001)
		pos = _leap_from.lerp(_leap_apex, t)
		pos.y = _leap_from.y + _leap_h * sin(PI * 0.5 * t)
	else:
		var t: = (u - _leap_f1) / maxf(1.0 - _leap_f1, 0.001)
		pos = _leap_apex.lerp(_leap_land, t)
		pos.y = _leap_from.y + _leap_h * cos(PI * 0.5 * t)
	body.global_position = pos
	body.velocity = Vector3.ZERO





func can_jump() -> bool:
	return not is_instance_valid(binding) and root_t <= 0.0 and _can_launch_jump()




func _can_launch_jump() -> bool:
	return walks() and jump_height > 0.0 and weight_kg <= JUMP_MAX_KG and can_act()\
	and trap_t <= 0.0 and stamina > 0.0 and air_t <= 0.0 and dash_t <= 0.0\
	and _lunge_t <= 0.0 and _may_jump_here()





func jump_verb() -> String:
	if is_flying():
		return "Land"
	if can_fly():
		return "Fly"
	return ""




func jump_ready() -> bool:
	match jump_verb():
		"Land":
			return true
		"Fly":
			return can_take_flight()
	return false






func may_start(mv: Dictionary) -> bool:



	if floats():
		return true
	return not is_airborne() or bool(mv.get("allowed_midair", true))



func start_jump() -> bool:
	if not can_jump():
		return false
	if body.on_water_platform():
		var aim: Vector3 = body.facing
		if is_instance_valid(opponent):
			aim = opponent.global_position - body.global_position
		return try_pad_hop(aim)
	jump_boost = 1.0
	jump_speed = 1.0
	air_t = jump_time
	air_h = 0.0
	stamina = maxf(stamina - pp_max * JUMP_STAMINA, 0.0)
	body.squash = JUMP_STRETCH
	body._vfx().burst(body.global_position + Vector3(0, 0.05, 0), JUMP_DUST, 6, 0.3, 1.4, 0.12, 180.0, Vector3.UP, Vector3(0, -2.5, 0))
	Audio.play_at("sfx/world/jump", body.global_position, -7.0)
	return true




func can_take_flight() -> bool:
	return not is_instance_valid(binding) and can_fly() and flight == Flight.GROUNDED and can_act()\
	and root_t <= 0.0 and trap_t <= 0.0 and land_t <= 0.0 and air_t <= 0.0\
	and dash_t <= 0.0 and _lunge_t <= 0.0 and fly_pp > fly_pp_base * FLIGHT_MIN



func take_flight() -> bool:
	if not can_take_flight():
		return false
	flight = Flight.AIRBORNE
	flight_t = 0.0
	fly_pp = maxf(fly_pp - fly_pp_base * FLIGHT_TAKEOFF, 0.0)
	body.squash = JUMP_STRETCH
	body._vfx().burst(body.global_position + Vector3(0, 0.05, 0), JUMP_DUST, 6, 0.3, 1.4, 0.12, 180.0, Vector3.UP, Vector3(0, -2.5, 0))
	return true





func begin_landing() -> void :
	if flight == Flight.AIRBORNE and surface() == Water.Surface.GROUND:
		flight = Flight.LANDING



func _touch_down() -> void :
	flight = Flight.GROUNDED
	flight_t = 0.0
	land_t = FLIGHT_LAND
	body.squash = JUMP_SQUASH
	body._vfx().burst(body.global_position + Vector3(0, 0.05, 0), JUMP_DUST, 9, 0.4, 2.0, 0.14, 180.0, Vector3.UP, Vector3(0, -3, 0))
	Audio.play_at("sfx/world/land", body.global_position, -7.0)







func read_local_intent() -> Dictionary:
	var lock: = Battle.tut_locked
	var slot: = -1




	if not lock and (Input.is_action_just_pressed("loadout_prev") or Input.is_action_just_pressed("loadout_next")):
		Battle.request_loadout_swap(body)
	for k in 4:
		if lock and k != Battle.tut_move:
			continue
		if not Input.is_action_just_pressed("move_%d" % (k + 1)):
			continue
		if Controls.items_page_held():
			Progression.use_quick_item(k)
		elif k < moves.size():
			slot = k
			break
	return {
		"move": Input.get_vector("move_left", "move_right", "move_up", "move_down"), 
		"evade": Input.is_action_just_pressed("sprint"), 
		"sprint": Input.is_action_pressed("sprint"), 
		"jump": Input.is_action_just_pressed("jump"), 
		"slot": slot, 
	}






func apply_intent(it: Dictionary) -> Vector3:
	var lock: = Battle.tut_locked


	if not lock and bool(it.get("jump", false)):
		var jumped: = false
		if is_flying():
			begin_landing()
			jumped = true
		elif can_fly():
			jumped = take_flight()
		if jumped:
			Battle.note_jump(body)
	var i: Vector2 = it.get("move", Vector2.ZERO)
	if lock and not Battle.tut_walk:
		i = Vector2.ZERO


	var w: = i if bool(it.get("world", false)) else _world_dir(i)
	var step: = Vector3(w.x, 0.0, w.y)


	var pressed: = bool(it.get("evade", false))
	if not it.has("evade"):
		pressed = bool(it.get("sprint", false)) and not _intent_sprint_was
		_intent_sprint_was = bool(it.get("sprint", false))
	if not lock and pressed:
		evade(step)
	if evade_t > 0.0 and _evade_motion_u < EVADE_BURST:
		step = evade_dir
	sprinting = evade_t > 0.0
	var slot: = int(it.get("slot", -1))
	if slot >= 0 and slot < mini(moves.size(), 4) and ( not lock or slot == Battle.tut_move):
		selected_move = String(moves[slot])
		if can_act():
			if selected_move != "" and out_of_pp():
				if gcd_t > 0.0:
					Audio.ui("sfx/ui/error")
				else:
					struggle()
			elif selected_move != "":
				body._moves().use(body, selected_move, true)
	return _player_pad_hop(step)





func _world_dir(i: Vector2) -> Vector2:
	if body == null or body.get_tree() == null:
		return i
	var rig: Node = body.get_tree().get_first_node_in_group("camera_rig")
	return stick_to_world(i, float(rig._yaw_off) if rig != null else 0.0)






static func stick_to_world(i: Vector2, yaw_deg: float) -> Vector2:
	return i.rotated( - deg_to_rad(yaw_deg)) if yaw_deg != 0.0 else i


func player_input(delta: = 1.0 / 60.0) -> Vector3:
	var it: = read_local_intent()
	if defiant_t > 0.0:
		it = defiant_intent(it, delta)
	return apply_intent(it)





var defiant_t: = 0.0
var _obey_t: = 0.0
var _defy_dir: = Vector2.ZERO
var _defy_turn_t: = 0.0




func _obedience_applies() -> bool:
	var b: Node = body._battle()
	return b != null and b.in_battle and not b.training and not b.online and not b.challenge\
	and not b.is_spar() and body.mon != null and body.mode == Creature.Mode.PLAYER



func rebel_gap() -> int:
	return TrainerLevel.rebel_gap(int(body.mon.level), Game.state.trainer_level(), int(body.mon.friend))





func obedience_tick(delta: float) -> void :
	if not _obedience_applies():
		defiant_t = 0.0
		_obey_t = 0.0
		return
	if defiant_t > 0.0:
		defiant_t = maxf(defiant_t - delta, 0.0)
		if defiant_t == 0.0:
			_obey_t = TrainerLevel.check_seconds()
		return
	var gap: = rebel_gap()
	if gap <= 0:
		_obey_t = TrainerLevel.check_seconds()
		return
	_obey_t -= delta
	if _obey_t > 0.0:
		return
	_obey_t = TrainerLevel.check_seconds()
	if randf() < TrainerLevel.defy_chance(gap):
		defiant_t = TrainerLevel.defy_seconds()
		_defy_turn_t = 0.0
		body._vfx().popup(body.head_pos(1.1), "%s ignores you!" % String(body.mon.display_name), 
			Color("fca5a5"), 0.9, "info")
		body._vfx().shake(0.12, 0.2)



func defiant_intent(it: Dictionary, delta: = 1.0 / 60.0) -> Dictionary:
	_defy_turn_t -= delta
	if _defy_turn_t <= 0.0:
		_defy_turn_t = randf_range(0.8, 1.6)
		_defy_dir = Vector2.from_angle(randf() * TAU)
	var out: = it.duplicate()
	out["move"] = _defy_dir * 0.6
	out["evade"] = false
	out["sprint"] = false
	out["jump"] = false
	out["slot"] = -1
	return out






func _player_pad_hop(step: Vector3) -> Vector3:
	if step.length() < 0.01 or not walks() or floats()\
	or air_t > 0.0 or land_t > 0.0 or _pad_leaping or _leaping:
		return step

	if body.has_method("on_sunk_pad") and body.on_sunk_pad():
		return step
	var g: Node = body._game()
	if g == null:
		return step
	var dir: = step.normalized()
	if surface() == Water.Surface.GROUND:
		if swimmer:
			return step


		try_pad_hop(dir)
	elif pad and swimmer and surface() == Water.Surface.DEEP:
		try_pad_climb(dir)
	return step



const DIG_UNDER_T: = 0.8
const DIG_LOCK_T: = 0.25


const DIG_SINK_T: = 0.4
const DIG_RISE_T: = 0.35


func start_dash(mv: Dictionary, dir: Vector3, miss: Node = null) -> void :
	_finish_ace()
	_dash_water = false
	dash_move = mv
	dash_miss = miss
	dash_dir = dir
	_dash_hit = false
	dash_power_scale = 1.0
	dash_slow = 1.0
	_dash_fist = false
	_dash_fx_done = false
	_dash_dodged.clear()
	_whiff_pending = false
	_dash_saw_evade = false
	_sa = StyleA.params(mv, body.species)
	if String(mv.get("id", "")) in ["flail", "reversal"]:
		_sa["spin_turns"] = float(Flail.turns(Flail.power(int(body.hp), int(body.max_hp))))


	_dash_style_a = String(mv.get("id", "")) != "dig"
	dash_range = float(mv.get("range", 3.0))




	dash_plan = dash_range
	if _dash_style_a and is_instance_valid(opponent) and miss == null:
		var to_t: = opponent.global_position - body.global_position
		to_t.y = 0.0
		dash_plan = clampf(to_t.length() - reach_to(opponent), 0.2, dash_range)

	var bw: = border_width()
	if bw > 0.0 and body.mode == Creature.Mode.BATTLE_AI:
		var g: Node = body._battle()
		if g != null and g.arena_rect.size.x > 0.0:
			var from: = Vector2(body.global_position.x, body.global_position.z)
			var stop: float = BattleArena.border_stop(g.arena_rect, from, Vector2(dir.x, dir.z), dash_plan, bw)
			if stop < dash_plan:
				dash_plan = maxf(stop - 0.25, 0.3)


	_dash_run = DashRun.build(mv, dash_plan, _dash_speed_factor(), Dex.dist_scale) if DashRun.uses_run(mv) else {}
	if not _dash_run.is_empty():

		dash_t = float(_dash_run.total)
		dash_speed = dash_plan / maxf(dash_t, 0.001)
	else:
		dash_speed = float(mv.get("speed", 12.0)) * speed_factor()
		var travel: = float(_sa.travel_ms) / 1000.0 / speed_factor()
		dash_t = travel if travel > 0.0 else dash_plan / maxf(dash_speed, 0.001)
		dash_speed = dash_plan / maxf(dash_t, 0.001)
	dash_total = dash_t
	dash_contact_p = 0.0




	_dash_running = _dash_style_a and not _dash_run.is_empty() and dash_miss == null
	_dash_budget = maxf(dash_range - float(_dash_run.l), 0.0) if _dash_running else 0.0
	_dash_lunge_u = -1.0
	_dash_coasting = false
	_dash_settle = false


	_dash_coast = maxf(dash_range - dash_plan, 0.3)
	_ghost_n = 0
	_ghost_t = 0.0


	var wc: Dictionary = _sa.get("water_cloak", {})
	if wc is Dictionary and not wc.is_empty():
		body._vfx().style_a_water_cloak(self, body, body.look_height(), dir, wc)

	var ad: Dictionary = _sa.get("axis_drill", {})
	if ad is Dictionary and not ad.is_empty():
		body._vfx().style_a_axis_drill(self, body, body.look_height(), dir, ad)

	var bt: Dictionary = _sa.get("bolt_trail", {})
	if bt is Dictionary and not bt.is_empty():
		body._vfx().style_a_bolt_trail(self, body, body.look_height(), dir, bt)


	_dash_hop = _dash_style_a and _dash_grounded()\
	and not (is_instance_valid(opponent) and (opponent.combat.air_t > 0.0 or opponent.combat.floats() or opponent.combat.is_airborne()))





	var hop_h: = float(_sa.hop_h)


	_dash_hop_h = hop_h * body.look_height() if hop_h > 0.0 else float(_sa.hop) * jump_height * _cast_k()
	_dash_from = body.global_position
	body.facing = dir



	if String(mv.get("id", "")) == "dig":
		dash_t = DIG_UNDER_T
		_dig_goal = body.global_position + dir * float(mv.get("range", 3.0))
		_dig_under()



func body_radius() -> float:
	if body != null and body.has_method("body_radius"):
		return body.body_radius()
	return BodySize.REF_SUM * 0.5





func reach_to(t: Node) -> float:
	if is_instance_valid(t) and t.has_method("body_radius"):
		return BodySize.contact(body_radius(), t.body_radius())
	return BodySize.contact(body_radius(), BodySize.REF_SUM * 0.5)




func _dash_grounded() -> bool:
	return not floats() and air_t <= 0.0







func _dig_hole_size() -> float:
	var r: = 0.35
	var cs: = body.get_node_or_null("CollisionShape3D")
	if cs != null and cs.shape is CapsuleShape3D:
		r = (cs.shape as CapsuleShape3D).radius
	return maxf(maxf(r * 2.4, body.look_height() * 0.8), 1.4)




func _dig_travel(bsp: float) -> void :
	if is_instance_valid(opponent) and dash_t > DIG_LOCK_T:
		_dig_goal = opponent.global_position
	var to: = _dig_goal - body.global_position
	to.y = 0.0
	var step: = dash_speed * Dex.dist_scale * bsp
	body.velocity.y = 0.0
	body.global_position.y = body.ground_y()
	if to.length() > 0.3:
		dash_dir = to.normalized()
		body.facing = dash_dir
		body.velocity.x = dash_dir.x * step
		body.velocity.z = dash_dir.z * step
	else:
		body.velocity.x = 0.0
		body.velocity.z = 0.0
	if dash_t <= 0.0:
		_dig_surface()
		_dig_burst_hit()




func _dig_burst_hit() -> void :
	var hole: = _dig_hole_size() * 0.5 + 0.6
	for t in body._moves().targets_of(body):
		if t == dash_miss:
			continue
		var d: Vector3 = t.global_position - body.global_position
		d.y = 0.0
		if d.length() < maxf(reach_to(t), hole):
			if passes_under(t):
				dodge_tell(t, dash_move.get("id", ""))
				continue
			_dash_hit = true
			body._moves().hit(body, t, dash_move, dash_dir)
			return





func _dig_under() -> void :
	_dig_sink = DIG_SINK_T
	_dig_rise = 0.0
	_dig_vis = 0.0
	underground = false
	body.sprite.visible = true


	body._vfx().style_a_dig(self, body, opponent, body.look_height())



func _dig_surface() -> void :
	if not underground:
		return
	underground = false
	_dig_sink = 0.0
	body.sprite.visible = true

	_dig_rise = DIG_RISE_T * clampf(_dig_vis, 0.0, 1.0)
	if _dig_rise <= 0.0:
		_dig_vis = 0.0





func _dig_reset() -> void :
	underground = false
	_dig_sink = 0.0
	_dig_rise = 0.0
	_dig_vis = 0.0
	if is_instance_valid(body) and body.sprite != null:
		body.sprite.visible = true




func dig_sink_m() -> float:
	if body == null or _dig_vis <= 0.0:
		return 0.0
	return _dig_vis * body.look_height()




func _dig_tick(delta: float) -> void :


	var blink: = float(_sa.get("blink", 0.0))
	if blink > 0.0 and not underground:
		body.sprite.visible = dash_t <= 0.0 or dash_progress() > blink
	if _dig_rise > 0.0:
		_dig_rise = maxf(_dig_rise - delta, 0.0)
		_dig_vis = _dig_rise / DIG_RISE_T
	if not underground:
		if _dig_sink > 0.0 and dash_t <= 0.0:

			_dig_sink = 0.0
			_dig_vis = 0.0
			body.sprite.visible = true
		return
	if dash_t > 0.0:
		body.sprite.visible = false
	else:
		_dig_surface()



func dash_progress() -> float:
	return clampf(1.0 - dash_t / maxf(dash_total, 0.001), 0.0, 1.0)



func dash_over() -> bool:
	return dash_t <= 0.0 and not _dash_coasting and not _dash_settle





func dash_roll(p: float) -> float:
	if not bool(_sa.spin):
		return 0.0
	var q: = clampf(p, 0.0, 1.0)
	return - body._cam_side(dash_dir) * TAU * float(_sa.get("spin_turns", 1.0)) * q * q * (3.0 - 2.0 * q)


func dash_hop_m() -> float:
	if not _dash_hop or dash_t <= 0.0:
		return 0.0
	if not _dash_run.is_empty():
		return _dash_hop_h * sin(PI * DashRun.lunge_q(_dash_run, dash_progress()))
	return _dash_hop_h * sin(PI * dash_progress())







func _dash_pursue(d: float, delta: float, bsp: float) -> float:
	var l: = float(_dash_run.l)
	var t_l: = maxf(float(_dash_run.t_l), 0.001)
	if _dash_running:
		var rem: = -1.0
		if is_instance_valid(opponent):
			var to_t: = opponent.global_position - body.global_position
			to_t.y = 0.0
			rem = to_t.length() - reach_to(opponent)
			if to_t.length() > 0.01:
				dash_dir = to_t.normalized()
				body.facing = dash_dir
		if rem >= 0.0 and rem <= l:



			_dash_running = false
			_dash_lunge_u = 0.0
			_dash_run = DashRun.build(dash_move, maxf(rem, 0.05), _dash_speed_factor(), Dex.dist_scale)
			l = float(_dash_run.l)
			t_l = maxf(float(_dash_run.t_l), 0.001)
			dash_t = t_l
		else:


			var step: = minf(float(_dash_run.v) * d, _dash_budget)
			_dash_budget = maxf(_dash_budget - step, 0.0)



			dash_t = maxf(dash_t, t_l + 0.01)
			if _dash_budget <= 0.0001:


				_dash_running = false
				_dash_lunge_u = 0.0
				dash_t = t_l
			return step

	var a: = float(_dash_run.a)
	var u0: = clampf(_dash_lunge_u, 0.0, 1.0)
	var u1: = clampf(u0 + d / t_l, 0.0, 1.0)
	var step: = l * ((a * u1 + (1.0 - a) * u1 * u1) - (a * u0 + (1.0 - a) * u0 * u0))
	_dash_lunge_u = u1
	dash_t = t_l * (1.0 - u1)
	if u1 >= 1.0:
		_dash_lunge_u = -1.0
		dash_t = 0.0


		if not _dash_hit:
			_dash_coast = maxf(_dash_budget, 0.3)
			_dash_coasting = true
	return step


func _dash_travel(p: float) -> float:
	if not _dash_run.is_empty():
		return DashRun.travel(_dash_run, p)
	return pow(clampf(p, 0.0, 1.0), SA_TRAVEL_EXP)






func _dash_trail(delta: float) -> void :
	if not _dash_style_a:
		return



	var step: = float(_sa.ghost_ms) / 1000.0
	var ghosts: = int(_sa.ghosts)
	if not _dash_run.is_empty():
		ghosts = maxi(ghosts, DASH_GHOSTS)

	if dash_t <= 0.0 or _dash_coasting:
		return
	var p0: = dash_progress() - step / maxf(dash_total, 0.001)



	var run_mode: = not _dash_run.is_empty()
	if run_mode and ghosts <= 0:
		return
	if p0 <= (0.0 if run_mode or float(_sa.get("blink", 0.0)) > 0.0 else 0.12):
		return
	_ghost_t -= delta
	if ( not run_mode and _ghost_n >= ghosts) or _ghost_t > 0.0:
		return
	_ghost_t = step
	_ghost_n += 1
	p0 = clampf(p0, 0.0, 1.0)
	var at: = _dash_from + dash_dir * (dash_plan * _dash_travel(p0))


	if _dash_running:
		at = body.global_position
	if _dash_hop:
		at += Vector3(0, _dash_hop_h * sin(PI * (DashRun.lunge_q(_dash_run, p0) if run_mode else p0)), 0)
	if run_mode:

		body._vfx().style_a_afterimage(body.sprite, at, 1, _sa, dash_roll(p0), maxf(ghosts * step, 0.05))
	else:
		body._vfx().style_a_afterimage(body.sprite, at, ghosts - _ghost_n + 1, _sa, dash_roll(p0))


func _check_dash_hit() -> void :
	if _dash_hit:
		return
	for t in body._moves().targets_of(body):
		if t == dash_miss:
			continue
		var grip: bool = t == holder()
		if grip or _flat_dist(t) < reach_to(t):

			if not grip and passes_under(t):



				if air_t > 0.0 and t.combat.air_h - jump_height < dash_reach():
					continue
				if not _dash_dodged.has(t.get_instance_id()):
					_dash_dodged[t.get_instance_id()] = true
					dodge_tell(t, dash_move.get("id", ""))
				continue

			if not grip and DashClash.head_on(body, t):
				continue
			_dash_hit = true
			dash_contact_p = dash_progress()
			dash_t = 0.0
			_dash_coasting = false


			var mvs: Node = body._moves()
			var multi: = bool(dash_move.get("full_contact", false))
			var sp: Dictionary = mvs._split_for(dash_splits, t, 0) if multi else {}
			var accepted: bool = mvs.hit(body, t, dash_move, dash_dir, dash_power_scale, not multi or int(dash_move.get("hits", 1)) == 1, sp)
			if accepted and String(dash_move.get("id", "")) == "aerial_ace":
				_begin_ace(t)
			return


func _begin_ace(target: PhysicsBody3D) -> void :
	_ace_active = true
	_ace_target = target
	_ace_from = body.global_position
	_ace_end = target.global_position
	_ace_total = maxf(float(_sa.cut_through.get("ms", 260.0)) / 1000.0, 0.001)
	dash_t = _ace_total

	body.add_collision_exception_with(target)
	target.add_collision_exception_with(body)


func _finish_ace() -> void :
	if not _ace_active:
		return
	if is_instance_valid(_ace_target):
		body.remove_collision_exception_with(_ace_target)
		_ace_target.remove_collision_exception_with(body)
	_ace_target = null
	_ace_active = false
	dash_t = 0.0


func _step_ace(d: float, delta: float) -> void :

	if dash_t <= 0.0:
		_finish_ace()
		body.velocity.x = 0.0
		body.velocity.z = 0.0
		return
	if is_instance_valid(_ace_target):
		_ace_end = _ace_target.global_position
	var behind: = maxf(HIT_RANGE, body.look_height() * float(_sa.cut_through.get("behind", 1.0)))
	var end: = _ace_end + dash_dir * behind
	var arena: = _arena()
	if arena.size.x > 1.0 and arena.size.y > 1.0:
		arena = arena.grow(-0.5)
		end.x = clampf(end.x, arena.position.x, arena.end.x)
		end.z = clampf(end.z, arena.position.y, arena.end.y)
	dash_t = maxf(dash_t - d, 0.0)
	var p: = 1.0 - dash_t / _ace_total
	var next: = _ace_from.lerp(end, 1.0 - pow(1.0 - p, 3.0))
	var motion: = (next - body.global_position) / maxf(delta, 0.0001)
	body.velocity.x = motion.x
	body.velocity.z = motion.z
	body.facing = dash_dir






func begin_prepare(id: String, mv: Dictionary, prepare: float) -> int:
	prepare_gen += 1
	revenge_bonus = false
	prepare_id = id
	prepare_move = mv
	prepare_t = prepare
	prepare_total = maxf(prepare, 0.001)
	prepare_interrupted = false
	if bool(StyleA.params(mv).get("comet", false)):
		comet_fx = body._vfx().style_a_comet(body)
	root_t = maxf(root_t, prepare)
	if id in WIND_MOVES:
		var wl: Dictionary = StyleA.params(mv).get("wing_lift", {})
		body.begin_wind_move(float(wl.get("lift", 0.15)), float(wl.get("hold", 0.0)))
	else:
		body.cancel_wind_move()
	body.squash = JUMP_SQUASH
	if id == "air_cutter":
		body._vfx().endeavor_aura(body, prepare + float(mv.range) / maxf(float(mv.speed) * body.speed_factor(), 0.001), false, "flying")
	if id == "focus_punch":
		body._vfx().style_a_focus_charge(body)
	if id == "confusion":
		body._vfx().timed_aura(body, "_psychic_light", prepare + 0.9)
	if id == "overheat":
		body._vfx().fire_aura(body, prepare + float(mv.get("duration", 0.7)) + 2.0)

	var prep_style: = StyleA.params(mv, body.species)
	if StyleA.windup(mv) and walks() and not floats() and body.is_on_floor() and air_t <= 0.0\
	and id not in WIND_MOVES and id not in ["dragon_breath", "twister"]\
	and (prep_style.get("head_first", {}) as Dictionary).is_empty()\
	and (prep_style.get("rise", {}) as Dictionary).is_empty():
		body._vfx().windup_dust(body, prepare_gen)

	if id == "dragon_rage":
		_prepare_fx = body._vfx().dragon_rage(body)
	elif id == "fire_blast":
		_prepare_fx = body._vfx().fire_blast(body)
	elif id == "dragon_breath":
		_prepare_fx = body._vfx().dragon_breath(body, null, body.aim_dir(), "tell")
	elif id == "heat_wave":
		_prepare_fx = body._vfx().heat_wave(body, null, body.aim_dir(), true)
	elif id == "leer":
		_prepare_fx = body._vfx().status_move_fx(body, "leer")
	elif id in ["kinesis", "role_play"]:

		body._vfx().timed_aura(body, "_psychic_light", prepare + 1.9)
		if is_instance_valid(opponent):
			body._vfx().timed_aura(opponent, "_psychic_light", prepare + 1.9)



	var feathers = StyleA.params(mv).get("feathers", {})
	if feathers is Dictionary and not feathers.is_empty():
		body._vfx().style_a_feathers(body, feathers, prepare)
	if String(StyleA.params(mv).get("art", "")) == "rock_throw":
		body._vfx().style_a_rock_lift(body, prepare)
	if String(StyleA.params(mv).get("art", "")) == "electro_ball":

		var orb = body._vfx().style_a_projectile(body, "electro_lift", body.look_height(), body.aim_dir())
		if orb != null:
			orb.shot_range = maxf(prepare, 0.05)
			orb.k = StyleA.electro_k(body)
	if String(StyleA.params(mv).get("art", "")) in ["tri_attack", "air_slash"]:

		var wlift = body._vfx().style_a_projectile(body, String(StyleA.params(mv).get("art", "")) + "_lift", body.look_height(), body.aim_dir())
		if wlift != null:
			wlift.shot_range = maxf(prepare, 0.05)
	if bool(StyleA.params(mv).get("teleport", false)):
		body._vfx().style_a_teleport_tell(body, prepare)
	if bool(StyleA.params(mv).get("thrash", false)):
		body._vfx().style_a_thrash(body, prepare)
	if bool(StyleA.params(mv).get("rampage", false)):

		body._vfx().timed_aura(body, "_dragon", prepare + float(mv.get("hits", 5)) * float(mv.get("interval", 0.3)) + 0.5)
	if bool(StyleA.params(mv).get("sun_gather", false)):
		body._vfx().style_a_sun_gather(body, prepare)
	if bool(StyleA.params(mv).get("drill_cone", false)):
		body._vfx().style_a_drill_cone(body, prepare)
	var charge_aura = StyleA.params(mv).get("charge_aura", false)
	if charge_aura is String:

		if charge_aura == "type":
			body._vfx().endeavor_aura(body, prepare + 0.35, false, String(mv.get("type", "normal")))
		else:
			body._vfx().timed_aura(body, String(charge_aura), prepare + 0.35)
	elif bool(charge_aura):
		body._vfx().timed_aura(body, "Zapdos", prepare + 0.15)
	if bool(StyleA.params(mv).get("live_wire", false)):
		body._vfx().style_a_live_wire(body, prepare, StyleA.params(mv).get("heavy_wire", {}))
	var dash_wire: Dictionary = StyleA.params(mv).get("dash_wire", {})
	if not dash_wire.is_empty():
		body._vfx().style_a_live_wire(body, prepare, dash_wire)
	var chain: Dictionary = StyleA.params(mv).get("chain_bolt", {})
	if not chain.is_empty():
		body._vfx().style_a_chain_bolt(body, prepare, chain)
	var chev = StyleA.params(mv).get("chevron", {})
	if chev is Dictionary and not chev.is_empty():
		body._vfx().style_a_chevron(body, chev, prepare)


	if bool(StyleA.params(mv).get("aqua_tail", false)):
		body._vfx().style_a_aqua_wave(self, body, body.look_height())


	if bool(StyleA.params(mv).get("poison_jab", false)):
		body._vfx().style_a_poison_stinger(self, body, body.look_height())

	if bool(StyleA.params(mv).get("flail", false)):
		body._vfx().style_a_flail(self, body, body.look_height())
		if String(mv.get("id", "")) == "reversal":

			body._vfx().endeavor_aura(body, prepare + 0.9, true)

			var aura: Node = body.sprite.get_node_or_null("LegendaryAura") if body.sprite != null else null
			if aura != null:
				var vk: float = Flail.visual_k(Flail.power(int(body.hp), int(body.max_hp)))
				aura.power = 0.45 + 1.3 * clampf((vk - 0.55) / 1.25, 0.0, 1.0)


	var hglint = StyleA.params(mv).get("head_glint", {})
	if hglint is Dictionary and not hglint.is_empty():
		body._vfx().style_a_head_glint(body, hglint)

	var sart: Dictionary = StyleA.params(mv, body.species).get("stream_art", {})
	if not sart.is_empty():
		body._vfx().style_a_stream_art_tell(body, sart, prepare)
	if String(mv.get("kind", "")) == "whip" and String(mv.get("id", "")) not in ["bind", "wrap"]:

		var wv: Array = body._moves().whip_victims(body, mv, body.aim_dir(), Dex.whip_reach(body.species, mv), float(mv.get("tip_radius", 0.6)))
		body._vfx().style_a_vine_whip_tell(body, StyleA.params(mv).get("vines", {}), prepare, 2 * maxi(wv.size(), 1))
	if String(mv.get("kind", "")) == "orbs":
		body._vfx().style_a_orbs_tell(body, prepare)
	if String(mv.get("dynamic", "")) == "facade" and prepare > 0.0:
		body._vfx().style_a_facade_tell(body, String(mv.get("_facade", "burn")))
	if String(mv.get("dynamic", "")) == "frustration":
		body._moves()._anger_marks(body, int(mv.get("_fr_tier", 0)))
	var icicles: Dictionary = StyleA.params(mv).get("icicles", {})
	if not icicles.is_empty():
		var icd: = icicles.duplicate()
		icd["count"] = int(mv.get("hits", 3))
		icd["interval"] = float(mv.get("interval", 0.16))
		icd["flight"] = float(StyleA.params(mv).flight_ms) / 1000.0
		body._vfx().style_a_icicles(body, prepare, icd)
	var prep_pose: = String(StyleA.params(mv, body.species).get("prep_pose", ""))
	if prep_pose != "" and body.has_method("play_prepare_pose"):
		body.play_prepare_pose(prep_pose, prepare, 0 if (bool(StyleA.params(mv).get("roundhouse", false)) or bool(StyleA.params(mv).get("sole_print", false)) or bool(StyleA.params(mv).get("comet", false)) or bool(StyleA.params(mv).close_barrage)) else -1)
	return prepare_gen




func wait_prepare(gen: int) -> bool:

	if prepare_id == "revenge":
		while is_instance_valid(body) and prepare_gen == gen and (prepare_t > 0.0 or in_impact()):
			await body.get_tree().physics_frame
	var t: = prepare_t
	if t > 0.0:
		await Battle.fight_wait(t)
	if prepare_gen != gen:
		return false
	if not is_instance_valid(body) or not can_act():
		_clear_prepare()
		return false
	return true



func _clear_prepare(keep_wind: = false) -> void :

	if is_instance_valid(body):
		if prepare_id in WIND_MOVES and not keep_wind:
			body.cancel_wind_move()
		if prepare_id in STATUS_GESTURES or prepare_id in DEFENSE_BUFFS or prepare_id in OTHER_SELF_BUFFS:
			body.cancel_status_gesture()
	revenge_bonus = false
	prepare_t = 0.0
	prepare_move = {}
	prepare_id = ""
	prepare_gen += 1
	if is_instance_valid(_prepare_fx):
		_prepare_fx.queue_free()
	_prepare_fx = null






func end_prepare() -> void :


	if prepare_id == "leer":
		_prepare_fx = null
	var wind: = prepare_id in WIND_MOVES
	if wind:
		body.release_wind_move()
	_clear_prepare(wind)
	root_t = 0.0
	body.squash = 0.0 if wind else JUMP_STRETCH



func cancel_prepare() -> void :
	if is_instance_valid(comet_fx):
		comet_fx.queue_free()
	cancel_binding()
	cancel_seismic_throw()
	_clear_prepare()




func interrupt_prepare() -> void :
	cancel_seismic_throw()
	if prepare_move.is_empty():
		return
	var id: = prepare_id
	finish_move_cooldown(cooldown_gen)
	_clear_prepare()
	prepare_interrupted = true
	root_t = 0.0
	stun_t = maxf(stun_t, PREPARE_STUN)
	if id != "":
		move_cd[id] = minf(float(move_cd.get(id, 0.0)), gcd_t)
	body._vfx().popup(body.head_pos(0.9), "FOCUS LOST!" if id == "focus_punch" else "Interrupted!", Color(1.0, 0.8, 0.5) if id == "focus_punch" else Color(0.7, 0.85, 1.0), 1.0, "interrupted")
	print("[prepare] %s interrupted" % body.species)



func entry_cooldown() -> void :
	gcd_duration = ENTRY_COOLDOWN
	gcd_t = gcd_duration / recovery_factor()


func begin_move_cooldown(id: String, mv: Dictionary) -> int:
	cooldown_gen += 1
	cooldown_move = id
	move_cd[id] = Dex.cooldown(mv) / recovery_factor()
	gcd_duration = Dex.GLOBAL_COOLDOWN
	gcd_t = gcd_duration / recovery_factor()
	evade_cd_t = EVADE_COOLDOWN / recovery_factor()
	return cooldown_gen


func finish_move_cooldown(gen: int) -> void :
	if gen == cooldown_gen:
		cooldown_move = ""




func set_loadout(i: int) -> void :
	if body == null or body.mon == null:
		return
	loadout = clampi(i, 0, 1)
	moves = body.mon.loadout(loadout).duplicate()
	selected_move = ""


func reset_move_cooldown() -> void :
	cooldown_clash = false
	cooldown_gen += 1
	cooldown_move = ""



func clear_cooldowns() -> void :
	reset_move_cooldown()
	move_cd.clear()
	gcd_t = 0.0
	evade_cd_t = 0.0
	root_t = 0.0
	cancel_prepare()



func struggle() -> void :
	if _cd > 0.0 or _lunge_t > 0.0 or gcd_t > 0.0 or not may_start(STRUGGLE):
		return
	body._vfx().popup(body.head_pos(1.0), "No PP left! Struggle!", Color(1, 0.6, 0.4))
	_start_lunge(aim_dir())
	_cd = 1.0
	_struggling = true


func _start_lunge(dir: Vector3) -> void :
	grudge = false
	hop_to_reach(opponent)
	_lunge_dir = dir
	_cd = ATTACK_CD
	gcd_duration = Dex.GLOBAL_COOLDOWN
	gcd_t = gcd_duration / recovery_factor()
	evade_cd_t = EVADE_COOLDOWN / recovery_factor()
	var gen: = begin_prepare("", LUNGE, LUNGE_PREPARE)
	_release_lunge(gen)



func _release_lunge(gen: int) -> void :
	if not await wait_prepare(gen):
		return
	end_prepare()
	_lunge_t = LUNGE_TIME
	_hit_done = false







func start_arc_step(dir: Vector3, allow_float: = false, max_range: = ARC_STEP_MAX) -> bool:
	_arc_step_t = 0.0
	if air_t > 0.0 or (floats() and not allow_float) or dash_t > 0.0 or _lunge_t > 0.0:
		return false
	var travel: = max_range
	if is_instance_valid(opponent):
		var to_o: = opponent.global_position - body.global_position
		to_o.y = 0.0
		travel = clampf(to_o.length() - reach_to(opponent), 0.0, max_range)
	if travel < 0.1:
		return false
	_arc_step_dir = dir.normalized() if dir.length() > 0.01 else Vector3.BACK
	_arc_step_t = travel / ARC_STEP_SPEED
	return true



func wait_arc_step() -> void :
	var guard: = 0
	var last: = _arc_step_t
	var stalled: = 0
	while _arc_step_t > 0.0 and is_instance_valid(body) and guard < 120:
		await body.get_tree().physics_frame
		guard += 1
		if absf(_arc_step_t - last) < 1e-05:
			stalled += 1
			if stalled > 2:
				break
		else:
			stalled = 0
		last = _arc_step_t


func _check_hit() -> void :
	if _hit_done or not is_instance_valid(opponent) or opponent.mode == Creature.Mode.FAINTED:
		return
	if _flat_dist(opponent) < reach_to(opponent):
		if passes_under(opponent):
			_hit_done = true
			_lunge_t = 0.0
			dodge_tell(opponent, STRUGGLE.id if _struggling else "lunge")
			return
		_hit_done = true
		_lunge_t = 0.0
		if not _struggling:

			body._moves().hit(body, opponent, Dex.move("tackle"), _lunge_dir)
			return
		_struggling = false
		body._moves().hit(body, opponent, STRUGGLE, _lunge_dir)
		var recoil: = maxi(1, int(body.max_hp / 4.0))
		body._vfx().popup(body.head_pos(0.6), "-%d recoil" % recoil, Color(1, 0.6, 0.4))
		Audio.play_at("sfx/battle/recoil", body.global_position)
		body.take_damage(recoil, - _lunge_dir, 3.0, {"source": body, "move": "struggle", "kind": "recoil"})





func tick(delta: float) -> void :
	is_infatuated()
	_expire_meal()
	check_held_berry()
	_border_lock = maxf(_border_lock - delta, 0.0)



	if impact_t > 0.0:
		return


	var wall: = delta if battle_speed() > 0.0 else 0.0

	delta *= battle_speed()
	_water_entry_t = maxf(_water_entry_t - delta, 0.0)
	_tick_taunt(delta)
	var attractor: = follow_me_target(body)
	if attractor != null:
		opponent = attractor
	_tick_lingering(delta)
	_cd = maxf(_cd - wall, 0.0)
	body.peace_timer = maxf(body.peace_timer - delta, 0.0)
	stun_t = maxf(stun_t - delta, 0.0)
	root_t = maxf(root_t - delta, 0.0)
	prepare_t = maxf(prepare_t - delta, 0.0)
	if prepare_t > 0.0 and prepare_id not in STATUS_GESTURES and prepare_id not in WIND_MOVES and prepare_id not in DEFENSE_BUFFS and prepare_id not in OTHER_SELF_BUFFS:
		body.squash = JUMP_SQUASH
	trap_t = maxf(trap_t - delta, 0.0)
	if trap_t <= 0.0 and not trap_zone.is_empty():
		trap_zone = {}
	land_t = maxf(land_t - delta, 0.0)
	evasion_t = maxf(evasion_t - delta, 0.0)
	lock_t = maxf(lock_t - delta, 0.0)
	endure_t = maxf(endure_t - delta, 0.0)
	if lock_t <= 0.0:
		lock_target = null
	if evasion_t <= 0.0:
		minimized = false
	protect_t = maxf(protect_t - delta, 0.0)
	mist_t = maxf(mist_t - delta, 0.0)
	if perish_n > 0 and Battle.in_battle and not Battle.online_guest:
		perish_t -= delta
		if perish_t <= 0.0:
			_perish_tick()
	if evade_t > 0.0:
		evade_t = maxf(evade_t - delta, 0.0)
		var was_protected: = evade_invuln_t > 0.0
		evade_invuln_t = maxf(evade_invuln_t - delta, 0.0)
		if was_protected and evade_invuln_t <= 0.0:
			Audio.play_at("sfx/battle/dodge_end", body.global_position, -8.0 if body.mode == Creature.Mode.PLAYER else -13.0, 1.0, true)
		if evade_t <= 0.0:
			sprinting = false
			if _evade_exhausted:
				_evade_exhausted = false
				stagger()
	_evade_regen_t = maxf(_evade_regen_t - delta, 0.0)
	var was_confused: = confusion_t > 0.0
	confusion_t = maxf(confusion_t - delta, 0.0)
	if was_confused and confusion_t <= 0.0:




		body._vfx().status_cure_attempt(body, "confusion", true)

	var holding: bool = is_instance_valid(binding) and binding.user == body
	for k in move_cd.keys():
		if k != cooldown_move and not (holding and k == String(binding.move.get("id", ""))):
			move_cd[k] = maxf(move_cd[k] - wall, 0.0)


	if cooldown_move == "" or cooldown_move in ["bind", "wrap", "clamp"]:
		gcd_t = maxf(gcd_t - wall, 0.0)
		evade_cd_t = maxf(evade_cd_t - wall, 0.0)
	_tick_status(delta)
	_tick_water(delta)
	if overboard:
		_try_climb()
	if flight != Flight.GROUNDED:
		flight_t += delta
		if flight == Flight.AIRBORNE:


			fly_pp = maxf(fly_pp - FLIGHT_DRAIN * delta, 0.0)
			if fly_pp <= fly_pp_base * FLIGHT_FLOOR:
				begin_landing()
	if stagger_t > 0.0:
		stagger_t = maxf(stagger_t - delta, 0.0)
		if stagger_t == 0.0:
			stamina = 0.0
			body.sprite.modulate = body.base_tint()
			body.refresh_label()
	elif stamina < pp_max and _evade_regen_t <= 0.0:
		stamina = minf(pp_max, stamina + pp_max * PP_REGEN * recovery_factor() * delta)
	elif stamina > pp_max:
		stamina = pp_max



const GROUND_START_SPEED: = 0.8
const GROUND_RUN_UP: = 1.0
var _ground_run_t: = 0.0
var _ground_direction: = Vector3.ZERO
var _turn_dust_cd: = 0.0



func drive_velocity(delta: float, want: Vector3, speed: float, fighting: bool) -> void :
	_turn_dust_cd = maxf(0.0, _turn_dust_cd - delta * battle_speed())

	if want.length_squared() <= 0.0001 or not fighting or not walks() or floats() or air_t > 0.0 or not body.is_on_floor()\
	or not can_act() or root_t > 0.0 or trap_t > 0.0 or impact_t > 0.0\
	or dash_t > 0.0 or _dash_coasting or _dash_settle or _lunge_t > 0.0\
	or _arc_step_t > 0.0 or evade_t > 0.0 or _ace_active or _leaping\
	or _pad_leaping or (is_instance_valid(binding) and not held_slowed()) or _knock.length() > 0.01:
		_ground_run_t = 0.0
		_ground_direction = Vector3.ZERO
	if is_instance_valid(binding):

		if binding.foe == body and dash_t > 0.0:
			_check_dash_hit()
		dash_t = 0.0
		_lunge_t = 0.0
		cancel_knock()

		if not held_slowed():
			body.velocity = Vector3.ZERO
			return
		speed *= SLOWED_SPEED






	_dig_tick(delta)


	if (dash_t > 0.0 or _dash_coasting) and not _dash_hit and is_instance_valid(opponent)\
	and opponent.combat.evade_t > 0.0:
		_dash_saw_evade = true
	if _dash_saw_evade and not _dash_hit and dash_over():
		_dash_saw_evade = false
		_whiff_pending = true
		_whiff_dir = dash_dir
	if _whiff_pending and dash_over() and _lunge_t <= 0.0:
		_whiff_pending = false
		body.whiff_stumble_now(_whiff_dir)
	if impact_t > 0.0:
		body.velocity = Vector3.ZERO
		return
	var bsp: = move_speed()
	var d: = delta * bsp
	if _leap_charge_t > 0.0:
		_tick_leap_tell(d)
		return
	if _leaping:
		_tick_leap(d)
		return
	if _pad_leaping:
		_tick_pad_leap(d)
		return
	if _ace_active and ( not fighting or not can_act() or trap_t > 0.0):
		_finish_ace()
	var in_fight: = fighting and is_instance_valid(opponent)
	if fighting:
		speed *= speed_factor()
	speed *= locomotion_speed_mult()
	speed *= terrain_speed_mult()
	if pad_hop and air_t > 0.0:
		speed *= PAD_HOP_SPEED







	if status == "freeze" or (fighting and not can_act()) or root_t > 0.0:
		want = Vector3.ZERO
	if ingrained and _knock.length() >= INGRAIN_BREAK:
		unroot()
	if trap_t > 0.0:

		want = Vector3.ZERO
		dash_t = 0.0
		_lunge_t = 0.0
		_knock = Vector3.ZERO


	if air_t > 0.0:
		air_t = maxf(air_t - d, 0.0)
		var jv: = jump_vy() * jump_boost * jump_speed
		var jg: = JUMP_G * jump_speed * jump_speed
		var t: = jump_time * jump_boost / jump_speed - air_t
		if _launch_v > 0.0:
			jv = _launch_v
			jg = JUMP_G
			t = _launch_total - air_t


		var ck: = _cast_k()
		jv *= ck
		jg *= ck
		air_h = maxf(jv * t - 0.5 * jg * t * t, 0.0)
		body.velocity.y = (jv - jg * t) * bsp
		if air_t <= 0.0:
			_launch_v = 0.0
			air_h = 0.0
			land_t = PAD_HOP_LAND if pad_hop else JUMP_LAND
			if pad_hop:
				_pad_hop_thump()
			pad_hop = false
			jump_boost = 1.0
			jump_speed = 1.0
			body.squash = JUMP_SQUASH
			Audio.play_at("sfx/world/land", body.global_position, -7.0)
	elif floats():
		hold_altitude(delta)

	if evade_t > 0.0:
		var u: = _evade_motion_u
		var u1: = minf(u + d, EVADE_TOTAL)
		_evade_motion_u = u1
		var ev: = (evade_progress(u1) - evade_progress(u)) * _evade_dist / maxf(d, 0.0001)

		var walk_fraction: = clampf((u1 - maxf(u, EVADE_BURST)) / maxf(d, 0.0001), 0.0, 1.0)
		var walk: = want * (speed / SPRINT_MULT) * walk_fraction * Dex.dist_scale
		body.velocity.x = (evade_dir.x * ev + walk.x) * bsp
		body.velocity.z = (evade_dir.z * ev + walk.z) * bsp
		if is_instance_valid(opponent):
			var to_e: = opponent.global_position - body.global_position
			to_e.y = 0.0
			if to_e.length() > 0.01:
				body.facing = to_e.normalized()
		_knock = _knock.move_toward(Vector3.ZERO, 30.0 * d)
		return
	if _ace_active:
		_step_ace(d, delta)
		return
	if dash_slow != 1.0 and dash_t > 0.0:
		d *= dash_slow

	var t_left: = dash_t

	var settling: = _dash_settle
	_dash_settle = false
	if dash_t > 0.0 or _dash_coasting or settling:
		dash_t = maxf(dash_t - d, 0.0)


		var fist = _sa.get("fist", {})
		if not _dash_fist and fist is Dictionary and not fist.is_empty()\
		and dash_t <= float(fist.get("lead_ms", 60.0)) / 1000.0 and is_instance_valid(opponent):
			_dash_fist = true
			body._vfx().style_a_mega_fist(self, opponent, dash_dir, fist)
		if underground:
			_dig_travel(bsp)
		elif _dig_sink > 0.0:


			_dig_sink = maxf(_dig_sink - d, 0.0)
			_dig_vis = 1.0 - _dig_sink / DIG_SINK_T
			body.velocity.x = 0.0
			body.velocity.z = 0.0
			if _dig_sink <= 0.0:
				_dig_vis = 1.0
				underground = true
				body.sprite.visible = false
		else:





			_check_dash_hit()
			if is_instance_valid(seismic_throw):
				return
			if is_instance_valid(binding):
				body.velocity = Vector3.ZERO
				return
			if _ace_active:
				body.velocity.x = 0.0
				body.velocity.z = 0.0
				return
			var step: = 0.0
			if _dash_water and _water_dash_leap_due():
				_water_dash_leap()
				return
			if _dash_running or _dash_lunge_u >= 0.0:
				step = _dash_pursue(d, delta, bsp)
				if _dash_water and (_dash_lunge_u >= 0.0 or not _dash_running):


					_water_dash_leap()
					return
			elif t_left > 0.0 and not settling:



				var p1: = dash_progress()
				var p0: = clampf(p1 - d / maxf(dash_total, 0.001), 0.0, 1.0)
				step = dash_plan * (_dash_travel(p1) - _dash_travel(p0))


				if dash_t <= 0.0 and not _dash_hit and _dash_coast > 0.0:
					_dash_coasting = true
			elif not _dash_hit and _dash_coast > 0.0:


				var coast_v: float = float(_dash_run.peak) if not _dash_run.is_empty() else SA_TRAVEL_EXP * dash_speed
				step = minf(coast_v * (1.0 if not _dash_run.is_empty() else Dex.dist_scale) * bsp * delta, _dash_coast)
				_dash_coast = maxf(_dash_coast - step, 0.0)
				if _dash_coast > 0.0:
					_dash_coasting = true
				else:

					_dash_settle = true
					_dash_coasting = false
			var sv: = step / maxf(delta, 0.0001)
			body.velocity.x = dash_dir.x * sv
			body.velocity.z = dash_dir.z * sv

		if not underground and _dig_sink <= 0.0:
			_dash_trail(delta)



		if dash_t <= 0.0 and _dash_coast <= 0.0 and not _dash_hit and not _dash_fx_done:
			_dash_fx_done = true
			body._moves().play_dash_reach_fx(body, dash_move, dash_dir)
		if dash_t <= 0.0 and not _dash_coasting:
			_dig_surface()
	elif _lunge_t > 0.0:
		_lunge_t -= d
		body.velocity.x = _lunge_dir.x * LUNGE_SPEED * Dex.dist_scale * bsp
		body.velocity.z = _lunge_dir.z * LUNGE_SPEED * Dex.dist_scale * bsp
		_check_hit()
	elif _arc_step_t > 0.0:

		_arc_step_t -= d
		var step: = ARC_STEP_SPEED * Dex.dist_scale
		if is_instance_valid(opponent):
			var to_t: = opponent.global_position - body.global_position
			to_t.y = 0.0
			step = minf(step, (to_t.length() - reach_to(opponent)) / maxf(d, 0.0001))
		step = maxf(step, 0.0)
		if step == 0.0:
			_arc_step_t = 0.0
		body.velocity.x = _arc_step_dir.x * step * bsp
		body.velocity.z = _arc_step_dir.z * step * bsp
	else:
		if _try_shore_transition(want):
			_tick_pad_leap(d)
			return


		var travel: = want * speed * Dex.dist_scale
		if fighting and walks() and not floats() and air_t <= 0.0 and body.is_on_floor()\
		and can_act() and root_t <= 0.0 and trap_t <= 0.0 and _knock.length() <= 0.01:
			var direction: = want.normalized()

			if direction != Vector3.ZERO and _ground_direction != Vector3.ZERO\
			and direction.dot(_ground_direction) <= 0.707107 and _turn_dust_cd <= 0.0\
			and body._battle_ground_speed > speed * 0.5 * Dex.dist_scale and land_t <= 0.0:
				body.squash = minf(body.squash, -0.18)
				_turn_dust_cd = 0.18
				body._vfx().turn_dust(body)
			_ground_direction = direction
			travel *= lerpf(GROUND_START_SPEED, 1.0, _ground_run_t / GROUND_RUN_UP)
			if want.length_squared() > 0.0001:
				_ground_run_t = minf(_ground_run_t + d, GROUND_RUN_UP)
		body.velocity.x = (travel.x + _knock.x) * bsp
		body.velocity.z = (travel.z + _knock.z) * bsp
		if in_fight:
			var to_o: = opponent.global_position - body.global_position
			to_o.y = 0.0
			if to_o.length() > 0.01:
				body.facing = to_o.normalized()
		elif want.length() > 0.1:
			body.facing = want.normalized()
	_knock = _knock.move_toward(Vector3.ZERO, 30.0 * d)



var _meal_seed: Dictionary = {}
var _meal_seeded: = false

func seed_meal() -> void :
	if _meal_seeded or body.mon == null:
		return
	_meal_seeded = true
	if not CookingRules.active(body.mon.meal_buff, Clock.minutes):
		return
	for stat in body.mon.meal_buff.get("stats", {}):
		var before: = int(stages.get(stat, 0))
		stages[stat] = clampi(before + int(body.mon.meal_buff.stats[stat]), -6, 6)
		_meal_seed[stat] = int(stages[stat]) - before

func _expire_meal() -> void :
	if _meal_seed.is_empty() or body.mon == null or CookingRules.active(body.mon.meal_buff, Clock.minutes):
		return
	for stat in _meal_seed:
		stages[stat] = clampi(int(stages.get(stat, 0)) - int(_meal_seed[stat]), -6, 6)
	_meal_seed.clear()

func _meal_blocks(s: String) -> bool:
	if body.mon == null or not body.mon.meal_blocks(s, Clock.minutes):
		return false
	body._vfx().popup(body.head_pos(0.5), "MEAL SHIELD", Color("34d399"), 0.8, "status")
	return true
