" vim-ipairs
" File:       ipairs.vim
" Repository: https://github.com/AnthonyK213/vim-ipairs
" License:    The MIT License (MIT)


function! ipairs#def_map(kbd, key) abort
  "let l:key = a:key =~ '\v\<.+\>' ?
  "      \ "" : "\"" . s:ipairs_str_escape(a:key) . "\""
  "exe 'inoremap <buffer> <silent> ' . a:kbd . ' <C-r>=<SID>ipairs_' .
  "      \ g:pairs_common_map[a:key] . '(' . l:key . ')<CR>'
  echo "haha"
endfunction
