# 🔥 wisp.gd, state made easy
class_name Wisp
extends Node

class State:
	extends Resource
	signal transition(state)
	signal new_effect(id)

	func name() -> String:
		return "Unnamed"
	
	var valid := false
	var current_effect := -1

	func consume_effect() -> State:
		current_effect = -1
		return self

	func recv_effect(id: int) -> int:
		while yield(self, "new_effect") != id:
			pass
		return id

	func send_effect(id: int) -> State:
		self.current_effect = id
		self.emit_signal("new_effect", id)
		return self

	func send_effect_after(id: int, promise: GDScriptFunctionState) -> State:
		yield(promise, "completed")
		self.send_effect(id)
		return self

	func poll_effect(id: int, value: bool) -> bool:
		if self.current_effect != -1:
			if self.current_effect == id:
				self.consume_effect()
				return true
		return value

	class EffectResult:
		enum EffectStatus {
			Done,
			HasData		
		}
		var inner := {}

		func _init(value: Dictionary) -> void:
			assert(value.keys().size() == 1)
			self.inner = value

		func key() -> int:
			return self.inner.keys()[0]
			
		func is_done() -> bool:
			return self.key() == EffectStatus.Done

		func has_data() -> bool:
			return self.key() == EffectStatus.HasData

		func data():
			return self.inner.get(EffectStatus.HasData, null)

		func data_unchecked():
			return self.inner[EffectStatus.HasData]

	func await_effect_result(id: int, value: GDScriptFunctionState) -> EffectResult:
		var res = WispSelector.new().select([
			self.recv_effect(id),
			value,
		])
		match yield(res, "completed"):
			{ 0: id }:
				self.consume_effect()
				return EffectResult.new({
					EffectResult.EffectStatus.Done: id		
				})
			{ 0: _ }:
				assert(false, "unreachable")

			{ 1: null }:
				return EffectResult.new({
					EffectResult.EffectStatus.Done: id
				})
			{ 1: var data }:
				return EffectResult.new({
					EffectResult.EffectStatus.HasData: data
				})
		return false

	func await_effect(id: int, value: GDScriptFunctionState, default = null):
		var res = yield(await_effect_result(id, value), "completed")
		if res.has_data():
			return res.data_unchecked()
		return default
		

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
	func name() -> String:
		return "Disabled"

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
		if current_state is Reducer:
			assert(new_state == null, "returned state from reducer process function. this transition is ignored.")
			return
		if new_state != current_state:
			transition(new_state)

	func physics_process(delta: float) -> void:
		if current_state is DisabledState:
			return
		var new_state = current_state.wisp_physics_process(owner, delta)
		if current_state is Reducer:
			assert(new_state == null, "returned state from reducer physics_process function. this transition is ignored.")
			return
		if new_state != current_state:
			transition(new_state)

	func input(event: InputEvent) -> void:
		if current_state is DisabledState:
			return
		var old_state = current_state
		var new_state = current_state.wisp_input(owner, event)
		if new_state is GDScriptFunctionState:
			new_state = yield (new_state, 'completed')
		if current_state is Reducer:
			assert(new_state == null, "returned state from reducer input function. this transition is ignored.")
			return
		if new_state != current_state and old_state == current_state:
			transition(new_state)

	func unhandled_input(event: InputEvent) -> void:
		if current_state is DisabledState:
			return
		var old_state = current_state
		var new_state = current_state.wisp_unhandled_input(owner, event)
		if new_state is GDScriptFunctionState:
			new_state = yield (new_state, 'completed')
		if current_state is Reducer:
			assert(new_state == null, "returned state from reducer unhandled_input function. this transition is ignored.")
			return
		if new_state != current_state and old_state == current_state:
			transition(new_state)

	func handle_command(command: int) -> void:
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
			return current_state.name()

	func send_effect(id: int) -> StateMachine:
		self.current_state.send_effect(id)
		return self
		
static func use_state_machine(owner, initial_state: State) -> StateMachine:
	return StateMachine.create(owner, initial_state)

class Reducer:
	extends State

	func handle_command(entity, command: int) -> State:
		return self

class WispSelector:
	extends Reference
	signal promise_completed

	var done = false

	static func wrap(object: Object, signal_name: String):
		return yield(object, signal_name)

	func select(
		promises: Array
	) -> Dictionary:
		var signal_map = {}
		var idx = 0
		var promise_refs := []
		for promise in promises:
			assert(promise is GDScriptFunctionState, promise)
			signal_map[idx] = {
				"finished": false,
				"value": null
			}
			var p = _promise(promise)
			promise_refs.append(p)
			p.connect(
				'completed', self, '_on_promise_completed', [signal_map, idx], CONNECT_ONESHOT | CONNECT_REFERENCE_COUNTED
			)
			idx += 1
		yield(self, "promise_completed")
		done = true	
		for branch in signal_map.keys():
			if signal_map[branch].finished:
				return { branch: signal_map[branch].value }
		return {}

	func _on_promise_completed(value, signal_map, idx: int):
		if done:
			return
		signal_map[idx] = {
			"finished": true,
			"value": value
		}
		emit_signal("promise_completed")

		
	static func _promise(state: GDScriptFunctionState):
		var res = yield(state, "completed")
		if res == null:
			return Maybe.new()
		else:
			return res
