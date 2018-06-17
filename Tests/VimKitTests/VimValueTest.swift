import XCTest
import VimKit
import VimInterface
import Vim

@testable import VimKit

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
        let result = Vim.eval("VALUE")!
        XCTAssertEqual(result.asString(), "VALUE")
        swiftvim_finalize()
    }

    func testCommandNone() {
        swiftvim_initialize()
        let result = Vim.command("VALUE")!
        XCTAssertNil(result.asString())
        swiftvim_finalize()
    }

    func testEvalInt() {
        swiftvim_initialize()
        mutateRuntime("eval", lambda: "lambda value : int(value)")
        let result = Vim.eval("2")!
        XCTAssertEqual(result.asInt(), 2)
        swiftvim_finalize()
    }

    func testEvalList() {
        swiftvim_initialize()
        mutateRuntime("eval", lambda: "lambda value : [1, 2]")
        let result = Vim.eval("")!
        let list = result.asList()!
        XCTAssertEqual(list.count, 2)
        XCTAssertEqual(list[0].asInt(), 1)
        XCTAssertEqual(list[1].asInt(), 2)
        list[1] = list[0]
        XCTAssertEqual(list[1].asInt(), 1)
        swiftvim_finalize()
    }

    func testListCollectionUsage() {
        swiftvim_initialize()
        mutateRuntime("eval", lambda: "lambda value : [1, 2]")
        let result = Vim.eval("")!
        let list = result.asList()!
        /// Smoke test we can do collectiony things.
        let incremented = list.map { $0.asInt()! + 1 }
        XCTAssertEqual(incremented[1], 3)
        swiftvim_finalize()
    }

    func testEvalDict() {
        swiftvim_initialize()
        mutateRuntime("eval", lambda: "lambda value : dict(a=42, b='a')")
        let result = Vim.eval("")!
        let dict = result.asDictionary()!
        let aVal = dict["a"]!
        XCTAssertEqual(aVal.asInt()!, 42)
        let nonVal = dict["s"]
        XCTAssertNil(nonVal?.asInt())

        swiftvim_finalize()
    }

    func testDictCollectionUsage() {
        swiftvim_initialize()
        mutateRuntime("eval", lambda: "lambda value : dict(a=42, b='a')")
        let result = Vim.eval("")!
        let dict = result.asDictionary()!
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
}

