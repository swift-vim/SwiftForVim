import XCTest
import VimInterface
import ExampleVim

/// Here we mutate the runtime to do things we want
/// Note, that this relies on the fact it uses python internally
/// to make testing easier.
func mutateRuntime(_ f: String, lambda: String) {
      let evalStr = "runtime.\(f) = \(lambda)"
      _ = "vim".withCString { moduleCStr in
          "py_exec".withCString { fCStr in
              evalStr.withCString { argCStr in
                  swiftvim_call(
                      UnsafeMutablePointer(mutating: moduleCStr),
                      UnsafeMutablePointer(mutating: fCStr),
                      UnsafeMutablePointer(mutating: argCStr))
              }
          }
      }
}

class VimValueTests: XCTestCase {
    static var allTests = [
        ("testEvalString", testEvalString),
        ("testEvalInt", testEvalInt),
        ("testEvalList", testEvalList),
        ("testEvalDict", testEvalDict),
        ("testCommandNone", testCommandNone),
        ("testListCollectionUsage", testListCollectionUsage),
        ("testDictCollectionUsage", testDictCollectionUsage),
        ("testBufferAttrs", testBufferAttrs),
    ]

    func testEvalString() {
        swiftvim_initialize()
        let result = try! Vim.eval("VALUE")
        XCTAssertEqual(String(result), "VALUE")
        swiftvim_finalize()
    }

    func testCommandNone() {
        swiftvim_initialize()
        let result = try! Vim.command("VALUE")
        XCTAssertNil(String(result))
        swiftvim_finalize()
    }

    func testEvalInt() {
        swiftvim_initialize()
        mutateRuntime("eval", lambda: "lambda value : int(value)")
        let result = try! Vim.eval("2")
        XCTAssertEqual(Int(result), 2)
        swiftvim_finalize()
    }

    func testEvalList() {
        swiftvim_initialize()
        mutateRuntime("eval", lambda: "lambda value : [1, 2]")
        let result = try! Vim.eval("")
        let list = VimList(result)!
        XCTAssertEqual(list.count, 2)
        XCTAssertEqual(Int(list[0]), 1)
        XCTAssertEqual(Int(list[1]), 2)
        list[1] = list[0]
        XCTAssertEqual(Int(list[1]), 1)
        swiftvim_finalize()
    }

    func testListCollectionUsage() {
        swiftvim_initialize()
        mutateRuntime("eval", lambda: "lambda value : [1, 2]")
        let result = try! Vim.eval("")
        let list = VimList(result)!
        /// Smoke test we can do collectiony things.
        let incremented = list.map { Int($0)! + 1 }
        XCTAssertEqual(incremented[1], 3)
        swiftvim_finalize()
    }

    func testEvalDict() {
        swiftvim_initialize()
        mutateRuntime("eval", lambda: "lambda value : dict(a=42, b='a')")
        let result = try! Vim.eval("")
        let dict = VimDictionary(result)!
        let aVal = dict["a"]!
        XCTAssertEqual(Int(aVal)!, 42)
        let nonVal = dict["s"]
        XCTAssertNil(Int(nonVal))

        swiftvim_finalize()
    }

    func testDictCollectionUsage() {
        swiftvim_initialize()
        mutateRuntime("eval", lambda: "lambda value : dict(a=42, b='a')")
        let result = try! Vim.eval("")
        let dict = VimDictionary(result)!
        XCTAssertEqual(dict.keys.count, 2)
        XCTAssertEqual(dict.values.count, 2)
        swiftvim_finalize()
    }

    func testBufferAttrs() {
        swiftvim_initialize()
        let buffer = Vim.current.buffer
        XCTAssertEqual(buffer.number, 1)
        XCTAssertEqual(buffer.name, "mock")
        swiftvim_finalize()
    }

    func testWindowAttrs() {
        swiftvim_initialize()
        let window = Vim.current.window
        XCTAssertEqual(window.cursor.0, 1)
        XCTAssertEqual(window.cursor.1, 2)
        swiftvim_finalize()
    }

    func testCallback() {
        var called = false
        var calledArgs: [VimValue]?
        let callback: (([VimValue]) -> VimScriptConvertible?) = { 
            args in
            called = true
            calledArgs = args
            print("test-info: DidCallback", args)
            return nil
        }

        swiftvim_initialize()
        let erasedFunc = callback as AnyObject
        let address = unsafeBitCast(erasedFunc, to: Int.self)
        VimPlugin.setCallable(String(address), callable: callback)
        let cb = "Example.invoke('\(address)', 'arga')"
        print("test-info: Callback:", cb)
        mutateRuntime("eval", lambda: "lambda value : \(cb)")
        _ = try? Vim.eval("")
        print("test-info: Callback Args:", calledArgs ?? "")
        XCTAssertTrue(called)
        XCTAssertEqual(calledArgs?.count, 1)
        XCTAssertEqual(String(calledArgs?.first), "arga") 
        swiftvim_finalize()
    }
}

