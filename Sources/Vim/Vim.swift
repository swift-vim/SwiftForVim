import VimInterface

enum VimError: Error {
    case invalidCall(String)
}

public struct Vim {
    public static var current: Current {
        return Current()
    }

    /// Run a Vim command.
    /// :help command
    @discardableResult public static func command(_ cmd: String) throws -> VimValue  {
        var value: VimValue?
        cmd.withCString { cStr in
            if let result = swiftvim_command(
                UnsafeMutablePointer(mutating: cStr)) {
                value = VimValue(result)
            }
        }
        if let value = value {
            return value
        }
        throw getCallError(context: cmd)
    }

    /// Evaluate an expression
    /// :help eval
    @discardableResult public static func eval(_ cmd: String) throws -> VimValue {
        var value: VimValue?
        cmd.withCString { cStr in
            if let result = swiftvim_eval(
                UnsafeMutablePointer(mutating: cStr)) {
                value = VimValue(result)
            }
        }
        if let value = value {
            return value
        }
        throw getCallError(context: cmd)
    }

    private static func getCallError(context: String) -> VimError {
        if let error = swiftvim_get_error() {
            if let base = swiftvim_asstring(error) {
                return VimError.invalidCall(String(cString: base) + " - " + context)
            }
        }
        return VimError.invalidCall(context)
    }
}

