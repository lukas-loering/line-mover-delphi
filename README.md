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

1. Build the `LineMover.bpl` project.
2. Load the compiled BPL into the Delphi IDE via **Component > Install Packages**.
3. Restart the IDE if necessary.

Tested with:

- **Embarcadero Delphi 12**  
  Version 29.0.53982.0329

## License

This plugin is based on code from the [DDevExtensions](https://github.com/ahausladen/DDevExtensions) project by Andreas Hausladen, and is licensed under the [Mozilla Public License 2.0](https://www.mozilla.org/MPL/2.0/).

See the `LICENSE` file for details.
