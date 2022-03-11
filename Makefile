# \ var
# detect module/project name by current directory
MODULE  = $(notdir $(CURDIR))
# detect OS name (only Linux/MinGW)
OS      = $(shell uname -s)
# host machine architecture (for cross-compiling)
MACHINE = $(shell uname -m)
# current date in the `ddmmyy` format
NOW     = $(shell date +%d%m%y)
# release hash: four hex digits (for snapshots)
REL     = $(shell git rev-parse --short=4 HEAD)
# current git branch
BRANCH  = $(shell git rev-parse --abbrev-ref HEAD)
# your own private working branch name
SHADOW ?= shadow
# number of CPU cores (for parallel builds)
CORES   = $(shell grep processor /proc/cpuinfo| wc -l)
# / var

# \ metainfo
AUTHOR  = Dmitry Ponyatov
EMAIL   = dponyatov@gmail.com
GITHUB  = https://github.com/ponyatov
# / metainfo

# \ dir
# current (project) directory
CWD     = $(CURDIR)
# compiled/executable files (target dir)
BIN     = $(CWD)/bin
# documentation & external manuals download
DOC     = $(CWD)/doc
# libraries / scripts
LIB     = $(CWD)/lib
# source code (not for all languages, Rust/C/Java included)
SRC     = $(CWD)/src
# temporary/flags/generated files
TMP     = $(CWD)/tmp
# Rust compiler installation path
CAR     = $(HOME)/.cargo/bin
# / dir

# \ tool
# http/ftp download
CURL    = curl -L -o
PY      = $(shell which python3)
PIP     = $(shell which pip3)
PEP     = $(shell which autopep8)
PYT     = $(shell which pytest)
RUSTUP  = $(CAR)/rustup
CARGO   = $(CAR)/cargo
RUSTC   = $(CAR)/rucstc
# / tool

# \ src
Y   += $(MODULE).metaL.py metaL.py
S   += $(Y)
F   += $(shell find lib -type f -regex ".+.f$$")
S   += $(F)
R   += $(shell find src -type f -regex ".+.rs$$")
S   += $(R) Cargo.toml
# / src

# \ all

.PHONY: all
all: $(R)
	$(CARGO) test && $(CARGO) fmt && $(CARGO) run $(F)

.PHONY: meta
meta: $(PY) $(MODULE).metaL.py
	$^
	$(MAKE) tmp/format_py

format: tmp/format_py
tmp/format_py: $(Y)
	$(PEP) --ignore=E26,E302,E305,E401,E402,E701,E702 --in-place $? && touch $@
# / all

# \ rule
$(SRC)/%/README: $(GZ)/%.tar.gz
	cd src ;  zcat $< | tar x && touch $@
$(SRC)/%/README: $(GZ)/%.tar.xz
	cd src ; xzcat $< | tar x && touch $@
# / rule

# \ doc

.PHONY: doxy
doxy:
	rm -rf docs ; doxygen doxy.gen 1>/dev/null
	rm -rf target/doc ; $(CARGO) doc --no-deps && cp -r target/doc docs/rust

.PHONY: doc
doc:
# / doc

# \ install
.PHONY: install update
install: $(OS)_install doc gz $(RUSTUP)
	$(MAKE) update
update: $(OS)_update
	$(PIP) install --user -U pip pytest autopep8
	$(MAKE) rust

.PHONY: Linux_install Linux_update
Linux_install Linux_update:
ifneq (,$(shell which apt))
	sudo apt update
	sudo apt install -u `cat apt.txt apt.dev`
endif

# \ gz
.PHONY: gz
gz:
# / gz

# \ rust
.PHONY: rust
rust: $(RUSTUP)
	$(RUSTUP) component add rust-analysis rust-src rls
	$(RUSTUP) update
	$(CARGO) update

$(RUSTUP):
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
# / rust
# / install

# \ merge
MERGE  = Makefile README.md .gitignore doxy.gen .clang-format $(S)
MERGE += apt.dev apt.txt
MERGE += .vscode bin doc lib src tmp

.PHONY: shadow
shadow:
	git push -v
	git checkout $(SHADOW)
	git pull -v

.PHONY: dev
dev:
	git push -v
	git checkout $@
	git pull -v
	git checkout $(SHADOW) -- $(MERGE)
	$(MAKE) doxy ; git add -f docs

.PHONY: release
release:
	git tag $(NOW)-$(REL)
	git push -v --tags
	$(MAKE) shadow

.PHONY: zip
ZIP = $(TMP)/$(MODULE)_$(BRANCH)_$(NOW)_$(REL).src.zip
zip:
	git archive --format zip --output $(ZIP) HEAD
	$(MAKE) doxy ; zip -r $(ZIP) docs
# / merge
