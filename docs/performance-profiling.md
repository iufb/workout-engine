# Performance profiling (workout screen)

Baseline and regression checks for the active workout screen after consolidating `TimelineView` and moving `engine.tick` into `WorkoutSessionCoordinator`.

## Record a trace

From the repo root, with a **physical device** attached (SwiftUI lane is empty on Simulator):

```bash
SKILL_DIR=".agents/skills/swiftui-expert-skill"
python3 "$SKILL_DIR/scripts/record_trace.py" --list-devices
python3 "$SKILL_DIR/scripts/record_trace.py" \
  --device "<device name>" \
  --attach "workout-engine" \
  --stop-file /tmp/stop-workout-trace \
  --output ~/Desktop/workout-session.trace
```

On **Simulator**, use Time Profiler instead:

```bash
python3 "$SKILL_DIR/scripts/record_trace.py" \
  --template "Time Profiler" \
  --attach "workout-engine" \
  --stop-file /tmp/stop-workout-trace \
  --output ~/Desktop/workout-session.trace
```

Exercise the app: scroll Home, start a 2+ minute workout, switch phases, then open Constructor and drag-reorder phases. When done:

```bash
touch /tmp/stop-workout-trace
```

## Analyze

```bash
python3 "$SKILL_DIR/scripts/analyze_trace.py" \
  --trace ~/Desktop/workout-session.trace \
  --json-only --top 10
```

Look for:

- `swiftui-causes.top_sources` — wide invalidation chains
- `--fanin-for "ActiveWorkoutView"` — who drives updates
- Animation hitch narratives during phase transitions

Success criteria after P0: a single timeline-driven refresh path on the workout screen, no `WorkoutEngineTick` in view bodies, lower main-thread SwiftUI body rate during a running session.
