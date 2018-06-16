import XCTest
@testable import VimInterface

/// These tests make assertions about "vim.py"
class VimInterfaceTests: XCTestCase {
    static var allTests = [
        ("testEvalString", testEvalString),
        ("testEvalInt", testEvalInt),
        ("testCommandNone", testCommandNone),
        ("testPyEval", testPyEval),
    ]

    func testEvalString() {
        swiftvim_initialize()
        "VALUE".withCString { cStr in
            let result = swiftvim_eval(
              UnsafeMutablePointer(mutating: cStr))
            let str = swiftvim_asstring(result)

            let value = String(cString: str!)
            XCTAssertEqual(value, "VALUE")
        }
        swiftvim_finalize()
    }

    func testCommandNone() {
        swiftvim_initialize()
        "VALUE".withCString { cStr in
            // This command returns a None
            let result = swiftvim_command(
              UnsafeMutablePointer(mutating: cStr))
            // This should return a null
            let str = swiftvim_asstring(result)
            XCTAssertNil(str)
        }
        swiftvim_finalize()
    }

    // Low level testing
    func testEvalInt() {
        swiftvim_initialize()
        // eval_int is a function that returns an int
        "vim".withCString { moduleCStr in
            "eval_int".withCString { fCStr in
                "1".withCString { argCStr in
                    let result = swiftvim_call(
                        UnsafeMutablePointer(mutating: moduleCStr),
                        UnsafeMutablePointer(mutating: fCStr),
                        UnsafeMutablePointer(mutating: argCStr))
                    let value = swiftvim_asint(result)
                    XCTAssertEqual(value, 1)
                }
            }
        }
        swiftvim_finalize()
    }

    // Low level testing
    func testPyEval() {
        swiftvim_initialize()
        // Swap out the runtime
        let setEvalAsInt = """
        runtime.eval = lambda value : int(value)
        """
        "vim".withCString { moduleCStr in
            "py_exec".withCString { fCStr in
                setEvalAsInt.withCString { argCStr in
                    swiftvim_call(
                        UnsafeMutablePointer(mutating: moduleCStr),
                        UnsafeMutablePointer(mutating: fCStr),
                        UnsafeMutablePointer(mutating: argCStr))
                }
            }
        }

        // Verify that above eval was correct
        "vim".withCString { moduleCStr in
            "eval".withCString { fCStr in
                "1".withCString { argCStr in
                    let result = swiftvim_call(
                        UnsafeMutablePointer(mutating: moduleCStr),
                        UnsafeMutablePointer(mutating: fCStr),
                        UnsafeMutablePointer(mutating: argCStr))
                    let value = swiftvim_asint(result)
                    XCTAssertEqual(value, 1)
                }
            }
        }
        swiftvim_finalize()
    }
}
