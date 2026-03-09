@tool
extends VBoxContainer

enum State { IDLE, DOWNLOADING, EXTRACTING, COMPLETE, ERROR }

var _state: State = State.IDLE
var _progress: float = 0.0

var _header_label: Label
var _links_row: HBoxContainer
var _install_button: Button
var _progress_bar: ProgressBar
var _status_label: Label
var _retry_button: Button
var _restart_button: Button
var _tos_link: LinkButton

var _downloader: Node


func _ready() -> void:
	_build_ui()
	_create_downloader()


func _build_ui() -> void:
	# Header
	_header_label = Label.new()
	_header_label.text = "Ziva AI Agent Installer"
	_header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_header_label)

	# Spacer
	var spacer1 := Control.new()
	spacer1.custom_minimum_size.y = 8
	add_child(spacer1)

	# Links row
	_links_row = HBoxContainer.new()
	_links_row.alignment = BoxContainer.ALIGNMENT_CENTER

	var website_link := LinkButton.new()
	website_link.text = "Website"
	website_link.uri = "https://ziva.sh"
	website_link.pressed.connect(func(): OS.shell_open("https://ziva.sh"))
	_links_row.add_child(website_link)

	var docs_link := LinkButton.new()
	docs_link.text = "Docs"
	docs_link.uri = "https://ziva.sh/docs"
	docs_link.pressed.connect(func(): OS.shell_open("https://ziva.sh/docs"))
	_links_row.add_child(docs_link)

	var discord_link := LinkButton.new()
	discord_link.text = "Discord"
	discord_link.uri = "https://ziva.sh/discord"
	discord_link.pressed.connect(func(): OS.shell_open("https://ziva.sh/discord"))
	_links_row.add_child(discord_link)

	add_child(_links_row)

	# Spacer
	var spacer2 := Control.new()
	spacer2.custom_minimum_size.y = 16
	add_child(spacer2)

	# Install button
	_install_button = Button.new()
	_install_button.text = "Install Ziva Agent"
	_install_button.pressed.connect(_on_install_pressed)
	add_child(_install_button)

	# Progress bar (hidden initially)
	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0
	_progress_bar.max_value = 100
	_progress_bar.value = 0
	_progress_bar.visible = false
	add_child(_progress_bar)

	# Status label
	_status_label = Label.new()
	_status_label.text = ""
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_status_label)

	# Retry button (hidden initially)
	_retry_button = Button.new()
	_retry_button.text = "Retry"
	_retry_button.visible = false
	_retry_button.pressed.connect(_on_retry_pressed)
	add_child(_retry_button)

	# Restart button (hidden initially)
	_restart_button = Button.new()
	_restart_button.text = "Restart Editor"
	_restart_button.visible = false
	_restart_button.pressed.connect(_on_restart_pressed)
	add_child(_restart_button)

	# Spacer
	var spacer3 := Control.new()
	spacer3.custom_minimum_size.y = 8
	add_child(spacer3)

	# ToS link
	_tos_link = LinkButton.new()
	_tos_link.text = "Terms of Service"
	_tos_link.uri = "https://ziva.sh/terms"
	_tos_link.pressed.connect(func(): OS.shell_open("https://ziva.sh/terms"))
	add_child(_tos_link)


func _create_downloader() -> void:
	var script := load("res://addons/ziva_installer/installer_download.gd")
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
			_status_label.text = "Downloading... %d%%" % int(progress * 100.0)
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
