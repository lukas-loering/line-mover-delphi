# LineMover Delphi Plugin

**LineMover** is a lightweight Delphi IDE plugin (BPL) that emulates Visual Studio Code-style line movement and duplication shortcuts.

## Features

- **Move line or selection up one line**  
    <kbd>Alt</kbd> + <kbd>↑</kbd>
- **Move line or selection down one line**  
    <kbd>Alt</kbd> + <kbd>↓</kbd>
- **Duplicate line or selection up one line**  
    <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>↑</kbd> 
- **Duplicate line or selection down one line**  
    <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>↓</kbd>

These shortcuts work with both single lines (when no text is selected) and multi-line selections.

## Installation

### Get the BPL

You have two options:

- **Option 1: Build from source**  
  Open the `LineMover.bpl` project in Delphi and build it.  
  The compiled `.bpl` will be placed in the configured **Package Output Directory**, which can be found under:  
  **Tools > Options > Language > Delphi > Library > Package Output Directory**

- **Option 2: Download a precompiled BPL**  
  Visit the [Releases](https://github.com/lukas-loering/line-mover-delphi/releases) section to download the compiled `.bpl`.  
  Note: The precompiled version is built for **Delphi 12 Version 29.0.53982.0329** and may not load in other versions.

### Install the Package

1. In Delphi, go to **Component > Install Packages**.
2. Click **Add**, browse to the `.bpl` file, and confirm.
3. Restart the IDE if needed.

Tested with:

- **Embarcadero Delphi 12**  
  Version 29.0.53982.0329

## License

This plugin is based on code from the [DDevExtensions](https://github.com/ahausladen/DDevExtensions) project by Andreas Hausladen, and is licensed under the [Mozilla Public License 2.0](https://www.mozilla.org/MPL/2.0/).

See the `LICENSE` file for details.
