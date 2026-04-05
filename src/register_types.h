#ifndef ZIVA_INSTALLER_REGISTER_TYPES_H
#define ZIVA_INSTALLER_REGISTER_TYPES_H

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/string.hpp>

using godot::ModuleInitializationLevel;
using godot::String;

void initialize_gdextension_types(ModuleInitializationLevel p_level);
void uninitialize_gdextension_types(ModuleInitializationLevel p_level);

const String &get_installer_base_dir();

#endif // ZIVA_INSTALLER_REGISTER_TYPES_H
