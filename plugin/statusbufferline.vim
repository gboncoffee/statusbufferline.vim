" Title:        statusbufferline.vim 
" Description:  statusline that shows the buffer list
" Last Change:  5 September 2022
" Mainteiner:   Gabriel G. de Brito https://github.com/gboncoffee
" Location:     plugin/statusbufferline.vim
" License:      MIT

if !exists('g:sbline_show_bfnr')
    let g:sbline_show_bfnr = 1
endif

if !exists('g:sbline_show_modified')
    let g:sbline_show_modified = 1
endif

if !exists('g:sbline_ruler')
    let g:sbline_ruler = 3
endif

if !exists('g:sbline_to_status')
    let g:sbline_to_status = 0
endif

if !exists('g:sbline_to_tabs')
    let g:sbline_to_tabs = 1
endif

if !exists('g:sbline_crop_bufname')
    let g:sbline_crop_bufname = 1
endif

if !exists('g:sbline_ignore')
    let g:sbline_ignore = [ 'nofile', 'quickfix', 'fugitive' ]
endif

if !exists('g:sbline_dynamic_tabline')
    let g:sbline_dynamic_tabline = 0
endif

if !exists('g:sbline_devicons')
    let g:sbline_devicons = 1
endif

augroup StatusBufferLine
    autocmd!
    if g:sbline_dynamic_tabline
        autocmd BufAdd,BufDelete,TabClosed,VimEnter * call GetBuffers()
    else
        " this is EXTREMELLY workaround but it works to force the tabline to be
        " redraw actually after the buffer is unlisted (at least in my machine
        " worked)
        autocmd BufDelete * call feedkeys(":\<BS>")
    endif
augroup END

function! TabList()

    let l:list=""
    let l:tabs=gettabinfo()
    let l:cur=tabpagenr()

    if len(l:tabs) > 1
        for l:tab in l:tabs

            if l:tab.tabnr == l:cur
                let l:list ..= "%#TabLineSel#"
            endif

            let l:list ..= " " .. l:tab.tabnr

            if l:tab.tabnr == l:cur
                let l:list ..= "%#*#"
            endif
        endfor
    endif

    return l:list

endfunction

function! GetBuffers()
    let l:bufs = getbufinfo({'buflisted':1})

    " we remove the ignored buffers from the list so we later can have a proper
    " list lenght
    let l:buffers = []
    for l:bufr in l:bufs

        let l:ignore = 0
        for l:type in g:sbline_ignore
            " I swear that I understand this conditional
            if getbufvar(l:bufr.bufnr, "&buftype") == l:type || getbufvar(l:bufr.bufnr, "&filetype") == l:type
                let l:ignore = 1
                break
            endif
        endfor

        if !l:ignore
            call add(l:buffers, l:bufr)
        endif

    endfor

    " we use this function as a hook to the dynamic tabline option
    " it needs a conditional to check if it needs to redraw (which will
    " eventually runs it again), otherwise it would enter a crazy recursion
    "
    " obviously I discovered the recursion with Neovim being slugish. the
    " perfomance difference with the conditinal is simply increadible
    if g:sbline_dynamic_tabline
        let l:last_opt=&showtabline
        if len(l:buffers) < 2
            let l:new_opt = 1
            set showtabline=1
        else
            let l:new_opt = 2
            set showtabline=2
        endif
    endif

    return l:buffers

endfunction

function! StatusBufferLine()

    let l:buffers = GetBuffers()

    let l:status = ""
    let l:counter = 0
    for l:bufr in l:buffers

        if l:bufr.bufnr == bufnr('%')
            let l:status ..= "%#TabLineSel#"
            if l:counter != 0
                let l:status ..= " "
            endif
        else
            if l:counter != 0
                let l:status ..= " "
            endif
            let l:status ..= "%#*#"
        endif

        if g:sbline_show_bfnr == 1
            let l:status ..= l:bufr.bufnr .. " "
        endif

        let l:bufname = bufname(bufr.bufnr)

        if empty(l:bufname)
            let l:bufname = "[No Name]"
        else
            if g:sbline_crop_bufname
                let l:bufnamesep=strridx(l:bufname, "/")
                let l:bufname=l:bufname[l:bufnamesep+1:]
            endif

            if g:sbline_devicons && exists('*WebDevIconsGetFileTypeSymbol()')
                let l:status ..= WebDevIconsGetFileTypeSymbol(l:bufname) .. " "
            endif
        endif

        let l:status ..= l:bufname

        if l:bufr.changed && g:sbline_show_modified
            let l:status ..= " [+]"
        endif

        let l:counter += 1

    endfor

    let l:status ..= " %#*#"

    if g:sbline_ruler == 1
        let l:status ..= '%=%-14.(%l,%c%V%) %P'
    elseif g:sbline_ruler == 2
        let l:status ..= '%=%-10.(%l,%2c:%L%)'
    elseif g:sbline_ruler == 3
        let l:status ..= "%=" .. TabList()
    endif

    return l:status

endfunction

if g:sbline_to_status == 1
    set statusline=%!StatusBufferLine()
elseif g:sbline_to_tabs == 1
    set tabline=%!StatusBufferLine()
endif
