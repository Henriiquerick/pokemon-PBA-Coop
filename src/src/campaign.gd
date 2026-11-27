extends Node
const CreatureDef = preload("res://scripts/creature.gd")
const MonDef = preload("res://scripts/stats/mon.gd")
const Proto = preload("res://scripts/net/battle_proto.gd")
const Sprites = preload("res://scripts/pokemon_sprites.gd")
const CombatDef = preload("res://scripts/combat/combatant.gd")
const ArenaDef = preload("res://scripts/battle_arena.gd")
const Trainers = preload("res://scripts/trainers.gd")
const PicnicDef = preload("res://scripts/world/picnic.gd")
const WORLD = "res://scenes/world/overworld.tscn"
const PEWTER_INTERIORS = "res://scenes/interiors/pewter_city_interiors.tscn"
const PROTOCOL = "pba-campaign-lan-9-personal"
var phase = "boot"
var role = "host"
var ip = "127.0.0.1"
var port = 24620
var auto_test = false
var test_case = "win"
var peer: ENetMultiplayerPeer
var remote_id = 0
var remote_mon: Dictionary = {}
var remote_avatar: Node3D
var remote_sprite: Sprite3D
var remote_companion: Node3D
var remote_companion_species = ""
var remote_picnic: Node3D
var weather_sync_ms = 0
var player: Node3D
var chosen_slot = -1
var own_mon: Dictionary = {}
var fighters: Array = []
var guest_body
var trainer
var battle_opts: Dictionary = {}
var saved_state: Dictionary = {}
var saved_pos = Vector3.ZERO
var saved_row = 0
var freeze: Array = []
var battle_number = 0
var battle_started_ms = 0
var world_started_ms = 0
var last_seen = 0
var seq = 0
var last_seq = -1
var snap = 0
var applied = -1
var send_t = 0.0
var label: Label
var audit: FileAccess
var result = ""
var ending = false
var launching = false
var peer_ready = false
var hits = [0,0]
var damage = [0,0]
var initial_pos: Array = []
var moved = [false,false]
var return_ms = 0
var repeat_count = 0
var closing = false
var pending_input: Dictionary = {}
var last_heartbeat = 0
var capture_done = false
var guest_arena: Node3D
var remote_prepared = false
var remote_rejected = false
var abort_reason = ""
var enemy_instance = 0
var switching_foe = false
var switching_slots: Dictionary = {}
var next_foe_index = 2
var foe_instances: Array = []
var encounter_mons: Array = []
var auto_edge_ms = 0
var return_logged = false
var pad_down = false
var pad_pulse_ms = 0
var pad_log_ms = 0
var approach_log_ms = 0
var target_trainer = "youngster_ryan"
var start_area = "route2"
var local_area = "route2"
var return_scene = ""
var return_pos = Vector3.ZERO
var return_row = 0
var auto_travel_started = false
var wild_test_stage = 0
var wild_live_ms = 0
var remote_wild_logged = false
var remote_zone = ""
var remote_busy = false
var route_trainers: Array = []
var captures: Dictionary = {}
var prepare_started_ms = 0
var presence_log_ms = 0

func _ready():
	process_priority = -20
	SaveGame.enabled = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--coop-role="): role = a.get_slice("=",1)
		if a.begins_with("--coop-ip="): ip = a.get_slice("=",1)
		if a.begins_with("--coop-port="): port = int(a.get_slice("=",1))
		if a == "--coop-autotest": auto_test = true
		if a.begins_with("--coop-test="): test_case = a.get_slice("=",1)
		if a.begins_with("--coop-trainer="): target_trainer = a.get_slice("=",1)
		if a.begins_with("--coop-start="): start_area = a.get_slice("=",1)
	local_area = ("brock" if role == "host" else "route2") if start_area == "split" else start_area
	var map_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/route_2.json"))
	for t in map_data.trainers: route_trainers.append(String(t.id))
	route_trainers.append_array(["brock","camper_liam","hiker_dudley"])
	audit = FileAccess.open("user://campaign_audit.jsonl",FileAccess.WRITE)
	Input.joy_connection_changed.connect(func(device,connected): _log("gamepad_connection",{"device":device,"connected":connected,"name":Input.get_joy_name(device) if connected else ""}))
	_log("mod_initialized", {"engine":Engine.get_version_info().string,"pads":Input.get_connected_joypads()})
	_boot.call_deferred()

func _boot():
	Game.state.reset_new_game()
	var imported: Dictionary = {}
	if FileAccess.file_exists("user://campaign_input.json"):
		var d = SaveGame.peek_file("user://campaign_input.json")
		if d.is_empty():
			_log("invalid_save")
			get_tree().quit(2)
			return
		Game.state.from_dict(d.state)
		imported = d
		_log("save_copy_loaded")
	else:
		if not auto_test:
			_log("save_required")
			get_tree().quit(6)
			return
		var species = ("Squirtle" if role == "host" else "Bulbasaur") if start_area in ["brock","split"] else ("Bulbasaur" if role == "host" else "Charmander")
		var test_level = 30 if start_area in ["brock","split"] else (20 if auto_test and test_case == "slot1" else 12)
		var moves = (["water_gun"] if role == "host" else ["vine_whip"]) if start_area in ["brock","split"] else (["tackle"] if role == "host" else ["scratch"])
		Game._apply_checkpoint({"party":[[species,test_level,moves]],"trainer_level":5,"flags":["has_parcel","parcel_delivered","has_pokedex"]})
		_log("test_save_created",{"species":species})
	for mon in Game.party: mon.ensure_ot_id(Game.state.trainer_id,Game.state.player_name)
	chosen_slot = Game.state.first_healthy()
	if chosen_slot < 0:
		_log("no_healthy_pokemon")
		get_tree().quit(3)
		return
	own_mon = Game.party[chosen_slot].to_dict()
	SaveGame.enabled = false
	var scene_path = String(imported.get("scene",WORLD)) if local_area == "save" else (PEWTER_INTERIORS if local_area == "brock" else WORLD)
	var spawn_name = String(imported.get("spawn","")) if local_area == "save" else ("pw_gym_in" if local_area == "brock" else "r2_trainer_trial")
	if not ResourceLoader.exists(scene_path):
		_log("save_scene_missing",{"scene":scene_path})
		get_tree().quit(7)
		return
	await Transitions.go_to(scene_path,spawn_name,true,0.0)
	player = Dialogue.player()
	if player == null:
		_log("missing_campaign_player")
		get_tree().quit(4)
		return
	if local_area == "save":
		var saved_at = imported.get("pos",[])
		if saved_at is Array and saved_at.size() == 3:
			player.global_position = Vector3(float(saved_at[0]),float(saved_at[1]),float(saved_at[2]))
			player.row = clampi(int(imported.get("row",0)),0,3)
			player.sprite.frame = player.row * 3
		_log("save_position_loaded",{"scene":scene_path,"zone":String(Game.event_zone(player)),"party_count":Game.party.size()})
	elif local_area == "brock":
		var marker = get_tree().current_scene.find_child("GymArenaCenter",true,false)
		if marker == null:
			_log("missing_gym_marker")
			get_tree().quit(5)
			return
		player.global_position = marker.global_position + Vector3(-2 if role == "host" else -4,0,5)
		target_trainer = "brock"
	else:
		player.global_position = Vector3(-4 if role == "host" else -6,0,-232)
	player.global_position.y = Transitions.ground_y(player.global_position,0)
	Transitions.reset_interp(player)
	Game.cutscene = false
	Game.talking = false
	player.controls_enabled = true
	if auto_test and test_case == "out_lead" and role == "host": await Game.send_out(0)
	if auto_test and test_case == "picnic" and role == "host":
		await PicnicDef.prepare_assets()
		var test_picnic = PicnicDef.new()
		test_picnic.set_process(false)
		player.get_parent().add_child(test_picnic)
		test_picnic._player = player
		test_picnic._started = true
		test_picnic.global_position = player.global_position
		test_picnic._build_prop()
		test_picnic.add_to_group("picnic")
	var layer = CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	label = Label.new()
	label.position = Vector2(18,90)
	layer.add_child(label)
	label.text = "LAN campanha / %s / aguardando parceiro / %s" % [role,"carregado do save" if local_area == "save" else ("Brock: converse no ginasio" if local_area == "brock" else "Ryan perto do Rattata")]
	var fixture = SaveGame.snapshot()
	fixture["game_version"] = "0.6.2a"
	var f = FileAccess.open("user://campaign_test_snapshot.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(fixture))
	_log("save_guard",{"write_allowed":SaveGame.save_now()})
	_log("campaign_ready",{"scene":get_tree().current_scene.scene_file_path,"pos":player.global_position,"trainers":_trainer_ids(),"input_move_events":InputMap.action_get_events("move_left").size()})
	if "--coop-smoke" in OS.get_cmdline_user_args():
		get_tree().quit()
		return
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(port,1) if role == "host" else peer.create_client(ip,port)
	if err != OK:
		_log("network_error",{"code":err})
		phase = "offline"
		label.text = "Falha de rede %d; mapa local liberado" % err
		return
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_left)
	multiplayer.connected_to_server.connect(func(): _hello.rpc_id(1,PROTOCOL,own_mon))
	multiplayer.connection_failed.connect(func(): _disconnect("connection_failed"))
	multiplayer.server_disconnected.connect(func(): _disconnect("disconnected"))
	multiplayer.multiplayer_peer = peer
	Moves.move_released.connect(_on_move)
	Moves.hit_landed.connect(_on_hit)
	phase = "world"
	world_started_ms = Time.get_ticks_msec()
	last_seen = world_started_ms

func _trainer_ids() -> Array:
	var ids: Array = []
	for n in get_tree().get_nodes_in_group("npc"):
		if n.get("trainer_id") != null: ids.append(n.trainer_id)
	return ids

func can_trigger(t) -> bool:
	return t != null and role == "host" and phase == "world" and peer_ready and not remote_busy and not Battle.in_battle and remote_zone in ["route_2","pewter_gym"] and t.trainer_id in route_trainers and not t._beaten() and t._gate_open() and Time.get_ticks_msec() - return_ms > 5000

func allow_solo_wild() -> bool:
	return phase in ["world","offline"] and not launching

func coop_battle_active() -> bool:
	return phase in ["prepare","fighting","ending","returning"] or launching

func blocks_trainer(t) -> bool:
	return not can_trigger(t)

func allow_campaign_battle() -> bool:
	return launching

func _peer_connected(id):
	if role == "host": remote_id = id

@rpc("any_peer","call_remote","reliable")
func _hello(protocol: String, mon: Dictionary):
	if role != "host" or multiplayer.get_remote_sender_id() != remote_id: return
	if protocol != PROTOCOL or not _valid_mon(mon):
		peer.disconnect_peer(remote_id)
		return
	remote_mon = mon
	peer_ready = true
	_welcome.rpc_id(remote_id,PROTOCOL,own_mon)
	_connected_world()

@rpc("authority","call_remote","reliable")
func _welcome(protocol: String, mon: Dictionary):
	if role != "guest" or protocol != PROTOCOL or not _valid_mon(mon): return
	remote_mon = mon
	remote_id = 1
	peer_ready = true
	_connected_world()

func _valid_mon(d: Dictionary) -> bool:
	return d.get("species","") is String and d.has("level") and int(d.get("hp",0)) > 0 and d.get("moves",[]) is Array

func _connected_world():
	last_seen = Time.get_ticks_msec()
	closing = false
	phase = "world"
	remote_zone = ""
	remote_busy = true
	_log("connected",{"peer":remote_id,"own_species":own_mon.get("species"),"other_species":remote_mon.get("species")})
	_make_remote_avatar()
	label.text = "LAN conectada / %s / batalhas selvagens locais" % [role]

func _make_remote_avatar():
	if not is_instance_valid(player) or get_tree().current_scene == null: return
	if is_instance_valid(remote_avatar): remote_avatar.queue_free()
	remote_avatar = Node3D.new()
	get_tree().current_scene.add_child(remote_avatar)
	remote_sprite = player.sprite.duplicate() as Sprite3D
	remote_avatar.add_child(remote_sprite)
	remote_sprite.modulate = Color(0.6,0.85,1)
	var tag = Label3D.new()
	tag.text = "PARCEIRO LAN"
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position.y = 2.1
	remote_avatar.add_child(tag)

func _process(delta):
	SaveGame.enabled = false
	if phase == "boot": return
	var now = Time.get_ticks_msec()
	if peer_ready and now - last_heartbeat > 500:
		last_heartbeat = now
		_ping.rpc_id(remote_id)
	if peer_ready and now - last_seen > 45000:
		_disconnect("timeout")
	if not is_instance_valid(player):
		player = Dialogue.player()
		if player == null: return
		if peer_ready:
			_make_remote_avatar()
			_log("map_rebound",{"scene":get_tree().current_scene.scene_file_path,"zone":String(Game.event_zone(player))})
	if auto_test and DisplayServer.get_name() != "headless":
		if phase == "world" and peer_ready and return_ms == 0 and now - world_started_ms > 1500: _request_capture("world")
		if phase == "fighting" and now - battle_started_ms > 1400: _request_capture("battle")
		if return_ms > 0 and now - return_ms > 500: _request_capture("return")
	if Input.is_physical_key_pressed(KEY_F10): get_tree().quit()
	if phase in ["world","offline"]:
		if auto_test: _auto_world(now)
		if phase == "world" and peer_ready:
			if role == "host" and now - weather_sync_ms > 5000:
				weather_sync_ms = now
				var weather = get_tree().get_first_node_in_group("weather")
				if weather != null: _weather_sync.rpc_id(remote_id,weather.to_dict())
			send_t += delta
			if send_t >= 0.05:
				send_t = 0
				var out_mon = {}
				for i in Game.companions:
					var c = Game.companions[i]
					if is_instance_valid(c) and c.visible and c.mon != null:
						out_mon = {"species":c.species,"level":c.level,"at":c.global_position,"facing":c.facing}
						break
				var picnic_at = Vector3.INF
				for p in get_tree().get_nodes_in_group("picnic"):
					if p.get("_player") == player and p.get("_started") == true:
						picnic_at = p.global_position
						break
				_presence.rpc_id(remote_id,player.global_position,player.row,player.sprite.frame,String(Game.event_zone(player)),out_mon,picnic_at,Battle.in_battle or Game.is_busy())
		return
	if phase not in ["prepare","fighting","ending"]: return
	player.controls_enabled = false
	if auto_test and test_case == "prepare_drop_" + role and phase == "prepare" and now - prepare_started_ms > 1200:
		_log("injected_exit")
		get_tree().quit()
	if Input.is_physical_key_pressed(KEY_F8):
		if role == "host" and Battle.in_battle: Battle.end_battle("aborted")
		elif role == "guest": _abort.rpc_id(1)
	if auto_test and test_case == "drop_" + role and now - battle_started_ms > 2400 and phase == "fighting":
		_log("injected_exit")
		get_tree().quit()
	if role == "host" and phase in ["prepare","fighting"]:
		_update_host_fighters()
		if not peer_ready and Battle.in_battle and not Battle._ending: Battle.end_battle("aborted")
		if phase == "fighting":
			if is_instance_valid(guest_body):
				guest_body.combat.remote_intent.slot = int(pending_input.get("slot",-1))
				guest_body.combat.remote_intent.jump = bool(pending_input.get("jump",false))
				guest_body.combat.remote_intent.evade = bool(pending_input.get("evade",false))
				pending_input.clear()
			if auto_test:
				if fighters.size() == 4: _apply_auto(fighters[0])
			if fighters.size() == 4:
				for i in 2: moved[i] = moved[i] or fighters[i].global_position.distance_to(initial_pos[i]) > 0.25
				var living = [fighters[0],fighters[1]].filter(func(c): return is_instance_valid(c) and c.alive())
				if living.is_empty() and not Battle._ending: Battle.end_battle("lost")
				else:
					for foe in Battle.foes():
						if not is_instance_valid(foe.opponent) or not foe.opponent.alive(): foe.opponent = living[0]
				if auto_test and test_case == "slot1" and Battle.foes().size() > 1:
					guest_body.opponent = Battle.foes()[-1]
					Battle.partner.opponent = Battle.foes()[0]
			if auto_test and test_case == "abort" and now - battle_started_ms > 3000: Battle.end_battle("aborted")
		send_t += delta
		if peer_ready and phase == "fighting" and fighters.size() == 4 and send_t >= 0.05:
			send_t = 0
			snap += 1
			var data = fighters.map(func(c): return Proto.snap_fighter(c,0) if is_instance_valid(c) else {"missing":true})
			_battle_snapshot.rpc_id(remote_id,battle_number,snap,data)
			if snap <= 15 or snap % 10 == 0: _log("snapshot_sent",{"seq":snap,"hp":data.map(func(d): return d.get("hp",0))})
	elif role == "guest" and phase == "fighting" and fighters.size() == 4:
		if auto_test and test_case == "pad": _inject_pad(_auto_intent(fighters[1]).move,true)
		var it = fighters[1].combat.read_local_intent()
		if auto_test and test_case != "pad":
			it = _auto_intent(fighters[1])
			if now - auto_edge_ms < 350: it.slot = -1
			else: auto_edge_ms = now
		if auto_test and test_case == "pad" and now - pad_log_ms > 700:
			pad_log_ms = now
			_log("synthetic_pad_read",{"move":it.move,"slot":it.slot,"host_control":"separate_process","connected_physical_pads":Input.get_connected_joypads()})
		# Edges travel reliably; movement has a separate ordered channel.
		if it.slot >= 0 or it.jump or it.evade:
			_edge.rpc_id(1,battle_number,int(it.slot),bool(it.jump),bool(it.evade))
		send_t += delta
		if send_t >= 1.0/30.0:
			send_t = 0
			seq += 1
			var w = CombatDef.stick_to_world(it.move,float(Dialogue.camera_rig()._yaw_off))
			_intent.rpc_id(1,battle_number,seq,w,bool(it.sprint))

@rpc("any_peer","call_remote","unreliable_ordered",1)
func _presence(at: Vector3,row: int,frame: int,zone: String,mon: Dictionary,picnic_at: Vector3,busy: bool):
	if multiplayer.get_remote_sender_id() != remote_id or not at.is_finite(): return
	last_seen = Time.get_ticks_msec()
	remote_zone = zone
	remote_busy = busy
	if auto_test and test_case == "wild" and busy and not remote_wild_logged:
		remote_wild_logged = true
		_log("remote_wild_busy",{"zone":zone})
	if phase == "world" and is_instance_valid(remote_avatar):
		remote_avatar.visible = not busy and not Battle.in_battle and zone == String(Game.event_zone(player))
		remote_avatar.global_position = at
		remote_sprite.frame = clampi(frame,0,remote_sprite.hframes * remote_sprite.vframes - 1)
		_sync_companion(mon,remote_avatar.visible)
		_sync_picnic(picnic_at,remote_avatar.visible)
		var now = Time.get_ticks_msec()
		if now - presence_log_ms > 1000:
			presence_log_ms = now
			_log("presence",{"pos":at,"row":row,"zone":zone})

@rpc("authority","call_remote","reliable")
func _weather_sync(state: Dictionary):
	if role != "guest" or phase != "world": return
	var weather = get_tree().get_first_node_in_group("weather")
	if weather != null and state.has("cells"):
		weather.from_dict(state)
		_log("weather_synced",{"cells":state.cells.size()})

func _sync_companion(mon: Dictionary,shown: bool):
	var species = String(mon.get("species",""))
	if species == "" or not shown:
		if is_instance_valid(remote_companion): remote_companion.hide()
		return
	if not is_instance_valid(remote_companion) or species != remote_companion_species:
		if is_instance_valid(remote_companion): remote_companion.queue_free()
		remote_companion_species = species
		remote_companion = Encounters.spawn_mon(MonDef.create(species,int(mon.get("level",1))),player.get_parent(),mon.at,false)
		remote_companion.mode = CreatureDef.Mode.PUPPET
		remote_companion.collision_layer = 0
		remote_companion.collision_mask = 0
		remote_companion.remove_from_group("wild")
		_log("remote_companion_visible",{"species":species})
	remote_companion.show()
	remote_companion.global_position = mon.at
	remote_companion.facing = mon.get("facing",Vector3.FORWARD)

func _sync_picnic(at: Vector3,shown: bool):
	if not at.is_finite() or not shown:
		if is_instance_valid(remote_picnic): remote_picnic.hide()
		return
	if not is_instance_valid(remote_picnic):
		remote_picnic = PicnicDef.new()
		remote_picnic.set_process(false)
		player.get_parent().add_child(remote_picnic)
		await PicnicDef.prepare_assets()
		if not is_instance_valid(remote_picnic): return
		remote_picnic._build_prop()
		_log("remote_picnic_visible")
	remote_picnic.global_position = at
	remote_picnic.show()

@rpc("any_peer","call_remote","unreliable",3)
func _ping():
	if multiplayer.get_remote_sender_id() == remote_id: last_seen = Time.get_ticks_msec()

func _auto_world(now):
	if test_case == "wild" and role == "guest" and now - world_started_ms > 25000:
		get_tree().quit()
		return
	if test_case == "wild" and role == "host" and wild_test_stage == 4 and now - wild_live_ms > 6500:
		get_tree().quit()
		return
	if return_ms > 0:
		player.debug_move = (Vector2.RIGHT if role == "host" else Vector2(0,0.5)) if start_area == "brock" and repeat_count > 1 else (Vector2.LEFT if saved_pos.x > 0 else Vector2.RIGHT)
		if test_case == "travel" and start_area == "split" and role == "host" and now - return_ms > 2400 and not auto_travel_started:
			auto_travel_started = true
			_auto_travel.call_deferred()
		if now - return_ms > 1700:
			if not return_logged:
				return_logged = true
				_log("return_control",{"enabled":player.controls_enabled,"moved":player.global_position.distance_to(saved_pos)>0.2,"battle":Battle.in_battle,"trainer_defeated":Game.flags.get("trainer_youngster_ryan",false),"money":Game.state.money})
			if test_case == "repeat" and repeat_count < 2 and phase == "world" and peer_ready:
				if now - return_ms > 5200:
					if start_area == "brock":
						var marker = get_tree().current_scene.find_child("GymArenaCenter",true,false)
						if marker != null:
							player.global_position = marker.global_position + Vector3(-2 if role == "host" else -4,0,5)
							player.global_position.y = Transitions.ground_y(player.global_position,0)
							Transitions.reset_interp(player)
					return_ms = 0
					world_started_ms = now - 3000
					player.debug_move = Vector2.ZERO
			elif start_area != "split" or now - return_ms > 12000: get_tree().quit()
		return
	if not peer_ready: return
	if test_case == "wild":
		_auto_wild(now)
		return
	# Real campaign player movement before the normal trainer sight trigger.
	if now - world_started_ms < 2200:
		player.debug_move = Vector2(0,0.5 if role == "host" else -0.5)
		if test_case == "pad":
			player.debug_move = Vector2.ZERO
			if role == "guest": _inject_pad(Vector2(0,-0.5),false)
	else:
		player.debug_move = Vector2.ZERO
		if test_case == "pad" and role == "guest": _inject_pad(Vector2.ZERO,false)
		if role == "host" and can_trigger(_find_trainer(target_trainer)):
			var t = _find_trainer(target_trainer)
			if target_trainer == "brock":
				t._battle_sequence(false)
				return
			player.global_position = Vector3(-3,0,-236) if target_trainer == "youngster_ryan" else t.global_position + Vector3(0,0,2.0)
			player.global_position.y = Transitions.ground_y(player.global_position,0)
			# can_see -> _spot_sequence -> trainer hook; no direct battle invocation.
			if now - approach_log_ms > 1000:
				approach_log_ms = now
				_log("approached_trainer",{"id":t.trainer_id,"can_see":t.can_see(player)})

func _auto_wild(now: int):
	player.debug_move = Vector2.ZERO
	if role == "guest":
		if now - world_started_ms > 25000: get_tree().quit()
		return
	if wild_test_stage == 0 and now - world_started_ms > 1800:
		wild_test_stage = 1
		_log("wild_requested")
		Encounters.grass_encounter(player,"res://data/encounters/route_2.json")
	elif wild_test_stage == 1 and Battle.in_battle and not Battle._intro:
		wild_test_stage = 2
		wild_live_ms = now
		_log("wild_started",{"foes":Battle.foes().size(),"allies":Battle.allies.size(),"connected":peer_ready})
	elif wild_test_stage == 2 and now - wild_live_ms > 1500:
		wild_test_stage = 3
		Battle.end_battle("aborted")
	elif wild_test_stage == 3 and not Battle.in_battle:
		wild_test_stage = 4
		_log("wild_return",{"controls":player.controls_enabled,"connected":peer_ready,"zone":String(Game.event_zone(player))})
	elif wild_test_stage == 4 and now - wild_live_ms > 6500:
		get_tree().quit()

func _auto_travel():
	await Transitions.go_to(WORLD,"r2_trainer_trial",true,0.0)
	_log("travel_done",{"scene":get_tree().current_scene.scene_file_path,"connected":peer_ready,"zone":String(Game.event_zone(player)) if is_instance_valid(player) else "missing_player"})

func _inject_pad(world_move: Vector2,attack: bool):
	var local = world_move.rotated(deg_to_rad(float(Dialogue.camera_rig()._yaw_off)))
	for axis in [JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y]:
		var e = InputEventJoypadMotion.new()
		e.device = 0
		e.axis = axis
		e.axis_value = local.x if axis == JOY_AXIS_LEFT_X else local.y
		Input.parse_input_event(e)
	var now = Time.get_ticks_msec()
	if pad_down or (attack and now - pad_pulse_ms > 400):
		var e = InputEventJoypadButton.new()
		e.device = 0
		e.button_index = JOY_BUTTON_A
		e.pressed = not pad_down and attack
		pad_down = e.pressed
		if pad_down: pad_pulse_ms = now
		Input.parse_input_event(e)

func _find_trainer(id: String):
	for n in get_tree().get_nodes_in_group("npc"):
		if n.get("trainer_id") == id: return n
	return null

func trainer_encounter(t) -> String:
	return await _host_encounter(t)

func _balanced_mons(t, original: Array) -> Array:
	# Only the LAN encounter receives the extra mon; trainer data and solo stay intact.
	if original.size() % 2 == 0: return original
	var gym_partner = {"brock":"Sandshrew", "erika":"Gloom", "surge":"Magnemite", "blaine":"Ponyta", "giovanni_gym":"Sandslash"}
	var klass = String(t._def.get("class",""))
	var type_partner = {"bug_catcher":"Weedle", "youngster":"Pidgey", "lass":"Nidoran F", "hiker":"Geodude", "swimmer":"Staryu", "super_nerd":"Magnemite", "picnicker":"Oddish", "camper":"Sandshrew"}
	var last = original.back()
	var species = String(gym_partner.get(t.trainer_id,type_partner.get(klass,last.species)))
	var added = MonDef.create(species,int(last.level))
	original.append(added)
	_log("roster_balanced",{"id":t.trainer_id,"added":species,"level":added.level,"count":original.size()})
	return original

func deploy_second_foe(t, mon, first_at: Vector3) -> void:
	var offset = Vector3(2.1,0,-0.4)
	var at: Vector3 = first_at + offset
	var rect = Battle._trainer_rect(Battle.trainer_battle)
	at = Battle.nearest_ok(at,mon,rect,Battle._blocked_at(at.y))
	at.y = Transitions.ground_y(at,first_at.y)
	await Battle._throw_pose(t,at)
	await Game._throw_ball(t.global_position + Vector3(0,1,0),at)
	await Sprites.prepare_species(mon.species)
	await Sprites.load_full(mon.species,mon.shiny)
	if not peer_ready or not launching: return
	var body = Encounters.spawn_mon(mon,player.get_parent(),at,true)
	body.remove_from_group("wild")
	body.combat.is_trainer_mon = true
	body.set_meta("add_ai_tier",String(battle_opts.get("ai_tier","low")))
	Battle.extra_foes.append(body)
	Vfx.send_out_reveal(body)
	Audio.cry(body.species,at)
	Battle.trainer_callout(t,"GO! %s!" % body.species.to_upper(),String(mon.ball))
	_log("second_foe_deployed",{"species":body.species,"at":at})

func _host_encounter(t) -> String:
	trainer = t
	phase = "prepare"
	label.text = "BATALHA LAN: %s desafia voces! Preparando a arena..." % t.npc_name
	prepare_started_ms = Time.get_ticks_msec()
	ending = false
	abort_reason = ""
	remote_prepared = false
	remote_rejected = false
	chosen_slot = Game.state.first_healthy()
	if chosen_slot < 0:
		phase = "world"
		return "aborted"
	own_mon = Game.party[chosen_slot].to_dict()
	_capture_local()
	battle_number += 1
	repeat_count += 1
	hits = [0,0]
	damage = [0,0]
	moved = [false,false]
	snap = 0
	last_seq = -1
	pending_input.clear()
	var base_mons = t._mons()
	if auto_test and test_case == "odd": base_mons = base_mons.slice(0,1)
	encounter_mons = _balanced_mons(t,base_mons)
	if auto_test and test_case in ["waves","slot1"]:
		encounter_mons.append(MonDef.create("Rattata",8))
		encounter_mons.append(MonDef.create("Pidgey",8))
	next_foe_index = 2
	switching_slots.clear()
	foe_instances = [0,0]
	battle_opts = t._battle_opts(player)
	battle_opts["arena"] = Vector2(maxf(battle_opts.get("arena",Vector2(10,6)).x,12.0),maxf(battle_opts.get("arena",Vector2(10,6)).y,10.0))
	battle_opts["online"] = true
	battle_opts["challenge"] = true
	battle_opts["scripted"] = true
	battle_opts["versus"] = {}
	battle_opts["intro_text"] = "LAN co-op: %s" % t.npc_name
	battle_opts["trainer_id"] = t.trainer_id
	battle_opts["ai_tier"] = String(t._def.get("ai_tier","low"))
	battle_opts["defeat"] = []
	battle_opts["lose"] = []
	battle_opts["roster"] = 0
	_begin_encounter.rpc_id(remote_id,battle_number,t.trainer_id,get_tree().current_scene.scene_file_path,battle_opts.center,battle_opts.arena,own_mon,encounter_mons.map(func(m): return m.to_dict()))
	_log("encounter_requested",{"id":t.trainer_id,"roster":encounter_mons.map(func(m): return m.species),"number":battle_number})
	var until = Time.get_ticks_msec() + 60000
	while not remote_prepared and not remote_rejected and peer_ready and Time.get_ticks_msec() < until: await get_tree().process_frame
	if remote_rejected or not remote_prepared or not peer_ready:
		_finish_local("aborted")
		return "aborted"
	var remote = MonDef.from_dict(remote_mon)
	await Sprites.prepare_species(remote.species)
	await Sprites.load_full(remote.species,remote.shiny)
	if not peer_ready or phase != "prepare":
		_finish_local("disconnected")
		return "aborted"
	guest_body = Encounters.spawn_mon(remote,player.get_parent(),battle_opts.center + Vector3(-2,0,2),false)
	guest_body.side = 0
	guest_body.set_meta("lan_remote",true)
	guest_body.mode = CreatureDef.Mode.IDLE
	guest_body.hide()
	Battle.guest_allies = [guest_body]
	Battle.no_capture = true
	Battle.no_whiteout = true
	launching = true
	if is_instance_valid(remote_avatar): remote_avatar.hide()
	var outcome = await Battle.start_trainer_battle(t,t.npc_name,encounter_mons,battle_opts)
	launching = false
	var final_hp = []
	# end_battle has already disposed guest/allies, so use the last authoritative audit.
	final_hp = _last_hp.duplicate()
	if peer_ready and multiplayer.get_peers().has(remote_id): _end_encounter.rpc_id(remote_id,battle_number,outcome,final_hp)
	_log("host_result",{"result":outcome,"hp":final_hp,"hits":hits,"damage":damage,"moved":moved,"number":battle_number})
	_finish_local(abort_reason if abort_reason != "" else outcome)
	return outcome

var _last_hp: Array = []

func _capture_local():
	return_logged = false
	saved_state = Game.state.to_dict().duplicate(true)
	saved_pos = player.global_position
	saved_row = player.row
	player.debug_move = Vector2.ZERO
	player.controls_enabled = false
	player.velocity = Vector3.ZERO
	Game.cutscene = false
	Game.talking = false
	var hud = Dialogue.hud()
	if hud != null: hud.close_menus()
	player.controls_enabled = false
	for n in Creatures._all.duplicate():
		if is_instance_valid(n):
			freeze.append([n,n.process_mode,n.visible])
			n.process_mode = Node.PROCESS_MODE_DISABLED
			n.hide()

@rpc("authority","call_remote","reliable")
func _begin_encounter(number: int,id: String,scene_path: String,center: Vector3,arena: Vector2,host_mon: Dictionary,roster: Array):
	if role != "guest" or id not in route_trainers or scene_path not in [WORLD,PEWTER_INTERIORS] or not center.is_finite(): return
	if phase != "world" or Battle.in_battle or Game.is_busy():
		_decline.rpc_id(1,number,"guest_busy")
		return
	return_scene = get_tree().current_scene.scene_file_path
	return_pos = player.global_position
	return_row = player.row
	phase = "prepare"
	prepare_started_ms = Time.get_ticks_msec()
	label.text = "BATALHA LAN: %s desafia voces! Preparando a arena..." % Trainers.display_name(id)
	var intro_hud = Dialogue.hud()
	if intro_hud: intro_hud.intro.bars(true)
	_log("guest_intro_started",{"id":id})
	battle_number = number
	abort_reason = ""
	ending = false
	_capture_local()
	if return_scene != scene_path:
		_log("join_map_started",{"from":return_scene,"to":scene_path,"return_pos":return_pos})
		if scene_path == WORLD:
			await Transitions.go_to(WORLD,"r2_trainer_trial",true,0.0)
		else:
			await Transitions.go_to_at(scene_path,center + Vector3(-5,0,3))
		player = Dialogue.player()
		if not is_instance_valid(player) or get_tree().current_scene.scene_file_path != scene_path:
			_abort.rpc_id(1)
			_disconnect("join_map_failed")
			return
		player.controls_enabled = false
		if not is_instance_valid(remote_avatar): _make_remote_avatar()
		_log("join_map_done",{"scene":scene_path,"pos":player.global_position})
	chosen_slot = Game.state.first_healthy()
	if chosen_slot < 0:
		_decline.rpc_id(1,number,"no_healthy_pokemon")
		_finish_local("no_healthy_pokemon")
		return
	own_mon = Game.party[chosen_slot].to_dict()
	remote_mon = host_mon
	battle_opts = {"center":center,"arena":arena,"trainer_id":id}
	encounter_mons = roster.map(func(d): return MonDef.from_dict(d))
	for m in [MonDef.from_dict(host_mon),Game.party[chosen_slot]] + encounter_mons:
		await Sprites.prepare_species(m.species)
		await Sprites.load_full(m.species,m.shiny)
	if not peer_ready or phase != "prepare" or number != battle_number: return
	player.global_position = center + Vector3(-5,0,3)
	player.global_position.y = Transitions.ground_y(player.global_position,center.y)
	Transitions.reset_interp(player)
	if is_instance_valid(remote_avatar): remote_avatar.hide()
	_log("encounter_received",{"id":id,"safe_position":player.global_position,"number":number})
	_prepared.rpc_id(1,number,own_mon)

@rpc("any_peer","call_remote","reliable")
func _prepared(number: int,mon: Dictionary):
	if role == "host" and multiplayer.get_remote_sender_id() == remote_id and number == battle_number and phase == "prepare" and _valid_mon(mon):
		remote_mon = mon
		remote_prepared = true

@rpc("any_peer","call_remote","reliable")
func _decline(number: int,reason: String):
	if role == "host" and multiplayer.get_remote_sender_id() == remote_id and number == battle_number and phase == "prepare":
		remote_rejected = true
		_log("encounter_declined",{"reason":reason})

func _update_host_fighters():
	if not Battle.in_battle or not is_instance_valid(guest_body): return
	# A lead already outside its ball was frozen with the overworld creatures.
	# Battle may reuse that same node, so restore it before reading input.
	if is_instance_valid(Battle.partner) and (Battle.partner.process_mode == Node.PROCESS_MODE_DISABLED or not Battle.partner.visible):
		Battle.partner.process_mode = Node.PROCESS_MODE_INHERIT
		Battle.partner.show()
		_log("host_lead_reactivated",{"species":Battle.partner.species})
	if auto_test and is_instance_valid(Battle.partner): Battle.partner.set_meta("lan_remote",true)
	var second = Battle.extra_foes[0] if not Battle.extra_foes.is_empty() else null
	if phase == "prepare" and not Battle._intro and is_instance_valid(Battle.partner) and is_instance_valid(Battle.wild):
		fighters = [Battle.partner,guest_body,Battle.wild,second]
		initial_pos = fighters.map(func(c): return c.global_position)
		foe_instances = [Battle.wild.get_instance_id(),second.get_instance_id() if is_instance_valid(second) else 0]
		phase = "fighting"
		battle_started_ms = Time.get_ticks_msec()
		_live.rpc_id(remote_id,battle_number,fighters.map(func(c): return c.mon.to_dict()),fighters.map(func(c): return c.global_position))
		_log("battle_started",{"number":battle_number,"id":trainer.trainer_id,"species":fighters.map(func(c): return c.species)})
	elif phase == "fighting":
		for slot in 2:
			var body = Battle.wild if slot == 0 else second
			if is_instance_valid(body) and body.get_instance_id() != foe_instances[slot]:
				fighters[slot+2] = body
				foe_instances[slot] = body.get_instance_id()
				if peer_ready: _replace_foe.rpc_id(remote_id,battle_number,slot,body.mon.to_dict(),body.global_position)
				_log("foe_replaced",{"species":body.species,"slot":slot,"index":next_foe_index-1})
	if fighters.size() == 4 and fighters.all(func(c): return is_instance_valid(c)):
		_last_hp = fighters.map(func(c): return c.hp)

@rpc("authority","call_remote","reliable")
func _live(number: int,mons: Array,positions: Array):
	if role != "guest" or phase != "prepare" or number != battle_number or mons.size() != 4 or positions.size() != 4: return
	fighters.clear()
	for i in 4: fighters.append(_puppet(MonDef.from_dict(mons[i]),positions[i],i))
	Battle.online = true
	Battle.online_guest = true
	Battle.in_battle = true
	Battle.challenge = true
	Battle.no_capture = true
	Battle.no_whiteout = true
	Battle._intro = false
	Battle._ending = false
	Battle.partner = fighters[1]
	Battle.allies = [fighters[0],fighters[1]]
	Battle.wild = fighters[2]
	Battle.extra_foes = [fighters[3]]
	Battle.arena_rect = Rect2(Vector2(battle_opts.center.x,battle_opts.center.z) - battle_opts.arena * 0.5,battle_opts.arena)
	Battle.trainer_battle = {"name":String(battle_opts.trainer_id),"mons":encounter_mons,"index":0,"total":encounter_mons.size(),"center":battle_opts.center,"arena":battle_opts.arena,"scripted":true}
	Controls.set_battle_dpad(true)
	fighters[0].opponent = fighters[2]
	fighters[1].opponent = fighters[2]
	fighters[2].opponent = fighters[1]
	fighters[3].opponent = fighters[0]
	guest_arena = ArenaDef.new()
	player.get_parent().add_child(guest_arena)
	guest_arena.setup(battle_opts.center,battle_opts.arena)
	Dialogue.camera_rig().focus_fixed(battle_opts.center,Battle._fit_cam_dist(battle_opts.arena))
	Audio.push_music("battle","music/battle_trainer",0.2)
	phase = "fighting"
	player.controls_enabled = false
	battle_started_ms = Time.get_ticks_msec()
	applied = -1
	Game.battle_started.emit(fighters[1],fighters[2])
	Vfx.send_out_reveal(fighters[1])
	var live_hud = Dialogue.hud()
	if live_hud:
		live_hud.intro.fight()
		live_hud.intro.bars(false)
	_log("guest_intro_finished",{"id":battle_opts.trainer_id})
	label.text = "BATALHA LAN: %s / dois adversarios ativos" % Trainers.display_name(String(battle_opts.trainer_id))
	_log("guest_entry_reveal",{"species":fighters[1].species})
	_log("battle_started",{"number":battle_number,"id":battle_opts.trainer_id,"species":fighters.map(func(c): return c.species),"trainer_controls":player.controls_enabled})

func _puppet(m,at: Vector3,index: int):
	var c = Encounters.spawn_mon(m,player.get_parent(),at,false)
	c.mode = CreatureDef.Mode.PUPPET
	c.side = 0 if index < 2 else 1
	c.collision_layer = 0
	c.collision_mask = 0
	c.add_to_group("combatant")
	return c

@rpc("authority","call_remote","reliable")
func _replace_foe(number: int,slot: int,mon: Dictionary,at: Vector3):
	if role != "guest" or number != battle_number or phase != "fighting" or slot not in [0,1]: return
	var index = slot + 2
	var old = fighters[index]
	fighters[index] = _puppet(MonDef.from_dict(mon),at,index)
	if slot == 0: Battle.wild = fighters[index]
	else: Battle.extra_foes = [fighters[index]]
	Battle.trainer_battle["index"] = int(Battle.trainer_battle.get("index",0)) + 1
	fighters[index].opponent = fighters[1]
	for a in fighters.slice(0,2):
		if a.opponent == old: a.opponent = fighters[index]
	if is_instance_valid(old): old.queue_free()
	_log("foe_replaced",{"species":mon.species,"slot":slot})

func fainted(c):
	if not launching or Battle._ending: return
	_last_hp = fighters.map(func(f): return f.hp if is_instance_valid(f) else 0)
	if c == Battle.wild or Battle.extra_foes.has(c):
		var slot = 0 if c == Battle.wild else 1
		_log("foe_fainted",{"slot":slot,"species":c.species,"next":next_foe_index})
		if switching_slots.has(slot): return
		switching_slots[slot] = true
		Battle._retarget_allies()
		await Battle._faint_beat(c)
		if not launching or not Battle.in_battle or Battle._ending:
			switching_slots.erase(slot)
			return
		if next_foe_index < encounter_mons.size():
			var next = next_foe_index
			next_foe_index += 1
			if slot == 0: await Battle._send_trainer_mon(next)
			else: await _replace_second_host(c,encounter_mons[next])
		elif Battle.foes().is_empty() and next_foe_index >= encounter_mons.size() and switching_slots.size() == 1:
			Battle.end_battle("won")
		switching_slots.erase(slot)

func _replace_second_host(old,mon) -> void:
	_log("second_replacement_begin",{"old":old.species if is_instance_valid(old) else "none","new":mon.species,"extras":Battle.extra_foes.size()})
	Battle.extra_foes.clear()
	Battle._combatants.erase(old)
	if is_instance_valid(old):
		old.queue_free()
	await get_tree().create_timer(0.65).timeout
	if not launching or not Battle.in_battle or Battle._ending: return
	var at = battle_opts.center + Vector3(2,0,-1)
	at.y = Transitions.ground_y(at,battle_opts.center.y)
	await Battle._throw_pose(trainer,at)
	await Game._throw_ball(trainer.global_position + Vector3(0,1,0),at)
	await Sprites.prepare_species(mon.species)
	await Sprites.load_full(mon.species,mon.shiny)
	if not launching or not Battle.in_battle or Battle._ending: return
	var body = Encounters.spawn_mon(mon,player.get_parent(),at,true)
	body.remove_from_group("wild")
	body.combat.is_trainer_mon = true
	body.set_meta("add_ai_tier",String(battle_opts.get("ai_tier","low")))
	Battle.extra_foes.append(body)
	_log("second_replacement_spawned",{"species":body.species,"extras":Battle.extra_foes.size()})
	Battle._prep_extra_foe(body,player)
	body.mode = CreatureDef.Mode.BATTLE_AI
	body.opponent = Battle.partner
	Vfx.send_out_reveal(body)
	Battle.trainer_callout(trainer,"GO! %s!" % body.species.to_upper(),String(mon.ball))

func _apply_auto(c):
	c.combat.remote_intent = _auto_intent(c)

func _auto_intent(c) -> Dictionary:
	var live = Battle.foes()
	var target = (live[-1] if test_case == "slot1" and role == "guest" else live[0]) if not live.is_empty() else null
	var to = target.global_position - c.global_position if is_instance_valid(target) else Vector3.ZERO
	return {"move":Vector2(to.x,to.z).normalized() if to.length()>1.0 else Vector2.ZERO,"world":true,"slot":0 if test_case != "lose" else -1,"sprint":false,"evade":false,"jump":false}

@rpc("authority","call_remote","unreliable_ordered",2)
func _battle_snapshot(number: int,sequence: int,data: Array):
	if role != "guest" or number != battle_number or phase != "fighting" or sequence <= applied or data.size() != 4: return
	for i in [2,3]:
		if not data[i].get("missing",false) and data[i].get("species","") != fighters[i].species: return
	applied = sequence
	last_seen = Time.get_ticks_msec()
	for i in 4:
		if data[i].get("missing",false): continue
		Proto.apply_fighter(fighters[i],data[i])
		fighters[i].global_position = data[i].pos
		fighters[i].velocity = data[i].vel
		fighters[i].facing = data[i].facing
		if fighters[i].hp <= 0 and fighters[i].mode != CreatureDef.Mode.FAINTED:
			fighters[i]._pmd_faint()
			fighters[i].mode = CreatureDef.Mode.FAINTED
	if sequence <= 15 or sequence % 10 == 0: _log("snapshot_applied",{"seq":sequence,"hp":fighters.map(func(c): return c.hp)})

@rpc("any_peer","call_remote","unreliable_ordered",1)
func _intent(number: int,sequence: int,v: Vector2,sprint: bool):
	if role != "host" or phase != "fighting" or number != battle_number or multiplayer.get_remote_sender_id() != remote_id or sequence <= last_seq or not v.is_finite(): return
	last_seq = sequence
	last_seen = Time.get_ticks_msec()
	if is_instance_valid(guest_body):
		guest_body.combat.remote_intent.move = v.limit_length()
		guest_body.combat.remote_intent.world = true
		guest_body.combat.remote_intent.sprint = sprint

@rpc("any_peer","call_remote","reliable")
func _edge(number: int,slot: int,jump: bool,evade: bool):
	if role != "host" or phase != "fighting" or number != battle_number or multiplayer.get_remote_sender_id() != remote_id: return
	pending_input = {"slot":clampi(slot,-1,3),"jump":jump,"evade":evade}
	_log("remote_edge",pending_input)

func _on_move(user,move):
	if role != "host" or phase != "fighting" or not fighters.has(user): return
	var index = fighters.find(user)
	if peer_ready: _move_event.rpc_id(remote_id,battle_number,index,String(move.get("id","")),user.facing)
	_log("move",{"player":index,"move":move.get("id","")})

@rpc("authority","call_remote","reliable")
func _move_event(number: int,index: int,id: String,dir: Vector3):
	if role == "guest" and phase == "fighting" and number == battle_number and index in [0,1,2,3]: Moves.replay(fighters[index],id,dir)

func _on_hit(user,target,info):
	if role != "host" or phase != "fighting": return
	var i = fighters.find(user)
	if i in [0,1] and target in fighters.slice(2,4):
		hits[i] += 1
		damage[i] += int(info.get("damage",0))
	_log("hit",{"player":i,"target":fighters.find(target),"damage":info.get("damage",0)})

@rpc("authority","call_remote","reliable")
func _end_encounter(number: int,outcome: String,hp: Array):
	if role != "guest" or number != battle_number: return
	_log("guest_result",{"result":outcome,"hp":hp,"number":number})
	_finish_local(outcome)

@rpc("any_peer","call_remote","reliable")
func _abort():
	if role == "host" and multiplayer.get_remote_sender_id() == remote_id and Battle.in_battle: Battle.end_battle("aborted")

func _finish_local(outcome: String):
	if ending: return
	ending = true
	result = outcome
	if role == "guest":
		Battle.clear_move_fields()
		for c in fighters:
			if is_instance_valid(c): c.queue_free()
		if is_instance_valid(guest_arena): guest_arena.close()
		Battle.online_guest = false
		Battle.online = false
		Battle.in_battle = false
		Battle._intro = false
		Battle._ending = false
		Battle.challenge = false
		Battle.partner = null
		Battle.wild = null
		Battle.extra_foes = []
		Battle.allies = []
		Battle.trainer_battle = {}
		Battle.arena_rect = Rect2()
		Battle.no_capture = false
		Battle.no_whiteout = false
		Game.battle_ended.emit(outcome)
		Audio.pop_music("battle",0.3)
	else:
		for c in fighters.slice(2,4):
			if is_instance_valid(c): c.queue_free()
		Battle.extra_foes = []
	for entry in freeze:
		if is_instance_valid(entry[0]):
			entry[0].process_mode = entry[1]
			entry[0].visible = entry[2]
	freeze.clear()
	# Only transient battle data changes: discard XP, HP, inventory and flag mutations.
	for c in Game.companions.values().duplicate():
		if is_instance_valid(c): c.queue_free()
	if not saved_state.is_empty(): Game.state.from_dict(saved_state)
	Game.cutscene = false
	Game.talking = false
	Game.menu_open = false
	SaveGame.enabled = false
	Battle._ambush = false
	var return_to_other_map = role == "guest" and return_scene != "" and return_scene != get_tree().current_scene.scene_file_path
	if return_to_other_map:
		phase = "returning"
		label.text = "LAN: voltando ao mapa anterior..."
		_log("return_map_started",{"scene":return_scene,"pos":return_pos})
		if return_scene == WORLD:
			await Transitions.go_to(WORLD,"r2_trainer_trial",true,0.0)
		else:
			await Transitions.go_to_at(return_scene,return_pos,return_row)
		player = Dialogue.player()
		if not is_instance_valid(player):
			_log("return_map_failed")
			phase = "offline"
			return
		if return_scene == WORLD:
			player.global_position = return_pos
			player.global_position.y = Transitions.ground_y(player.global_position,return_pos.y)
			player.row = return_row
		if not is_instance_valid(remote_avatar) and peer_ready: _make_remote_avatar()
		_log("return_map_done",{"scene":get_tree().current_scene.scene_file_path,"pos":player.global_position,"zone":String(Game.event_zone(player))})
	else:
		player.global_position = saved_pos
		player.row = saved_row
	player.velocity = Vector3.ZERO
	player.debug_move = Vector2.ZERO
	player.controls_enabled = true
	Transitions.reset_interp(player)
	Controls.set_battle_dpad(false)
	var hud = Dialogue.hud()
	if hud: hud.intro.reset()
	Dialogue.camera_rig().focus_follow(player)
	if is_instance_valid(trainer):
		trainer._spotting = false
		trainer.talking = false
		trainer._sight_cd = 5.0
		trainer.global_position = trainer._spot_home
		trainer.row = trainer._spot_facing
	if is_instance_valid(remote_avatar): remote_avatar.show()
	fighters.clear()
	guest_body = null
	launching = false
	switching_foe = false
	switching_slots.clear()
	phase = "world" if peer_ready else "offline"
	return_ms = Time.get_ticks_msec()
	label.text = "LAN: %s / de volta ao %s / encontro repetivel; sem recompensas" % [outcome,String(Game.event_zone(player))]
	_log("returned_to_campaign",{"result":outcome,"controls":player.controls_enabled,"battle":Battle.in_battle,"trainer_defeated":Game.flags.get("trainer_youngster_ryan",false),"money":Game.state.money,"saved_money":saved_state.get("money"),"flags_restored":Game.flags == saved_state.get("flags",{}),"party_restored":Game.party.map(func(m):return m.to_dict()) == saved_state.get("party",[]),"party_hp":Game.party.map(func(m):return m.hp),"pos":player.global_position,"scene":get_tree().current_scene.scene_file_path})

func _peer_left(id):
	if id == remote_id: _disconnect("disconnected")

func _disconnect(reason):
	if phase == "offline" or closing: return
	closing = true
	peer_ready = false
	abort_reason = reason
	remote_id = 0
	if role == "host" and launching:
		if Battle.in_battle and not Battle._ending: Battle.end_battle("aborted")
	elif phase in ["prepare","fighting","ending"]:
		_finish_local(reason)
	else:
		phase = "offline"
		Game.cutscene = false
		if is_instance_valid(player): player.controls_enabled = true
	if is_instance_valid(remote_avatar): remote_avatar.hide()
	if label != null: label.text = "LAN desconectada; mapa local liberado"
	_log("disconnected",{"reason":reason})

func _log(event: String,d: Dictionary = {}):
	var row = {"event":event,"role":role,"ms":Time.get_ticks_msec(),"phase":phase,"number":battle_number}
	row.merge(d)
	var line = JSON.stringify(row)
	print("[campaign-lan] ",line)
	if audit != null:
		audit.store_line(line)
		audit.flush()

func _request_capture(kind: String):
	if captures.has(kind): return
	captures[kind] = true
	_save_capture.call_deferred(kind)

func _save_capture(kind: String):
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://campaign_" + kind + ".png")
