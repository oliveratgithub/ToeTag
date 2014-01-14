
@class TEntity;
@class TBrush;
@class TTexture;
@class TVec3D;
@class TEntityClass;
@class TPlane;
@class TLevelView;
@class TTextureBrowserView;

@interface TBookmark : NSObject
{
@public
	TVec3D *perspectiveLocation, *perspectiveRotation, *orthoLocation;
	float orthoZoom;
}

-(id) initWithPerspectiveLocation:(TVec3D*)InPerspectiveLocation PerspectiveRotation:(TVec3D*)InPerspectiveRotation OrthoLocation:(TVec3D*)InOrthoLocation OrthoZoom:(float)InOrthoZoom;

@end

// ------------------------------------------------------

@interface TPlaneX : TPlane
{
@public
	int vertCount;
	float facesLeftUncut;
}

-(float) getWeight;

@end

// ------------------------------------------------------

@interface TEdgeX : NSObject
{
@public
	int start, end;		// Indices into the vertex cloud array
	
	NSMutableArray *connectedToStart, *connectedToEnd;

}

-(BOOL) isEqualTo:(TEdgeX*)In;

@end

// ------------------------------------------------------

@interface MAPDocument : NSDocument
{
@public
	NSMutableArray* entities;

	NSMutableDictionary* entityClasses;
	NSMutableArray* texturesFromWADs;
	NSMutableDictionary* textureLookUps;
	TTexture* defaultTexture;

	// Handy access pointers to the viewports
	IBOutlet TLevelView* perspectiveViewport;
	IBOutlet TOrthoLevelView* orthoViewport;
	IBOutlet TTextureBrowserView* textureBrowserView;
	
	// All viewports that show the level being edited
	NSMutableArray* levelViewports;
	
	// All OpenGL viewports that show textures
	NSMutableArray* textureViewports;
	
	// Configuration lines that were read from the MAP file.  These need to be processed
	// well after the MAP is actually loaded since the viewports aren't created initially.
	NSMutableArray* configLines;
	
	// Tracks selections made within this document (including textures in the texture browser)
	TSelection* selMgr;
	
	// Tracks which objects are hidden
	TVisibility* visMgr;
	
	// Undo/redo manager
	THistory* historyMgr;
	
	// Grid size for dragging operations
	float gridSz;
	
	// Verts in pointfile
	TRenderArray* pointFileRA;
	
	// Bookmarks
	NSMutableDictionary* bookmarks;

	// Filtering of visible entities
	EEntityFilter filterOption;
	BOOL bShowEditorOnlyEntities;
	
	// Flags for knowing when to refresh render data
	BOOL bLevelGeometryIsDirty;
	
	// The WAD to load when the map loading is finished.
	NSString* pendingWADName;
	
	// The last WAD that was loaded.  Prevents multiple loads of the same WAD.
	NSString* lastLoadedWADName;
}

-(NSMutableArray*) _visibleEntities;

-(TEntity*) findEntityByClassName:(NSString*)InClassName;
-(BOOL) doesTextureExist:(NSString*)InName;
-(TEntity*) getEntityByClassName:(NSString*)InClassName;
-(TEntity*) addNewEntity:(NSString*)InClassName;
-(void) destroyEntity:(TEntity*)InEntity;
-(void) destroyBrush:(TBrush*)InBrush InEntity:(TEntity*)InEntity;
-(void) destroyObject:(NSObject*)InObject;
-(TEntityClass*) getEntityClassFor:(NSObject*)InObject;
-(TEntity*) getEntityFor:(NSObject*)InObject;
-(void) destroyAllSelected;
-(id) findObjectByPickName:(NSNumber*)InPickName;
-(TVec3D*) getLocationForPickName:(NSNumber*)InPickName;
-(TTexture*) findTextureByName:(NSString*)InName;
-(void) removeTextureByName:(NSString*)InName;
-(void) sortTexturesBySize;
-(void) clearLoadedTextures;
-(BOOL) loadWAD:(NSString*)InName;
-(BOOL) loadWADFullPath:(NSString*)InFilename;
-(void) saveWADFullPath:(NSString*)InFilename;
-(void) redrawLevelViewports;
-(void) redrawTextureViewports;
-(void) registerTexturesWithViewports:(BOOL)InRedrawViewports;
-(void) DragSelectionsBy:(TVec3D*)InOffset;
-(TVec3D*) getUsableOrigin;
-(void) rotateSelectionsByX:(float)InPitch Y:(float)InYaw Z:(float)InRoll;
-(void) maybeCreateNewQuickGroupID;
-(void) importEntitiesFromText:(NSMutableString*)InText SelectAfterImport:(BOOL)InSelectAfterImport;
-(void) importSingleEntityFromText:(NSMutableString*)InText SelectAfterImport:(BOOL)InSelectAfterImport;
-(void) duplicateSelected;
-(void) cut:(id)sender;
-(void) copy:(id)sender;
-(void) paste:(id)sender;
-(void) applySelectedTexture;
-(void) offsetSelectedTexturesByU:(int)InU V:(int)InV;
-(void) rotateSelectedTexturesBy:(int)InAngle;
-(void) setSelectedTextureRotation:(int)InAngle;
-(void) scaleSelectedTexturesByU:(float)InU V:(float)InV;
-(void) resetSelectedFacesUOffset:(BOOL)InUOffset VOffset:(BOOL)InVOffset Rotation:(BOOL)InRotation UScale:(BOOL)InUScale VScale:(BOOL)InVScale;
-(void) refreshInspectors;
-(void) createEntityFromSelections:(NSString*)InEntityClassName;
-(NSMutableArray*) getTexturesForWritingToWAD;
-(int) snapScalarToGrid:(float)InValue;
-(TVec3D*) snapVtxToGrid:(TVec3D*)InValue;
-(void) deleteEmptyBrushEntities;
-(void) synchronizeTextureBrowserWithSelectedFaces;
-(void) scrollToSelectedTexture;
-(void) selectAll;
-(void) selectMatching;
-(void) selectMatchingWithinEntity;
-(void) deselect;
-(void) csgCreateClipBrush;
-(void) csgMergeConvexHull;
-(TBrush*) createConvexHull:(NSMutableArray*)InBrushes useBrushPlanesFirst:(BOOL)InUseBrushPlanesFirst;
-(void) csgMergeBoundingBox;
-(void) csgSubtractFromWorld;
-(void) subtractBrush:(TBrush*)InCarver FromBrush:(TBrush*)InBrush Entity:(TEntity*)InEntity;
-(void) csgClipAgainstWorld;
-(void) csgBevel;
-(void) csgExtrude;
-(void) csgSplit;
-(void) csgTriangulateFan;
-(void) csgTriangulateFromCenter;
-(void) csgOptimize;
-(void) csgHollowSelected;
-(void) csgClipSelectedBrushesAgainstPlane:(TPlane*)InPlane flippedPlane:(TPlane*)InFlippedPlane split:(BOOL)InSplit;
-(TEntity*) findBestSelectedBrushBasedEntity;
-(void) playLevelInQuake;
-(void) loadPointFile;
-(void) clearPointFile;
-(void) drawPointFile;
-(void) jumpCamerasTo:(TVec3D*)InLocation;
-(void) purgeBadBrushesAndEntities;
-(TEntityClass*) findEntityClassByName:(NSString*)InName;
-(void) populateCreateEntityMenu;
-(void) refreshEntityClasses;
-(void) setBookmark:(NSString*)InKey;
-(void) jumpToBookmark:(NSString*)InKey;
-(void) quantizeVerts;
-(void) mirrorSelectedX:(BOOL)InX Y:(BOOL)InY Z:(BOOL)InZ;
-(void) markAllTexturesDirtyRenderArray;
-(void) hideSelected;
-(void) isolateSelected;
-(void) showAll;

@end
