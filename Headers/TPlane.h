
@class TVec3D;
@class TFace;

@interface TPlane : NSObject
{
@public
	TVec3D* axisVectors[2];
	TVec3D* normal;
	float dist;
	
	// A vertex that is guaranteed to be on this plane.  This vertex lies in the middle
	// of the original 3 verts that were used to create this plane via initFromTriangle
	TVec3D* baseVert;
	
	// Temp variables using during MAP reading/CSG operations
	NSString* textureName;
	int uoffset, voffset, rotation;
	float uscale, vscale;
	
	// Temp variables used when breaking down concave meshes
	float vertexRatio;
	int facesCut;
}

-(id)initFromTriangleA:(TVec3D*)InA B:(TVec3D*)InB C:(TVec3D*)InC;
-(float) getDistanceFrom:(TVec3D*)InVector;
-(ESide) getVertexSide:(TVec3D*)InVector;
-(TFace*) getHugePolygon;
-(void) copyTexturingAttribsFrom:(TFace*)InFace;
-(BOOL) isAlmostEqualTo:(TPlane*)In;
-(TPlane*) flip;

@end
