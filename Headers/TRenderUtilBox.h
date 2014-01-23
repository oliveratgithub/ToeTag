
@class TVec3D;

@interface TRenderUtilBox : NSObject
{

}

+(void) drawBoxWidth:(int)InW Height:(int)InH Depth:(int)InD;
+(void) drawBoxBBox:(TBBox*)InBBox;
+(void) drawBoxMin:(TVec3D*)InMin Max:(TVec3D*)InMax;

@end
