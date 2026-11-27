class_name SaveGame
extends RefCounted














const DEFAULT_PATH: = "user://save.json"
const SAVE_NAME: = "save.json"


const SLOTS: = 3

static func slot_name(i: int) -> String:
	if i <= 0:
		return SAVE_NAME
	return "save%d.json" % i


static func slot_path(i: int) -> String:
	if i <= 0:
		return path
	return path.get_basename() + str(i) + ".json"


static var path: = DEFAULT_PATH

static var slot: = 0

static var legacy_path: = ""
static var _platform_done: = false
static func set_slot(i: int) -> void :
	slot = clampi(i, 0, SLOTS - 1)



static func read_path_for(i: int) -> String:
	var p: = slot_path(i)
	if FileAccess.file_exists(p):
		return p
	if i == 0 and legacy_path != "" and FileAccess.file_exists(legacy_path):
		return legacy_path
	return p



static func peek_slot(i: int) -> Dictionary:
	var p: = read_path_for(i)
	if not FileAccess.file_exists(p):
		return {}
	return peek_file(p)



static func has_file_slot(i: int) -> bool:
	return FileAccess.file_exists(read_path_for(i))



static var enabled: = false



const Compat: = preload("res://scripts/state/save_compat.gd")
const OLD_SUFFIX: = ".pre-0.4.0"




static func resolve(platform: String, downloads: String) -> Dictionary:
	var dir: = SharedPaths.folder(platform, downloads)
	if dir == "":
		return {"path": DEFAULT_PATH, "legacy": ""}
	return {"path": dir.path_join(SAVE_NAME), "legacy": DEFAULT_PATH}




static func _ensure_platform() -> void :
	if _platform_done:
		return
	_platform_done = true
	if path != DEFAULT_PATH:
		return
	var r: = resolve(OS.get_name(), OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS) if OS.has_feature("android") else "")
	path = String(r.path)
	legacy_path = String(r.legacy)
	if legacy_path != "":
		SharedPaths.ensure_access(path)

	print("[save] path=%s exists=%s | legacy=%s exists=%s" % [path, FileAccess.file_exists(path), 
		legacy_path, legacy_path != "" and FileAccess.file_exists(legacy_path)])



static func shared() -> bool:
	return legacy_path != ""




static func read_path() -> String:
	_ensure_platform()
	return read_path_for(slot)


static func compatible(d: Dictionary) -> bool:
	return Compat.compatible(d)



static func too_old() -> bool:
	var p: = read_path()
	if not FileAccess.file_exists(p):
		return false
	var d = JSON.parse_string(FileAccess.get_file_as_string(p))
	return d is Dictionary and d.get("state") is Dictionary and not compatible(d)



static func peek() -> Dictionary:
	return peek_file(read_path())


static func peek_file(p: String) -> Dictionary:
	if not FileAccess.file_exists(p):
		return {}
	var f: = FileAccess.open(p, FileAccess.READ)
	if f == null:
		print("[save] peek %s OPEN FAILED %s" % [p, error_string(FileAccess.get_open_error())])
		return {}
	var n: = f.get_length()
	var text: = f.get_as_text()
	f.close()
	print("[save] peek %s declared_len=%d text_len=%d head=%s" % [p, n, text.length(), text.substr(0, 24)])
	var d = JSON.parse_string(text)
	if not (d is Dictionary and d.get("state") is Dictionary):
		push_warning("[save] %s is not a valid save" % p)
		return {}
	if not compatible(d):
		push_warning("[save] %s is from a version before %s" % [p, Compat.MIN_VERSION_TEXT])
		return {}
	if not ResourceLoader.exists(String(d.get("scene", ""))):
		push_warning("[save] %s points at a missing scene: %s" % [p, d.get("scene")])
		return {}
	return migrate_layout(d)


static func migrate_layout(d: Dictionary) -> Dictionary:


	if int(d.get("world_layout", 0)) >= 1 or d.get("scene") != "res://scenes/world/overworld.tscn":
		return d
	var pos: Variant = d.get("pos")
	if pos is Array and pos.size() == 3 and float(pos[0]) >= 7.0 and float(pos[0]) < 30.0\
	and float(pos[2]) <= -213.0 and float(pos[2]) >= -253.5:
		var flags: Dictionary = d.get("state", {}).get("flags", {})
		d["spawn"] = "r2_cave" if d.get("spawn") == "r2_cave" and flags.get("thunder_badge", false) else "r2_works"
		d["pos"] = null
	d["world_layout"] = 1
	return d


static func exists() -> bool:
	return not peek().is_empty()



static func peek_all() -> Array:
	_ensure_platform()
	var out: Array = []
	for i in SLOTS:
		out.append(peek_slot(i))
	return out




static func has_file() -> bool:
	return FileAccess.file_exists(read_path())



static func summary_rows(d: Dictionary) -> Array:
	var st: Dictionary = d.get("state", {})
	var party = st.get("party", [])
	return [
		["PLAYER", str(st.get("player_name", GameState.DEFAULT_PLAYER_NAME))], 
		["TIME", GameState.format_time(float(st.get("play_time", 0.0)))], 
		["POKéMON", str(party.size() if party is Array else 0)], 
		["LOCATION", str(d.get("location", "?"))], 
	]



static func snapshot() -> Dictionary:
	var tower: = Game.get_tree().root.get_node_or_null("BattleTower")
	if tower != null and tower.story_state != null:
		var safe: Dictionary = tower.entry_snapshot.duplicate(true)
		safe["state"] = tower.story_state.to_dict()
		return safe
	var tree: = Game.get_tree()
	var scene: = tree.current_scene
	var d: = {"state": Game.state.to_dict(), "scene": scene.scene_file_path if scene else "", 
		"spawn": "", "pos": null, "row": 0, "location": location_name(), 
		"saved_at": int(Time.get_unix_time_from_system()), "world_layout": 1}
	var p: = Game.get_player()
	if p:
		d.spawn = nearest_spawn(p.global_position)
		d.pos = [p.global_position.x, p.global_position.y, p.global_position.z]
		d.row = int(p.row)

		if p.has_method("riding_slot"):
			d["ride"] = int(p.riding_slot())
	return d


static func write(d: Dictionary) -> bool:
	if Game.get_node_or_null("/root/LanCampaign") != null: return false
	_ensure_platform()
	var sp: = slot_path(slot)
	d["game_version"] = Compat.game_version()
	var text: = JSON.stringify(d, "\t")
	if shared():

		if _store(sp, text):
			return true


		push_warning("[save] shared write failed; falling back to %s" % DEFAULT_PATH)
		return _store(DEFAULT_PATH, text)
	if too_old():
		DirAccess.copy_absolute(ProjectSettings.globalize_path(sp), ProjectSettings.globalize_path(sp + OLD_SUFFIX))
	var tmp: = sp + ".tmp"
	if not _store(tmp, text):
		return false
	var err: = DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(sp))
	if err != OK:
		push_warning("[save] rename failed: %s" % error_string(err))
	return err == OK


static func _store(p: String, text: String) -> bool:
	var f: = FileAccess.open(p, FileAccess.WRITE)
	if f == null:
		push_warning("[save] cannot write %s (%s)" % [p, error_string(FileAccess.get_open_error())])
		return false
	f.store_string(text)
	f.close()
	return true


static func save_now() -> bool:
	var ok: = write(snapshot())
	Debug.log("[save] slot %d %s -> %s" % [slot, slot_path(slot), "ok" if ok else "FAILED"])
	return ok


static func can_autosave() -> bool:
	return enabled and Game.get_player() != null and not Battle.in_battle and not Battle._ambush\
	and not Game.cutscene and not Game.talking and not Transitions.busy()



static func autosave() -> void :
	if not can_autosave():
		return
	if save_now():
		var h: = Game.get_hud()
		if h and h.has_method("show_saving"):
			h.show_saving()



static func restore() -> bool:
	var d: = peek()
	if d.is_empty():
		return false



	for i in Game.companions.keys():
		var old = Game.companions.get(i)
		if old != null and is_instance_valid(old):
			old.queue_free()
	Game.state.from_dict(d.state)
	await Transitions.go_to(String(d.scene), String(d.get("spawn", "")), true)


	_restore_ride(d)
	await _place_saved(d)
	_sync_ride_body()
	enabled = true
	return true




static func _restore_ride(d: Dictionary) -> void :
	var slot: = int(d.get("ride", -1))
	var p: = Game.get_player()
	if slot < 0 or p == null or slot >= Game.party.size() or Game.party[slot].hp <= 0:
		return


	if not is_instance_valid(Game.companions.get(slot)):
		Transitions.respawn_companion(slot, p)
	if not is_instance_valid(Game.companions.get(slot)):
		return
	if not p.mount_up(slot):


		var c = Game.companions.get(slot)
		if c != null and is_instance_valid(c) and not c.visible:
			c.visible = true
			c.set_physics_process(true)




static func _sync_ride_body() -> void :
	var p: = Game.get_player()
	if p == null or not p.has_method("riding_slot"):
		return
	var ride: int = p.riding_slot()
	var c = Game.companions.get(ride) if ride >= 0 else null
	if c != null and is_instance_valid(c):
		c.global_position = p.global_position
		Transitions.reset_interp(c)


static func _place_saved(d: Dictionary) -> void :
	var p: = Game.get_player()
	var pos = d.get("pos")
	if p == null or not (pos is Array and pos.size() == 3):
		return
	var v: = Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
	p.global_position = v
	Transitions.reset_interp(p)
	p.row = clampi(int(d.get("row", 0)), 0, 3)
	p.sprite.frame = p.row * 3


	Transitions.snap_arrival_hooks()
	var cam: = Game.get_camera_rig()
	if cam:
		cam.snap()
	for _i in 3:
		await Game.get_tree().physics_frame
	if p.global_position.y < v.y - 2.0:
		push_warning("[save] saved position %s has no floor; using spawn %s" % [v, d.get("spawn")])
		Transitions.pending_spawn = String(d.get("spawn", ""))
		Transitions.place_player(p)



static func location_name() -> String:
	var tree: = Game.get_tree()
	var streamer: = tree.get_first_node_in_group("zone_streamer")
	if streamer and streamer.zones.has(streamer.active):
		return String(streamer.zones[streamer.active].name)
	var scene: = tree.current_scene
	if scene == null:
		return ""
	return scene.scene_file_path.get_file().get_basename().trim_suffix("_interiors").capitalize()



static func nearest_spawn(pos: Vector3) -> String:
	var tree: = Game.get_tree()
	var allowed: = {}
	var streamer: = tree.get_first_node_in_group("zone_streamer")
	if streamer and streamer.zones.has(streamer.active):
		for s in streamer.zones[streamer.active].spawns:
			allowed[String(s)] = true
	var best: = ""
	var best_d: = INF
	for sp in tree.get_nodes_in_group("spawn_point"):
		if not allowed.is_empty() and not allowed.has(String(sp.name)):
			continue
		var dist: float = pos.distance_squared_to(sp.global_position)
		if dist < best_d:
			best_d = dist
			best = String(sp.name)
	return best
