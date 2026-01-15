# Desktop Validation

## Purpose
Validate exported metadata by applying it to lab scans using exiftool, then verifying in Lightroom Classic.

## Prerequisites
- exiftool installed (e.g. `sudo apt install libimage-exiftool-perl`)
- Exported CSV from the iOS app
- Lab scans renamed in sequence (example: `frame_01.jpg`, `frame_02.jpg`)

## Apply Metadata
Run the script from the repo root:

```bash
python3 desktop/apply_metadata.py \
  --csv /path/to/roll-<roll_id>.csv \
  --images /path/to/scans \
  --ext jpg \
  --pattern "frame_{frame_number:02d}"
```

Notes:
- By default the script writes XMP sidecars next to the images.
- Use `--inplace` to write directly into files instead.
- The script expects a file per frame based on the pattern and extension.

## Verify with exiftool
Inspect a sidecar:

```bash
exiftool -G1 -a -s /path/to/scans/frame_01.xmp
```

Expected tags:
- IPTC: `Caption-Abstract`, `Keywords`, `Location`
- XMP: `FilmShutterSpeed`, `FilmAperture`, `FilmISO`, `FilmStock`, `Camera`, `Lens`

## Verify in Lightroom Classic
1. Import the images with their sidecars in the same folder.
2. Open a photo and check Metadata panel:
   - Caption matches `voice_note_parsed` or `voice_note_raw`
   - Keywords are present
   - Location shows `latitude,longitude` string
   - Custom XMP fields appear in the metadata list

## Known Limitations
- No automatic scan matching: filenames must map to `frame_number`.
- GPS is written as IPTC `Location` string, not as geo coordinates.
