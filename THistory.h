
@class MAPDocument;

// ----------------------------------------------------------------------------
// One atomic action.  Selecting an entity, deleting a brush, etc.

@interface THistoryAction : NSObject
{
@public
	EHistoryActionType type;
	
	NSNumber* objectPickName;
	id dataObject;
	id data, dataNew, dataOld;
	NSNumber* ownerObjectPickName;
}

-(id) initWithType:(EHistoryActionType)InType Object:(id)InObject;
-(id) initWithType:(EHistoryActionType)InType Object:(id)InObject Owner:(id)InOwnerObject;
-(id) initWithType:(EHistoryActionType)InType Object:(id)InObject Data:(id)InData;
-(id) initWithType:(EHistoryActionType)InType Object:(id)InObject Owner:(id)InOwnerObject Data:(id)InData;
-(id) initWithType:(EHistoryActionType)InType Object:(id)InObject OldData:(id)InOldData NewData:(id)InNewData;

@end

// ----------------------------------------------------------------------------
// Represents one record.  Each transaction can
// contain multiple actions.

@interface THistoryRecord : NSObject
{
@public
	MAPDocument* map;
	NSMutableArray* actions;
	NSString* desc;					// Text description to use in menus/logs
}

-(id) initWithMAP:(MAPDocument*)InMap Desc:(NSString*)InDesc;
-(void) undo;
-(void) redo;

@end

// ----------------------------------------------------------------------------

@interface THistory : NSObject
{
@public
	MAPDocument* map;
	NSMutableArray* undoRecords;	// (THistoryRecord*)
	NSMutableArray* redoRecords;	// (THistoryRecord*)
	
@private
	THistoryRecord* currentRecord;
	int recordRefCount;

	// If YES, then the history system is undoing or redoing. In this state,
	// no new records or actions can be recorded (they will be ignored).
	BOOL bIsTransacting;		
}

-(id) initWithMAP:(MAPDocument*)InMap;
-(void) startRecord:(NSString*)InDesc;
-(void) stopRecord;
-(void) addAction:(THistoryAction*)InAction;
-(void) undo;
-(void) redo;

@end
