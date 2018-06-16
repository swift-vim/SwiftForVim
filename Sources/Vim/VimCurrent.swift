import VimInterface

public class Current {
    private let value: UnsafeVimValue

    public lazy var buffer: VimBuffer = {
        return VimBuffer(value: self.value.attrp("buffer")!)
    }()

    public lazy var window: VimWindow = {
        return VimWindow(value: self.value.attrp("window")!)
    }()

    init() {
        let module = "vim".withCString { moduleCStr in
            return swiftvim_get_module(moduleCStr)
        }
        guard let value = module?.attrp("current") else {
            fatalError("missing current")
        }
        self.value = value
    }
}
