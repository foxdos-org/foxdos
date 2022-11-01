TARGET = foxdos

FILES = src/int21.s \
		src/kernel.s

.PHONY: all qemu clean
all: prepare boot kernel img

qemu: all
	qemu-system-i386 -fda $(TARGET)

prepare:
	mkdir -p obj

boot: src/boot.s
	nasm -I. -Isrc src/boot.s -o obj/boot.o

kernel: $(FILES)
	nasm -I. -Isrc src/kernel.s -o obj/kernel.o

img:
	cat obj/boot.o obj/kernel.o > $(TARGET)

clean:
	rm -rf obj/ $(TARGET)
