
@implementation TEntityInspectorDelegate

-(void) awakeFromNib
{
	mapBitToCheck = [NSMutableDictionary new];
	mapBitToText = [NSMutableDictionary new];
	
	[mapBitToCheck setObject:SFCheck1 forKey:[NSNumber numberWithInt:1]];
	[mapBitToCheck setObject:SFCheck2 forKey:[NSNumber numberWithInt:2]];
	[mapBitToCheck setObject:SFCheck4 forKey:[NSNumber numberWithInt:4]];
	[mapBitToCheck setObject:SFCheck8 forKey:[NSNumber numberWithInt:8]];
	[mapBitToCheck setObject:SFCheck16 forKey:[NSNumber numberWithInt:16]];
	[mapBitToCheck setObject:SFCheck32 forKey:[NSNumber numberWithInt:32]];
	[mapBitToCheck setObject:SFCheck64 forKey:[NSNumber numberWithInt:64]];
	[mapBitToCheck setObject:SFCheck128 forKey:[NSNumber numberWithInt:128]];
	[mapBitToCheck setObject:SFCheck256 forKey:[NSNumber numberWithInt:256]];
	[mapBitToCheck setObject:SFCheck512 forKey:[NSNumber numberWithInt:512]];
	[mapBitToCheck setObject:SFCheck1024 forKey:[NSNumber numberWithInt:1024]];
	
	[mapBitToText setObject:SFText1 forKey:[NSNumber numberWithInt:1]];
	[mapBitToText setObject:SFText2 forKey:[NSNumber numberWithInt:2]];
	[mapBitToText setObject:SFText4 forKey:[NSNumber numberWithInt:4]];
	[mapBitToText setObject:SFText8 forKey:[NSNumber numberWithInt:8]];
	[mapBitToText setObject:SFText16 forKey:[NSNumber numberWithInt:16]];
	[mapBitToText setObject:SFText32 forKey:[NSNumber numberWithInt:32]];
	[mapBitToText setObject:SFText64 forKey:[NSNumber numberWithInt:64]];
	[mapBitToText setObject:SFText128 forKey:[NSNumber numberWithInt:128]];
	[mapBitToText setObject:SFText256 forKey:[NSNumber numberWithInt:256]];
	[mapBitToText setObject:SFText512 forKey:[NSNumber numberWithInt:512]];
	[mapBitToText setObject:SFText1024 forKey:[NSNumber numberWithInt:1024]];
	
	keyvalueStrings = [NSMutableArray new];
}

-(void) refreshInspectors
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	TEntityClass* ec = [map->selMgr getSelectedEntityClass];
	
	entityClasses = [map->selMgr getSelectedEntityClasses];
	selectedEntities = [map->selMgr getSelectedEntities];
	
	// Key/Value panel
	
	NSMutableDictionary* kvwork = [NSMutableDictionary new];
	
	for( TEntity* E in selectedEntities )
	{
		NSEnumerator *enumerator = [E->keyvalues keyEnumerator];
		id obj;
		
		while( obj = [enumerator nextObject] )
		{
			NSString *key, *value;
			
			key = obj;
			value = [E->keyvalues valueForKey:key];
			
			// Certain key/values are a hassle to have the user editing them directly so they are excluded
			
			if( [key isEqualToString:@"spawnflags"]
				|| [key isEqualToString:@"origin"] )
			{
				continue;
			}
			
			NSString* workValue = [kvwork objectForKey:key];
			if( workValue == nil )
			{
				[kvwork setObject:value forKey:key];
			}
			else
			{
				if( [[kvwork valueForKey:key] isEqual:value] == NO )
				{
					[kvwork setObject:@"[multiple values]" forKey:key];
				}
			}
		}
	}
	
	keyvalueStrings = [NSMutableArray new];

	NSEnumerator *enumerator = [kvwork keyEnumerator];
	id obj;
	
	while( obj = [enumerator nextObject] )
	{
		NSString *key, *value;
		
		key = obj;
		value = [kvwork valueForKey:key];
	
		NSString* kv = [NSString stringWithFormat:@"%@=%@", key, value];
		[keyvalueStrings addObject:kv];
	}
	
	[keyvalueTableView reloadData];
	
	// Spawn flag panel
	
	NSNumber* bit = [NSNumber numberWithInt:1];
	int spawnFlagValue = -1;
	NSCellStateValue checkBoxState;
	
	while( [bit intValue] < 2048 )
	{
		checkBoxState = NSOffState;
		
		// Value
		
		spawnFlagValue = -1;
		
		for( TEntity* E in selectedEntities )
		{
			int spawnFlagValueFromEntity = E->spawnFlags & [bit intValue];
			
			if( spawnFlagValue == -1 )
			{
				spawnFlagValue = spawnFlagValueFromEntity;
				
				if( spawnFlagValue > 0 )
				{
					checkBoxState = NSOnState;
				}
			}
			else
			{
				if( spawnFlagValue != spawnFlagValueFromEntity )
				{
					checkBoxState = NSMixedState;
					break;
				}
			}
		}
		
		NSButton* checkBox = [mapBitToCheck objectForKey:bit];
		[checkBox setState:checkBoxState];
		
		// Description
		
		NSString* spawnFlagName = @"";
		
		for( TEntityClass* EC in entityClasses )
		{
			NSString* spawnFlagFromClass = [EC->spawnFlags objectForKey:bit];
			
			if( [spawnFlagName length] == 0 )
			{
				spawnFlagName = [spawnFlagFromClass mutableCopy];
				if( spawnFlagName == nil )
				{
					spawnFlagName = @"";
				}
			}
			else
			{
				if( [spawnFlagName isEqualToString:spawnFlagFromClass] == NO )
				{
					spawnFlagName = @"[multiple flag names]";
					break;
				}
			}
		}

		NSTextField* textField = [mapBitToText objectForKey:bit];
		[textField setStringValue:spawnFlagName];

		// Move to next bit
		
		bit = [NSNumber numberWithInt:[bit intValue] * 2];
	}
	
	// Description panel
	
	NSMutableString* desc = [NSMutableString string];
	
	if( ec == nil )
	{
		desc = @"";
	}
	else
	{
		[desc appendFormat:@"\"%@\"\n\n", [ec->name uppercaseString]];
		
		for( NSString* S in ec->descText )
		{
			[desc appendFormat:@"%@\n", S];
		}
	}
	
	[descTextView setString:desc];
	
	// Title of the entity inspector panel
	
	if( [entityClasses count] == 0 )
	{
		[panelEntityInspector setTitle:@"Entity Inspector"];
	}
	else
	{
		ec = [entityClasses objectAtIndex:0];
		NSString* title = [NSString stringWithFormat:@"%@", [ec->name uppercaseString]];
		
		if( [selectedEntities count] > 1 )
		{
			if( [entityClasses count] == 1 )
			{
				title = [NSString stringWithFormat:@"%d %@s", [selectedEntities count], [ec->name uppercaseString]];
			}
			else
			{
				title = [NSString stringWithFormat:@"%d Entities", [selectedEntities count] ];
			}
		}
		
		[panelEntityInspector setTitle:title];
	}
}

-(void) addToSpawnFlags:(int)InBit
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	NSMutableArray* entities = [map->selMgr getSelectedEntities];
	
	for( TEntity* E in entities )
	{
		E->spawnFlags |= InBit;
	}
	
	[self refreshInspectors];
	[map redrawLevelViewports];
}

-(void) removeFromSpawnFlags:(int)InBit
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	NSMutableArray* entities = [map->selMgr getSelectedEntities];
	
	for( TEntity* E in entities )
	{
		E->spawnFlags &= ~InBit;
	}
	
	[self refreshInspectors];
	[map redrawLevelViewports];
}

- (IBAction)onCheckBox1:(id)sender
{
	if( [sender state] == NSMixedState )	[sender setState:NSOnState];
	
	if( [sender state] == NSOnState )		[self addToSpawnFlags:1];
	else if( [sender state] == NSOffState )	[self removeFromSpawnFlags:1];
}

- (IBAction)onCheckBox2:(id)sender
{
	if( [sender state] == NSMixedState )	[sender setState:NSOnState];
	
	if( [sender state] == NSOnState )		[self addToSpawnFlags:2];
	else if( [sender state] == NSOffState )	[self removeFromSpawnFlags:2];
}

- (IBAction)onCheckBox4:(id)sender
{
	if( [sender state] == NSMixedState )	[sender setState:NSOnState];
	
	if( [sender state] == NSOnState )		[self addToSpawnFlags:4];
	else if( [sender state] == NSOffState )	[self removeFromSpawnFlags:4];
}

- (IBAction)onCheckBox8:(id)sender
{
	if( [sender state] == NSMixedState )	[sender setState:NSOnState];
	
	if( [sender state] == NSOnState )		[self addToSpawnFlags:8];
	else if( [sender state] == NSOffState )	[self removeFromSpawnFlags:8];
}

- (IBAction)onCheckBox16:(id)sender
{
	if( [sender state] == NSMixedState )	[sender setState:NSOnState];
	
	if( [sender state] == NSOnState )		[self addToSpawnFlags:16];
	else if( [sender state] == NSOffState )	[self removeFromSpawnFlags:16];
}

- (IBAction)onCheckBox32:(id)sender
{
	if( [sender state] == NSMixedState )	[sender setState:NSOnState];
	
	if( [sender state] == NSOnState )		[self addToSpawnFlags:32];
	else if( [sender state] == NSOffState )	[self removeFromSpawnFlags:32];
}

- (IBAction)onCheckBox64:(id)sender
{
	if( [sender state] == NSMixedState )	[sender setState:NSOnState];
	
	if( [sender state] == NSOnState )		[self addToSpawnFlags:64];
	else if( [sender state] == NSOffState )	[self removeFromSpawnFlags:64];
}

- (IBAction)onCheckBox128:(id)sender
{
	if( [sender state] == NSMixedState )	[sender setState:NSOnState];
	
	if( [sender state] == NSOnState )		[self addToSpawnFlags:128];
	else if( [sender state] == NSOffState )	[self removeFromSpawnFlags:128];
}

- (IBAction)onCheckBox256:(id)sender
{
	if( [sender state] == NSMixedState )	[sender setState:NSOnState];
	
	if( [sender state] == NSOnState )		[self addToSpawnFlags:256];
	else if( [sender state] == NSOffState )	[self removeFromSpawnFlags:256];
}

- (IBAction)onCheckBox512:(id)sender
{
	if( [sender state] == NSMixedState )	[sender setState:NSOnState];
	
	if( [sender state] == NSOnState )		[self addToSpawnFlags:512];
	else if( [sender state] == NSOffState )	[self removeFromSpawnFlags:512];
}

- (IBAction)onCheckBox1024:(id)sender
{
	if( [sender state] == NSMixedState )	[sender setState:NSOnState];
	
	if( [sender state] == NSOnState )		[self addToSpawnFlags:1024];
	else if( [sender state] == NSOffState )	[self removeFromSpawnFlags:1024];
}

// Data sourcing for key/value table

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [keyvalueStrings count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	return [keyvalueStrings objectAtIndex:rowIndex];
}

- (void)tableView:(NSTableView *)aTable setObjectValue:(id)aData forTableColumn:(NSTableColumn *)aCol row:(int)aRow
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	
	NSScanner* scanner = [NSScanner scannerWithString:aData];
	NSString *key, *value;
	
	[scanner scanUpToString: @"=" intoString:&key];
	[scanner scanString: @"=" intoString:nil];
	BOOL bHasValue = [scanner scanUpToString: @"" intoString:&value];
	
	if( bHasValue && [value length] > 0 && [value isEqualToString:@"[multiple values]"] == NO )
	{
		// Delete the existing key/value in case the user is changing the name of the key
		[self deleteKeyValueAtRow:aRow];
		
		// Add the key/value into every selected entity
		for( TEntity* E in selectedEntities )
		{
			[E->keyvalues setValue:value forKey:key];
			[E finalizeInternals:[TGlobal getMAP]];
		}
		
		// Special case handling of certain keys
		
		if( [key isEqualToString:@"_game"] ) 
		{
			[map refreshEntityClasses];
			[map populateCreateEntityMenu];
		}
		
		[self refreshInspectors];
		[map redrawLevelViewports];
	}
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
	NSString* kvstring = [keyvalueStrings objectAtIndex:rowIndex];
	NSScanner* scanner = [NSScanner scannerWithString:kvstring];
	NSString *key;
	[scanner scanUpToString: @"=" intoString:&key];
	
	// The user can't edit the classname by hand.  They must use the Entity menu.
	
	if( [key isEqualToString:@"classname"] )
	{
		return NO;
	}
	
	return YES;
}

- (IBAction)onNewButton:(id)sender
{
	for( TEntity* E in selectedEntities )
	{
		[E->keyvalues setValue:@"[value]" forKey:@"key"];
	}
	
	[self refreshInspectors];
}

- (IBAction)onDeleteButton:(id)sender
{
	NSIndexSet* rows = [keyvalueTableView selectedRowIndexes];
	
	if( [rows count] > 0 )
	{
		int row = [rows lastIndex];
		
		while( row != NSNotFound )
		{
			[self deleteKeyValueAtRow:row];
			
			row = [rows indexLessThanIndex:row];
		}
		
		[self refreshInspectors];

		MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
		[map redrawLevelViewports];
	}
}

-(void) deleteKeyValueAtRow:(int)InRow
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	
	NSString* kvstring = [keyvalueStrings objectAtIndex:InRow];
	NSScanner* scanner = [NSScanner scannerWithString:kvstring];
	NSString *key;
	[scanner scanUpToString: @"=" intoString:&key];
	
	for( TEntity* E in selectedEntities )
	{
		[E->keyvalues removeObjectForKey:key];
		[E finalizeInternals:[TGlobal getMAP]];
	}
	
	if( [key isEqualToString:@"_game"] )
	{
		[map refreshEntityClasses];
		[map populateCreateEntityMenu];
	}
}

- (IBAction)onUpButton:(id)sender
{
	for( TEntity* E in selectedEntities )
	{
		[E->keyvalues setObject:@"-1" forKey:@"angle"];
		[E finalizeInternals:[TGlobal getMAP]];
	}
	
	[self refreshInspectors];
}

- (IBAction)onDownButton:(id)sender
{
	for( TEntity* E in selectedEntities )
	{
		[E->keyvalues setObject:@"-2" forKey:@"angle"];
		[E finalizeInternals:[TGlobal getMAP]];
	}
	
	[self refreshInspectors];
}

- (IBAction)onAngleSlider:(id)sender
{
	// Coerces the slider control to return values counterclockwise instead of clockwise.  We then add 90 degrees
	// to account for the Quake coordinate system.
	
	int angle = ([sender intValue] * -1) + 90;
	if( angle < 0 )		angle += 360;
	if( angle > 360 )	angle -= 360;
	
	for( TEntity* E in selectedEntities )
	{
		[E->keyvalues setObject:[NSString stringWithFormat:@"%d", angle] forKey:@"angle"];
		[E finalizeInternals:[TGlobal getMAP]];
	}
	
	[self refreshInspectors];
}

@end
