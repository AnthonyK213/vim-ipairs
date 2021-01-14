" vim-ipairs
" File:       ipairs.vim
" Repository: https://github.com/AnthonyK213/vim-ipairs
" License:    The MIT License (MIT)


" Global variables.
"" User defined pairs.
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

if !exists('g:pairs_map_spc')
  let g:pairs_map_spc = 1
endif

let g:pairs_is_word = 'a-z_\u4e00-\u9fa5'

"" Refresh buffer variables.
function! s:ipairs_def_buf()
  let b:pairs_buffer = copy(g:pairs_common)
  let b:last_spec = '"''\\'
  let b:next_spec = '"'''
  let b:back_spec = '\v^\b'
  let b:pairs_buffer_map = {
        \ "<CR>"   : "enter",
        \ "<BS>"   : "backs",
        \ "<M-BS>" : "supbs",
        \ "<SPACE>": "space"
        \ }
  let b:pairs_map_list = [
        \ "(", "[", "{",
        \ ")", "]", "}",
        \ "'", '"',
        \ ]

  if &filetype == 'vim'
    let b:back_spec = '\v^\s*$'
  elseif &filetype == 'rust'
    let b:last_spec = '"''\\&<'
  elseif &filetype == 'lisp'
    call filter(b:pairs_map_list, 'v:val !~ "''"')
    call insert(b:pairs_map_list, '`')
    call extend(b:pairs_buffer, {'`':"'"})
  elseif &filetype == 'html'
    call extend(b:pairs_map_list, ['<', '>'])
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
endfunction

" FIXME: What if just change the file type in the same buffer?
" The problem is that the added key maps should be removed if this 
" kind of change happened...
" Or just add a determination to the functions which tests if the key is in the list.
augroup pairs_switch_buffer
  autocmd!
  au BufEnter * call <SID>ipairs_def_buf() | call <SID>ipairs_def_map_all()
augroup end

let g:pairs_esc_reg = {
      \ "(" : "\\(",
      \ "[" : "\\[",
      \ "{" : "\\{",
      \ ")" : "\\)",
      \ "]" : "\\]",
      \ "}" : "\\}",
      \ "*" : "\\*",
      \ " " : "\\s",
      \ "<" : "\\<",
      \ ">" : "\\>"
      \ }


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
function! s:ipairs_str_escape(str, esc_dict)
  let l:str_lst = split(a:str, '.\zs')
  let l:i = 0
  for char in str_lst
    if has_key(a:esc_dict, char)
      let str_lst[i] = a:esc_dict[char]
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
        \ "\<CR>\<C-o>O" :
        \ "\<CR>"
endfunction

function! s:ipairs_backs()
  let l:back = s:ipairs_context.get('b')
  let l:fore = s:ipairs_context.get('f')
  if l:back =~ '\v\{\s$' && l:fore =~ '\v^\s\}'
    return "\<C-g>U\<Right>\<C-g>U\<BS>\<C-g>U\<BS>""
  endif
  return s:ipairs_is_surrounded(b:pairs_buffer) ?
        \ "\<C-g>U\<Right>\<BS>\<BS>" :
        \ "\<BS>"
endfunction

function! s:ipairs_supbs()
  let l:back = s:ipairs_context.get('b')
  let l:fore = s:ipairs_context.get('f')
  let l:res = [0, 0, 0]
  for [key, val] in items(b:pairs_buffer)
    let l:key_esc = "\\v" . s:ipairs_str_escape(key, g:pairs_esc_reg) . '$'
    let l:val_esc = "\\v^" . s:ipairs_str_escape(val, g:pairs_esc_reg)
    if l:back =~ l:key_esc && l:fore =~ l:val_esc && 
     \ len(key) + len(val) > l:res[1] + l:res[2]
      let l:res = [1, len(key), len(val)]
    endif
  endfor
  return l:res[0] == 1 ?
        \ repeat("\<C-g>U\<Right>", l:res[2]) .
        \ repeat("\<BS>", l:res[1] + l:res[2]) :
        \ "\<BS>"
endfunction

function! s:ipairs_space()
  return s:ipairs_is_surrounded({"{":"}"}) ?
        \ "\<SPACE>\<SPACE>\<C-g>U\<Left>" :
        \ "\<SPACE>"
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
        \ l:last_char =~ s:ipairs_reg(g:pairs_is_word . b:last_spec) ||
        \ l:next_char =~ s:ipairs_reg(g:pairs_is_word . b:next_spec) ||
        \ s:ipairs_context.get('b') =~ b:back_spec
    return a:quote
  else
    return a:quote . a:quote . "\<C-g>U\<Left>"
  endif
endfunction

"" Key maps
""" <CR> could be remapped by other plugin.
function! s:ipairs_def_map(kbd, key)
  let l:key = a:key =~# '\v\<[A-Z].*\>' ?
        \ "" : "\"" . s:ipairs_str_escape(a:key, {"\"": "\\\""}) . "\""
  exe 'inoremap <buffer><silent><expr>' a:kbd '<SID>ipairs_' .
        \ b:pairs_buffer_map[a:key] . '(' . l:key . ')'
endfunction

function! s:ipairs_def_map_all()
  if g:pairs_map_ret
    call s:ipairs_def_map("<CR>", "<CR>")
  endif

  if g:pairs_map_bak
    call s:ipairs_def_map("<BS>", "<BS>")
    call s:ipairs_def_map("<M-BS>", "<M-BS>")
  endif

  if g:pairs_map_spc
    call s:ipairs_def_map("<SPACE>", "<SPACE>")
  endif

  for key in b:pairs_map_list
    call s:ipairs_def_map(key, key)
  endfor

  if exists('g:pairs_usr_extd_map')
    for [key, val] in items(g:pairs_usr_extd_map)
      call s:ipairs_def_map(key, val)
    endfor
  endif
endfunction
