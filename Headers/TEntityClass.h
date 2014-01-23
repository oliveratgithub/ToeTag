
// ------------------------------------------------------
// A class read from a .DEF file definition.  These are the entity types that can be added to a level.

@interface TEntityClass : NSObject
{
@public
	NSString* name;
	NSString* modelName;				// Name of an MDL file associated with this class
	NSMutableArray* emodelChoices;		// A list of EModel choices that this entity class could potentially display
	TVec3D *color, *szMin, *szMax;
	NSMutableArray* descText;
	NSMutableDictionary* spawnFlags;
	BOOL bEditorOnly;					// Used for filtering editor only entity classes in the viewports
	
	// Rendering
	NSMutableArray* boundingBoxFaces;
	
	// The rendering components that are attached to this entity class
	NSMutableArray* renderComponenents;
}

-(float) getSuggestedAlpha;
-(int) getWidth;
-(int) getHeight;
-(int) getDepth;
-(void) finalizeInternals;
-(void) draw:(MAPDocument*)InMAP Entity:(TEntity*)InEntity;
-(void) drawSelectionHighlights:(MAPDocument*)InMAP Entity:(TEntity*)InEntity;
-(void) drawOrthoSelectionHighlights:(MAPDocument*)InMAP Entity:(TEntity*)InEntity;
-(void) drawWire:(MAPDocument*)InMAP Entity:(TEntity*)InEntity;
-(void) drawForPick:(TEntity*)InEntity MAP:(MAPDocument*)InMAP Category:(ESelectCategory)InCategory;
-(BOOL) isPointClass;
-(BOOL) hasArrowComponent;
-(BOOL) hasMDLComponent;

@end
