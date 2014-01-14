
@implementation TVisibility

-(id) initWithMAP:(MAPDocument*)InMap
{
	[super init];
	
	hiddenObjects = [NSMutableDictionary new];
	map = InMap;
	
	return self;
}

// Checks InObject to see if it has the proper selectors inside of it to
// work nicely with the visibility system.

-(BOOL) hasNeededSelectors:(id)InObject
{
	if( [InObject respondsToSelector:@selector(getPickName)] == YES )
	{
		return YES;
	}
	
	return NO;
}

-(BOOL) isVisible:(id)InObject
{
	if( [hiddenObjects objectForKey:[InObject getPickName]] == nil )
	{
		return YES;
	}
	
	return NO;
}

-(void) hide:(id)InObject
{
	if( [self isVisible:InObject] )
	{
		[map->historyMgr startRecord:@"Hide Object"];
		[map->historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_HideObject Object:InObject]];
		
		[hiddenObjects setObject:InObject forKey:[InObject getPickName]];
		
		if( [InObject isKindOfClass:[TBrush class]] )
		{
			[InObject markDirtyRenderArray];
		}
		
		// If an object is being hidden, it can't stay selected
		[map->selMgr removeSelection:InObject];
		
		[map->historyMgr stopRecord];
	}
}

-(void) show:(id)InObject
{
	if( [self isVisible:InObject] == NO )
	{
		[map->historyMgr startRecord:@"Show Object"];
		[map->historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_ShowObject Object:InObject]];
		
		if( [InObject isKindOfClass:[TBrush class]] )
		{
			[InObject markDirtyRenderArray];
		}
		
		[hiddenObjects removeObjectForKey:[InObject getPickName]];
		
		[map->historyMgr stopRecord];
	}
}

-(void) showAll
{
	NSDictionary* sels = [hiddenObjects copy];
	NSEnumerator *enumerator = [sels objectEnumerator];
	id obj;
	
	[map->historyMgr startRecord:@"Show All"];
	
	while( obj = [enumerator nextObject] )
	{
		[self show:obj];
	}
	
	[map->historyMgr stopRecord];
}

@end
