
// Base class for entity rendering components

@interface TEntityClassRenderComponent : TRenderComponent
{
@public
	TEntityClass* entityClassOwner;
	BOOL bNegatesBoundingBox;
}

-(id)initWithOwner:(TEntityClass*)InEntityClassOwner;

-(void) beginDraw:(BOOL)InSelect;
-(void) draw:(MAPDocument*)InMAP Entity:(TEntity*)InEntity;
-(void) drawWire:(MAPDocument*)InMAP Entity:(TEntity*)InEntity;
-(void) drawSelectionHighlights:(MAPDocument*)InMAP Entity:(TEntity*)InEntity;
-(void) drawForPick:(MAPDocument*)InMAP Entity:(TEntity*)InEntity;
-(void) endDraw:(BOOL)InSelect;
-(void) drawWithoutOutput;

@end
