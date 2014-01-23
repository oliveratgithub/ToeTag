
@implementation TTextureBrowserProjComponent

-(id)initWithOwner:(TOpenGLView*)InOwnerView
{
	[super initWithOwner:InOwnerView];
	
	ownerView->orthoZoom = 1.0f;
	
	return self;
}

-(void) apply:(BOOL)InSelectMode
{
	NSSize size = [ownerView frame].size;
	
	float w = size.width;
	float h = size.height;

	// Projection
	
	glMatrixMode( GL_PROJECTION );
	glLoadIdentity();
	
	if( InSelectMode )
	{
		GLint viewport[4];
		glGetIntegerv( GL_VIEWPORT, viewport );
		gluPickMatrix( mouseX, viewport[3] - mouseY, PICK_AREA_SZ, PICK_AREA_SZ, viewport );
	}
	
	glOrtho( 0, w, -h, 0, 0, 10 );		// Places 0,0 in top left corner of viewport instead of bottom left
	
	// Camera
	
	glMatrixMode( GL_MODELVIEW );
	glLoadIdentity();
	glTranslatef( 0, ownerView->cameraLocation->y, 0 );
}

@end
