TARGET = foxdos

FILES = config.s \
		src/int21.s \
		src/kernel.s

.PHONY: all qemu clean
all: obj/boot.o obj/kernel.o $(TARGET)

qemu: all
	qemu-system-i386 -fda $(TARGET)

obj/boot.o: src/boot.s
	@mkdir -p obj
	nasm -I. -Isrc src/boot.s -o obj/boot.o

obj/kernel.o: $(FILES)
	@mkdir -p obj
	nasm -I. -Isrc src/kernel.s -o obj/kernel.o

$(TARGET): src/boot.s $(FILES)
	cat obj/boot.o obj/kernel.o > $(TARGET)

clean:
	rm -rf obj/ $(TARGET)
