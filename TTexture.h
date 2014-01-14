
@interface TTexture : NSObject
{
@public
	NSString* name;
	NSInteger width, height;
	byte* RGBBytes;
	GLuint texGLName;
	BOOL bShowInBrowser;			// NO means the texture is registered with all contexts, but isn't browsable
	NSNumber* pickName;
	
	BOOL bInUse;					// If YES, this texture is being used in the level (on visible geometry at least - hidden brushes aren't counted)
	unsigned int mruClickCount;		// The mru number assigned to this texture the last time it was clicked
	
	// Temp - refreshed every time the texture browser is drawn
	float lastXPos, lastYPos;
	
	// Temp - used to optimize drawing of textured level views
	BOOL bDirtyRenderArray;
	TRenderArray* renderArray;
	
	// Temp - used when writing the texture out to a WAD
	miptexheader_t* mipTex;
}

-(void) registerWithCurrentOpenGLContext;
-(void) bind;
-(void) setLastRenderLocationX:(float)InX Y:(float)InY;
-(void) pushPickName;
-(NSNumber*) getPickName;
-(ESelectCategory) getSelectCategory;
-(void) selmgrWasUnselected;

@end
