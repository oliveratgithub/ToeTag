
@implementation TSelection

// Objects that wish to work with the selection system need to implement these selectors:
//
// Pushes the pick name onto the OpenGL stack.  If the object doesn't have a pick name
// it will generate one before pushing.
// -(void) pushPickName;
//
// Returns the OpenGL pick name that was generated for the object.  If the object doesn't have a pick name
// it will generate one before returning.
// -(NSNumber*) getPickName;
//
// Returns the category that this item fits into (see ESelectCategory definition)
// -(ESelectCategory) getSelectCategory;
//
// Called whenever the object is unselected.  Allows for clean up within the object.
// -(void) selmgrWasUnselected;

-(id) initWithMAP:(MAPDocument*)InMap
{
	[super init];
	
	selections = [NSMutableDictionary new];
	orderedSelections = [NSMutableArray new];
	map = InMap;
	
	return self;
}

// Checks InObject to see if it has the proper selectors inside of it to
// work nicely with the selection system.

-(BOOL) hasNeededSelectors:(id)InObject
{
	if( [InObject respondsToSelector:@selector(getSelectCategory)] == YES
		&& [InObject respondsToSelector:@selector(getPickName)] == YES
		&& [InObject respondsToSelector:@selector(pushPickName)] == YES
		&& [InObject respondsToSelector:@selector(selmgrWasUnselected)] == YES )
	{
		return YES;
	}
	
	return NO;
}

-(void) toggleSelection:(id)InObject
{
	//if( [self hasNeededSelectors:InObject] == NO )	return;
	
	if( [self isSelected:InObject] )
	{
		[self removeSelection:InObject];
	}
	else
	{
		[self addSelection:InObject];
	}
}

-(void) addSelection:(id)InObject
{
	//if( [self hasNeededSelectors:InObject] == NO )	return;
	
	if( [self isSelected:InObject] == NO )
	{
		[map->historyMgr startRecord:@"Add Selection"];
		[map->historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_SelectObject Object:InObject]];

		[selections setObject:InObject forKey:[InObject getPickName]];
		[orderedSelections addObject:InObject];

		[map->historyMgr stopRecord];
	}
}

-(void) removeSelection:(id)InObject
{
	//if( [self hasNeededSelectors:InObject] == NO )	return;
	
	if( [self isSelected:InObject] )
	{
		[map->historyMgr startRecord:@"Remove Selection"];
		[map->historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_UnselectObject Object:InObject]];
		
		[selections removeObjectForKey:[InObject getPickName]];
		[InObject selmgrWasUnselected];
		
		[orderedSelections removeObject:InObject];
		
		[map->historyMgr stopRecord];
	}
}

// Unselects all objects in a category

-(void) unselectAll:(ESelectCategory)InCategory
{
	NSDictionary* sels = [selections copy];
	NSEnumerator *enumerator = [sels objectEnumerator];
	id obj;
	
	[map->historyMgr startRecord:@"Unselect All"];
	
	while( obj = [enumerator nextObject] )
	{
		if( [obj getSelectCategory] == InCategory )
		{
			[self removeSelection:obj];
		}
	}
	
	[map->historyMgr stopRecord];
}

// Returns whether or not InObject is in the selection list

-(BOOL) isSelected:(id)InObject
{
	//if( [self hasNeededSelectors:InObject] == NO )	return NO;
	
	if( [selections objectForKey:[InObject getPickName]] != nil )
	{
		return YES;
	}
			 
	return NO;
}

-(BOOL) hasSelectionsInCategory:(ESelectCategory)InCategory
{
	NSEnumerator *enumerator = [selections objectEnumerator];
	id obj;
	
	while( obj = [enumerator nextObject] )
	{
		if( [obj getSelectCategory] == InCategory )
		{
			return YES;
		}
	}
	
	return NO;
}

-(NSMutableArray*) getSelections:(ESelectCategory)InCategory
{
	NSMutableArray* sels = [NSMutableArray new];
	
	for( id obj in orderedSelections )
	{
		if( [obj getSelectCategory] == InCategory )
		{
			[sels addObject:obj];
		}
	}
			
	return sels;
}

// A special case function that looks for the one selected texture in the
// list here and returns its name.

-(NSString*) getSelectedTextureName
{
	NSMutableArray* sels = [self getSelections:TSC_Texture];
	
	if( [sels count] > 0 )
	{
		return [((TTexture*)[sels objectAtIndex:0])->name mutableCopy];
	}
	
	return @"TOETAGDEFAULT";
}

// Looks at all the selected entities and returns a TEntityClass* if there
// is one kind of entity selected or nil if multiple classes are selected.

-(TEntityClass*) getSelectedEntityClass
{
	NSMutableArray* sels = [self getSelections:TSC_Level];
	TEntityClass* ec = nil;
	
	for( NSObject* O in sels )
	{
		TEntityClass* eclass = [map getEntityClassFor:O];
		
		if( ec == nil )
		{
			ec = eclass;
		}
		else
		{
			if( ec != eclass )
			{
				ec = nil;
				break;
			}
		}
	}
	
	return ec;
}

// Returns an array of all the unique entity classes that are selected

-(NSMutableArray*) getSelectedEntityClasses
{
	NSMutableArray* sels = [self getSelections:TSC_Level];
	NSMutableArray* entityClasses = [NSMutableArray new];
	
	for( NSObject* O in sels )
	{
		TEntityClass* eclass = [map getEntityClassFor:O];
		
		if( [entityClasses containsObject:eclass] == NO )
		{
			[entityClasses addObject:eclass];
		}
	}
	
	return entityClasses;
}

// Returns an array of all the selected brushes

-(NSMutableArray*) getSelectedBrushes
{
	NSMutableArray* sels = [self getSelections:TSC_Level];
	NSMutableArray* brushes = [NSMutableArray new];
	
	for( NSObject* O in sels )
	{
		if( [O isKindOfClass:[TBrush class]] )
		{
			TBrush* brush = (TBrush*)O;
			
			if( [brushes containsObject:brush] == NO )
			{
				[brushes addObject:brush];
			}
		}
	}
	
	return brushes;
}

// Returns an array of all the unique entities that are selected

-(NSMutableArray*) getSelectedEntities
{
	NSMutableArray* sels = [self getSelections:TSC_Level];
	NSMutableArray* entities = [NSMutableArray new];
	
	for( NSObject* O in sels )
	{
		TEntity* entity = [map getEntityFor:O];
		
		if( [entities containsObject:entity] == NO )
		{
			[entities addObject:entity];
		}
	}
	
	return entities;
}

// Marks the textures on selected entities as dirty render array

-(void) markTexturesOnSelectedDirtyRenderArray
{
	NSMutableArray* sels = [self getSelections:TSC_Level];
	
	for( NSObject* O in sels )
	{
		TEntity* E = [map getEntityFor:O];

		for( TBrush* B in E->brushes )
		{
			for( TFace* F in B->faces )
			{
				[map findTextureByName:F->textureName]->bDirtyRenderArray = YES;
			}
		}
	}
}

@end
