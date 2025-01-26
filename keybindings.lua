-- Include the following in your init.lua for nvim or source keybindings.lua from your init.lua 

local map = vim.keymap.set
local opts = { noremap = true, silent = true }
-- Vimwiki Markdown Preview
function VimwikiMarkdownPreview()
    -- Path to the script
    local script_path = vim.fn.expand('~/.config/nvim/scripts/vimwiki-markdown-preview.sh')
    -- Check if the script exists
    if vim.fn.filereadable(script_path) == 0 then
        vim.notify("Script not found at " .. script_path, vim.log.levels.ERROR)
        return
    end
    -- Run the script with --index-wiki flag
    local command = string.format('bash %s --index-wiki', vim.fn.shellescape(script_path))
    vim.cmd('silent !' .. command)
end
map('n', '<leader>mip', VimwikiMarkdownPreview, opts)

-- Vimwiki Convert Current File to HTML, move it, and open with qutebrowser
function VimwikiConvertCurrent()
    -- Path to the script
    local script_path = vim.fn.expand('~/.config/nvim/scripts/vimwiki-markdown-preview.sh')
    -- Check if the script exists
    if vim.fn.filereadable(script_path) == 0 then
        vim.notify("Script not found at " .. script_path, vim.log.levels.ERROR)
        return
    end
    -- Get the current file path
    local current_file = vim.api.nvim_buf_get_name(0)
    -- vim.notify("Retrieved file path: " .. current_file, vim.log.levels.INFO) -- Debugging: Print the file path
    -- Check if it's a markdown file
    if not current_file:match('%.md$') then
        vim.notify('Current file is not a Markdown file.', vim.log.levels.ERROR)
        return
    end
    -- Check if the source file exists
    if vim.fn.filereadable(current_file) == 0 then
        vim.notify('Current Markdown file does not exist.', vim.log.levels.ERROR)
        return
    end
    -- Explicitly construct the command string
    local command = "bash " .. vim.fn.shellescape(script_path) .. " --convert " .. current_file
    vim.notify("Running command: " .. command, vim.log.levels.INFO) -- Debugging: Print the command being run
    -- Run the command
    vim.cmd('silent !' .. command)
    vim.notify('Conversion and opening in qutebrowser completed.', vim.log.levels.INFO)
end

map('n', '<leader>mp', VimwikiConvertCurrent, opts)
