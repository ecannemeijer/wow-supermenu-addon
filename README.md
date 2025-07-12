# Supermenu - WoW Classic Addon

A comprehensive character statistics and menu addon for World of Warcraft Classic (Mists of Pandaria).

## Features

### 📊 **Character Statistics Window**
- **Comprehensive Stats Display**: View all your character's primary stats, combat stats, defensive stats, and resistances
- **Accurate Calculations**: Uses correct MoP Classic formulas for armor reduction and other calculations
- **Interactive Tooltips**: Hover over any stat to see detailed explanations
- **Scrollable Interface**: Organized categories with color-coded headers
- **Minimize/Maximize**: Collapsible window to save screen space

### 🎛️ **Main Menu Interface**
- **Clean UI**: Modern dark blue theme matching the stats window
- **Multiple Buttons**: Expandable menu system for additional functions
- **Position Memory**: Remembers window position between game sessions
- **Drag & Drop**: Movable windows for optimal placement

### ⚡ **Quality of Life Features**
- **Auto-Show**: Menu appears automatically when you log in
- **Toggle Commands**: Use `/supermenu` to show/hide the main menu
- **Persistent Settings**: All window positions saved between sessions
- **MoP Classic Compatible**: Designed specifically for Interface 50400

## Installation

1. Download the addon files
2. Extract to your `World of Warcraft\_classic_\Interface\AddOns\` directory
3. Make sure the folder is named exactly `Supermenu`
4. Restart WoW or reload your UI (`/reload`)

## Usage

### Main Menu
- The menu will appear automatically when you log in
- Use `/supermenu` to toggle the main menu visibility
- Drag the window to reposition it (position is saved)

### Character Stats
- Click "Character Stats" button to open the statistics window
- Click again to close it
- Use the minimize button (\_) to collapse the stats window
- Hover over any stat for detailed tooltips
- Scroll through different categories: Primary Stats, Combat Stats, Defensive Stats, Resistances

## File Structure

```
Supermenu/
├── Supermenu.toc      # Addon manifest
├── Supermenu.lua      # Main addon logic
├── Supermenu.xml      # UI frame definitions
└── README.md          # This file
```

## Technical Details

- **Interface Version**: 50400 (MoP Classic)
- **Saved Variables**: `SupermenuDB` (stores window positions)
- **Dependencies**: None (uses standard WoW API)

## Stats Accuracy

This addon uses the correct MoP Classic formulas for:
- Armor damage reduction calculation
- Combat rating conversions
- Proper API function calls for all statistics

## Compatibility

- ✅ **Mists of Pandaria Classic** (Interface 50400)
- ❌ Other WoW versions (would need API adjustments)

## Support

If you encounter any issues or have suggestions for improvements, please create an issue in this repository.

## Version History

### v1.0.0
- Initial release
- Complete stats system with accurate MoP Classic calculations
- Position memory system
- Modern UI design matching reference implementation
- Auto-show functionality
- Comprehensive tooltips and help system