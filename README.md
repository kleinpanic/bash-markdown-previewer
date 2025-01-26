### README.md

# Vimwiki Markdown Utilities

A collection of Lua keybindings and shell scripts for enhancing the functionality of Vimwiki in Neovim. This project focuses on providing seamless workflows for previewing, converting, and managing Markdown files directly from Neovim.

---

## Features

1. **Markdown Preview**:
   - Quickly preview your Vimwiki Markdown files using a simple keybinding.
   - Leverages a custom shell script to index and render the wiki for better organization.
   - Opens the preview directly in a browser.

2. **Convert Markdown to HTML**:
   - Convert the current Markdown file to HTML and open it in Qutebrowser with one command.
   - Automatically checks for file compatibility and script availability.

3. **Neovim Integration**:
   - Preconfigured keybindings to streamline workflows.
   - Error notifications for missing files or unsupported formats.

---

## Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/<your-username>/vimwiki-markdown-utilities.git
   ```

2. **Add to Neovim**:
   - Include the `keybindings.lua` file in your Neovim configuration.
     ```lua
     require('path-to-keybindings/keybindings')
     ```
   - Alternatively, source it from your `init.lua`:
     ```lua
     dofile('~/.config/nvim/keybindings.lua')
     ```

3. **Place the Shell Script**:
   - Move `vimwiki-markdown-preview.sh` to `~/.config/nvim/scripts/` or update the path in `keybindings.lua`.

4. **Install Requirements**:
   - Ensure you have `bash`, `qutebrowser`, and any additional dependencies needed by the shell script.

---

## Usage

### Keybindings:
- **Preview Markdown Wiki**:
  - Press `<leader>mip` to render and index the Vimwiki Markdown files.

- **Convert and Open Markdown**:
  - Press `<leader>mp` to convert the current Markdown file to HTML and open it in Qutebrowser.

### Script Options:
- The shell script supports:
  - `--index-wiki`: Index and render the entire Vimwiki.
  - `--convert <file>`: Convert a specific Markdown file to HTML.

---

## Troubleshooting

- **Script Not Found**: Ensure the path to `vimwiki-markdown-preview.sh` is correct in `keybindings.lua`.
- **Browser Not Opening**: Verify that Qutebrowser is installed and accessible from the terminal.
- **File Not Markdown**: The `Convert and Open` command only works for `.md` files.

---

## Contributions

Contributions are welcome! Feel free to submit issues or pull requests to improve functionality, add features, or fix bugs.

---

## License

This project is licensed under the MIT License. See the `LICENSE` file for more details.

---

