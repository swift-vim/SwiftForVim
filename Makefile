SHELL=bash

LAST_LOG=.build/last_build.log
PWD=$(shell pwd)

PLUGIN_NAME=Example
TRIPPLE=x86_64-apple-macosx10.12
BUILD_DIR=$(PWD)/.build/$(CONFIG)

# Generate a plugin setup to work with Vim
.PHONY: generate
generate: 
	@./PluginGenerator/plugin_generator.sh

.PHONY: debug
debug: CONFIG=debug
debug: plugin_so

.PHONY: release
release: CONFIG=debug
release: vim_lib plugin_so

BASE_OPTS=-Xcc -I$(PYTHON_INCLUDE) \
	-Xcc -DVIM_PLUGIN_NAME=$(PLUGIN_NAME) \
	-Xlinker $(PYTHON_LINKED_LIB) \
	-Xcc -fvisibility=hidden \
	-Xlinker -undefined -Xlinker dynamic_lookup \
	-Xlinker -all_load


# Build namespaced versions of Vim and VimAsync libs.
# The modules have a prefix of the plugin name, to avoid conflicts
# when the code is linked into the Vim process.
# The module is imported as "import $(PLUGIN_NAME)Vim"
# FIXME: Consider other ways to do this that work transitively and
# doesn't trigger rebuilds


.PHONY: vim_lib, renamed_vim_lib
vim_lib: SWIFT_OPTS=--product Vim  \
	-Xswiftc -module-name=$(PLUGIN_NAME)Vim \
	-Xswiftc -module-link-name=$(PLUGIN_NAME)Vim \
	$(BASE_OPTS) 
renamed_vim_lib: vim_lib
	@ditto $(BUILD_DIR)/Vim.swiftmodule \
		$(BUILD_DIR)/$(PLUGIN_NAME)Vim.swiftmodule
	@ditto $(BUILD_DIR)/Vim.swiftdoc \
		$(BUILD_DIR)/$(PLUGIN_NAME)Vim.swiftdoc
	@ditto $(BUILD_DIR)/libVim.a \
		$(BUILD_DIR)/lib$(PLUGIN_NAME)Vim.a

.PHONY: vim_async_lib, renamed_vim_lib_async
vim_async_lib: SWIFT_OPTS=--product VimAsync  \
	-Xswiftc -module-name=$(PLUGIN_NAME)VimAsync \
	-Xswiftc -module-link-name=$(PLUGIN_NAME)VimAsync \
	$(BASE_OPTS) 
renamed_vim_async_lib: vim_async_lib
	@ditto $(BUILD_DIR)/VimAsync.swiftmodule \
		$(BUILD_DIR)/$(PLUGIN_NAME)VimAsync.swiftmodule
	@ditto $(BUILD_DIR)/VimAsync.swiftdoc \
		$(BUILD_DIR)/$(PLUGIN_NAME)VimAsync.swiftdoc
	@ditto $(BUILD_DIR)/libVimAsync.a \
		$(BUILD_DIR)/lib$(PLUGIN_NAME)libVimAsync.a

# Main plugin lib
.PHONY: plugin_lib
plugin_lib: SWIFT_OPTS=--product $(PLUGIN_NAME) \
		$(BASE_OPTS) 
plugin_lib: renamed_vim_lib 
# To useadd VimAsync, add it following `renamed_vim_lib`

# Build the .so, which Vim dynamically links.
.PHONY: plugin_so
plugin_so: plugin_lib 
	@clang -g \
		-Xlinker $(PYTHON_LINKED_LIB) \
		-Xlinker $(BUILD_DIR)/lib$(PLUGIN_NAME).dylib \
		-shared -o .build/$(PLUGIN_NAME).so

# Build for the python dylib vim links
.PHONY: py_vars
py_vars:
	@source VimUtils/make_lib.sh; python_info
	$(eval PYTHON_LINKED_LIB=$(shell source VimUtils/make_lib.sh; linked_python))
	$(eval PYTHON_INCLUDE=$(shell source VimUtils/make_lib.sh; python_inc_dir))

# SPM Build
vim_lib vim_async_lib plugin_lib test_b: py_vars
	@echo "Building.."
	@mkdir -p .build
	@swift build -c $(CONFIG) \
	   	$(BASE_OPTS) $(SWIFT_OPTS) $(EXTRA_OPTS) \
	  	-Xswiftc -target -Xswiftc $(TRIPPLE) \
	  	-Xlinker $(BUILD_DIR)/libVim.a \
	   	| tee $(LAST_LOG)

# Mark - Internal Utils:

# Overriding Python:
# USE_PYTHON=/usr/local/Cellar/python/3.6.4_4/Frameworks/Python.framework/Versions/3.6/Python make test 
.PHONY: test
test: CONFIG=debug
test: EXTRA_OPTS= \
       -Xcc -DSPMVIM_LOADSTUB_RUNTIME
test: debug
	@echo "Testing.."
	@mkdir -p .build
	@swift build --product VimPackageTests \
	   	$(BASE_OPTS) $(SWIFT_OPTS) $(EXTRA_OPTS) \
		-Xlinker $(BUILD_DIR)/lib$(PLUGIN_NAME).dylib \
	  	-Xswiftc -target -Xswiftc $(TRIPPLE)
	@swift test --skip-build | tee $(LAST_LOG)


.PHONY: test_generate
test_generate:
	# We use the HEAD ref in the test
	git diff --quiet || (echo 'Dirty tree' && exit 1)
	rm -rf ~/Desktop/Swiftvimexample || true
	plugin_path=~/Desktop/Swiftvimexample make generate
	cd ~/Desktop/Swiftvimexample && make

clean:
	rm -rf .build/debug/*
	rm -rf .build/release/*

# Generate the example
PluginGenerator/PluginMain.tpl.swift: Sources/Example/Example.swift
	sed "s,Example,__VIM_PLUGIN_NAME__,g" $< > $@

# Build compile_commands.json
# Unfortunately, we need to clean.
# Use the last installed product incase we messed something up during
# coding.
compile_commands.json: SWIFT_OPTS=-Xswiftc -parseable-output \
	-Xcc -I$(PYTHON_INCLUDE) \
	-Xlinker $(PYTHON_LINKED_LIB) 
compile_commands.json: CONFIG=debug
compile_commands.json: clean build_impl
	cat $(LAST_LOG) | /usr/local/bin/spm-vim compile_commands

