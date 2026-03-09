@tool
extends Node

var _server: TCPServer
var _dock: VBoxContainer
var _clients: Array = []

const PORT := 8099


class ClientConnection:
	var peer: StreamPeerTCP
	var buffer: String = ""

	func _init(p: StreamPeerTCP) -> void:
		peer = p


func _ready() -> void:
	_server = TCPServer.new()
	var err := _server.listen(PORT, "127.0.0.1")
	if err != OK:
		push_error("ZivaInstaller TestAPI: Failed to listen on port %d: %s" % [PORT, str(err)])
		return
	print("ZivaInstaller TestAPI: Listening on 127.0.0.1:%d" % PORT)


func set_dock(dock: Variant) -> void:
	_dock = dock


func _process(_delta: float) -> void:
	if _server == null:
		return

	# Accept new connections
	while _server.is_connection_available():
		var peer := _server.take_connection()
		if peer:
			_clients.append(ClientConnection.new(peer))

	# Process existing connections
	var to_remove: Array[int] = []
	for i in range(_clients.size()):
		var client: ClientConnection = _clients[i]
		client.peer.poll()

		var status := client.peer.get_status()
		if status == StreamPeerTCP.STATUS_NONE or status == StreamPeerTCP.STATUS_ERROR:
			to_remove.append(i)
			continue

		if status != StreamPeerTCP.STATUS_CONNECTED:
			continue

		var available := client.peer.get_available_bytes()
		if available > 0:
			var data := client.peer.get_data(available)
			if data[0] == OK:
				client.buffer += data[1].get_string_from_utf8()

		# Check if we have a complete HTTP request
		if "\r\n\r\n" in client.buffer:
			var response := _handle_request(client.buffer)
			client.peer.put_data(response.to_utf8_buffer())
			to_remove.append(i)

	# Remove processed/dead connections (reverse order)
	to_remove.reverse()
	for i in to_remove:
		_clients.remove_at(i)


func _handle_request(raw: String) -> String:
	var first_line := raw.split("\r\n")[0]
	var parts := first_line.split(" ")
	if parts.size() < 2:
		return _http_response(400, '{"error": "bad request"}')

	var method := parts[0]
	var path := parts[1]

	match [method, path]:
		["GET", "/ready"]:
			return _http_response(200, '{"ready": true}')

		["GET", "/state"]:
			return _get_state_response()

		["GET", "/screenshot"]:
			return _get_screenshot_response()

		["POST", "/install"]:
			return _post_install_response()

		["POST", "/restart"]:
			return _post_restart_response()

		["GET", "/ziva-installed"]:
			return _get_ziva_installed_response()

	return _http_response(404, '{"error": "not found"}')


func _get_state_response() -> String:
	if _dock == null:
		return _http_response(500, '{"error": "dock not initialized"}')

	var state: String = _dock.get_state()
	var progress: float = _dock.get_progress()
	return _http_response(200, '{"state": "%s", "progress": %s}' % [state, str(progress)])


func _get_screenshot_response() -> String:
	var viewport := EditorInterface.get_base_control().get_viewport()
	var img := viewport.get_texture().get_image()

	var path := OS.get_user_data_dir() + "/ziva_installer_screenshot.png"
	img.save_png(path)

	return _http_response(200, '{"path": "%s"}' % path.replace("\\", "\\\\"))


func _post_install_response() -> String:
	if _dock == null:
		return _http_response(500, '{"error": "dock not initialized"}')

	_dock.start_install()
	return _http_response(200, '{"started": true}')


func _post_restart_response() -> String:
	EditorInterface.restart_editor()
	return _http_response(200, '{"restarting": true}')


func _get_ziva_installed_response() -> String:
	var installed := FileAccess.file_exists("res://addons/ziva_agent/ziva_agent.gdextension")
	return _http_response(200, '{"installed": %s}' % str(installed).to_lower())


func _http_response(code: int, body: String) -> String:
	var status_text := "OK"
	match code:
		200:
			status_text = "OK"
		400:
			status_text = "Bad Request"
		404:
			status_text = "Not Found"
		500:
			status_text = "Internal Server Error"

	return "HTTP/1.1 %d %s\r\nContent-Type: application/json\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s" % [code, status_text, body.length(), body]


func _exit_tree() -> void:
	if _server:
		_server.stop()
		_server = null
