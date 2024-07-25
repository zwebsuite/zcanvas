build:
	zig build
#	zig cc -Wall -std=c99 ./src/*.c -lSDL2 -o game

run:
	./zig-out/bin/zig-html-canvas
