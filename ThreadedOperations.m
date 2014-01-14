
@implementation NSOperationCreateBrushFromPlanes

-(id) initWithMap:(MAPDocument*)InMap ClipPlanes:(NSMutableArray*)InClipPlanes quickGroupID:(int)InQuickGroupID Entity:(TEntity*)InEntity SelectAfterImport:(BOOL)InSelectAfterImport
{
	[super init];
	
	map = InMap;
	clipPlanes = InClipPlanes;
	entity = InEntity;
	bSelectAfterImport = InSelectAfterImport;
	quickGroupID = InQuickGroupID;
	
	return self;
}

-(void) main
{
	TBrush* brush = [TBrush createBrushFromPlanes:clipPlanes MAP:map];
	
	[entity->brushes addObject:brush];
	[map->historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_AddBrush Object:brush Owner:entity]];
	
	brush->quickGroupID = quickGroupID;
	
	if( bSelectAfterImport == YES )
	{
		[map->selMgr addSelection:brush];
	}
}

@end

// ------------------------------------------------------

@implementation NSOperationGenerateMipMaps

-(id) initWithTexture:(TTexture*)InTexture DiskSize:(int)InDiskSize
{
	[super init];
	
	texture = InTexture;
	dsize = InDiskSize;
	
	return self;
}

-(void) main
{
	byte* rgbData = texture->RGBBytes;
	
	strcpy( texture->mipTex->name, [texture->name UTF8String] );
	texture->mipTex->width = texture->width;
	texture->mipTex->height = texture->height;
	
	texture->mipTex->offsets[0] = sizeof( miptexheader_t );
	texture->mipTex->offsets[1] = texture->mipTex->offsets[0] + (texture->width * texture->height);
	texture->mipTex->offsets[2] = texture->mipTex->offsets[1] + ((texture->width / 2) * (texture->height / 2));
	texture->mipTex->offsets[3] = texture->mipTex->offsets[2] + ((texture->width / 4) * (texture->height / 4));
	
	int x = 0;
	int step = 1;
	
	byte *mip = (byte*)texture->mipTex + texture->mipTex->offsets[x];
	
	for( ; x < 4 ; ++x )
	{
		int w, h;
		
		for( h = 0 ; h < texture->height ; h += step )
		{
			for( w = 0 ; w < texture->width ; w += step )
			{
				int r, g, b, count, ww, hh;
				
				r = g = b = count = 0;
				
				// TODO: try keeping the brightest pixel instead of averaging them all together and see what that looks like.  might be interesting
				for( hh = h ; hh < h + step ; ++hh )
				{
					for( ww = w ; ww < w + step ; ++ww )
					{
						int idx = ((hh * texture->width) + ww) * 3;
						
						byte* rgb = rgbData + idx;
						r += *rgb;
						g += *(rgb + 1);
						b += *(rgb + 2);
						
						count++;
					}
				}
				
				r /= (float)count;
				g /= (float)count;
				b /= (float)count;
				
				byte palIdx = [[TGlobal G] getBestPaletteIndexForR:r G:g B:b AllowFullbrights:YES];
				
				*mip = palIdx;
				mip++;
			}
		}
		
		step *= 2;
	}

	SWAPINT32( texture->mipTex->height );
	SWAPINT32( texture->mipTex->width );
	SWAPINT32( texture->mipTex->offsets[0] );
	SWAPINT32( texture->mipTex->offsets[1] );
	SWAPINT32( texture->mipTex->offsets[2] );
	SWAPINT32( texture->mipTex->offsets[3] );

	NSLog( @"Generated mipmaps for : %@", texture->name );
}

@end

