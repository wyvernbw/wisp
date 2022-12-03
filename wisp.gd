# 🔥 wisp.gd, state made easy
class_name Wisp
extends Node

class State:
	var name = ""
	func enter(owner) -> void:
		pass
	func exit(owner) -> void:
		pass

	func wisp_process(owner, delta) -> State:
		return self
	func wisp_physics_process(owner, delta) -> State:
		return self
	func wisp_input(owner, event) -> State:
		return self

class StateMachine:
	var current_state: State
	var owner: Node

	static func create(new_owner: Node, initial_state: State) -> StateMachine:
		var sm = StateMachine.new(new_owner, initial_state)
		return sm

	func _init(new_owner: Node, state: State) -> void:
		current_state = state
		owner = new_owner
		current_state.enter(owner)

	func transition(new_state: State) -> void:
		current_state.exit(owner)
		new_state.enter(owner)
		current_state = new_state

	func process(delta) -> void:
		var new_state = current_state.wisp_process(owner, delta)
		if new_state != current_state:
			transition(new_state)	
	func physics_process(delta) -> void:
		var new_state = current_state.wisp_physics_process(owner, delta)
		if new_state != current_state:
			transition(new_state)
	func input(event) -> void:
		var new_state = current_state.wisp_input(owner, event)
		if new_state != current_state:
			transition(new_state)
		
func use_state_machine(owner: Node, initial_state: State) -> StateMachine:
	return StateMachine.create(owner, initial_state)