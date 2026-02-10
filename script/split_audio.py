import sys
import os
from pydub import AudioSegment
from pydub.silence import split_on_silence

def split(file_name, output_prefix):
    # 1. Load the audio file
    if not os.path.exists(file_name):
        print(f"❌ Error: File '{file_name}' not found.")
        return

    print(f"Loading {file_name}...")
    audio = AudioSegment.from_mp3(file_name)

    # 2. Split based on silent segments
    # min_silence_len: minimum duration of silence to be used for a split (ms)
    # silence_thresh: any sound quieter than this (in dBFS) is considered silence
    # keep_silence: amount of silence to leave at the beginning/end of each chunk (ms)
    chunks = split_on_silence(
        audio,
        min_silence_len=800,
        silence_thresh=-40,
        keep_silence=300
    )

    # 3. Create output directory if it doesn't exist
    output_dir = "savage_split_output"
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # 4. Export each chunk with the given prefix
    for i, chunk in enumerate(chunks):
        output_path = os.path.join(output_dir, f"{output_prefix}_{i+1}.mp3")
        print(f"Exporting {output_path}...")
        chunk.export(output_path, format="mp3")

    print(f"✅ Process complete. Total {len(chunks)} files created in '{output_dir}'.")

if __name__ == '__main__':
    # Check if correct number of arguments are provided
    if len(sys.argv) < 3:
        print("Usage: python split_audio.py <filename> <output_prefix>")
        print("Example: python split_audio.py savage_timer_full/tt.mp3 mild_rest")
    else:
        # Get parameters from command line arguments
        input_file = sys.argv[1]
        prefix = sys.argv[2]
        split(input_file, prefix)