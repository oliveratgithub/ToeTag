
@class TVec3D;
@class MAPDocument;
@class TBrush;

@interface TBrushBuilderWedge : NSObject
{

}

-(TBrush*) build:(MAPDocument*)InMAP Location:(TVec3D*)InLocation Extents:(TVec3D*)InExtents Args:(NSArray*)InArgs;

@end
