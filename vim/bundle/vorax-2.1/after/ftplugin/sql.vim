" Description: Overwrite settings for sql file type
" Mainainder: Alexandru Tica <alexandru.tica.at.gmail.com>
" License: Apache License 2.0

" switch to vorax completion
setlocal omnifunc=Vorax_Complete

" defines vorax mappings for the current buffer
if !exists('*Vorax_UtilsToolkit')
  runtime! vorax/lib/vim/vorax_utils.vim
endif

let utils = Vorax_UtilsToolkit()
call utils.CreateBufferMappings()

" take $# as word characters
setlocal isk+=$
setlocal isk+=#

