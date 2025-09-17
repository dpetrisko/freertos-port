
checkout:
	echo "Initializing submodules"
	git submodule update --jobs 8 --init .
	echo "Recursively initializing submodules"
	git submodule update --jobs 8 --init --recursive .

bleach:
	git submodule deinit -f .
	git clean -ffdx .

