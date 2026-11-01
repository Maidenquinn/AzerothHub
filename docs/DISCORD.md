# Message Discord — Azeroth Hub 0.7.0

**Azeroth Hub 0.7.0** est sorti.

C’est le centre de réglages / lanceur pour Azeroth Survivors : un seul endroit pour ouvrir tes addons et ajuster ce qu’ils exposent, sans fouiller dix panneaux différents.

**Ce que ça change**
- Plusieurs **profils** (solo, coop, test…) : tu en crées autant que tu veux, tu copies un profil existant, tu bascules quand tu veux.
- Une **interface unique** pour les réglages intégrés (cases, curseurs, listes) + accès aux options d’origine de chaque addon.
- Chargement **dynamique** : changer de profil réapplique les réglages enregistrés ; après `/reload`, un addon fraîchement installé apparaît dans la liste.
- Toute la liste d’addons référencée sur [SurvivorsForge](https://forge.rezondes.net/) est prise en charge dans le Hub (visibilité + lancement). Selon l’addon : réglages dans le Hub, ou ouverture de sa fenêtre native.

**Téléchargement**  
https://github.com/Maidenquinn/AzerothHub/releases/tag/v0.7.0  
Prends le ZIP `AzerothHub-0.7.0.zip` (pas « Source code »), extrais le dossier `AzerothHub` dans `AddOns`, relance le jeu. `/azhub` ou clic sur l’engrenage.

**Auteurs d’addons — pour être pris en charge automatiquement**  
Sans rien patcher dans le Hub, publiez `AzerothHubCatalog` depuis votre addon :

1. Clé = nom exact du dossier addon (celui du `.toc`).
2. `available` / `open` (et `configure` si besoin).
3. `options` avec des descripteurs stables : `id`, `kind` (`check` / `slider` / `choice`), `get` / `set` sûrs.
4. `profile = false` pour ce qui ne doit pas aller dans les profils ; `reload = true` si un `/reload` est nécessaire (le Hub ne le force pas).

Détail + exemple : https://github.com/Maidenquinn/AzerothHub/blob/main/docs/INTEGRATION.md
