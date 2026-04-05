#include "register_types.h"

#include "installer_plugin.h"

#include <gdextension_interface.h>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/classes/editor_plugin_registration.hpp>

using namespace godot;

// The native library path is resolved once at init time and used by InstallerPlugin
// to locate sibling GDScript files regardless of install directory name.
static String s_plugin_base_dir;

const String &get_installer_base_dir() {
	return s_plugin_base_dir;
}

void initialize_gdextension_types(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_EDITOR) {
		return;
	}

	// Derive base dir from the native library path (e.g. res://.../bin/lib.dll → res://.../)
	String lib_path;
	internal::gdextension_interface_get_library_path(internal::library, &lib_path);
	s_plugin_base_dir = lib_path.get_base_dir().get_base_dir();

	ClassDB::register_internal_class<InstallerPlugin>();
	EditorPlugins::add_by_type<InstallerPlugin>();
}

void uninitialize_gdextension_types(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_EDITOR) {
		return;
	}
}

extern "C"
{
	// Initialization
	GDExtensionBool GDE_EXPORT ziva_installer_init(GDExtensionInterfaceGetProcAddress p_get_proc_address, GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization)
	{
		GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
		init_obj.register_initializer(initialize_gdextension_types);
		init_obj.register_terminator(uninitialize_gdextension_types);
		init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_EDITOR);

		return init_obj.init();
	}
}
