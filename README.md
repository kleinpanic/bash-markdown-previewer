# Vimwiki Markdown Utilities

A powerful set of utilities for enhancing the Vimwiki experience in Neovim. This project combines Lua keybindings with a custom shell script to provide seamless Markdown preview, conversion to HTML, and browser integration. Designed for developers and note-takers who rely on Vimwiki and Markdown for their workflows.

---

## Features

### 1. Markdown Preview
- Preview your entire Vimwiki in Markdown format.
- Automatically indexes and renders the wiki files.
- Opens the preview in your default web browser.

### 2. Convert Markdown to HTML
- Convert the current Markdown file into an HTML document.
- Moves the HTML file to a designated location and opens it in Qutebrowser.
- Ensures compatibility by checking file existence and format.

### 3. Neovim Integration
- Custom Lua keybindings for quick access to preview and conversion features.
- Built-in error handling to notify you of issues (e.g., missing files or unsupported formats).

---

## Installation

### 1. Clone the Repository
```bash
git clone https://github.com/<your-username>/vimwiki-markdown-utilities.git
```

### 2. Configure Neovim
- Include `keybindings.lua` in your Neovim configuration:
  ```lua
  require('path-to-keybindings/keybindings')
  ```
- Alternatively, source it directly in your `init.lua`:
  ```lua
  dofile('~/.config/nvim/keybindings.lua')
  ```

### 3. Place the Shell Script
- Move `vimwiki-markdown-preview.sh` to your Neovim scripts directory:
  ```bash
  mkdir -p ~/.config/nvim/scripts/
  cp vimwiki-markdown-preview.sh ~/.config/nvim/scripts/
  ```
- Ensure the path in `keybindings.lua` matches the script location.

### 4. Install Dependencies
Make sure the following are installed and accessible from your system:
- `bash`
- `pandoc` (for Markdown-to-HTML conversion)
- `qutebrowser` (or modify the script for your preferred browser)
- `sed`
- `find`
- `rsync`
- `grep`
- `mkdir`
- `basenme`
- `diff`

---

## Usage

### Keybindings:

#### Preview Markdown Wiki
- **Keybinding**: `<leader>mip`
- **Description**: Renders and indexes your Vimwiki Markdown files, then opens them in a web browser.

#### Convert and Open Markdown
- **Keybinding**: `<leader>mp`
- **Description**: Converts the current Markdown file to HTML and opens it in Qutebrowser.

### Script Functionality

The `vimwiki-markdown-preview.sh` script performs the following:

#### `--index-wiki`
- Generates an index of your Vimwiki files.
- Prepares a single HTML file for all wikis in your configuration.

#### `--convert <file>`
- Converts a specified Markdown file to HTML using `pandoc`.
- Moves the resulting HTML file to `~/.config/nvim/scripts/vimwiki_html/`.
- Opens the HTML file in Qutebrowser.

#### Example Usage:
```bash
bash vimwiki-markdown-preview.sh --index-wiki
bash vimwiki-markdown-preview.sh --convert ~/vimwiki/notes.md
```

---

## Troubleshooting

1. **Script Not Found**:
   - Ensure the `vimwiki-markdown-preview.sh` path in `keybindings.lua` matches its actual location.

2. **File Not Markdown**:
   - The "Convert and Open" command only works for `.md` files. Check the file format before running the command.

3. **Browser Not Opening**:
   - Verify that `qutebrowser` is installed and accessible. Alternatively, modify the script to use a different browser.

4. **Missing Dependencies**:
   - Install `pandoc` if HTML conversion fails:
     ```bash
     sudo apt install pandoc
     ```

---

## Contribution

Contributions are welcome! If you find bugs, want to suggest features, or improve the code, feel free to open an issue or submit a pull request.

---

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.


