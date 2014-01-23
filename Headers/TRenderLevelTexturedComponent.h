
// Renderer for the level editing views.  Contains special optimizations for textured views.

@interface TRenderLevelTexturedComponent : TRenderComponent 
{

}

-(void) beginDraw:(BOOL)InSelect;
-(void) draw:(MAPDocument*)InMAP SelectedState:(BOOL)InSelect;
-(void) drawForPick:(MAPDocument*)InMAP Category:(ESelectCategory)InCategory;

@end
