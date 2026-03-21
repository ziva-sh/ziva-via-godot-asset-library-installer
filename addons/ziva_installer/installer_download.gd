@tool
extends Node

signal state_changed(state: String, progress: float)
signal error_occurred(message: String)

var _http_api: HTTPRequest
var _http_download: HTTPRequest
var _download_tag: String = ""
var _download_path: String = ""


func _ready() -> void:
	_http_api = HTTPRequest.new()
	_http_api.request_completed.connect(_on_api_request_completed)
	add_child(_http_api)

	_http_download = HTTPRequest.new()
	_http_download.request_completed.connect(_on_download_completed)
	add_child(_http_download)


func start_install() -> void:
	state_changed.emit("downloading", 0.0)
	var err := _http_api.request(
		"https://api.github.com/repos/ziva-sh/ziva-agent-plugin-godot/releases/latest",
		["Accept: application/vnd.github+json", "User-Agent: ZivaInstaller"]
	)
	if err != OK:
		error_occurred.emit("Failed to start API request: " + str(err))


func _process(_delta: float) -> void:
	if _http_download.get_http_client_status() == HTTPClient.STATUS_BODY:
		var body_size := _http_download.get_body_size()
		var downloaded := _http_download.get_downloaded_bytes()
		if body_size > 0:
			var progress := float(downloaded) / float(body_size)
			state_changed.emit("downloading", progress)


func _on_api_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		error_occurred.emit("GitHub API request failed (code: %d, result: %d)" % [response_code, result])
		return

	var json := JSON.new()
	var parse_err := json.parse(body.get_string_from_utf8())
	if parse_err != OK:
		error_occurred.emit("Failed to parse GitHub API response")
		return

	var data: Dictionary = json.data
	if not data.has("tag_name"):
		error_occurred.emit("No tag_name in GitHub release response")
		return

	_download_tag = data["tag_name"]
	var suffix := _get_platform_suffix()
	if suffix == "":
		error_occurred.emit("Unsupported platform: " + OS.get_name())
		return

	var url := "https://github.com/ziva-sh/ziva-agent-plugin-godot/releases/download/%s/ziva-ai-agent-%s-godot-v4.2.0-%s.zip" % [_download_tag, _download_tag, suffix]
	_download_path = OS.get_user_data_dir() + "/ziva_installer_temp.zip"

	_http_download.download_file = _download_path
	var err := _http_download.request(url, ["User-Agent: ZivaInstaller"])
	if err != OK:
		error_occurred.emit("Failed to start download: " + str(err))


func _on_download_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		error_occurred.emit("Download failed (code: %d, result: %d)" % [response_code, result])
		return

	state_changed.emit("extracting", 1.0)
	_extract_zip()


func _extract_zip() -> void:
	var reader := ZIPReader.new()
	var err := reader.open(_download_path)
	if err != OK:
		error_occurred.emit("Failed to open ZIP file: " + str(err))
		return

	var files := reader.get_files()
	for file_path in files:
		# Zip already contains paths like "addons/ziva_agent/..."
		if not file_path.begins_with("addons/ziva_agent/"):
			continue

		if file_path.ends_with("/"):
			DirAccess.make_dir_recursive_absolute("res://" + file_path)
			continue

		var data := reader.read_file(file_path)
		var dest := "res://" + file_path
		var dir_path := dest.get_base_dir()
		DirAccess.make_dir_recursive_absolute(dir_path)

		var f := FileAccess.open(dest, FileAccess.WRITE)
		if f == null:
			push_warning("ZivaInstaller: Could not write: " + dest)
			continue
		f.store_buffer(data)
		f.close()

	reader.close()

	# Clean up temp file
	DirAccess.remove_absolute(_download_path)

	state_changed.emit("complete", 1.0)


func _get_platform_suffix() -> String:
	var os_name := OS.get_name()
	match os_name:
		"Windows":
			if OS.has_feature("arm64"):
				return "windows-arm64"
			return "windows-x64"
		"macOS":
			return "macos-universal"
		"Linux":
			if OS.has_feature("arm64"):
				return "linux-arm64"
			return "linux-x64"
	return ""
