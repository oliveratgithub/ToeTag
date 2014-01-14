
@class MAPDocument;
@class TEdge;

// A collection of TFace's that form a convex volume.

@interface TBrush : NSObject
{
@public
	NSNumber* pickName;
	NSMutableArray* faces;
	int quickGroupID;
	
	// If YES, then this brush will be written to the MAP file but not read from it.  This will set the tag "TB:1" on the brush
	// in the MAP and ToeTag will not load it back in.
	BOOL bTemporaryBrush;
}

+(TBrush*) createBrushFromPlanes:(NSMutableArray*)InClippingPlanes MAP:(MAPDocument*)InMAP;

-(void) generateTexCoords:(MAPDocument*)InMAP;
-(void) drawSelectionHighlights:(MAPDocument*)InMAP;
-(void) drawOrthoSelectionHighlights:(MAPDocument*)InMAP;
-(void) drawHighlightedOutline:(MAPDocument*)InMAP Color:(TVec3D*)InColor;
-(void) drawVerts:(TVec3D*)InColor MAP:(MAPDocument*)InMAP;
-(void) drawEdgesForPick;
-(void) drawVertsForPick;
-(void) drawFlatFaces:(MAPDocument*)InMAP Color:(TVec3D*)InColor;
-(NSMutableString*) exportToText;
-(void) dragBy:(TVec3D*)InOffset MAP:(MAPDocument*)InMAP;
-(TVec3D*) getCenter;
-(TVec3D*) getExtents;
-(TBBox*) getBoundingBox;
-(NSMutableArray*) getVertsNear:(TVec3D*)InVert;
-(void) selectVertsNear:(TVec3D*)InVert MAP:(MAPDocument*)InMAP;
-(TBrush*) carveBrushAgainstPlane:(TPlane*)InPlane MAP:(MAPDocument*)InMAP;
-(void) generateCappingFace:(MAPDocument*)InMAP referencePlane:(TPlane*)InPlane;
-(void) pushPickName;
-(NSNumber*) getPickName;
-(int) getQuickGroupID;
-(ESelectCategory) getSelectCategory;
-(void) selmgrWasUnselected;
-(BOOL) doesPlaneIntersect:(TPlane*)InPlane;
-(BOOL) doesFaceIntersect:(TFace*)InFace;
-(BOOL) isBehindOrOn:(TPlane*)InPlane;
-(BOOL) isPointInside:(TVec3D*)InVtx;
-(BOOL) doesBrushIntersect:(TBrush*)InBrush;
-(TVec3D*) getVertexNormal:(TVec3D*)InVtx;
-(NSMutableArray*) getFacesConnectedToVertex:(TVec3D*)InVtx;
-(NSMutableArray*) getUniqueSelectedEdges:(MAPDocument*)InMAP;
-(void) finalizeInternals;
-(void) clearPickNames;
-(void) snapToUnitGrid;
-(TFace*) findFaceWithMatchingEdge:(TEdge*)InEdge IgnoreFace:(TFace*)InIgnoreFace;
-(BOOL) isConvex;
-(NSMutableArray*) getUniqueVertices;
-(NSMutableArray*) getUniqueFullEdges;
-(void) markDirtyRenderArray;

@end
