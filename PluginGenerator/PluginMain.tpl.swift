// VimKit Plugin initialization
import VimKit
import VimAsync

public final class __VIM_PLUGIN_NAME__Plugin: VimPlugin {
    // Handle callbacks from Vim
    public func event(event id: Int, context: String) -> String? {
        return nil
    }
}

// Core bootstrap for the plugin
@_cdecl("__VIM_PLUGIN_NAME___plugin_init")
public func plugin_init(context: UnsafePointer<Int8>) -> Int {
    // Setup the plugin conforming to <VimPlugin> here
    VimKit.setPlugin(__VIM_PLUGIN_NAME__Plugin())
    return 0
}

@_cdecl("__VIM_PLUGIN_NAME___plugin_event")
public func plugin_event(event: Int, context: UnsafePointer<Int8>) -> UnsafePointer<Int8>? {
    return VimKit.event(event: event, context: context)
}

@_cdecl("__VIM_PLUGIN_NAME___plugin_runloop_callback")
public func plugin_runloop_callback() {
    // RunLoop callbacks for threading.
    // Note: VimTask is tested on OSX only as of now.
    // Comment out the next line for use on other platforms.
    VimKit.runLoopCallback()
}

