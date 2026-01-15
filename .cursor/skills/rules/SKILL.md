---
name: rules
description: This is a new rule
---

# Cursor Rules
Film Metadata Log App

## General
- Write clear, readable code
- Prefer simplicity over abstraction
- Avoid premature optimization

## Language and Framework
- iOS code uses Swift and SwiftUI
- If React Native is used, prefer Expo
- Use TypeScript where applicable

## Data
- SQLite is source of truth
- No network dependency in MVP
- Schema changes require migration notes

## Voice
- Always store raw transcript
- Parsed values never overwrite raw data

## Files
- No hardcoded paths
- All exports user selectable

## Metadata
- Match Lightroom field names exactly
- Custom fields go into XMP only

## Testing
- Test with real Lightroom imports
- Validate against at least one full roll

## Commits
- Small commits
- Clear messages
- One feature per commit

## Documentation
- Every data field documented
- Export format documented

