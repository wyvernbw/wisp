# <img src="./icon.gif" style="image-rendering: pixelated"></img> wisp

(sprite from Terraria)

**Wisp** is a very minimal
script (<100 lines) for all your state machine logic:

- **Easy to use**: You can create a state machine in a few lines of code
- **Concurrent**: You can have multiple state machines running at the same time
- **Minimal**: as little overhead as possible and easy to install
- **Full Control**: your classes, your code, your game

## Install

In your project folder, run:

```bash
git submodule add https://github.com/wyvernbw/wisp
```

If you are using godot 4, run these commands after cloning the repo:

```bash
cd wisp # or wherever you cloned the repo
git switch @godot4
```

done. You can now use the script in your project. Otherwise, you can just copy
the script into a new file in your project.

## Usage

- [Getting Started](#getting-started)
  - [Defining States](#defining-states)
  - [Creating a State Machine](#creating-a-state-machine)
- [API](#api)
  - [State](#state)
    - [enter](#enter)
    - [exit](#exit)
    - [wisp_process](#wisp_process)
    - [wisp_physics_process](#wisp_physics_process)
    - [wisp_input](#wisp_input)

### Get started

#### Defining States

States are just classes that inherit from `Wisp.State`.

```gdscript
# Player.gd
class_name Player
extends KinematicBody2D

class IdleState extends Wisp.State:
	func _enter():
		print("Entering Idle State")
```

or

```gdscript
# IdleState.gd
class_name IdleState
extends Wisp.State

func _enter():
	print("Entering Idle State")
```

The [enter](#enter) and [exit](#exit) functions are called when transitioning states.

Note that the [wisp_process](#wisp_process), [wisp_physics_process](#wisp_physics_process), and [wisp_input](#wisp_input) functions
all return a state to transition to. If you want to stay in the same state,
return `self`.

```gdscript
class ExampleState extends Wisp.State:
	func wisp_input(owner: Node, event: InputEvent) -> Wisp.State:
		if event.is_action_pressed("jump"):
			return JumpState.new()
		return self
```

[enter](#enter) also supports returning a new state. You can also use `yield` to wait before transitioning. This is useful for states that will always transition to a new state after a certain amount of time.
**WARNING**: returning a new instance of the same class will cause an infinite loop and crash your game!
_NOTE_: before, you could use the 'transition' signal to transition to a new state. While this is still supported, it is recommended to use the return value instead.

```gdscript
class ExampleState extends Wisp.State:
	func enter(owner: Node) -> void:
		# do stuff
		yield(get_tree().create_timer(1), "timeout")
		return JumpState.new()
```

#### Creating a state machine

For this, use `Wisp.use_state_machine()`. This will return a `StateMachine`
object.

```gdscript
func use_state_machine(owner: Node, initial_state: State) -> StateMachine
```

Example:

```gdscript
onready var state_machine = Wisp.use_state_machine(self, IdleState)
```

then, in your `_process()`, `_physics_process()`, or `_input()` functions,
simply call `state_machine.process()`, `state_machine.physics_process()`, or
`state_machine.input()`, respectively.

```gdscript
func _process(delta):
	state_machine.process(delta)

func _physics_process(delta):
	state_machine.physics_process(delta)

func _input(event):
	state_machine.input(event)
```

Feel free to opt out of calling any of these functions if you don't need
to.

## API

### State

#### enter

called when entering the state

```gdscript
func enter(owner: Node) -> void
```

#### exit

called when exiting the state

```gdscript
func exit(owner: Node) -> void
```

#### wisp_process

called every frame, returns a state to transition to

```gdscript
func wisp_process(owner: Node, delta: float) -> State
```

#### wisp_physics_process

called every physics frame, returns a state to transition to

```gdscript
func wisp_physics_process(owner: Node, delta: float) -> State
```

#### wisp_input

called every input event, returns a state to transition to

```gdscript
func wisp_input(owner: Node, event: InputEvent) -> State
```

## Roadmap

- [x] Basic state logic
- [x] Concurrency
- [ ] pushdown automata
