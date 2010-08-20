" Mainainder: Alexandru Tica <alexandru.tica.at.gmail.com>
" License: Apache License 2.0

" no multiple loads allowed
if exists("g:vorax_utils")
  finish
endif

" mark as loaded
let g:vorax_utils = 1

let s:utils = {}

" print the provided error
function s:utils.EchoErr(msg) dict
  echohl WarningMsg
  echo a:msg
  echohl Normal
endfunction

" Returns an waiting indicator char in order to simulate
" somekind of busy marker.
function! s:utils.BusyIndicator() dict
  if !exists('s:vorax_status') || s:vorax_status == "|"
    let s:vorax_status = '/'
  elseif s:vorax_status == '/'
    let s:vorax_status = '-'
  elseif s:vorax_status == '-'
    let s:vorax_status = '\'
  elseif s:vorax_status == '\'
    let s:vorax_status = '|'
  endif
  return s:vorax_status
endfunction

" This function is used to replace placeholders from resource strings. The
" placeholder format is {#}
function! s:utils.Translate(rs, ...) dict
  let str = a:rs
  let i = 1
  while str =~ '{#}'
    if i > a:0
      " we're out of placeholder values
      break
    endif
    let str = substitute(str, '{#}', a:{i}, '')
    let i += 1
  endwhile
  return str
endfunction

" Get the content of the current buffer
function s:utils.BufferContent() dict
  let lines = getline(0, line('$'))
  let content = ""
  for line in lines
    let content .= line . "\n"
  endfor
  return content
endfunction

" this function returns 1 if the first char from a:str is lower,
" or 0 otherwise. It is used in completion functions to determine
" how the items should be returned: upper or lower.
function s:utils.IsLower(str) dict
  if a:str[0] == tolower(a:str[0])
    return 1
  else
    return 0
  endif
endfunction

" Get the under cursor statemnt boundaries. It returns
" an array with [start_line, start_col, stop_line, stop_col, statement, relpos].
" The meaning of these values are:
" start_line => the line where the current statement begins
" start_col => the column where the current statement begins
" stop_line => the line where the current statement ends
" stop_col => the column where the current statement ends
" statement => the text of the statement
" relpos => the absolute position of the cursor witin the current statement
function s:utils.UnderCursorStatement() dict
  silent! call s:log.trace('start of s:utils.UnderCursorStatement')
  let old_wrapscan=&wrapscan
  let &wrapscan = 0
  let old_search=@/
  let old_line = line('.')
  let old_col = col('.')
  " start of the statement
  let start_line = 0
  let start_col = 0
  " end of the statement
  let stop_line = 0
  let stop_col = 0
  while (start_line == 0)
    let result = search(';\|\/', 'beW')
    if result
      let syn = synIDattr(synIDtrans(synID(line("."), col("."), 1)), "name")  
      if syn == "Constant" || syn == 'Comment'
        " do nothing
      else
        " if the delimitator is not within quotes or comments
        normal l
        let start_line = line('.')
        let start_col = col('.')
      endif
    else
      " set the begining of the statement at the very
      " beginning of the buffer content
      let start_line = 1
      let start_col = 1
    endif
  endwhile
  while (stop_line == 0)
    let result = search(';\|\/', 'W')
    if result
      let syn = synIDattr(synIDtrans(synID(line("."), col("."), 1)), "name")  
      if syn == "Constant" || syn == "Comment"
        " do nothing
      else
        " if the delimitator is not within quotes or comments
        let stop_line = line('.')
        let stop_col = col('.') - 1
      endif
    else
      " set the begining of the statement at the very
      " beginning of the buffer content
      normal G$
      let stop_line = line('.')
      let stop_col = col('.') 
    endif
  endwhile
  " extract the actual statement
  let statement = ""
  for line in getline(start_line, stop_line)
    let statement .= line . "\n"
  endfor
  let statement = strpart(statement, start_col-1, strlen(statement) - (strlen(getline(stop_line)) - stop_col))
  " get rid of the final \n
  let statement = substitute(statement, '\n$', '', '')
  " restore the old pos
  call cursor(old_line, old_col)
  " compute relative pos
  let rel_line = old_line - start_line + 1
  let rel_pos = 1
  let i = 1
  let lines = split(statement, '\n', 1)
  for line in lines
    if i == rel_line
      let rel_pos += old_col - 1
      break
    else
      " we add 1 to count \n
      let rel_pos += strlen(line) + 1
    endif
    let i += 1
  endfor
  let &wrapscan=old_wrapscan
  let @/=old_search
  let retval = [start_line, start_col, stop_line, stop_col, statement, rel_pos]
  silent! call s:log.trace('end of s:utils.UnderCursorStatement: returned value=' . string(retval))
  return retval
endfunction

" Create the mappings for a vorax buffer.
function s:utils.CreateBufferMappings() dict
  " defines vorax mappings for the current buffer
  if mapcheck('<Leader>vl', 'i') == ""
    imap <buffer> <unique> <Leader>vl <Esc>:VoraxSearch<cr>
  endif

  if mapcheck('<Leader>ve', 'n') == ""
    nmap <buffer> <unique> <Leader>ve :VoraxExecUnderCursor<cr>
  endif

  if mapcheck('<Leader>ve', 'v') == ""
    xmap <buffer> <unique> <Leader>ve :VoraxExecVisualSQL<cr>
  endif

  if mapcheck('<Leader>vb', 'n') == ""
    nmap <buffer> <unique> <Leader>vb :VoraxExecBuffer<cr>
  endif

  if maparg('<Leader>vd', 'n') == ""
    nmap <buffer> <unique> <Leader>vd :VoraxDescribe<cr>
  endif

  if maparg('<Leader>vdv', 'n') == ""
    nmap <buffer> <unique> <Leader>vdv :VoraxDescribeVerbose<cr>
  endif

  if mapcheck('<Leader>vg', 'n') == ""
    nmap <buffer> <unique> <Leader>vg :VoraxGotoDefinition<cr>
  endif

  if maparg('<Leader>vdv', 'v') == ""
    xmap <buffer> <unique> <Leader>vdv :VoraxDescribeVerboseVisual<cr>
  endif

  if maparg('<Leader>vd', 'v') == ""
    xmap <buffer> <unique> <Leader>vd :VoraxDescribeVisual<cr>
  endif
endfunction

" Returns 1 if the provided filename is a vorax managed one,
" 0 otherwise. A file is considered vorax managed if its
" extension is within g:vorax_db_explorer_file_extensions or
" is 'sql'
function s:utils.Managed(file) dict
  let ext = fnamemodify(a:file, ':e')
  for item in g:vorax_dbexplorer_file_extensions
    if ext ==? item.ext || ext ==? 'sql'
      return 1
    endif
  endfor
  return 0
endfunction

" When a db object is about to be opened, we don't want the edit window
" to be layed out randomly, or ontop of special windows like the results
" window. This procedure finds out a suitable window for opening the
" db object. If it cannot find any then a new split will be performed.
function s:utils.FocusCandidateWindow() dict
  let winlist = []
  " we save the current window because the after windo we may end up in
  " another window
  let original_win = winnr()
  " iterate through all windows and get info from them
  windo let winlist += [[bufnr('%'),  winnr(), &buftype]]
  for w in winlist
    if w[2] == "nofile" || w[2] == 'quickfix' || w[2] == 'help'
      " do nothing
    else
      " great! we just found a suitable window... focus it please
      exe w[1] . 'wincmd w'
      return
    endif
  endfor
  " if here, then no suitable window was found... we'll create one
  " first of all, restore the old window
  exe original_win . 'wincmd w'
  " split a new window taking into account where the dbexplorer is
  let settings = VrxTree_GetSettings(bufname('%'))
  if settings['vertical']
    " compute how large this window should be
    let span = winwidth(0) - settings['minWidth']
    if settings['side'] == 1
      let splitcmd = 'topleft ' . (span > 0 ? span : "") . 'new'
    elseif settings['side'] == 0
      let splitcmd = 'botright ' . (span > 0 ? span : "") . 'new'
    endif
  else
    " compute how tall this window should be
    let span = winheight(0) - settings['minHeight']
    if settings['side'] == 1
      let splitcmd = 'topleft vertical ' . (span > 0 ? span : "") . 'new'
    elseif settings['side'] == 0
      let splitcmd = 'botright vertical ' . (span > 0 ? span : "") . 'new'
    endif
  endif
  exe splitcmd
endfunction

" Get the corresponding file extension for the provided
" object type. The file extension is returned according to
" the g:vorax_dbexplorer_file_extensions variable.
function s:utils.ExtensionForType(type) dict
  for item in g:vorax_dbexplorer_file_extensions
    if item.type ==? a:type
      return item.ext
    endif
  endfor
  return 'sql'
endfunction

" Get the tools object
function Vorax_UtilsToolkit()
  return s:utils
endfunction

