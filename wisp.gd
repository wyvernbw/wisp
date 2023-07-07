# 🔥 wisp.gd, state made easy
class_name Wisp
extends Node

class State:
	signal transition(state)

	var name = ""
	func enter(owner: Node) -> Wisp.State:
		return self
	func exit(owner: Node) -> void:
		pass

	func wisp_process(owner: Node, delta: float) -> State:
		return self
	func wisp_physics_process(owner: Node, delta: float) -> State:
		return self
	func wisp_input(owner: Node, event: InputEvent) -> State:
		return self
	func use_transition(new_state: State) -> Callable:
		return func() -> void:
			transition.emit(new_state)

class StateMachine:
	signal state_changed(state)

	var current_state: State
	var owner: Node
	var disabled: bool = false

	static func create(new_owner: Node, initial_state: State) -> StateMachine:
		var sm = StateMachine.new(new_owner, initial_state)
		return sm

	func disable() -> void:
		if current_state == null:
			return
		# current_state.disconnect('transition', self, 'transition')
		current_state.transition.disconnect(self.transition)
		current_state.exit(owner)
		current_state = null
		disabled = true

	func enable(state: State) -> void:
		disabled = false
		current_state = state
		# current_state.connect('transition', self, 'transition')
		current_state.transition.connect(self.transition)
		current_state.enter(owner)

	func _init(new_owner: Node, state: State) -> void:
		current_state = state
		owner = new_owner
		# current_state.connect('transition', self, 'transition')
		current_state.transition.connect(self.transition)
		current_state.enter(owner)

	func transition(new_state: State) -> void:
		if disabled or current_state == null:
			return
		# current_state.disconnect('transition', self, 'transition')
		current_state.transition.disconnect(self.transition)
		current_state.exit(owner)
		current_state = new_state
		# current_state.connect('transition', self, 'transition')
		current_state.transition.connect(self.transition)
		state_changed.emit(current_state)
		var res = await current_state.enter(owner)
		# res = yield(res, 'completed')
		if not res == current_state:
			transition(res)

	func process(delta: float) -> void:
		if current_state == null:
			return
		var new_state = current_state.wisp_process(owner, delta)
		if new_state != current_state:
			transition(new_state)	
	func physics_process(delta: float) -> void:
		if current_state == null:
			return
		var new_state = current_state.wisp_physics_process(owner, delta)
		if new_state != current_state:
			transition(new_state)
	func input(event: InputEvent) -> void:
		if current_state == null:
			return
		var new_state = current_state.wisp_input(owner, event)
		if new_state != current_state:
			transition(new_state)
	func debug() -> String:
		if disabled:
			return "disabled"
		else:
			return current_state.name
		
static func use_state_machine(owner: Node, initial_state: State) -> StateMachine:
	return StateMachine.create(owner, initial_state)
