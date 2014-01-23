
@class TVec3D;
@class TEntityClass;
@class MAPDocument;

@interface TEntity : NSObject
{
@public
	NSMutableDictionary* keyvalues;
	NSMutableArray* brushes;
	
	// Used for rendering
	TEntityClass* entityClass;
	
	// Used mainly for point entities
	TVec3D* location;
	TVec3D* rotation;
	
	// Read from and written to MAP file
	int spawnFlags;
	
	// Used for selections
	NSNumber* pickName;
	
	int quickGroupID;

}

-(NSMutableArray*) _visibleBrushes:(MAPDocument*)InMAP;

@property (readonly) NSMutableArray* _brushes;
@property (readonly) NSMutableArray* _trianglemeshes;

-(void) pushPickName;
-(NSNumber*) getPickName;
-(int) getQuickGroupID;
-(ESelectCategory) getSelectCategory;
-(void) selmgrWasUnselected;

-(void) drawForPick:(MAPDocument*)InMAP Category:(ESelectCategory)InCategory;
-(void) drawWireForPick:(MAPDocument*)InMAP Category:(ESelectCategory)InCategory;
-(void) finalizeInternals:(MAPDocument*)InMAP;
-(void) setKey:(NSString*)InKey Value:(NSString*)InValue;
-(NSString*) valueForKey:(NSString*)InKey defaultValue:(NSString*)InDefaultValue;
-(TVec3D*) valueVectorForKey:(NSString*)InKey defaultValue:(NSString*)InDefaultValue;
-(BOOL) isPointEntity;
-(NSMutableString*) exportToText:(BOOL)InIncludeBrushes;
-(NSMutableString*) exportKeyValuesToText;
-(void) matchUpKeyValuesToLiterals;
-(TVec3D*) getCenter;
-(TVec3D*) getExtents;
-(TBBox*) getBoundingBox;
-(void) drawSelectionHighlights:(MAPDocument*)InMAP;
-(void) drawTargetLineBoxFrom:(TVec3D*)InFrom To:(TVec3D*)InTo Box:(TBBox*)InBox;
-(void) markDirtyRenderArray;

@end
