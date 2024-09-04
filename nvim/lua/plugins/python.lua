function switch_to_test_file()
    local current_file = vim.api.nvim_buf_get_name(0)

    local project_directory =
        vim.fn.finddir("tests", vim.fn.expand("%:p:h") .. ";")
end

function get_visual_selection()
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local start_line = start_pos[2]
    local end_line = end_pos[2]
    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
    return lines
end

function python_main_block()
    -- Go to the end of the file
    vim.api.nvim_command("normal! G")
    -- Insert Python main block
    vim.api.nvim_buf_set_lines(0, -1, -1, false, {
        "",
        "",
        'if __name__ == "__main__":',
        "    # TODO: write your code here",
    })
    vim.api.nvim_command("normal! G")
end

function random_seed()
    local function add_rng_to_script(seed)
        local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
        vim.api.nvim_buf_set_lines(0, row, row, false, {
            'seed = sum(map(ord, "' .. seed .. '"))',
            "rng = np.random.default_rng(seed)",
        })
    end

    vim.ui.input({ prompt = "Seed: " }, add_rng_to_script)
end

-- Map <leader>mb to call the function
vim.api.nvim_set_keymap(
    "n",
    "<leader>mb",
    ":lua python_main_block()<CR>",
    { noremap = true, silent = true }
)

vim.api.nvim_set_keymap(
    "n",
    "<leader>rs",
    ":lua random_seed()<CR>",
    { noremap = true, silent = true }
)

function print_current_visual_selection()
    local lines = get_visual_selection()
    local code = table.concat(lines, "\n")
    local file = io.open("temp-python-script.py", "w")
    file:write(code)
    file:close()
    os.execute("python temp-python-script.py")
    os.remove("temp-python-script.py")
end

vim.api.nvim_set_keymap(
    "v",
    "<C-r>",
    ":lua print_current_visual_selection()<CR>",
    { noremap = true, silent = true }
)

return {
    {
        "jpalardy/vim-slime",
        config = function()
            vim.g.slime_target = "tmux"
            vim.g.slime_python_ipython = 1
            vim.g.slime_default_config = {
                socket_name = "default",
                target_pane = "{last}",
                python_ipython = 0,
                dispatch_ipython_pause = 100,
            }
            vim.g.slime_bracketed_paste = 1
        end,
    },
    { "hanschen/vim-ipython-cell" },
}
