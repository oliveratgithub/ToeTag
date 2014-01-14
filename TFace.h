
@class TVec3D;
@class TPlane;
@class TTexture;
@class MAPDocument;
@class TEdgeFull;

// A clockwise winding of points.

@interface TFace : NSObject
{
@public
	NSString* textureName;
	
	int uoffset, voffset, rotation;
	float uscale, vscale;
	
	NSMutableArray* verts;
	float lightValue, area;
	NSNumber* pickName;
	TPlane* normal;
	NSMutableArray* edges;
	
	// Temp variable used when breaking down triangle meshes into convex brushes
	TTriangle* ownerTriangle;
	int index;
}

-(void) pushPickName;
-(NSNumber*) getPickName;
-(ESelectCategory) getSelectCategory;
-(void) selmgrWasUnselected;

-(void) textureAxisFromNormal:(TVec3D*)InNormal OutU:(TVec3D**)OutU OutV:(TVec3D**)OutV;
-(void) generateTexCoords:(MAPDocument*)InMAP;
-(void) finalizeInternals;
-(int) splitWithPlane:(TPlane*)InPlane Front:(TFace**)InFront Back:(TFace**)InBack;
-(void) drawSelectionHighlights:(MAPDocument*)InMAP;
-(void) drawOrthoSelectionHighlights:(MAPDocument*)InMAP;
-(void) drawHighlightedOutline:(MAPDocument*)InMAP Color:(TVec3D*)InColor;
-(void) drawFlatFace:(MAPDocument*)InMAP Color:(TVec3D*)InColor;
-(void) computeArea;
-(TVec3D*) getCenter;
-(TFace*) flip;
-(TFace*) reverseVerts;
-(void) copyTexturingAttribsFrom:(TFace*)InFace;
-(void) maintainTextureLockAfterDrag:(TVec3D*)InDelta;
-(TPlane*) getPlane;
-(int) getVertIdx:(TVec3D*)InV;
-(BOOL) containsFullEdge:(TEdgeFull*)InFullEdge;
-(void) markDirtyRenderArray;

@property (readwrite,copy) NSString* textureName;

@end
