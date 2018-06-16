import Foundation
import Vim

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
        return value.replacingOccurrences(of: "'", with: "''")
    }

    /// Mark - Eval Helpers
    public static func exists(variable: String) -> Bool {
        return get("exists('\(escapeForVim(variable))'")
    }

    public static func set(variable: String, value: VimScriptConvertible) {
        command("let \(variable) = \(value.toVimScript())")
    }

    public static func get(variable: String) -> VimValue {
        return eval(variable)
    }

    public static func get(_ variable: String) -> VimValue {
        return eval(variable)
    }

    public static func get(_ variable: String) -> Bool {
        return Bool((eval(variable).asInt() ?? 0) != 0)
    }

    public static func get(_ variable: String) -> Int {
        return eval(variable).asInt() ?? 0
    }

    /// Returns the 0-based current line and 0-based current column
    public static func currentLineAndColumn() -> (Int, Int) {
        return current.window.cursor
    } 

    // FIXME: Use the LibC realpath or something
    // This doesn't handle cases like /tmp/
    public static func realpath(_ path: String) -> String {
        return URL(fileURLWithPath: path)
            .standardizedFileURL.resolvingSymlinksInPath().path
    }

    // MARK - Buffers

    public static func getBufferNumber(for filename: String, openFileIfNeeded: Bool=false) -> Int {
        let path = escapeForVim(realpath(filename))
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

