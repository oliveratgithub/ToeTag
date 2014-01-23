
@implementation NSImage (ProportionalScaling)

- (NSImage*)imageByScalingProportionallyToSize:(NSSize)targetSize
{
	NSImage* sourceImage = self;
	NSImage* newImage = nil;
	
	if ([sourceImage isValid])
	{
		NSSize imageSize = [sourceImage size];
		float width  = imageSize.width;
		float height = imageSize.height;
		
		float targetWidth  = targetSize.width;
		float targetHeight = targetSize.height;
		
		float scaledWidth  = targetWidth;
		float scaledHeight = targetHeight;
		
		if ( NSEqualSizes( imageSize, targetSize ) == NO )
		{
			float widthFactor  = targetWidth / width;
			float heightFactor = targetHeight / height;

			scaledWidth  = width  * widthFactor;
			scaledHeight = height * heightFactor;
		}
		
		newImage = [[NSImage alloc] initWithSize:targetSize];
		
		[newImage lockFocus];
		
		NSRect thumbnailRect = NSMakeRect( 0, 0, scaledWidth, scaledHeight );
		
		[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
		
		[sourceImage drawInRect: thumbnailRect
					   fromRect: NSZeroRect
					  operation: NSCompositeSourceOver
					   fraction: 1.0];
		
		[newImage unlockFocus];
		
	}
	
	return newImage;
}

@end

#pragma optimization_level 0

@implementation TWADReader

-(BOOL) loadFile:(NSString*)InFilename Map:(MAPDocument*)InMap
{
	LOG( @"Reading WAD file: %@", InFilename );
	LOG_IN();
	
	[self openFile:InFilename];
	
	if( !fileHandle )
	{
		ERROR( @"Couldn't find WAD file: %@", InFilename );
		LOG_OUT();
		return NO;
	}
	
	NSData* data = [fileHandle readDataToEndOfFile];
	byte* headOfFile = (byte*)[data bytes];
	
	// Read the WAD header
	
	WADHeader = (wadhead_t*)headOfFile;
	
	SWAPINT32( WADHeader->diroffset );
	SWAPINT32( WADHeader->numentries );
	
	// Verify that this is a WAD file
	
	if( WADHeader->magic[0] != 'W' && WADHeader->magic[1] != 'A' && WADHeader->magic[2] != 'D' && WADHeader->magic[3] != '2' )
	{
		[fileHandle closeFile];
		return NO;
	}
	
	// Read the table of contents
	
	WADEntries = (wadentry_t*)(headOfFile + WADHeader->diroffset);
	
	// Read each entry
	
	TFileReader* paletteReader = [TFileReader new];
	[paletteReader openFileFromResources:@"QuakePalette.lmp"];
	
	NSData* paletteData = [paletteReader->fileHandle readDataToEndOfFile];
	byte palettedata[768];
	[paletteData getBytes:palettedata length:768];
	
	[paletteReader closeFile];
	
	int e;
	
	for( e = 0 ; e < WADHeader->numentries ; ++e )
	{
		SWAPINT32( WADEntries[e].filepos );
	
		switch( WADEntries[e].type )
		{
			case 68:		// Texture
			{
				byte* filePos = headOfFile + WADEntries[e].filepos;
				miptexheader_t* miptex = (miptexheader_t*)filePos;
				
				SWAPINT32( miptex->height );
				SWAPINT32( miptex->width );
				SWAPINT32( miptex->offsets[0] );
				SWAPINT32( miptex->offsets[1] );
				SWAPINT32( miptex->offsets[2] );
				SWAPINT32( miptex->offsets[3] );
				
				// If this texture name already exists, skip it.  Otherwise we end up with duplicates being loaded (the same texture in memory more than once).
				
				if( [InMap doesTextureExist:[NSString stringWithCString:miptex->name encoding:NSUTF8StringEncoding]] )
				{
					continue;
				}
				
				TTexture* T = [TTexture new];
				T->name = [NSString stringWithCString:miptex->name encoding:NSUTF8StringEncoding];
				T->width = miptex->width;
				T->height = miptex->height;
				
				T->RGBBytes = (byte*)malloc( (T->width * T->height) * 3 );
				
				//-----------------------
				
				int sz, x, palidx;
				byte R, G, B;
				
				byte* colorIndices = filePos + miptex->offsets[0];
				byte* RGBp = T->RGBBytes;
				
				sz = T->width * T->height;
				
				NSLog( @"Reading texture : %@ - %d x %d", T->name, T->width, T->height );
				
				for( x = 0 ; x < sz ; ++x )
				{
					palidx = colorIndices[x] * 3;
					
					assert( palidx > -1 && palidx < 768 );
					
					//NSLog( @"%u", colorIndices[x] );
					
					R = palettedata[ palidx ];
					G = palettedata[ palidx+1 ];
					B = palettedata[ palidx+2 ];
					
					*RGBp = R;	RGBp++;
					*RGBp = G;	RGBp++;
					*RGBp = B;	RGBp++;
				}
				
				[InMap->texturesFromWADs addObject:T];
			}
			break;
		}
	}
	
	[self closeFile];
	
	LOG( @"Done loading WAD." );
	LOG_OUT();
	
	return YES;
}

@end

#pragma optimization_level reset
