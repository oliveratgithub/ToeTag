
@interface TEntityClassRenderComponentEMDL : TEntityClassRenderComponent
{
@public
	NSMutableArray* emodels;
}

-(void) draw:(MAPDocument*)InMAP Entity:(TEntity*)InEntity;
-(void) drawForPick:(MAPDocument*)InMAP Entity:(TEntity*)InEntity;

-(void) drawEMDL:(TEModel*)InEModel MAP:(MAPDocument*)InMAP Entity:(TEntity*)InEntity;
@end
