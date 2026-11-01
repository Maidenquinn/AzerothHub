# Discord message — Azeroth Hub 0.7.1

```md
**Azeroth Hub 0.7.1** is out.

Central launcher and settings hub for Azeroth Survivors: one place to open your addons and tweak what they expose, without digging through a dozen panels.

**What's new / what it does**
- Multiple **profiles** (solo, coop, test…): create as many as you want, copy an existing one, switch whenever you like.
- One **unified UI** for integrated settings (checks, sliders, lists) + access to each addon's original options.
- **Dynamic** profile load: switching profiles reapplies saved settings; after `/reload`, a newly installed addon shows up in the list.
- The full addon list from [SurvivorsForge](https://forge.rezondes.net/) is supported in the Hub (visibility + launch). Depending on the addon: Hub-integrated settings, or its native window.
- **14 game languages** (English, Polski, Čeština, Deutsch, Português (Brasil), Español, Français, Română, Türkçe, Русский, Українська, 简体中文, 日本語, 한국어). Follows the game language (`azsLanguage`) automatically; you can override it under **Azeroth Hub → Language** (needs `/reload` to rebuild the window).

**Download**
https://github.com/Maidenquinn/AzerothHub/releases/tag/v0.7.1  
Take **AzerothHub-0.7.1.zip** (not “Source code”), extract the `AzerothHub` folder into `AddOns`, relaunch. `/azhub` or click the gear.

**Addon authors — automatic Hub support**  
Publish `AzerothHubCatalog` from your addon (no Hub patch required):

1. Key = exact addon folder name (same as the `.toc`)
2. `available` / `open` (and `configure` if needed)
3. `options` with stable descriptors: `id`, `kind` (`check` / `slider` / `choice`), safe `get` / `set` — **labels in English** (Hub translates them)
4. `profile = false` for session-only / destructive controls; `reload = true` if a `/reload` is needed (Hub never forces it)

Details + example: https://github.com/Maidenquinn/AzerothHub/blob/main/docs/INTEGRATION.md
```
