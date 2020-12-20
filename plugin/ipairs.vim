" vim-ipairs
" File:       ipairs.vim
" Repository: https://github.com/AnthonyK213/vim-ipairs
" License:    The MIT License (MIT)


" Global variables.
"" Can be overwritten.
""" User defined pairs.
let g:pairs_common = {"(":")", "[":"]", "{":"}", "'":"'", "\"":"\""}

if exists('g:pairs_usr_extd')
  call extend(g:pairs_common, g:pairs_usr_extd)
endif

if !exists('g:pairs_map_ret')
  let g:pairs_map_ret = 1
endif

if !exists('g:pairs_map_bak')
  let g:pairs_map_bak = 1
endif

"" For key maps.
""" Common.


"" Pair special quotes.

function! s:ipairs_def_buf()
  "if exists('b:pairs_buffer')
  "  return b:pairs_buffer
  "endif
  let b:pairs_buffer_map = {"<CR>":"enter", "<BS>":"backs"}
  let b:last_spec = '"''\\'
  let b:next_spec = '"'''
  let b:back_spec = '\v^\b'
  let b:pairs_is_word = 'a-z_\u4e00-\u9fa5'
  let b:pairs_buffer = copy(g:pairs_common)
  if &filetype == 'vim'
    let b:back_spec = '\v^\s*$'
  elseif &filetype == 'rust'
    let b:last_spec = '"''\\&<'
  elseif &filetype == 'lisp'
    unlet b:pairs_buffer["'"]
    call extend(b:pairs_common, {'`':"'"})
  elseif &filetype == 'html'
    call extend(b:pairs_buffer, {'<':'>'})
  endif

  for [key, val] in items(b:pairs_buffer) 
    if key ==# val
      if len(val) == 1
        call extend(b:pairs_buffer_map, {key:"quote"})
      else
        call extend(b:pairs_buffer_map, {key:"mates"})
      endif
    else
      call extend(b:pairs_buffer_map, {key:"mates", val:"close"})
    endif
  endfor

  "return b:pairs_buffer
endfunction

augroup pairs_switch_buffer
  autocmd!
  au BuffEnter * call <SID>ipairs_def_buf()
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
  return has_key(b:pairs_buffer, l:last_char) &&
        \ b:pairs_buffer[l:last_char] == s:ipairs_context.get('n')
endfunction

function! s:ipairs_enter()
  return s:ipairs_is_surrounded(b:pairs_buffer) ?
        \ "\<CR>\<ESC>O" :
        \ "\<CR>"
endfunction

function! s:ipairs_backs()
  return s:ipairs_is_surrounded(b:pairs_buffer) ?
        \ "\<C-g>U\<Right>\<BS>\<BS>" :
        \ "\<BS>"
endfunction

function! s:ipairs_mates(pair_a)
  return s:ipairs_context.get('n') =~ s:ipairs_reg(g:pairs_is_word) ?
        \ a:pair_a :
        \ a:pair_a . b:pairs_buffer[a:pair_a] .
        \ repeat("\<C-g>U\<Left>", len(b:pairs_buffer[a:pair_a]))
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

function! s:ipairs_def_map(kbd, key)
  let l:key = a:key =~# '\v\<[A-Z].*\>' ?
        \ "" : "\"" . s:ipairs_str_escape(a:key) . "\""
  exe 'inoremap <buffer><silent><expr> ' . a:kbd . ' <SID>ipairs_' .
        \ b:pairs_buffer_map[a:key] . '(' . l:key . ')'
endfunction


" Key maps
"" <CR> could be remapped by other plugin.
let s:pairs_map_list = [
      \ "(", "[", "{",
      \ ")", "]", "}",
      \ "'", '"',
      \ ]

if g:pairs_map_ret
  call s:ipairs_def_map("<CR>", "<CR>")
endif

if g:pairs_map_bak
  call s:ipairs_def_map("<BS>", "<BS>")
endif

for key in s:pairs_map_list
  call s:ipairs_def_map(key, key)
endfor

if exists('g:pairs_usr_extd_map')
  for [key, val] in items(g:pairs_usr_extd_map)
    call s:ipairs_def_map(key, val)
  endfor
endif
