TARGET = foxdos

FILES = config.s \
		$(wildcard src/*.s) \
		$(wildcard src/int21/*.s)

.PHONY: all qemu clean
all: obj/mbr.o obj/kernel.o $(TARGET)

qemu: all
	qemu-system-i386 -fda $(TARGET)

obj/mbr.o: src/mbr.s
	@mkdir -p obj
	nasm -I. -Isrc src/mbr.s -o obj/mbr.o

obj/kernel.o: $(FILES)
	@mkdir -p obj
	nasm -I. -Isrc src/kernel.s -o obj/kernel.o

$(TARGET): src/mbr.s $(FILES)
	cat obj/mbr.o obj/kernel.o > $(TARGET)

clean:
	rm -rf obj/ $(TARGET) kernel.map
