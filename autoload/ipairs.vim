" vim-ipairs
" File:       ipairs.vim
" Repository: https://github.com/AnthonyK213/vim-ipairs
" License:    The MIT License (MIT)


"" Replace chars in a string according to a dictionary.
function! s:ipairs_str_escape(str)
  let l:str_lst = split(a:str, '.\zs')
  let l:esc_dict = {
        \ "\"": "\\\""
        \ }
  let l:i = 0
  for char in str_lst
    if has_key(esc_dict, char)
      let str_lst[i] = esc_dict[char]
    endif
    let l:i += 1
  endfor
  return join(str_lst, '')
endfunction

function! ipairs#def_map(kbd, key) abort
  let l:key = a:key =~ '\v\<.+\>' ?
        \ "" : "\"" . s:ipairs_str_escape(a:key) . "\""
  exe 'inoremap <buffer> <silent> ' . a:kbd . ' <C-r>=<SID>ipairs_' .
        \ g:pairs_common_map[a:key] . '(' . l:key . ')<CR>'
endfunction
