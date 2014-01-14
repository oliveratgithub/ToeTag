
@implementation TPlane

-(id)initFromTriangleA:(TVec3D*)InA B:(TVec3D*)InB C:(TVec3D*)InC
{
	[super init];
	
	normal = [TVec3D calcNormalFromA:InA B:InB C:InC];
	dist = [self getDistanceFrom:InC];
	
	axisVectors[0] = [[TVec3D subtractA:InA andB:InB] normalize];
	axisVectors[1] = [TVec3D crossA:normal andB:axisVectors[0]];
	
	baseVert = [TVec3D new];
	baseVert->x = (InA->x + InB->x + InC->x) / 3.0f;
	baseVert->y = (InA->y + InB->y + InC->y) / 3.0f;
	
	baseVert->z = (InA->z + InB->z + InC->z) / 3.0f;
	
	uoffset = voffset = rotation = 0;
	uscale = vscale = 1;
	
	textureName = @"";
	
	return self;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	TPlane* newplane = [TPlane new];
	
	newplane->axisVectors[0] = [axisVectors[0] mutableCopy];
	newplane->axisVectors[1] = [axisVectors[1] mutableCopy];
	newplane->normal = [normal mutableCopy];
	newplane->baseVert = [baseVert mutableCopy];
	newplane->dist = dist;
	
	return newplane;
}

-(float) getDistanceFrom:(TVec3D*)InVector
{
	return [TVec3D dotA:normal andB:InVector];
}

-(ESide) getVertexSide:(TVec3D*)InVector
{
	float vertDistanceToThisPlane = [self getDistanceFrom:InVector];
	float absdelta = fabs( vertDistanceToThisPlane - dist );

	if( vertDistanceToThisPlane - dist >= ON_PLANE_EPSILON )
	{
		return S_Front;
	}
	
	if( absdelta <= ON_PLANE_EPSILON )
	{
		return S_OnPlane;
	}
	
	return S_Behind;
}

// Creates a huge TFace polygon that lies on this plane

-(TFace*) getHugePolygon
{
	TFace* face = [TFace new];
	
	float sz = WORLD_SZ;
	
	TVec3D* UVecMin = [TVec3D addA:baseVert andB:[TVec3D scale:axisVectors[0] By:-sz]];
	TVec3D* UVecMax = [TVec3D addA:baseVert andB:[TVec3D scale:axisVectors[0] By:sz]];
	TVec3D* VVecMin = [TVec3D addA:baseVert andB:[TVec3D scale:axisVectors[1] By:-sz]];
	TVec3D* VVecMax = [TVec3D addA:baseVert andB:[TVec3D scale:axisVectors[1] By:sz]];
	
	TVec3D* TL = [TVec3D scale:[TVec3D addA:UVecMin andB:VVecMin] By:0.5f];
	TVec3D* TR = [TVec3D scale:[TVec3D addA:UVecMax andB:VVecMin] By:0.5f];
	TVec3D* BR = [TVec3D scale:[TVec3D addA:UVecMax andB:VVecMax] By:0.5f];
	TVec3D* BL = [TVec3D scale:[TVec3D addA:UVecMin andB:VVecMax] By:0.5f];
	
	[face->verts addObject:TL];
	[face->verts addObject:TR];
	[face->verts addObject:BR];
	[face->verts addObject:BL];
	
	face->textureName = [textureName mutableCopy];
	face->uoffset = uoffset;
	face->voffset = voffset;
	face->rotation = rotation;
	face->uscale = uscale;
	face->vscale = vscale;
	
	return face;
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

-(BOOL) isAlmostEqualTo:(TPlane*)In
{
	if( fabs(dist - In->dist) > NUMBERS_ARE_SAME_LARGE_EPSILON || [normal isAlmostEqualTo:In->normal] == NO )
	{
		return NO;
	}
	
	return YES;
}

-(TPlane*) flip
{
	normal->x *= -1.0f;
	normal->y *= -1.0f;
	normal->z *= -1.0f;
	
	dist *= -1;
	
	// Return self as a convenience to the caller. The flip happens in place.
	return self;
}

- (NSComparisonResult)compareByVertexRatio:(TPlane*)InPlane
{
	if( vertexRatio == InPlane->vertexRatio )
	{
		int diff = facesCut - InPlane->facesCut;
		
		if( diff == 0 )
		{
			return NSOrderedSame;
		}
		else if( diff < 0 )
		{
			return NSOrderedAscending;
		}
		
		return NSOrderedDescending;
	}

	float diff = vertexRatio - InPlane->vertexRatio;

	if( diff < 0 )
	{
		return NSOrderedAscending;
	}
	
	return NSOrderedDescending;
}

- (NSComparisonResult)compareByNormalStrength:(TPlane*)InPlane
{
	float nx = fabs( normal->x );
	float ny = fabs( normal->y );
	float nz = fabs( normal->z );

	float pnx = fabs( InPlane->normal->x );
	float pny = fabs( InPlane->normal->y );
	float pnz = fabs( InPlane->normal->z );
	
	if( nx == pnx )
	{
		if( ny == pny )
		{
			if( nz > pnz )
			{
				return NSOrderedAscending;
			}
			else if( nz < pnz )
			{
				return NSOrderedDescending;
			}
		}
		else
		{
			if( ny > pny )
			{
				return NSOrderedDescending;
			}
			else if( ny < pny )
			{
				return NSOrderedAscending;
			}
		}
	}
	else
	{
		if( nx > pnx )
		{
			return NSOrderedAscending;
		}
		else if( nx < pnx )
		{
			return NSOrderedDescending;
		}
	}
	
	return NSOrderedSame;
}

@end
