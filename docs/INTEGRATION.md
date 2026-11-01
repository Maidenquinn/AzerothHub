# Intégrer un addon dans Azeroth Hub

Azeroth Hub liste les addons Survivors, ouvre leurs options, et peut exposer des
réglages dans ses profils. **Vous n’avez pas besoin de patcher le Hub** pour y
figurer : publiez un petit catalogue depuis votre addon.

Le Hub ne lit jamais vos SavedVariables au hasard. Sans descripteurs, il ne peut
pas inventer des libellés, des bornes ni une écriture sûre.

## Détection automatique

Au chargement (et à chaque `/azhub scan` / ouverture du gestionnaire), le Hub :

1. Lit l’index client (`GetNumAddOns`) quand il est disponible.
2. Fusionne `AzerothHubInventory` (catalogue des addons Survivors connus, même
   pas encore installés — ils apparaissent alors comme non chargés).
3. Adopte `AzerothHubCatalog` (votre publication).
4. Repère les addons déjà chargés via `IsAddOnLoaded`, les boutons de minimap et
   les commandes slash déjà enregistrées.

Donc : le joueur installe le Hub, puis plus tard votre addon → `/reload` → votre
entrée passe en **chargé**, avec les réglages que vous avez publiés.

## Bloc minimal à ajouter dans votre addon

Placez ceci dans un `.lua` chargé par votre `.toc` (n’importe quel fichier, tôt
ou tard). Le Hub peut se charger avant ou après vous :

```lua
AzerothHubCatalog = AzerothHubCatalog or {}
AzerothHubCatalog.MonAddon = {
  -- true dès que votre addon est réellement utilisable
  available = function()
    return type(SlashCmdList) == "table" and type(SlashCmdList.MONADDON) == "function"
  end,

  -- ouvre votre fenêtre / panneau
  open = function()
    SlashCmdList.MONADDON("")
  end,

  -- optionnel : même cible que « Options d'origine »
  configure = function()
    SlashCmdList.MONADDON("settings")
  end,

  -- réglages éditables dans le Hub (+ profils, sauf profile=false)
  options = function()
    return {
      {
        id = "enabled",
        label = "Activer",
        kind = "check",
        section = "Affichage",
        tip = "Court texte d’aide.",
        get = function() return MonAddonDB.enabled ~= false end,
        set = function(v) MonAddonDB.enabled = v and true or false; MonAddon_Apply() end,
      },
      {
        id = "scale",
        label = "Échelle",
        kind = "slider",
        min = 0.5, max = 2, step = 0.05,
        section = "Affichage",
        unit = "%", displayScale = 100,
        get = function() return MonAddonDB.scale or 1 end,
        set = function(v) MonAddonDB.scale = v; MonAddon_Apply() end,
      },
      {
        id = "mode",
        label = "Mode",
        kind = "choice",
        section = "Affichage",
        values = { "Simple", "Complet" },
        get = function()
          return (MonAddonDB.mode == "full") and 2 or 1
        end,
        set = function(i)
          MonAddonDB.mode = (i == 2) and "full" or "simple"
          MonAddon_Apply()
        end,
      },
    }
  end,
}
```

Le **nom de clé** (`MonAddon`) doit être le **nom du dossier** de l’addon
(celui du `.toc`), caractères `[A-Za-z0-9_]`, max 80.

## Champs reconnus

| Champ | Rôle |
|---|---|
| `available` | `function() → boolean` — l’addon est prêt (slash / API présentes). |
| `open` | Ouvre l’UI principale. |
| `configure` | Ouvre les options natives (sinon le Hub réutilise `open`). |
| `prepare` | Appelé avant de lire `options` (ex. forcer la construction d’un schéma). |
| `options` | `function → liste` **ou** table fixe de descripteurs. |

### Descripteur d’option

| Champ | Requis | Notes |
|---|---|---|
| `id` | oui | Identifiant stable (profils). |
| `label` | recommandé | Texte affiché. |
| `kind` | oui | `check`, `slider` ou `choice`. |
| `get` / `set` | oui | Lecture / écriture ; `set` doit être confirmé par un `get` cohérent. |
| `section` | non | Groupe de lignes. |
| `page` / `pageLabel` | non | Onglets dans le Hub. |
| `tip` | non | Infobulle. |
| `min` `max` `step` | slider | Bornes. |
| `unit` `displayScale` | non | Ex. `"%"` + `100` pour afficher 0.8 → 80 %. |
| `values` | choice | Liste de libellés ; `get` renvoie l’**index** 1..n. |
| `profile` | non | `false` = hors profils (actions de session / données destructives). |
| `reload` | non | `true` = le Hub signale qu’un `/reload` est nécessaire (il ne le lance pas). |

Une intégration déjà écrite **dans** le Hub n’est **pas** écrasée par le catalogue
(vos `open` / `options` ne remplacent pas ceux du Hub s’ils existent déjà).

## Bonnes pratiques

- N’exposez que des réglages d’**affichage / confort**, pas l’historique, les
  collections ni des interrupteurs qui effacent des données (marquez-les
  `profile = false` ou gardez-les dans votre UI seule).
- Dans `set`, appliquez tout de suite (rafraîchir vos frames) pour que le Hub
  puisse confirmer la valeur.
- Testez avec Hub installé **et** sans Hub : le catalogue est inoffensif si Hub
  est absent (`AzerothHubCatalog = AzerothHubCatalog or {}`).
- Après ajout : `/reload`, `/azhub scan`, puis vérifier **Avec réglages**.

## Sans catalogue

Sans `AzerothHubCatalog`, votre addon peut quand même :

- apparaître dans la liste s’il est dans `Inventory.lua` ou déjà chargé ;
- s’ouvrir via un bouton minimap reconnu ou une intégration Hub existante ;
- rester dans **Sans réglages** tant qu’aucun descripteur n’est publié.

Pour demander l’ajout au catalogue d’inventaire distribué avec le Hub (visibilité
même avant installation), contactez le mainteneur avec le nom de dossier, le
`.toc` (Title / Notes / Version) et la commande slash.

## Exemple de test manuel

1. Installer Azeroth Hub + votre addon dans `benilla-config/AddOns`.
2. `/reload`
3. `/azhub` → votre addon dans **Avec réglages** si `options` renvoie au moins une ligne.
4. Modifier une valeur → elle change en jeu ; créer un profil → la valeur est mémorisée.
5. Désactiver votre addon → au prochain scan il n’est plus « chargé » (ou disparaît de l’index natif).
