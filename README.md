# SwiftForVim

Fast, typesafe, Vim plugins with the power of Swift!

SwiftForVim integrates the Swift Programming Language into Vim.

## Vim API

### Vim

Vimscript <-> Swift

Calling Vim commands from Swift
```swift
Vim.command("echo 'Hello World!'")
```

Evaluating Vim expressions from Swift
```swift
let path = String(Vim.eval("expand('%:p')"))
```

Call Swift functions from Vim

```swift
VimPlugin.setCallable("cursorMoved") {
    _ in
    print("The cursor moved")
}

// Off in VimScript
call s:SwiftVimEval("MyAwesomePlugin.invoke('cursorMoved')")
```

### VimAsync

Threading and Async support for Vim 

```swift
DispatchQueue.async {
    // Do some work
    VimTask.onMain {
        Vim.command("echo 'Hello World! on the main thread.'")
    }
}
```

_Note: VimAsync depends on Foundation. Its not needed for basic, single threaded plugins._

## Usage

First, generate a Vim Plugin setup to use Swift.
```bash
git clone https://github.com/swift-vim/SwiftForVim.git
cd SwiftForVim
plugin_path=/path/to/MyAwesomePlugin make generate
```

Then, build the plugin.
```bash
cd /path/to/MyAwesomePlugin
make
```

Last, setup the plugin ( VimPlug, Pathogen, etc ).

## Design Goals

Portable, fast, and simple to use.

It doesn't require recompiling Vim or a custom fork of the Swift language.

## Why?

Swift makes it easy to build fast, type safe programs, that are easy to debug
and deploy.

## Examples

The source tree contains a very basic example and test case.

[SwiftPackageManger.vim](https://github.com/swift-vim/SwiftPackageManager.vim) is the canonical use case and uses [VimAsync](#VimAsync) to run a custom RPC service inside of vim.

