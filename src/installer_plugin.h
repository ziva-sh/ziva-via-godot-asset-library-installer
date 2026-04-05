#pragma once

#include <godot_cpp/classes/editor_plugin.hpp>
#include <godot_cpp/classes/control.hpp>
#include <godot_cpp/classes/node.hpp>

using namespace godot;

class InstallerPlugin : public EditorPlugin {
	GDCLASS(InstallerPlugin, EditorPlugin);

protected:
	static void _bind_methods();

public:
	void _enter_tree() override;
	void _exit_tree() override;
	bool _has_main_screen() const override;
	String _get_plugin_name() const override;

private:
	Control *dock_ = nullptr;
	Node *test_api_ = nullptr;
};
