# 🔥 wisp.gd, state made easy
class_name Wisp
extends Node

class State:
	extends Resource

	signal transition(state)

	var valid := false

	func name() -> String:
		return "unnamed"
	func enter(owner) -> Wisp.State:
		return self
	func exit(owner) -> void:
		pass
	func guard(owner, current_state: State) -> bool:
		return true
	func exit_guard(owner, next_state: State) -> bool:
		return true
	func process(owner, delta: float) -> State:
		return self
	func physics_process(owner, delta: float) -> State:
		return self
	func input(owner, event: InputEvent) -> State:
		return self
	func unhandled_input(owner, event: InputEvent) -> State:
		return self
	func use_transition(new_state: State) -> Callable:
		return func() -> void:
			transition.emit(new_state)

class DisabledState extends State:
	func name() -> String:
		return "Disabled"

class StateMachine:
	extends Resource

	signal state_changed(state)
	signal pretransition(state)

	var current_state: State
	var target: Node
	var disabled: bool = false

	static func create(new_target: Node, initial_state: State) -> StateMachine:
		var sm = await StateMachine.new(new_target, initial_state)
		return sm

	func disable() -> void:
		if current_state is DisabledState:
			return
		self.transition(DisabledState.new(), false)

	func enable(state: State) -> void:
		self.transition(state)

	func _init(new_target: Node, state: State) -> void:
		self.target = new_target
		self.current_state = DisabledState.new()
		self.current_state.connect('transition', self, 'transition')
		self.transition(state, false)

	func transition(new_state: State, use_yield := true) -> void:
		if use_yield:
			yield(owner.get_tree(), 'idle_frame')
		var old_state = self.current_state
		var guard_result = await new_state.guard(self.owner, self.current_state)
		var exit_guard_result = await new_state.exit_guard(self.owner, self.current_state)
		# transition happend while waiting
		if old_state != self.current_state:
			return
		if not (guard_result and exit_guard_result):
			return
		self.pretransition.emit(new_state)
		# current_state.disconnect('transition', self, 'transition')
		current_state.transition.disconnect(self.transition)
		current_state.exit(target)
		current_state.valid = false
		current_state = new_state
		# current_state.connect('transition', self, 'transition')
		current_state.transition.connect(self.transition)
		state_changed.emit(current_state)
		var new_current_state = current_state
		var res = await current_state.enter(target)
		# transition happend while waiting
		if new_current_state != self.current_state:
			return
		if not res == self.current_state:
			self.transition(res, false)

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
	func unhandled_input(event: InputEvent) -> void:
		if current_state == null:
			return
		var new_state = current_state.unhandled_input(target, event)
		if new_state != current_state:
			transition(new_state)
	func debug() -> String:
		if current_state is DisabledState:
			return "disabled"
		else:
			return current_state.name()
		
static func use_state_machine(owner: Node, initial_state: State) -> StateMachine:
	return await StateMachine.create(owner, initial_state)
