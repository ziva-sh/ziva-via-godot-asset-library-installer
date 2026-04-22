@tool
extends VBoxContainer

enum State { IDLE, DOWNLOADING, EXTRACTING, COMPLETE, ERROR }

var _state: State = State.IDLE
var _progress: float = 0.0

var _links_row: HBoxContainer
var _install_button: Button
var _progress_bar: ProgressBar
var _status_label: Label
var _retry_button: Button
var _restart_button: Button

var _downloader: Node


func _ready() -> void:
	_build_ui()
	_create_downloader()


func _get_editor_font_size() -> int:
	return EditorInterface.get_editor_theme().get_font_size("main_size", "EditorFonts")


func _scale_editor_font_size(multiplier: float) -> int:
	return roundi((_get_editor_font_size() * 1.0) * multiplier)


func _build_ui() -> void:
	self.alignment = BoxContainer.ALIGNMENT_CENTER
	self.add_theme_constant_override("separation", 24)

	# Header
	var header_label = Label.new()
	header_label.text = "Ziva AI Agent Installer"
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_label.add_theme_font_override("font", EditorInterface.get_editor_theme().get_font("bold", "EditorFonts"))
	header_label.add_theme_font_size_override("font_size", _scale_editor_font_size(1.25))
	add_child(header_label)

	# Links row
	_links_row = HBoxContainer.new()
	_links_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_links_row.add_theme_constant_override("separation", 16)

	var website_link := _build_link_btn("Website", "https://ziva.sh")
	_links_row.add_child(website_link)
	
	var docs_link := _build_link_btn("Docs", "https://ziva.sh/docs")
	_links_row.add_child(docs_link)

	var discord_link := _build_link_btn("Discord", "https://ziva.sh/discord")
	_links_row.add_child(discord_link)

	add_child(_links_row)

	# Spacer
	add_child(_build_vertical_spacer(12))

	# Actions row
	var actions_row := HBoxContainer.new()
	actions_row.alignment = BoxContainer.ALIGNMENT_CENTER
	actions_row.add_theme_constant_override("separation", 24)

	# Install button
	_install_button = Button.new()
	_install_button.text = "Install Ziva AI Agent"
	_install_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_install_button.pressed.connect(_on_install_pressed)
	_install_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	actions_row.add_child(_install_button)
	
	add_child(actions_row)
	
	add_child(_build_vertical_spacer(8))

	# Subtext 
	var subtext_label := Label.new()
	subtext_label.text = "By installing you agree to the Terms of service and privacy policy"
	subtext_label.add_theme_font_size_override("font_size", _scale_editor_font_size(0.75))
	subtext_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	subtext_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	add_child(subtext_label)
	
	# Footer row
	var footer_row := HBoxContainer.new()
	footer_row.alignment = BoxContainer.ALIGNMENT_CENTER
	footer_row.add_theme_constant_override("separation", 24)

	# Terms of service link
	var tos_link = _build_link_btn("Terms of Service", "https://ziva.sh/terms")
	tos_link.add_theme_font_size_override("font_size", _scale_editor_font_size(0.75))
	footer_row.add_child(tos_link)

	# Privacy policy link
	var privacy_policy_link := _build_link_btn("Privacy Policy", "https://ziva.sh/privacy")
	privacy_policy_link.add_theme_font_size_override("font_size", _scale_editor_font_size(0.75))
	footer_row.add_child(privacy_policy_link)

	add_child(footer_row)

	# Spacer
	add_child(_build_vertical_spacer(20))

	# Margin Container for progress and status
	var status_margin := MarginContainer.new()
	status_margin.add_theme_constant_override("margin_left", 32)
	status_margin.add_theme_constant_override("margin_right", 32)
	add_child(status_margin)
	
	var status_vbox := VBoxContainer.new()
	status_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	status_margin.add_child(status_vbox)

	# Progress bar (hidden initially)
	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0
	_progress_bar.max_value = 100
	_progress_bar.value = 0
	_progress_bar.visible = false
	_progress_bar.custom_minimum_size.y = 24
	status_vbox.add_child(_progress_bar)

	# Status label
	_status_label = Label.new()
	_status_label.text = ""
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_vbox.add_child(_status_label)

	# Retry button (hidden initially)
	_retry_button = Button.new()
	_retry_button.text = "Retry"
	_retry_button.visible = false
	_retry_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_retry_button.pressed.connect(_on_retry_pressed)
	_retry_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	status_vbox.add_child(_retry_button)

	# Restart button (hidden initially)
	_restart_button = Button.new()
	_restart_button.text = "Restart Editor"
	_restart_button.visible = false
	_restart_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_restart_button.pressed.connect(_on_restart_pressed)
	_restart_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	status_vbox.add_child(_restart_button)


func _build_link_btn(p_text: String, p_link: String) -> LinkButton:
	var btn := LinkButton.new()
	btn.text = p_text
	btn.uri = p_link
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return btn

func _build_vertical_spacer(p_height: int) -> Control:
	var control := Control.new()
	control.custom_minimum_size.y = p_height
	return control

func _create_downloader() -> void:
	var base_dir: String = get_script().resource_path.get_base_dir()
	var script := load(base_dir.path_join("installer_download.gd"))
	if script == null:
		push_error("ZivaInstaller: Could not load installer_download.gd")
		return
	_downloader = Node.new()
	_downloader.set_script(script)
	_downloader.state_changed.connect(_on_state_changed)
	_downloader.error_occurred.connect(_on_error_occurred)
	add_child(_downloader)


func get_state() -> String:
	match _state:
		State.IDLE:
			return "idle"
		State.DOWNLOADING:
			return "downloading"
		State.EXTRACTING:
			return "extracting"
		State.COMPLETE:
			return "complete"
		State.ERROR:
			return "error"
	return "idle"


func get_progress() -> float:
	return _progress


func start_install() -> void:
	if _downloader:
		_downloader.start_install()


func _on_install_pressed() -> void:
	start_install()


func _on_retry_pressed() -> void:
	_retry_button.visible = false
	_status_label.text = ""
	start_install()


func _on_restart_pressed() -> void:
	EditorInterface.restart_editor()


func _on_state_changed(state_str: String, progress: float) -> void:
	_progress = progress

	match state_str:
		"idle":
			_state = State.IDLE
		"downloading":
			_state = State.DOWNLOADING
			_install_button.visible = false
			_progress_bar.visible = true
			_progress_bar.value = progress * 100.0
			_status_label.text = ""
		"extracting":
			_state = State.EXTRACTING
			_progress_bar.visible = true
			_progress_bar.value = 100
			_status_label.text = "Extracting..."
		"complete":
			_state = State.COMPLETE
			_progress_bar.visible = false
			_status_label.text = "Installation complete! Please restart the editor."
			_restart_button.visible = true


func _on_error_occurred(message: String) -> void:
	_state = State.ERROR
	_progress_bar.visible = false
	_install_button.visible = false
	_status_label.text = "Error: " + message
	_retry_button.visible = true
