
@implementation TRenderTextureBrowserComponent

-(id) init
{
	[super init];
	
	return self;
}

-(void) beginDraw:(BOOL)InSelect
{
	[super beginDraw:InSelect];
	
	[TGlobal G]->currentRenderComponent = self;
	
	glClearColor( 0.15, 0.25, 0.35, 0 );
	glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
}

-(void) draw:(MAPDocument*)InMAP SelectedState:(BOOL)InSelect
{
	if( [TGlobal G]->drawingPausedRefCount > 0 )
	{
		return;
	}

	NSSize size = [ownerView frame].size;
	
	glEnable( GL_TEXTURE_2D );

	float XPos, YPos,
		BorderSz = 5.0f,
		TexBorderSz = 2.f,
		TallestTexture = 0.0f;
	
	XPos = BorderSz + TexBorderSz;
	YPos = -BorderSz - TexBorderSz;
	
	NSMutableArray* textures = [self getFilteredTextureArray];
	for( TTexture* T in textures )
	{
		float TWidth = T->width * ownerView->orthoZoom;
		float THeight = T->height * ownerView->orthoZoom;
		
		if( XPos + TWidth + BorderSz + TexBorderSz > size.width )
		{
			XPos = BorderSz;
			YPos -= TallestTexture + BorderSz + TexBorderSz;
			TallestTexture = 0;
		}
		
		// Black background
		
		if( [InMAP->selMgr isSelected:T] )
		{
			// We want the selected texture to have a pure white border, so bind -1 as the current texture.
			glBindTexture( GL_TEXTURE_2D, -1 );
			glColor3f( 1.0f, 1.0f, 1.0f );
		}
		else
		{
			// Unselected textures have a black border and that can be accomplished without changing the
			// current texture bind as a color of black gives you pure black pixels.
			glColor3f( 0.0f, 0.0f, 0.0f );
		}
		
		glBegin( GL_TRIANGLE_FAN );
		{
			glVertex3f( XPos-2, YPos+2, 0.0 );
			glVertex3f( XPos -2, YPos-THeight-2, 0.0 );
			glVertex3f( XPos+TWidth+2, YPos-THeight-2, 0.0 );
			glVertex3f( XPos+TWidth+2, YPos+2, 0.0 );
		}
		glEnd();
		
		// Texture
		
		[T bind];
		
		glColor3f( 1.0f, 1.0f, 1.0f );
		
		glBegin( GL_TRIANGLE_FAN );
		{
			glTexCoord2f( 0.0, 0.0 );
			glVertex3f( XPos, YPos, 0.0 );
			
			glTexCoord2f( 0.0, 1.0 );
			glVertex3f( XPos, YPos-THeight, 0.0 );
			
			glTexCoord2f( 1.0, 1.0 );
			glVertex3f( XPos+TWidth, YPos-THeight, 0.0 );

			glTexCoord2f( 1.0, 0.0 );
			glVertex3f( XPos+TWidth, YPos, 0.0 );
		}
		glEnd();
		
		if( THeight > TallestTexture )
		{
			TallestTexture = THeight;
		}

		XPos += TWidth + BorderSz + TexBorderSz;
	}
	
	glDisable( GL_TEXTURE_2D );
}

-(void) drawForPick:(MAPDocument*)InMAP Category:(ESelectCategory)InCategory
{
	NSSize size = [ownerView frame].size;
	
	float XPos, YPos,
	BorderSz = 5.0f,
	TexBorderSz = 2.f,
	TallestTexture = 0.0f;
	
	XPos = BorderSz + TexBorderSz;
	YPos = -BorderSz - TexBorderSz;
	
	NSMutableArray* textures = [self getFilteredTextureArray];
	for( TTexture* T in textures )
	{
		float TWidth = T->width * ownerView->orthoZoom;
		float THeight = T->height * ownerView->orthoZoom;
		
		if( XPos + TWidth + BorderSz + TexBorderSz > size.width )
		{
			XPos = BorderSz;
			YPos -= TallestTexture + BorderSz + TexBorderSz;
			TallestTexture = 0;
		}
		
		// Pickable rectangle
		
		[T pushPickName];
		
		glBegin( GL_TRIANGLE_FAN );
		{
			glVertex3f( XPos-2, YPos+2, 0.0 );
			glVertex3f( XPos -2, YPos-THeight-2, 0.0 );
			glVertex3f( XPos+TWidth+2, YPos-THeight-2, 0.0 );
			glVertex3f( XPos+TWidth+2, YPos+2, 0.0 );
		}
		glEnd();
		
		glPopName();
		
		if( THeight > TallestTexture )
		{
			TallestTexture = THeight;
		}
		
		XPos += TWidth + BorderSz + TexBorderSz;
	}
}

-(void) drawWithoutOutput
{
	NSSize size = [ownerView frame].size;
	float XPos, YPos,
	BorderSz = 5.0f,
	TexBorderSz = 2.f,
	TallestTexture = 0.0f;
	
	XPos = BorderSz + TexBorderSz;
	YPos = -BorderSz - TexBorderSz;
	
	NSMutableArray* textures = [self getFilteredTextureArray];
	for( TTexture* T in textures )
	{
		float TWidth = T->width * ownerView->orthoZoom;
		float THeight = T->height * ownerView->orthoZoom;
		
		if( XPos + TWidth + BorderSz + TexBorderSz > size.width )
		{
			XPos = BorderSz;
			YPos -= TallestTexture + BorderSz + TexBorderSz;
			TallestTexture = 0;
		}
		
		// Record where the texture was last drawn
		
		[T setLastRenderLocationX:XPos Y:YPos];
		
		// **Drawing code removed
		
		if( THeight > TallestTexture )
		{
			TallestTexture = THeight;
		}
		
		XPos += TWidth + BorderSz + TexBorderSz;
	}
	
	ownerView->cameraLimits->y = - (YPos + BorderSz);
}

-(NSMutableArray*) getFilteredTextureArray
{
	NSMutableArray* textures = [NSMutableArray new];
	
	MAPDocument* map = [[[ownerView window] windowController] document];
	NSString* texNameFilter = ((TTextureBrowserView*)ownerView)->texNameFilter;
	
	for( TTexture* T in map->texturesFromWADs )
	{
		// Exclude textures that aren't supposed to be shown in the browser
		
		if( T->bShowInBrowser == NO )
		{
			continue;
		}
		
		// Check the name against the name filter
		
		if( ([texNameFilter length] > 0 && [T->name rangeOfString:texNameFilter].location == NSNotFound ) )
		{
			continue;
		}
		
		// Check the texture against the usage filter
		
		switch( ((TTextureBrowserView*)ownerView)->usageFilter )
		{
			case TBUF_All:
			{
			}
			break;

			case TBUF_InUse:
			{
				if( T->bInUse == NO )
				{
					continue;
				}
			}
			break;
				
			case TBUF_MRU:
			{
				if( T->mruClickCount == 0 )
				{
					continue;
				}
			}
			break;
		}

		// Texture is usable so add it to the list
		
		[textures addObject:T];
	}
	
	if( ((TTextureBrowserView*)ownerView)->usageFilter == TBUF_MRU )
	{
		// Sort by mruClickCount
		
		textures = [[textures sortedArrayUsingSelector:@selector(compareByMRUClickCount:)] mutableCopy]; 
	}
	
	return textures;
}

@end

