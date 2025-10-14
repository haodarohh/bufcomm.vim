" buffcomm.vim - Compare buffers using comm command with split view
" Author: Generated for vim script comparison
" License: MIT

if exists('g:loaded_buffcomm')
  finish
endif
let g:loaded_buffcomm = 1

function! s:GetSortedBuffers()
  let buffers = []
  for bufnr in range(1, bufnr('$'))
    if buflisted(bufnr) && bufexists(bufnr)
      let bufname = bufname(bufnr)
      let filepath = bufname

      " Handle unnamed or unsaved buffers
      if empty(bufname) || getbufvar(bufnr, '&modified')
        let tempfile = tempname()
        let lines = getbufline(bufnr, 1, '$')
        call writefile(lines, tempfile)
        let filepath = tempfile
        let cleanup_temp = 1
      else
        let cleanup_temp = 0
      endif

      call add(buffers, {
        \ 'nr': bufnr,
        \ 'name': empty(bufname) ? '[No Name]' : bufname,
        \ 'filepath': filepath,
        \ 'cleanup': cleanup_temp
        \ })
    endif
  endfor
  return buffers
endfunction

function! s:CreateTempFile(lines, suffix)
  let tempfile = tempname() . '_' . a:suffix
  call writefile(a:lines, tempfile)
  return tempfile
endfunction

function! s:CloseAllComparisonWindows()
  if exists('t:buffcomm_tab') && t:buffcomm_tab == tabpagenr()
    tabclose
  endif
endfunction

function! s:SetupComparisonWindow(lines, title, position)
  let tempfile = s:CreateTempFile(a:lines, tolower(substitute(a:title, ' ', '_', 'g')))

  execute 'edit ' . tempfile
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal readonly
  setlocal nomodifiable
  execute 'file [' . a:title . ']'

  " Set up autocmd to close all windows when this buffer is closed
  let b:buffcomm_comparison = 1
  augroup BuffCommCleanup
    autocmd! * <buffer>
    autocmd BufWipeout <buffer> call s:CloseAllComparisonWindows()
  augroup END

  call delete(tempfile)
endfunction

function! s:ShowFilePaths()
  if exists('t:buffcomm_tab') && t:buffcomm_tab == tabpagenr()
    echo "File 1: " . t:buffcomm_file1_path . " (" . t:buffcomm_file1_name . ")"
    echo "File 2: " . t:buffcomm_file2_path . " (" . t:buffcomm_file2_name . ")"
  else
    echo "Not in a BuffComm comparison tab"
  endif
endfunction

function! s:RunCommComparison(file1, file2)
  let cmd_only_file1 = 'comm -23 ' . shellescape(a:file1) . ' ' . shellescape(a:file2)
  let cmd_only_file2 = 'comm -13 ' . shellescape(a:file1) . ' ' . shellescape(a:file2)
  let cmd_common = 'comm -12 ' . shellescape(a:file1) . ' ' . shellescape(a:file2)

  let only_file1 = systemlist(cmd_only_file1)
  let only_file2 = systemlist(cmd_only_file2)
  let common = systemlist(cmd_common)

  if v:shell_error != 0
    echoerr "Error running comm command"
    return
  endif

  return {'only_file1': only_file1, 'only_file2': only_file2, 'common': common}
endfunction

function! BuffComm(...) abort
  let buffers = s:GetSortedBuffers()
  let cleanup_files = []

  if a:0 == 0
    if len(buffers) != 2
      echoerr "Expected exactly 2 active buffers, found " . len(buffers) . ". Please specify two filenames."
      " Clean up any temp files created for unsaved buffers
      for buf in buffers
        if buf.cleanup
          call delete(buf.filepath)
        endif
      endfor
      return
    endif
    let file1 = buffers[0].filepath
    let file2 = buffers[1].filepath
    let name1 = fnamemodify(buffers[0].name, ':t')
    let name2 = fnamemodify(buffers[1].name, ':t')

    " Track temp files for cleanup
    for buf in buffers
      if buf.cleanup
        call add(cleanup_files, buf.filepath)
      endif
    endfor
  elseif a:0 == 2
    let file1 = expand(a:1)
    let file2 = expand(a:2)
    let name1 = fnamemodify(file1, ':t')
    let name2 = fnamemodify(file2, ':t')

    if !filereadable(file1)
      echoerr "File not readable: " . file1
      return
    endif
    if !filereadable(file2)
      echoerr "File not readable: " . file2
      return
    endif
  else
    echoerr "Usage: BuffComm [file1] [file2] or BuffComm (with exactly 2 active buffers)"
    return
  endif

  let temp1 = s:CreateTempFile(sort(readfile(file1)), 'sorted1')
  let temp2 = s:CreateTempFile(sort(readfile(file2)), 'sorted2')

  let result = s:RunCommComparison(temp1, temp2)
  call delete(temp1)
  call delete(temp2)

  " Clean up temporary files created for unsaved buffers
  for tempfile in cleanup_files
    call delete(tempfile)
  endfor

  if empty(result)
    return
  endif

  tabnew

  " Mark this tab as a BuffComm comparison tab and store file paths
  let t:buffcomm_tab = tabpagenr()
  let t:buffcomm_file1_path = file1
  let t:buffcomm_file2_path = file2
  let t:buffcomm_file1_name = name1
  let t:buffcomm_file2_name = name2

  " Setup first window (top left) - use current window
  call s:SetupComparisonWindow(result.only_file1, 'Only in ' . name1, 'topleft')

  " Setup second window (top right) - split vertically
  vnew
  call s:SetupComparisonWindow(result.only_file2, 'Only in ' . name2, 'topright')

  " Setup third window (bottom) - go to first window and split horizontally below both
  wincmd t
  botright new
  call s:SetupComparisonWindow(result.common, 'Common in both files', 'bottom')

  " Focus on first window
  wincmd t

  echo "Comparison complete: " . len(result.only_file1) . " unique to " . name1 .
       \ ", " . len(result.only_file2) . " unique to " . name2 .
       \ ", " . len(result.common) . " common lines"
endfunction

command! -nargs=* BuffComm call BuffComm(<f-args>)
command! BuffCommPaths call s:ShowFilePaths()

nnoremap <Plug>BuffCommCompare :BuffComm<CR>