#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>

#include <fs.h> // structs for mothfs
#include <mfs_hdr.h> // bootcode

#define setbit(x, y) x[y >> 3] |= 1 << (y & 7)

typedef struct {
	char* name;
	int (*fn)(int, char**);
} multicall;

int pstrlen(char* d, char* typ) {
	int i = 0;
	while((d[i] ^ '/') && d[i] != 0) i++; // slash or null terminated
	*typ = d[i] ? 1 : 0;
	return i;
}

char** psplit(char* path, int* i) {
	int l, a = 8;
	char** rpth = malloc(sizeof(char*)*a);
	*i = 0;
	char x = 1, dir = 0;
	
	if(*path == '/') {
		rpth[(*i)++] = memcpy(malloc(2), "/", 2);
		path++;
	}

	if(path[strlen(path) - 1] == '/') dir = 1;

	while(x) {
		while(*path == '/') path++;
		if(!*path) break;
		l = pstrlen(path, &x);
		if(*path == '.' && l < 3) {
			// nop - will not handle case l == 0 or l == 1
			if(l == 2) {
				if(path[1] == '.') {
					printf("handling .. at i == %i\n", *i);
					if(*i != !!strcmp(rpth[0], "/")) {
						printf("..: free rpth[%i]\n", *i);
						free(memcpy(rpth[--(*i)], "\0", 1)); // will not overwrite first element if it is "/" or index oob
					} else if(strcmp(rpth[0], "/")) {
						int acc = 0;
						for(int z = 0; z < *i; z++) {
							acc += !!strcmp(rpth[z], "..");
							printf("check rpth[%i]:\t%s\n", z, rpth[z]);
						}
						printf("acc = %i\n", acc);
						if(!acc) {
							printf("INSERT ..\n");
							goto addent;
						}
					}
				} else goto addent;
			}
		} else { // insert string
		addent:	rpth[*i] = memcpy(malloc(l + 1), path, l);
			rpth[(*i)++][l] = 0;
		}
		path += l + x; // prevent buffer overrun
		if(*i >= a) rpth = realloc(rpth, sizeof(char*)*(a += 4));
	}

	printf("end psplit\n\n");

	if(dir) {
		if(*i + 1 >= a) rpth = realloc(rpth, sizeof(char*)*(a += 4));
		rpth[(*i)++] = memcpy(malloc(2), "/", 2);
	}
	
	// TODO free a-*i elements from end to avoid leak
	return rpth;
}

int xstrlen(char* s) {
	int i = strlen(s) - 1;
	for(;s[i] != '.' && i; i--);
	return i;
}

// s: passed path
// d: path in fs to check against
// TODO does this even work
int nmatch(char* s, char* d) {
	int x = xstrlen(s);
	for(int i = 0; i < (x > 8 ? 8 : x); i++) {
		if(
			(s[i] & ((s[i] >= 'a' && s[i] <= 'z') ? 0xDF: 0xFF)) != d[i]
		) return 0;
	}
	s = s + x + 1;
	x = strlen(s);
	for(int i = 0; i < (x > 3 ? 3 : x); i++) {
		if(
			(s[i] & ((s[i] >= 'a' && s[i] <= 'z') ? 0xDF: 0xFF)) != d[i]
		) return 0;
	}
	return 1;
}

// returns sector of file or directory
uint32_t mfs_traverse(int fd, uint32_t from, char* name) {
	uint64_t r = 0; // sector to return?
	mothfs_file d, next;
	int sz;
	char** rpth = psplit(name, &sz);
	uint32_t* ns = malloc(512);
	
	int i = 0;

	if(!strcmp(*rpth, "/")) {
		lseek(fd, 0, SEEK_SET);
		read(fd, &d, 512);
		mothfs_header* e = (mothfs_header*)&d; // reuse buffer
		from = e->reserved + e->abm + 1;
		i++;
	}

	for(; i < sz; i++) { // TODO . and ..
		lseek(fd, ((uint64_t)from) << 9, SEEK_SET);
		read(fd, &d, 512);
		uint32_t* sp = d.data + 121;
		switch(d.type) {
			case 0: // file
				r = strcmp(rpth[sz - 1], "/") ? from : 0; // fail if last element of path is a /
				if(sz - !strcmp(rpth[sz - 1], "/") - 1 != i) r = 0; // TODO does this work. fail if the current element is not the last one, excluding a possible "/"
				goto ret;
				break;
			case 1: // directory
				for(int c = 0; c < 121; c++) {
					if(!d.data[c]) {
						r = 0;
						goto ret;
					}
					lseek(fd, ((uint64_t)d.data[c]) << 9, SEEK_SET);
					read(fd, &next, 512);
					if(nmatch((char*)next.name, rpth[i])) {
						// TODO set r if last element
						if(i == sz - 1 - !strcmp(rpth[sz - 1], "/")) {
							r = d.data[c];
							goto ret;
						}
						from = d.data[c];
						break;
					}
				} // else check linked sector:
			cls:	lseek(fd, ((uint64_t)(*sp)) << 9, SEEK_SET);
				read(fd, ns, 512);
				for(int c = 0; c < 127; c++) {
					if(!ns[c]) {
						r = 0;
						goto ret;
					}
					lseek(fd, ((uint64_t)d.data[c]) << 9, SEEK_SET);
					read(fd, &next, 512);
					if(nmatch((char*)next.name, rpth[i])) {
						// TODO set r if last element
						if(i == sz - 1 - !strcmp(rpth[sz - 1], "/")) {
							r = d.data[c];
							goto ret;
						}
						from = d.data[c];
						break;
					}
				} // else go to next linked sector:
				sp = ns + 127;
				goto cls;
				break;
		}
	}

ret:	for(; i < sz; i++) free(rpth[i]);
	free(rpth);
	free(ns);
	return r;
}

#define LFIL argv[1]
#define SIZE argv[2]
#define SKIP argv[3]

int mfs_new(int argc, char** argv) {
	if(argc < 4) return !!printf("need arguments: [file] [size] [sector offset]\n");
	int fd;
	if((fd = open(LFIL, O_RDWR|O_CREAT, 0644)) < 0) return !!printf("could not open %s\n", LFIL);
	uint64_t sz = atol(SIZE);
	sz = (sz + ((sz & 0x1FF) ? 512 : 0)) >> 9; // round up to number of sectors
	uint64_t skip = atol(SKIP);
	ftruncate(fd, sz << 9);
	
	mothfs_header* header = (mothfs_header*)mfs_hdr;
	header->size = sz;
	header->offset = skip;
	header->reserved = 127;

	// currently uses 1/8 of the partition but that isnt too bad for now
	header->abm = (sz + ((sz & 7) ? 8 : 0)) >> 3;

	write(fd, header, 512); // write bootloader

	// start writing initial abm
	lseek(fd, 512*(header->reserved + 1), SEEK_SET);

	// volume name
	memcpy(header->volname, "mothfs\0????????", 15); // this will look really funny if parsed wrong
	
	// reserve the boot sector, bootcode area, and abm
	uint8_t* rsv = malloc(header->abm << 9);
	memset(rsv, 0, header->abm << 9);
	for(unsigned long i = 0; i < 1 + header->reserved + header->abm; i++) setbit(rsv, i);
	write(fd, rsv, header->abm << 9);
	free(rsv);

	mothfs_file root;
	memset(&root, 0, sizeof(mothfs_file));

	root.type = MFS_DIR;
	root.ext = 0;
	*root.data = 0; // no files yet - that is the user's job
	
	// set root to itself
	root.dir = ((uint64_t)lseek(fd, 0, SEEK_CUR)) >> 9;

	write(fd, &root, 512);
	return 0;
}

int mfs_insert(int argc, char** argv) {
	if(argc < 3) return !!printf("need arguments: [mothfs file] [file to insert]\n");
	return 1;
}

#define NUM_MULTICALL 2
multicall mc[NUM_MULTICALL] = {
	{"new", mfs_new},
	{"insert", mfs_insert},
};

int main(int argc, char** argv) {

	int y;
	//char** x = psplit("/pl/../././../p2/p3/..//", &y);
	//char** x = psplit("/p2/", &y);
	//char** x = psplit("../../p2/", &y);
	char** x = psplit("pl/../../././../p2/p3/..//", &y);

	printf("%i\n", y);
	for(int i = 0; i < y; i++) printf("%i:\t%s\n", i, x[i]);

	if(argc < 2) err: {
		printf("valid functions:");
		for(int i = 0; i < NUM_MULTICALL; i++) printf(" %s%c", mc[i].name, ((NUM_MULTICALL - i) ^ 1) ? ',' : '\n');
		return 1;
	}
	for(int i = 0; i < NUM_MULTICALL; i++) if(!strcmp(argv[1], mc[i].name)) return mc[i].fn(argc - 1, argv + 1);
	goto err;
}

