CC = gcc
CXX = g++ # Potrzebne do linkowania C++
CFLAGS = -O3 -march=native -fPIC -Wall -Wextra -I./llama.cpp/include -I./llama.cpp/ggml/include
ODIN = odin
ODINFLAGS = -o:speed -out:lumi

# Ścieżki do bibliotek, które znalazłeś
LLAMA_LIBS = ./llama.cpp/build/src/libllama.a \
             ./llama.cpp/build/ggml/src/libggml.a \
             ./llama.cpp/build/ggml/src/libggml-base.a \
             ./llama.cpp/build/ggml/src/libggml-cpu.a

# Systemowe biblioteki wymagane przez llama.cpp (wątki, dynamiczne linkowanie, matematyka, C++)
SYS_LIBS = -lpthread -ldl -lm -lstdc++ -lgomp

all: lumi

build/liblumi_c.a: c/arena.c c/math.c c/llm_wrapper.c c/arena.h c/math.h c/llm_wrapper.h
	@mkdir -p build
	$(CC) $(CFLAGS) -c c/arena.c -o build/arena.o
	$(CC) $(CFLAGS) -c c/math.c -o build/math.o
	$(CC) $(CFLAGS) -c c/llm_wrapper.c -o build/llm_wrapper.o
	ar rcs $@ build/arena.o build/math.o build/llm_wrapper.o

lumi: build/liblumi_c.a src/main.odin src/tensor.odin src/brain.odin
	$(ODIN) build src $(ODINFLAGS) -extra-linker-flags:"$(LLAMA_LIBS) $(SYS_LIBS)"

clean:
	rm -rf build lumi
