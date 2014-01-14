
@implementation TEdgeFull

-(id) initWithVert0:(TVec3D*)InVert0 Vert1:(TVec3D*)InVert1
{
	[super init];
	
	verts[0] = InVert0;
	verts[1] = InVert1;
	
	return self;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	TEdgeFull* newedge = [TEdgeFull new];
	
	newedge->verts[0] = [verts[0] mutableCopy];
	newedge->verts[1] = [verts[1] mutableCopy];
	
	return newedge;
}

- (BOOL) isEqual:(id)anObject
{
	if( [anObject isKindOfClass:[TEdgeFull class]] == NO )
	{
		return [super isEqual:anObject];
	}
	
	TEdgeFull* G = (TEdgeFull*)anObject;
	
	if( ([verts[0] isAlmostEqualTo:G->verts[0]] && [verts[1] isAlmostEqualTo:G->verts[1]]) || ([verts[0] isAlmostEqualTo:G->verts[1]] && [verts[1] isAlmostEqualTo:G->verts[0]]) )
	{
		return YES;
	}
	
	return NO;
}

-(void) swapVerts
{
	TVec3D* save = verts[0];
	verts[0] = verts[1];
	verts[1] = save;
}

-(BOOL) sharesVertWith:(TEdgeFull*)InE
{
	if( [verts[0] isAlmostEqualTo:InE->verts[0]] || [verts[1] isAlmostEqualTo:InE->verts[1]] )
	{
		return YES;
	}
	
	return NO;
}

@end
