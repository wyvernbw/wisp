# <img src="./icon.gif" style="image-rendering: pixelated"></img> wisp

(sprite from Terraria)

**Wisp** is a very minimal
script (<100 lines) for all your state machine logic:

- **Easy to use**: You can create a state machine in a few lines of code.
- **Code first**: No weird state trees with nodes. It's all code.
- **Fully async first**: Create complex asynchronous state machines with coroutines.
- **Minimal**: as little overhead as possible and easy to install.
- **Full Control**: your classes, your code.

## Versions

- godot 4: you are here
- godot 3: https://github.com/wyvernbw/wisp/tree/main

## Quickstart

### Installation

In your project folder, run:

```bash
git submodule add https://github.com/wyvernbw/wisp
cd wisp
git switch godot4
```

done. You can now use the script in your project. Otherwise, you can just copy
the script into a new file in your project.

### Usage

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

