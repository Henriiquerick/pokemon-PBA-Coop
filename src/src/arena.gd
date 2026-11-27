extends Node3D
## LAN experiment: real Creature/Combatant/Moves, no campaign or save loading.
const MonDef = preload("res://scripts/stats/mon.gd")
const CreatureDef = preload("res://scripts/creature.gd")
const Proto = preload("res://scripts/net/battle_proto.gd")
const PokemonSprites = preload("res://scripts/pokemon_sprites.gd")
const PROTOCOL = "pba-0.6.2a-coop-1"
const CENTER = Vector3(0.5, 0, -238)
var role = "host"
var address = "127.0.0.1"
var port = 24620
var auto_test = false
var test_case = "win"
var peer: ENetMultiplayerPeer
var remote_id = 0
var phase = "loading"
var fighters: Array = []
var mons: Array = []
var status_label: Label
var hp_label: Label
var started_ms = 0
var last_seen = 0
var last_input = 0
var seq = 0
var received_seq = -1
var snap_seq = 0
var applied_snap = -1
var tick_accum = 0.0
var input_accum = 0.0
var hit_counts = [0, 0]
var damage_counts = [0, 0]
var moved = [false, false]
var original_positions: Array = []
var ended_ms = 0
var audit_file: FileAccess
var last_report = 0
var result = ""
var lobby_position = CENTER + Vector3(-5, 0, 7)
var captured = false

func _ready():
	SaveGame.enabled = false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--coop-role="): role = arg.get_slice("=", 1)
		if arg.begins_with("--coop-ip="): address = arg.get_slice("=", 1)
		if arg.begins_with("--coop-port="): port = int(arg.get_slice("=", 1))
		if arg == "--coop-autotest": auto_test = true
		if arg.begins_with("--coop-test="): test_case = arg.get_slice("=", 1)
	if role not in ["host", "guest"] or port < 1024 or port > 65535:
		push_error("COOP invalid role/port")
		get_tree().quit(2)
		return
	audit_file = FileAccess.open("user://coop_audit.jsonl", FileAccess.WRITE)
	Game.state.reset_new_game()
	Game.state.player_name = "LAN " + role
	_build_world()
	_log("boot", {"role": role, "engine": Engine.get_version_info().string, "user_dir": OS.get_user_data_dir()})
	# All test data is newly created. No SaveGame.load or campaign trainer hooks.
	seed(0xC00F)
	for spec in [["Bulbasaur", 12, "tackle"], ["Charmander", 12, "scratch"], ["Rattata", 12, "tackle"]]:
		var mon = MonDef.create(spec[0], spec[1])
		mon.moves = [spec[2]]
		mon.ivs = {"hp": 15, "atk": 15, "def": 15, "spa": 15, "spd": 15, "spe": 15}
		mon.nature = "hardy"
		mon.recalc()
		mon.heal_full()
		mons.append(mon)
		await PokemonSprites.prepare_species(spec[0])
		await PokemonSprites.load_full(spec[0], false)
	Game.state.party = [mons[0], mons[1]]
	_spawn_fighters()
	Moves.move_released.connect(_on_move)
	Moves.hit_landed.connect(_on_hit)
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 1) if role == "host" else peer.create_client(address, port)
	if error != OK:
		_finish("network_error_%d" % error)
		return
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.connected_to_server.connect(_connected)
	multiplayer.connection_failed.connect(func(): _finish("connection_failed"))
	multiplayer.server_disconnected.connect(func(): _finish("disconnected"))
	multiplayer.multiplayer_peer = peer
	phase = "waiting"
	started_ms = Time.get_ticks_msec()
	last_seen = started_ms
	status_label.text = "Route 2 / arena LAN | %s | %s:%d | aguardando segundo PC" % [role, address, port]
	_log("listening" if role == "host" else "connecting", {"ip": address, "port": port})

func _build_world():
	var environment = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("91bfd0")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.8
	environment.environment = env
	add_child(environment)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-65, -25, 0)
	add_child(sun)
	_box(CENTER + Vector3(0, -0.3, 0), Vector3(32, 0.6, 30), Color("668e4b"), true)
	# Reconstruct only the Ryan clearing and nearby path from the original Route 2 data.
	var map_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/route_2.json"))
	for p in map_data.get("paths", []):
		var r = Rect2(p[0], p[1], p[2], p[3])
		if r.intersects(Rect2(-13, -250, 27, 27)):
			_box(Vector3(r.get_center().x, 0.005, r.get_center().y), Vector3(r.size.x, 0.015, r.size.y), Color("c5b681"))
	_box(CENTER, Vector3(12, 0.025, 10), Color("adbd72"))
	for x in [-6.1, 6.1]: _box(CENTER + Vector3(x, 0.04, 0), Vector3(0.08, 0.05, 10), Color("f4dc69"))
	for z in [-5.1, 5.1]: _box(CENTER + Vector3(0, 0.04, z), Vector3(12, 0.05, 0.08), Color("f4dc69"))
	var camera = Camera3D.new()
	add_child(camera)
	camera.position = CENTER + Vector3(0, 17, 16)
	camera.look_at(CENTER)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 16
	camera.current = true
	var layer = CanvasLayer.new()
	add_child(layer)
	status_label = Label.new()
	status_label.position = Vector2(18, 15)
	layer.add_child(status_label)
	hp_label = Label.new()
	hp_label.position = Vector2(18, 50)
	layer.add_child(hp_label)
	var help = Label.new()
	help.position = Vector2(18, 615)
	help.text = "WASD/setas: mover | 1: Tackle/Scratch | Shift: esquiva | Esc: sair da luta\nTeste sem save/recompensas. NPC: Rattata de teste com IA real. F10: fechar."
	layer.add_child(help)

func _box(at: Vector3, size: Vector3, color: Color, solid = false):
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	add_child(mesh)
	mesh.position = at
	if solid:
		var body = StaticBody3D.new()
		var shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		body.add_child(shape)
		add_child(body)
		body.position = at

func _spawn_fighters():
	for c in fighters:
		if is_instance_valid(c): c.queue_free()
	fighters.clear()
	for i in 3:
		var at = CENTER + [Vector3(-2, 0.15, -1.4), Vector3(-2, 0.15, 1.4), Vector3(2, 0.15, 0)][i]
		var c = Encounters.spawn_mon(mons[i], self, at, i == 2)
		c.remove_from_group("wild")
		c.mode = CreatureDef.Mode.IDLE if role == "host" else CreatureDef.Mode.PUPPET
		c.side = 0 if i < 2 else 1
		c.ai_uses_moves = true
		c.combat.is_trainer_mon = true
		c.selected_move = String(c.moves[0])
		c.combat.auto_brain("low", "", "youngster")
		c.add_to_group("combatant")
		var tag = Label3D.new()
		tag.text = ["P1 / HOST", "P2 / GUEST", "NPC / IA HOST"][i]
		tag.position.y = 2.2
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.font_size = 32
		tag.pixel_size = 0.009
		c.add_child(tag)
		fighters.append(c)
	fighters[0].opponent = fighters[2]
	fighters[1].opponent = fighters[2]
	fighters[2].opponent = fighters[0]
	original_positions = fighters.map(func(c): return c.global_position)

func _peer_connected(id):
	if role == "host":
		remote_id = id
		last_seen = Time.get_ticks_msec()
		_log("peer_connected", {"peer": id})

func _connected():
	_hello.rpc_id(1, PROTOCOL)

@rpc("any_peer", "call_remote", "reliable")
func _hello(protocol: String):
	if role != "host" or multiplayer.get_remote_sender_id() != remote_id or phase != "waiting": return
	if protocol != PROTOCOL:
		peer.disconnect_peer(remote_id)
		return
	_setup.rpc_id(remote_id, mons.map(func(m): return m.to_dict()))

@rpc("authority", "call_remote", "reliable")
func _setup(data: Array):
	if role != "guest" or data.size() != 3: return
	mons = data.map(func(d): return MonDef.from_dict(d))
	Game.state.party = [mons[0], mons[1]]
	_spawn_fighters()
	_ack.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func _ack():
	if role != "host" or multiplayer.get_remote_sender_id() != remote_id or phase != "waiting": return
	_start.rpc_id(remote_id)
	_start_battle()

@rpc("authority", "call_remote", "reliable")
func _start():
	_start_battle()

func _start_battle():
	phase = "fighting"
	started_ms = Time.get_ticks_msec()
	last_seen = started_ms
	Battle.in_battle = true
	Battle.online = true
	Battle.online_guest = role == "guest"
	Battle.challenge = true
	Battle.no_capture = true
	Battle.no_whiteout = true
	Battle._intro = false
	Battle._ending = false
	Battle.partner = fighters[0 if role == "host" else 1]
	Battle.allies = [fighters[0], fighters[1]]
	Battle.wild = fighters[2]
	Battle.arena_rect = Rect2(CENTER.x - 6, CENTER.z - 5, 12, 10)
	Battle.trainer_battle = {"name": "LAN Test NPC", "center": CENTER, "arena": Vector2(12, 10), "scripted": true, "mons": [mons[2]], "index": 0, "total": 1}
	if role == "host":
		for i in 3:
			Battle._join_fight(fighters[i])
			fighters[i].mode = CreatureDef.Mode.REMOTE if i < 2 else CreatureDef.Mode.BATTLE_AI
	status_label.text = "Route 2 / ARENA CO-OP | %s | dois jogadores contra NPC" % role
	_log("battle_started", {"species": mons.map(func(m): return m.species)})

func _process(delta):
	if Input.is_physical_key_pressed(KEY_F10): get_tree().quit()
	var now = Time.get_ticks_msec()
	if phase in ["loading", "waiting"]:
		if phase == "waiting" and now - last_seen > 30000: _finish("connect_timeout")
		return
	if phase == "ended":
		# Offline control is returned immediately; test PCs can close independently.
		var me = fighters[0 if role == "host" else 1]
		var v = _local_move()
		if auto_test: v = Vector2.RIGHT
		me.global_position += Vector3(v.x, 0, v.y) * delta * 3
		me.global_position.x = clampf(me.global_position.x, CENTER.x - 14, CENTER.x + 14)
		me.global_position.z = clampf(me.global_position.z, CENTER.z - 13, CENTER.z + 13)
		if auto_test and now - ended_ms > 1500:
			_log("exit_ok", {"result": result, "control_restored": me.global_position.distance_to(lobby_position) > 0.3, "outside_arena": not Rect2(CENTER.x - 6, CENTER.z - 5, 12, 10).has_point(Vector2(me.global_position.x, me.global_position.z))})
			get_tree().quit()
		return
	if phase != "fighting": return
	if not captured and auto_test and DisplayServer.get_name() != "headless" and now - started_ms > 1600:
		captured = true
		_capture.call_deferred()
	if now - last_seen > 8000:
		_finish("timeout")
		return
	input_accum += delta
	if input_accum >= 1.0 / 30.0:
		input_accum = 0
		seq += 1
		var intent = _intent()
		if role == "host": _apply_input(0, intent)
		else: _input_packet.rpc_id(1, seq, intent)
	if Input.is_physical_key_pressed(KEY_ESCAPE):
		if role == "host": _finish("aborted")
		else: _abort.rpc_id(1)
	if role == "host":
		# Test harness uses the very same intent path as keyboard/network input.
		if auto_test and test_case == "abort" and now - started_ms > 3000:
			_finish("aborted")
			return
		if auto_test and test_case == "drop_host" and now - started_ms > 3000:
			_log("injected_process_exit")
			get_tree().quit()
		if auto_test and test_case == "drop_guest" and now - started_ms > 15000: _finish("test_timeout")
		for i in 2:
			moved[i] = moved[i] or fighters[i].global_position.distance_to(original_positions[i]) > 0.3
			if not fighters[i].alive(): fighters[i].combat.remote_intent.move = Vector2.ZERO
		var living = [fighters[0], fighters[1]].filter(func(c): return c.alive())
		if not fighters[2].alive() or fighters[2].hp <= 0:
			_finish("won")
		elif living.is_empty():
			_finish("lost")
		elif not is_instance_valid(fighters[2].opponent) or not fighters[2].opponent.alive():
			fighters[2].opponent = living[0]
		tick_accum += delta
		if phase == "fighting" and tick_accum >= 0.05:
			tick_accum = 0
			snap_seq += 1
			_snapshot.rpc_id(remote_id, snap_seq, fighters.map(func(c): return Proto.snap_fighter(c, 0)))
			_log("snapshot_sent", {"snapshot": snap_seq, "hp": fighters.map(func(c): return c.hp)})
		if auto_test and now - started_ms > 90000: _finish("test_timeout")
	elif auto_test and test_case == "drop_guest" and now - started_ms > 3000:
		_log("injected_process_exit")
		get_tree().quit()
	if now - last_report >= 1000:
		last_report = now
		_log("state", {"snapshot": snap_seq if role == "host" else applied_snap, "hp": fighters.map(func(c): return c.hp), "pos": fighters.map(func(c): return [c.global_position.x, c.global_position.y, c.global_position.z])})
	hp_label.text = "P1 Bulbasaur: %d/%d    P2 Charmander: %d/%d    NPC Rattata: %d/%d" % [fighters[0].hp, fighters[0].max_hp, fighters[1].hp, fighters[1].max_hp, fighters[2].hp, fighters[2].max_hp]

func _local_move() -> Vector2:
	return Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))).limit_length()

func _capture():
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://arena.png")

func _intent() -> Dictionary:
	var v = _local_move()
	var slot = 0 if Input.is_physical_key_pressed(KEY_1) else -1
	if auto_test:
		var me = fighters[0 if role == "host" else 1]
		var diff = fighters[2].global_position - me.global_position
		v = Vector2(diff.x, diff.z).normalized() if diff.length() > 1.2 else Vector2.ZERO
		slot = 0 if Time.get_ticks_msec() - started_ms > 800 else -1
		if test_case == "lose":
			v = Vector2.ZERO
			slot = -1
	return {"move": v, "world": true, "sprint": Input.is_physical_key_pressed(KEY_SHIFT), "slot": slot}

func _apply_input(index: int, intent: Dictionary):
	if fighters[index].alive():
		fighters[index].combat.remote_intent = intent

@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func _input_packet(number: int, intent: Dictionary):
	if role != "host" or phase != "fighting" or multiplayer.get_remote_sender_id() != remote_id or number <= received_seq: return
	if not intent.get("move") is Vector2: return
	var v: Vector2 = intent.move
	if not is_finite(v.x) or not is_finite(v.y): return
	received_seq = number
	last_seen = Time.get_ticks_msec()
	_apply_input(1, {"move": v.limit_length(), "world": true, "sprint": bool(intent.get("sprint", false)), "slot": clampi(int(intent.get("slot", -1)), -1, 0)})

@rpc("authority", "call_remote", "unreliable_ordered", 2)
func _snapshot(number: int, data: Array):
	if role != "guest" or phase != "fighting" or number <= applied_snap or data.size() != 3: return
	applied_snap = number
	last_seen = Time.get_ticks_msec()
	for i in 3:
		Proto.apply_fighter(fighters[i], data[i])
		fighters[i].global_position = data[i].pos
		fighters[i].velocity = data[i].vel
		fighters[i].facing = data[i].facing
		if fighters[i].hp <= 0: fighters[i].mode = CreatureDef.Mode.FAINTED
	_log("snapshot_applied", {"snapshot": number, "hp": fighters.map(func(c): return c.hp)})

func _on_move(user, move):
	if role != "host" or phase != "fighting" or not fighters.has(user): return
	var index = fighters.find(user)
	_event.rpc_id(remote_id, index, String(move.get("id", "")), user.facing)
	_log("move", {"player": index, "move": move.get("id", "")})

@rpc("authority", "call_remote", "reliable")
func _event(index: int, move: String, facing: Vector3):
	if role == "guest" and phase == "fighting" and index >= 0 and index < 3:
		Moves.replay(fighters[index], move, facing)

func _on_hit(user, target, info):
	if role != "host" or phase != "fighting": return
	var index = fighters.find(user)
	if index >= 0 and index < 2 and target == fighters[2]:
		hit_counts[index] += 1
		damage_counts[index] += int(info.get("damage", 0))
	_log("hit", {"attacker": index, "target": fighters.find(target), "damage": info.get("damage", 0)})

@rpc("any_peer", "call_remote", "reliable")
func _abort():
	if role == "host" and multiplayer.get_remote_sender_id() == remote_id: _finish("aborted")

func _peer_disconnected(id):
	if role == "host" and id == remote_id:
		remote_id = 0
		_finish("disconnected")

@rpc("authority", "call_remote", "reliable")
func _end_packet(outcome: String, hp: Array):
	if role == "guest":
		for i in mini(hp.size(), fighters.size()): fighters[i].hp = int(hp[i])
		_finish(outcome)

func _finish(outcome: String):
	if phase == "ended": return
	result = outcome
	var hp = fighters.map(func(c): return c.hp)
	if role == "host" and remote_id != 0 and peer != null and multiplayer.get_peers().has(remote_id):
		_end_packet.rpc_id(remote_id, outcome, hp)
	phase = "ended"
	ended_ms = Time.get_ticks_msec()
	Battle.clear_move_fields()
	Battle.in_battle = false
	Battle.online = false
	Battle.online_guest = false
	Battle.challenge = false
	Battle.no_capture = false
	Battle.no_whiteout = false
	Battle.partner = null
	Battle.wild = null
	Battle.allies = []
	Battle._combatants.clear()
	Battle.trainer_battle = {}
	Battle.arena_rect = Rect2()
	for c in fighters:
		c.reset_battle_mods()
		c.mode = CreatureDef.Mode.IDLE
		c.opponent = null
		c.velocity = Vector3.ZERO
		c.remove_from_group("combatant")
	var me = fighters[0 if role == "host" else 1] if fighters.size() >= 2 else null
	if me != null: me.global_position = lobby_position
	status_label.text = "Sessao encerrada: %s | fora da arena; WASD livre | F10 fecha" % outcome
	_log("ended", {"result": outcome, "hp": hp, "hits": hit_counts, "damage": damage_counts, "moved": moved, "battle_cleared": not Battle.in_battle, "save_enabled": SaveGame.enabled})

func _log(event: String, data: Dictionary = {}):
	var row = {"event": event, "ms": Time.get_ticks_msec(), "role": role}
	row.merge(data)
	var line = JSON.stringify(row)
	print("[coop] ", line)
	if audit_file != null:
		audit_file.store_line(line)
		audit_file.flush()
