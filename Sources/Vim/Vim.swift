import VimInterface

public struct Vim {
    public static var current: Current {
        return Current()
    }

    /// Run a vim command
    @discardableResult public static func command(_ cmd: String) -> VimValue? {
        var value: VimValue?
        cmd.withCString { cStr in
            //FIXME: handle error propagation
            if let result = swiftvim_command(
                UnsafeMutablePointer(mutating: cStr)) {
                value = VimValue(result)
            }
        }
        return value
    }

    /// Evaluate an expression
    @discardableResult public static func eval(_ cmd: String) -> VimValue? {
        var value: VimValue?
        cmd.withCString { cStr in
            //FIXME: handle error propagation
            if let result = swiftvim_eval(
                UnsafeMutablePointer(mutating: cStr)) {
                value = VimValue(result)
            }
        }
        return value
    }
}

