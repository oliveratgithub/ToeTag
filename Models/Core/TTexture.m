
@implementation TTexture

-(id) init
{
	[super init];
	
	name = @"???";
	width = height = 0;
	RGBBytes = nil;
	mipTex = nil;
	texGLName = 0;
	bShowInBrowser = YES;
	pickName = nil;
	bDirtyRenderArray = YES;
	
	renderArray = nil;
	
	return self;
}

- (void)finalize
{
	if( RGBBytes != nil )
	{
		free( RGBBytes );
	}

	if( mipTex != nil )
	{
		free( mipTex );
	}
	
	[super finalize];
}

-(void) pushPickName
{
	if( pickName == nil )
	{
		pickName = [NSNumber numberWithUnsignedInt:[[TGlobal G] generatePickName]];
	}
	
	glPushName( [pickName unsignedIntValue] );
}

-(NSNumber*) getPickName
{
	if( pickName == nil )
	{
		pickName = [NSNumber numberWithUnsignedInt:[[TGlobal G] generatePickName]];
	}

	return pickName;
}

-(ESelectCategory) getSelectCategory
{
	return TSC_Texture;
}

-(void) selmgrWasUnselected
{
}

// Uploads this texture to OpenGL within the current context.

-(void) registerWithCurrentOpenGLContext
{
	if( texGLName == 0 )
	{
		glGenTextures( 1, &texGLName );
	}

	[self bind];
	
	glTexImage2D( GL_TEXTURE_2D, 0, 3, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, RGBBytes );
		
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
}

// Bind this texture to OpenGL in preperation for using it to draw with.

-(void) bind
{
	glBindTexture( GL_TEXTURE_2D, texGLName );
	
	if( [TGlobal G]->bTrackingTextureUsage == YES )
	{
		bInUse = YES;
	}
}

-(void) setLastRenderLocationX:(float)InX Y:(float)InY
{
	lastXPos = InX;
	lastYPos = InY;
}

// Sort textures by name

- (NSComparisonResult)compareByName:(TTexture*)InTex
{
	return [name caseInsensitiveCompare:InTex->name];
}

// Sort texture by their sizes (height first, then width, and finally using their name as a tie breaker)
// This method produces a very tight arrangement of textures in the browser.

- (NSComparisonResult)compareBySize:(TTexture*)InTex
{
	NSString* nameA = [NSString stringWithFormat:@"%04i%04i%@", height, width, name];
	NSString* nameB = [NSString stringWithFormat:@"%04i%04i%@", InTex->height, InTex->width, InTex->name];
	
	return [nameA caseInsensitiveCompare:nameB];
}

// Sorts textures by their mruClickCount, highest on top

- (NSComparisonResult)compareByMRUClickCount:(TTexture*)InTex
{
	return ((int)InTex->mruClickCount) - ((int)mruClickCount);
}

@end
