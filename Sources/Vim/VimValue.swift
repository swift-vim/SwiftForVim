import VimInterface

/// Vim Value represents a value in Vim
///
/// This value is generally created from vimscript function calls. It provides
/// a "readonly" view of Vim's state.
public final class VimValue {
    fileprivate let value: UnsafeVimValue?
    private let doDeInit: Bool

    init(value: UnsafeVimValue?, doDeInit: Bool = false) {
        self.value = value
        self.doDeInit = doDeInit
    }

    deinit {
        /// Correctly decrement when this value is done.
        if doDeInit {
            swiftvim_decref(value)
        }
    }

    // Mark - Casting

    public func asString() -> String? {
        guard let value = self.value else { return nil }
        guard let cStr = swiftvim_asstring(value) else {
            return nil
        }
        return String(cString: cStr)
    }

    public func asInt() -> Int? {
        // Generally, eval results are returned as strings
        // Perhaps there is a better way to express this.
        if let strValue = asString(), 
            let value = Int(strValue) {
            return value  
        }
        guard let value = self.value else { return nil }
        return Int(swiftvim_asint(value))
    }

    public func asList() -> VimList? {
        guard let value = self.value else { return nil }
        return VimList(value: value)
    }

    public func asDictionary() -> VimDictionary? {
        guard let value = self.value else { return nil }
        return VimDictionary(value: value)
    }
}

// A Dictionary
public final class VimDictionary {
    private let value: UnsafeVimValue

    fileprivate init(value: UnsafeVimValue) {
        self.value = value
    }

    public var count: Int {
        return Int(swiftvim_dict_size(value))
    }

    public var keys: VimList {
        guard let list = VimValue(value: swiftvim_dict_keys(value),
                  doDeInit: false).asList() else {
            fatalError("Can't get keys")
         }
         return list
    }

    public var values: VimList {
        guard let list =  VimValue(value: swiftvim_dict_values(value),
                  doDeInit: false).asList() else {
            fatalError("Can't get values")
        }
        return list
    }

    public subscript(index: VimValue) -> VimValue? {
        get {
            guard let v = swiftvim_dict_get(value, index.value) else {
                return nil
            }
            return VimValue(value: v)
        }
        set {
            swiftvim_dict_set(value, index.value!, newValue?.value)
        }
    }

    public subscript(index: String) -> VimValue? {
        get {
            return index.withCString { cStrIdx in
                guard let v = swiftvim_dict_getstr(value, cStrIdx) else {
                    return nil
                }
                return VimValue(value: v)
            }
        }
        set {
            index.withCString { cStrIdx in
                swiftvim_dict_setstr(value, cStrIdx, newValue?.value)
            }
        }
    }
}


/// A List of VimValues
public final class VimList: Collection {
    private let value: UnsafeVimValue

    /// Cast a VimValue to a VimList
    public init(_ vimValue: VimValue) {
        self.value = vimValue.value!
    }

    init(value: UnsafeVimValue) {
        self.value = value
    }

    public var startIndex: Int {
        return 0
    }

    public var endIndex: Int {
        return Int(swiftvim_list_size(value))
    }

    public var isEmpty: Bool {
        return swiftvim_list_size(value) == 0 
    }

    public var count: Int {
        return Int(swiftvim_list_size(value))
    }

    public subscript(index: Int) -> VimValue {
        get {
            return VimValue(value: swiftvim_list_get(value, Int32(index)))
        }
        set {
            swiftvim_list_set(value, Int32(index), newValue.value)
        }
    }

    public func index(after i: Int) -> Int {
        precondition(i < endIndex, "Can't advance beyond endIndex")
        return i + 1
    }
}

// MARK - Internal

/// This is a helper for internal usage
typealias UnsafeVimValue = UnsafeMutableRawPointer

extension UnsafeVimValue {
    func attrp(_ key: String) -> UnsafeVimValue? {
        let value = key.withCString { fCStr in
            return swiftvim_get_attr(
                self,
                UnsafeMutablePointer(mutating: fCStr))
        }
        return value
    }

    func attr(_ key: String) -> String {
        let value = key.withCString { fCStr in
            return swiftvim_get_attr(
                self,
                UnsafeMutablePointer(mutating: fCStr))
        }
        return String(cString: swiftvim_asstring(value)!)
    }

    func attr(_ key: String) -> Int {
        let value = key.withCString { fCStr in
            return swiftvim_get_attr(
                self,
                UnsafeMutablePointer(mutating: fCStr))
        }
        return Int(swiftvim_asint(value))
    }
}

