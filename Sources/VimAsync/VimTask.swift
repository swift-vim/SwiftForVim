import Foundation

private var rlLock = os_unfair_lock_s()

fileprivate final class VimRunLoop {
    private let source: CFRunLoopSource 
    private let runLoopRef: CFRunLoop
    private let runLoop: RunLoop

    private init() { 
        let runLoop = RunLoop.current
        let runLoopRef =  RunLoop.current.getCFRunLoop()
        var ctx = CFRunLoopSourceContext()
        let source = CFRunLoopSourceCreate(nil, 0, UnsafeMutablePointer(&ctx))!
        CFRunLoopAddSource(runLoopRef, source, CFRunLoopMode.commonModes)
        self.runLoopRef = runLoopRef
        self.runLoop = runLoop
        self.source = source
        CFRunLoopSourceSignal(source);
        CFRunLoopWakeUp(runLoopRef);
    }

    public func runOnce() {
        os_unfair_lock_lock(&rlLock)
        CFRunLoopSourceSignal(source);
        CFRunLoopWakeUp(runLoopRef);
        CFRunLoopRunInMode(CFRunLoopMode.defaultMode, 0, true)
        os_unfair_lock_unlock(&rlLock)
    }

    /// Schedule the block to run
    public func perform(_ bl: @escaping (() -> Void)) {
        os_unfair_lock_lock(&rlLock)
        runLoop.perform(bl)
        CFRunLoopRunInMode(CFRunLoopMode.defaultMode, 0, true)
        os_unfair_lock_unlock(&rlLock)
    }

    public static var main: VimRunLoop = {
        var rl: VimRunLoop!
        os_unfair_lock_lock(&rlLock)
        rl = VimRunLoop()
        os_unfair_lock_unlock(&rlLock)
        return rl
    }()
}

/// Create tasks for new threads or use existing ones
/// The program should be as synchronous as possible
public final class VimTask<T> : NSObject {
    public typealias VimTaskBlock = () -> T

    public init(main: Bool? = false, bl: @escaping VimTaskBlock) {
        self.bl = bl
        self.main = main ?? false
        super.init()
    }

    /// Schedule on Vim's main thread in a thread safe way.
    /// Vim is a "single threaded", thread unsafe program, so any code that touches
    /// vim must run on the main thread.
    /// 
    /// This includes any function calls and associated data.
    /// Beware, that not adhereing to this will case several issues and thread
    /// safety is generally not validated.
    public static func onMain(_ bl: @escaping VimTaskBlock) {
        if Thread.current == Thread.main {
            _ = bl()
            return
        }
        VimTask(main: true, bl: bl).run()
    }

    public var isDone: Bool {
        var x = false
        mutQueue.sync {
            x = self.done
        }
        return x
    }

    public func run() {
        if main {
            VimRunLoop.main.perform {
                () -> Void in
                self.start(sender: nil)
            }
        } else {
            Thread.detachNewThreadSelector(#selector(start), toTarget:self, with: nil)
        }
    }

    private let bl: VimTaskBlock
    private let main: Bool
    private let mutQueue = DispatchQueue(label: "com.bs.threadMut")
    private var done = false
    private var running = false

    @objc
    private func start(sender: Any?) {
        mutQueue.sync {
            self.running = true
        }
        let _ = bl()
        mutQueue.sync {
            self.done = true
            self.running = false
        }
    }

}

/// Callback for the main run loop
public func VimTaskRunLoopCallback() {
    VimRunLoop.main.runOnce()
}

/// Check in code if thread is on the main
public func VimTaskMainThreadGuard() {
    guard Thread.current == Thread.main else {
        fatalError("error: main thread check failed")
    }
}


