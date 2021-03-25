
all:
	docker build --tag=repro-cxxopts-msan-warning --network=host .
	docker run -it --rm repro-cxxopts-msan-warning -- build launch

build:
	clang++ \
		-g -O0 \
		-std=c++17 \
		-stdlib=libc++ \
		-Wall \
		-fsanitize=memory \
		-fsanitize-recover=all \
		-fno-omit-frame-pointer \
		-fno-optimize-sibling-calls \
		-fdiagnostics-color \
		-I src \
		src/main.cpp
		ls -al

launch:
	MSAN_OPTIONS="symbolize=1:halt_on_error=0" MSAN_SYMBOLIZER_PATH="$(shell which llvm-symbolizer)" ./a.out
