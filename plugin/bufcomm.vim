" bufcomm.vim - Compare buffers using comm with split view
" Maintainer: Generated for vim script comparison
" License: MIT

if exists('g:loaded_bufcomm')
  finish
endif
let g:loaded_bufcomm = 1

command! -nargs=* -complete=file BufComm call bufcomm#open_comparison(<f-args>)
command! BufCommPaths call bufcomm#show_paths()

if !hasmapto('<Plug>BufCommCompare')
  nnoremap <silent> <Leader>bc <Plug>BufCommCompare
endif
nnoremap <silent> <Plug>BufCommCompare :BufComm<CR>
