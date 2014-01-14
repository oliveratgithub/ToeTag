
@implementation TBuildInspectorDelegate

-(void) awakeFromNib
{
	leakLocation = nil;
}

-(IBAction) OnJumpToLeak:(id)sender
{
	if( leakLocation != nil )
	{
		MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
		
		for( TEntity* E in map->entities )
		{
			if( [E isPointEntity] && [E->location isAlmostEqualTo:leakLocation] )
			{
				[map jumpCamerasTo:[TVec3D scale:E->location By:-1]];
			}
		}
	}
}

@end
