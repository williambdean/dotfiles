" after/syntax/rst.vim
"
" Fix for syntax errors when including code blocks in rst files.
" This prevents included syntax files (like vim, java, markdown) from setting
" their own 'syn sync' options, which conflicts with the main rst syntax file.

if !exists("b:current_syntax") || b:current_syntax != "rst"
  finish
endif

" Set guards to prevent conflicting 'syn sync' commands from included files.
let b:is_vim_syntax = 1
let b:is_java_syn = 1
let b:is_markdown = 1
