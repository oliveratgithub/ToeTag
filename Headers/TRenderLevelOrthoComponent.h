
// Renderer for the level editing views.

@interface TRenderLevelOrthoComponent : TRenderComponent 
{
}

-(void) beginDraw:(BOOL)InSelect;
-(void) draw:(MAPDocument*)InMAP SelectedState:(BOOL)InSelect;

@end
