
@implementation TPAKReader

-(void) loadMDLTableOfContents:(NSString*)InFilename Into:(NSMutableDictionary*)InTableOfContents
{
	LOG( @"Reading PAK file table of contents: %@", InFilename );
	LOG_IN();
	
	[self openFile:InFilename];
	
	if( !fileHandle )
	{
		ERROR( @"Couldn't find PAK file: %@", InFilename );
		LOG_OUT();
		return;
	}
	
	// Extract the name of the owner mod by grabbing the right chunk of the path
	
	NSArray* chunks = [InFilename componentsSeparatedByString:@"/"];
	NSString* ownerMod = [chunks objectAtIndex:[chunks count] - 2];
	
	// Read the PAK header
	
	NSData* phdata = [fileHandle readDataOfLength:sizeof(pakheader_t)];
	PAKHeader = (pakheader_t*)[phdata bytes];
	
	SWAPINT32( PAKHeader->diroffset );
	SWAPINT32( PAKHeader->dirsize );
	
	// Verify that this is a PAK file
	
	if( PAKHeader->magic[0] != 'P' && PAKHeader->magic[1] != 'A' && PAKHeader->magic[2] != 'C' && PAKHeader->magic[3] != 'K' )
	{
		[fileHandle closeFile];
		return;
	}
	
	// Read the table of contents
	
	[fileHandle seekToFileOffset:PAKHeader->diroffset];
	NSData* pedata = [fileHandle readDataOfLength:PAKHeader->dirsize];
	PAKEntries = (pakentry_t*)[pedata bytes];
	
	int x;
	int numentries = PAKHeader->dirsize / sizeof( pakentry_t );
	
	for( x = 0 ; x < numentries ; ++x )
	{
		pakentry_t* pakentry = &PAKEntries[x];
		NSString* filename = [NSString stringWithUTF8String:pakentry->filename];
		
		// We only care about MDL files so filter on that extension.
		
		if( [[filename pathExtension] isEqual:@"mdl"] )
		{
			NSString* TOCKey = [[NSString stringWithFormat:@"%@/%@", ownerMod, filename] lowercaseString];
			
			SWAPINT32( pakentry->offset );
			SWAPINT32( pakentry->size );
			
			TMDLTocEntry* TOCEntry = [TMDLTocEntry new];
			TOCEntry->PAKFilename = [InFilename mutableCopy];
			TOCEntry->offset = pakentry->offset;
			TOCEntry->sz = pakentry->size;
			
			[InTableOfContents setObject:TOCEntry forKey:TOCKey];
		}
		
		pakentry++;
	}

	// Clean up
	
	[self closeFile];
	
	LOG_OUT();
}

-(TMDL*) loadMDL:(NSString*)InFilename Offset:(int)InOffset Size:(int)InSize
{
	LOG( @"Reading MDL from PAK file: %@", InFilename );
	LOG_IN();
	
	[self openFile:InFilename];
	
	if( !fileHandle )
	{
		ERROR( @"Couldn't find PAK file: %@", InFilename );
		LOG_OUT();
		return nil;
	}
	
	// Move to the start of this MDL in the file and read in it's data as one large blob.  We'll
	// use pointer arithmetic to move through it in RAM instead of seeking through it on the disk.
	
	[fileHandle seekToFileOffset:InOffset];
	
	NSData* mdldata = [fileHandle readDataOfLength:InSize];
	byte* mdlblob = (byte*)[mdldata bytes];
	
	byte* pos = mdlblob;
	
	// ---------------------
	// HEADER
	
	// Store a pointer to the header so we can access it later
	mdlheader_t* mdlheader = (mdlheader_t*)pos;
	
	SWAPINT32( mdlheader->flags );
	SWAPINT32( mdlheader->numframes );
	SWAPINT32( mdlheader->numtris );
	SWAPINT32( mdlheader->numskins );
	SWAPINT32( mdlheader->numverts );
	SWAPINT32( mdlheader->skinheight );
	SWAPINT32( mdlheader->skinwidth );
	SWAPINT32( mdlheader->synctype );
	SWAPINT32( mdlheader->version );
	SWAPFLOAT32( mdlheader->scale[0] );
	SWAPFLOAT32( mdlheader->scale[1] );
	SWAPFLOAT32( mdlheader->scale[2] );
	SWAPFLOAT32( mdlheader->origin[0] );
	SWAPFLOAT32( mdlheader->origin[1] );
	SWAPFLOAT32( mdlheader->origin[2] );
	SWAPFLOAT32( mdlheader->offsets[0] );
	SWAPFLOAT32( mdlheader->offsets[1] );
	SWAPFLOAT32( mdlheader->offsets[2] );
	SWAPFLOAT32( mdlheader->size );
	SWAPFLOAT32( mdlheader->radius );
	
	pos += 84;
	
	TMDL* mdl = [TMDL new];
	
	// ---------------------
	// SKINS
	
	// For each skin:
	// - allocate a TTexture to hold it
	// - read the index data and add the RGB values from the palette into the texture
	
	int s;
	for( s = 0 ; s < mdlheader->numskins ; ++s )
	{
		// Allocate a new skin texture
		TTexture* texture = [TTexture new];
		texture->name = @"modelskin";
		texture->width = mdlheader->skinwidth;
		texture->height = mdlheader->skinheight;
		texture->bShowInBrowser = NO;
		[mdl->skinTextures addObject:texture];
		
		// Figure out which kind of skin this is (static or animated)
		long skingroup = *pos;
		pos += sizeof(long);
		
		int skinsz = mdlheader->skinwidth * mdlheader->skinheight;
		
		switch( skingroup )
		{
			case 0:		// Static
			{
				texture->RGBBytes = (byte*)malloc( skinsz * 3 );
				byte* RGBp = texture->RGBBytes;
				
				int p;
				
				for( p = 0 ; p < skinsz ; ++p )
				{
					TVec3D* color = [[TGlobal G]->palette objectAtIndex:*pos];
					
					*RGBp = (byte)color->x;
					RGBp++;
					*RGBp = (byte)color->y;
					RGBp++;
					*RGBp = (byte)color->z;
					RGBp++;
					
					pos++;
				}
			}
				break;
				
			case 1:		// Animated
				assert( 0 );	// we don't support this yet (will we ever need to?)
				break;
		}
	}
	
	int x;
	
	// ---------------------
	// UVs
	
	// Store a pointer to where the UVs are in memory for use later
	
	stvert_t* UVs = (stvert_t*)pos;
	pos += sizeof(stvert_t) * mdlheader->numverts;
	
	for( x = 0 ; x < mdlheader->numverts ; ++x )
	{
		stvert_t* uv = &UVs[x];
		
		SWAPINT32( uv->onseam );
		SWAPINT32( uv->s );
		SWAPINT32( uv->t );
	}
	
	// ---------------------
	// TRIANGLES
	
	// Store a pointer to where the triangles are in memory for use later
	
	itriangle_t* triangles = (itriangle_t*)pos;
	pos += sizeof(itriangle_t) * mdlheader->numtris;
	
	for( x = 0 ; x < mdlheader->numtris ; ++x )
	{
		itriangle_t* tri = &triangles[x];
	
		SWAPINT32( tri->facesfront );
		SWAPINT32( tri->vertices[0] );
		SWAPINT32( tri->vertices[1] );
		SWAPINT32( tri->vertices[2] );
	}
	
	// ---------------------
	// FRAMES
	
	// We've reached the animation frames.  Every frame contains it's own set of vertices.  We only want the vertices
	// for the first animation frame for a simple representation in the editor.
	
	// Grab the frame type.  Animations are either simple (1 frame) or complex (multiple frames, also called a group)
	
	long frametype = *pos;
	pos += sizeof(long);
	
	switch( frametype )
	{
		case 0:		// simple
			pos += sizeof(simpleframe_t);
			break;
			
		default:	// complex
		{
			int numpics = *pos;
			pos += sizeof(long);			// number of pics
			pos += sizeof(trivertex_t);		// min
			pos += sizeof(trivertex_t);		// max
			pos += sizeof(float) * numpics;
			pos += sizeof(simpleframe_t);
		}
		break;
	}
	
	// Store a pointer to the verts in this frame
	trivertex_t* frameVerts = (trivertex_t*)pos;
	
	int tri;
	trivertex_t* vtx;
	stvert_t* st;
	for( tri = 0 ; tri < mdlheader->numtris ; ++tri )
	{
		itriangle_t* t = &triangles[tri];
		
		// This is mind warpingly complicated, but basically:
		//
		// - loop through all of the triangles in the MDL (grabbed a pointer to these earlier, they are global)
		// - each triangle contains indices into the frame verts.  these indices are used to grab the 3 verts to create each triangle.
		// - the UV list matches up with the vertex list, so the indices in the triangle can be used to grab a set of UV coords as well
		// 
		// NOTE: the vertices are packed into a 256x256x256 cube and must be expanded into their actual locations by 
		//       multiplying by the scale in the header and adding the origin, also found in the header
		//
		// NOTE : UV coords must sometimes have their U coordinate tweaked by 0.5 if they are:
		//        a) on a seam and b) the triangle they are on is facing the back of the model.
		//        this has something to do with how Quake does it's texture mapping.  all I know is that it works.
		
		vtx = (trivertex_t*)&frameVerts[t->vertices[0]];
		st = &UVs[t->vertices[0]];
		
		TVec3D* vtx0 = [[TVec3D alloc]
						initWithX:vtx->packedposition[0] * mdlheader->scale[0] + mdlheader->origin[0]
						Y:vtx->packedposition[1] * mdlheader->scale[1] + mdlheader->origin[1]
						Z:vtx->packedposition[2] * mdlheader->scale[2] + mdlheader->origin[2]
						U:st->s / (float)mdlheader->skinwidth
						V:st->t / (float)mdlheader->skinheight];
		
		if( st->onseam && !t->facesfront )
		{
			vtx0->u += 0.5f;
		}
		
		vtx = (trivertex_t*)&frameVerts[t->vertices[1]];
		st = &UVs[t->vertices[1]];
		
		TVec3D* vtx1 = [[TVec3D alloc]
						initWithX:vtx->packedposition[0] * mdlheader->scale[0] + mdlheader->origin[0]
						Y:vtx->packedposition[1] * mdlheader->scale[1] + mdlheader->origin[1]
						Z:vtx->packedposition[2] * mdlheader->scale[2] + mdlheader->origin[2]
						U:st->s / (float)mdlheader->skinwidth
						V:st->t / (float)mdlheader->skinheight];
		
		if( st->onseam && !t->facesfront )
		{
			vtx1->u += 0.5f;
		}
		
		vtx = (trivertex_t*)&frameVerts[t->vertices[2]];
		st = &UVs[t->vertices[2]];
		
		TVec3D* vtx2 = [[TVec3D alloc]
						initWithX:vtx->packedposition[0] * mdlheader->scale[0] + mdlheader->origin[0]
						Y:vtx->packedposition[1] * mdlheader->scale[1] + mdlheader->origin[1]
						Z:vtx->packedposition[2] * mdlheader->scale[2] + mdlheader->origin[2]
						U:st->s / (float)mdlheader->skinwidth
						V:st->t / (float)mdlheader->skinheight];
		
		if( st->onseam && !t->facesfront )
		{
			vtx2->u += 0.5f;
		}
		
		// Once we have 3 teeth, err verts, extracted we can swizzle them and store them
		
		[mdl->triangles addObject:[vtx2 swizzleFromQuake]];
		[mdl->triangles addObject:[vtx1 swizzleFromQuake]];
		[mdl->triangles addObject:[vtx0 swizzleFromQuake]];
	}
	
	// Clean up
	
	[self closeFile];
	
	LOG_OUT();
	
	return mdl;
}

@end
