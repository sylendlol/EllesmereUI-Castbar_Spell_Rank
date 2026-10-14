# EllesmereUI-Castbar_Spell_Rank
<img width="1346" height="1084" alt="{59B20C93-D06C-4509-891E-B069C3065C17}" src="https://github.com/user-attachments/assets/a18315a7-9efa-4756-9c1c-36e5556fa676" />

A small standalone add-on for **EllesmereUI** that shows the spell's rank after its name on the EllesmereUI player cast bar.

```
Fireball - Rank 3
Fireball (Rank 3)
```

Built for **WoW Forever** (Interface 16001) and tested against **EllesmereUI v9.4**.

## Features

- Shows the rank of the spell you are casting, channeling or empowering, right after the spell name.
- Two formats: `Spell Name - Rank 3` or `Spell Name (Rank 3)`.
- Optional custom color for the rank text. By default the rank uses the cast bar's Spell Text color.
- Spells without a numbered rank (racials, rankless spells) show only their name.
- Settings apply right away, even mid-cast.
- No EllesmereUI file is modified. The add-on attaches to the Resource Bars module at run time, and if that module is missing it does nothing.

## Requirements

- EllesmereUI
- The EllesmereUI **Resource Bars** module (`EllesmereUIResourceBars`), with the Player Cast Bar enabled

## Installation

1. Download or clone this repository.
2. Copy the `EllesmereUI_CastRank` folder into your AddOns folder, for example:
   `World of Warcraft\_classic_beta_\Interface\AddOns\EllesmereUI_CastRank`
3. Make sure the folder contains `EllesmereUI_CastRank.toc` directly (not a nested folder).
4. Enable **EllesmereUI Cast Rank** in the add-on list and `/reload`.

## Settings

Open EllesmereUI → **Resource & Cast Bars** → **Cast Bar** tab and scroll to the **EXTRAS** section at the bottom.

| Setting | Description |
| --- | --- |
| **Show Spell Rank** | Turns the rank suffix on or off (off by default). |
| **Rank Format** | `Spell Name - Rank 3` or `Spell Name (Rank 3)`. |
| **Custom Rank Color** | Off: the rank uses the Spell Text color. On: the rank uses the color below. |
| **Rank Color** | Color of the rank text when Custom Rank Color is on. |

Settings are saved in your EllesmereUI Resource Bars profile, so they follow profile switches. A Resource Bars reset clears them as well.

## Text style

The rank is added to the same text as the spell name, so it follows the cast bar's **Spell Text** settings: font, size, outline, position (Left / Right / Center) and X/Y offset. Only the color can be set separately.

## Notes and limitations

- The rank text comes from the game client (`GetSpellSubtext`), so it is localized, for example "Rank 3" on English clients.
- The preview bar at the top of the options page always shows plain "Spell Name". The rank appears on live casts only.
- A long spell name plus its rank can be cut off on a narrow cast bar. Make the bar wider or the Spell Text smaller if that happens.

## For developers

The Cast Bar page's EXTRAS section is a small shared host (`ns._EUICastExtras` on the Resource Bars module namespace). Other cast bar add-ons can add their own rows without wrapping the page builder again:

```lua
local ns = EllesmereUI._ModuleNS["EllesmereUIResourceBars"]
-- copy the host block from CastRank_Options.lua, then:
X.Register("MyExtra", 20, function(parent, y)
    y = X.Header(parent, y, EllesmereUI.Widgets)
    -- add your rows, return the new y
    return y
end)
```

Saved settings (in `profile.castBar`): `rankSuffixEnabled`, `rankSuffixFormat` (`"dash"` / `"paren"`), `rankSuffixCustom`, `rankSuffixR/G/B`.

## Files

| File | Purpose |
| --- | --- |
| `EllesmereUI_CastRank.toc` | Add-on manifest |
| `CastRank.lua` | Runtime: hooks the cast bar's spell name text and adds the rank |
| `CastRank_Options.lua` | The EXTRAS section on the Cast Bar options page |

## Credits

Add-on for EllesmereUI by Ellesmere. This project is not affiliated with EllesmereUI.
