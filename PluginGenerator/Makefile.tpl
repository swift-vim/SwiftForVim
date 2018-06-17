SHELL=bash

LAST_LOG=.build/last_build.log
PWD=$(shell pwd)

PLUGIN_NAME=__VIM_PLUGIN_NAME__

default: debug

.PHONY: release
release: CONFIG=release
release: SWIFT_OPTS= \
	-Xcc -I$(PYTHON_INCLUDE) \
	-Xcc -fvisibility=hidden \
	-Xcc -DVIM_PLUGIN_NAME=$(PLUGIN_NAME) \
	-Xlinker $(PYTHON_LINKED_LIB)
release: build_impl

.PHONY: debug
debug: CONFIG=debug
debug: SWIFT_OPTS= \
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
	@source VimUtils/make_lib.sh; python_info
	$(eval PYTHON_LINKED_LIB=$(shell source VimUtils/make_lib.sh; linked_python))
	$(eval PYTHON_INCLUDE=$(shell source VimUtils/make_lib.sh; python_inc_dir))


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
	@clang -g \
		-Xlinker $(PYTHON_LINKED_LIB) \
		-Xlinker $(PWD)/.build/$(CONFIG)/lib$(PLUGIN_NAME).dylib \
		-shared -o .build/$(PLUGIN_NAME).so

.PHONY: test
test_b: CONFIG=debug
test_b: SWIFT_OPTS= \
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

