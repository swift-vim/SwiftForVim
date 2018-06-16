" This is basic vim plugin boilerplate
let s:save_cpo = &cpo
set cpo&vim

" BEGIN_SWIFTVIM
" COMPILED_FOR_SWIFTVIM_VERSION 0.1

" The API uses Python internally
function! s:UsingPython3()
  if has('python3')
    return 1
  endif
  return 0
endfunction

" Prefer py3
let s:using_python3 = s:UsingPython3()
let s:python_until_eof = s:using_python3 ? "python3 << EOF" : "python << EOF"
let s:python_command = s:using_python3 ? "py3 " : "py "

let s:path = fnamemodify(expand('<sfile>:p:h'), ':h')

" SwiftVimEval:
" Eval commands against the VimPlugin instance
"
" The Vim API exposes a single method:
" pluginName.event(Int, String)
"
" This corresponds to the Swift protocol
" protocol VimPlugin {
" 	func event(id: Int, context: String) -> String
" }
"
" ex:
" myvimplugin.event(42, 'MeaningOfLife')
"
function! s:SwiftVimEval( eval_string )
    " Run some python
    if s:using_python3
        return py3eval( a:eval_string )
    endif
    return pyeval( a:eval_string )
endfunction

function! s:SwiftVimSetupPlugin() abort
	exec s:python_until_eof
import vim
import os
import sys

# Directory of the plugin
plugin_dir  = vim.eval('s:path')

# Bootstrap Swift Plugin
sys.path.insert(0, os.path.join(plugin_dir, '.build'))
import __VIM_PLUGIN_NAME__
__VIM_PLUGIN_NAME__.load()

vim.command('return 1')
EOF
endfunction

if s:SwiftVimSetupPlugin() != 1
  echom "Setting up python failed..." . s:path
endif

" Internal, VimRunLoop integration
fun s:SwiftVimRunLoopTimer(timer)
    call s:SwiftVimEval("__VIM_PLUGIN_NAME__.runloop_callback()")
endf

let s:SwiftVimRunLoopTimer = timer_start(100, function('s:SwiftVimRunLoopTimer'), {'repeat':-1})

" END_SWIFTVIM

" This is basic vim plugin boilerplate
let &cpo = s:save_cpo
unlet s:save_cpo

