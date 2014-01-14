
@class TFace;

@interface TEdgeFull : NSObject
{
@public
	TVec3D* verts[2];
}

-(id) initWithVert0:(TVec3D*)InVert0 Vert1:(TVec3D*)InVert1;
-(void) swapVerts;
-(BOOL) sharesVertWith:(TEdgeFull*)InE;

@end
