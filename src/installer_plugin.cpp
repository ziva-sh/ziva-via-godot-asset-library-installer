#include "installer_plugin.h"

#include <godot_cpp/classes/dir_access.hpp>
#include <godot_cpp/classes/editor_interface.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/gd_extension_manager.hpp>
#include <godot_cpp/classes/os.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/script.hpp>
#include <godot_cpp/classes/v_box_container.hpp>

void ZivaInstallerPlugin::_bind_methods() {}

String ZivaInstallerPlugin::_get_base_dir() const {
	// Try GDExtensionManager first — returns res:// paths of loaded .gdextension files.
	GDExtensionManager *manager = GDExtensionManager::get_singleton();
	if (manager) {
		PackedStringArray extensions = manager->get_loaded_extensions();
		for (int i = 0; i < extensions.size(); i++) {
			if (extensions[i].contains("ziva_installer")) {
				return extensions[i].get_base_dir();
			}
		}
	}

	// Fallback: scan addons/ for any directory containing our .gdextension file.
	// Handles renamed folders (e.g. "ziva-installer-v0.1.6 (1) - Copy").
	Ref<DirAccess> dir = DirAccess::open("res://addons");
	if (dir.is_valid()) {
		dir->list_dir_begin();
		String name = dir->get_next();
		while (name != "") {
			if (dir->current_is_dir()) {
				String candidate = "res://addons/" + name;
				if (FileAccess::file_exists(candidate + "/ziva_installer.gdextension")) {
					return candidate;
				}
			}
			name = dir->get_next();
		}
	}

	// Last resort: check project root.
	if (FileAccess::file_exists("res://ziva_installer/ziva_installer.gdextension")) {
		return "res://ziva_installer";
	}

	return "res://addons/ziva_installer";
}

void ZivaInstallerPlugin::_ready() {
	// If the full Ziva Agent plugin is already installed, do nothing.
	if (FileAccess::file_exists("res://addons/ziva_agent/ziva_agent.gdextension")) {
		return;
	}

	// If the GDScript plugin already added the dock, don't duplicate it.
	if (EditorInterface::get_singleton()->get_base_control()->find_child("Ziva Installer", true, false)) {
		return;
	}

	String base_dir = _get_base_dir();

	// Load the installer dock GDScript and attach it to a VBoxContainer.
	Ref<Script> script = ResourceLoader::get_singleton()->load(base_dir.path_join("/installer_dock.gd"));
	if (script.is_null()) {
		return;
	}

	dock_ = memnew(VBoxContainer);
	dock_->set_script(script);
	dock_->set_name("Ziva Installer");
	add_control_to_dock(DOCK_SLOT_LEFT_UL, dock_);

	// Test API support: if env var is set and the script exists, wire it up.
	if (OS::get_singleton()->has_environment("ZIVA_INSTALLER_TEST_API") &&
		FileAccess::file_exists(base_dir.path_join("/test_api.gd"))) {
		Ref<Script> test_script = ResourceLoader::get_singleton()->load(base_dir.path_join("test_api.gd"));
		if (test_script.is_valid()) {
			test_api_ = memnew(Node);
			test_api_->set_script(test_script);
			test_api_->call("set_dock", dock_);
			add_child(test_api_);
		}
	}
}

void ZivaInstallerPlugin::_exit_tree() {
	if (dock_ != nullptr) {
		remove_control_from_docks(dock_);
		dock_->queue_free();
		dock_ = nullptr;
	}

	// test api is auto removed since its a child
}

bool ZivaInstallerPlugin::_has_main_screen() const {
	return false;
}

String ZivaInstallerPlugin::_get_plugin_name() const {
	return "Ziva Installer";
}
