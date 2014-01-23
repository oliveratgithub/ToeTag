
@implementation TFace

-(id) init
{
	[super init];
	
	textureName = @"TOETAGDEFAULT";
	
	verts = [NSMutableArray new];
	uoffset = voffset = 0.0;
	rotation = 0;
	uscale = vscale = 1;
	pickName = nil;
	edges = [NSMutableArray new];

	return self;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	TFace* newface = [TFace new];
	
	newface->textureName = [textureName mutableCopy];
	newface->uoffset = uoffset;
	newface->voffset = voffset;
	newface->rotation = rotation;
	newface->uscale = uscale;
	newface->vscale = vscale;
	
	for( TVec3D* V in verts )
	{
		[newface->verts addObject:[V mutableCopy]];
	}
	
	for( TEdge* G in edges )
	{
		[newface->edges addObject:[G mutableCopy]];
	}
	
	newface->normal = [normal mutableCopy];
	newface->lightValue = lightValue;
	newface->pickName = [pickName copy];

	return newface;
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
	return TSC_Face;
}

-(void) selmgrWasUnselected
{
}

-(void) textureAxisFromNormal:(TVec3D*)InNormal OutU:(TVec3D**)OutU OutV:(TVec3D**)OutV
{
	float bestaxis, dot, best, i;

	best = 0;
	bestaxis = 0;

	for( i = 0 ; i < 6 ; i++ )
	{
		dot = [TVec3D dotA:InNormal andB:[[TGlobal G]->baseAxis objectAtIndex:(i * 3)]];
		
		if( dot > best )
		{
			best = dot;
			bestaxis = i;
		}
	}

	TVec3D* u = [[TGlobal G]->baseAxis objectAtIndex:(bestaxis*3)+1];
	TVec3D* v = [[TGlobal G]->baseAxis objectAtIndex:(bestaxis*3)+2];
	
	*OutU = [u mutableCopy];
	*OutV = [v mutableCopy];
}

-(void) generateTexCoords:(MAPDocument*)InMAP
{
	// This is a good spot to update this faces normal
	
	normal = [[TPlane alloc] initFromTriangleA:[verts objectAtIndex:1] B:[verts objectAtIndex:0] C:[verts objectAtIndex:2]];
	
	TTexture* tex = [InMAP findTextureByName:textureName];
	
	if( tex == nil )
	{
		return;
	}
	
	TVec3D* v0 = [[verts objectAtIndex:0] swizzleToQuake];
	TVec3D* v1 = [[verts objectAtIndex:1] swizzleToQuake];
	TVec3D* v2 = [[verts objectAtIndex:2] swizzleToQuake];
	
	TVec3D* Normal = [TVec3D calcNormalFromA:v0 B:v1 C:v2];
	TVec3D *UVec = [TVec3D new], *VVec = [TVec3D new];
	
	[v0 swizzleFromQuake];
	[v1 swizzleFromQuake];
	[v2 swizzleFromQuake];
	
	// Generate basic texture mapping vectors based on the polygon normals.
	
	[self textureAxisFromNormal:Normal OutU:&UVec OutV:&VVec];
	
	// Adapted from QBSP texturing code
	// Adapted from QBSP texturing code
	
	float uvec[3] = { UVec->x, UVec->y, UVec->z };
	float vvec[3] = { VVec->x, VVec->y, VVec->z };
	
	int sv, tv;
	float ang, sinv, cosv, ns, nt;
	
	if( rotation == 0 )			{ sinv =  0; cosv =  1; }
	else if( rotation == 90 )	{ sinv =  1; cosv =  0; }
	else if( rotation == 180 )	{ sinv =  0; cosv = -1; }
	else if( rotation == 270 )	{ sinv = -1; cosv =  0; }
	else
	{	
		ang = rotation / 180.0f * M_PI;
		sinv = sin( ang );
		cosv = cos( ang );
	}
	
	if( uvec[0] )		{ sv = 0; }
	else if( uvec[1] )	{ sv = 1; }
	else				{ sv = 2; }
	
	if( vvec[0] )		{ tv = 0; }
	else if( vvec[1] )	{ tv = 1; }
	else				{ tv = 2; }
	
	ns = cosv * uvec[sv] - sinv * uvec[tv];
	nt = sinv * uvec[sv] +  cosv * uvec[tv];
	uvec[sv] = ns;	uvec[tv] = nt;
	
	ns = cosv * vvec[sv] - sinv * vvec[tv];
	nt = sinv * vvec[sv] +  cosv * vvec[tv];
	vvec[sv] = ns;	vvec[tv] = nt;
	
	uvec[0] /= uscale;	uvec[1] /= uscale;	uvec[2] /= uscale;
	vvec[0] /= vscale;	vvec[1] /= vscale;	vvec[2] /= vscale;

	// Adapted from QBSP texturing code
	// Adapted from QBSP texturing code
	
	UVec = [[TVec3D alloc] initWithX:uvec[0] Y:uvec[1] Z:uvec[2]];
	VVec = [[TVec3D alloc] initWithX:vvec[0] Y:vvec[1] Z:vvec[2]];
	
	for( TVec3D* V in verts )
	{
		TVec3D* qvtx = [V swizzleToQuake];
		
		V->u = ((UVec->x * qvtx->x) + (UVec->y * qvtx->y) + (UVec->z * qvtx->z)) + uoffset;
		V->v = ((VVec->x * qvtx->x) + (VVec->y * qvtx->y) + (VVec->z * qvtx->z)) + voffset;
		
		V->u /= tex->width;
		V->v /= tex->height;
		
		[V swizzleFromQuake];
	}
	
	[self finalizeInternals];	
}

-(void) finalizeInternals
{
	// This is a good spot to update this faces normal
	
	normal = [[TPlane alloc] initFromTriangleA:[verts objectAtIndex:1] B:[verts objectAtIndex:0] C:[verts objectAtIndex:2]];
	
	// Compute a light value for this face.  This is what makes some faces darker than others.
	
	lightValue = 0.70;
	TVec3D* fnormal = [[TVec3D alloc] initWithX:fabs(normal->normal->x) Y:fabs(normal->normal->y) Z:fabs(normal->normal->z)];
	
	if( fnormal->x > fnormal->y )
	{
		if( fnormal->x > fnormal->z )
		{
			lightValue = 0.85;
		}
	}
	else
	{
		if( fnormal->y > fnormal->z )
		{
			lightValue = 1.0;
		}
	}
	
	edges = [NSMutableArray new];
	
	int x;
	for( x = 0 ; x < [verts count] ; ++x )
	{
		[edges addObject:[[TEdge alloc] initWithOwner:self Vert0:x Vert1:(x + 1 ) % [verts count]]];
	}
	
	[self computeArea];
}

-(int) splitWithPlane:(TPlane*)InPlane Front:(TFace**)InFront Back:(TFace**)InBack
{
	normal = [[TPlane alloc] initFromTriangleA:[verts objectAtIndex:1] B:[verts objectAtIndex:0] C:[verts objectAtIndex:2]];

	// Do a quick check to see if this face is entirely in front of or behind the plane.
	
	BOOL bFront = NO, bBehind = NO, bOnPlane = YES;
	
	for( TVec3D* V in verts )
	{
		ESide side = [InPlane getVertexSide:V];
		
		if( side == S_Behind )
		{
			bBehind = YES;
			bOnPlane = NO;
		}
		else if( side == S_Front )
		{
			bFront = YES;
			bOnPlane = NO;
		}
		
		if( bFront && bBehind )
		{
			break;
		}
	}
	
	// All verts lie on the plane
	
	if( bOnPlane )
	{
		if( signof( normal->dist ) == signof( InPlane->dist ) )
		{
			return TFS_Back;
		}
		else
		{
			return TFS_Front;
		}
	}
	
	// All verts are in front of the plane
	
	if( bFront && !bBehind )
	{
		return TFS_Front;
	}
	
	// All verts are behind the plane
	
	if( !bFront && bBehind )
	{
		return TFS_Back;
	}
	
	// If we've gotten this far, the plane must be splitting this face.
	
	*InFront = [TFace new];
	[*InFront copyTexturingAttribsFrom:self];
	
	*InBack = [TFace new];
	[*InBack copyTexturingAttribsFrom:self];
	
	TVec3D *splitVert;
	float v1Dist, v2Dist, startPct;
	int v;
	for( v = 0 ; v < [verts count] ; ++v )
	{
		TVec3D* v1 = [verts objectAtIndex:v];
		TVec3D* v2 = [verts objectAtIndex:((v+1) % [verts count])];
		
		ESide sidev1 = [InPlane getVertexSide:v1];
		ESide sidev2 = [InPlane getVertexSide:v2];
		
		// Vertex is on the plane, so add it to both sides
		
		if( sidev1 == S_OnPlane )
		{
			[(*InFront)->verts addObject:[v1 mutableCopy]];
			[(*InBack)->verts addObject:[v1 mutableCopy]];
			continue;
		}
		
		// Vertex is in front of the plane
		
		if( sidev1 == S_Front )
		{
			[(*InFront)->verts addObject:[v1 mutableCopy]];
		}
		
		// Vertex is behind the plane
		
		if( sidev1 == S_Behind )
		{
			[(*InBack)->verts addObject:[v1 mutableCopy]];
		}
		
		// If the second vertex is on the plane or both verts are on the same side, skip ahead
		
		if( sidev2 == S_OnPlane || sidev2 == sidev1 )
		{
			continue;
		}
		
		// Get the distance from the start/end positions to the plane
		
		v1Dist = fabs([InPlane getDistanceFrom:v1] - InPlane->dist);
		v2Dist = fabs([InPlane getDistanceFrom:v2] - InPlane->dist);
		
		// Compute the pct of the distance that the starting position is away from the plane
		
		startPct = v1Dist / (v1Dist + v2Dist);
		
		// Generate a vertex at the split point
		
		splitVert = [TVec3D addA:v1 andB:[TVec3D scale:[TVec3D subtractA:v2 andB:v1] By:startPct]];
		
		// Add it to both sides
		
		[(*InFront)->verts addObject:[splitVert mutableCopy]];
		[(*InBack)->verts addObject:[splitVert mutableCopy]];
	}

	// Sanity check here at the end.
	
	if( [(*InFront)->verts count] < 3 )
	{
		*InFront = nil;
		return TFS_Back;
	}
	
	if( [(*InBack)->verts count] < 3 )
	{
		*InBack = nil;
		return TFS_Front;
	}
	
	return TFS_Split;
}

-(void) drawSelectionHighlights:(MAPDocument*)InMAP
{
	// Draws the faces of the brush with a highlight color over them
	
	[self drawFlatFace:InMAP Color:[TGlobal G]->colorSelectedBrush];
	
	// Draws the outline of the brush in bold white
	
	glLineWidth( 2.0 );
	[self drawHighlightedOutline:InMAP Color:[TGlobal G]->colorWhite];
	glLineWidth( 1.0 );
}

-(void) drawOrthoSelectionHighlights:(MAPDocument*)InMAP
{
	// Draws the outline of the brush in bold white
	
	glLineWidth( 2.0 );
	[self drawHighlightedOutline:InMAP Color:[TGlobal G]->colorWhite];
	glLineWidth( 1.0 );
}

-(void) drawHighlightedOutline:(MAPDocument*)InMAP Color:(TVec3D*)InColor
{
	glDisable( GL_TEXTURE_2D );
	glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
	
	glColor3fv( &InColor->x );
	
	glBegin( GL_LINE_LOOP );
	{
		for( TVec3D* V in verts )
		{
			glVertex3fv( &V->x );
		}
	}
	glEnd();
	
	glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
	glEnable( GL_TEXTURE_2D );
}

-(void) drawFlatFace:(MAPDocument*)InMAP Color:(TVec3D*)InColor
{
	glDisable( GL_TEXTURE_2D );
	
	glColor4f( InColor->x, InColor->y, InColor->z, 0.05f );
	
	glBegin( GL_TRIANGLE_FAN );
	{
		for( TVec3D* V in verts )
		{
			glVertex3fv( &V->x );
		}
	}
	glEnd();
	
	glEnable( GL_TEXTURE_2D );
}

-(TVec3D*) getCenter
{
	TVec3D* center = [TVec3D new];
	
	for( TVec3D* V in verts )
	{
		center = [TVec3D addA:center andB:V];
	}
	
	center = [TVec3D scale:center By:1.0f / [verts count]];
	
	return center;
}

// Returns the area of the face as the sum of the length of it's edges.  This may or may not
// be mathematically correct, but it works for our purposes.

-(void) computeArea
{
	area = 0;
	
	int v;
	for( v = 0 ; v < [verts count] ; ++v )
	{
		TVec3D* v0 = [verts objectAtIndex:v];
		TVec3D* v1 = [verts objectAtIndex:((v + 1) % [verts count])];
		
		area += [[TVec3D subtractA:v1 andB:v0] getSize];
	}
}

// Sort faces by area

- (NSComparisonResult)compareByArea:(TFace*)InFace
{
	// Multiply by -1 so that we sort in descending order (this sorts the larger faces first)
	
	return (area - InFace->area) * -1;
}

// Sort faces by texture name

- (NSComparisonResult)compareByTextureName:(TFace*)InFace
{
	return [textureName caseInsensitiveCompare:InFace->textureName];
}

-(TFace*) flip
{
	[self reverseVerts];
	
	[self finalizeInternals];
	
	// Return self as a convenience to the caller. The flip happens in place.
	return self;
}

-(TFace*) reverseVerts
{
	NSMutableArray* newVerts = [NSMutableArray new];
	
	NSEnumerator *enumerator = [verts reverseObjectEnumerator];
	id object;
	
	while ((object = [enumerator nextObject]))
	{
		[newVerts addObject:object];
	}
	
	verts = newVerts;
	
	// Return self as a convenience to the caller. The flip happens in place.
	return self;
}

-(void) copyTexturingAttribsFrom:(TFace*)InFace
{
	textureName = [InFace->textureName mutableCopy];
	uoffset = InFace->uoffset;
	voffset = InFace->voffset;
	rotation = InFace->rotation;
	uscale = InFace->uscale;
	vscale = InFace->vscale;
}

// Adjusts the offsets for this face to maintain texture lock

-(void) maintainTextureLockAfterDrag:(TVec3D*)InDelta
{
	if( [TGlobal G]->bTextureLock == NO )
	{
		return;
	}
	
	InDelta = [InDelta swizzleToQuake];
	
	TVec3D *vX, *vY;
	
	TVec3D* v0 = [[verts objectAtIndex:0] swizzleToQuake];
	TVec3D* v1 = [[verts objectAtIndex:1] swizzleToQuake];
	TVec3D* v2 = [[verts objectAtIndex:2] swizzleToQuake];
	
	TVec3D* Normal = [TVec3D calcNormalFromA:v0 B:v1 C:v2];
	[self textureAxisFromNormal:Normal OutU:&vX OutV:&vY];
	
	[v0 swizzleFromQuake];
	[v1 swizzleFromQuake];
	[v2 swizzleFromQuake];
	
	TVec3D* vDP = [TVec3D new];
	vDP->x = [TVec3D dotA:InDelta andB:vX];
	vDP->y = [TVec3D dotA:InDelta andB:vY];
	
	double fAngle = rotation / 180.0f * M_PI;
	double c = cos( fAngle );
	double s = sin( fAngle );
	
	TVec3D* vShift = [TVec3D new];
	vShift->x = vDP->x * c - vDP->y * s;
	vShift->y = vDP->x * s + vDP->y * c;
	
	uoffset -= vShift->x / uscale;
	voffset -= vShift->y / vscale;
	
	[InDelta swizzleFromQuake];
}

-(TPlane*) getPlane
{
	return [[TPlane alloc] initFromTriangleA:[verts objectAtIndex:0] B:[verts objectAtIndex:1] C:[verts objectAtIndex:2]];
}

-(int) getVertIdx:(TVec3D*)InV
{
	int idx = 0;
	
	for( TVec3D* V in verts )
	{
		if( [V isAlmostEqualTo:InV] )
		{
			return idx;
		}
		
		idx++;
	}
	
	return -1;
}

// Determines if this face contains an edge that matches the 2 verts in InFullEdge

-(BOOL) containsFullEdge:(TEdgeFull*)InFullEdge
{
	for( TEdge* E in edges )
	{
		TVec3D* edgeV0 = [verts objectAtIndex:E->verts[0]];
		TVec3D* edgeV1 = [verts objectAtIndex:E->verts[1]];
		
		TVec3D* fullEdgeV0 = InFullEdge->verts[0];
		TVec3D* fullEdgeV1 = InFullEdge->verts[1];
		
		if( ([fullEdgeV0 isAlmostEqualTo:edgeV0] && [fullEdgeV1 isAlmostEqualTo:edgeV1]) || ([fullEdgeV0 isAlmostEqualTo:edgeV1] && [fullEdgeV1 isAlmostEqualTo:edgeV0]) )
		{
			return YES;
		}
	}
	
	return NO;
}

-(void) markDirtyRenderArray
{
	[[TGlobal getMAP] findTextureByName:textureName]->bDirtyRenderArray = YES;
}

// Properties

-(void) setTextureName:(NSString*)InTextureName
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	
	if( map )
	{
		[map findTextureByName:textureName]->bDirtyRenderArray = YES;
		[map findTextureByName:InTextureName]->bDirtyRenderArray = YES;
	}
	
	textureName = [InTextureName copy];
}

@synthesize textureName;

@end
