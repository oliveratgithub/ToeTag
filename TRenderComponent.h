
@class TOpenGLView;
@class MAPDocument;

// Base class for all components that want to override view rendering in OpenGL.

@interface TRenderComponent : TComponent 
{
@public
	TOpenGLView* ownerView;
}

-(id)initWithOwner:(TOpenGLView*)InOwner;

-(void) beginDraw:(BOOL)InSelect;
-(void) draw:(MAPDocument*)InMAP SelectedState:(BOOL)InSelect;
-(void) drawForPick:(MAPDocument*)InMAP Category:(ESelectCategory)InCategory;
-(void) endDraw:(BOOL)InSelect;
-(void) drawWithoutOutput;

@end
