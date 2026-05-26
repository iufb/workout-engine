# Background workout timer

The active workout keeps running while the screen is locked via `UIBackgroundModes = audio`, a silent loop (`silence_loop.wav`), and wall-clock sync in `WorkoutEngine`.

## Manual verification (physical iPhone)

Use a preset with short phases, e.g. 5 s prepare, 10 s work, 10 s rest, 2 rounds.

1. Start a workout and lock the screen for at least 35 seconds.
2. Unlock: current phase and countdown should match real elapsed time.
3. Repeat with **sounds disabled** in Settings — the timer must still advance (no phase freeze).
4. Repeat with sounds enabled — phase change bells and 3–2–1 countdown should be audible in the background.
5. During a workout, trigger an incoming call; after it ends, phase transitions should resume.

## Architecture

- Workout WAV files live under `Resources/Sounds/` and load with `subdirectory: "Sounds"`.
- `SoundPlayer.prepareForWorkoutSession()` — re-binds players after the audio session activates.
- `SoundPlayer.startSessionAudio()` — keep-alive audio (not gated on sound effect settings). Effect sounds briefly pause keep-alive so cues are audible.
- `AudioSessionManager` — `.playback` session; resumes after interruptions when possible.
- `WorkoutEngine.syncToWallClock(now:)` — maps elapsed time (minus pause) to phase index and `phaseEndsAt`.
- `WorkoutSessionCoordinator` — tick loop at `WorkoutTheme.timelineTickInterval` (0.25 s).
- `ActiveWorkoutView` — calls `coordinator.syncSession()` on `.active` and `.background`.
