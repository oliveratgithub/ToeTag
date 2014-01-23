
// ------------------------------------------------------

@implementation TRenderArray



-(id) initWithElementType:(ERenderArrayElementType)InType
{
	[super init];
	
	type = InType;
	
	switch( type )
	{
		case RAET_Vert:
			numFloatsPerElement = 3;
			break;
		case RAET_VertUV:
			numFloatsPerElement = 5;
			break;
		case RAET_VertUVColor:
			numFloatsPerElement = 8;
			break;
		case RAET_VertColor:
			numFloatsPerElement = 6;
			break;
	}
	
	currentIdx = maxIdx = 0;
	GROW_SZ = 250;
	data = nil;
	
	return self;
}

-(void) finalize
{
	if( data != nil )
	{
		free( data );
	}

	[super finalize];
}

-(void) resetToStart
{
	currentIdx = 0;
}

-(void) addElement:(int)InNumElements, ...;
{
	assert( InNumElements == numFloatsPerElement );

	if( currentIdx >= maxIdx )
	{
		maxIdx = currentIdx + (numFloatsPerElement * GROW_SZ);
		
		if( data == nil )
		{
			data = malloc( maxIdx * (numFloatsPerElement * sizeof(float)) );
		}
		else
		{
			data = realloc( data, maxIdx * (numFloatsPerElement * sizeof(float)) );
		}
	}

	float* writePtr = (float*)(data + currentIdx);
	
	va_list argumentList;
	va_start( argumentList, InNumElements );
	
	int x;
	for( x = 0 ; x < InNumElements ; ++x )
	{
		*writePtr = (float)va_arg( argumentList, double );
		writePtr++;
	}
	
	va_end( argumentList );
	
	currentIdx += numFloatsPerElement;
}

-(void) draw:(GLuint)InPrimType
{
	int stride = sizeof(float) * numFloatsPerElement;
	
	switch( type )
	{
		case RAET_Vert:
		{
			glEnableClientState( GL_VERTEX_ARRAY );
			glDisableClientState( GL_TEXTURE_COORD_ARRAY );
			glDisableClientState( GL_COLOR_ARRAY );
			
			glVertexPointer( 3, GL_FLOAT, stride, data );
		}
		break;
			
		case RAET_VertUV:
		{
			glEnableClientState( GL_VERTEX_ARRAY );
			glEnableClientState( GL_TEXTURE_COORD_ARRAY );
			glDisableClientState( GL_COLOR_ARRAY );

			glVertexPointer( 3, GL_FLOAT, stride, data );
			glTexCoordPointer( 2, GL_FLOAT, stride, data + 3 );
		}
		break;

		case RAET_VertUVColor:
		{
			glEnableClientState( GL_VERTEX_ARRAY );
			glEnableClientState( GL_TEXTURE_COORD_ARRAY );
			glEnableClientState( GL_COLOR_ARRAY );

			glVertexPointer( 3, GL_FLOAT, stride, data );
			glTexCoordPointer( 2, GL_FLOAT, stride, data + 3 );
			glColorPointer( 3, GL_FLOAT, stride, data + 5 );
		}
		break;

		case RAET_VertColor:
		{
			glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
			glDisable( GL_TEXTURE_2D );
			
			glEnableClientState( GL_VERTEX_ARRAY );
			glDisableClientState( GL_TEXTURE_COORD_ARRAY );
			glEnableClientState( GL_COLOR_ARRAY );

			glVertexPointer( 3, GL_FLOAT, stride, data );
			glColorPointer( 3, GL_FLOAT, stride, data + 3 );
		}
		break;
	}
	
	glDrawArrays( InPrimType, 0, currentIdx / numFloatsPerElement );

	glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
}

@end

// ------------------------------------------------------

@implementation TPreferencesTools

+(BOOL) isQuakeDirectoryValid:(NSUserDefaultsController*)InUDC
{
	NSString* quakeDir = [[InUDC values] valueForKey:@"quakeDirectory"];
	
	// Verify that the Quake directory is valid by checking for the existence of "id1/pak0.pak" within it.
	
	NSFileManager* fm = [NSFileManager defaultManager];
	if( [fm fileExistsAtPath:[NSString stringWithFormat:@"%@/id1/pak0.pak", [quakeDir stringByExpandingTildeInPath]]] == YES )
	{
		return YES;
	}
	
	return NO;
}

@end

// ------------------------------------------------------

@implementation TBBox

-(id) init
{
	[super init];
	
	min = [[TVec3D alloc] initWithX:WORLD_SZ Y:WORLD_SZ Z:WORLD_SZ];
	max = [[TVec3D alloc] initWithX:-WORLD_SZ Y:-WORLD_SZ Z:-WORLD_SZ];
	
	return self;
}

-(void) addVertex:(TVec3D*)In
{
	if( In->x < min->x )	min->x = In->x;
	if( In->y < min->y )	min->y = In->y;
	if( In->z < min->z )	min->z = In->z;

	if( In->x > max->x )	max->x = In->x;
	if( In->y > max->y )	max->y = In->y;
	if( In->z > max->z )	max->z = In->z;
}

-(TVec3D*) getCenter
{
	return [TVec3D addA:min andB:[TVec3D scale:[self getExtents] By:0.5]];
}

-(TVec3D*) getExtents
{
	return [TVec3D subtractA:max andB:min];
}

-(void) expandBy:(float)In
{
	min->x -= In;
	min->y -= In;
	min->z -= In;
	
	max->x += In;
	max->y += In;
	max->z += In;
}

@end
	
// ------------------------------------------------------

@implementation TMDLTocEntry

-(id) init
{
	[super init];
	
	PAKFilename = @"??";
	offset = sz = 0;
	
	return self;
}

@end

// ------------------------------------------------------
// A triangle mesh loaded from a PAK file

@implementation TMDL

-(id) init
{
	[super init];
	
	skinTextures = [NSMutableArray new];
	triangles = [NSMutableArray new];
	
	verts = nil;
	uvs = nil;
	elementCount = 0;
	primType = GL_TRIANGLES;
	
	return self;
}

-(void) finalize
{
	if( verts != nil )	free( verts );
	if( uvs != nil )	free( uvs );
	
	[super finalize];
}

-(void) finalizeInternals
{
	elementCount = [triangles count];
	
	verts = malloc( sizeof(float) * elementCount * 3 );
	uvs = malloc( sizeof(float) * elementCount * 2 );
	
	float* vp = verts;
	float* uvp = uvs;
	
	for( TVec3D* V in triangles )
	{
		*vp = V->x;		vp++;
		*vp = V->y;		vp++;
		*vp = V->z;		vp++;
		
		*uvp = V->u;	uvp++;
		*uvp = V->v;	uvp++;
	}
	
	triangles = nil;
}

@end

// ------------------------------------------------------
// A brush built from special MAP files included with ToeTag
// (which were released as part of the Quake source dump)
//
// Stuff like ammo boxes, exploding boxes, etc.

@implementation TEModel

-(id) init
{
	[super init];
	
	spawnFlagBit = 0;
	brush = nil;
	
	return self;
}

@end

// ------------------------------------------------------

@implementation TGlobal

@synthesize MDLTableOfContents;

static TGlobal* GData = nil;

-(id) init
{
	[super init];
	
	lastQuickGroupID = 0;
	lastPickName = 0;
	lastMRUClickCount = 0;
	lastTargetID = 0;
	bTrackingTextureUsage = NO;
	currentLevelView = nil;
	bTextureLock = NO;
	pivotLocation = nil;
	
	[self loadMDLTableOfContents];
	
	return self;
}

-(void) loadMDLTableOfContents
{
	LOG( @"Loading table of contents for MDLs" );
	LOG_IN();
	
	self.MDLTableOfContents = [NSMutableDictionary new];
	
	TPAKReader* pakreader = [TPAKReader new];
	NSString *quakeDir = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"quakeDirectory"];
	
//	[[NSFileManager defaultManager] directoryContentsAtPath:[NSString stringWithFormat:@"%@/%@", quakeDir, @"/*.PAK"]];
    NSError *aError;
    
    NSString *folderPath = [[NSString stringWithFormat:@"%@/%@", quakeDir, @"id1"] stringByStandardizingPath];
//    NSString *folderPath = [quakeDir stringByStandardizingPath];
    NSLog(@"folderPath %@", folderPath);
    
    NSArray *contentsArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: folderPath error:nil];

    NSLog(@"folderPath %@ %@", folderPath, contentsArray);
    
    for (NSString *file in contentsArray)
    {
		if( [[[file uppercaseString] pathExtension] isEqualToString:@"PAK"] )
		{
			NSString* filename = [NSString stringWithFormat:@"%@id1/%@", quakeDir, file];
			[pakreader loadMDLTableOfContents:filename Into:MDLTableOfContents];
		}
    }
    
    NSLog(@"MDLTableOfContents %@", MDLTableOfContents);
    
//	NSDirectoryEnumerator* dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:[NSString stringWithFormat:@"%@/", quakeDir]];
//	
//	NSString* file;
//	while( file = [dirEnum nextObject] )
//	{
//		if( [[[file uppercaseString] pathExtension] isEqualToString:@"PAK"] )
//		{
//			NSString* filename = [NSString stringWithFormat:@"%@/%@", quakeDir, file];
//			[pakreader loadMDLTableOfContents:filename Into:MDLTableOfContents];
//		}
//	}
	
	LOG_OUT();
}

-(void) precacheResources:(MAPDocument*)InMAP
{
	LOG( @"Start precaching:" );
	LOG_IN();
	
	// Read the palette file. Anything that loads with indexed colors will reference this palette.
	
	LOG( @"Palette: QuakePalette" );
	TFileReader* paletteReader = [TFileReader new];
	[paletteReader openFileFromResources:@"QuakePalette.lmp"];
	
	NSData* data = [paletteReader->fileHandle readDataToEndOfFile];
	byte rawdata[768];
	[data getBytes:rawdata length:768];
	
	palette = [NSMutableArray new];
	
	int x;
	for( x = 0 ; x < 768 ; x += 3 )
	{
		[palette addObject:[[TVec3D alloc] initWithX:rawdata[x] Y:rawdata[x+1] Z:rawdata[x+2]]];
	}
	
	[paletteReader closeFile];

	// Load textures for item emodels
	
	[self cacheTextureFromResources:@"+0_box_side" MAP:InMAP];
	[self cacheTextureFromResources:@"+0_box_top" MAP:InMAP];
	[self cacheTextureFromResources:@"+0_med25" MAP:InMAP];
	[self cacheTextureFromResources:@"+0_med25s" MAP:InMAP];
	[self cacheTextureFromResources:@"+0_med100" MAP:InMAP];
	[self cacheTextureFromResources:@"batt0sid" MAP:InMAP];
	[self cacheTextureFromResources:@"batt0top" MAP:InMAP];
	[self cacheTextureFromResources:@"batt1sid" MAP:InMAP];
	[self cacheTextureFromResources:@"batt1top" MAP:InMAP];
	[self cacheTextureFromResources:@"med3_0" MAP:InMAP];
	[self cacheTextureFromResources:@"med3_1" MAP:InMAP];
	[self cacheTextureFromResources:@"med100" MAP:InMAP];
	[self cacheTextureFromResources:@"nail0sid" MAP:InMAP];
	[self cacheTextureFromResources:@"nail0top" MAP:InMAP];
	[self cacheTextureFromResources:@"nail1sid" MAP:InMAP];
	[self cacheTextureFromResources:@"nail1top" MAP:InMAP];
	[self cacheTextureFromResources:@"rock0sid" MAP:InMAP];
	[self cacheTextureFromResources:@"rock1sid" MAP:InMAP];
	[self cacheTextureFromResources:@"rockettop" MAP:InMAP];
	[self cacheTextureFromResources:@"shot0sid" MAP:InMAP];
	[self cacheTextureFromResources:@"shot0top" MAP:InMAP];
	[self cacheTextureFromResources:@"shot1sid" MAP:InMAP];
	[self cacheTextureFromResources:@"shot1top" MAP:InMAP];
	[self cacheTextureFromResources:@"toetagdefault" MAP:InMAP];
	
	LOG_OUT();
	LOG( @"End precaching" );
}

-(void) cacheTextureFromResources:(NSString*)InName MAP:(MAPDocument*)InMAP
{
	LOG( @"Texture: %@", InName );
	
	NSString* filename = [NSString stringWithFormat:@"%@/%@.bmp", [[NSBundle mainBundle] resourcePath], InName ];
	NSImage* img = [[NSImage alloc] initWithContentsOfFile:filename];
	NSData *tiff_data = [[NSData alloc] initWithData:[img TIFFRepresentation]];
	NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithData:tiff_data];
	
	TTexture* texture = [TTexture new];
	texture->name = [[InName uppercaseString] mutableCopy];
	texture->bShowInBrowser = NO;
	texture->width = [[img bestRepresentationForDevice:nil] pixelsWide];
	texture->height = [[img bestRepresentationForDevice:nil] pixelsHigh];
	texture->RGBBytes = (byte*)malloc( (texture->width * texture->height) * 3 );
	
	int w, h;
	NSColor* color;
	for( w = 0 ; w < texture->width ; ++w )
	{
		for( h = 0 ; h < texture->height ; ++h )
		{
			int idx = ((h * texture->width) + w) * 3;
			color = [bitmap colorAtX:w y:h];
			
			byte* rgb = texture->RGBBytes + idx;
			
			*rgb = (byte)([color redComponent] * 255);
			*(rgb + 1) = (byte)([color greenComponent] * 255);
			*(rgb + 2) = (byte)([color blueComponent] * 255);
		}
	}
	
	[InMAP->texturesFromWADs addObject:texture];
	
	if( [InName isEqualToString:@"toetagdefault"] )
	{
		InMAP->defaultTexture = texture;
	}
}

+(TGlobal*) G
{
	if( !GData )
	{
		GData = [TGlobal new];
		
		// Some initialization relies on the global object being created already (like TVec3Ds).  If they aren't done here, outside
		// of the TGlobal constructor, infinite loops will happen.

		GData->LevelRenderLightDir = [[[TVec3D alloc] initWithX:4 Y:6 Z:2] normalize];
		
		GData->colorWhite = [[TVec3D alloc] initWithX:1.0 Y:1.0 Z:1.0];
		GData->colorBlack = [[TVec3D alloc] initWithX:0.0 Y:0.0 Z:0.0];
		GData->colorLtGray = [[TVec3D alloc] initWithX:0.75 Y:0.75 Z:0.75];
		GData->colorMedGray = [[TVec3D alloc] initWithX:0.5 Y:0.5 Z:0.5];
		GData->colorDkGray = [[TVec3D alloc] initWithX:0.25 Y:0.25 Z:0.25];
		GData->colorSelectedBrush = [[TVec3D alloc] initWithX:0.0 Y:0.5 Z:1.0];
		GData->colorSelectedBrushHalf = [[TVec3D alloc] initWithX:0.0 Y:0.25 Z:0.5];
		
		GData->worldExtents = [[TVec3D alloc] initWithX:WORLD_SZ Y:WORLD_SZ Z:WORLD_SZ];
		
		GData->baseAxis = [NSMutableArray new];
		
		[GData->baseAxis addObject:[[TVec3D alloc] initWithX:0 Y:0 Z:1]];	[GData->baseAxis addObject:[[TVec3D alloc] initWithX:1 Y:0 Z:0]];	[GData->baseAxis addObject:[[TVec3D alloc] initWithX:0 Y:-1 Z:0]];
		[GData->baseAxis addObject:[[TVec3D alloc] initWithX:0 Y:0 Z:-1]];	[GData->baseAxis addObject:[[TVec3D alloc] initWithX:1 Y:0 Z:0]];	[GData->baseAxis addObject:[[TVec3D alloc] initWithX:0 Y:-1 Z:0]];
		[GData->baseAxis addObject:[[TVec3D alloc] initWithX:1 Y:0 Z:0]];	[GData->baseAxis addObject:[[TVec3D alloc] initWithX:0 Y:1 Z:0]];	[GData->baseAxis addObject:[[TVec3D alloc] initWithX:0 Y:0 Z:-1]];
		[GData->baseAxis addObject:[[TVec3D alloc] initWithX:-1 Y:0 Z:0]];	[GData->baseAxis addObject:[[TVec3D alloc] initWithX:0 Y:1 Z:0]];	[GData->baseAxis addObject:[[TVec3D alloc] initWithX:0 Y:0 Z:-1]];
		[GData->baseAxis addObject:[[TVec3D alloc] initWithX:0 Y:1 Z:0]];	[GData->baseAxis addObject:[[TVec3D alloc] initWithX:1 Y:0 Z:0]];	[GData->baseAxis addObject:[[TVec3D alloc] initWithX:0 Y:0 Z:-1]];
		[GData->baseAxis addObject:[[TVec3D alloc] initWithX:0 Y:-1 Z:0]];	[GData->baseAxis addObject:[[TVec3D alloc] initWithX:1 Y:0 Z:0]];	[GData->baseAxis addObject:[[TVec3D alloc] initWithX:0 Y:0 Z:-1]];
		
		GData->dragAxis = [NSMutableArray new];
		
		[GData->dragAxis addObject:[[TVec3D alloc] initWithX:0 Y:0 Z:1]];	[GData->dragAxis addObject:[[TVec3D alloc] initWithX:1 Y:0 Z:0]];	[GData->dragAxis addObject:[[TVec3D alloc] initWithX:0 Y:0 Z:1]];
		[GData->dragAxis addObject:[[TVec3D alloc] initWithX:0 Y:0 Z:-1]];	[GData->dragAxis addObject:[[TVec3D alloc] initWithX:-1 Y:0 Z:0]];	[GData->dragAxis addObject:[[TVec3D alloc] initWithX:0 Y:0 Z:-1]];
		[GData->dragAxis addObject:[[TVec3D alloc] initWithX:1 Y:0 Z:0]];	[GData->dragAxis addObject:[[TVec3D alloc] initWithX:0 Y:0 Z:-1]];	[GData->dragAxis addObject:[[TVec3D alloc] initWithX:1 Y:0 Z:0]];
		[GData->dragAxis addObject:[[TVec3D alloc] initWithX:-1 Y:0 Z:0]];	[GData->dragAxis addObject:[[TVec3D alloc] initWithX:0 Y:0 Z:1]];	[GData->dragAxis addObject:[[TVec3D alloc] initWithX:-1 Y:0 Z:0]];
		[GData->dragAxis addObject:[[TVec3D alloc] initWithX:0 Y:1 Z:0]];	[GData->dragAxis addObject:[[TVec3D alloc] initWithX:1 Y:0 Z:0]];	[GData->dragAxis addObject:[[TVec3D alloc] initWithX:0 Y:0 Z:1]];
		[GData->dragAxis addObject:[[TVec3D alloc] initWithX:0 Y:-1 Z:0]];	[GData->dragAxis addObject:[[TVec3D alloc] initWithX:-1 Y:0 Z:0]];	[GData->dragAxis addObject:[[TVec3D alloc] initWithX:0 Y:0 Z:-1]];
		
		GData->drawingPausedRefCount = 0;

		// Standard string attributes
		
		NSFont* font = [NSFont fontWithName:@"Andale Mono" size:14.0];
		GData->standardStringAttribs = [NSMutableDictionary dictionary];
		[GData->standardStringAttribs setObject:font forKey:NSFontAttributeName];
		[GData->standardStringAttribs setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
		[GData->standardStringAttribs setObject:[NSNumber numberWithFloat:-2.0] forKey:NSStrokeWidthAttributeName];
	}
	
	return GData;
}

-(GLuint) generatePickName
{
	return ++lastPickName;
}

-(int) generateQuickGroupID
{
	MAPDocument* map = [TGlobal getMAP];
	
	BOOL bQGValueIsUnique = NO;
	
	while( bQGValueIsUnique == NO )
	{
		lastQuickGroupID++;
		
		bQGValueIsUnique = YES;
		
		for( TEntity* E in map->entities )
		{
			if( E->quickGroupID == lastQuickGroupID )
			{
				bQGValueIsUnique = NO;
				break;
			}
			
			for( TBrush* B in E->brushes )
			{
				if( B->quickGroupID == lastQuickGroupID )
				{
					bQGValueIsUnique = NO;
					break;
				}
			}
		}
	}
	
	return lastQuickGroupID;
}

-(unsigned int) generateMRUClickCount
{
	return ++lastMRUClickCount;
}

-(unsigned int) generateTargetID
{
	return ++lastTargetID;
}

// Searches through the palette and finds the index that is closest to
// InR,InG,InB using error diffusion.

-(byte) getBestPaletteIndexForR:(int)InR G:(int)InG B:(int)InB AllowFullbrights:(BOOL)InAllowFullbrights
{
	int i, dr, dg, db, bestdistortion, distortion, bestcolor;
	
	//
	// let any color go to 0 as a last resort
	//
	
	bestdistortion = ( InR*InR + InG*InG + InB*InB ) * 2;
	bestcolor = 0;
	int max = 256;
	
	if( InAllowFullbrights == NO )
	{
		max -= 32;
	}
	
	for( i = 0 ; i < max ; ++i )
	{
		TVec3D* color = [palette objectAtIndex:i];
		
		dr = InR - (int)color->x;
		dg = InG - (int)color->y;
		db = InB - (int)color->z;
		
		distortion = dr*dr + dg*dg + db*db;
		
		if( distortion < bestdistortion )
		{
			if( !distortion )
			{
				return i;               // perfect match
			}
			
			bestdistortion = distortion;
			bestcolor = i;
		}
	}
	
	return bestcolor;
}

+(int) findClosestPowerOfTwo:(int)InValue
{
	--InValue;
	
	InValue |= InValue >> 1;
	InValue |= InValue >> 2;
	InValue |= InValue >> 4;
	InValue |= InValue >> 8;
	InValue |= InValue >> 16;
	
	return ++InValue;
}

+(int) findBestPowerOfTwo:(int)InValue
{
	int value = 1;
	
	while( TRUE )
	{
		if( value >= InValue )
		{
			break;
		}
		
		value *= 2;
	}
	
	return value;
}

+(MAPDocument*) getMAP
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	
	// No current document.  Pass a MAPDocument* instead of calling here.
	assert( map != nil );
	
	return map;
}

+(void) logOpenGLErrors
{
	GLenum error;

	while( (error = glGetError()) != GL_NO_ERROR )
	{
		char* error_msg = (char*)gluErrorString( error );

		if (error_msg == NULL)
		{
			NSLog( @"OPENGL ERROR : Unknown" );
		}
		else
		{
			NSLog( @"OPENGL ERROR : %s", error_msg );
		}
	}
}

@end
