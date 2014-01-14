
// An orthographic projection in OpenGL

@interface TOrthoProjComponent : TProjComponent 
{
}

-(id)initWithOwner:(TOpenGLView*)InOwner;

-(void) apply:(BOOL)InSelectMode;

@end
