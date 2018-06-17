# SwiftForVim

Fast, typesafe, Vim plugins with the power of Swift!

SwiftForVim integrates the Swift Programming Language into Vim.

## Usage

First, generate a Vim Plugin setup to use Swift.
```
git clone https://github.com/swift-vim/SwiftForVim.git
cd SwiftForVim
plugin_path=/path/to/MyAwesomePlugin make generate
```

Then, build the plugin
```
cd /path/to/MyAwesomePlugin
make
```

Last, setup the plugin like any other vim plugin ( i.e. with Pathogen ).

## Vim API

SwiftForVim is made up of 3 small modules.

### Vim

Vimscript <-> Swift

Calling Vim commands
```
Vim.command("echo 'Hello World!'")
```

Evaluating Vim expressions
```
let path = String(Vim.eval("expand('%:p')"))
```

### VimKit

Implement plugins and handle callbacks from Vim

```
class ExamplePlugin: VimPlugin {
    func event(event id: Int, context: String) -> String? {
        print("Autocmd")
        return nil 
    }
}

// Off in VimScript
autocmd CursorMoved * call s:SwiftVimEval("example.event(0, 'Moved')")
```

### VimAsync

Threading and Async support for Vim 

```
DispatchQueue.async {
    // Do some work
    VimTask.onMain {
        Vim.command("echo 'Hello World! on the main thread.'")
    }
}
```

_Note: this is macOS only right now. Its not needed for basic, single threaded plugins._

## Design Goals

Portable, fast, and simple to use.

It doesn't require recompiling Vim or a custom fork of the Swift language.

## Why?

Swift makes it easy to build fast, type safe programs, that are easy to debug
and deploy.

## Examples

The source tree contains a very basic example and test case.

[SwiftPackageManger.vim](https://github.com/swift-vim/SwiftPackageManager.vim) is the canonical use case and uses [VimAsync](#VimAsync) to run a custom RPC service inside of vim.


## Contributing

Contributions welcome :)

