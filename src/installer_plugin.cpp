#include "installer_plugin.h"

#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/gd_extension_manager.hpp>
#include <godot_cpp/classes/os.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/script.hpp>
#include <godot_cpp/classes/v_box_container.hpp>

void InstallerPlugin::_bind_methods() {}

String InstallerPlugin::_get_base_dir() const {
	GDExtensionManager *manager = GDExtensionManager::get_singleton();
	if (manager) {
		PackedStringArray extensions = manager->get_loaded_extensions();
		for (int i = 0; i < extensions.size(); i++) {
			if (extensions[i].contains("ziva_installer")) {
				return extensions[i].get_base_dir();
			}
		}
	}
	return "res://addons/ziva_installer";
}

void InstallerPlugin::_enter_tree() {
	// If the full Ziva Agent plugin is already installed, do nothing.
	if (FileAccess::file_exists("res://addons/ziva_agent/ziva_agent.gdextension")) {
		return;
	}

	String base_dir = _get_base_dir();

	// Load the installer dock GDScript and attach it to a VBoxContainer.
	Ref<Script> script = ResourceLoader::get_singleton()->load(base_dir + "/installer_dock.gd");
	if (script.is_null()) {
		return;
	}

	dock_ = memnew(VBoxContainer);
	dock_->set_script(script);
	dock_->set_name("ZivaInstaller");
	add_control_to_dock(DOCK_SLOT_LEFT_UL, dock_);

	// Test API support: if env var is set and the script exists, wire it up.
	if (OS::get_singleton()->has_environment("ZIVA_INSTALLER_TEST_API") &&
		FileAccess::file_exists(base_dir + "/test_api.gd")) {
		Ref<Script> test_script = ResourceLoader::get_singleton()->load(base_dir + "/test_api.gd");
		if (test_script.is_valid()) {
			test_api_ = memnew(Node);
			test_api_->set_script(test_script);
			test_api_->call("set_dock", dock_);
			add_child(test_api_);
		}
	}
}

void InstallerPlugin::_exit_tree() {
	if (dock_ != nullptr) {
		remove_control_from_docks(dock_);
		dock_->queue_free();
		dock_ = nullptr;
	}

	if (test_api_ != nullptr) {
		test_api_->queue_free();
		test_api_ = nullptr;
	}
}

bool InstallerPlugin::_has_main_screen() const {
	return false;
}

String InstallerPlugin::_get_plugin_name() const {
	return "Ziva Installer";
}
