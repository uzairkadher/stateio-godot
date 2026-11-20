class_name EventBus
extends RefCounted
## Lightweight headless-safe event bus connecting simulation, AI, presentation, UI, and audio.
## Every event carries a plain Dictionary payload so listeners stay decoupled.

var _listeners: Dictionary = {}
var _event_log: Array = []
var record_history: bool = false
var max_history: int = 512

func subscribe(event_name: String, callback: Callable) -> void:
	if not _listeners.has(event_name):
		_listeners[event_name] = []
	var list: Array = _listeners[event_name]
	if not list.has(callback):
		list.append(callback)

func unsubscribe(event_name: String, callback: Callable) -> void:
	if not _listeners.has(event_name):
		return
	var list: Array = _listeners[event_name]
	list.erase(callback)

func emit_event(event_name: String, payload: Dictionary = {}) -> void:
	if record_history:
		_event_log.append({"event": event_name, "payload": payload.duplicate(true)})
		if _event_log.size() > max_history:
			_event_log.pop_front()
	if not _listeners.has(event_name):
		return
	var list: Array = _listeners[event_name].duplicate()
	for cb in list:
		if cb is Callable and cb.is_valid():
			cb.call(payload)

func get_history() -> Array:
	return _event_log.duplicate(true)

func clear_history() -> void:
	_event_log.clear()

func clear_all() -> void:
	_listeners.clear()
	_event_log.clear()
