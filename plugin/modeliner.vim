" Modeliner
"
" Version: 0.3.1-junkblocker
" Description:
"
"   Generates a modeline from current settings.
"
" Last Change: Nov 27 2025 09:08 AM PST-Jun-2008.
" Maintainer: Shuhei Kubota <chimachima@gmail.com>
"
" Usage:
"   execute ':Modeliner'.
"   Then a modeline is generated.
"
"   The modeline will either be appended next to the current line or replace
"   the existing one.
"
"   If you want to customize option, modify g:Modeliner_format.

if !exists('g:Modeliner_format')
    let g:Modeliner_format = 'et ff= fenc= sts= sw= ts='
    " /[ ,:]/ delimited.
    "
    " if the type of a option is NOT 'boolean' (see :help 'option-name'),
    " append '=' to the end of each option.
endif


"[text] vi: tw=80 noai
"[text]	vim:tw=80 noai
" ex:tw=80 : noai:
"
"[text] vim: set tw=80 noai:[text]
"[text] vim: se tw=80 noai:[text]
"[text] vim:set tw=80 noai:[text]
" vim: set tw=80 noai: [text]
" vim:se tw=80 noai:


command! Modeliner  call <SID>Modeliner_execute()


" to retrieve the position
let s:Modeline_SEARCH_PATTERN = '\svi:\|vim:\|ex:'
" to extract options from existing modeline
let s:Modeline_EXTRACT_PATTERN = '\v(.*)\s+(vi|vim|ex):\s*(set?\s+)?(.+)' " very magic
" first form
"let s:Modeline_EXTRACT_OPTPATTERN1 = '\v(.+)' " very magic
" second form
let s:Modeline_EXTRACT_OPTPATTERN2 = '\v(.+):(.*)' " very magic


function! s:Modeliner_execute()
    " find existing modeline, and determine the insert position
    let l:info = s:SearchExistingModeline()

    " parse g:Modeliner_format and join options with them
    let l:extractedOptStr = g:Modeliner_format . ' ' . l:info.optStr
    let l:extractedOptStr = substitute(l:extractedOptStr, '[ ,:]\+', ' ', 'g')
    let l:extractedOptStr = substitute(l:extractedOptStr, '=\S*', '=', 'g')
    let l:extractedOptStr = substitute(l:extractedOptStr, 'no\(.\+\)', '\1', 'g')
    let l:opts = sort(split(l:extractedOptStr))
    "echom 'opt(list): ' . join(l:opts, ', ')

    let l:optStr = ''
    let l:prevO = ''
    for o in l:opts
        if o == l:prevO | continue | endif
        let l:prevO = o

        if stridx(o, '=') != -1
            " let optExpr = 'ts=' . &ts
            execute 'let l:optExpr = "' . o . '" . &' . strpart(o, 0, strlen(o) - 1)
        else
            " let optExpr = (&et ? '' : 'no') . 'et'
            execute 'let l:optExpr = (&' . o . '? "" : "no") . "' . o . '"'
        endif

        let l:optStr = l:optStr . ' ' . l:optExpr
    endfor

    if l:info.lineNum == 0
        let l:modeline = s:Commentify(l:optStr)
    else
        let l:modeline = l:info.firstText . ' vim: set' . l:optStr . ' :' . l:info.lastText
    endif
    let l:modeline = trim(l:modeline)


    " insert new modeline
    if l:info.lineNum != 0
        "modeline FOUND -> replace the modeline

        "show the existing modeline
        let l:orgLine = line('.')
        let l:orgCol  = col('.')
        call cursor(l:info.lineNum, 1)
        normal V
        redraw

        "confirm
        "if confirm('Are you sure to overwrite this existing modeline?', "&Yes\n&No", 1) == 1
        echo 'Are you sure to overwrite this existing modeline? [y/N]'
        if char2nr(tolower(nr2char(getchar()))) == char2nr('y')
            call setline(l:info.lineNum, l:modeline)

            "show the modeline being changed
            if (l:info.lineNum != line('.')) && (l:info.lineNum != line('.') + 1)
                redraw
                sleep 1
            endif
        endif

        "back to the previous position
        echo
        execute "normal \<ESC>"
        call cursor(l:orgLine, l:orgCol)
    else
        "modeline NOT found -> append new modeline
        call append('.', l:modeline)
    endif

endfunction


function! s:Commentify(s)
    let l:commentstring = &commentstring
    if len(l:commentstring) == 0
        let l:commentstring = '%s'
    endif
    if exists('g:NERDMapleader') " NERDCommenter
        let l:result = b:left . ' vim: set' . a:s . ' : ' . b:right
    else
        let l:result = substitute(l:commentstring, '%s', ' vim: set' . a:s . ' : ', '')
    endif

    return l:result
endfunction


function! s:SearchExistingModeline()
    let l:info = {'lineNum':0, 'text':'', 'firstText':'', 'lastText':'', 'optStr':''}

    let l:candidates = []

    " cursor position?
    call add(l:candidates, line('.'))
    " user may position the cursor to previous line...
    call add(l:candidates, line('.') + 1)
    let l:cnt = 0
    while l:cnt < &modelines
    " header?
        call add(l:candidates, l:cnt + 1)
    " footer?
        call add(l:candidates, line('$') - l:cnt)
        let l:cnt = l:cnt + 1
    endwhile

    " search
    for i in l:candidates
        let l:lineNum = i
        let l:text = getline(l:lineNum)

        if match(l:text, s:Modeline_SEARCH_PATTERN) != -1
            let l:info.lineNum = l:lineNum
            let l:info.text = l:text
            break
        endif
    endfor

    " extract texts
    if l:info.lineNum != 0
        "echom 'modeline: ' l:info.lineNum . ' ' . l:info.text

        let l:info.firstText = substitute(l:info.text, s:Modeline_EXTRACT_PATTERN, '\1', '')
        let l:info.firstText = substitute(l:info.firstText, '\s$', '', '')

        let l:isSecondForm = (strlen(substitute(l:info.text, s:Modeline_EXTRACT_PATTERN, '\3', '')) != 0)
        "echom 'form : ' . string(l:isSecondForm + 1)
        if l:isSecondForm == 0
            let l:info.lastText = ''
            let l:info.optStr = substitute(l:info.text, s:Modeline_EXTRACT_PATTERN, '\4', '')
        else
            let l:info.lastText = substitute(
                            \ substitute(l:info.text, s:Modeline_EXTRACT_PATTERN, '\4', ''),
                            \ s:Modeline_EXTRACT_OPTPATTERN2,
                            \ '\2',
                            \ '')
            let l:info.optStr = substitute(
                                \ substitute(l:info.text, s:Modeline_EXTRACT_PATTERN, '\4', ''),
                                \ s:Modeline_EXTRACT_OPTPATTERN2,
                                \ '\1',
                                \ '')
        endif
    endif

    "echom 'firstText: ' . l:info.firstText
    "echom 'lastText: ' . l:info.lastText
    "echom 'optStr: ' . l:info.optStr

    return l:info
endfunction


function! s:ExtractOptionStringFromModeline(text)
    let l:info = {}

    let l:info.firstText = substitute(a:text, s:Modeline_EXTRACT_PATTERN, '\1', '')

    let l:isSecondForm = (strlen(substitute(a:text, s:Modeline_EXTRACT_PATTERN, '\3', '') != 0)
    if l:isSecondForm == 0
        let l:info.lastText = ''
        let l:info.optStr = substitute(a:text, s:Modeline_EXTRACT_PATTERN, '\2', '')
    else
        let l:info.lastText = substitute(
                        \ substitute(a:text, s:Modeline_EXTRACT_PATTERN, '\4', ''),
                        \ s:Modeline_EXTRACT_OPTPATTERN2,
                        \ '\2',
                        \ '')
        let l:info.optStr = substitute(
                            \ substitute(a:text, s:Modeline_EXTRACT_PATTERN, '\4', ''),
                            \ s:Modeline_EXTRACT_OPTPATTERN2,
                            \ '\1',
                            \ '')
    endif

    return l:info
endfunction

" vim: set et fenc=utf-8 ff=unix sts=4 sw=4 ts=4 :
