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

set colorcolumn=80
highlight ColorColumn ctermbg=0 guibg=grey

autocmd BufNewFile,BufFilePre,BufRead *.md set filetype=markdown.pandoc

call plug#begin('~/.vim/plugged')

Plug 'tpope/vim-fugitive'
Plug 'morhetz/gruvbox'
Plug 'itchyny/lightline.vim'
Plug 'mbbill/undotree'
Plug 'preservim/nerdtree'
Plug 'mhinz/vim-startify'
Plug 'davidhalter/jedi-vim'
Plug 'nvie/vim-flake8'
Plug 'justinmk/vim-sneak'

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
