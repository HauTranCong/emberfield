extends Node
## Backend service singleton — handles authentication and user data fetching.
## Replace the placeholder HTTP calls with your real backend endpoints.
##
## Usage from anywhere:
##   BackendService.authenticate("user", "pass")
##   await BackendService.auth_completed
##   if BackendService.is_authenticated:
##       var data = BackendService.user_data

signal auth_completed(success: bool, message: String)
signal user_data_loaded(success: bool)

# ── State ──────────────────────────────────────────────
var is_authenticated := false
var user_data: Dictionary = {}   # Populated after successful load
var auth_token: String = ""

# ── Nodes (created at runtime) ─────────────────────────
var _http_auth: HTTPRequest
var _http_data: HTTPRequest

func _ready() -> void:
	_http_auth = HTTPRequest.new()
	_http_auth.name = "HTTPAuth"
	add_child(_http_auth)
	_http_auth.request_completed.connect(_on_auth_response)

	_http_data = HTTPRequest.new()
	_http_data.name = "HTTPData"
	add_child(_http_data)
	_http_data.request_completed.connect(_on_data_response)


# ── Public API ─────────────────────────────────────────

## Call this to start the full login + data-load pipeline.
## Emits auth_completed when auth resolves, then user_data_loaded when data is fetched.
func authenticate(username: String, password: String) -> void:
	is_authenticated = false
	user_data.clear()
	auth_token = ""

	# ---- PLACEHOLDER — swap with your real endpoint ----
	# Example: _http_auth.request("https://api.example.com/auth",
	#     ["Content-Type: application/json"],
	#     HTTPClient.METHOD_POST,
	#     JSON.stringify({"username": username, "password": password}))

	# Simulate a network round-trip so the loading screen is visible
	await get_tree().create_timer(1.0).timeout
	_simulate_auth_success(username)


## Fetch player profile / inventory / world state after auth.
func load_user_data() -> void:
	# ---- PLACEHOLDER — swap with your real endpoint ----
	# Example: _http_data.request("https://api.example.com/user/data",
	#     ["Authorization: Bearer " + auth_token])

	# Simulate loading delay
	await get_tree().create_timer(0.8).timeout
	_simulate_data_success()


func logout() -> void:
	is_authenticated = false
	user_data.clear()
	auth_token = ""


# ── Placeholder Simulation ─────────────────────────────

func _simulate_auth_success(username: String) -> void:
	auth_token = "placeholder_token_12345"
	is_authenticated = true
	auth_completed.emit(true, "Welcome, %s!" % username)

func _simulate_data_success() -> void:
	# Mimic the shape of data your backend would return
	user_data = {
		"display_name": "Player",
		"gold": 100,
		"max_health": 100,
		"attack_damage": 10,
		"defense": 0,
		"inventory": [],
	}
	user_data_loaded.emit(true)


# ── Real HTTP Callbacks (wired up for when you integrate) ──

func _on_auth_response(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var json: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("token"):
			auth_token = json["token"]
			is_authenticated = true
			auth_completed.emit(true, "Authenticated")
			return
	auth_completed.emit(false, "Auth failed (HTTP %d)" % response_code)

func _on_data_response(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var json: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json is Dictionary:
			user_data = json
			user_data_loaded.emit(true)
			return
	user_data_loaded.emit(false)
