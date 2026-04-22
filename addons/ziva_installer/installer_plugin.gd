@tool
extends EditorPlugin

var _dock: VBoxContainer


func _enter_tree() -> void:
	if FileAccess.file_exists("res://addons/ziva_agent/ziva_agent.gdextension"):
		return

	# If the GDExtension C++ plugin already added the dock, don't duplicate it.
	if EditorInterface.get_base_control().find_child("ZivaInstaller", true, false):
		return

	var base_dir: String = get_script().resource_path.get_base_dir()
	var script := load(base_dir + "/installer_dock.gd")
	if script == null:
		return

	_dock = VBoxContainer.new()
	_dock.set_script(script)
	_dock.set_name("ZivaInstaller")
	add_control_to_dock(DOCK_SLOT_LEFT_UL, _dock)


func _exit_tree() -> void:
	if _dock:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null


func _has_main_screen() -> bool:
	return false


func _get_plugin_name() -> String:
	return "Ziva Installer"
