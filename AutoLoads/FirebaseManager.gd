extends Node
class_name FirebaseHandeler

const PROJECT_ID : String = "godotwebrtc"

const BASE_URL := "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents" % PROJECT_ID

var http : HTTPRequest
var http_ic : HTTPRequest
var http_requested : bool = false
var offer_uploaded : bool = false
var ice_uploaded : bool = false

var ic_http_requested : bool = false

enum RequestTYPE{
	NONE,
	GET_ROOM,
	UPLOAD_OFFER,
	UPLOAD_ANSWER,
	GET_ANSWER,
	UPLOAD_ICE,
	GET_ICE
}
enum ICRequestTYPE{
	NONE,
	UPLOAD_ICE,
	GET_ICE
}
var current_request_type : RequestTYPE = RequestTYPE.NONE
var current_ic_request_type : ICRequestTYPE = ICRequestTYPE.NONE

signal room_recieved(type:String , sdp : String)
signal offer_answered(type:String , sdp : String)
signal offer_answer_unavailable
signal ice_candidate_recieved(sender, media, index, candidate)

var room_requested : bool = false
func _ready() -> void:
	http = HTTPRequest.new()
	add_child(http)
	http_ic = HTTPRequest.new()
	add_child(http_ic)
	
	http.request_completed.connect(_on_request_completed)
	http_ic.request_completed.connect(on_ice_http_req_completed)

func _on_request_completed(result, response_code, headers, body):
	match current_request_type:
		RequestTYPE.NONE:
			return
		RequestTYPE.GET_ROOM:
			room_requested = true
			handle_recieved_room(body)
		RequestTYPE.UPLOAD_OFFER:
			offer_uploaded = true
		RequestTYPE.UPLOAD_ANSWER:
			pass
		RequestTYPE.GET_ANSWER:
			handle_recieved_answer(body)

func on_ice_http_req_completed(result, response_code, headers, body):
	match current_ic_request_type:
		ICRequestTYPE.GET_ICE:
			ic_http_requested = false
			handle_recieved_ice(body)
		ICRequestTYPE.UPLOAD_ICE:
			ic_http_requested = false
			ice_uploaded = true


func upload_offer(_room_code : String , type : String , sdp : String):
	var body := {
		"fields": {
			"offer_type": {
				"stringValue": type
			},
			"offer_sdp": {
				"stringValue": sdp
			},
			"host_id": {
				"integerValue": 1
			}
		}
	}
	var body_json = JSON.stringify(body)
	var headers := [
		"Content-Type: application/json"
	]
	var url = BASE_URL + "/rooms/" + _room_code
	current_request_type = RequestTYPE.UPLOAD_OFFER
	var err = http.request(url , headers , HTTPClient.METHOD_PATCH , body_json)

func get_room(room_code : String):
	if room_requested : return
	var url = BASE_URL + "/rooms/" + room_code
	current_request_type = RequestTYPE.GET_ROOM
	var err = http.request(url)
	room_requested = true


func handle_recieved_room(_body):
	var body_json = JSON.new()
	var err = body_json.parse(_body.get_string_from_utf8())
	if err != OK:
		return
	
	var data = body_json.data
	#if !data.has("fields"): 
		#print("field not available")
	#return
	var fields = data["fields"]
	var offer_type = fields["offer_type"]["stringValue"]
	var offer_sdp  = fields["offer_sdp"]["stringValue"]
	room_recieved.emit(offer_type , offer_sdp)


func upload_answer(_room_code : StringName , _type : String , _sdp : String):
	var body = {
		"fields": {
			"answer_type": {
				"stringValue": _type
			},
			"answer_sdp": {
				"stringValue": _sdp
			}
		}
	}
	
	var body_json = JSON.stringify(body)
	var headers := [
		"Content-Type: application/json"
	]
	var url = BASE_URL + "/rooms/" + _room_code \
+ "?updateMask.fieldPaths=answer_type" \
+ "&updateMask.fieldPaths=answer_sdp"
	current_request_type = RequestTYPE.UPLOAD_ANSWER
	var err = http.request(url , headers , HTTPClient.METHOD_PATCH , body_json)
	

func get_answer(_room_code : String):
	if !offer_uploaded:
		return
	if http_requested:
		return
	var url = BASE_URL + "/rooms/" + _room_code
	current_request_type = RequestTYPE.GET_ANSWER
	http_requested = true
	var err = http.request(url)


func handle_recieved_answer(_body):
	http_requested = false
	var body_json = JSON.new()
	var err = body_json.parse(_body.get_string_from_utf8())
	var data = body_json.data
	if data == null : return
	var fields = data["fields"]
	
	if !fields.has("answer_type"):
		offer_answer_unavailable.emit()
		return
	
	var answer_type = fields["answer_type"]["stringValue"]
	var answer_sdp = fields["answer_sdp"]["stringValue"]
	offer_answered.emit(answer_type , answer_sdp)
	

func upload_ice_candidates(_room_code : String , _media : String , _candidates : String , _index : int , _sender : String):
	if ic_http_requested:
		return
	var body = {
		"fields": {
			"sender":{
				"stringValue": _sender
			},
			"media": {
				"stringValue": _media
			},
			"index": {
				"stringValue": str(_index)
			},
			"candidates": {
				"stringValue": _candidates
			}
		}
	}
	
	var body_json = JSON.stringify(body)
	var headers = ["Content-Type: application/json"]
	var url = BASE_URL + "/rooms/%s/candidates" % _room_code
	current_ic_request_type  = ICRequestTYPE.UPLOAD_ICE
	var err = http_ic.request(url, headers, HTTPClient.METHOD_POST, body_json)
	ic_http_requested = true


func get_ice_candidates(room_code : String):
	if ic_http_requested: return
	var url = BASE_URL + "/rooms/" + room_code + "/candidates"
	current_ic_request_type = ICRequestTYPE.GET_ICE
	var err = http_ic.request(url , [] , HTTPClient.METHOD_GET)
	ic_http_requested = true
	if err != OK:
		return

func handle_recieved_ice(_body):
	var json = JSON.new()
	var err = json.parse(_body.get_string_from_utf8())
	
	if err != OK:
		print(err)
		return
	
	var data = json.data
	
	if !data.has("documents"):
		offer_answer_unavailable.emit()
		return
	
	var documents = data["documents"]
	
	for document in documents:
		
		var fields = document["fields"]
		
		var sender = fields["sender"]["stringValue"]
		var media = fields["media"]["stringValue"]
		var index = int(fields["index"]["stringValue"])
		var candidate = fields["candidates"]["stringValue"]
		ice_candidate_recieved.emit(sender, media, index, candidate)
