
@class MAPDocument;
@class TEntityClass;

@interface TSelection : NSObject
{
@public
	NSMutableDictionary* selections;
	NSMutableArray* orderedSelections;
	MAPDocument* map;
}

-(id) initWithMAP:(MAPDocument*)InMap;
-(BOOL) hasNeededSelectors:(id)InObject;
-(void) toggleSelection:(id)InObject;
-(void) addSelection:(id)InObject;
-(void) removeSelection:(id)InObject;
-(void) unselectAll:(ESelectCategory)InCategory;
-(BOOL) isSelected:(id)InObject;
-(BOOL) hasSelectionsInCategory:(ESelectCategory)InCategory;
-(NSMutableArray*) getSelections:(ESelectCategory)InCategory;
-(NSString*) getSelectedTextureName;
-(TEntityClass*) getSelectedEntityClass;
-(NSMutableArray*) getSelectedEntityClasses;
-(NSMutableArray*) getSelectedBrushes;
-(NSMutableArray*) getSelectedEntities;
-(void) markTexturesOnSelectedDirtyRenderArray;

@end
