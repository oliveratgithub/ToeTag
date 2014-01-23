
@class TOpenGLView;

// A 3D projection in OpenGL

@interface TProjComponent : TComponent 
{
@public
	TOpenGLView* ownerView;
	
	// Used for processing selections
	float mouseX, mouseY;
	GLuint buffer[GL_PICK_BUFFER_SZ];
}

-(id)initWithOwner:(TOpenGLView*)InOwner;
-(void) apply:(BOOL)InPickMode;
-(int) pickAtX:(float)InX Y:(float)InY DoubleClick:(BOOL)InDoubleClick ModifierFlags:(NSUInteger)InModFlags Category:(ESelectCategory)InCategory;

@end
