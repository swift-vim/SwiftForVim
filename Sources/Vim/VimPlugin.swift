import VimInterface

public typealias VimCallabeArgs = Any // Not yet implemented
public typealias VimCallable = ((VimCallabeArgs) -> Any?)

private var CallablePluginMethods: [String: VimCallable] = [:]

public struct VimPlugin {

    /// Set a callable
    /// This may be called from Vim:
    /// Example.invoke("Func", 1, 2, 3)
    /// Note, that args are not yet implemented
    public static func setCallable(_ name: String,
           callable: @escaping VimCallable) {
        CallablePluginMethods[name] = callable
    }

    // Here the callback is handled
    /// The fact that this is here now is a current implementation
    /// detail, and will likely go away in the future.
    public static func invokeCallback(_ args: UnsafeMutableRawPointer) -> UnsafePointer<Int8>? {
        guard let ref = swiftvim_tuple_get(args, 0),
            let name = String(VimValue(reference: ref)) else {
            return nil
        }
        return call(name: name, args: args)
    }

    static func call(name: String, args: UnsafeMutableRawPointer) -> UnsafePointer<Int8>? {
        let callable = CallablePluginMethods[name]
        let ret = callable?([])
        return UnsafePointer<Int8>(String(describing: ret))
    }
}

