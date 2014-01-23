
@implementation TOpenGLOrthoView

-(void) awakeFromNib
{
	[super awakeFromNib];
	
	projectionComponent = [[TOrthoProjComponent alloc] initWithOwner:self];
}

@end
