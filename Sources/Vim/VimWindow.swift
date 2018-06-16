import VimInterface

public class VimWindow {
    private let value: UnsafeVimValue

    init(value: UnsafeVimValue) {
        self.value = value
    }

    public var cursor: (Int, Int) {
        guard let cursor = self.value.attrp("cursor") else {
            return (0, 0)
        }
        let first = swiftvim_tuple_get(cursor, 0)
        let second = swiftvim_tuple_get(cursor, 1)
        return (Int(swiftvim_asint(first)), Int(swiftvim_asint(second)))
    }

    public var height: Int {
        return value.attr("height")
    }

    public var col: Int {
        return value.attr("col")
    }

    public var row: Int {
        return value.attr("row")
    }

    public var valid: Bool {
        return value.attr("valid") != 0
    }

    public var buffer: VimBuffer {
        return VimBuffer(value: value.attrp("buffer")!)
    }
}

