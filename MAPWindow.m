
@implementation MAPWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)windowStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation
{
	[super initWithContentRect:contentRect styleMask:windowStyle backing:bufferingType defer:deferCreation];
	
	visiblePanels = [NSMutableArray new];
	rebuildOption = TBO_Full;
	
	return self;
}

- (void) windowDidBecomeMain: (NSNotification *) notification
{
	// Restore visible panels

	for( NSPanel* panel in visiblePanels )
	{
		[panel setIsVisible:YES];
	}
	
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map populateCreateEntityMenu];
}

- (void) windowDidResignMain: (NSNotification *) notification
{
	// Record all visible dialogs
	
	visiblePanels = [NSMutableArray new];
	
	if( [panelFaceInspector isVisible] )
	{
		[visiblePanels addObject:panelFaceInspector];
		[panelFaceInspector setIsVisible:NO];
	}
	
	if( [panelEntityInspector isVisible] )
	{
		[visiblePanels addObject:panelEntityInspector];
		[panelEntityInspector setIsVisible:NO];
	}
	
	if( [panelBuildInspector isVisible] )
	{
		[visiblePanels addObject:panelBuildInspector];
		[panelBuildInspector setIsVisible:NO];
	}
}

- (IBAction)OnShowFaceInspector:(id)sender
{
	[panelFaceInspector setIsVisible:YES];
}

- (IBAction)OnShowEntityInspector:(id)sender
{
	[panelEntityInspector setIsVisible:YES];
}

- (IBAction)OnShowBuildInspector:(id)sender
{
	[panelBuildInspector setIsVisible:YES];
}

-(void) refreshInspectors
{
	[[panelEntityInspector delegate] refreshInspectors];
	[[panelFaceInspector delegate] refreshInspectors];
}

- (IBAction)onHideSelected:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map hideSelected];
}

- (IBAction)onIsolate:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map isolateSelected];
}

- (IBAction)onShowAll:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map showAll];
}

- (IBAction)onRebuildOption:(id)sender
{
	rebuildOption = [sender indexOfSelectedItem];
	
	// Compensate for the seperator in the popup menu
	
	if( rebuildOption > 1 )
	{
		rebuildOption--;
	}
}

- (IBAction)onCompile:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	MAPWindow* mapwindow = (MAPWindow*)[map windowForSheet];
	NSTextView* outputTextView = ((TBuildInspectorDelegate*)[mapwindow->panelBuildInspector delegate])->outputTextView;
	
	[jumpToLeakButton setEnabled:NO];
	
	// Make sure the map is saved out before trying to compile it
	
	[map saveDocument:nil];
	
	[mapwindow OnShowBuildInspector:nil];
	
	NSString *BSP_Filename = [NSString stringWithFormat:@"%@/QBSP", [[NSBundle mainBundle] resourcePath]];
	NSString *LIGHT_Filename = [NSString stringWithFormat:@"%@/LIGHT", [[NSBundle mainBundle] resourcePath]];
	NSString *VIS_Filename = [NSString stringWithFormat:@"%@/VIS", [[NSBundle mainBundle] resourcePath]];

	// Create a game directory to pass to the compiling tools
	
	NSString* dir = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"quakeDirectory"];
	
	NSString* gameName = @"";
	gameName = [[map findEntityByClassName:@"worldspawn"]->keyvalues valueForKey:@"_game"];
	
	if( [gameName length] > 0 )
	{
		dir = [NSString stringWithFormat:@"%@/%@/", dir, gameName];
	}
	else
	{
		dir = [NSString stringWithFormat:@"%@/id1/", dir ];
	}
	
	[outputTextView setString:@""];
	
	switch( rebuildOption )
	{
		case TBO_Full:
		{
			[self emitTextToBuildResults:@"\nCompiling: Full Rebuild\n"];
			
			[self emitHeaderToBuildResults:@"QBSP"];
			[self emitTextToBuildResults:[self runTask:BSP_Filename UseBSPFile:NO Args:[NSArray arrayWithObjects:@"-gamedir", dir, nil]]];
			
			[self emitHeaderToBuildResults:@"LIGHT"];
			[self emitTextToBuildResults:[self runTask:LIGHT_Filename UseBSPFile:YES Args:[NSArray arrayWithObjects:@"-extra", @"-gamedir", dir, nil]]];
			
			[self emitHeaderToBuildResults:@"VIS"];
			[self emitTextToBuildResults:[self runTask:VIS_Filename UseBSPFile:YES Args:[NSArray arrayWithObjects:@"-level", @"4", @"-gamedir", dir, nil]]];
		}
			break;
			
		case TBO_Quick:
		{
			[self emitTextToBuildResults:@"\nCompiling: Quick Rebuild\n"];
			
			[self emitHeaderToBuildResults:@"QBSP"];
			[self emitTextToBuildResults:[self runTask:BSP_Filename UseBSPFile:NO Args:[NSArray arrayWithObjects:@"-gamedir", dir, nil]]];
			
			[self emitHeaderToBuildResults:@"LIGHT"];
			[self emitTextToBuildResults:[self runTask:LIGHT_Filename UseBSPFile:YES Args:[NSArray arrayWithObjects: @"-gamedir", dir, nil]]];
			
			[self emitHeaderToBuildResults:@"VIS"];
			[self emitTextToBuildResults:[self runTask:VIS_Filename UseBSPFile:YES Args:[NSArray arrayWithObjects:@"-fast", @"-gamedir", dir, nil]]];
		}
			break;
			
		case TBO_GeometryOnly:
		{
			[self emitTextToBuildResults:@"\nCompiling: Geometry Only\n"];
			
			[self emitHeaderToBuildResults:@"QBSP"];
			[self emitTextToBuildResults:[self runTask:BSP_Filename UseBSPFile:NO Args:[NSArray arrayWithObjects:@"-gamedir", dir, nil]]];
		}
			break;
			
		case TBO_EntitiesOnly:
		{
			[self emitTextToBuildResults:@"\nCompiling: Entities Only\n"];
			
			[self emitHeaderToBuildResults:@"QBSP"];
			[self emitTextToBuildResults:[self runTask:BSP_Filename UseBSPFile:NO Args:[NSArray arrayWithObjects:@"-onlyents", @"-gamedir", dir, nil]]];
		}
			break;
			
		case TBO_LightingOnly:
		{
			[self emitTextToBuildResults:@"\nCompiling: Lighting Only\n"];
			
			[self emitHeaderToBuildResults:@"QBSP"];
			[self emitTextToBuildResults:[self runTask:BSP_Filename UseBSPFile:NO Args:[NSArray arrayWithObjects:@"-onlyents", @"-gamedir", dir, nil]]];
			
			[self emitHeaderToBuildResults:@"LIGHT"];
			[self emitTextToBuildResults:[self runTask:LIGHT_Filename UseBSPFile:YES Args:[NSArray arrayWithObjects:@"-extra", @"-gamedir", dir, nil]]];
		}
			break;
	}
	
	[self emitHeaderToBuildResults:@"Finished"];
	
	// Automatically load the point file
	
	[map loadPointFile];
}

- (IBAction)onPlayLevel:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map playLevelInQuake];
}

- (IBAction)onEntityFilter:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	map->filterOption = [sender indexOfSelectedItem];
	[map redrawLevelViewports];
}

- (IBAction)onShowEditorEntitiesOnly:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	map->bShowEditorOnlyEntities = !map->bShowEditorOnlyEntities;
	[map markAllTexturesDirtyRenderArray];
	[map redrawLevelViewports];
}

-(void) emitHeaderToBuildResults:(NSString*)InText
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	MAPWindow* mapwindow = (MAPWindow*)[map windowForSheet];
	NSTextView* outputTextView = ((TBuildInspectorDelegate*)[mapwindow->panelBuildInspector delegate])->outputTextView;
	
	[outputTextView insertText:@"\n"];
	[outputTextView insertText:@"==========================================\n"];
	[outputTextView insertText:[NSString stringWithFormat:@" %@\n", InText]];
	[outputTextView insertText:@"==========================================\n"];
	[outputTextView insertText:@"\n"];
	
	[outputTextView display];
}

-(void) emitTextToBuildResults:(NSString*)InText
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	MAPWindow* mapwindow = (MAPWindow*)[map windowForSheet];
	NSTextView* outputTextView = ((TBuildInspectorDelegate*)[mapwindow->panelBuildInspector delegate])->outputTextView;
	TVec3D** leakLocation = &(((TBuildInspectorDelegate*)[mapwindow->panelBuildInspector delegate])->leakLocation);
	
	[outputTextView insertText:InText];
	
	// Parse the text looking for a leak location
	
	NSMutableArray* chunks = [[InText componentsSeparatedByString:@"\n"] mutableCopy];
	
	for( NSString* S in chunks )
	{
		if( [S length] > 15 && [[S substringToIndex:16] isEqualToString:@"reached occupant"] )
		{
			NSScanner* scanner = [NSScanner scannerWithString:S];
			
			*leakLocation = [TVec3D new];
			[scanner scanString:@"reached occupant at: " intoString:nil];
			[scanner scanFloat:&(*leakLocation)->x];
			[scanner scanFloat:&(*leakLocation)->y];
			[scanner scanFloat:&(*leakLocation)->z];
			
			(*leakLocation) = [(*leakLocation) swizzleFromQuake];
			
			[jumpToLeakButton setEnabled:YES];
		}
	}
	
	[outputTextView display];
}

-(NSString*) runTask:(NSString*)InApp UseBSPFile:(BOOL)bUseBSPFile Args:(NSArray*)InArgs
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	NSString* mapURL = [[map fileName] mutableCopy];
	
	// If this tool operates on the BSP file rather than the MAP, pass that filename instead
	
	if( bUseBSPFile )
	{
		NSArray* chunks = [mapURL componentsSeparatedByString:@"/"];
		mapURL = [[chunks objectAtIndex:[chunks count] - 1] mutableCopy];
		chunks = [mapURL componentsSeparatedByString:@"."];
		mapURL = [chunks objectAtIndex:0];
		
		NSString* quakeDir = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"quakeDirectory"];
		
		NSString* gameName = @"";
		gameName = [[map findEntityByClassName:@"worldspawn"]->keyvalues valueForKey:@"_game"];
		
		if( [gameName length] > 0 )
		{
			mapURL = [NSString stringWithFormat:@"%@/%@/maps/%@.bsp", quakeDir, gameName, mapURL];
		}
		else
		{
			mapURL = [NSString stringWithFormat:@"%@/id1/maps/%@.bsp", quakeDir, mapURL];
		}
	}
	
	// Allocate a task
	
    NSTask* task = [NSTask new];
	[task setLaunchPath:InApp];
	
	// Wrangle arguments into one array
	
    NSMutableArray* arguments = [NSMutableArray new];
	[arguments addObjectsFromArray:InArgs];
	[arguments addObject:mapURL];
	
    [task setArguments:arguments];
	
	// Set up to capture stdout from the command line tools
	
    NSPipe* stdoutPipe = [NSPipe pipe];
    [task setStandardOutput:stdoutPipe];
	
    NSFileHandle* file = [stdoutPipe fileHandleForReading];
	
	// Run the task
	
    [task launch];
	
	// Grab the output text
	
    NSData* data = [file readDataToEndOfFile];
	
	[file closeFile];
	
	// Return the output text as a string
	
	return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (IBAction)OnToolsBrushBuildersCube:(id)sender
{
	[self buildBrush:[TBrushBuilderCube new] Args:[NSArray arrayWithObjects:nil]];
}

- (IBAction)OnToolsBrushBuildersWedge:(id)sender
{
	[self buildBrush:[TBrushBuilderWedge new] Args:[NSArray arrayWithObjects:nil]];
}

- (IBAction)OnToolsBrushBuildersCylinder6:(id)sender
{
	[self buildBrush:[TBrushBuilderCylinder new] Args:[NSArray arrayWithObjects:[NSNumber numberWithInt:6], nil]];
}

- (IBAction)OnToolsBrushBuildersCylinder8:(id)sender
{
	[self buildBrush:[TBrushBuilderCylinder new] Args:[NSArray arrayWithObjects:[NSNumber numberWithInt:8], nil]];
}

- (IBAction)OnToolsBrushBuildersCylinder12:(id)sender
{
	[self buildBrush:[TBrushBuilderCylinder new] Args:[NSArray arrayWithObjects:[NSNumber numberWithInt:12], nil]];
}

- (IBAction)OnToolsBrushBuildersSpike3:(id)sender
{
	[self buildBrush:[TBrushBuilderSpike new] Args:[NSArray arrayWithObjects:[NSNumber numberWithInt:3], nil]];
}

- (IBAction)OnToolsBrushBuildersSpike4:(id)sender
{
	[self buildBrush:[TBrushBuilderSpike new] Args:[NSArray arrayWithObjects:[NSNumber numberWithInt:4], nil]];
}

- (IBAction)OnToolsBrushBuildersSpike8:(id)sender
{
	[self buildBrush:[TBrushBuilderSpike new] Args:[NSArray arrayWithObjects:[NSNumber numberWithInt:8], nil]];
}

- (IBAction)OnToolsBrushBuildersSpike12:(id)sender
{
	[self buildBrush:[TBrushBuilderSpike new] Args:[NSArray arrayWithObjects:[NSNumber numberWithInt:12], nil]];
}

-(void) buildBrush:(TBrushBuilder*)InBrushBuilder Args:(NSArray*)InArgs
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map registerTexturesWithViewports:NO];
	
	[map->historyMgr startRecord:@"Brush Builder"];
	
	TVec3D* location;
	TVec3D* sz;
	BOOL bFoundSelections = NO;
	
	for( TEntity* E in map->entities )
	{
		NSMutableArray* tempB = [NSMutableArray arrayWithArray:E->brushes];
		for( TBrush* B in tempB )
		{
			if( [map->selMgr isSelected:B] )
			{
				bFoundSelections = YES;
				
				location = [B getCenter];
				sz = [B getExtents];
				
				TBrush* brush = [InBrushBuilder build:map Location:location Extents:sz Args:InArgs];
				[brush generateTexCoords:map];
				
				[map->historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_AddBrush Object:brush Owner:E]];
				
				[E->brushes addObject:brush];
				
				[map destroyObject:B];
			}
		}
	}
	
	if( bFoundSelections == NO )
	{
		TBrush* brush = [InBrushBuilder build:map Location:[TVec3D new] Extents:[[TVec3D alloc] initWithX:128 Y:128 Z:128] Args:InArgs];
		[brush generateTexCoords:map];
		
		TEntity* E = [map findBestSelectedBrushBasedEntity];
		[map->historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_AddBrush Object:brush Owner:E]];
		
		[E->brushes addObject:brush];
	}
	
	[map redrawLevelViewports];
	[map->historyMgr stopRecord];
}

@end
