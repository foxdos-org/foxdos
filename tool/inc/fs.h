typedef struct {
	uint32_t jmp;		// used to jump past the header
	uint8_t magic[7];	// 'MOTHFS\0'
	uint8_t version;	// currently fs version 0
	uint32_t size;		// partition size in sectors - sectors always 512b
				// this means the max size is 'only' 2tb but i would
				// be surprised if anyone managed to use 2tb in dos

	uint32_t offset;	// offset of partition from start of disk
	uint8_t volname[15];	// name of partition
	uint8_t reserved;	// number of sectors reserved for boot code. these
				// are stored immediately following this header

	uint32_t abm;		// number of sectors reserved for the allocation
				// bitmap. these immediately follow the boot code
				// sectors. the root directory is stored in the first
				// non-reserved sector
	
	uint8_t bootcode[470];
	uint16_t signature;	// 0xAA55 as usual to make it directly bootable
} mothfs_header; // 512 bytes

typedef struct {
	uint32_t sector;	// sector offset relative to the partition, not the disk
	uint32_t length;	// number of consecutive sectors to address
} ptrlen; // 8 bytes

typedef struct {
	uint8_t type;		// 0 - file
				// 1 - directory

	uint8_t perms[3];	// unused in foxdos. good for alignment. top bit of
				// each nibble must be zero

	uint32_t ext;		// undefined in version 0 - contains uid, gid, data
				// for other file types, long filename, etc

	uint8_t name[8];	// filename
	uint8_t ext[3];		// extension
	uint8_t lfn;		// size of long filename - must be zero in version 0
				// this is on par with most filesystems

	uint16_t freebytes;	// number of bytes unused in last sector of file data
	uint16_t pad;
	
	uint32_t data[122];

	// for files - `data` is 61 `ptrlen`s. if not all 60 are used, it must be null
	// terminated by setting ptrlen.sector to zero. if there is no terminator,
	// data[60].sector points to a sector containing 64 more `ptrlen`s. if there is
	// no terminator in that sector, the last `ptrlen` points to another sector of
	// identical layout. this continues until a sector with a terminator is found

	// for directories - `data` is 122 sector offsets. if not all 121 are used, it
	// must be null terminated. if there is no terminator, data[121] points to a
	// sector containing 128 more sector offsets. the rules for this are similar
	// enough to how files work that i do not want to write it out again
} mothfs_file; // 512 bytes
