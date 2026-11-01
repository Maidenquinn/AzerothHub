# Azeroth Hub

Centre de réglages pour Azeroth Survivors. Un bouton sur la minimap ouvre les autres addons et leurs réglages intégrés, avec des profils réutilisables. Le catalogue listé suit les addons référencés sur [SurvivorsForge](https://forge.rezondes.net/).

Interface 11200, Lua 5.0. Version **0.7.3**. UI in the game’s **14 languages** (follows `azsLanguage`; change via the language dropdown next to **Apparence**, then `/reload` if needed).

## Installation

1. Fermer le jeu.
2. Télécharger le ZIP joueur depuis les [releases](https://github.com/Maidenquinn/AzerothHub/releases) — pas l’archive « Source code » générée par GitHub.
3. Extraire le dossier `AzerothHub` dans `benilla-config/AddOns` du client réellement lancé.
4. Vérifier que `AddOns/AzerothHub/AzerothHub.toc` existe, sans dossier imbriqué une seconde fois.
5. Relancer le jeu.

La mise à jour remplace seulement ce dossier. Elle ne modifie pas les autres addons ni leurs fichiers de sauvegarde.

## Utilisation

Clic gauche sur l’engrenage : lanceur. Clic droit, `/azhub` ou `/hub` : gestionnaire.

L’en-tête indique où vous êtes : **profil → addon → onglet**. Les sections se replient d’un clic. Le réglage est la ligne, avec sa valeur à droite.

1. Choisir le profil. En Grimoire, le bouton « Profil » ouvre la liste. En Atelier, la colonne de gauche sert au même usage. En Compact, « Profil » est à gauche de « Addon ».
2. Choisir l’addon. Ses onglets reprennent l’ordre publié par l’addon lorsqu’il en a plusieurs.
3. Modifier un réglage. La valeur change tout de suite quand l’intégration le permet, et le profil actif est mis à jour.
4. Pour un nouveau profil : ouvrir les profils, saisir un nom, puis **Copier ce profil**. Un nom déjà utilisé est refusé.
5. **Reappliquer les réglages enregistrés** restaure le profil actif. S’il faut recharger l’interface, le bouton correspondant apparaît. Rien n’est rechargé tout seul.

**Options d’origine** ouvre le panneau de l’addon. **Retour au Hub** enregistre les valeurs que l’intégration sait lire. **Voir en jeu** masque le Hub sans ouvrir les autres fenêtres et sans activer un addon éteint.

La molette et les barres font défiler les listes. Les flèches avancent d’une page. La molette au-dessus d’un curseur ne change pas sa valeur. Sur ce client, le minimum d’un curseur vertical est en haut.

## Apparences

Le bouton **Apparence** propose Grimoire, Atelier et Compact. Le choix est immédiat, il est enregistré dans `AzerothHubDB.appearance`, et il ne dépend pas du profil de réglages. Une valeur inconnue revient à Grimoire.

## Réglages intégrés

Le Hub ne devine pas la configuration de tous les addons. Il lit des schémas publics ou des intégrations explicites. Il ne copie pas les SavedVariables entières, les collections, l’historique ni les statistiques.

- **Azerloot** : onglets et descripteurs `AzlSettings.TABS` (livre, liste de souhaits, alertes). Le suivi des sorts peut être modifié, mais il est exclu des profils : le désactiver dans Azerloot efface des données de sorts appris.
- **FieldKit** : cases, curseurs et listes de son schéma public, y compris les sous-pages. Les éditeurs de couleurs et de disposition restent dans FieldKit.
- **ASBuilder** : visibilité du suivi, verrouillage, repli, échelle et luminosité. Les builds et les données de partie ne sont pas copiés.
- **Azeroth Cursor** : activation, halo, diamètre, épaisseur, opacité, réticule et point. L’aperçu utilise `CreateVisual` et `Style`. Il ne déplace pas l’aperçu d’origine et n’active pas le repère.
- **Azeroth Stats** : barre, verrouillage, sons des records, échelle et opacité.
- **AZS Spell Meter** et **AZS Elite Tracker** : affichage, verrouillage et annonces par leurs commandes.
- **Clarity** : actions de session, exclues des profils.
- **Survivor UI** : modules principaux (suivi, combat, cadres, chat…). La fenêtre complète reste dans **Options d’origine**.
- **Survivor Plates** : affichage, échelle et filtres de plaques.

Un addon déjà chargé, même absent de `Inventory.lua`, est retrouvé s’il a un bouton sur la minimap dont le nom mène à un addon chargé. Les autres addons apparaissent dans la liste et, quand un raccourci est connu, dans le lanceur. Leurs réglages restent dans leur propre fenêtre tant qu’ils ne publient pas le catalogue ci-dessous, ou qu’aucune intégration n’existe.

### Catalogue pour un addon futur (recommandé)

Guide complet : [docs/INTEGRATION.md](docs/INTEGRATION.md).

Le Hub ne parcourt pas les sauvegardes d’un addon inconnu. L’auteur publie
`AzerothHubCatalog` depuis son propre code (sans patcher le Hub). Exemple minimal :

```lua
AzerothHubCatalog = AzerothHubCatalog or {}
AzerothHubCatalog.MonAddon = {
 available = function() return type(SlashCmdList)=="table" and type(SlashCmdList.MONADDON)=="function" end,
 open = function() SlashCmdList.MONADDON("") end,
 options = function()
  return {
   {id="scale", label="Echelle", kind="slider", min=0.5, max=2, step=0.05,
    section="Affichage", unit="%", displayScale=100,
    get=function() return MonAddonDB.scale end,
    set=function(v) MonAddonDB.scale=v; MonAddon_Apply() end},
  }
 end,
}
```

`kind` : `check`, `slider` ou `choice`. `get` d’une liste renvoie l’**index**.
`profile = false` exclut des profils. `reload = true` signale un `/reload` sans le
lancer. Après `/reload`, l’addon apparaît dans **Avec réglages**. Une intégration
déjà écrite dans le Hub n’est pas écrasée.

Le catalogue d’inventaire livré avec le Hub couvre les addons Survivors courants
(même pas encore installés). Dès qu’un joueur les installe et recharge, le Hub les
détecte et active les raccourcis / réglages connus — **sans modifier leurs sources**.

Un profil enregistre les réglages intégrés. Il n’active pas un addon, ne le décharge pas, et ne remplace pas **Options → AddOns**. Changer de profil n’applique pas les anciennes sélections d’activation.

## Minimap

Au premier lancement récent, les boutons d’addons reconnus sont regroupés dans le lanceur. Leurs cadres d’origine ne sont ni détruits ni réassignés : ils deviennent transparents et non cliquables. **Minimap séparée**, ou `/azhub release`, leur rend l’état observé avant le regroupement. Les marqueurs natifs, coffres et antres ne sont pas regroupés. Si le lanceur est plein, les boutons sans entrée restent visibles.

## Commandes

- `/azhub` ou `/hub` : ouvre ou ferme le gestionnaire
- `/azhub scan` : relit la liste des addons
- `/azhub diag` : version, API et raccourcis
- `/azhub release` : rend les boutons de minimap
- `/azhub cancel` : abandonne d’anciens réglages différés, sans effacer une activation déjà écrite

## Compatibilité

- Client Azeroth Survivors, Interface 11200, Lua 5.0.
- `GetNumAddOns` peut renvoyer 0 alors que les addons locaux tournent. `Inventory.lua` sert alors de catalogue (addons Survivors connus, installés ou non). Un addon de cette liste, installé plus tard, est détecté au `/reload` via `IsAddOnLoaded` / commandes slash / `AzerothHubCatalog`. Pour régénérer l’inventaire côté mainteneur : `python refresh_inventory.py --addons-dir <AddOns> --zips-dir <archives>`. Le script ne lit que les `.toc` / ZIP et n’écrit que cet inventaire.
- Certaines API WoW récentes sont absentes. `EditBox:HasFocus` n’est pas utilisé.

## Limites connues

- Un addon qui ne publie pas `AzerothHubCatalog`, et qui n’a pas d’intégration écrite, reste dans **Sans réglages**.
- Un réglage qui exige un rechargement est signalé. Le Hub ne recharge pas l’interface.
- L’aperçu intégré ne concerne que Cursor, et seulement si son API de rendu est présente.
- Le grand message natif « Bougez pour commencer » peut passer au-dessus des fenêtres. Ce n’est pas corrigé ici.
- Les cadres des autres addons ne sont pas déplacés pour les faire entrer dans le Hub.
- Une archive partagée contient l’inventaire de l’installation où elle a été préparée.

## Vérification

Depuis le dossier du Hub :

```
python tests/run.py
```

Le script cherche Lua 5.0 dans `AZHUB_LUA`, sinon à côté du dépôt dans `azeroth-stats-audit/toolchain/lua50.exe`. Cet exécutable n’est pas fourni avec l’addon. Si `AZHUB_ADDONS` pointe vers le dossier AddOns, les suites supplémentaires chargent les vrais fichiers d’Azerloot et de Cursor lorsqu’ils y sont. Ces suites simulent le client : elles ne remplacent pas un passage dans le jeu.

## Licence

Aucun contrat de licence libre n’accompagne ce dépôt. L’auteur, Maidenhead, publie cette version pour l’installer et l’utiliser dans Azeroth Survivors. Le code ne peut pas être réutilisé dans un autre projet sans accord.

## Historique

Voir [CHANGELOG.md](CHANGELOG.md).
