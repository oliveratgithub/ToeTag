
@implementation TRenderComponent

-(id)initWithOwner:(TOpenGLView*)InOwnerView
{
	[super init];
	
	ownerView = InOwnerView;
	
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	TRenderComponent* newrc = [TRenderComponent new];
	
	newrc->ownerView = ownerView;
	
	return newrc;
}

-(void) beginDraw:(BOOL)InSelect
{
}

-(void) draw:(MAPDocument*)InMAP SelectedState:(BOOL)InSelect
{
}

-(void) drawForPick:(MAPDocument*)InMAP Category:(ESelectCategory)InCategory
{
}

-(void) endDraw:(BOOL)InSelect
{
}

// Does everything the "draw" function would do without any OpenGL calls.

-(void) drawWithoutOutput
{
}

@end

