SHELL=bash

LAST_LOG=.build/last_build.log
PWD=$(shell pwd)

PLUGIN_NAME=example

# Generate a plugin setup to work with VimKit
.PHONY: generate
generate: 
	@./PluginGenerator/plugin_generator.sh

default: debug

.PHONY: release
release: CONFIG=release
release: SWIFT_OPTS=--product VimKit  \
	-Xcc -I$(PYTHON_INCLUDE) \
	-Xcc -fvisibility=hidden \
	-Xcc -DVIM_PLUGIN_NAME=$(PLUGIN_NAME) \
	-Xlinker $(PYTHON_LINKED_LIB)
release: build_impl

.PHONY: debug
debug: CONFIG=debug
debug: SWIFT_OPTS=--product VimKit  \
	-Xcc -I$(PYTHON_INCLUDE) \
	-Xcc -fvisibility=hidden \
	-Xcc -DVIM_PLUGIN_NAME=$(PLUGIN_NAME) \
	-Xlinker $(PYTHON_LINKED_LIB)
debug: build_impl

# Dynamically find python vars
# Note, that this is OSX specific
# We will pass this directly to the linker command line
# Whatever dylib was used i.e. Py.framework/SOMEPYTHON
.PHONY: py_vars
py_vars:
	@source Utils/make_lib.sh; python_info
	$(eval PYTHON_LINKED_LIB=$(shell source Utils/make_lib.sh; linked_python))
	$(eval PYTHON_INCLUDE=$(shell source Utils/make_lib.sh; python_inc_dir))


# SPM Build
.PHONY: build_impl
# Careful: assume we need to depend on this here
build_impl: py_vars
build_impl:
	@echo "Building.."
	@mkdir -p .build/$(CONFIG)
	@swift build -c $(CONFIG) $(SWIFT_OPTS) \
	  	-Xswiftc "-target"  -Xswiftc "x86_64-apple-macosx10.12" \
	   	| tee $(LAST_LOG)

# Running tests with custom versions of Python
# USE_PYTHON=/usr/local/Cellar/python/3.6.4_4/Frameworks/Python.framework/Versions/3.6/Python make test 
.PHONY: test
test_b: CONFIG=debug
test_b: SWIFT_OPTS= \
	-Xcc -DSPMVIM_LOADSTUB_RUNTIME \
	-Xcc -I$(PYTHON_INCLUDE) \
	-Xcc -DVIM_PLUGIN_NAME=$(PLUGIN_NAME) \
	-Xlinker $(PYTHON_LINKED_LIB) \
	--build-tests
test_b: build_impl
test: CONFIG=debug
test: py_vars test_b
	@echo "Testing.."
	@mkdir -p .build/$(CONFIG)
	@swift test --skip-build -c $(CONFIG) $(SWIFT_OPTS) | tee $(LAST_LOG)

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

