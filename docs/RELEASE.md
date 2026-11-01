# Release 0.7.0

## Artefact joueur

- `AzerothHub-0.7.0.zip` (dossier `AzerothHub/` à extraire dans `AddOns`)
- SHA-256 dans `AzerothHub-0.7.0.zip.sha256`
- Ne pas utiliser l’archive « Source code » de GitHub

## Contenu

- Lanceur / gestionnaire central (`/azhub`, `/hub`, engrenage minimap)
- Profils multiples, chargement dynamique du profil actif
- Réglages intégrés + ouverture native pour le catalogue Survivors
- Inventaire aligné sur les addons référencés (Desktop / [SurvivorsForge](https://forge.rezondes.net/))
- Guide auteurs : `docs/INTEGRATION.md` (`AzerothHubCatalog`)

## Build

```text
python tests/run.py
python tools/build_release.py
```
