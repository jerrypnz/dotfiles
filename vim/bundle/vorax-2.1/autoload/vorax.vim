" Description: Autoload buddy script for VoraX.
" Mainainder: Alexandru Tica <alexandru.tica.at.gmail.com>
" License: Apache License 2.0

" no multiple loads allowed
if exists("g:autoload_vorax")
  finish
endif

" flag to signal this source was loaded
let g:autoload_vorax = 1

" Load interfaces
runtime! vorax/interface/**/*.vim

" Load vim libraries
runtime! vorax/lib/vim/*.vim

" Load ruby libraries
let s:ruby_lib_dir = fnamemodify(finddir('vorax/lib/ruby', fnamemodify(&rtp, ':p:8')), ':p:8')
let s:ruby_lib_dir = substitute(s:ruby_lib_dir, '\', '/', 'g')
" the above trickery is for Windows OS
if s:ruby_lib_dir != ""
  let s:ruby_lib_dir = substitute(s:ruby_lib_dir, '\', '/', 'g')
  ruby require "rubygems"
  ruby Dir[VIM::evaluate('s:ruby_lib_dir')+"*.rb"].each {|file| require file}
endif

" The location of the sql script directory
let s:sql_dir = substitute(fnamemodify(finddir('vorax/sql', fnamemodify(&rtp, ':p:8')), ':p:8'), '\', '/', 'g')

" The interface object
let s:interface = Vorax_GetInterface()

" Get the utils toolkit
let s:tk_utils = Vorax_UtilsToolkit()

" Get the connection toolkit
let s:tk_db = Vorax_DbLayerToolkit()

" Get the result window toolkit
let s:tk_rwin = Vorax_RwinToolkit()

" Get the parser toolkit
let s:tk_parser = Vorax_ParserToolkit()

" Geth the connection window toolkit
let s:tk_cwin = Vorax_CwinToolkit()

" This variable contains all plsql_objects processed by the
" last exec command in foreground mode. This is used to
" display errors on compilation.
let s:processed_plsql_objects = []

" This variable contains the buffer number from where the
" last fg exec command was executed.
let s:exec_from_buffer = bufnr('%')

" Just let vim know that we are dealing with an Oracle database
let g:sql_type_default = 'sqloracle'

" Enable logging
if g:vorax_debug
  silent! call log#init('ALL', ['~/vorax.log'])
  silent! let s:log = log#getLogger(expand('<sfile>:t'))
endif

function vorax#Search()
  let search_tk = Vorax_SearchToolkit()
  call search_tk.find()
endfunction

" Executes the provided sql command. If a:show is 1 then the output
" is displayed within the results window. If a:show is 0 then nothing is
" displayed but the result is returned as an array of lines. The big
" diference between these two methods is that the first method executes
" asynchronically, unlike the second one which will wait till the 
" statements completes and all output is fetched. So, do not try to
" execute commands which requires user input using the sync method
" because the call will indefinitelly wait for statement to complete.
function! vorax#Exec(cmd, show, feedback)
  silent! call s:log.trace('start of vorax#Exec(cmd, show)')
  silent! call s:log.debug('cmd=['.a:cmd.'] show=['.a:show.']')
  let result = []
  if s:tk_db.connected
    if s:interface.more
      silent! call s:log.error("VRX-EXEC: still executing")
      throw "VRX-EXEC: " . g:vorax_messages['still_executing']
    else
      let dbcommand = a:cmd
      if dbcommand == ''
        " the command is not provided... assume the under cursor
        " statement
        silent! call s:log.debug('No statement provided. Compute the one under cursor.')
        let stmt = s:tk_utils.UnderCursorStatement()
        let dbcommand = stmt[4]
      endif
      " remove trailing blanks from cmd
      let dbcommand = substitute(dbcommand, '\_s*\_$', '', 'g')
      " add the delimitator
      let dbcommand .= s:tk_db.Delimitator(dbcommand)
      silent! call s:log.debug('statement='.dbcommand)
      " executes the sql file
      if a:show
        if g:vorax_logging
          " to have executed statements sepparated by a new line
          call s:tk_rwin.LogStuff("\n")
        endif
        call s:interface.send(s:interface.pack(dbcommand))
      else
        let result = s:tk_db.Exec(dbcommand, a:feedback)
        if a:feedback != ""
          "clear feedback
          redraw
          echon ""
        endif
        return result
      endif
      if s:interface.last_error == ""
        if a:show
          let s:processed_plsql_objects = s:tk_parser.ModulesInfo(dbcommand)
          let s:exec_from_buffer = bufnr('%')
          silent! call s:log.debug('s:exec_from_buffer='.s:exec_from_buffer)
          " display results asynchronically
          call s:tk_rwin.ShowResults(1)
        endif
      else
        silent! call s:log.error(s:interface.last_error)
        call s:tk_utils.EchoErr(g:vorax_messages['unexpected_error'])
      endif
    endif
  else
    silent! call s:log.error("not connected")
    call s:tk_utils.EchoErr(g:vorax_messages['not_connected'])
  endif
  return result
  silent! call s:log.trace('end of vorax#Exec')
endfunction

" Disconnects the current connection by shutdown the interface
function! vorax#Disconnect()
  silent! call s:log.trace('start of vorax#Disconnect')
  call s:interface.shutdown()
  " we don't want this to be called for every buffer therefore
  " we deregister the VimLeave autocommand after the first run
  autocmd! VoraX VimLeave *
  silent! call s:log.trace('end of vorax#Disconnect')
endfunction

" Get the currently selected block.
function! vorax#SelectedBlock() range
    let save = @"
    silent normal gvy
    let vis_cmd = @"
    let @" = save
    return vis_cmd
endfunction 

" execute the current buffer
function! vorax#ExecBuffer()
  silent! call s:log.trace('start of vorax#ExecBuffer')
  if &ft == 'sql' || &ft == 'plsql'
    let content = s:tk_utils.BufferContent()
    let content .= s:tk_db.Delimitator(content)
    " go to the beginning of the buffer. This is importat,
    " especially when computing error line numbers in
    " quickfix window
    normal gg
    call vorax#Exec(content, 1, "Executing...")
  else
  silent! call s:log.error('wrong buffer')
    call s:tk_utils.EchoErr(g:vorax_messages['wrong_buffer'])
  endif
  silent! call s:log.trace('end of vorax#ExecBuffer')
endfunction

" Connects to the provided database using the cstr
" connection string. The cstr has the common sqlplus
" format user/password@db [as sys(dba|asm|oper). It also
" accepts incomplete formats like user@db or just user, the
" user being prompted afterwards for the missing parts.
function! vorax#Connect(cstr)
  silent! call s:log.trace('start of vorax#Connect(cstr)')
  silent! call s:log.debug('cstr='.a:cstr)
  try
    let result = s:tk_db.Connect(a:cstr)
    call s:tk_rwin.SpitOutput(result)
    if g:vorax_open_scratch_at_connect && bufnr('__scratch__.sql') == -1 && s:tk_db.connected
      " if not already opened
      call s:tk_utils.FocusCandidateWindow()
      silent e! __scratch__.sql
    endif
    redraw
    echo g:vorax_messages['done']
  catch /^VRX-1/
    call s:tk_utils.EchoErr(v:exception)
  endtry
  " registers an autocommand to shutdown the interface when vim exits
  autocmd VoraX VimLeave * call vorax#Disconnect()
  silent! call s:log.trace('end of vorax#Connect(cstr)')
endfunction

" Opens the db explorer window
function! vorax#ToggleConnWindow()
  silent! call s:log.trace('start of vorax#ToggleConWindow()')
  call s:tk_cwin.FocusWindow()
  silent! call s:log.trace('end of vorax#ToggleConWindow()')
endfunction

" Opens the db explorer window
function! vorax#DbExplorer()
  silent! call s:log.trace('start of vorax#DbExplorer()')
  call Vorax_DbExplorerToggle()
  silent! call s:log.trace('end of vorax#DbExplorer()')
endfunction

" Show errors for all create plsql modules, if any
function! vorax#ShowLastCompileErrors()
  silent! call s:log.trace('start of vorax#ShowLastCompileErrors()')
  let in_clause = ""
  silent! call s:log.debug('s:processed_plsql_objects='.string(s:processed_plsql_objects))
  " we rely on the s:processed_plsql_objects array which contains all the
  " information about the plsql modules created/altered at the last exec
  for item in s:processed_plsql_objects
    " build up a nice IN filter which will be used to query the errors
    " table from the database
    let in_clause .= "decode('" . item['owner'] . "', '', SYS_CONTEXT('USERENV', 'SESSION_USER'), '" . 
                    \ item['owner'] . "') || '." . item['object'] . "." . item['type'] . "',"
  endfor
  if in_clause != ""
    "get rid of the final comma and add brackets
    let in_clause = '(' . strpart(in_clause, -1, strlen(in_clause)) . ')'
    " build up the final query... All queried fields are separated by our 
    " custom --> separator and we'll be use that to split the items, later
    let query = "select line || '-->' || position || '-->' || owner || '-->' " .
                  \ "|| name || '-->' || type || '-->' || " .
                  \ "replace(replace(text, chr(10), ' '), '\', '\\') " .
                  \ "from all_errors " .
                  \ "where owner || '.' || name || '.' || type in " . in_clause .
                  \ " order by line, position "
    let result = vorax#Exec(query . ";\n", 0, "")
    silent! call s:log.debug('result='.string(result))
    let qerr = []
    for error in result
      let parts = split(error, '-->')
      silent! call s:log.debug('parts='.string(parts))
      if type(parts) == 3 && len(parts) == 6
        " we expect 6 fields
        let start_module_line = 0
        " find out the correspondence between the record error from
        " ALL_ERRORS and the position of the plsql block in our buffer
        for element in s:processed_plsql_objects
          let owner = element['owner']
          if owner == ""
            " if no owner then it's the currently connected one, we
            " can get it from the title
            let title = split(&titlestring, '@')
            if len(title) > 0
              let owner = title[0]
            endif
          endif
          " match the entry from the db with the one from the buffer
          " source info
          if owner ==? parts[2] && element['object'] ==? parts[3] && element['type'] ==? parts[4]
            " start_module_line contains the line number where the plsql
            " block is declared
            let start_module_line = element['start_line'] - 1
            break
          endif
        endfor
        " get the current line number within the exec buffer
        let wnr = bufwinnr(s:exec_from_buffer)
        if wnr != -1
          " focus the exec buffer only if it's still open
          exe wnr . "wincmd w"
          let crr_line = line('.') - 1
          " add this error to our error list
          let qerr += [{'bufnr' : s:exec_from_buffer, 'lnum' : str2nr(parts[0]) + crr_line + start_module_line, 
                      \ 'col' : str2nr(parts[1]), 'text' : parts[5]}]
        endif
      endif
    endfor
    let qerr = sort(qerr, 's:CompareQuickfixEntries')
    call setqflist(qerr, 'r')
    if len(qerr) > 0
      " show the error window only if we have errors
      botright cwindow
    else
      cclose
    endif
  endif
  silent! call s:log.trace('end of vorax#ShowLastCompileErrors()')
endfunction

" Describes the provided database object. If no object is given then the
" word under cursor is used.
function! vorax#Describe(object)
  silent! call s:log.trace('start of vorax#Describe(object)')
  silent! call s:log.trace('object='.a:object)
  let object = a:object
  if object == ""
    let isk_bak = &isk
    " the $ and # should be considered as part of an word
    set isk=@,48-57,_,$,#,.,\"
    let object = expand('<cword>')
    silent! call s:log.trace('computed object under cursor='.object)
    exe 'set isk=' . isk_bak
  endif
  let result = vorax#Exec(
        \ "set linesize 100\n" .
        \ 'desc ' . object . ";\n" 
        \ , 0, g:vorax_messages['reading'])
  call s:tk_rwin.SpitOutput(result)
  redraw
  echo g:vorax_messages['done']
  silent! call s:log.trace('end of vorax#Describe(object)')
endfunction

" Describes the provided database object. If no object is given then the
" word under cursor is used.
function! vorax#DescribeVerbose(object)
  silent! call s:log.trace('start of vorax#VerboseDescribeTable(object)')
  silent! call s:log.trace('object='.a:object)
  let object = a:object
  if object == ""
    let isk_bak = &isk
    " the $ and # should be considered as part of an word
    set isk=@,48-57,_,$,#,.,\"
    let object = expand('<cword>')
    silent! call s:log.trace('computed object under cursor='.object)
    exe 'set isk=' . isk_bak
  endif
  " check the object type
  let info = s:tk_db.ResolveDbObject(object)
  if has_key(info, 'schema') && (info.type == 2 || info.type == 4)
    let result = vorax#Exec(
          \ '@ ' . s:sql_dir . "/desc_table.sql" . " " . shellescape(info.schema) . " " . shellescape(info.object)
          \ , 0, g:vorax_messages['reading'])
    call s:tk_rwin.SpitOutput(result)
  else
    redraw
    call s:tk_utils.EchoErr(g:vorax_messages['invalid_desc'])
    return
  endif
  redraw
  echo g:vorax_messages['done']
  silent! call s:log.trace('end of vorax#VerboseDescribeTable(object)')
endfunction

" Initialize a VoraX buffer
function vorax#InitBuffer()
  let ext = fnamemodify(bufname('%'), ':e')
  let type = ""
  for item in g:vorax_dbexplorer_file_extensions
    if item.ext ==? ext
      let type = item.type
      break
    endif
  endfor
  if type == 'PACKAGE' || type == 'PACKAGE_SPEC' || type == 'PACKAGE_BODY' ||
    \ type == 'FUNCTION' || type == 'PROCEDURE' || type == 'TYPE' ||
    \ type == 'TYPE_SPEC' || type == 'TYPE_BODY' || type == 'TRIGGER'
    " set as plsql file
    exe 'set ft=plsql'
  elseif (type == "" && ext ==? 'sql') || type != ""
    " set as an sql file if the file has the sql extenssion or
    " a the ext is within the registered ones.
    exe 'set ft=sql'
  endif
endfunction

" Go to the definition under the cursor
function vorax#GotoDefinition(object)
  if a:object == ""
    let isk_bak = &isk
    " the $ and # should be considered as part of an word
    set isk=@,48-57,_,$,#,.,\"
    let object = expand('<cword>')
    exe 'set isk=' . isk_bak
  else
    let object = a:object
  endif
  call s:tk_db.LocateDbObject(object)
endfunction


" Internal function to sort error items in the
" quickfix window
function! s:CompareQuickfixEntries(i1, i2)
  if a:i1.lnum == a:i2.lnum && a:i1.col == a:i2.col
    return 0
  elseif a:i1.lnum == a:i2.lnum && a:i1.col < a:i2.col
    return -1
  elseif a:i1.lnum == a:i2.lnum && a:i1.col > a:i2.col
    return 1
  elseif a:i1.lnum < a:i2.lnum
    return -1
  else
    return 1
  endif
endfunction

