
typedef struct
{
	byte magic[4];		// "WAD2", Name of the new WAD format
	long numentries;			// Number of entries
	long diroffset;				// Position of WAD directory in file
} wadhead_t;

typedef struct
{
	long filepos;				// Position of the entry in WAD
	long dsize;					// Size of the entry in WAD file
	long size;					//Size of the entry in memory
	char type;					// type of entry
	char cmprs;					// Compression. 0 if none.
	short dummy;				// Not used
	char name[16];				// 1 to 16 characters, '\0'-padded
} wadentry_t;

typedef struct
{
	char			name[16];
	unsigned int	width, height;
	unsigned int	offsets[4];		// four mip maps stored
} miptexheader_t;

// PAK file header

typedef struct
{
	byte magic[4];				// "PACK", Name of the new WAD format
	long diroffset;				// Position of WAD directory from start of file
	long dirsize;				// Number of entries * 0x40 (64 char)
} pakheader_t;

// PAK directory entry

typedef struct
{
	char filename[56];			// Name of the file, Unix style, with extension,
	long offset;				// Position of the entry in PACK file
	long size;					// Size of the entry in PACK file
} pakentry_t;

// MDL header

typedef struct
{
	long id;					// 0x4F504449 = "IDPO" for IDPOLYGON
	long version;				// Version = 6
	float scale[3];				// Model scale factors.
	float origin[3];			// Model origin.
	float radius;				// Model bounding radius.
	float offsets[3];			// Eye position (useless?)
	long numskins;				// the number of skin textures
	long skinwidth;				// Width of skin texture (must be multiple of 8)
	long skinheight;			// Height of skin texture (must be multiple of 8)
	long numverts;				// Number of vertices
	long numtris;				// Number of triangles surfaces
	long numframes;				// Number of frames
	long synctype;				// 0= synchron, 1= random
	long flags;					// 0 (see Alias models)
	float size;					// average size of triangles
} mdlheader_t;

// Skin vertex

typedef struct
{
	long onseam;				// 0 or 0x20
	long s;						// position, horizontally (in range [0,skinwidth])
	long t;						// position, vertically (in range [0,skinheight])
} stvert_t;

// MDL triangle

typedef struct
{
	long facesfront;			// boolean
	long vertices[3];			// Index of 3 triangle vertices (in range [0,numverts])
} itriangle_t;

// MDL vertex

typedef struct
{
	byte packedposition[3];	// X,Y,Z coordinate, packed on 0-255
	byte lightnormalindex;		// index of the vertex normal
} trivertex_t;

// MDL animation frame

typedef struct
{
	trivertex_t min;				// minimum values of X,Y,Z
	trivertex_t max;				// maximum values of X,Y,Z
	char name[16];					// name of frame
	//trivertex_t* frame;			// array of vertices (matches mdlheader->numverts)
} simpleframe_t;

