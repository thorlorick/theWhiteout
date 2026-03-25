# VisionComponent — Inspector Reference

---

## Setup

| Variable | Default | What it does |
|---|---|---|
| `wall_collision_mask` | `1` | Which physics layers rays check. Must include your wall layer AND player layer. |

---

## Rays

| Variable | Default | What it does |
|---|---|---|
| `ray_count` | `5` | Number of rays in the fan. More = smoother detection, slightly more CPU. |
| `ray_length` | `200px` | How far each ray reaches. Your sight distance in pixels. |
| `cone_half_spread` | `10°` | Half the cone width in degrees. 10 = 20° total cone. Try 25–35 for wider vision. |

---

## Distances

| Variable | Default | What it does |
|---|---|---|
| `alert_distance` | `150px` | Yellow ring. Guard notices something — meter starts filling. ~9 tiles. |
| `danger_distance` | `100px` | Orange ring. Confirmed sighting — triggers chase. ~6 tiles. |
| `strike_distance` | `40px` | Red ring. Gap closed — triggers attack. ~2 tiles. |

---

## Detection

| Variable | Default | What it does |
|---|---|---|
| `alert_threshold` | `0.3` | White marker on the bar. How full before alert fires. 0.0–1.0. |
| `fill_rate_center` | `2.5/sec` | How fast the meter fills when the player is dead centre of the cone. |
| `fill_rate_edge` | `1.0/sec` | How fast the meter fills when the player is at the cone's edge. Slower = peripheral vision. |
| `drain_rate` | `1.5/sec` | How fast the meter empties when the player leaves view. Higher = faster forgetting. |
| `lost_timer_max` | `0.5sec` | Grace period after a confirmed target leaves view before the guard loses them. |

---

## Sweep + Look Around

| Variable | Default | What it does |
|---|---|---|
| `sweep_angle` | `25°` | How far the cone oscillates left/right while moving. |
| `sweep_speed` | `60°/sec` | How fast the cone oscillates. |
| `look_angles` | `[-40, 0, 40, 0]` | The head-turn sequence at idle, in degrees. |
| `look_step_time` | `0.8sec` | How long the guard pauses at each angle in the look-around sequence. |
