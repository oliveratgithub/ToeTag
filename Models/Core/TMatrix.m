
@implementation TMatrix

-(id) init
{
	[super init];
	
	[self loadIdentity];
	
	return self;
}

-(void) loadIdentity
{
	memset( m, 0, sizeof(float) * 16 );
	
	m[0][0] = 1;
	m[1][1] = 1;
	m[2][2] = 1;
	m[3][3] = 1;
}

+(TMatrix*) translateWithX:(float)InX Y:(float)InY Z:(float)InZ
{
	TMatrix* wk = [TMatrix new];
	
	wk->m[3][0] = InX;
	wk->m[3][1] = InY;
	wk->m[3][2] = InZ;
	
	return wk;
}

+(TMatrix*) rotateX:(float)InAngle;
{
	InAngle *= 0.0174532925;
	
	TMatrix* wk = [TMatrix new];

	if( InAngle == 0 )
	{
		return wk;
	}
	
	float C = cos( InAngle );
	float S = sin( InAngle );
	
	wk->m[1][1] = C;
	wk->m[1][2] = S;
	wk->m[2][1] = -S;
	wk->m[2][2] = C;

	return wk;
}
	
+(TMatrix*) rotateY:(float)InAngle;
{
	InAngle *= 0.0174532925;
	
	TMatrix* wk = [TMatrix new];
	
	if( InAngle == 0 )
	{
		return wk;
	}
	
	float C = cos( InAngle );
	float S = sin( InAngle );
	
	wk->m[0][0] = C;
	wk->m[0][2] = -S;
	wk->m[2][0] = S;
	wk->m[2][2] = C;
	
	return wk;
}

+(TMatrix*) rotateZ:(float)InAngle;
{
	InAngle *= 0.0174532925;
	
	TMatrix* wk = [TMatrix new];
	
	if( InAngle == 0 )
	{
		return wk;
	}
	
	float C = cos( InAngle );
	float S = sin( InAngle );
	
	wk->m[0][0] = C;
	wk->m[0][1] = S;
	wk->m[1][0] = -S;
	wk->m[1][1] = C;
	
	return wk;
}

+(TMatrix*) scale:(float)InScale
{
	return [self scaleWithX:InScale Y:InScale Z:InScale];
}

+(TMatrix*) scaleWithX:(float)InX Y:(float)InY Z:(float)InZ
{
	TMatrix* wk = [TMatrix new];
	
	wk->m[0][0] = InX;
	wk->m[1][1] = InY;
	wk->m[2][2] = InZ;
	
	return wk;
}

+(TMatrix*) multiplyA:(TMatrix*)InA withB:(TMatrix*)InB
{
	TMatrix* wk = [TMatrix new];
	
	wk->m[0][0] = InA->m[0][0] * InB->m[0][0] + InA->m[1][0] * InB->m[0][1] + InA->m[2][0] * InB->m[0][2] + InA->m[3][0] * InB->m[0][3];
	wk->m[1][0] = InA->m[0][0] * InB->m[1][0] + InA->m[1][0] * InB->m[1][1] + InA->m[2][0] * InB->m[1][2] + InA->m[3][0] * InB->m[1][3];
	wk->m[2][0] = InA->m[0][0] * InB->m[2][0] + InA->m[1][0] * InB->m[2][1] + InA->m[2][0] * InB->m[2][2] + InA->m[3][0] * InB->m[2][3];
	wk->m[3][0] = InA->m[0][0] * InB->m[3][0] + InA->m[1][0] * InB->m[3][1] + InA->m[2][0] * InB->m[3][2] + InA->m[3][0] * InB->m[3][3];
	
	wk->m[0][1] = InA->m[0][1] * InB->m[0][0] + InA->m[1][1] * InB->m[0][1] + InA->m[2][1] * InB->m[0][2] + InA->m[3][1] * InB->m[0][3];
	wk->m[1][1] = InA->m[0][1] * InB->m[1][0] + InA->m[1][1] * InB->m[1][1] + InA->m[2][1] * InB->m[1][2] + InA->m[3][1] * InB->m[1][3];
	wk->m[2][1] = InA->m[0][1] * InB->m[2][0] + InA->m[1][1] * InB->m[2][1] + InA->m[2][1] * InB->m[2][2] + InA->m[3][1] * InB->m[2][3];
	wk->m[3][1] = InA->m[0][1] * InB->m[3][0] + InA->m[1][1] * InB->m[3][1] + InA->m[2][1] * InB->m[3][2] + InA->m[3][1] * InB->m[3][3];
	
	wk->m[0][2] = InA->m[0][2] * InB->m[0][0] + InA->m[1][2] * InB->m[0][1] + InA->m[2][2] * InB->m[0][2] + InA->m[3][2] * InB->m[0][3];
	wk->m[1][2] = InA->m[0][2] * InB->m[1][0] + InA->m[1][2] * InB->m[1][1] + InA->m[2][2] * InB->m[1][2] + InA->m[3][2] * InB->m[1][3];
	wk->m[2][2] = InA->m[0][2] * InB->m[2][0] + InA->m[1][2] * InB->m[2][1] + InA->m[2][2] * InB->m[2][2] + InA->m[3][2] * InB->m[2][3];
	wk->m[3][2] = InA->m[0][2] * InB->m[3][0] + InA->m[1][2] * InB->m[3][1] + InA->m[2][2] * InB->m[3][2] + InA->m[3][2] * InB->m[3][3];
	
	wk->m[0][3] = InA->m[0][3] * InB->m[0][0] + InA->m[1][3] * InB->m[0][1] + InA->m[2][3] * InB->m[0][2] + InA->m[3][3] * InB->m[0][3];
	wk->m[1][3] = InA->m[0][3] * InB->m[1][0] + InA->m[1][3] * InB->m[1][1] + InA->m[2][3] * InB->m[1][2] + InA->m[3][3] * InB->m[1][3];
	wk->m[2][3] = InA->m[0][3] * InB->m[2][0] + InA->m[1][3] * InB->m[2][1] + InA->m[2][3] * InB->m[2][2] + InA->m[3][3] * InB->m[2][3];
	wk->m[3][3] = InA->m[0][3] * InB->m[3][0] + InA->m[1][3] * InB->m[3][1] + InA->m[2][3] * InB->m[3][2] + InA->m[3][3] * InB->m[3][3];
	
	return wk;
}

-(TVec3D*) transformVector:(TVec3D*)InVector
{
	TVec3D* vec = [TVec3D new];
	
	vec->x = ( InVector->x * m[0][0] ) + ( InVector->y * m [1][0] ) + ( InVector->z * m[2][0] ) + m[3][0];
	vec->y = ( InVector->x * m[0][1] ) + ( InVector->y * m[1][1] ) + ( InVector->z * m[2][1] ) + m[3][1];
	vec->z = ( InVector->x * m[0][2] ) + ( InVector->y * m[1][2] ) + ( InVector->z * m[2][2] ) + m[3][2];
		
	return vec;
}

@end
