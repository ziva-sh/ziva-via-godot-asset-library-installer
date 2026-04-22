@tool
extends EditorPlugin

var _dock: VBoxContainer
var _test_api: Node

var base_dir: String = get_script().resource_path.get_base_dir()

func _ready() -> void:
	if FileAccess.file_exists("res://addons/ziva_agent/ziva_agent.gdextension"):
		return

	var script := load(base_dir.path_join("installer_dock.gd"))
	if script == null:
		return

	_dock = VBoxContainer.new()
	_dock.set_script(script)
	_dock.set_name("Ziva Installer")
	add_control_to_dock(DOCK_SLOT_LEFT_UL, _dock)

	_load_test_api()


func _load_test_api():
	var test_api_file_path = base_dir.path_join("test_api.gd")
	if not OS.has_environment("ZIVA_INSTALLER_TEST_API"):
		return
	
	if not FileAccess.file_exists(test_api_file_path):
		return
	
	var test_script: Script = load(test_api_file_path)
	if not test_script:
		return
	
	_test_api = Node.new()
	_test_api.set_script(test_script)
	_test_api.call("set_dock", _dock)
	add_child(_test_api)
	print("ZivaInstaller:: Added test api")


func _exit_tree() -> void:
	if _dock:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null
	
	# Test api is automatically removed because its a child


func _has_main_screen() -> bool:
	return false


func _get_plugin_name() -> String:
	return "Ziva Installer"
