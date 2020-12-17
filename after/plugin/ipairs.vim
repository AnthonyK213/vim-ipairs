" vim-ipairs
" File:       ipairs.vim
" Repository: https://github.com/AnthonyK213/vim-ipairs
" License:    The MIT License (MIT)


" Global variables.
"" Can be overwritten.
""" User defined pairs.
let g:pairs_usr_def = get(g:, 'pairs_usr_def', {"(":")", "[":"]", "{":"}", "'":"'", "\"":"\"", "<":">"})
"let g:pairs_usr_def = {
"      \ "("  : ")",
"      \ "["  : "]",
"      \ "{"  : "}",
"      \ "'"  : "'",
"      \ "\"" : "\"",
"      \ "<"  : ">"
"      \ }

"" For key maps.
""" Common.
let g:pairs_common_map = {
      \ "<CR>": "enter",
      \ "<BS>": "backs"
      \ }

for [key, val] in items(g:pairs_usr_def) 
  if key ==# val
    call extend(g:pairs_common_map, {key:"quote"})
  else
    call extend(g:pairs_common_map, {key:"mates", val:"close"})
  endif
endfor

"" Pair special quotes.
let g:last_spec = '"''\\'
let g:next_spec = '"'''
let g:back_spec = '\v^\b'
let g:pairs_is_word = 'a-z_\u4e00-\u9fa5'
augroup pairs_special
  autocmd!
  au BufEnter *.rs let g:last_spec = '"''\\&<'
  au BufLeave *.rs let g:last_spec = '"''\\'
  au BufEnter *.vim let g:back_spec = '\v^\s*$'
  au BufLeave *.vim let g:back_spec = '\v^\b'
augroup end


" Functions
function! s:ipairs_reg(str)
  return '\v[' . a:str . ']'
endfunction

"" Get the character around the cursor.
let s:ipairs_context = {
      \ 'l' : ['.\%',   'c'],
      \ 'n' : ['\%',   'c.'],
      \ 'b' : ['^.*\%', 'c'],
      \ 'f' : ['\%', 'c.*$']
      \ }
function! s:ipairs_context.get(arg) abort
  return matchstr(getline('.'), self[a:arg][0] . col('.') . self[a:arg][1])
endfunction

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

"" Pairs
function! s:ipairs_is_surrounded(pair_dict)
  let l:last_char = s:ipairs_context.get('l')
  return has_key(g:pairs_usr_def, l:last_char) &&
        \ g:pairs_usr_def[l:last_char] == s:ipairs_context.get('n')
endfunction

function! s:ipairs_enter(...)
  return s:ipairs_is_surrounded(g:pairs_usr_def) ?
        \ "\<CR>\<ESC>O" :
        \ "\<CR>"
endfunction

function! s:ipairs_backs(...)
  return s:ipairs_is_surrounded(g:pairs_usr_def) ?
        \ "\<C-g>U\<Right>\<BS>\<BS>" :
        \ "\<BS>"
endfunction

function! s:ipairs_mates(pair_a)
  return s:ipairs_context.get('n') =~ s:ipairs_reg(g:pairs_is_word) ?
        \ a:pair_a :
        \ a:pair_a . g:pairs_usr_def[a:pair_a] .
        \ repeat("\<C-g>U\<Left>", len(g:pairs_usr_def[a:pair_a]))
endfunction

function! s:ipairs_close(pair_b)
  return s:ipairs_context.get('n') ==# a:pair_b ?
        \ "\<C-g>U\<Right>" :
        \ a:pair_b
endfunction

function! s:ipairs_quote(quote)
  let l:last_char = s:ipairs_context.get('l')
  let l:next_char = s:ipairs_context.get('n')
  if l:next_char ==# a:quote &&
        \ (l:last_char ==# a:quote ||
        \  l:last_char =~ s:ipairs_reg(g:pairs_is_word))
    return "\<C-g>U\<Right>"
  elseif  l:last_char ==# a:quote ||
        \ l:last_char =~ s:ipairs_reg(g:pairs_is_word . g:last_spec) ||
        \ l:next_char =~ s:ipairs_reg(g:pairs_is_word . g:next_spec) ||
        \ s:ipairs_context.get('b') =~ g:back_spec
    return a:quote
  else
    return a:quote . a:quote . "\<C-g>U\<Left>"
  endif
endfunction

function! IpairsDefMap(kbd, key)
  let l:key = "\"" . s:ipairs_str_escape(a:key) . "\""
  exe 'inoremap <silent><expr> ' . a:kbd . ' <SID>ipairs_' .
        \ g:pairs_common_map[a:key] . '(' . l:key . ')'
endfunction


" Key maps
"" <CR> could be remapped by other plugin.
for key in ["(", "[", "{", "'", '"', "<CR>", "<BS>"]
  call IpairsDefMap(key, key)
endfor
augroup pairs_filetype
  autocmd!
  au BufEnter *.el,*.lisp  exe "iunmap '"
  au BufLeave *.el,*.lisp  call IpairsDefMap("'", "'")
  au BufEnter *.xml,*.html call IpairsDefMap("<", "<") | call IpairsDefMap(">", ">")
  au BufLeave *.xml,*.html exe 'inoremap < <' | exe 'inoremap > >'
augroup end
