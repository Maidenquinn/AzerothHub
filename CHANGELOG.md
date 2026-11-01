# Changelog

## 0.7.0 - 2026-11-01

Première release publique du Hub élargi (catalogue SurvivorsForge / Desktop).

- Azeroth Cursor : schéma Hub complet 1.2 (repère, icône de classe, taille, classe du blason, couleur prédéfinie, langue).
- Liste Hub en 3 groupes : Avec réglages / Chargés sans schéma / Catalogue (non chargés).
- Catalogue d’inventaire élargi aux addons Survivors référencés (archives + installation locale), visibles dès le premier lancement même s’ils ne sont pas encore installés.
- Détection au `/reload` quand un joueur installe plus tard un addon de cette liste.
- Intégrations sans modifier les sources des autres addons (FieldKit, Azerloot, Stats, Cursor, Survivor UI/Plates, AetherHUD, BigCursor, LocalClock, Max Hit, VCT, Blackwell, Bordo, Keijin, Dragon UI, etc.).
- Guide auteurs : `docs/INTEGRATION.md` (`AzerothHubCatalog` pour inclusion automatique des réglages).
- `refresh_inventory.py` accepte `--zips-dir` en plus de `--addons-dir`.

## 0.6.6-test

- Moins de travail par image : le scan des boutons de minimap passe a une fois par seconde, et les boutons deja connus ne sont plus reidentifies a chaque passage.

## 0.6.5-test

- Un addon deja charge, meme absent de l'inventaire, est retrouve via son bouton de minimap.
- Survivor UI et Survivor Plates exposent leurs modules principaux dans le Hub. Le reste reste dans Options d'origine.

## 0.6.4-test

- L'inventaire inclut les dossiers ajoutes dans le jeu. Un addon present dans cet inventaire et deja charge est marque comme charge.
- Le lanceur ouvre le bouton de minimap principal quand un addon en a plusieurs.

## 0.6.3-test

- Un addon peut publier ses reglages dans `AzerothHubCatalog`. Le Hub les reprend au chargement, sans modification du Hub.
- Une integration deja ecrite dans le Hub reste prioritaire.

## 0.6.2-test

- La liste des addons separe ceux qui ont des reglages integres de ceux qui n'en ont pas.
- Chaque categorie s'affiche comme un titre, avec le nombre de reglages, et les options sont decalees en dessous.

## 0.6.1-test

Correctif de chargement. La zone de déplacement lisait un champ `points` qui n’existe que dans les tests, ce qui bloquait l’ouverture dans le jeu.

## 0.6.0-test

Interface du gestionnaire réorganisée. Le chemin affiché est désormais : profil actif, addon, onglet, puis section repliable et réglage. Le second bouton « Gérer les profils » à côté du profil a été retiré en mode Grimoire. En mode Compact, le profil est le premier choix et l’addon le second.

Les onglets n’apparaissent que lorsqu’un addon en a plusieurs. Le menu « Toutes les catégories », qui doublait les sections, n’est plus affiché. Les consignes sur la molette et la ligne « Cliquer pour replier » ont quitté l’écran : le repli reste un clic sur le titre de section, avec une info-bulle. Les descriptions longues sont raccourcies dans la ligne et restent complètes au survol.

Les valeurs gardent leur unité et une largeur suffisante. Le bouton Recharger n’apparaît que si un réglage intégré le demande. L’aperçu Cursor reste visible sans activer le repère. Les trois apparences et leurs identifiants de réglages sont inchangés.

Vérification hors jeu : suites Lua 5.0, y compris les descripteurs Azerloot installés et le rendu Cursor installé. Le rendu dans le client reste à confirmer tant que cette version porte le suffixe test.

## 0.5.0-test

Onglets natifs Azerloot et FieldKit, sections repliables, recherche globale avec le chemin du résultat.

## 0.4.0

Aperçu Cursor branché sur son moteur, unités, boutons moins et plus, mode « Voir en jeu ».

## 0.3.1

Sens des curseurs verticaux corrigé et zone de déplacement séparée des boutons Apparence et Fermer.

## 0.3.0

Apparences Grimoire, Atelier et Compact.

## 0.2.0

Profils de réglages, lanceur minimap et premières intégrations.
