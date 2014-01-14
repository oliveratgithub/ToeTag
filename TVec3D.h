
@class TMatrix;

@interface TVec3D : NSObject
{
@public
	NSNumber* pickName;
	float x, y, z, u, v;
	
	// Temp variables used when exporting triangle meshes
	TVec3D* normal;
}

-(id) init;
-(id)initWithX:(float)InX Y:(float)InY Z:(float)InZ;
-(id)initWithX:(float)InX Y:(float)InY Z:(float)InZ U:(float)InU V:(float)InV;

-(void) pushPickName;
-(NSNumber*) getPickName;
-(ESelectCategory) getSelectCategory;
-(void) selmgrWasUnselected;
-(void) pushPickName;
-(TVec3D*) normalize;
-(float) getSizeSquared;
-(float) getSize;
-(TVec3D*) swizzleToQuake;
-(TVec3D*) swizzleFromQuake;
-(BOOL) isAlmostEqualTo:(TVec3D*)In;

+(TVec3D*) calcNormalFromA:(TVec3D*)InA B:(TVec3D*)InB C:(TVec3D*)InC;
+(TVec3D*) subtractA:(TVec3D*)InA andB:(TVec3D*)InB;
+(TVec3D*) addA:(TVec3D*)InA andB:(TVec3D*)InB;
+(TVec3D*) multiplyA:(TVec3D*)InA andB:(TVec3D*)InB;
+(TVec3D*) scale:(TVec3D*)In By:(float)InScale;
+(TVec3D*) crossA:(TVec3D*)InA andB:(TVec3D*)InB;
+(float) dotA:(TVec3D*)InA andB:(TVec3D*)InB;
+(TVec3D*) dirFromYaw:(float)InYaw;

@end
