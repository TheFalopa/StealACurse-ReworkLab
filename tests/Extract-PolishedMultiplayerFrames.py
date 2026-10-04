"""Extract time-labelled review sheets from the existing native multiplayer videos.

No visual approvals are inferred. Container duration is read with ffmpeg -i;
frame labels use the decoded source PTS, not the requested seek alone.
"""

from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
FFMPEG = ROOT / "tests/ffmpeg-review.exe"
MANIFEST = ROOT / "assets/review/animations-polished/multiplayer-video-manifest.json"
OUT = ROOT / "assets/review/animations-polished/videos/mp-review"


def font(size: int) -> ImageFont.ImageFont:
    try:
        return ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", size)
    except OSError:
        return ImageFont.load_default(size=size)


def duration(video: Path) -> float:
    # ffmpeg intentionally exits nonzero when probing without an output file.
    result = subprocess.run(
        [str(FFMPEG), "-hide_banner", "-i", str(video)],
        capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=30,
    )
    match = re.search(r"Duration:\s*(\d+):(\d+):(\d+(?:\.\d+)?)", result.stderr)
    if not match:
        raise RuntimeError(f"No measurable container duration for {video.name}: {result.stderr[-1000:]}")
    return int(match[1]) * 3600 + int(match[2]) * 60 + float(match[3])


def extract(video: Path, requested: float, output: Path) -> float:
    result = subprocess.run(
        [str(FFMPEG), "-hide_banner", "-loglevel", "info", "-nostdin", "-y",
         "-copyts", "-ss", f"{requested:.6f}", "-i", str(video), "-map", "0:v:0",
         "-vf", "showinfo", "-frames:v", "1", "-update", "1", str(output)],
        capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=45,
    )
    if result.returncode or not output.is_file():
        raise RuntimeError(f"Frame extraction failed for {video.name} at {requested}s: {result.stderr[-1500:]}")
    match = re.search(r"n:\s*0\s+pts:\s*-?\d+\s+pts_time:([\d.eE+-]+)", result.stderr)
    if not match:
        raise RuntimeError(f"No decoded source timestamp for {output.name}")
    return float(match[1])


def main() -> None:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8-sig"))
    OUT.mkdir(parents=True, exist_ok=True)
    records = []
    label_font, title_font = font(20), font(25)
    for entry in manifest["videos"]:
        video = Path(entry["path"])
        length = duration(video)
        if length <= 18:
            raise RuntimeError(f"{video.name} is only {length}s; requested 18s frame is unavailable")
        times = [1, 3, 6, 8, 12, 16, 18, min(23, length - 0.3)]
        stem = video.stem
        frame_dir = OUT / stem
        frame_dir.mkdir(exist_ok=True)
        cell, footer, header = 576, 34, 48
        sheet = Image.new("RGB", (cell * 4, header + (cell + footer) * 2), (14, 19, 28))
        draw = ImageDraw.Draw(sheet)
        draw.text((12, 8), f'{entry["id"]} / {entry["role"]} | duration {length:.2f}s',
                  fill="white", font=title_font)
        frames = []
        for index, requested in enumerate(times):
            output = frame_dir / f"{index + 1:02}.png"
            actual = extract(video, requested, output)
            with Image.open(output) as source:
                image = source.convert("RGB")
                image.thumbnail((cell, cell), Image.Resampling.LANCZOS)
                left = (index % 4) * cell
                top = header + (index // 4) * (cell + footer)
                sheet.paste(image, (left + (cell - image.width) // 2, top + (cell - image.height) // 2))
            draw.text((left + 8, top + cell + 4), f"t={actual:.3f}s (seek {requested:.3f}s)",
                      fill=(190, 224, 255), font=label_font)
            frames.append({"requestedSeconds": requested, "sourceFrameSeconds": actual,
                           "path": output.as_posix()})
        contact = OUT / f"{stem}-contact.png"
        sheet.save(contact)
        entry["durationSeconds"] = length
        records.append({"id": entry["id"], "role": entry["role"], "video": video.as_posix(),
                        "durationSeconds": length, "contact": contact.as_posix(), "frames": frames})
        print(f"{stem}: {length:.2f}s, 8 frames -> {contact}", flush=True)
    # Preserve every existing mapping, note, source, and recording field.
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (OUT / "frames-index.json").write_text(json.dumps({
        "durationMethod": "ffmpeg-review.exe -i container Duration",
        "frameMethod": "copyts + showinfo first decoded frame; labels are source PTS",
        "visualReviewPerformed": False,
        "videos": records,
    }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
