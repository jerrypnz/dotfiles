" Mainainder: Alexandru Tica <alexandru.tica.at.gmail.com>
" License: Apache License 2.0

" no multiple loads allowed
if exists("g:vorax_search")
  finish
endif

" mark as loaded
let g:vorax_search = 1

runtime! vorax/lib/vim/vorax_utils.vim
let s:tk_utils = Vorax_UtilsToolkit()

let s:search = {}

function s:search.onComplete(item, method)
  let parts = split(a:item, ' :')
  if len(parts) > 0
    let to_be_inserted = substitute(parts[0], '\s*$', '', '')
    exe 'normal a' . to_be_inserted
    startinsert!
  endif
endfunction

function s:search.onAbort()
  startinsert!
endfunction

function s:search.find()
  if exists('g:fuf_modes')
    call add(g:fuf_modes, 'voraxitem')
    call fuf#voraxitem#launch('', 0, '>', self)
  else
    call s:tk_utils.EchoErr("FuzzyFinder plugin not found!")
    startinsert!
  endif
endfunction

function Vorax_SearchToolkit()
  return s:search
endfunction
