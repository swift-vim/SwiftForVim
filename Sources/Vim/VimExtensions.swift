#if os(Linux)
    import Glibc
    let sysRealpath = Glibc.realpath
#else
    import Darwin.C
    let sysRealpath = Darwin.realpath
#endif

/// Convert to a vimscript string
public protocol VimScriptConvertible {
    func toVimScript() -> String
}

extension Int: VimScriptConvertible{
    public func toVimScript() -> String {
        return String(self)
    }
}

extension String: VimScriptConvertible {
    public func toVimScript() -> String {
        return self
    }
}

extension Vim {
    public static func escapeForVim(_ value: String) -> String {
        return value.reduce(into: "", { acc, x  in
            if x == "'" { acc += "''" }
            else { acc += String(x) }
        })
    }

    /// Mark - Eval Helpers
    public static func exists(variable: String) -> Bool {
        return get("exists('\(escapeForVim(variable))'")
    }

    public static func set(variable: String, value: VimScriptConvertible) {
        _ = try? command("let \(variable) = \(value.toVimScript())")
    }

    public static func get(variable: String) -> VimValue? {
        return try? eval(variable)
    }

    public static func get(_ variable: String) -> VimValue? {
        return try? eval(variable)
    }

    public static func get(_ variable: String) -> Bool {
        return (try? eval(variable))?.asBool() ?? false
    }

    public static func get(_ variable: String) -> Int {
        return (try? eval(variable))?.asInt() ?? 0
    }

    public static func get(_ variable: String) -> String {
        return (try? eval(variable))?.asString() ?? ""
    }

    /// Returns the 0-based current line and 0-based current column
    public static func currentLineAndColumn() -> (Int, Int) {
        return current.window.cursor
    } 

    public static func realpath(_ path: String) -> String? {
        guard let p = sysRealpath(path, nil) else { return nil }
        defer { free(p) }
        return String(validatingUTF8: p)
    }

    // MARK - Buffers

    public static func getBufferNumber(for filename: String, openFileIfNeeded: Bool=false) -> Int {
        guard let rpath = realpath(filename) else { return -1 }
        let path = escapeForVim(rpath)
        let create = openFileIfNeeded == true ? "1" : "0"
        return get("bufnr('\(path)', \(create))")
    }

    public static func bufferIsVisible(bufferNumber: Int) -> Bool {
        guard bufferNumber > 0 else {
            return false
        }
        let windowNumber: Int = get("bufwinnr(\(bufferNumber))")
        return windowNumber != -1
    }
}

