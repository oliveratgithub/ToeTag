
// Triangular mesh loaded from PAK file

@interface TEntityClassRenderComponentMDL : TEntityClassRenderComponent
{
@public
	TMDL* model;
	int skinIdx;
}

-(void) draw:(MAPDocument*)InMAP Entity:(TEntity*)InEntity;
-(void) drawForPick:(MAPDocument*)InMAP Entity:(TEntity*)InEntity;

-(void) drawMDL:(MAPDocument*)InMAP Entity:(TEntity*)InEntity;
@end
