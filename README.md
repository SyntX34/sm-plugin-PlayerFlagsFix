# PlayerFlagsFix

A SourceMod plugin that fixes PLAYER_FLAG_BITS truncation issues causing trigger_push prediction problems in CS:GO and CS:S.

## Description

This plugin addresses a critical issue in Source-1 games (specifically Counter-Strike: Global Offensive and Counter-Strike: Source) where player flags are truncated due to limited bit allocation. This truncation causes prediction issues with trigger_push entities, leading to inconsistent player movement and physics behavior.

The plugin works by patching memory addresses related to player flag handling to expand the bit allocation from 11 bits to 32 bits, allowing for proper flag representation and eliminating prediction errors.

## Installation

1. Compile the [playerflagsfix.sp](scripting/playerflagsfix.sp) file using SourceMod's compiler
2. Place the compiled plugin file in your server's `plugins` folder:
```addons/sourcemod/plugins/playerflagsfix.smx```
3. Copy the gamedata files to your server's `gamedata` folder:
```addons/sourcemod/gamedata/playerflagsfix.csgo.txt```
```addons/sourcemod/gamedata/playerflagsfix.css.txt```
4. Restart your server or load the plugin with:
```sm plugins load playerflagsfix```

## How It Fixes 2025 Source-1 Game Updates Issues
In 2025, Valve's Source-1 game updates introduced changes that exacerbated existing issues with player flag handling:

1. **PLAYER_FLAG_BITS Truncation**: The game engine was truncating player flags to only 11 bits, which is insufficient for modern gameplay requirements
2. **Trigger Push Prediction Issues**: This truncation caused prediction errors in trigger_push entities, resulting in inconsistent player movement
3. **Network Synchronization Problems**: Players experienced different physics behavior between client and server predictions
This plugin resolves these issues by:

- Expanding PLAYER_FLAG_BITS from 11 bits to 32 bits
- Patching m_fFlags to use 32 bits instead of the default 11
- Fixing m_vecBaseVelocity flag handling
- Forcing sendtable updates to ensure proper network synchronization

## Configuration

The plugin provides two console variables for customization:

- `sm_playerflagsfix_enable` (default: 1) - Enable/disable the entire plugin
- `sm_playerflagsfix_fixflags` (default: 1) - Enable/disable the PLAYER_FLAG_BITS fix specifically

## Supported Games

- Counter-Strike: Global Offensive (CS:GO)
- Counter-Strike: Source (CS:S)

## Technical Details

The plugin patches several critical memory addresses:

1. **PLAYER_FLAG_BITS**: Expands from 11-bit to 32-bit flag representation
2. **m_fFlags**: Updates the bit count for player flags
3. **m_vecBaseVelocity**: Fixes flag handling for player velocity
4. **g_SendTableCRC**: Forces sendtable updates for proper network synchronization

## Credits

- Original work by GAMMACASE
- Modified and enhanced by +SyntX34
- Additional contributions by zombiesharp

## Changelog

### Version 1.2
- Initial release with full support for CS:GO and CS:S
- Implementation of memory patching for player flag handling
- Configurable convars for enabling/disabling fixes
- Automatic detection of game version and applying appropriate patches

## Troubleshooting

If you experience issues with the plugin:

1. Check server console for error messages
2. Verify that the correct gamedata files are installed
3. Ensure your SourceMod version is compatible
4. Try toggling the plugin off and on again with:
```sm_playerflagsfix_enable 0```
```sm_playerflagsfix_enable 1```

## Disclaimer

This plugin modifies game memory directly and should be used with caution. Always backup your server before installing plugins that modify core game functionality.