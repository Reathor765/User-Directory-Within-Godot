# User Directory Workspace GUI (UDWG)

A Godot 4.x plugin that adds a FileSystem-like dock for browsing and managing files in the user:// directory of your project.

## Features

- Browse the user:// directory structure in a tree view
- File operations:
  - Open files directly in the editor/inspector
  - Rename files and folders
  - Delete files (moves to trash)
  - Copy file paths
- Drag and drop support for moving files between folders
- File type recognition with appropriate icons
- Collapsed folder view for better organization

## Installation

1. Copy the `UDWG` folder into your project's `addons` directory
2. Enable the plugin in Project → Project Settings → Plugins
3. The "UserDir" dock will appear in the bottom-left panel of the editor

## Usage

### Basic Navigation
- Click the arrow next to folders to expand/collapse them
- Double-click files to open them in the appropriate editor
- Use the Refresh button to update the view

### File Operations
- Right-click any file or folder to show the context menu with options:
  - Open in Inspector
  - Copy Path
  - Rename
  - Delete
- Drag and drop files between folders to move them

### Supported File Types
Special handling and icons for:
- Text files (.txt, .md, .json, .cfg, .ini)
- Godot resources (.tres, .res)
- Godot scenes (.tscn)
- GDScript files (.gd)

## Development

The plugin consists of a single script (`udwg_plugin.gd`) that implements:
- A custom dock widget using Tree control
- File system operations using DirAccess
- Drag and drop functionality
- Context menu actions

## License

MIT License

Copyright (c) 2025 Reathor765

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.