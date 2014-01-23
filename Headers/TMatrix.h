
@class TVec3D;

@interface TMatrix : NSObject
{
	float m[4][4];
}

-(id) init;
-(void) loadIdentity;
-(TVec3D*) transformVector:(TVec3D*)InVector;

+(TMatrix*) translateWithX:(float)InX Y:(float)InY Z:(float)InZ;
+(TMatrix*) rotateX:(float)InAngle;
+(TMatrix*) rotateY:(float)InAngle;
+(TMatrix*) rotateZ:(float)InAngle;
+(TMatrix*) scale:(float)InScale;
+(TMatrix*) scaleWithX:(float)InX Y:(float)InY Z:(float)InZ;
+(TMatrix*) multiplyA:(TMatrix*)InA withB:(TMatrix*)InB;

@end
