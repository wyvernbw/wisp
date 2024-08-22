# 🔥 wisp.gd, state made easy
class_name Wisp
extends Node

class State:
	extends RefCounted

	signal transition(state)

	func name() -> String:
		return "unnamed"
	func enter(owner) -> Wisp.State:
		return self
	func exit(owner) -> void:
		pass
	func process(owner, delta: float) -> State:
		return self
	func physics_process(owner, delta: float) -> State:
		return self
	func input(owner, event: InputEvent) -> State:
		return self
	func use_transition(new_state: State) -> Callable:
		return func() -> void:
			transition.emit(new_state)

class StateMachine:
	extends Node

	signal state_changed(state)

	var current_state: State
	var target: Node
	var disabled: bool = false

	static func create(new_target: Node, initial_state: State) -> StateMachine:
		var sm = await StateMachine.new(new_target, initial_state)
		return sm

	func disable() -> void:
		if current_state == null:
			return
		# current_state.disconnect('transition', self, 'transition')
		current_state.transition.disconnect(self.transition)
		current_state.exit(target)
		current_state = null
		disabled = true

	func enable(state: State) -> void:
		disabled = false
		current_state = state
		# current_state.connect('transition', self, 'transition')
		current_state.transition.connect(self.transition)
		var old_state = current_state
		var res = await current_state.enter(target)
		# res = yield(res, 'completed')
		# check for transition between await point
		if not res == current_state and old_state == current_state:
			transition(res)

	func _init(new_target: Node, state: State) -> void:
		current_state = state
		target = new_target
		# current_state.connect('transition', self, 'transition')
		current_state.transition.connect(self.transition)
		var old_state = current_state
		var res = await current_state.enter(target)
		# res = yield(res, 'completed')
		# check for transition between await point
		if not res == current_state and old_state == current_state:
			transition(res)

	func transition(new_state: State) -> void:
		if disabled or current_state == null:
			return
		# current_state.disconnect('transition', self, 'transition')
		current_state.transition.disconnect(self.transition)
		current_state.exit(target)
		current_state = new_state
		# current_state.connect('transition', self, 'transition')
		current_state.transition.connect(self.transition)
		state_changed.emit(current_state)
		var state = current_state
		var res = await current_state.enter(target)
		# res = yield(res, 'completed')
		# check for transition between await point
		if not res == current_state and state == current_state:
			transition(res)

	func process(delta: float) -> void:
		if current_state == null:
			return
		var new_state = current_state.process(target, delta)
		if new_state != current_state:
			transition(new_state)	
	func physics_process(delta: float) -> void:
		if current_state == null:
			return
		var new_state = current_state.physics_process(target, delta)
		if new_state != current_state:
			transition(new_state)
	func input(event: InputEvent) -> void:
		if current_state == null:
			return
		var new_state = current_state.input(target, event)
		if new_state != current_state:
			transition(new_state)
	func debug() -> String:
		if disabled:
			return "disabled"
		else:
			return current_state.name()
		
static func use_state_machine(owner: Node, initial_state: State) -> StateMachine:
	return await StateMachine.create(owner, initial_state)
