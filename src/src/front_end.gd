extends Control







const Splash: = preload("res://scripts/front/splash.gd")
const TitleScreen: = preload("res://scripts/front/title_screen.gd")
const SaveSlotsMenu: = preload("res://scripts/front/save_slots_menu.gd")
const GameLinks: = preload("res://scripts/front/game_links.gd")
const OakWelcome: = preload("res://scripts/front/oak_welcome.gd")
const NameEntry: = preload("res://scripts/ui/kit/pk_name_entry.gd")
const GiftFlow: = preload("res://scripts/gift/gift_flow.gd")
const GenderPick: = preload("res://scripts/ui/kit/pk_gender_pick.gd")

const CreditsPanelScript: = preload("res://scripts/ui/credits_panel.gd")
const PkLoadingScript: = preload("res://scripts/ui/kit/pk_loading.gd")



const NEW_GAME_SCENE: = "res://scenes/world/overworld.tscn"
const NEW_GAME_SPAWN: = "start"
const IDLE_TO_SPLASH: = 60.0

enum S{SPLASH, TITLE, MENU, BUSY, INTRO}

static var boot_to_menu: = false

var state: = S.SPLASH
var _splash: ColorRect
var _title: Control
var _menu: Control
var _options: OptionsScreen
var _credits: Control
var _loading: Control
var _prewarm: Node
var _dialog: PkDialogBox
var _hints: PkHintBar
var _idle: = 0.0
var _oak: Control
var _name_entry: Control
var _gender_pick: Control
var _intro_skipped: = false


func _ready() -> void :
	if "--coop-campaign" in OS.get_cmdline_user_args():
		SaveGame.enabled = false
		set_process(false)
		set_process_input(false)
		set_process_unhandled_input(false)
		var session = load("res://coop/campaign.gd").new()
		session.name = "LanCampaign"
		get_tree().root.add_child.call_deferred(session)
		return
	if "--coop" in OS.get_cmdline_user_args():
		set_process(false)
		set_process_input(false)
		set_process_unhandled_input(false)
		get_tree().change_scene_to_file.call_deferred("res://coop/arena.tscn")
		return
	print("[campaign-lan] solo_original_boot")
	_normal_ready()

func _normal_ready() -> void :
	add_to_group("front_end")
	theme = UiKit.theme()
	UiKit.setup_input()
	SaveGame.enabled = false
	if Debug.checkpoint != "":
		return
	_title = TitleScreen.new()
	add_child(_title)
	_menu = SaveSlotsMenu.new()
	_menu.picked.connect(_on_menu)
	add_child(_menu)
	_hints = PkHintBar.new()
	_hints.position = Vector2(80, 552)
	_hints.set_hints([["pk_ok", "Continue"], ["pk_alt", "New Game"], [["pk_left", "pk_right"], "Panel"]])
	_hints.visible = false
	add_child(_hints)
	_dialog = PkDialogBox.new()
	_dialog.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_dialog.offset_left = 120
	_dialog.offset_right = -120
	_dialog.offset_top = -190
	_dialog.offset_bottom = -30
	add_child(_dialog)

	if Analytics.needs_notice():
		_title.visible = false
		await _dialog.say("", ["This game collects anonymized data to improve the experience.\nYou can change this at any time in the OPTIONS screen."])
		Analytics.notice_acknowledged()
		_title.visible = true
	Analytics.app_opened()
	_options = OptionsScreen.new()
	_options.closed.connect( func():
		state = S.MENU
		_menu.slots.active = _menu.pane == 0
		_menu.side.active = _menu.pane == 1)
	add_child(_options)
	_credits = CreditsPanelScript.new()
	_credits.closed.connect( func():
		state = S.MENU
		_menu.slots.active = _menu.pane == 0
		_menu.side.active = _menu.pane == 1)
	add_child(_credits)



	if Prewarm.wanted():
		_loading = PkLoadingScript.new()
		_loading.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_loading.z_index = 100
		add_child(_loading)
		_loading.begin()
		_prewarm = Prewarm.new()
		_prewarm.name = "Prewarm"
		add_child(_prewarm)
		_prewarm.progressed.connect(_loading.stage)
		_prewarm.finished.connect( func():
			_loading.end()
			_prewarm.queue_free())
		_prewarm.start()
	Audio.set_area_music("music/title", 1.0)
	if boot_to_menu:
		boot_to_menu = false
		_title.show_instant()
		_open_menu()
		return
	_splash = Splash.new()
	add_child(_splash)
	state = S.SPLASH
	await _splash.play()
	_splash.queue_free()
	_splash = null


	if is_instance_valid(_prewarm):
		await _prewarm.finished
	state = S.TITLE
	_title.play_intro()


func _input(e: InputEvent) -> void :



	if state == S.INTRO and _name_entry == null and _gender_pick == null and e.is_action_pressed("pk_back"):
		_skip_intro()
		get_viewport().set_input_as_handled()


func _unhandled_input(e: InputEvent) -> void :
	if e is InputEventKey and e.pressed:
		_idle = 0.0
	match state:
		S.SPLASH:
			if _splash and (e is InputEventKey or e is InputEventAction) and e.is_pressed():
				_splash.skip()
				get_viewport().set_input_as_handled()
		S.TITLE:
			if e.is_action_pressed("pk_ok"):
				UiKit.sfx("confirm")
				_open_menu()
				get_viewport().set_input_as_handled()


func _process(delta: float) -> void :
	if state == S.TITLE:
		_idle += delta
		if _idle > IDLE_TO_SPLASH:
			get_tree().reload_current_scene()



func is_title() -> bool:
	return state == S.TITLE


func _open_menu() -> void :
	state = S.MENU
	_title.show_press_start(false)
	_hints.visible = true
	_menu.open(SaveGame.peek_all())


func _open_options() -> void :
	state = S.BUSY
	_menu.slots.active = false
	_menu.side.active = false
	_options.open()



func _open_gift() -> void :
	state = S.BUSY
	_menu.slots.active = false
	_menu.side.active = false
	_hints.visible = false
	var flow: = GiftFlow.new()
	flow.dialog = _dialog
	add_child(flow)
	await flow.run()
	flow.queue_free()
	_hints.visible = true
	_open_menu()


func _open_credits() -> void :
	state = S.BUSY
	_menu.slots.active = false
	_menu.side.active = false
	_credits.open()


func _on_menu(id: String, slot: int) -> void :
	Analytics.track("title_choice", {"choice": id, "slot": slot, 
		"has_save": slot >= 0 and not SaveGame.peek_slot(slot).is_empty()})
	match id:
		"continue":
			continue_game(slot)
		"new_game":
			new_game(slot)
		"options":
			_open_options()
		"credits":
			_open_credits()
		"gift":
			_open_gift()
		"patreon":
			GameLinks.open(GameLinks.PATREON)
		"discord":
			GameLinks.open(GameLinks.DISCORD)
		"quit":
			Analytics.quit_game()


func new_game(slot: = 0) -> void :
	state = S.BUSY
	_menu.slots.active = false
	_menu.side.active = false
	SaveGame.set_slot(slot)
	if SaveGame.has_file_slot(slot):
		_hints.visible = false
		var yes: = await _confirm_erase(slot)
		if not yes:
			state = S.MENU
			_menu.slots.active = true
			_hints.visible = true
			return
	Game.state.reset_new_game()
	Game.start_night_prologue()
	_menu.visible = false
	_hints.visible = false
	Audio.set_area_music("music/oak", 0.5)
	await _run_intro()
	SaveGame.enabled = true

	Transitions.go_to(NEW_GAME_SCENE, NEW_GAME_SPAWN, true)





func _confirm_erase(slot: = 0) -> bool:
	var what: = "a saved game"
	var d: = SaveGame.peek_slot(slot)
	if not d.is_empty():
		var rows: = SaveGame.summary_rows(d)
		what = "%s's saved game (%s played)" % [rows[0][1], rows[1][1]]
	var id: String = await _dialog.ask_choice("", "WARNING! There is already %s.\nStarting a new game ERASES it for good. Erase it and start over?" % what, 
		[{"id": "no", "label": "NO, KEEP MY GAME"}, {"id": "yes", "label": "YES, ERASE IT"}])
	return id == "yes"




func _run_intro() -> void :
	state = S.INTRO
	_intro_skipped = false
	_oak = OakWelcome.new()
	add_child(_oak)
	await _oak.play_intro()
	if not _intro_skipped:
		await _oak.stage("side")
		Game.state.player_gender = await _ask_gender()
	if not _intro_skipped:
		Game.state.player_name = await _ask_name("YOUR NAME?", Game.state.player_name)
	Analytics.track("trainer_created", {"gender": _character(Game.state.player_gender), 
		"default_name": Game.state.player_name == GameState.DEFAULT_PLAYER_NAME})
	await _oak.play_after_player(Game.state.player_name)
	if not _intro_skipped:
		Game.state.rival_name = await _ask_name("RIVAL'S NAME?", Game.state.rival_name)
	await _oak.play_finale()
	_oak = null
	AnalyticsBeats.beat("intro_done")
	Analytics.track("intro_completed", {"skipped": _intro_skipped, 
		"default_names": Game.state.player_name == GameState.DEFAULT_PLAYER_NAME
			and Game.state.rival_name == GameState.DEFAULT_RIVAL_NAME})



func _ask_gender() -> String:
	var pick: = GenderPick.new()

	pick.position = Vector2(40, 280)
	add_child(pick)
	_gender_pick = pick
	var g: String = await pick.ask(Game.state.player_gender)
	_gender_pick = null
	pick.queue_free()
	Analytics.track("character_chosen", {"character": _character(g)})
	return g



static func _character(gender: String) -> String:
	return "leaf" if gender == "green" else "red"


func _ask_name(title_text: String, default_name: String) -> String:
	var entry: = NameEntry.new()

	entry.position = Vector2(40, 380)
	add_child(entry)
	_name_entry = entry
	var n: String = await entry.ask(title_text, default_name)
	_name_entry = null
	entry.queue_free()
	return n


func _skip_intro() -> void :
	if _intro_skipped:
		return
	_intro_skipped = true
	if _oak:
		_oak.skip()


func continue_game(slot: = 0) -> void :
	state = S.BUSY
	SaveGame.set_slot(slot)
	_menu.slots.active = false
	_menu.side.active = false
	if SaveGame.peek().is_empty():
		_hints.visible = false
		await _dialog.say("", ["This save is from an older version and can't be loaded. Start a new game." if SaveGame.too_old() else "The save file could not be loaded."])
		_hints.visible = true
		_open_menu()
		return
	SaveGame.restore()
