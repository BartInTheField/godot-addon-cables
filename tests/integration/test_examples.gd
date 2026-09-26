extends "res://tests/test_case.gd"

# The example scenes, wired up through their real .tres Cables. Those are shared, cached
# resources, so assertions are relative to the value a cable had before the test.

const COIN_COLLECTOR := "res://examples/example_coin_collector/example_coin_collector_main.tscn"
const PLAYER_HEALTH := "res://examples/example_player_health/example_player_health_main.tscn"
const SCORE := "res://examples/example_coin_collector/cables/score.tres"

func test_coin_click_updates_counter() -> void:
	var main: Node = add(load(COIN_COLLECTOR).instantiate())
	var spawner: CoinSpawner = main.get_node("CoinSpawner")
	var label: Label = main.get_node("UI/CounterDisplay/Label")
	var score: Cable = load(SCORE)
	var before: int = score.get_value_or_default(0)

	spawner.spawn()
	var coin: Coin = spawner.get_child(spawner.get_child_count() - 1)
	coin.notify_click()
	await wait_frames()

	assert_eq(score.current_value, before + 1)
	assert_eq(label.text, str(before + 1))
	assert_false(is_instance_valid(coin), "clicked coin is freed")

func test_counter_display_replays_score() -> void:
	var score: Cable = load(SCORE)
	score.notify(99)
	var main: Node = add(load(COIN_COLLECTOR).instantiate())
	var label: Label = main.get_node("UI/CounterDisplay/Label")
	assert_eq(label.text, "99")

func test_player_damage_updates_ui() -> void:
	var main: Node = add(load(PLAYER_HEALTH).instantiate())
	await wait_frames()
	var player: Player = main.get_node("Player")
	var ui := "CanvasLayer/CanvasLayoutRoot/"
	var health_bar: HealthBar = main.get_node(ui + "HealthBar")
	var overlay: Control = main.get_node(ui + "PlayerDeadOverlay")
	var deaths_label: Label = main.get_node(ui + "DeathCounterUI/Label")
	var death_count: Cable = player.death_count_cable
	var deaths_before: int = death_count.get_value_or_default(0)

	player.take_damage(25.0)
	assert_eq(player.health_value_cable.current_value, 75.0)
	assert_eq(health_bar.fill_amount, 0.75)
	assert_false(overlay.visible)

	player.take_damage(1000.0)
	assert_eq(health_bar.fill_amount, 0.0)
	assert_true(overlay.visible, "death overlay shows")
	assert_eq(death_count.current_value, deaths_before + 1)
	assert_eq(deaths_label.text, "Deaths: %s" % (deaths_before + 1))

func test_player_starts_with_initial_health_after_reload() -> void:
	var first: Node = add(load(PLAYER_HEALTH).instantiate())
	await wait_frames()
	var health: FloatCable = first.get_node("Player").health_value_cable
	first.get_node("Player").take_damage(1000.0)
	assert_eq(health.current_value, 0.0)
	first.queue_free()
	await wait_frames()

	var main: Node = add(load(PLAYER_HEALTH).instantiate())
	await wait_frames()
	var player: Player = main.get_node("Player")
	var health_bar: HealthBar = main.get_node("CanvasLayer/CanvasLayoutRoot/HealthBar")
	assert_eq(player.health, health.initial_value)
	assert_eq(health.current_value, health.initial_value)
	assert_eq(health_bar.fill_amount, 1.0)

func test_player_node_cable_is_cleared_when_scene_is_freed() -> void:
	var main: Node = add(load(PLAYER_HEALTH).instantiate())
	await wait_frames()
	var player_cable: Cable = main.main_player_value_cable
	assert_true(player_cable.current_value == main.get_node("Player"))
	main.queue_free()
	await wait_frames()
	assert_null(player_cable.current_value)
