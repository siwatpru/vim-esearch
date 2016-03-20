" TODO add highlight of the replaced text
fu! esearch#substitute#do(args, from, to, out)
  let line = a:from
  let limit = a:from > a:to ? a:from + 1 : a:to + 1

  let pushed_right = 0
  let root = tabpagenr()
  let last_modified_tab = tabpagenr()
  let opened_files = {}
  let prev_filename = ''
  let noautocmd = 'noautocmd '

  while line < limit
    exe line
    if getline(line) =~# a:out.file_entry
      let not_found = 0

      let filename = a:out.filename()
      let target_line = a:out.line_number()
      let already_opened = has_key(opened_files, filename)

      if already_opened
        exe noautocmd.'tabn'.opened_files[filename].'|'.target_line
      else
        call a:out.open('$tabnew')
        let opened_files[filename] = tabpagenr()
      endif

      try
        exe 's'a:args
      catch /E486:/
        let not_found = 1
      catch
        let useless_tab = tabpagenr()
        exe noautocmd.'tabn'.root
        exe noautocmd.'tabclose'.useless_tab
        echohl Error | echo v:exception | echohl Normal
        return
      endtry

      if !not_found
        if !exists('b:esearch')
          let b:esearch = { 'matchids': [] }
          augroup ESearchSubstituteHL
            au! * <buffer>
            au InsertEnter,BufWritePost,TextChanged <buffer> call s:clear_hightligh()
          augroup END
        endif
        call add(b:esearch.matchids, matchadd('DiffChange', '\%'.target_line.'l', -1))
      endif

      if not_found && !already_opened
        call remove(opened_files, filename)
        let useless_tab = tabpagenr()
        exe noautocmd.'tabn'.root
        exe noautocmd.'tabclose'.useless_tab
      else
        let last_modified_tab = tabpagenr()
        exe noautocmd.'tabn'.root
        if !pushed_right
          let pushed_right = 1
          " Push current search tab to the right (penultimate position,
          " before the newly opened) for more convenience
          let root = tabpagenr('$') - 1
          exe noautocmd.'tabm '.(root - 1 )
        endif
      endif

    endif
    let line += 1
  endwhile

  exe 'tabn'last_modified_tab
  echo len(opened_files) . ' files changed'
endfu

fu! s:clear_hightligh()
  au! ESearchSubstituteHL * <buffer>
  for m in b:esearch.matchids
    call matchdelete(m)
  endfor
  unlet b:esearch
endfu
