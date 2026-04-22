#ifndef ZIVA_INSTALLER_REGISTER_TYPES_H
#define ZIVA_INSTALLER_REGISTER_TYPES_H

#include <godot_cpp/core/class_db.hpp>

using godot::ModuleInitializationLevel;

void initialize_gdextension_types(ModuleInitializationLevel p_level);
void uninitialize_gdextension_types(ModuleInitializationLevel p_level);

#endif // ZIVA_INSTALLER_REGISTER_TYPES_H
