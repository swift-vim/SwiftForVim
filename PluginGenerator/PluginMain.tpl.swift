// VimPlugin Plugin initialization
import __VIM_PLUGIN_NAME__Vim
import __VIM_PLUGIN_NAME__VimAsync

/// plugin_load
/// Core bootstrap for the plugin.
/// This is called from Vimscript, when the plugin loads.
/// Non 0 return value indicates failure.
@_cdecl("__VIM_PLUGIN_NAME___plugin_load")
func plugin_load(context: UnsafePointer<Int8>) -> Int {
    // Obligatory Hello World
    _ = try? Vim.command("echo 'Hello world!'")

    // Set a callable
    // Vimscript can call such as:
    // call s:SwiftVimEval("Swiftvimexample.invoke('helloSwift')")
    VimPlugin.setCallable("helloSwift") {
        _ in
        _ = try? Vim.command("echo 'Hello Vim!'")
        return nil
    }
    return 0
}

// Mark - Boilerplate

/// plugin_runloop_callback
/// This func is called from Vim to wakeup the main runloop
/// It isn't necessary for single threaded plugins
@_cdecl("__VIM_PLUGIN_NAME___plugin_runloop_callback")
func plugin_runloop_callback() {
    // Make sure to add VimAsync to the Makefile
    // and remove the comment.
    VimTaskRunLoopCallback()
}

/// plugin_runloop_invoke
/// This is called from Vim:
/// __VIM_PLUGIN_NAME__.invoke("Func", 1, 2, 3)
/// The fact that this is here now is a current implementation
/// detail, and will likely go away in the future.
@_cdecl("__VIM_PLUGIN_NAME___plugin_invoke")
func plugin_invoke_callback(_ args: UnsafeMutableRawPointer) -> UnsafePointer<Int8>? {
    return VimPlugin.invokeCallback(args)
}



