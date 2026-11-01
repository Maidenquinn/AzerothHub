# Discord message — Azeroth Hub 0.7.4 (first announcement)

```md
**Azeroth Hub 0.7.4** is out

Azeroth Hub is the **central launcher and settings hub** for Azeroth Survivors. One place to open your addons, tweak what they expose, and switch between saved setups — without digging through a dozen separate panels.

**What you get**
- **Multiple profiles** (solo, coop, light, custom…): create, copy, switch anytime; reapply saved settings in one click
- **One UI** for integrated Hub settings (checks / sliders / lists) + **Original options** to open each addon’s own window
- **Dynamic**: newly installed addons show up after `/reload`; left list sections (With settings / catalog) are collapsible
- **SurvivorsForge catalog**: addons listed on https://forge.rezondes.net/ are visible in the Hub (launch + native options; deeper Hub controls where integrated)
- **14 game languages** — follows the game language; change anytime via the language dropdown next to **Appearance**

**Download**
https://github.com/Maidenquinn/AzerothHub/releases/tag/v0.7.4  
Take **AzerothHub-0.7.4.zip** (not “Source code”) → extract the `AzerothHub` folder into `AddOns` → relaunch → `/azhub` or click the gear on the minimap.

---

**Currently supported**

*Hub settings (edit inside Hub + profiles)*  
Azeroth Hub · Azeroth FieldKit · Azerloot · Azeroth Cursor · Azeroth Stats · ASBuilder · AZS Spell Meter · AZS Elite Tracker · AZS Max Hit · Survivor UI · Survivor Plates · AetherHUD · BigCursor · LocalClock · Vulchan’s Combat Text · Azeroth Clarity

*Listed / openable (native window or minimap; Hub settings if the author publishes a catalog)*  
BlackwellUI · BordoUI · KeijinUI · SurvivorsDragonUi · SurvivorUI Classic · MoveAnything / MoveUI · LuckyOdds · ASTinyPlates · and the rest of the SurvivorsForge / Desktop catalog (Azeroth Challenges, Collector, Death Recap, Pilot Bridge, etc.)

If an addon is on Forge but not installed yet, it still appears under **Catalog** until you install it.

---

**Addon authors — automatic Hub support (no Hub patch required)**

Publish `AzerothHubCatalog` from your own addon:

1. **Key** = exact addon folder name (same as the `.toc`)
2. **`available`** / **`open`** (and **`configure`** if you have a separate options panel)
3. **`options`** with stable descriptors: `id`, `kind` (`check` / `slider` / `choice`), safe `get` / `set` — prefer **English labels** (Hub translates them)
4. **`profile = false`** for session-only / destructive controls; **`reload = true`** if a `/reload` is needed (Hub never forces it)

After `/reload`, your addon appears under **With settings**.

Full guide + example:  
https://github.com/Maidenquinn/AzerothHub/blob/main/docs/INTEGRATION.md
```
