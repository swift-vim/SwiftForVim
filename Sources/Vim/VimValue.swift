import VimInterface


extension Int {
    init?(_ value: VimValue) {
        // Generally, eval results are returned as strings
        // Perhaps there is a better way to express this.
        if let strValue = value.asString(), 
            let intValue = Int(strValue) {
            self.init(intValue)
        } else {
            self.init(swiftvim_asnum(value.reference))
        }
    }

    init?(_ value: VimValue?) {
        guard let value = value else {
            return nil
        }
        self.init(value)
    }
}

extension String {
    init?(_ value: VimValue) {
        guard let cStr = swiftvim_asstring(value.reference) else {
            return nil
        }
        self.init(cString: cStr)
    }

    init?(_ value: VimValue?) {
        guard let value = value else {
            return nil
        }
        self.init(value)
    }
}

extension Bool {
    init?(_ value: VimValue) {
        self.init((Int(value) ?? 0) != 0)
    }

    init?(_ value: VimValue?) {
        guard let value = value else {
            return nil
        }
        self.init(value)
    }
}

/// Vim Value represents a value in Vim
///
/// This value is generally created from vimscript function calls. It provides
/// a "readonly" view of Vim's state.
public final class VimValue {
    let reference: UnsafeVimValue
    private let doDeInit: Bool

    init(_ value: UnsafeVimValue, doDeInit: Bool = false) {
        self.reference = value
        self.doDeInit = doDeInit
    }

    /// Borrowed reference
    init(borrowedReference: UnsafeVimValue) {
        self.reference = borrowedReference
        self.doDeInit = false
    }

    init(reference: UnsafeVimValue) {
        // FIXME: Audit spmvim_lib.c for cases of this
        self.reference = reference
        self.doDeInit = true
    }

    deinit {
        /// Correctly decrement when this value is done.
        if doDeInit {
            swiftvim_decref(reference)
        }
    }
}

/// Casting extensions
extension VimValue {
    public func asString() -> String? {
        return String(self)
    }

    public func asInt() -> Int? {
        return Int(self)
    }

    public func asBool() -> Bool? {
        return Bool(self)
    }

    public func asList() -> VimList? {
        return VimList(self)
    }

    public func asDictionary() -> VimDictionary? {
        return VimDictionary(self)
    }
}

// A Dictionary
public final class VimDictionary {
    private let value: VimValue

    init?(_ value: VimValue) {
        self.value = value
    }

    public var count: Int {
        return Int(swiftvim_dict_size(value.reference))
    }

    public var keys: VimList {
        guard let list = VimValue(reference: swiftvim_dict_keys(value.reference)).asList() else {
            fatalError("Can't get keys")
         }
         return list
    }

    public var values: VimList {
        guard let list = VimValue(reference: swiftvim_dict_values(value.reference)).asList() else {
            fatalError("Can't get values")
        }
        return list
    }

    public subscript(index: VimValue) -> VimValue? {
        get {
            guard let v = swiftvim_dict_get(value.reference, index.reference) else {
                return nil
            }
            return VimValue(v)
        }
        set {
            swiftvim_dict_set(value.reference, index.reference, newValue?.reference)
        }
    }

    public subscript(index: String) -> VimValue? {
        get {
            return index.withCString { cStrIdx in
                guard let v = swiftvim_dict_getstr(value.reference, cStrIdx) else {
                    return nil
                }
                return VimValue(v)
            }
        }
        set {
            index.withCString { cStrIdx in
                swiftvim_dict_setstr(value.reference, cStrIdx, newValue?.reference)
            }
        }
    }
}


/// A List of VimValues
public final class VimList: Collection {
    private let value: VimValue

    public init?(_ value: VimValue) {
        self.value = value
    }

    public var startIndex: Int {
        return 0
    }

    public var endIndex: Int {
        return Int(swiftvim_list_size(value.reference))
    }

    public var isEmpty: Bool {
        return swiftvim_list_size(value.reference) == 0 
    }

    public var count: Int {
        return Int(swiftvim_list_size(value.reference))
    }

    public subscript(index: Int) -> VimValue {
        get {
            return VimValue(swiftvim_list_get(value.reference, Int32(index)))
        }
        set {
            swiftvim_list_set(value.reference, Int32(index), newValue.reference)
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
        return Int(swiftvim_asnum(value))
    }
}

