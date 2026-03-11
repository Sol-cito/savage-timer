Voice Script Files for ElevenLabs Automation
============================================

Input files are JSON by language:

- `ko.json` (or `ko.txt` with JSON content)
- `en.json` / `en.txt`
- `es.json` / `es.txt`

Schema:

```json
{
  "mild": {
    "start": {
      "mild_start_1": "Your text"
    },
    "count": {
      "count_1": "one"
    }
  }
}
```

Rules:

- Top-level key: mode (`mild`, `medium`, `savage`, `neutral`)
- 2nd-level key: folder (`start`, `rest`, `exercise`, `examples`/`example`, `count`)
- leaf key: file name (with or without `.mp3`)
- leaf value: text for ElevenLabs payload

Generated path for each leaf:

- `assets/sounds/<lang>/<mode>/<folder>/<file>.mp3`

Environment keys used from `.env`:

- `ELEVENLABS_API_KEY`
- `ELEVENLABS_MODEL_ID_<LANG>` (payload `model_id`)
- `ELEVENLABS_VOICE_ID_<LANG>_<MODE>` (URL path voice id)
- Optional settings (by mode):
  - `ELEVENLABS_STABILITY_<MODE>`
  - `ELEVENLABS_SIMILARITY_BOOST_<MODE>`
  - `ELEVENLABS_STYLE_<MODE>`
  - `ELEVENLABS_SPEED_<MODE>`
  - `ELEVENLABS_USE_SPEAKER_BOOST` or `_ <MODE>`

Run examples:

```bash
# Dry run using only ko.json
python3 scripts/generate_voice_assets.py --language ko --dry-run

# Real generation
python3 scripts/generate_voice_assets.py --language ko

# Overwrite already-existing files
python3 scripts/generate_voice_assets.py --language ko --force
```

By default, existing output files are skipped before any API call.
