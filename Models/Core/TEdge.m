
@implementation TEdge

-(id) initWithOwner:(TFace*)InOwner Vert0:(int)InVert0 Vert1:(int)InVert1
{
	[super init];
	
	ownerFace = InOwner;
	verts[0] = InVert0;
	verts[1] = InVert1;
	pickName = nil;
	normal = nil;
	
	return self;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	TEdge* newedge = [TEdge new];
	
	newedge->ownerFace = ownerFace;
	newedge->verts[0] = verts[0];
	newedge->verts[1] = verts[1];
	newedge->pickName = [pickName copy];
	
	return newedge;
}

- (BOOL) isEqual:(id)anObject
{
	if( [anObject isKindOfClass:[TEdge class]] == NO )
	{
		return [super isEqual:anObject];
	}
	
	TEdge* G = (TEdge*)anObject;
	
	TVec3D* v0 = [ownerFace->verts objectAtIndex:verts[0]];
	TVec3D* v1 = [ownerFace->verts objectAtIndex:verts[1]];
	
	TVec3D* gv0 = [G->ownerFace->verts objectAtIndex:G->verts[0]];
	TVec3D* gv1 = [G->ownerFace->verts objectAtIndex:G->verts[1]];
	
	if( ([v0 isAlmostEqualTo:gv0] && [v1 isAlmostEqualTo:gv1]) || ([v0 isAlmostEqualTo:gv1] && [v1 isAlmostEqualTo:gv0]) )
	{
		return YES;
	}
	
	return NO;
}

-(void) pushPickName
{
	if( pickName == nil )
	{
		pickName = [NSNumber numberWithUnsignedInt:[[TGlobal G] generatePickName]];
	}
	
	glPushName( [pickName unsignedIntValue] );
}

-(NSNumber*) getPickName
{
	if( pickName == nil )
	{
		pickName = [NSNumber numberWithUnsignedInt:[[TGlobal G] generatePickName]];
	}
	
	return pickName;
}

-(ESelectCategory) getSelectCategory
{
	return TSC_Edge;
}

-(void) selmgrWasUnselected
{
}

-(BOOL) isSelected:(MAPDocument*)InMap
{
	if( [InMap->selMgr isSelected:[ownerFace->verts objectAtIndex:verts[0]]] && [InMap->selMgr isSelected:[ownerFace->verts objectAtIndex:verts[1]]] )
	{
		return YES;
	}
	
	return NO;
}

@end
