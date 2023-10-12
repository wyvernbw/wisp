# <img src="./icon.gif" style="image-rendering: pixelated"></img> wisp

(sprite from Terraria)

**Wisp** is a very minimal
script (<100 lines) for all your state machine logic:

-   **Easy to use**: You can create a state machine in a few lines of code
-   **Concurrent**: You can have multiple state machines running at the same time
-   **Minimal**: as little overhead as possible and easy to install
-   **Full Control**: your classes, your code, your game

## Install

In your project folder, run:

```bash
git submodule add https://github.com/wyvernbw/wisp
```

If you are using godot 4, run these commands after cloning the repo:

```bash
cd wisp # or wherever you cloned the repo
git switch godot4
```

done. You can now use the script in your project. Otherwise, you can just copy
the script into a new file in your project.

## Usage

### Getting Started

First, create a new class that extends Wisp.State, either as an inner class or a new file:

```gdscript
class Idle:
	extends Wisp.State

	# It's a good idea to define this function
	func name() -> String:
		return "idle"

	func enter(owner: Player) -> Wisp.State:
		print(owner, " entered idle")
		return self

	func process(owner: Player, delta: float) -> Wisp.State:
		# do stuff
		return self
```

Then, create a new state machine in your main class:

```gdscript
class_name Player
extends CharacterBody2D

var state_machine := Wisp.use_state_machine(self, Idle.new())
```

Finally, call the state machine methods from your main class:

```gdscript
func _process(delta: float) -> void:
	state_machine.process(delta)

func _physics_process(delta: float) -> void:
	state_machine.physics_process(delta)

func _input(event: InputEvent) -> void:
	state_machine.input(event)
```

### `State` Class

The `State` class is a base class for defining game states in your project. You can create custom state classes by extending this class and implementing the necessary methods.

#### Properties and Methods

-   `signal transition(state)`: A signal emitted when a state transition occurs.

-   `func name() -> String`: Returns the name of the state.

-   `func enter(owner) -> Wisp.State`: Called when a state is entered.

-   `func exit(owner) -> void`: Called when a state is exited.

-   `func process(owner, delta: float) -> State`: Called during the main game loop.

-   `func physics_process(owner, delta: float) -> State`: Called during the physics process.

-   `func input(owner, event: InputEvent) -> State`: Called when input events occur.

-   `func use_transition(new_state: State) -> Callable`: Returns a callable function to transition to a new state.

### `StateMachine` Class

The `StateMachine` class manages the current state and facilitates state transitions.

#### Properties and Methods

-   `signal state_changed(state)`: A signal emitted when the state changes.

-   `var current_state: State`: The currently active state.

-   `var target: Node`: The target object associated with the state machine.

-   `var disabled: bool = false`: A flag to disable the state machine.

-   `static func create(new_target: Node, initial_state: State) -> StateMachine`: A static factory method to create a new `StateMachine` instance.

-   `func disable() -> void`: Disables the state machine.

-   `func enable(state: State) -> void`: Enables the state machine with a specified initial state.

-   `func _init(new_target: Node, state: State) -> void`: Initializes the state machine.

-   `func transition(new_state: State) -> void`: Initiates a state transition.

-   `func process(delta: float) -> void`: Handles the main game loop processing.

-   `func physics_process(delta: float) -> void`: Handles physics processing.

-   `func input(event: InputEvent) -> void`: Handles input events.

-   `func debug() -> String`: Returns a debug string indicating the current state or "disabled" if the state machine is disabled.

### `use_state_machine` Function

A static function to create and set up a `StateMachine` for a specific owner object with an initial state.

## Roadmap

-   [x] Basic state logic
-   [x] Concurrency
-   [ ] pushdown automata

```

```
