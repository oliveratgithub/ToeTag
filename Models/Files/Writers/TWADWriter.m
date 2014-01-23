
@implementation TWADWriter

-(void) saveFile:(NSString*)InFilename Map:(MAPDocument*)InMap
{
	LOG( @"Writing WAD : %@", InFilename );
	
	NSMutableArray* textures = [InMap getTexturesForWritingToWAD];
	
	if( [textures count] > MAX_WAD_ENTRIES )
	{
		LOG( @"Too many textures (%d) being written to WAD.  Max allowed is: %d", [textures count], MAX_WAD_ENTRIES );
		return;
	}
	
	[self openFile:InFilename];
	
	// Generate mipmaps
	
	NSOperationQueue* queue = [NSOperationQueue new];

	for( TTexture* T in textures )
	{
		int sz = T->width * T->height;
		int dsize = sizeof(miptexheader_t) + sz + (sz / 2) + (sz / 4) + (sz / 8);
		
		if( T->mipTex != nil )
		{
			free( T->mipTex );
		}
		
		T->mipTex = (miptexheader_t*)malloc( dsize );
		
		[queue addOperation:[[NSOperationGenerateMipMaps alloc] initWithTexture:T DiskSize:dsize]];
	}

	[queue waitUntilAllOperationsAreFinished];

	// Create and fill out the header
	
	wadhead_t wadHeader;
	memset( &wadHeader, 0, sizeof(wadhead_t) );
	
	wadHeader.magic[0] = 'W';
	wadHeader.magic[1] = 'A';
	wadHeader.magic[2] = 'D';
	wadHeader.magic[3] = '2';
	
	wadHeader.numentries = [textures count];
	wadHeader.diroffset = sizeof(wadhead_t);

	for( TTexture* T in textures )
	{
		int sz = T->width * T->height;
		wadHeader.diroffset += sizeof(miptexheader_t) + sz + (sz / 2) + (sz / 4) + (sz / 8);
	}
		
	// Write the header
	
	SWAPINT32( wadHeader.diroffset );
	SWAPINT32( wadHeader.numentries );
	
	[fileHandle writeData:[NSData dataWithBytes:&wadHeader length:sizeof(wadhead_t)]];
	
	SWAPINT32( wadHeader.diroffset );
	SWAPINT32( wadHeader.numentries );
	
	wadentry_t WADEntries[MAX_WAD_ENTRIES];
	memset( &WADEntries, 0, sizeof(wadentry_t) * MAX_WAD_ENTRIES );
	
	// Now that the miptex structures have been created for every texture we are writing out, write that data to the disk.

	int weidx = 0;
	long filepos = sizeof( wadhead_t );
	
	for( TTexture* T in textures )
	{
		NSLog( @"Writing to WAD : %@ [%dx%d]", T->name, T->width, T->height );
		
		int sz = T->width * T->height;
		int dsize = sizeof(miptexheader_t) + sz + (sz / 2) + (sz / 4) + (sz / 8);

		wadentry_t* WE = &WADEntries[weidx];
		WE->filepos = filepos;
		WE->dsize = WE->size = sizeof(miptexheader_t) + sz + (sz / 2) + (sz / 4) + (sz / 8);
		WE->type = 68;		// texture
		strcpy( WE->name, [T->name UTF8String] );

		[fileHandle writeData:[NSData dataWithBytes:T->mipTex length:dsize]];
		
		SWAPINT32( WE->dsize );
		SWAPINT32( WE->filepos );
		SWAPINT32( WE->size );
		
		filepos += WE->dsize;
		weidx++;
	}
	
	// Write out the directory entries
	
	[fileHandle writeData:[NSData dataWithBytes:&WADEntries length:sizeof( wadentry_t ) * wadHeader.numentries]];
	
	LOG( @"WAD Written successfully" );
}

@end
