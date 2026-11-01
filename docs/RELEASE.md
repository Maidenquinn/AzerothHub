# Release 0.7.1

## Player artifact

- `AzerothHub-0.7.1.zip` (extract folder `AzerothHub/` into `AddOns`)
- SHA-256 in `AzerothHub-0.7.1.zip.sha256`
- Do not use GitHub’s “Source code” archive

## Highlights

- UI + Hub-authored schemas in all **14** Survivors languages
- Detects `azsLanguage`; optional override in Hub → Language
- Profiles, unified settings UI, SurvivorsForge catalog (unchanged from 0.7.0)

## Build

```text
python tools/audit_locales.py
python tests/run.py
python tools/build_release.py
```
