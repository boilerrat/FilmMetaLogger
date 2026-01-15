from __future__ import annotations

import argparse
import csv
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


@dataclass(frozen=True)
class RollRow:
    roll_id: str
    film_stock: str
    iso: str
    camera: str
    lens: str
    notes: str
    start_time: str
    end_time: str
    frame_number: str
    shutter: str
    aperture: str
    focal_length: str
    exposure_comp: str
    timestamp: str
    latitude: str
    longitude: str
    weather_summary: str
    temperature_c: str
    voice_note_raw: str
    voice_note_parsed: str
    keywords: str

    @property
    def caption(self) -> str:
        return self.voice_note_parsed or self.voice_note_raw

    @property
    def location_string(self) -> str:
        if self.latitude and self.longitude:
            return f"{self.latitude},{self.longitude}"
        return ""

    @property
    def keyword_list(self) -> list[str]:
        return [item.strip() for item in self.keywords.split(",") if item.strip()]


def parse_rows(csv_path: Path) -> Iterable[RollRow]:
    with csv_path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            yield RollRow(
                roll_id=row.get("roll_id", ""),
                film_stock=row.get("film_stock", ""),
                iso=row.get("iso", ""),
                camera=row.get("camera", ""),
                lens=row.get("lens", ""),
                notes=row.get("notes", ""),
                start_time=row.get("start_time", ""),
                end_time=row.get("end_time", ""),
                frame_number=row.get("frame_number", ""),
                shutter=row.get("shutter", ""),
                aperture=row.get("aperture", ""),
                focal_length=row.get("focal_length", ""),
                exposure_comp=row.get("exposure_comp", ""),
                timestamp=row.get("timestamp", ""),
                latitude=row.get("latitude", ""),
                longitude=row.get("longitude", ""),
                weather_summary=row.get("weather_summary", ""),
                temperature_c=row.get("temperature_c", ""),
                voice_note_raw=row.get("voice_note_raw", ""),
                voice_note_parsed=row.get("voice_note_parsed", ""),
                keywords=row.get("keywords", ""),
            )


def build_exiftool_args(row: RollRow, inplace: bool, config_path: Path) -> list[str]:
    args = [
        "exiftool",
        "-config",
        str(config_path),
        "-overwrite_original" if inplace else "-o",
    ]

    if not inplace:
        args.append("%d%f.xmp")

    if row.caption:
        args.append(f"-XMP-dc:Description={row.caption}")

    if row.location_string:
        args.append(f"-XMP-iptcCore:Location={row.location_string}")

    for keyword in row.keyword_list:
        args.append(f"-XMP-dc:Subject+={keyword}")

    if row.shutter:
        args.append(f"-XMP-filmmeta:FilmShutterSpeed={row.shutter}")
    if row.aperture:
        args.append(f"-XMP-filmmeta:FilmAperture={row.aperture}")
    if row.iso:
        args.append(f"-XMP-filmmeta:FilmISO={row.iso}")
    if row.film_stock:
        args.append(f"-XMP-filmmeta:FilmStock={row.film_stock}")
    if row.camera:
        args.append(f"-XMP-filmmeta:Camera={row.camera}")
    if row.lens:
        args.append(f"-XMP-filmmeta:Lens={row.lens}")

    return args


def resolve_image_path(
    images_dir: Path,
    filename_template: str,
    frame_number: int,
    extension: str,
) -> Path:
    filename = filename_template.format(frame_number=frame_number)
    return images_dir / f"{filename}.{extension}"


def apply_metadata(
    csv_path: Path,
    images_dir: Path,
    filename_template: str,
    extension: str,
    inplace: bool,
) -> None:
    config_path = Path(__file__).with_name("exiftool_config")
    missing_files: list[Path] = []
    for row in parse_rows(csv_path):
        if not row.frame_number.isdigit():
            continue
        image_path = resolve_image_path(
            images_dir,
            filename_template,
            int(row.frame_number),
            extension,
        )
        if not image_path.exists():
            missing_files.append(image_path)
            continue

        args = build_exiftool_args(row, inplace, config_path)
        args.append(str(image_path))
        subprocess.run(args, check=True)

    if missing_files:
        missing_list = "\n".join(str(path) for path in missing_files)
        raise SystemExit(f"Missing files:\n{missing_list}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Apply roll metadata via exiftool.")
    parser.add_argument("--csv", required=True, type=Path, help="CSV export path.")
    parser.add_argument("--images", required=True, type=Path, help="Images folder.")
    parser.add_argument("--ext", default="jpg", help="Image extension without dot.")
    parser.add_argument(
        "--pattern",
        default="frame_{frame_number:02d}",
        help="Filename pattern without extension.",
    )
    parser.add_argument(
        "--inplace",
        action="store_true",
        help="Write metadata into files instead of XMP sidecars.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    apply_metadata(
        csv_path=args.csv,
        images_dir=args.images,
        filename_template=args.pattern,
        extension=args.ext,
        inplace=args.inplace,
    )


if __name__ == "__main__":
    main()
