# Mr. Mythical: Gear Check

> **Comprehensive gear validation tool for Mythic+ and Raid groups with detailed inspection and issue detection.**

## What Does This Addon Do?

Quickly inspect your group's gear to identify common preparation issues like missing enchants, empty gem sockets, and low durability items before starting challenging content.

---

**❤️ Support development on [Patreon](https://www.patreon.com/c/mrmythical)** - Help keep Mr. Mythical and all our addons updated and feature-rich!

---

## Key Features

### **Comprehensive Gear Validation**
Perform detailed inspections of player equipment to identify common issues:
- **Enchants**: Detect missing enchants and low-rank enchantments on gear
- **Gems & Sockets**: Identify empty or missing sockets and inappropriate gem selections
- **Durability**: Flag low durability items that may break during encounters
- **Item level**: Optional average and per-piece item-level gates
- **Embellishments**: Optional Unique-Equipped: Embellished count (cap 2)
- **Spec hints**: Warn when chest/leg/weapon enchants or gems use the wrong primary stat

### **Commands**
- `/mrgc` or `/gearcheck` - Open the gear check interface

## Data Source

`enchantments.json` is the source of truth for gem/enchant data. The addon consumes a generated Lua mirror file at runtime:

- Place `enchantments.json` at the repo root (array of entry objects, or `{ "entries": [...] }`)
- Generate/update Lua data: `node scripts/generate_enchantments_lua.js`
- Optional custom path: `node scripts/generate_enchantments_lua.js path/to/enchantments.json`
- Generated file: `Data/EnchantmentsData.lua`

Keep `enchantments.json` updated on patch/season changes, then regenerate before releasing.

## Patch-day data updates

When a new season or enchant list ships:

1. Replace `enchantments.json` at the repo root (array of entries, or `{ "entries": [...] }`).
2. Keep `CURRENT_EXPANSION` in `scripts/generate_enchantments_lua.js` in sync with `Data/SeasonData.lua` (`SeasonData.EXPANSION`). Enchantment tables for Midnight are still tagged as expansion **11**.
3. Regenerate Lua: `node scripts/generate_enchantments_lua.js`
4. Revisit `Data/SeasonData.lua`:
   - Item-level presets (`ILVL_PRESETS`) if the Spark/vault band moved
   - `MAX_EMBELLISHMENTS` if Unique-Equipped: Embellished changes
   - `SPEC_PRIMARY_STAT` / named chest mappings (`ENCHANT_NAME_PRIMARY`) if new specs or named enchants appear
5. Revisit `Data/ConfigData.lua` `ENCHANTABLE_SLOTS` if Blizzard adds or removes slot enchants.

### Midnight enchant slots (Interface 120100)

**Checked:** Head, Shoulder, Chest, Legs, Feet, Rings, Main Hand, Off Hand.

**Not enchanted this expansion:** Neck, Wrist, Hands, Belt, Cloak, Trinkets.

**Class exceptions:** Death Knights need a weapon **rune** (not a generic weapon enchant). Shields and held-in-off-hand items skip the off-hand enchant check.

Embellishment and item-level gates default **off** so groups are not spammed; enable them in Settings → Mr. Mythical → Gear Check → Season Rules.

## Download

Get the latest version from your preferred addon manager:

[Download on CurseForge](https://www.curseforge.com/wow/addons/mr-mythical-gear-check)

[Download on Wago](https://addons.wago.io/addons/mrmythicalgearcheck)

## Related Addons

Looking for more Mythic+ tools? Check out our companion addons:

**[Mr. Mythical: Mythic+ Dashboard & Tooltips](https://github.com/Mr-Mythical/MrMythicalAddon)** - Enhanced keystone tooltips with detailed reward info, score calculations, and personal progress tracking.

[Download on CurseForge](https://www.curseforge.com/wow/addons/mr-mythical)

[Download on Wago](https://addons.wago.io/addons/mrmythical)

**[Mr. Mythical: Leaderboard](https://github.com/Mr-Mythical/MrMythicalLeaderboard)** - Display top Mythic+ runs from Raider.IO directly in your keystone tooltips.

[Download on CurseForge](https://www.curseforge.com/wow/addons/mr-mythical-leaderboard)

[Download on Wago](https://addons.wago.io/addons/mrmythicalleaderboard)

**[Mr. Mythical: Assistant](https://github.com/Mr-Mythical/MrMythicalAssistant)** - A sophisticated unicorn companion who provides witty commentary and helpful automation for your adventures.

[Download on CurseForge](https://www.curseforge.com/wow/addons/mr-mythical-assistant)

[Download on Wago](https://addons.wago.io/addons/mrmythicalassistant)

## More Tools & Resources

Visit **[MrMythical.com](https://mrmythical.com)** for additional Mythic+ & Raid tools.

### **Want to report a bug or suggest a feature?**
Visit our [GitHub Issues](https://github.com/Mr-Mythical/MrMythicalGearCheck/issues) page for bug reports and feature requests.

## Author

**Braunerr** - Addon developer

---

**Mr. Mythical: Gear Check - Comprehensive gear validation for detecting preparation issues.**

*Part of the Mr. Mythical addon ecosystem.*