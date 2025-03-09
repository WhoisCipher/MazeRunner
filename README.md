# MazeRunner

A classic maze navigation game developed in Assembly language.

## Description

Maze Runner is a 2D maze navigation game written in x86 Assembly. The player must navigate through maze levels using the WASD keys while avoiding obstacles and managing time constraints.

## Features

- **Menu System**: Navigate using arrow keys and select with Enter
- **Game Controls**:
  - WASD for player movement
  - Spacebar to activate Superman mode
  - ESC to pause the game
  - R to reset the current level
  - Q to quit the game
- **Game Elements**:
  - Score tracking
  - Lives system
  - Timer functionality
  - Superman mode for special abilities

## Technical Details

The game utilizes several BIOS interrupts for core functionality:
- **INT 10h**: BIOS VGA modes for graphics
- **INT 9h**: Keyboard interrupt for player input
- **INT 8h**: Timer interrupt for game timing

## Code Structure

The codebase is organized into several key components:

### Interrupt Handlers
- **Keyboard Interrupt**: Handles menu navigation and in-game controls
- **Timer Interrupt**: Manages game timing with approximately 18 ticks per second

### Game Functions
- Screen management (video mode setting, clearing)
- Menu drawing and selection
- Player movement
- Score and lives tracking
- Timer functionality
- Superman mode toggle

### Graphics
- Custom font rendering
- Color palette configuration
- Maze rendering
- UI element drawing

## Developers

- Moiz Ijaz
- Abdullah Shoain

## Building and Running

### Manual Build
This game is designed to run in a 16-bit DOS environment. It can be assembled using NASM or similar x86 assemblers and executed in DOS or a DOS emulator like DOSBox.

```
nasm maze.asm -o maze.com
```

### Automated Build

You can use either Bash or Lua build scripts to automate the build process.

#### Lua Build Script

1. Install Lua:
   - Ubuntu/Debian: `sudo apt-get install lua5.3`
   - macOS: `brew install lua`
   - Windows: Download from the official Lua website

2. Make the build script executable (Linux/macOS):
   ```bash
   chmod +x build.lua
   ```

3. Run the build script:
   - Linux/macOS: `./build.lua` or `lua build.lua`
   - Windows: `lua build.lua`


#### Requirements for Automated Build
- NASM assembler
- Bash shell (Linux/macOS/WSL) or Lua interpreter
- Optional: DOSBox for testing
- Optional: zip utility for creating distribution packages

## Distribution Packages

The build scripts can create distribution packages for easy sharing of your game. A distribution package includes:

1. **The executable file** (`maze.com`) - Your compiled game that users can run
2. **Documentation** (`README.md`) - Instructions and information about the game
3. **Convenience scripts** (`run_game.bat`) - A batch file for easy game launching
4. **Everything packaged in a ZIP file** - For easy distribution

Users who receive your distribution package can simply extract the ZIP file and run the game without needing to compile it themselves.

## Running the Game

After building, run the game in DOSBox:

1. Mount your directory in DOSBox:
   ```
   mount c /path/to/game
   c:
   ```

2. Run the executable:
   ```
   maze.com
   ```

Or use the automated launcher in the build script by selecting "yes" when asked if you want to run the game in DOSBox.

## Screenshots

*Screenshots of the game would be placed here*

## Notes

- The game uses VGA mode 13h (320x200, 256 colors) for graphics
- Custom interrupt handling is implemented for keyboard and timer functions
- The code segment starting at 0x0100h is typical for .COM files in DOS
