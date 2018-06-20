SHELL=bash

LAST_LOG=.build/last_build.log
PWD=$(shell pwd)

PLUGIN_NAME=__VIM_PLUGIN_NAME__
TRIPPLE=x86_64-apple-macosx10.12
BUILD_DIR=.build/$(CONFIG)

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
	ditto $(BUILD_DIR)/VimAsync.swiftmodule \
		$(BUILD_DIR)/$(PLUGIN_NAME)VimAsync.swiftmodule
	ditto $(BUILD_DIR)/VimAsync.swiftdoc \
		$(BUILD_DIR)/$(PLUGIN_NAME)VimAsync.swiftdoc
	@ditto $(BUILD_DIR)/libVimAsync.a \
		$(BUILD_DIR)/lib$(PLUGIN_NAME)VimAsync.a

# Main plugin lib
.PHONY: plugin_lib
plugin_lib: SWIFT_OPTS=--product $(PLUGIN_NAME) \
		$(BASE_OPTS) \
	  	-Xlinker $(BUILD_DIR)/libVim.a
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
	@mkdir -p .build
	@echo "Building.."
	swift build -c $(CONFIG) \
	   	$(BASE_OPTS) $(SWIFT_OPTS) $(EXTRA_OPTS) \
	  	-Xswiftc -target -Xswiftc $(TRIPPLE) \
	   	| tee $(LAST_LOG)
