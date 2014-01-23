
// ----------------------------------------------------------------------------

@implementation THistoryAction

-(id) initWithType:(EHistoryActionType)InType Object:(id)InObject
{
	[super init];
	
	type = InType;
	objectPickName = [[InObject getPickName] copy];
	dataObject = InObject;
	
	return self;
}

-(id) initWithType:(EHistoryActionType)InType Object:(id)InObject Owner:(id)InOwnerObject
{
	[super init];
	
	type = InType;
	objectPickName = [[InObject getPickName] copy];
	dataObject = InObject;
	ownerObjectPickName = [[InOwnerObject getPickName] copy];
	
	return self;
}

-(id) initWithType:(EHistoryActionType)InType Object:(id)InObject Data:(id)InData
{
	[super init];
	
	type = InType;
	objectPickName = [[InObject getPickName] copy];
	dataObject = InObject;
	data = InData;
	
	return self;
}

-(id) initWithType:(EHistoryActionType)InType Object:(id)InObject Owner:(id)InOwnerObject Data:(id)InData
{
	[super init];
	
	type = InType;
	objectPickName = [[InObject getPickName] copy];
	dataObject = InObject;
	ownerObjectPickName = [[InOwnerObject getPickName] copy];
	data = InData;
	
	return self;
}

-(id) initWithType:(EHistoryActionType)InType Object:(id)InObject OldData:(id)InOldData NewData:(id)InNewData
{
	[super init];
	
	type = InType;
	objectPickName = [[InObject getPickName] copy];
	dataObject = InObject;
	dataOld = [InOldData mutableCopy];
	dataNew = [InNewData mutableCopy];
	
	return self;
}

@end

// ----------------------------------------------------------------------------

@implementation THistoryRecord

-(id) initWithMAP:(MAPDocument*)InMap Desc:(NSString*)InDesc
{
	[super init];
	
	map = InMap;
	desc = [InDesc mutableCopy];
	actions = [NSMutableArray new];
	
	return self;
}

-(void) undo
{
	int x;
	for( x = [actions count] - 1 ; x > -1 ; x-- )
	{
		THistoryAction* A = [actions objectAtIndex:x];
		
		switch( A->type )
		{
			case TUAT_SelectObject:
			{
				[map->selMgr removeSelection:[map findObjectByPickName:A->objectPickName]];
			}
			break;

			case TUAT_UnselectObject:
			{
				[map->selMgr addSelection:[map findObjectByPickName:A->objectPickName]];
			}
			break;

			case TUAT_HideObject:
			{
				[map->visMgr show:[map findObjectByPickName:A->objectPickName]];
			}
			break;
				
			case TUAT_ShowObject:
			{
				[map->visMgr hide:[map findObjectByPickName:A->objectPickName]];
			}
			break;
				
			case TUAT_DeleteBrush:
			{
				TBrush* B = [A->dataObject mutableCopy];
				[B finalizeInternals];
				
				[((TEntity*)[map findObjectByPickName:A->ownerObjectPickName])->brushes addObject:B];
			}
			break;

			case TUAT_DeleteEntity:
			{
				[map->entities addObject:[A->dataObject mutableCopy]];
			}
			break;
				
			case TUAT_CreateEntity:
			{
				[map destroyObject:[map findObjectByPickName:A->objectPickName]];
			}
			break;
				
			case TUAT_DragEntity:
			{
				TEntity* ent = (TEntity*)A->dataObject;
				ent->location = [TVec3D addA:ent->location andB:[TVec3D scale:(TVec3D*)A->data By:-1]];
			}
			break;
				
			case TUAT_AddEntity:
			{
				[map destroyObject:[map findObjectByPickName:A->objectPickName]];
			}
			break;

			case TUAT_AddBrush:
			{
				[map destroyObject:[map findObjectByPickName:A->objectPickName]];
			}
			break;

			case TUAT_DragBrush:
			{
				TBrush* brush = [map findObjectByPickName:A->objectPickName];
				[brush dragBy:[TVec3D scale:(TVec3D*)A->data By:-1] MAP:map];
			}
			break;
				
			case TUAT_DragVertex:
			{
				TBrush* brush = [map findObjectByPickName:A->ownerObjectPickName];
				TVec3D* vtx = [map findObjectByPickName:A->objectPickName];
				
				vtx->x -= ((TVec3D*)A->data)->x;
				vtx->y -= ((TVec3D*)A->data)->y;
				vtx->z -= ((TVec3D*)A->data)->z;
				
				[brush generateTexCoords:map];
			}
			break;
				
			case TUAT_ModifyFaceTextureName:
			{
				TFace* face = (TFace*)A->dataObject;
				face->textureName = [A->dataOld mutableCopy];
				[face generateTexCoords:map];
			}
			break;
				
			case TUAT_RotateEntity:
			{
				TEntity* entity = (TEntity*)A->dataObject;
				entity->rotation = [A->dataOld mutableCopy];
				[entity matchUpKeyValuesToLiterals];
			}
			break;
				
			case TUAT_ModifyFaceVerts:
			{
				TFace* face = (TFace*)A->dataObject;
				face->verts = [A->dataOld mutableCopy];
				[face generateTexCoords:map];
			}
			break;
			
			case TUAT_ChangeEntityClassname:
			{
				TEntity* entity = (TEntity*)A->dataObject;
				[entity setKey:@"classname" Value:[A->dataOld mutableCopy]];
				[entity finalizeInternals:[TGlobal getMAP]];
			}
			break;
				
			case TUAT_AddBrushToEntity:
			{
				TEntity* entity = [map findObjectByPickName:A->ownerObjectPickName];
				TBrush* brush = [map findObjectByPickName:A->objectPickName];
				
				[entity->brushes removeObject:brush];
			}
			break;
				
			case TUAT_RemoveBrushFromEntity:
			{
				TEntity* entity = [map findObjectByPickName:A->ownerObjectPickName];
				TBrush* brush = [map findObjectByPickName:A->objectPickName];
				[brush finalizeInternals];
				
				[entity->brushes addObject:brush];
			}
			break;

			case TUAT_ModifyFaceTextureAttribs:
			{
				TFace* face = (TFace*)A->dataObject;
				face->textureName = [[((NSArray*)A->dataOld) objectAtIndex:0] mutableCopy];
				face->uoffset = [[((NSArray*)A->dataOld) objectAtIndex:1] intValue];
				face->voffset = [[((NSArray*)A->dataOld) objectAtIndex:2] intValue];
				face->rotation = [[((NSArray*)A->dataOld) objectAtIndex:3] intValue];
				face->uscale = [[((NSArray*)A->dataOld) objectAtIndex:4] floatValue];
				face->vscale = [[((NSArray*)A->dataOld) objectAtIndex:5] floatValue];
				
				[face generateTexCoords:map];
			}
			break;
		}
	}
	
	[map markAllTexturesDirtyRenderArray];
}

-(void) redo
{
	for( THistoryAction* A in actions )
	{
		switch( A->type )
		{
			case TUAT_SelectObject:
			{
				[map->selMgr addSelection:[map findObjectByPickName:A->objectPickName]];
			}
			break;

			case TUAT_UnselectObject:
			{
				[map->selMgr removeSelection:[map findObjectByPickName:A->objectPickName]];
			}
			break;
				
			case TUAT_HideObject:
			{
				[map->visMgr hide:[map findObjectByPickName:A->objectPickName]];
			}
			break;
				
			case TUAT_ShowObject:
			{
				[map->visMgr show:[map findObjectByPickName:A->objectPickName]];
			}
			break;
				
			case TUAT_DeleteBrush:
			{
				[map destroyObject:[map findObjectByPickName:A->objectPickName]];
			}
			break;
				
			case TUAT_DeleteEntity:
			{
				[map destroyObject:[map findObjectByPickName:A->objectPickName]];
			}
			break;
				
			case TUAT_CreateEntity:
			{
				[map->entities addObject:[A->dataObject mutableCopy]];
			}
			break;
				
			case TUAT_DragEntity:
			{
				TEntity* ent = (TEntity*)A->dataObject;
				ent->location = [TVec3D addA:ent->location andB:(TVec3D*)A->data];
			}
			break;
				
			case TUAT_AddEntity:
			{
				[map->entities addObject:A->dataObject];
			}
			break;
				
			case TUAT_AddBrush:
			{
				TEntity* ent = [map findObjectByPickName:A->ownerObjectPickName];
				TBrush* brush = [(TBrush*)A->dataObject mutableCopy];
				[brush finalizeInternals];
				
				[ent->brushes addObject:brush];
			}
			break;

			case TUAT_DragBrush:
			{
				TBrush* brush = [map findObjectByPickName:A->objectPickName];
				[brush dragBy:(TVec3D*)A->data MAP:map];
			}
			break;	
				
			case TUAT_DragVertex:
			{
				TBrush* brush = [map findObjectByPickName:A->ownerObjectPickName];
				TVec3D* vtx = [map findObjectByPickName:A->objectPickName];
				
				vtx->x += ((TVec3D*)A->data)->x;
				vtx->y += ((TVec3D*)A->data)->y;
				vtx->z += ((TVec3D*)A->data)->z;
				
				[brush generateTexCoords:map];
			}
			break;
				
			case TUAT_ModifyFaceTextureName:
			{
				TFace* face = (TFace*)A->dataObject;
				
				face->textureName = [A->dataNew mutableCopy];
				[face generateTexCoords:map];
			}
			break;
				
			case TUAT_RotateEntity:
			{
				TEntity* entity = (TEntity*)A->dataObject;
				entity->rotation = [A->dataNew mutableCopy];
				[entity matchUpKeyValuesToLiterals];
			}
			break;

			case TUAT_ModifyFaceVerts:
			{
				TFace* face = (TFace*)A->dataObject;
				face->verts = [A->dataNew mutableCopy];
				[face generateTexCoords:map];
			}
			break;
				
			case TUAT_ChangeEntityClassname:
			{
				TEntity* entity = (TEntity*)A->dataObject;
				[entity setKey:@"classname" Value:[A->dataNew mutableCopy]];
				[entity finalizeInternals:[TGlobal getMAP]];
			}
			break;
		
			case TUAT_AddBrushToEntity:
			{
				TEntity* entity = [map findObjectByPickName:A->ownerObjectPickName];
				TBrush* brush = [map findObjectByPickName:A->objectPickName];
				[brush finalizeInternals];
				
				[entity->brushes addObject:brush];
			}
			break;
			
			case TUAT_RemoveBrushFromEntity:
			{
				TEntity* entity = [map findObjectByPickName:A->ownerObjectPickName];
				TBrush* brush = [map findObjectByPickName:A->objectPickName];
				[brush finalizeInternals];
				
				[entity->brushes removeObject:brush];
			}
			break;
				
			case TUAT_ModifyFaceTextureAttribs:
			{
				TFace* face = (TFace*)A->dataObject;
				face->textureName = [[((NSArray*)A->dataNew) objectAtIndex:0] mutableCopy];
				face->uoffset = [[((NSArray*)A->dataNew) objectAtIndex:1] intValue];
				face->voffset = [[((NSArray*)A->dataNew) objectAtIndex:2] intValue];
				face->rotation = [[((NSArray*)A->dataNew) objectAtIndex:3] intValue];
				face->uscale = [[((NSArray*)A->dataNew) objectAtIndex:4] floatValue];
				face->vscale = [[((NSArray*)A->dataNew) objectAtIndex:5] floatValue];
				
				[face generateTexCoords:map];
			}
			break;
		}
	}
	
	[map markAllTexturesDirtyRenderArray];
}

@end

// ----------------------------------------------------------------------------

@implementation THistory

-(id) initWithMAP:(MAPDocument*)InMap
{
	[super init];
	
	map = InMap;
	undoRecords = [NSMutableArray new];
	redoRecords = [NSMutableArray new];
	
	currentRecord = nil;
	recordRefCount = 0;
	
	return self;
}

// Creates a new undo record

-(void) startRecord:(NSString*)InDesc
{
	if( bIsTransacting )
	{
		return;
	}
	
	recordRefCount++;
	
	if( currentRecord != nil )
	{
		return;
	}
	
	currentRecord = [[THistoryRecord alloc] initWithMAP:map Desc:InDesc];
	[undoRecords addObject:currentRecord];
	
	// Since we are starting a new undo record, the redo buffer needs to be cleared.
	
	[redoRecords removeAllObjects];
}

-(void) stopRecord
{
	if( currentRecord == nil || bIsTransacting )
	{
		return;
	}
	
	recordRefCount--;
	
	if( recordRefCount < 1 )
	{
		// Check the record and see if it has any actions in it.  A record with no
		// actions is not worth keeping and will be deleted.
		
		if( [currentRecord->actions count] == 0 )
		{
			[undoRecords removeLastObject];
		}
		else
		{
			[map updateChangeCount:NSChangeDone];
			[map markAllTexturesDirtyRenderArray];
		}
		
		recordRefCount = 0;
		currentRecord = nil;
	}
}

-(void) addAction:(THistoryAction*)InAction
{
	// This means we are running some code that might record history actions in an
	// undo buffer sometimes and sometimes not.  That's valid.
	
	if( currentRecord == nil || bIsTransacting )
	{
		return;
	}
	
	[currentRecord->actions addObject:InAction];
}

-(void) undo
{
	if( [undoRecords count] == 0 )
	{
		return;
	}
	
	bIsTransacting = YES;
	
	// Grab the last undo record from the undo list
	
	THistoryRecord* rec = [undoRecords lastObject];
	[undoRecords removeLastObject];
	
	// Add that record to the end of the redo list
	
	[redoRecords addObject:rec];
	
	// Undo the record
	
	[rec undo];
	
	// Finish up
	
	[map redrawLevelViewports];
	
	bIsTransacting = NO;

	[map updateChangeCount:NSChangeUndone];
}

-(void) redo
{
	if( [redoRecords count] == 0 )
	{
		return;
	}
	
	bIsTransacting = YES;
	
	// Grab the last undo record from the redo list
	
	THistoryRecord* rec = [redoRecords lastObject];
	[redoRecords removeLastObject];
	
	// Add that record to the end of the undo list
	
	[undoRecords addObject:rec];
	
	// Redo the record
	
	[rec redo];
	
	// Finish up
	
	[map redrawLevelViewports];

	bIsTransacting = NO;

	[map updateChangeCount:NSChangeDone];
}

@end
