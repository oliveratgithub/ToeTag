
@implementation TOrthoProjComponent

-(id)initWithOwner:(TOpenGLView*)InOwnerView
{
	[super initWithOwner:InOwnerView];
	
	ownerView->orthoZoom = 1.0f;
	
	return self;
}

-(void) apply:(BOOL)InSelectMode
{
	NSSize size = [ownerView frame].size;

	float w = size.width / 2.0f;
	float h = size.height / 2.0f;
	
	// Projection
	
	glMatrixMode( GL_PROJECTION );
	glLoadIdentity();
	
	if( InSelectMode )
	{
		GLint viewport[4];
		glGetIntegerv( GL_VIEWPORT, viewport );
		gluPickMatrix( mouseX, viewport[3] - mouseY, PICK_AREA_SZ, PICK_AREA_SZ, viewport );
	}
	
	glOrtho( -w * ownerView->orthoZoom, w * ownerView->orthoZoom, -h * ownerView->orthoZoom, h * ownerView->orthoZoom, -WORLD_SZ_HALF, WORLD_SZ_HALF );
	
	switch( ((TOrthoLevelView*)ownerView)->orientation )
	{
		case TO_Top_XZ:
			glRotatef( 90, 1, 0, 0 );
			break;

		case TO_Side_YZ:
			glRotatef( 90, 0, 1, 0 );
			break;
			
		case TO_Front_XY:
			// The default rotation is good
			break;
	}

	// Camera
	
	glMatrixMode( GL_MODELVIEW );
	glLoadIdentity();
	glTranslatef( ownerView->cameraLocation->x, ownerView->cameraLocation->y, ownerView->cameraLocation->z );
}

@end
