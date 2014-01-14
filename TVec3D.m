
@implementation TVec3D

-(id) init
{
	[super init];
	
	pickName = nil;
	x = y = z = u = v = 0;
	normal = nil;
	
	return self;
}

-(id)initWithX:(float)InX Y:(float)InY Z:(float)InZ
{
	[super init];
	
	pickName = nil;
	x = InX;
	y = InY;
	z = InZ;
	u = v = 0;
	normal = nil;
	
	return self;
}

-(id)initWithX:(float)InX Y:(float)InY Z:(float)InZ U:(float)InU V:(float)InV
{
	[super init];
	
	pickName = nil;
	x = InX;
	y = InY;
	z = InZ;
	u = InU;
	v = InV;
	normal = nil;
	
	return self;
}

-(NSString*) description
{
	return [NSString stringWithFormat:@"%f,%f,%f", x, y, z];
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
	return TSC_Vertex;
}

-(void) selmgrWasUnselected
{
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	TVec3D* newvec = [TVec3D new];
	
	newvec->x = x;
	newvec->y = y;
	newvec->z = z;
	newvec->u = u;
	newvec->v = v;
	newvec->pickName = [pickName copy];
	
	if( normal != nil )
	{
		newvec->normal = [normal mutableCopy];
	}
	
	return newvec;
}

+(TVec3D*) calcNormalFromA:(TVec3D*)InA B:(TVec3D*)InB C:(TVec3D*)InC
{
	TVec3D* vec = [TVec3D new];
	
	vec = [TVec3D crossA:[TVec3D subtractA:InA andB:InB] andB:[TVec3D subtractA:InC andB:InB]];
	[vec normalize];

	return vec;
}

// A - B

+(TVec3D*) subtractA:(TVec3D*)InA andB:(TVec3D*)InB
{
	return [[TVec3D alloc] initWithX:(InA->x - InB->x) Y:(InA->y - InB->y) Z:(InA->z - InB->z)];
}

// A + B

+(TVec3D*) addA:(TVec3D*)InA andB:(TVec3D*)InB
{
	return [[TVec3D alloc] initWithX:(InA->x + InB->x) Y:(InA->y + InB->y) Z:(InA->z + InB->z)];
}

// A * B

+(TVec3D*) multiplyA:(TVec3D*)InA andB:(TVec3D*)InB
{
	return [[TVec3D alloc] initWithX:(InA->x * InB->x) Y:(InA->y * InB->y) Z:(InA->z * InB->z)];
}

// In * (float)InScale

+(TVec3D*) scale:(TVec3D*)In By:(float)InScale
{
	return [[TVec3D alloc] initWithX:(In->x * InScale) Y:(In->y * InScale) Z:(In->z * InScale)];
}

-(TVec3D*) normalize
{
	float length = [self getSizeSquared];
	
	if( length == 0 )
	{
		return self;
	}
	
	x /= length;
	y /= length;
	z /= length;

	// We return ourselves to accomodate callers who want to use a return value
	return self;
}

-(float) getSizeSquared
{
	return sqrt( (x * x) + (y * y) + (z * z ) );
}

-(float) getSize
{
	return (x * x) + (y * y) + (z * z );
}

+(TVec3D*) crossA:(TVec3D*)InA andB:(TVec3D*)InB
{
	TVec3D* wk = [TVec3D new];
	
	wk->x = ( InA->y * InB->z ) - ( InA->z * InB->y );
	wk->y = ( InA->z * InB->x ) - ( InA->x * InB->z );
	wk->z = ( InA->x * InB->y ) - ( InA->y * InB->x );
	
	return wk;
}

+(float) dotA:(TVec3D*)InA andB:(TVec3D*)InB
{
	return ((InA->x * InB->x) + (InA->y * InB->y) + (InA->z * InB->z));
}

+(TVec3D*) dirFromYaw:(float)InYaw
{
	TVec3D* dir = [[TVec3D alloc] initWithX:0 Y:0 Z:1];
	
	dir = [[TMatrix rotateY:-InYaw] transformVector:dir];
	
	return [dir normalize];
}

-(TVec3D*) swizzleToQuake
{
	float Y = y, Z = z;
	
	y = -Z;
	z = Y;
	
	return self;
}

-(TVec3D*) swizzleFromQuake
{
	float Y = y, Z = z;
	
	y = Z;
	z = -Y;
	
	return self;
}

-(BOOL) isAlmostEqualTo:(TVec3D*)In
{
	if( fabs( x - In->x ) > VERTS_ARE_SAME_EPSILON || fabs( y - In->y ) > VERTS_ARE_SAME_EPSILON || fabs( z - In->z ) > VERTS_ARE_SAME_EPSILON )
	{
		return NO;
	}
	
	return YES;
}

- (NSComparisonResult)compareBySize:(TVec3D*)InV
{
	NSString* nameA = [NSString stringWithFormat:@"%f, %f, %f", x, y, z];
	NSString* nameB = [NSString stringWithFormat:@"%f, %f, %f", InV->x, InV->y, InV->z];
	
	return [nameA caseInsensitiveCompare:nameB];
}

@end
