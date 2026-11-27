extends Node



const Dex: = preload("res://scripts/dex.gd")
const Trainers: = preload("res://scripts/trainers.gd")
const PokemonSprites: = preload("res://scripts/pokemon_sprites.gd")
const CreatureDef: = preload("res://scripts/creature.gd")
const MonScript: = preload("res://scripts/stats/mon.gd")

const ShinyPity: = preload("res://scripts/shiny_pity.gd")
const SurfAmbush: = preload("res://scripts/surf_ambush.gd")
const CREATURE_SCENE: = preload("res://scenes/creature.tscn")
const MonLightScript: = preload("res://scripts/world/mon_light.gd")


var _tables: = {}

var _rates: = {}





func prepare_scene(scene: PackedScene, owner: = "") -> void :
	var species: = {}
	_collect_scene_species(scene.get_state(), species, {})
	if owner != "":
		PokemonSprites.claim(owner, species.keys())
	for mon in Game.party:
		species[String(mon.species)] = true
	for name: String in species:
		await PokemonSprites.prepare_species(name)


func _collect_scene_species(state: SceneState, species: Dictionary, visited: Dictionary) -> void :
	if visited.has(state.get_instance_id()):
		return
	visited[state.get_instance_id()] = true
	var base: = state.get_base_scene_state()
	if base != null:
		_collect_scene_species(base, species, visited)
	for i in state.get_node_count():
		var nested: = state.get_node_instance(i)
		if nested != null:
			_collect_scene_species(nested.get_state(), species, visited)
		for j in state.get_node_property_count(i):
			var key: = state.get_node_property_name(i, j)
			var value = state.get_node_property_value(i, j)
			if key == "species" and value is String and value != "":
				species[value] = true
			elif key == "trainer_id" and value is String:
				var trainer: = Trainers.get_def(value)
				var party: Array = trainer.get("party", [])
				var variants: Dictionary = trainer.get("parties", {})
				if not variants.is_empty():
					party = variants.get(String(Game.flags.get(String(trainer.get("party_flag", "")), "")), party)
				for mon in party:
					var name: = String(mon[0])
					if name.begins_with("@"):
						name = String(Game.flags.get(name.substr(1), ""))
					if name != "":
						species[name] = true
			elif key == "encounter_table" and value is String:
				for entry in load_table(value):
					species[String(entry.species)] = true


func prepare_table(path: String) -> void :
	for entry in load_table(path):
		await PokemonSprites.prepare_species(String(entry.species))




func load_table(path: String) -> Array:
	if not _tables.has(path):
		var entries: Array = []
		var f: = FileAccess.open(path, FileAccess.READ)
		if f:
			var data = JSON.parse_string(f.get_as_text())
			if data is Dictionary:
				entries = data.get("entries", [])
		_tables[path] = entries
	return _tables[path]





func table_rate(path: String) -> int:
	if not _rates.has(path):
		var rate: = 21
		var f: = FileAccess.open(path, FileAccess.READ)
		if f:
			var data = JSON.parse_string(f.get_as_text())
			if data is Dictionary and data.has("rate"):
				rate = int(data["rate"])
		_rates[path] = rate
	return _rates[path]






static func eligible(e: Dictionary, ctx: Dictionary) -> bool:
	if ctx.is_empty():
		return true
	var period: = String(ctx.get("period", ""))
	var t: String = e.get("time", "any")
	if t == "day" and not period in ["morning", "midday", "afternoon"]:
		return false
	if t == "night" and not period in ["sunset", "night"]:
		return false
	if e.get("weather", "any") == "rain":
		return bool(ctx.get("wet", false))
	return true



func ctx_at(pos: Vector3) -> Dictionary:
	return {"period": Clock.period(), "wet": Game._rain_at(pos)}



func roll(path: String, mode: String, ctx: = {}) -> Dictionary:
	var pool: Array = []
	var total: = 0.0
	for e in load_table(path):
		var m: String = e.get("mode", "both")
		if (m == mode or m == "both") and eligible(e, ctx):
			pool.append(e)
			total += float(e.get("weight", 1))
	if pool.is_empty():
		return {}
	var r: = randf() * total
	for e in pool:
		r -= float(e.get("weight", 1))
		if r <= 0.0:
			return e
	return pool[-1]





static func roll_held(table: Array) -> String:
	var r: = randf() * 100.0
	for row in table:
		r -= float(row.get("chance", 0))
		if r <= 0.0:
			return String(row.get("item", ""))
	return ""



func spawn_creature(entry: Dictionary, parent: Node, pos: Vector3, is_wild: = true, shiny: = false) -> CreatureDef:
	var lr: Array = entry.get("level_range", [2, 4])
	var lv: = int(entry.level) if entry.has("level") else randi_range(int(lr[0]), int(lr[1]))
	var m = MonScript.create(entry.get("species", "Bulbasaur"), lv, null, shiny or Debug.shiny)
	m.held = roll_held(Dex.species(m.species).get("wild_held", []))
	var behaviours: = {"passive": CreatureDef.Behaviour.PASSIVE, "flee": CreatureDef.Behaviour.FLEE, "aggressive": CreatureDef.Behaviour.AGGRESSIVE}
	return spawn_mon(m, parent, pos, is_wild, behaviours.get(entry.get("behaviour", "passive"), CreatureDef.Behaviour.PASSIVE))



func spawn_mon(m: RefCounted, parent: Node, pos: Vector3, is_wild: = true, behaviour: = 0) -> CreatureDef:
	var c: CreatureDef = CREATURE_SCENE.instantiate()
	c.mon = m
	c.is_wild = is_wild
	c.species = m.species
	c.level = m.level
	c.behaviour = behaviour
	parent.add_child(c)
	c.global_position = pos
	Transitions.reset_interp(c)
	c.set_home_here()


	if not is_wild and not Battle.in_battle:
		MonLightScript.attach(c, m.species)
	return c





func surf_zone_at(p: Vector3) -> Dictionary:
	var zones: Array = []
	for z in get_tree().get_nodes_in_group("spawn_zone"):
		if z.mode == "swim":
			zones.append({"pos": Vector2(z.global_position.x, z.global_position.z), "size": z.size, 
				"radius": z.radius, "table": z.encounter_table, "mode": "swim"})
	return SurfAmbush.zone_for(zones, Vector2(p.x, p.z))



func surf_encounter(p: Node3D, table: String) -> void :
	var lan = get_node_or_null("/root/LanCampaign")
	if lan != null and not lan.allow_solo_wild(): return
	if Game.is_busy() or Game.party.is_empty():
		return
	var pool: = SurfAmbush.pool(load_table(table), ctx_at(p.global_position), self)
	if pool.is_empty():
		return
	var total: = 0.0
	for e in pool:
		total += float(e.get("weight", 1))
	var r: = randf() * total
	var e: Dictionary = pool[-1]
	for row in pool:
		r -= float(row.get("weight", 1))
		if r <= 0.0:
			e = row
			break
	Battle._ambush = true
	Battle.snapshot_out()
	p.controls_enabled = false
	p.show_alert(true)
	Vfx.water_splash(p, true, 0.8, 0.6, Vector3.INF)
	await get_tree().create_timer(0.6).timeout
	p.show_alert(false)
	if not is_instance_valid(p):
		Battle._ambush = false
		return
	var ahead: Vector3 = p.facing_vector()
	var target: Vector3 = p.global_position + Vector3(ahead.x, 0.0, ahead.z).normalized() * 2.2
	target.y = p.global_position.y
	await PokemonSprites.prepare_species(String(e.species))
	if not is_instance_valid(p):
		Battle._ambush = false
		return
	var c: = spawn_creature(e, p.get_parent(), target + Vector3(0, -0.8, 0), true, 
		ShinyPity.roll(Time.get_ticks_msec() / 1000.0))
	c.mode = CreatureDef.Mode.IDLE
	var tw: = create_tween()
	tw.tween_property(c, "position", target + Vector3(0, 0.6, 0), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "position", target, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	Battle._ambush = false
	if c.mon != null and c.mon.shiny:
		Vfx.shiny_sparkle(c)
	Battle.start_battle(c)





func cave_zone_at(p: Vector3) -> Dictionary:
	var zones: Array = []
	for z in get_tree().get_nodes_in_group("cave_zone"):
		zones.append({"pos": Vector2(z.global_position.x, z.global_position.z), "size": z.size, 
			"radius": z.radius, "table": z.encounter_table, "mode": z.mode})
	return SurfAmbush.cave_zone_for(zones, Vector2(p.x, p.z))




func cave_encounter(p: Node3D, table: String) -> void :
	if Game.is_busy() or Game.party.is_empty():
		return
	var pool: = SurfAmbush.cave_pool(load_table(table), ctx_at(p.global_position), self)
	if pool.is_empty():
		return
	var total: = 0.0
	for e in pool:
		total += float(e.get("weight", 1))
	var r: = randf() * total
	var e: Dictionary = pool[-1]
	for row in pool:
		r -= float(row.get("weight", 1))
		if r <= 0.0:
			e = row
			break
	Battle._ambush = true
	Battle.snapshot_out()
	p.controls_enabled = false
	var ahead: Vector3 = p.facing_vector()
	ahead = Vector3(ahead.x, 0.0, ahead.z).normalized()
	var target: Vector3 = p.global_position + ahead * 2.2
	var eye: = Vector3(0, 0.5, 0)
	var q: = PhysicsRayQueryParameters3D.create(p.global_position + eye, target + eye)
	q.exclude = [p.get_rid()]
	if not p.get_world_3d().direct_space_state.intersect_ray(q).is_empty():
		target = p.global_position - ahead * 2.2
	target.y = p.global_position.y
	p.show_alert(true)
	Vfx.rising_dust(target, 1.2, 0.8)
	Vfx.shake(0.05, 0.5)
	await get_tree().create_timer(0.6).timeout
	p.show_alert(false)
	await PokemonSprites.prepare_species(String(e.species))
	if not is_instance_valid(p):
		Battle._ambush = false
		return
	var c: = spawn_creature(e, p.get_parent(), target + Vector3(0, 2.6, 0), true, 
		ShinyPity.roll(Time.get_ticks_msec() / 1000.0))
	c.mode = CreatureDef.Mode.IDLE
	var tw: = create_tween()
	tw.tween_property(c, "global_position", target, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	Vfx.rising_dust(target, 0.8, 1.0)
	Battle._ambush = false
	if c.mon != null and c.mon.shiny:
		Vfx.shiny_sparkle(c)
	Battle.start_battle(c)




func grass_encounter(p: Node3D, table: String) -> void :
	var lan = get_node_or_null("/root/LanCampaign")
	if lan != null and not lan.allow_solo_wild(): return
	if Game.is_busy() or Game.party.is_empty():
		return
	var e: = roll(table, "grass", ctx_at(p.global_position))
	if e.is_empty():
		return
	Battle._ambush = true
	Battle.snapshot_out()
	p.controls_enabled = false

	var driven = p.get("pilot")
	var src: Node3D = driven if driven != null and is_instance_valid(driven) else p
	var ahead: Vector3 = (driven.facing if src == driven else p.facing_vector())


	var grass = p.get("_grass")
	if src == driven and p.get("_pilot_patch") != null:
		grass = [p.get("_pilot_patch")]
	if grass is Array and not grass.is_empty():
		var g: Node = grass[-1]
		if g.has_method("shake"):
			g.shake(src.global_position)
	p.show_alert(true)
	await get_tree().create_timer(0.6).timeout
	p.show_alert(false)
	if not is_instance_valid(src):
		src = p
		ahead = p.facing_vector()
	var target: Vector3 = src.global_position + Vector3(ahead.x, 0.0, ahead.z).normalized() * 2.2
	target.y = Transitions.ground_y(target, src.global_position.y)
	await PokemonSprites.prepare_species(String(e.species))
	if not is_instance_valid(p):
		Battle._ambush = false
		return
	var c: = spawn_creature(e, p.get_parent(), target + Vector3(0, -0.8, 0), true, 
		ShinyPity.roll(Time.get_ticks_msec() / 1000.0))
	c.mode = CreatureDef.Mode.IDLE
	var tw: = create_tween()
	tw.tween_property(c, "position", target + Vector3(0, 1.3, 0), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "position", target, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	Battle._ambush = false
	if c.mon != null and c.mon.shiny:
		Vfx.shiny_sparkle(c)
	Battle.start_battle(c)
