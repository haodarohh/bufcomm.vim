" buffercomm.vim - Compare buffers using comm with split view
" Maintainer: Generated for vim script comparison
" License: MIT

if exists('g:loaded_buffercomm')
  finish
endif
let g:loaded_buffercomm = 1

function! s:GetBufferInfo()
  let buffers = []
  for bufnr in range(1, bufnr('$'))
    if buflisted(bufnr) && bufexists(bufnr)
      let bufname = bufname(bufnr)
      let filepath = bufname
      let cleanup = 0

      if empty(bufname) || getbufvar(bufnr, '&modified')
        let filepath = tempname()
        call writefile(getbufline(bufnr, 1, '$'), filepath)
        let cleanup = 1
      endif

      call add(buffers, {
            \ 'nr': bufnr,
            \ 'name': empty(bufname) ? '[No Name]' : bufname,
            \ 'filepath': filepath,
            \ 'cleanup': cleanup
            \ })
    endif
  endfor
  return buffers
endfunction

function! s:CreateTempfile(lines, suffix)
  let tempfile = tempname() . '_' . a:suffix
  call writefile(a:lines, tempfile)
  return tempfile
endfunction

function! s:CloseComparisonTab()
  if exists('t:buffercomm_tab') && t:buffercomm_tab == tabpagenr()
    tabclose
  endif
endfunction

function! s:SetupComparisonWindow(lines, title)
  let tempfile = s:CreateTempfile(a:lines, substitute(tolower(a:title), ' ', '_', 'g'))
  execute 'edit ' . fnameescape(tempfile)
  setlocal buftype=nofile bufhidden=wipe noswapfile readonly nomodifiable
  execute 'file [' . a:title . ']'
  call delete(tempfile)

  augroup buffercomm_cleanup
    autocmd! * <buffer>
    autocmd BufWipeout <buffer> call s:CloseComparisonTab()
  augroup END
endfunction

function! s:RunComm(file1, file2)
  let cmd1 = 'comm -23 ' . shellescape(a:file1) . ' ' . shellescape(a:file2)
  let cmd2 = 'comm -13 ' . shellescape(a:file1) . ' ' . shellescape(a:file2)
  let cmd3 = 'comm -12 ' . shellescape(a:file1) . ' ' . shellescape(a:file2)

  let only1 = systemlist(cmd1)
  if v:shell_error != 0
    echoerr 'Error running comm command'
    return {}
  endif

  let only2 = systemlist(cmd2)
  let common = systemlist(cmd3)
  return {'only1': only1, 'only2': only2, 'common': common}
endfunction

function! s:ResolveFiles(argcount, ...) abort
  let cleanup = []
  if a:argcount == 0
    let buffers = s:GetBufferInfo()
    if len(buffers) != 2
      echoerr 'Expected exactly 2 active buffers, found ' . len(buffers)
      for buf in buffers
        if buf.cleanup
          call delete(buf.filepath)
        endif
      endfor
      return {}
    endif
    for buf in buffers
      if buf.cleanup
        call add(cleanup, buf.filepath)
      endif
    endfor
    return {
          \ 'file1': buffers[0].filepath,
          \ 'file2': buffers[1].filepath,
          \ 'name1': fnamemodify(buffers[0].name, ':t'),
          \ 'name2': fnamemodify(buffers[1].name, ':t'),
          \ 'cleanup': cleanup
          \ }
  elseif a:argcount == 2
    let file1 = expand(a:1)
    let file2 = expand(a:2)
    if !filereadable(file1)
      echoerr 'File not readable: ' . file1
      return {}
    endif
    if !filereadable(file2)
      echoerr 'File not readable: ' . file2
      return {}
    endif
    return {
          \ 'file1': file1,
          \ 'file2': file2,
          \ 'name1': fnamemodify(file1, ':t'),
          \ 'name2': fnamemodify(file2, ':t'),
          \ 'cleanup': cleanup
          \ }
  endif
  echoerr 'Usage: :BuffComm [file1] [file2]'
  return {}
endfunction

function! s:ClearTempCleanup(paths)
  for path in a:paths
    if filereadable(path)
      call delete(path)
    endif
  endfor
endfunction

function! s:OpenComparison(argcount, ...) abort
  let files = call(function('s:ResolveFiles'), [a:argcount] + a:000)
  if empty(files)
    return
  endif

  let sorted1 = s:CreateTempfile(sort(readfile(files.file1)), 'sorted1')
  let sorted2 = s:CreateTempfile(sort(readfile(files.file2)), 'sorted2')

  let result = s:RunComm(sorted1, sorted2)
  call delete(sorted1)
  call delete(sorted2)
  call s:ClearTempCleanup(files.cleanup)
  if empty(result)
    return
  endif

  tabnew
  let t:buffercomm_tab = tabpagenr()
  let t:buffercomm_file1 = files.file1
  let t:buffercomm_file2 = files.file2
  let t:buffercomm_name1 = files.name1
  let t:buffercomm_name2 = files.name2

  call s:SetupComparisonWindow(result.only1, 'Only in ' . files.name1)
  vnew
  call s:SetupComparisonWindow(result.only2, 'Only in ' . files.name2)
  wincmd t
  botright new
  call s:SetupComparisonWindow(result.common, 'Common in both files')
  wincmd t

  echomsg 'Comparison complete: '
        \ . len(result.only1) . ' unique to ' . files.name1 . ', '
        \ . len(result.only2) . ' unique to ' . files.name2 . ', '
        \ . len(result.common) . ' common lines'
endfunction

function! s:ShowPaths()
  if exists('t:buffercomm_tab') && t:buffercomm_tab == tabpagenr()
    echo 'File 1: ' . t:buffercomm_file1 . ' (' . t:buffercomm_name1 . ')'
    echo 'File 2: ' . t:buffercomm_file2 . ' (' . t:buffercomm_name2 . ')'
  else
    echo 'Not in a BuffComm comparison tab'
  endif
endfunction

function! BufferComm(...) abort
  call s:OpenComparison(a:0, a:000)
endfunction

command! -nargs=* -complete=file BuffComm call BufferComm(<f-args>)
command! BuffCommPaths call s:ShowPaths()

if !hasmapto('<Plug>BuffCommCompare')
  nnoremap <silent> <Leader>bc <Plug>BuffCommCompare
endif
nnoremap <silent> <Plug>BuffCommCompare :BuffComm<CR>
