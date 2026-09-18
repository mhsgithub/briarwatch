class_name RecoveryComponent
extends Node
## One non-stacking potion recovery. Pauses with gameplay and never survives death.
var health: HealthComponent
var remaining: float = 0.0
var rate: float = 0.0

func start(amount: float, duration: float) -> bool:
	if remaining > 0 or health.current <= 0 or health.current >= health.maximum:
		return false
	remaining = maxf(0.1, duration)
	rate = amount / remaining
	return true

func cancel() -> void:
	remaining = 0
	rate = 0

func _physics_process(delta: float) -> void:
	if remaining <= 0:
		return
	if health.current <= 0:
		cancel()
		return
	var step := minf(delta, remaining)
	health.heal(rate * step)
	remaining = maxf(0, remaining - step)
