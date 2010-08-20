" Description: Executes the sqlplus file from the NERDTree.
" Mainainder: Alexandru Tica <alexandru.tica.at.gmail.com>
" License: Apache License 2.0

if exists("g:vorax_nerdtree_exec")
    finish
endif
let g:vorax_nerdtree_exec = 1 

" Add ! key to execute a node in vorax.
call NERDTreeAddKeyMap({'key': '@', 'quickhelpText': 'Execute file in vorax.', 'callback': 'NERDTreeVoraxExec'})

" Callback function to actually execute the vorax file.
function! NERDTreeVoraxExec()
  let treenode = g:NERDTreeFileNode.GetSelected()
  if !treenode.path.isDirectory
    let cmd = treenode.path.str({'escape': 0})
    " to address blanks in path on windows
    let cmd = fnamemodify(cmd, ':8')
    if exists('*Vorax_UtilsToolkit')
      let utils = Vorax_UtilsToolkit()
      if utils.Managed(cmd)
        call vorax#Exec('@' . cmd, 1, "")
      else
        echo g:vorax_messages['wrong_file']
      endif
    endif
  else
      echo g:vorax_messages['dir_not_allowed']
  endif
endfunction 

