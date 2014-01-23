
// Renderer for the texture browser view.

@interface TRenderTextureBrowserComponent : TRenderComponent 
{
}

-(id) init;
-(void) beginDraw:(BOOL)InSelect;
-(void) draw:(MAPDocument*)InMAP SelectedState:(BOOL)InSelect;
-(void) drawForPick:(MAPDocument*)InMAP Category:(ESelectCategory)InCategory;
-(void) drawWithoutOutput;
-(NSMutableArray*) getFilteredTextureArray;

@end
