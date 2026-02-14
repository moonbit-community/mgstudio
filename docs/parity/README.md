# Bevy Parity Artifacts

This directory stores generated and curated artifacts for the Bevy parity program.

## Files

- `bevy_example_parity_matrix.md`: Generated category + per-example parity matrix.
- `bevy_example_parity.csv`: Generated machine-readable parity inventory.
- `bevy_api_parity_matrix.md`: Curated API parity matrix by subsystem/track.
- `EXAMPLE_PARITY_NOTE_TEMPLATE.md`: Template for per-example migration notes.

## Generation

```bash
python3 scripts/generate_bevy_example_parity.py
```

## Drift Check

```bash
python3 scripts/generate_bevy_example_parity.py --check
```

## Smoke Gate

```bash
./scripts/smoke_bevy_examples.sh
```

Optional runtime smoke:

```bash
MGSTUDIO_SMOKE_RUNTIME=1 ./scripts/smoke_bevy_examples.sh
```
