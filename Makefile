config ?= release
arch ?= native
version ?= $(shell cat VERSION)
flags ?= -j2

srcDir := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
buildDir := $(srcDir)/build/build_$(config)
outDir := $(srcDir)/build/$(config)

libsSrcDir := $(srcDir)/lib
libsBuildDir := $(srcDir)/build/build_libs
libsOutDir := $(srcDir)/build/libs

SILENT =

.DEFAULT_GOAL := build
.PHONY: all libs cleanlibs configure build test test-ci test-check-version test-core test-stdlib-debug test-stdlib-release test-examples test-validate-grammar clean

libs:
	$(SILENT)mkdir -p $(libsBuildDir)
	$(SILENT)cd $(libsBuildDir) && cmake -B $(libsBuildDir) -S $(libsSrcDir) -DCMAKE_INSTALL_PREFIX="$(libsOutDir)" -DCMAKE_BUILD_TYPE=Release
	$(SILENT)cd $(libsBuildDir) && cmake --build $(libsBuildDir) --target install --config Release -- $(flags)

cleanlibs:
	$(SILENT)rm -rf $(libsBuildDir)
	$(SILENT)rm -rf $(libsOutDir)

configure:
	$(SILENT)mkdir -p $(buildDir)
	$(SILENT)cd $(buildDir) && cmake -B $(buildDir) -S $(srcDir) -DCMAKE_BUILD_TYPE=$(config) -DCMAKE_C_FLAGS="-march=$(arch)" -DCMAKE_CXX_FLAGS="-march=$(arch)" -DPONYC_VERSION=$(version)

all: build

build:
	$(SILENT)cd $(buildDir) && cmake --build $(buildDir) --config $(config) --target all -- $(flags)

test: all test-core test-stdlib-release test-examples

test-ci: all test-check-version test-core test-stdlib-debug test-stdlib-release test-examples test-validate-grammar

test-check-version: all
	$(SILENT)cd $(outDir) && ./ponyc --version

test-core: all
	$(SILENT)cd $(outDir) && ./libponyrt.tests --gtest_shuffle
	$(SILENT)cd $(outDir) && ./libponyc.tests --gtest_shuffle

test-stdlib-release: all
	$(SILENT)cd $(outDir) && ./ponyc -b stdlib-release --pic --checktree --verify ../../packages/stdlib && ./stdlib-release && rm stdlib-release

test-stdlib-debug: all
	$(SILENT)cd $(outDir) && ./ponyc -d -b stdlib-debug --pic --strip --checktree --verify ../../packages/stdlib && ./stdlib-debug && rm stdlib-debug

test-examples: all
	$(SILENT)cd $(outDir) && PONYPATH=.:$(PONYPATH) find ../../examples/*/* -name '*.pony' -print | xargs -n 1 dirname | sort -u | grep -v ffi- | xargs -n 1 -I {} ./ponyc -d -s --checktree -o {} {}

test-validate-grammar: all
	$(SILENT)cd $(outDir) && ./ponyc --antlr >> pony.g.new && diff ../../pony.g pony.g.new && rm pony.g.new

clean:
	$(SILENT)([ -d $(buildDir) ] && cd $(buildDir) && cmake --build $(buildDir) --config $(config) --target clean) || true
	$(SILENT)rm -rf $(buildDir)
	$(SILENT)rm -rf $(outDir)

distclean:
	$(SILENT)([ -d build ] && rm -rf build) || true
