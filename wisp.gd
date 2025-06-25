# 🔥 wisp.gd, state made easy
class_name Wisp
extends Node

class State:
	extends Resource
	signal transition(state)

	var name = ""
	var valid := false

	func enter(owner) -> Wisp.State:
		return self
	func exit(owner) -> void:
		pass

	func guard(owner, current_state: State) -> bool:
		return true
	func exit_guard(owner, next_state: State) -> bool:
		return true
	func wisp_process(owner, delta: float) -> State:
		return self
	func wisp_physics_process(owner, delta: float) -> State:
		return self
	func wisp_input(owner, event: InputEvent) -> State:
		return self
	func wisp_unhandled_input(owner, event: InputEvent) -> State:
		return self
	func is_valid() -> bool:
		return valid

class DisabledState extends State:
	func _init():
		name = "Disabled"

class StateMachine:
	signal pretransition(new_state)
	signal post_transition(new_state)

	var current_state: State
	var owner: Node

	static func create(new_owner: Node, initial_state: State) -> StateMachine:
		var sm = StateMachine.new(new_owner, initial_state)
		return sm

	func disable() -> void:
		if current_state is DisabledState:
			return
		self.transition(DisabledState.new(), false)

	func enable(state: State) -> void:
		self.transition(state, false)

	func _init(new_owner: Node, state: State) -> void:
		owner = new_owner
		current_state = DisabledState.new()
		current_state.connect('transition', self, 'transition')
		self.transition(state, false)

	func transition(new_state: State, use_yield: bool = true) -> void:
		if use_yield:
			yield(owner.get_tree(), 'idle_frame')
		# if current_state is DisabledState:
		# 	return
		# Guard check
		var old_state = current_state
		var guard_result = new_state.guard(owner, current_state)
		var exit_guard_result = current_state.exit_guard(owner, new_state)
		if guard_result is GDScriptFunctionState:
			guard_result = yield (guard_result, 'completed')
		if exit_guard_result is GDScriptFunctionState:
			exit_guard_result = yield (exit_guard_result, 'completed')
		if old_state != current_state:
			return
		if not guard_result:
			return
		if not exit_guard_result:
			return
		emit_signal('pretransition', new_state)
		current_state.disconnect('transition', self, 'transition')
		current_state.exit(owner)
		current_state.valid = false
		current_state = new_state
		current_state.connect('transition', self, 'transition')
		current_state.valid = true
		var new_current_state = self.current_state
		var res = current_state.enter(owner)
		if res is GDScriptFunctionState:
			res = yield (res, 'completed')
		# Transition happened between yield points, cancel current transition
		if new_current_state != self.current_state:
			return
		if not res == current_state:
			transition(res, false)
		emit_signal("post_transition", new_state)

	func process(delta: float) -> void:
		if current_state is DisabledState:
			return
		var new_state = current_state.wisp_process(owner, delta)
		if new_state != current_state:
			transition(new_state)

	func physics_process(delta: float) -> void:
		if current_state is DisabledState:
			return
		var new_state = current_state.wisp_physics_process(owner, delta)
		if new_state != current_state:
			transition(new_state)

	func input(event: InputEvent) -> void:
		if current_state is Reducer:
			return
		if current_state is DisabledState:
			return
		var old_state = current_state
		var new_state = current_state.wisp_input(owner, event)
		if new_state is GDScriptFunctionState:
			new_state = yield (new_state, 'completed')
		if new_state != current_state and old_state == current_state:
			transition(new_state)

	func unhandled_input(event: InputEvent) -> void:
		if current_state is Reducer:
			return
		if current_state is DisabledState:
			return
		var old_state = current_state
		var new_state = current_state.wisp_unhandled_input(owner, event)
		if new_state is GDScriptFunctionState:
			new_state = yield (new_state, 'completed')
		if new_state != current_state and old_state == current_state:
			transition(new_state)

	func handle_command(command: Command) -> void:
		if current_state is DisabledState:
			return
		if not current_state is Reducer:
			return
		var old_state = current_state
		var new_state = current_state.handle_command(owner, command)
		if new_state is GDScriptFunctionState:
			new_state = yield (new_state, 'completed')
		if new_state != current_state and old_state == current_state:
			transition(new_state)

	func debug() -> String:
		if current_state is DisabledState:
			return "disabled"
		else:
			return current_state.name
		
static func use_state_machine(owner, initial_state: State) -> StateMachine:
	return StateMachine.create(owner, initial_state)

class Command:
	extends Resource

	var timestamp: float
	var id_value: int

	func id() -> int:
		assert(false, "id function not implemented!")
		return 0

	func _init() -> void:
		self.timestamp = OS.get_system_time_msecs()
		self.id_value = id()

class Reducer:
	extends State

	func handle_command(entity, command: Command) -> State:
		return self
