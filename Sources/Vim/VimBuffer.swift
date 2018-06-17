import VimInterface

public class VimBuffer {
    private let value: VimValue

    init(_ value: VimValue) {
        self.value = value
    }

    public lazy var number: Int = {
        return self.value.reference.attr("number")
    }()

    public lazy var name: String = {
        return self.value.reference.attr("name")
    }()

    public func asList() -> VimList {
        return VimList(self.value)
    }
}
