
@implementation TEntityClassRenderComponent

-(id)initWithOwner:(TEntityClass*)InEntityClassOwner
{
	[super init];
	
	entityClassOwner = InEntityClassOwner;
	bNegatesBoundingBox = NO;
	
	return self;
}

-(void) beginDraw:(BOOL)InSelect
{
}

-(void) draw:(MAPDocument*)InMAP Entity:(TEntity*)InEntity
{
}

-(void) drawWire:(MAPDocument*)InMAP Entity:(TEntity*)InEntity
{
	[self draw:InMAP Entity:InEntity];
}

-(void) drawSelectionHighlights:(MAPDocument*)InMAP Entity:(TEntity*)InEntity
{
}

-(void) drawForPick:(MAPDocument*)InMAP Entity:(TEntity*)InEntity
{
}

-(void) endDraw:(BOOL)InSelect
{
}

-(void) drawWithoutOutput
{
}

@end

