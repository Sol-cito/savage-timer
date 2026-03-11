#!/usr/bin/env python3
"""Generate localized voice assets from JSON script files.

Expected input files under scripts/voice_scripts:
  - <lang>.json (preferred)
  - <lang>.txt  (allowed if the content is JSON)

JSON schema example:
{
  "mild": {
    "start": {
      "mild_start_1": "text..."
    },
    "count": {
      "count_1": "one"
    }
  }
}

Output for language "ko":
  assets/sounds/ko/<mode>/<folder>/<key>.mp3
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import random
import sys
import time
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from typing import Dict, Iterable, List
from urllib import error, parse, request

SUPPORTED_LANGUAGES = ("en", "es", "ko")
SUPPORTED_MODES = ("mild", "medium", "savage", "neutral")
SUPPORTED_FOLDERS = {"count", "examples", "exercise", "rest", "start"}
FOLDER_ALIASES = {"example": "examples"}

DEFAULT_SCRIPTS_DIR = Path("scripts/voice_scripts")
DEFAULT_OUTPUT_ROOT = Path("assets/sounds")
DEFAULT_CACHE_FILE = Path("scripts/.elevenlabs_voice_cache.json")
DEFAULT_API_KEY_ENV = "ELEVENLABS_API_KEY"
DEFAULT_DEFAULT_MODEL_ID = "eleven_multilingual_v2"
DEFAULT_OUTPUT_FORMAT = "mp3_44100_128"
DEFAULT_TIMEOUT_SECONDS = 120
RETRYABLE_STATUS_CODES = {429, 500, 502, 503, 504}


@dataclass(frozen=True)
class VoiceLine:
    language: str
    mode: str
    output_path: str
    text: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate localized voice assets with the ElevenLabs API.",
    )
    parser.add_argument(
        "--scripts-dir",
        default=str(DEFAULT_SCRIPTS_DIR),
        help="Directory containing <lang>.json/<lang>.txt files.",
    )
    parser.add_argument(
        "--output-root",
        default=str(DEFAULT_OUTPUT_ROOT),
        help="Root output directory (assets/sounds).",
    )
    parser.add_argument(
        "--cache-file",
        default=str(DEFAULT_CACHE_FILE),
        help="Path to generation cache JSON.",
    )
    parser.add_argument(
        "--language",
        action="append",
        choices=SUPPORTED_LANGUAGES,
        help="Language to generate. Repeat for multiple.",
    )
    parser.add_argument(
        "--env-file",
        default=".env",
        help="Optional .env file to read when env vars are not exported.",
    )
    parser.add_argument(
        "--api-key-env",
        default=DEFAULT_API_KEY_ENV,
        help="Environment variable name for ElevenLabs API key.",
    )
    parser.add_argument(
        "--default-model-id",
        default=DEFAULT_DEFAULT_MODEL_ID,
        help="Fallback payload model_id if ELEVENLABS_MODEL_ID_<LANG> is missing.",
    )
    parser.add_argument(
        "--stability",
        type=float,
        default=0.5,
        help="Fallback stability if mode-specific env values are missing.",
    )
    parser.add_argument(
        "--similarity-boost",
        type=float,
        default=0.75,
        help="Fallback similarity_boost if mode-specific env values are missing.",
    )
    parser.add_argument(
        "--style",
        type=float,
        default=0.0,
        help="Fallback style if mode-specific env values are missing.",
    )
    parser.add_argument(
        "--speed",
        type=float,
        default=1.0,
        help="Fallback speed if mode-specific env values are missing.",
    )
    parser.add_argument(
        "--disable-speaker-boost",
        action="store_true",
        help="Disable speaker boost unless overridden by env.",
    )
    parser.add_argument(
        "--max-retries",
        type=int,
        default=5,
        help="Maximum retries for 429/5xx failures.",
    )
    parser.add_argument(
        "--timeout-seconds",
        type=int,
        default=DEFAULT_TIMEOUT_SECONDS,
        help="HTTP timeout in seconds per request.",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Ignore cache and regenerate all lines.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print planned writes without calling API or writing files.",
    )
    return parser.parse_args()


def load_dotenv(env_file: Path) -> Dict[str, str]:
    if not env_file.exists():
        return {}

    values: Dict[str, str] = {}
    for raw_line in env_file.read_text(encoding="utf-8").splitlines():
        stripped = raw_line.strip()
        if not stripped or stripped.startswith("#") or "=" not in stripped:
            continue
        key, value = stripped.split("=", 1)
        key = key.strip()
        value = value.strip().strip("'").strip('"')
        if key:
            values[key] = value
    return values


def env_or_dotenv(key: str, dotenv_values: Dict[str, str]) -> str:
    return os.getenv(key, "").strip() or dotenv_values.get(key, "").strip()


def parse_float(value: str, key_name: str) -> float:
    try:
        return float(value)
    except ValueError as exc:
        raise ValueError(f"{key_name} must be a float, got '{value}'.") from exc


def parse_bool(value: str, key_name: str) -> bool:
    normalized = value.strip().lower()
    if normalized in ("1", "true", "yes", "y", "on"):
        return True
    if normalized in ("0", "false", "no", "n", "off"):
        return False
    raise ValueError(f"{key_name} must be boolean, got '{value}'.")


def discover_script_file(scripts_dir: Path, language: str) -> Path | None:
    json_path = scripts_dir / f"{language}.json"
    if json_path.exists():
        return json_path
    txt_path = scripts_dir / f"{language}.txt"
    if txt_path.exists():
        return txt_path
    return None


def select_languages(raw_languages: Iterable[str] | None, scripts_dir: Path) -> List[str]:
    if raw_languages is not None:
        return list(dict.fromkeys(raw_languages))

    detected = [lang for lang in SUPPORTED_LANGUAGES if discover_script_file(scripts_dir, lang)]
    if not detected:
        raise FileNotFoundError(
            f"No script files found in {scripts_dir}. "
            "Expected <lang>.json or <lang>.txt.",
        )
    return detected


def normalize_mode(mode: str, file_path: Path, context: str) -> str:
    normalized = mode.strip().lower()
    if normalized not in SUPPORTED_MODES:
        raise ValueError(
            f"{file_path} {context}: mode '{mode}' is invalid. "
            f"Expected one of {', '.join(SUPPORTED_MODES)}.",
        )
    return normalized


def normalize_folder(folder: str, file_path: Path, context: str) -> str:
    normalized = folder.strip().lower()
    normalized = FOLDER_ALIASES.get(normalized, normalized)
    if normalized not in SUPPORTED_FOLDERS:
        raise ValueError(
            f"{file_path} {context}: folder '{folder}' is invalid. "
            f"Expected one of {', '.join(sorted(SUPPORTED_FOLDERS))}.",
        )
    return normalized


def normalize_filename(file_key: str, file_path: Path, context: str) -> str:
    filename = file_key.strip()
    if not filename:
        raise ValueError(f"{file_path} {context}: empty file key.")
    if "/" in filename or "\\" in filename:
        raise ValueError(
            f"{file_path} {context}: file key '{file_key}' must not contain path separators.",
        )
    return filename if filename.endswith(".mp3") else f"{filename}.mp3"


def load_json_script(language: str, scripts_dir: Path) -> List[VoiceLine]:
    script_file = discover_script_file(scripts_dir, language)
    if script_file is None:
        raise FileNotFoundError(
            f"No script file for '{language}' in {scripts_dir} "
            f"(expected {language}.json or {language}.txt).",
        )

    try:
        payload = json.loads(script_file.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"{script_file} is not valid JSON.") from exc

    if not isinstance(payload, dict):
        raise ValueError(f"{script_file}: root must be a JSON object.")

    lines: List[VoiceLine] = []
    seen_paths = set()

    def add_line(mode_value: str, folder_value: str, key: str, text_value: object, context: str) -> None:
        mode = normalize_mode(mode_value, script_file, context)
        folder = normalize_folder(folder_value, script_file, context)
        filename = normalize_filename(key, script_file, context)
        if not isinstance(text_value, str) or not text_value.strip():
            raise ValueError(f"{script_file} {context}: value for '{key}' must be non-empty text.")

        output_path = f"{mode}/{folder}/{filename}"
        if output_path in seen_paths:
            raise ValueError(f"{script_file}: duplicate output path '{output_path}'.")
        seen_paths.add(output_path)
        lines.append(
            VoiceLine(
                language=language,
                mode=mode,
                output_path=output_path,
                text=text_value.strip(),
            ),
        )

    for top_key, top_value in payload.items():
        if not isinstance(top_value, dict):
            raise ValueError(f"{script_file}: '{top_key}' must map to an object.")

        # Format A: "mode": {"folder": {"file_key": "text"}}
        if "/" not in top_key:
            for folder_key, file_map in top_value.items():
                if not isinstance(file_map, dict):
                    raise ValueError(
                        f"{script_file}: '{top_key}.{folder_key}' must map to an object.",
                    )
                for file_key, text_value in file_map.items():
                    add_line(
                        mode_value=top_key,
                        folder_value=folder_key,
                        key=str(file_key),
                        text_value=text_value,
                        context=f"({top_key}.{folder_key})",
                    )
            continue

        # Format B: "mode/folder": {"file_key": "text"}
        parts = PurePosixPath(top_key).parts
        if len(parts) != 2:
            raise ValueError(
                f"{script_file}: key '{top_key}' must be 'mode/folder' when using slash format.",
            )
        mode_key, folder_key = parts
        for file_key, text_value in top_value.items():
            add_line(
                mode_value=mode_key,
                folder_value=folder_key,
                key=str(file_key),
                text_value=text_value,
                context=f"({top_key})",
            )

    return lines


def load_cache(cache_file: Path) -> Dict[str, str]:
    if not cache_file.exists():
        return {}
    try:
        parsed = json.loads(cache_file.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"Cache JSON is invalid: {cache_file}") from exc
    if not isinstance(parsed, dict):
        raise ValueError(f"Cache JSON must contain an object: {cache_file}")
    return {str(k): str(v) for k, v in parsed.items()}


def write_cache(cache_file: Path, cache: Dict[str, str]) -> None:
    cache_file.parent.mkdir(parents=True, exist_ok=True)
    cache_file.write_text(
        json.dumps(dict(sorted(cache.items())), ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def resolve_voice_id(language: str, mode: str, dotenv_values: Dict[str, str]) -> str:
    key = f"ELEVENLABS_VOICE_ID_{language.upper()}_{mode.upper()}"
    return env_or_dotenv(key, dotenv_values)


def resolve_payload_model_id(language: str, dotenv_values: Dict[str, str], fallback: str) -> str:
    key = f"ELEVENLABS_MODEL_ID_{language.upper()}"
    return env_or_dotenv(key, dotenv_values) or fallback


def resolve_float_setting(
    setting_prefix: str,
    language: str,
    mode: str,
    dotenv_values: Dict[str, str],
    fallback: float,
) -> float:
    lookup_keys = (
        f"{setting_prefix}_{language.upper()}_{mode.upper()}",
        f"{setting_prefix}_{mode.upper()}",
        setting_prefix,
    )
    for key in lookup_keys:
        value = env_or_dotenv(key, dotenv_values)
        if value:
            return parse_float(value, key)
    return fallback


def resolve_bool_setting(
    setting_prefix: str,
    language: str,
    mode: str,
    dotenv_values: Dict[str, str],
    fallback: bool,
) -> bool:
    lookup_keys = (
        f"{setting_prefix}_{language.upper()}_{mode.upper()}",
        f"{setting_prefix}_{mode.upper()}",
        setting_prefix,
    )
    for key in lookup_keys:
        value = env_or_dotenv(key, dotenv_values)
        if value:
            return parse_bool(value, key)
    return fallback


def hash_line(
    line: VoiceLine,
    voice_id: str,
    payload_model_id: str,
    output_format: str,
    stability: float,
    similarity_boost: float,
    style: float,
    speed: float,
    speaker_boost: bool,
) -> str:
    payload = {
        "language": line.language,
        "mode": line.mode,
        "output_path": line.output_path,
        "text": line.text,
        "voice_id": voice_id,
        "payload_model_id": payload_model_id,
        "output_format": output_format,
        "stability": stability,
        "similarity_boost": similarity_boost,
        "style": style,
        "speed": speed,
        "speaker_boost": speaker_boost,
    }
    encoded = json.dumps(payload, ensure_ascii=False, sort_keys=True).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def call_elevenlabs_tts(
    *,
    api_key: str,
    voice_id: str,
    payload_model_id: str,
    output_format: str,
    text: str,
    stability: float,
    similarity_boost: float,
    style: float,
    speed: float,
    speaker_boost: bool,
    timeout_seconds: int,
    max_retries: int,
) -> bytes:
    encoded_format = parse.quote(output_format, safe="")
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}?output_format={encoded_format}"
    payload = {
        "text": text,
        "model_id": payload_model_id,
        "voice_settings": {
            "stability": stability,
            "similarity_boost": similarity_boost,
            "style": style,
            "speed": speed,
            "use_speaker_boost": speaker_boost,
        },
    }
    data = json.dumps(payload, ensure_ascii=False).encode("utf-8")

    for attempt in range(1, max_retries + 1):
        req = request.Request(
            url=url,
            method="POST",
            data=data,
            headers={
                "xi-api-key": api_key,
                "Content-Type": "application/json",
                "Accept": "audio/mpeg",
            },
        )
        try:
            with request.urlopen(req, timeout=timeout_seconds) as response:
                return response.read()
        except error.HTTPError as exc:
            body = exc.read().decode("utf-8", errors="replace")
            if exc.code in RETRYABLE_STATUS_CODES and attempt < max_retries:
                delay = retry_delay_seconds(exc.headers.get("Retry-After"), attempt)
                print(
                    f"  HTTP {exc.code}; retry {attempt}/{max_retries} in {delay:.1f}s",
                    file=sys.stderr,
                )
                time.sleep(delay)
                continue
            raise RuntimeError(
                f"ElevenLabs request failed with HTTP {exc.code}: {body[:500]}",
            ) from exc
        except error.URLError as exc:
            if attempt < max_retries:
                delay = retry_delay_seconds(None, attempt)
                print(
                    f"  Network error; retry {attempt}/{max_retries} in {delay:.1f}s ({exc})",
                    file=sys.stderr,
                )
                time.sleep(delay)
                continue
            raise RuntimeError(f"Network error calling ElevenLabs API: {exc}") from exc

    raise RuntimeError("Retries exhausted while calling ElevenLabs API.")


def retry_delay_seconds(retry_after_header: str | None, attempt: int) -> float:
    if retry_after_header:
        try:
            retry_after = float(retry_after_header)
            if retry_after > 0:
                return retry_after
        except ValueError:
            pass
    exponential = min(30.0, 1.5 * (2 ** (attempt - 1)))
    jitter = random.uniform(0.0, 0.75)
    return exponential + jitter


def main() -> int:
    args = parse_args()

    scripts_dir = Path(args.scripts_dir)
    output_root = Path(args.output_root)
    cache_file = Path(args.cache_file)
    env_file = Path(args.env_file)

    dotenv_values = load_dotenv(env_file)
    languages = select_languages(args.language, scripts_dir)

    api_key = env_or_dotenv(args.api_key_env, dotenv_values)
    if not api_key and not args.dry_run:
        print(
            f"Missing API key. Set {args.api_key_env} in environment or {env_file}.",
            file=sys.stderr,
        )
        return 1

    lines_by_language: Dict[str, List[VoiceLine]] = {}
    for language in languages:
        lines = load_json_script(language, scripts_dir)
        if not lines:
            print(f"Warning: no voice lines found for language '{language}'.", file=sys.stderr)
            continue
        lines_by_language[language] = lines

    cache = load_cache(cache_file)
    generated_count = 0
    skipped_count = 0
    error_count = 0

    fallback_speaker_boost = not args.disable_speaker_boost

    for language in languages:
        lines = lines_by_language.get(language, [])
        if not lines:
            continue

        print(f"\nLanguage: {language} ({len(lines)} lines)")

        payload_model_id = resolve_payload_model_id(
            language=language,
            dotenv_values=dotenv_values,
            fallback=args.default_model_id,
        )

        for index, line in enumerate(lines, start=1):
            voice_id = resolve_voice_id(language, line.mode, dotenv_values)
            stability = resolve_float_setting(
                setting_prefix="ELEVENLABS_STABILITY",
                language=language,
                mode=line.mode,
                dotenv_values=dotenv_values,
                fallback=args.stability,
            )
            similarity_boost = resolve_float_setting(
                setting_prefix="ELEVENLABS_SIMILARITY_BOOST",
                language=language,
                mode=line.mode,
                dotenv_values=dotenv_values,
                fallback=args.similarity_boost,
            )
            style = resolve_float_setting(
                setting_prefix="ELEVENLABS_STYLE",
                language=language,
                mode=line.mode,
                dotenv_values=dotenv_values,
                fallback=args.style,
            )
            speed = resolve_float_setting(
                setting_prefix="ELEVENLABS_SPEED",
                language=language,
                mode=line.mode,
                dotenv_values=dotenv_values,
                fallback=args.speed,
            )
            speaker_boost = resolve_bool_setting(
                setting_prefix="ELEVENLABS_USE_SPEAKER_BOOST",
                language=language,
                mode=line.mode,
                dotenv_values=dotenv_values,
                fallback=fallback_speaker_boost,
            )

            output_path = output_root / language / line.output_path
            if not voice_id:
                if args.dry_run:
                    generated_count += 1
                    print(
                        f"  [{index}/{len(lines)}] dry-run {output_path} "
                        f"(missing ELEVENLABS_VOICE_ID_{language.upper()}_{line.mode.upper()})",
                    )
                    continue
                error_count += 1
                print(
                    f"  ERROR {output_path}: missing ELEVENLABS_VOICE_ID_{language.upper()}_{line.mode.upper()}",
                    file=sys.stderr,
                )
                continue

            # Skip immediately if the file already exists locally.
            # This avoids unnecessary API usage even when cache is missing.
            if (not args.force) and output_path.exists():
                skipped_count += 1
                print(f"  [{index}/{len(lines)}] skip-existing {output_path}")
                continue

            line_hash = hash_line(
                line=line,
                voice_id=voice_id,
                payload_model_id=payload_model_id,
                output_format=DEFAULT_OUTPUT_FORMAT,
                stability=stability,
                similarity_boost=similarity_boost,
                style=style,
                speed=speed,
                speaker_boost=speaker_boost,
            )
            cache_key = f"{language}:{line.output_path}"

            if (not args.force) and cache.get(cache_key) == line_hash and output_path.exists():
                skipped_count += 1
                print(f"  [{index}/{len(lines)}] skip {output_path}")
                continue

            if args.dry_run:
                generated_count += 1
                print(f"  [{index}/{len(lines)}] dry-run {output_path}")
                continue

            print(f"  [{index}/{len(lines)}] generate {output_path}")
            try:
                audio_bytes = call_elevenlabs_tts(
                    api_key=api_key,
                    voice_id=voice_id,
                    payload_model_id=payload_model_id,
                    output_format=DEFAULT_OUTPUT_FORMAT,
                    text=line.text,
                    stability=stability,
                    similarity_boost=similarity_boost,
                    style=style,
                    speed=speed,
                    speaker_boost=speaker_boost,
                    timeout_seconds=args.timeout_seconds,
                    max_retries=args.max_retries,
                )
                output_path.parent.mkdir(parents=True, exist_ok=True)
                output_path.write_bytes(audio_bytes)
                cache[cache_key] = line_hash
                generated_count += 1
            except Exception as exc:  # pylint: disable=broad-except
                error_count += 1
                print(f"  ERROR {output_path}: {exc}", file=sys.stderr)

    if not args.dry_run:
        write_cache(cache_file, cache)

    print("\nSummary")
    print(f"  Generated: {generated_count}")
    print(f"  Skipped:   {skipped_count}")
    print(f"  Errors:    {error_count}")
    return 1 if error_count > 0 else 0


if __name__ == "__main__":
    raise SystemExit(main())
