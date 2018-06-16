import Foundation
import VimInterface

/// VimPlugin is the main protocol for the plugin
public protocol VimPlugin {
    // Handle an event from Vim
    func event(event id: Int, context: String) -> String?
}

private var SharedPlugin: VimPlugin?

public struct VimKit {
    /// Set the plugin
    public static func setPlugin(_ plugin: VimPlugin) {
        if SharedPlugin != nil {
            fatalError("Plugin already set")
        }
        SharedPlugin = plugin
    }

    /// Dispatch events to the plugin
    public static func event(event: Int, context: UnsafePointer<Int8>) -> UnsafePointer<Int8>? {
        let ret = SharedPlugin?.event(event: event,
            context: String(cString: context))
        return UnsafePointer<Int8>(ret)
    }
}

