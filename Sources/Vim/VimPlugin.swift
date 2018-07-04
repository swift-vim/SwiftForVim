import VimInterface

/// VimCallable:
/// VarArgs style calling from Vim
/// May return nil if needed
public typealias VimCallable = (([VimValue]) -> VimScriptConvertible?)

/// This is not thread safe and has no reason to be.
private var CallablePluginMethods: [String: VimCallable] = [:]

/// VimPlugin represents the namespaced module which VimScript interacts with.
/// All calls run on Vim's main thread.
public struct VimPlugin {

    /// Set a callable
    /// This may be called from Vim:
    /// Example.invoke("Func", 1, 2, 3)
    ///
    /// @recommendation these functions should return fast. Don't block the event
    /// loop, and use `VimAsync` for slow tasks
    public static func setCallable(_ name: String,
           callable: @escaping VimCallable) {
        CallablePluginMethods[name] = callable
    }

    /// Here the callback is actually invoked
    public static func invokeCallback(_ args: UnsafeMutableRawPointer) -> UnsafePointer<Int8>? {
        guard let ref = swiftvim_tuple_get(args, 0),
            let name = String(VimValue(reference: ref)) else {
            return nil
        }
        return call(name: name, args: args)
    }

    static func call(name: String, args: UnsafeMutableRawPointer) -> UnsafePointer<Int8>? {
        guard let callable = CallablePluginMethods[name] else {
            fatalError("error: tried to call unregistered plugin func: " + name)
        }
        let varArgs: [VimValue] = (1..<swiftvim_tuple_size(args))
            .map {
            i -> VimValue in
            guard let ref = swiftvim_tuple_get(args, i) else {
                fatalError("error: incoherent call usage")
            }
            let value = VimValue(borrowedReference: ref, own: true)
            return value
        }

        /// FIXME: should this return `None` for Nil?
        let ret = callable(varArgs)?.toVimScript() ?? ""
        return UnsafePointer<Int8>(ret)
    }
}

