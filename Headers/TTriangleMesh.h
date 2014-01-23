
// A triangle that contains information about the triangles around it

@interface TTriangle : NSObject
{
@public
	TFace* ownerFace;
	
	// The faces that connect to each edge of this triangle
	TFace* connectedFaces[3];
}

@end

// A collection of TFace (with 3 verts each) forming a mesh of connected triangles.

@interface TPolyMesh : TBrush
{
@public
}

-(NSMutableString*) exportToText;

@end
