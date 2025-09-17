TOP ?= $(shell git rev-parse --show-toplevel)

INSTALLDIR := install
WORKDIR := work
PATCHDIR := patches
COMMIT := $(INSTALLDIR)/.git_commit_hash

SPIKESRC := riscv-isa-sim
SPIKEWORK := $(addprefix $(WORKDIR)/,$(SPIKESRC))
SPIKEPATCH := $(wildcard $(addprefix $(PATCHDIR)/,$(SPIKESRC))/*.patch)
SPIKEBIN := $(INSTALLDIR)/bin/spike

SPIKEFLAGS :=
SPIKEFLAGS += --prefix=$(abspath $(INSTALLDIR))
SPIKEFLAGS += --without-boost --without-boost-asio --without-boost-regex

PATCHFLAGS :=
PATCHFLAGS += --verbose
PATCHFLAGS += --ignore-space-change --ignore-whitespace

all: $(SPIKEBIN) $(DROMAJOBIN)

$(SPIKEWORK)/patch: $(COMMIT)
	mkdir -p $(@D)
	git apply --directory=$(SPIKESRC) $(PATCHFLAGS) $(SPIKEPATCH)
	touch $@

$(SPIKEWORK)/Makefile: $(SPIKEWORK)/patch
	cd $(@D); $(abspath $(SPIKESRC))/configure $(SPIKEFLAGS)

$(SPIKEBIN): $(SPIKEWORK)/Makefile
	$(MAKE) -C $(<D) install

DROMAJOSRC := dromajo
DROMAJOWORK := $(addprefix $(WORKDIR)/,$(DROMAJOSRC))
DROMAJOPATCH := $(wildcard $(addprefix $(PATCHDIR)/,$(DROMAJOSRC))/*.patch)
DROMAJOBIN := $(INSTALLDIR)/bin/dromajo

DROMAJOFLAGS :=
DROMAJOFLAGS += -DCMAKE_INSTALL_PREFIX=$(abspath $(INSTALLDIR))
DROMAJOFLAGS += -DCMAKE_BUILD_TYPE=Release

$(DROMAJOWORK)/patch: $(COMMIT)
	mkdir -p $(@D)
	git apply --directory=$(DROMAJOSRC) $(PATCHFLAGS) $(DROMAJOPATCH)
	touch $@

$(DROMAJOWORK)/Makefile: $(DROMAJOWORK)/patch
	cmake -B $(@D) -S $(abspath $(DROMAJOSRC)) $(DROMAJOFLAGS)

$(DROMAJOBIN): $(DROMAJOWORK)/Makefile
	$(MAKE) -C $(<D)
	@# Install target doesn't work correctly
	@mkdir -p $(@D) && cp $(<D)/$(@F) $@

checkout: $(COMMIT)
$(COMMIT):
	mkdir -p $(INSTALLDIR) $(WORKDIR)
	echo "Initializing submodules"
	git submodule update --jobs 8 --init .
	echo "Recursively initializing submodules"
	git submodule update --jobs 8 --init --recursive .
	git rev-parse HEAD > $@
bleach:
	git submodule deinit -f .
	git clean -ffdx .

