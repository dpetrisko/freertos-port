TOP ?= $(shell git rev-parse --show-toplevel)

INSTALLDIR := install
WORKDIR := work
COMMIT := .git_commit_hash

all: bins
checkout: $(COMMIT)
bins: $(SPIKEBIN) $(DROMAJOBIN)
$(COMMIT):
	echo "Initializing submodules"
	git submodule update --jobs 8 --init .
	echo "Recursively initializing submodules"
	git submodule update --jobs 8 --init --recursive .
	git rev-parse HEAD > $@
bleach:
	git submodule deinit -f .
	git clean -ffdx .

SPIKESRC := riscv-isa-sim
SPIKEWORK := $(addprefix $(WORKDIR)/,$(SPIKESRC))
SPIKEBIN := $(INSTALLDIR)/bin/spike

SPIKEFLAGS :=
SPIKEFLAGS += --prefix=$(abspath $(INSTALLDIR))
SPIKEFLAGS += --without-boost --without-boost-asio --without-boost-regex

$(SPIKEWORK)/Makefile: $(COMMIT)
	mkdir -p $(@D)
	cd $(@D); $(abspath $(SPIKESRC))/configure $(SPIKEFLAGS)

$(SPIKEBIN): $(SPIKEWORK)/Makefile
	$(MAKE) -C $(<D) install

DROMAJOSRC := dromajo
DROMAJOWORK := $(addprefix $(WORKDIR)/,$(DROMAJOSRC))
DROMAJOBIN := $(INSTALLDIR)/bin/dromajo

DROMAJOFLAGS :=
DROMAJOFLAGS += -DCMAKE_INSTALL_PREFIX=$(abspath $(INSTALLDIR))
DROMAJOFLAGS += -DCMAKE_BUILD_TYPE=Release

$(DROMAJOWORK)/Makefile: $(COMMIT)
	mkdir -p $(@D)
	cmake -B $(@D) -S $(abspath $(DROMAJOSRC)) $(DROMAJOFLAGS)

$(DROMAJOBIN): $(DROMAJOWORK)/Makefile
	mkdir -p $(@D)
	$(MAKE) -C $(<D)
	cp $(<D)/$(@F) $@

