import XCTest
import VimInterface
import ExampleVim
import ExampleVimAsync
import Foundation

class VimAsyncTests: XCTestCase {
    static var allTests = [
        ("testCommandNone", testCommandNone)
    ]

    func testCommandNone() {
        swiftvim_initialize()
        var result: VimValue!
        let semaphore = DispatchSemaphore(value: 0)
        let serial = DispatchQueue(label: "Queuename")
        serial.async {
            VimTask.onMain {
                result = try! Vim.command("VALUE")
                semaphore.signal()
            }
        }

        let timeout = DispatchTime.now() + .seconds(120)
        guard semaphore.wait(timeout: timeout) != .timedOut else {
          fatalError("Fail.")
        }
        XCTAssertNotNil(result)
        XCTAssertNil(String(result))
        swiftvim_finalize()
    }
}
