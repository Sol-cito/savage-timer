import sys
import os
from pydub import AudioSegment
from pydub.silence import split_on_silence

# Reference volume target (savage_example_1.mp3 dBFS)
TARGET_DBFS = -13.58


def normalize_volume(audio, target_dbfs=TARGET_DBFS):
    """Adjust audio volume to match target dBFS."""
    change_in_dbfs = target_dbfs - audio.dBFS
    return audio.apply_gain(change_in_dbfs)


def split(file_name, output_prefix, output_dir=None):
    """Split a single audio file on silence, normalize, and export chunks."""
    if not os.path.exists(file_name):
        print(f"  Error: File '{file_name}' not found.")
        return 0

    print(f"  Loading {file_name}...")
    audio = AudioSegment.from_mp3(file_name)

    chunks = split_on_silence(
        audio,
        min_silence_len=800,
        silence_thresh=-40,
        keep_silence=300,
    )

    if output_dir is None:
        output_dir = os.path.dirname(file_name)

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    for i, chunk in enumerate(chunks):
        normalized = normalize_volume(chunk)
        output_path = os.path.join(output_dir, f"{output_prefix}_{i + 1}.mp3")
        print(f"  Exporting {output_path} ({len(chunk)}ms, {normalized.dBFS:.1f} dBFS)")
        normalized.export(output_path, format="mp3")

    print(f"  -> {len(chunks)} files created.\n")
    return len(chunks)


def batch_split():
    """Process all _full.mp3 files in the assets/sounds directory."""
    base = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "assets",
        "sounds",
    )

    levels = ["mild", "medium", "savage"]
    subfolders = ["exercise", "rest", "start"]

    total_files = 0

    for level in levels:
        for subfolder in subfolders:
            full_file = os.path.join(base, level, subfolder, f"{level}_{subfolder}_full.mp3")
            if not os.path.exists(full_file):
                print(f"Skipping {level}/{subfolder} (no _full.mp3 found)")
                continue

            print(f"Processing {level}/{subfolder}:")
            output_dir = os.path.join(base, level, subfolder)
            prefix = f"{level}_{subfolder}"

            count = split(full_file, prefix, output_dir)
            total_files += count

            # Remove the _full.mp3 file after successful split
            if count > 0:
                os.remove(full_file)
                print(f"  Removed {full_file}\n")

    # Also normalize existing example files
    for level in levels:
        examples_dir = os.path.join(base, level, "examples")
        if not os.path.exists(examples_dir):
            continue
        for fname in os.listdir(examples_dir):
            if fname.endswith(".mp3"):
                fpath = os.path.join(examples_dir, fname)
                audio = AudioSegment.from_mp3(fpath)
                if abs(audio.dBFS - TARGET_DBFS) > 1.0:
                    normalized = normalize_volume(audio)
                    normalized.export(fpath, format="mp3")
                    print(f"Normalized {fpath} ({audio.dBFS:.1f} -> {normalized.dBFS:.1f} dBFS)")

    print(f"\nDone! Total {total_files} voice clips created.")


if __name__ == "__main__":
    if len(sys.argv) >= 3:
        # Single file mode: python split_audio.py <filename> <output_prefix>
        input_file = sys.argv[1]
        prefix = sys.argv[2]
        split(input_file, prefix)
    else:
        # Batch mode: process all _full.mp3 files
        print("Batch splitting all _full.mp3 files...\n")
        batch_split()
