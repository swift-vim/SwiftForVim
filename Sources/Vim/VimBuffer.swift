import VimInterface

public class VimBuffer {
    private let value: UnsafeVimValue

    init(value: UnsafeVimValue) {
        self.value = value
    }

    public lazy var number: Int = {
        return self.value.attr("number")
    }()

    public lazy var name: String = {
        return self.value.attr("name")
    }()

    public func asList() -> VimList {
        return VimList(value: self.value)
    }
}
