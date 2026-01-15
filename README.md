# Film Metadata Log App

Local-first iOS app for logging film rolls/frames and exporting metadata for lab scans.

## Status
- iOS SwiftUI MVP with local SQLite storage
- Per-roll JSON/CSV export
- Desktop exiftool workflow for sidecar injection

## iOS Workflow
1. Create a roll.
2. Add frames with timestamp, GPS, and voice note.
3. Export JSON/CSV from the frames screen.

Notes:
- SQLite database stored in the app Documents directory.
- Audio is recorded to Documents; transcript stored on the frame.

## Desktop Validation
See `desktop/README.md` for the exiftool script and Lightroom checks.

## Structure
- `ios/FilmMetaLogger`: SwiftUI MVP source
- `desktop`: Metadata injection scripts + docs
