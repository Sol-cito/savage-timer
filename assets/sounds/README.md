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
