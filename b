NAME=foxdos

rm $NAME

mkdir -p obj

# TODO this only works in root directory. might be good to just use a proper build system
nasm -I. -Isrc src/boot.s -o obj/boot
nasm -I. -Isrc src/kernel.s -o obj/kernel

cat obj/boot obj/kernel > $NAME
