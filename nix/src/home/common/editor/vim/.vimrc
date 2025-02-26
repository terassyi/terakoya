filetype on
filetype plugin indent on


set termguicolors
let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
set relativenumber
set wildmenu

set ruler
set number
set hidden

set nobackup
set noswapfile
set noerrorbells

set incsearch
set wrapscan
set hlsearch

set laststatus=2

set autoindent
set tabstop=4
set shiftwidth=4

set mouse=a

"dein scripts---------------------------
let s:cache_home = empty($XDG_CACHE_HOME) ? expand('~/.cache') : $XDG_CACHE_HOME
let s:dein_dir = s:cache_home . '/dein'
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'
if !isdirectory(s:dein_repo_dir)
  call system('git clone https://github.com/Shougo/dein.vim ' . shellescape(s:dein_repo_dir))
endif

if &compatible
        set nocompatible
endif

set runtimepath+=$HOME/.cache/dein/repos/github.com/Shougo/dein.vim

if dein#load_state('$HOME/.cache/dein')
        call dein#begin('$HOME/.cache/dein')
                call dein#add('lambdalisue/fern.vim')
                call dein#add('tpope/vim-fugitive')
                call dein#add('majutsushi/tagbar')
                call dein#add('nathanaelkane/vim-indent-guides')
                call dein#add('junegunn/fzf', {'build': './install --all'})
                call dein#add('junegunn/fzf.vim')
                call dein#add('vim-airline/vim-airline')
                call dein#add('vim-airline/vim-airline-themes')
                call dein#add('Shougo/unite.vim')

                call dein#add('prabirshrestha/vim-lsp')
                call dein#add('mattn/vim-lsp-settings')
                call dein#add('prabirshrestha/asyncomplete.vim')
                call dein#add('prabirshrestha/asyncomplete-lsp.vim')
                call dein#add('Shougo/deoplete.nvim')
                call dein#add('lighttiger2505/deoplete-vim-lsp')
                " call dein#add('cohama/lexima.vim')
                call dein#add('vim-denops/denops.vim')
                call dein#add('higashi000/dps-kakkonan')

                call dein#add('doums/darcula')
                call dein#add('sainnhe/sonokai')
                call dein#add ('chriskempson/base16-vim')

                call dein#add('brglng/vim-im-select')

				call dein#add('justmao945/vim-clang')
        call dein#end()
endif

if dein#check_install()
        call dein#install()
endif

" leader setting
let mapleader = "\<Space>"

" Indent highlighit
let g:indent_guides_auto_colors = 0
autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  guibg=red   ctermbg=3
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven guibg=green ctermbg=4

let base16colorspace=256  " Access colors present in 256 colorspace
" colorscheme base16-default-dark
colorscheme darcula

autocmd VimEnter,ColorScheme * highlight Comment ctermfg=235 ctermbg=237
syntax enable

nnoremap <silent> <Leader>g :<C-u>silent call <SID>find_rip_grep()<CR>
function! s:find_rip_grep() abort
    call fzf#vim#grep(
                \   'rg --ignore-file ~/.ignore --column --line-number --no-heading --hidden --smart-case .+',
                \   1,
                \   fzf#vim#with_preview({'options': '--delimiter : --nth 4..'}, 'right:50%', '?'),
                \   0,
                \ )
endfunction

let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'
let g:airline#extensions#tabline#formatter = 'unique_tail'


if has('vim_starting')
        let &t_SI .= "\e[6 q"
        let &t_EI .= "\e[2 q"
        let &t_SR .= "\e[4 q"
endif

nnoremap <Leader>w :w<CR>
nnoremap <Leader>q :q<CR>
nnoremap <Leader>h <C-w>h
nnoremap <Leader>l <C-w>l
nnoremap <Leader>j <C-w>j
nnoremap <Leader>k <C-w>k
nnoremap <Leader>, :bp<CR>
nnoremap <Leader>. :bn<CR>

noremap <C-e> :Fern . -reveal=% -drawer<CR>

noremap <C-Z> :Unite file_mru<CR>
noremap <C-N> :Unite -buffer-name=file file<CR>
noremap <C-P> :Unite buffer<CR>

"inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
"inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
"inoremap <expr> <cr>    pumvisible() ? asyncomplete#close_popup() : "\<cr>"
inoremap <expr><CR> pumvisible() ? "<C-y>" : "<CR>"
set completeopt=menuone,noinsert
inoremap <expr><C-j> pumvisible() ? "<Down>" : "<C-j>"
inoremap <expr><C-k> pumvisible() ? "<Up>" : "<C-k>"

nmap <Tab> gt
nmap <S-Tab> gT

nmap <buffer> gd <plug>(lsp-definition)
nmap <buffer> <C-]> <plug>(lsp-definition)
"nmap <buffer> <Leader>d <plug>(lsp-type-definition)
"nmap <buffer> <Leader>r <plug>(lsp-references)
"nmap <buffer> <Leader>i <plug>(lsp-implementation)
"nmap <buffer> <Leader>e <plug>(lsp-document-diagnostics)
nmap <silent> ] :LspDefinition<CR>
nmap <silent> <Leader>d :LspTypeDefinition<CR>
nmap <silent> [ :LspReferences<CR>
nmap <silent> ]] :LspImplementation<CR>
nmap <buffer> <Leader>e :LspDocumentDiagnostics<CR>
nmap <buffer> <Leader>r :LspRename

let g:lsp_signs_enabled = 1
let g:lsp_diagnostics_echo_cursor = 1
