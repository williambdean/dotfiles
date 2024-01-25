syntax on

set spell
set noerrorbells
set tabstop=4 softtabstop=4
set shiftwidth=4
set expandtab
set smartindent
set nu
set nowrap
set smartcase
set noswapfile
set nobackup
set undodir=~/.vim/undodir
set undofile
set incsearch
set scrolloff=15
set relativenumber
set encoding=utf-8

set backspace=indent,eol,start

set colorcolumn=80
highlight ColorColumn ctermbg=0 guibg=grey

autocmd BufNewFile,BufFilePre,BufRead *.md set filetype=markdown.pandoc

call plug#begin('~/.vim/plugged')

Plug 'jpalardy/vim-slime', { 'for': 'python' }
Plug 'hanschen/vim-ipython-cell', { 'for': 'python' }
Plug 'tpope/vim-fugitive'
Plug 'morhetz/gruvbox'
Plug 'edluffy/hologram.nvim'
Plug 'itchyny/lightline.vim'
Plug 'mbbill/undotree'
Plug 'preservim/nerdtree'
Plug 'mhinz/vim-startify'
Plug 'davidhalter/jedi-vim'
Plug 'github/copilot.vim'
Plug 'nvie/vim-flake8'
Plug 'justinmk/vim-sneak'
Plug 'nvim-lua/plenary.nvim'
Plug 'dense-analysis/ale'
" Plug 'ThePrimeagen/harpoon'
Plug 'nvim-telescope/telescope.nvim'
Plug 'stevearc/oil.nvim'

call plug#end()

let NERDTreeIgnore = ['\.pyc$']

colorscheme gruvbox
set background=dark

let mapleader = " "

nnoremap <leader>h :wincmd h<CR>
nnoremap <leader>j :wincmd j<CR>
nnoremap <leader>k :wincmd k<CR>
nnoremap <leader>l :wincmd l<CR>

nnoremap <leader>n :NERDTreeFocus<CR>
nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <C-f> :NERDTreeFind<CR>

nnoremap <leader>o o<esc>k

let g:sneak#label = 1

" Find files using Telescope command-line sugar.
nnoremap <leader>ff <cmd>Telescope find_files<cr>
" vim.api.nvim_set_keymap('n', '<Leader>ff', ':lua require"telescope.builtin".find_files({ hidden = true })
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>

" SLIME configuration
" for all buffers
let g:slime_target = "tmux"
let g:slime_default_config = {"socket_name": "default", "target_pane": "{last}", "python_ipython": 0, "dispatch_ipython_pause": 100}
let g:slime_python_ipython = 1
let g:slime_bracketed_paste = 1

" function! _EscapeText_python(text)
"   if slime#config#resolve("python_ipython") && len(split(a:text,"\n")) > 1
"     return ["%cpaste -q\n", slime#config#resolve("dispatch_ipython_pause"), a:text, "--\n"]
"   else
"     let empty_lines_pat = '\(^\|\n\)\zs\(\s*\n\+\)\+'
"     let no_empty_lines = substitute(a:text, empty_lines_pat, "", "g")
"     let dedent_pat = '\(^\|\n\)\zs'.matchstr(no_empty_lines, '^\s*')
"     let dedented_lines = substitute(no_empty_lines, dedent_pat, "", "g")
"     let except_pat = '\(elif\|else\|except\|finally\)\@!'
"     let add_eol_pat = '\n\s[^\n]\+\n\zs\ze\('.except_pat.'\S\|$\)'
"     return substitute(dedented_lines, add_eol_pat, "\n", "g")
"   end
" endfunction
