if exists('g:loaded_autoload_fuf_voraxitem') || v:version < 702
  finish
endif

let g:loaded_autoload_fuf_voraxitem = 1

let s:sql_dir = substitute(fnamemodify(finddir('vorax/sql', fnamemodify(&rtp, ':p:8')), ':p:8'), '\', '/', 'g')
let s:min_pattern = 3

function fuf#voraxitem#createHandler(base)
  return a:base.concretize(copy(s:handler))
endfunction

function fuf#voraxitem#getSwitchOrder()
  return -1
endfunction

function fuf#voraxitem#renewCache()
endfunction

function fuf#voraxitem#requiresOnCommandPre()
  return 0
endfunction

function fuf#voraxitem#onInit()
endfunction

function fuf#voraxitem#launch(initialPattern, partialMatching, prompt, listener)
  let s:prompt = (empty(a:prompt) ? '>' : a:prompt)
  let s:listener = a:listener
  if exists('s:items')
    unlet s:items
  endif
  call fuf#launch(s:MODE_NAME, a:initialPattern, a:partialMatching)
endfunction

let s:MODE_NAME = expand('<sfile>:t:r')

let s:handler = {}

function s:handler.getModeName()
  return s:MODE_NAME
endfunction

function s:handler.getPrompt()
  return fuf#formatPrompt(s:prompt, self.partialMatching)
endfunction

function s:handler.getPreviewHeight()
  return 0
endfunction

function s:handler.targetsPath()
  return 0
endfunction

function s:handler.makePatternSet(patternBase)
  let parser = 's:interpretPrimaryPatternForNonPath'
  return fuf#makePatternSet(a:patternBase, parser, self.partialMatching)
endfunction

function s:handler.makePreviewLines(word, count)
  return []
endfunction

function s:handler.getCompleteItems(patternPrimary)
  if len(a:patternPrimary) == s:min_pattern && !exists('s:items')
    echo 'Building dictionary for [' . a:patternPrimary . ']. Please wait...'
    let s:items = vorax#Exec('@' . s:sql_dir .  "/search.sql " .shellescape(toupper(a:patternPrimary)), 'Loading items...', 0)
    call map(s:items, 'fuf#makeNonPathItem(v:val, "")')
    call fuf#mapToSetSerialIndex(s:items, 1)
    echo 'Done'
    return s:items
  else
    if exists('s:items') && len(a:patternPrimary) < s:min_pattern 
      unlet s:items
    elseif exists('s:items') && len(a:patternPrimary) > s:min_pattern 
      return s:items
    endif
  endif
  return []
endfunction

function s:handler.onOpen(word, mode)
  call s:listener.onComplete(a:word, a:mode)
endfunction

function s:handler.onModeEnterPre()
endfunction

function s:handler.onModeEnterPost()
endfunction

function s:handler.onModeLeavePost(opened)
  if !a:opened
    call s:listener.onAbort()
  endif
endfunction

