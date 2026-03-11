Voice localization layout
=========================

Localized voice assets live under language-code folders:

- `assets/sounds/en/`
- `assets/sounds/es/`
- `assets/sounds/ko/`

Inside each language folder, keep the same filenames and structure:

- `<level>/count/`
- `<level>/examples/`
- `<level>/exercise/`
- `<level>/rest/`
- `<level>/start/`

Where `<level>` is one of:

- `mild`
- `medium`
- `savage`
- `neutral` (count files only)

Example path:

- `assets/sounds/es/mild/start/mild_start_1.mp3`

Non-localized cues remain shared:

- `assets/sounds/bell_1time.mp3`
- `assets/sounds/bell_3times.mp3`
- `assets/sounds/clapping.mp3`
- `assets/sounds/silence.wav`

Runtime behavior:

- App uses the current selected locale (`en`, `es`, `ko`) for voice/count files.
- If a localized file set is missing, it falls back to `en`.

Automated ElevenLabs generation
-------------------------------

Use script-driven generation to create localized voice packs:

1. Fill script files in `scripts/voice_scripts/`:
   - `en.json` / `en.txt` (JSON content)
   - `es.json` / `es.txt` (JSON content)
   - `ko.json` / `ko.txt` (JSON content)
2. Set environment variables:
   - `ELEVENLABS_API_KEY`
   - `ELEVENLABS_MODEL_ID_<LANG>` (payload `model_id`)
   - `ELEVENLABS_VOICE_ID_EN_MILD`
   - `ELEVENLABS_VOICE_ID_EN_MEDIUM`
   - `ELEVENLABS_VOICE_ID_EN_SAVAGE`
   - `ELEVENLABS_VOICE_ID_EN_NEUTRAL`
   - `ELEVENLABS_VOICE_ID_ES_MILD`
   - `ELEVENLABS_VOICE_ID_ES_MEDIUM`
   - `ELEVENLABS_VOICE_ID_ES_SAVAGE`
   - `ELEVENLABS_VOICE_ID_ES_NEUTRAL`
   - `ELEVENLABS_VOICE_ID_KO_MILD`
   - `ELEVENLABS_VOICE_ID_KO_MEDIUM`
   - `ELEVENLABS_VOICE_ID_KO_SAVAGE`
   - `ELEVENLABS_VOICE_ID_KO_NEUTRAL`
   - Optional per-mode voice settings:
     - `ELEVENLABS_STABILITY_<MODE>`
     - `ELEVENLABS_SIMILARITY_BOOST_<MODE>`
     - `ELEVENLABS_STYLE_<MODE>`
     - `ELEVENLABS_SPEED_<MODE>`
     - `ELEVENLABS_USE_SPEAKER_BOOST` or `ELEVENLABS_USE_SPEAKER_BOOST_<MODE>`
   - (or place the same keys in `.env`)
3. Run:
   - `python3 scripts/generate_voice_assets.py --language ko`

Each JSON entry is:

- `<mode> -> <folder> -> <file_key>: <text>`

Generated file path is:

- `assets/sounds/<lang>/<mode>/<folder>/<file_key>.mp3`
