
@implementation TApplicationDelegate

-(void) awakeFromNib
{
	bCreateEntityMenuInitialized = NO;

	// Check to see if the user preferences are valid.  If not, open the preferences panel and
	// force the user to set up ToeTag properly.
	
	if( [TPreferencesTools isQuakeDirectoryValid:[NSUserDefaultsController sharedUserDefaultsController]] == NO )
	{
		[preferencesPanel makeKeyAndOrderFront:nil];
		NSBeginAlertSheet(@"ToeTag", @"OK", nil, nil, preferencesPanel, nil, nil, nil, nil,
						  @"ToeTag has some invalid preferences set.  These will need to be set correctly before you can start using the editor." );
		[[NSApplication sharedApplication] runModalForWindow:preferencesPanel];
	}
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	// Prevents the application from opening an empty document when it starts up
	return NO;
}

- (IBAction)onFileOpenPointFile:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map loadPointFile];
}

- (IBAction)onFileClearPointFile:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	
	[map clearPointFile];
	[map redrawLevelViewports];
}

- (IBAction)onViewFaceInspector:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	MAPWindow* mapwindow = (MAPWindow*)[map windowForSheet];
	[mapwindow OnShowFaceInspector:sender];
}

- (IBAction)onViewEntityInspector:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	MAPWindow* mapwindow = (MAPWindow*)[map windowForSheet];
	[mapwindow OnShowEntityInspector:sender];
}

- (IBAction)onViewBuildInspector:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	MAPWindow* mapwindow = (MAPWindow*)[map windowForSheet];
	[mapwindow OnShowBuildInspector:sender];
}

- (IBAction)onToolsTexturesOpen:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	NSArray *fileTypes = [NSArray arrayWithObjects:@"wad", nil];

	NSOpenPanel* oPanel = [NSOpenPanel openPanel];

	[oPanel setCanChooseDirectories:NO];
	[oPanel setCanChooseFiles:YES];
	[oPanel setAllowsMultipleSelection:YES];
	[oPanel setAlphaValue:0.95];
	[oPanel setTitle:@"Select a WAD to open"];

	if( [oPanel runModalForDirectory:nil file:nil types:fileTypes] == NSOKButton )
	{
		[map clearLoadedTextures];
		
		NSArray* files = [oPanel filenames];

		for( NSString *filename in files )
		{
			[map loadWADFullPath:filename];
			
			// Extract the WAD path from the filename and tell the worldspawn about it
			
			NSScanner* scanner = [NSScanner scannerWithString:filename];
			NSString *wadpath;
			
			[scanner scanUpToString: @"gfx/" intoString:nil];
			[scanner scanUpToString: @"" intoString:&wadpath];
			
			[[map findEntityByClassName:@"worldspawn"] setKey:@"wad" Value:wadpath];
			[map refreshInspectors];
		}
	}
	
	[map redrawTextureViewports];
	[map redrawTextureViewports];
}

- (IBAction)onToolsTexturesAppend:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	NSArray *fileTypes = [NSArray arrayWithObjects:@"wad", nil];
	
	NSOpenPanel* oPanel = [NSOpenPanel openPanel];
	
	[oPanel setCanChooseDirectories:NO];
	[oPanel setCanChooseFiles:YES];
	[oPanel setAllowsMultipleSelection:YES];
	[oPanel setAlphaValue:0.95];
	[oPanel setTitle:@"Select a WAD to append"];
	
	if( [oPanel runModalForDirectory:nil file:nil types:fileTypes] == NSOKButton )
	{
		NSArray* files = [oPanel filenames];
		
		for( NSString *filename in files )
		{
			[map loadWADFullPath:filename];
			
			// Don't know what the WAD name is at this point.  It's undefined until the user saves this merged WAD.
			
			[[map findEntityByClassName:@"worldspawn"] setKey:@"wad" Value:@"unknown"];
		}
	}
	
	[map redrawTextureViewports];
	[map redrawTextureViewports];
}

- (IBAction)onToolsTexturesSave:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	NSArray *fileTypes = [NSArray arrayWithObjects:@"wad", nil];
	
	NSSavePanel* sPanel = [NSSavePanel savePanel];
	[sPanel setAllowedFileTypes:fileTypes];
	[sPanel setAlphaValue:0.95];
	[sPanel setTitle:@"Select a WAD to save to"];
	
	if( [sPanel runModalForDirectory:nil file:nil] == NSFileHandlingPanelOKButton )
	{
		[map saveWADFullPath:[sPanel filename]];
		
		// Extract the WAD path from the filename and tell the worldspawn about it
		NSScanner* scanner = [NSScanner scannerWithString:[sPanel filename]];
		NSString *wadpath;
		
		[scanner scanUpToString: @"gfx/" intoString:nil];
		[scanner scanUpToString: @"" intoString:&wadpath];
		
		[[map findEntityByClassName:@"worldspawn"] setKey:@"wad" Value:wadpath];
		[map refreshInspectors];
	}
}

- (IBAction)onToolsTexturesImport:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	NSArray *fileTypes = [NSImage imageFileTypes];
	
	NSOpenPanel* oPanel = [NSOpenPanel openPanel];
	
	[oPanel setCanChooseDirectories:NO];
	[oPanel setCanChooseFiles:YES];
	[oPanel setAllowsMultipleSelection:YES];
	[oPanel setAlphaValue:0.95];
	[oPanel setTitle:@"Select files to import"];
	
	if( [oPanel runModalForDirectory:nil file:nil types:fileTypes] == NSOKButton )
	{
		NSArray* files = [oPanel filenames];
		
		for( NSString *filename in files )
		{
			NSImage* img = [[NSImage alloc] initWithContentsOfFile:filename];
			NSData *tiff_data = [[NSData alloc] initWithData:[img TIFFRepresentation]];
			NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithData:tiff_data];
			
			NSString* textureName = [[[filename lastPathComponent] stringByDeletingPathExtension] uppercaseString];
			
			// If this texture name is longer than 16 characters, we can't use it.
			if( [textureName length] > 16 )
			{
				NSString* err = [NSString stringWithFormat:@"The texture '%@'s name is too long so it can't be imported.  Quake can only handle texture names that are 8 characters or less.", textureName ];
				NSBeginAlertSheet(@"ToeTag", @"OK", nil, nil, preferencesPanel, nil, nil, nil, nil, err);
				continue;
			}
			
			TTexture* texture = [TTexture new];
			texture->name = [textureName mutableCopy];
			
			// If this texture already exists, remove it from the WAD before adding a new version
			[map removeTextureByName:texture->name];
			
			texture->bShowInBrowser = YES;
			texture->width = [[img bestRepresentationForDevice:nil] pixelsWide];
			texture->height = [[img bestRepresentationForDevice:nil] pixelsHigh];
			texture->RGBBytes = (byte*)malloc( (texture->width * texture->height) * 3 );
			
			int w, h;
			NSColor* color;
			for( w = 0 ; w < texture->width ; ++w )
			{
				for( h = 0 ; h < texture->height ; ++h )
				{
					int idx = ((h * texture->width) + w) * 3;
					byte* rgb = texture->RGBBytes + idx;
					
					color = [bitmap colorAtX:w y:h];
					
					int palidx = [[TGlobal G] getBestPaletteIndexForR:(byte)([color redComponent] * 255) G:(byte)([color greenComponent] * 255) B:(byte)([color blueComponent] * 255) AllowFullbrights:NO];
					TVec3D* clr = [[TGlobal G]->palette objectAtIndex:palidx];
					
					*rgb = (byte)clr->x;
					*(rgb + 1) = (byte)clr->y;
					*(rgb + 2) = (byte)clr->z;
				}
			}
			
			[map->texturesFromWADs addObject:texture];
		}
	}
	
	[map registerTexturesWithViewports:NO];
	
	[map redrawTextureViewports];
	[map redrawTextureViewports];
}

- (IBAction)onToolsTexturesImportWithFullbrights:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	NSArray *fileTypes = [NSImage imageFileTypes];
	
	NSOpenPanel* oPanel = [NSOpenPanel openPanel];
	
	[oPanel setCanChooseDirectories:NO];
	[oPanel setCanChooseFiles:YES];
	[oPanel setAllowsMultipleSelection:YES];
	[oPanel setAlphaValue:0.95];
	[oPanel setTitle:@"Select files to import"];
	
	if( [oPanel runModalForDirectory:nil file:nil types:fileTypes] == NSOKButton )
	{
		NSArray* files = [oPanel filenames];
		
		for( NSString *filename in files )
		{
			NSImage* img = [[NSImage alloc] initWithContentsOfFile:filename];
			NSData *tiff_data = [[NSData alloc] initWithData:[img TIFFRepresentation]];
			NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithData:tiff_data];
			
			NSString* textureName = [[[filename lastPathComponent] stringByDeletingPathExtension] uppercaseString];
			
			// If this texture name is longer than 16 characters, we can't use it.
			if( [textureName length] > 16 )
			{
				NSString* err = [NSString stringWithFormat:@"The texture '%@'s name is too long so it can't be imported.  Quake can only handle texture names that are 8 characters or less.", textureName ];
				NSBeginAlertSheet(@"ToeTag", @"OK", nil, nil, preferencesPanel, nil, nil, nil, nil, err);
				continue;
			}
			
			TTexture* texture = [TTexture new];
			texture->name = [textureName mutableCopy];
			
			// If this texture already exists, remove it from the WAD before adding a new version
			[map removeTextureByName:texture->name];
			
			texture->bShowInBrowser = YES;
			texture->width = [[img bestRepresentationForDevice:nil] pixelsWide];
			texture->height = [[img bestRepresentationForDevice:nil] pixelsHigh];
			texture->RGBBytes = (byte*)malloc( (texture->width * texture->height) * 3 );
			
			int w, h;
			NSColor* color;
			for( w = 0 ; w < texture->width ; ++w )
			{
				for( h = 0 ; h < texture->height ; ++h )
				{
					int idx = ((h * texture->width) + w) * 3;
					byte* rgb = texture->RGBBytes + idx;
					
					color = [bitmap colorAtX:w y:h];
					
					int palidx = [[TGlobal G] getBestPaletteIndexForR:(byte)([color redComponent] * 255) G:(byte)([color greenComponent] * 255) B:(byte)([color blueComponent] * 255) AllowFullbrights:YES];
					TVec3D* clr = [[TGlobal G]->palette objectAtIndex:palidx];
					
					*rgb = (byte)clr->x;
					*(rgb + 1) = (byte)clr->y;
					*(rgb + 2) = (byte)clr->z;
				}
			}
			
			[map->texturesFromWADs addObject:texture];
		}
	}
	
	[map registerTexturesWithViewports:NO];
	
	[map redrawTextureViewports];
	[map redrawTextureViewports];
}

- (IBAction)onToolsTexturesExport:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	NSArray *fileTypes = [NSArray arrayWithObjects:@"png", nil];
	
	TTexture* T = [map findTextureByName:[map->selMgr getSelectedTextureName]];
	
	NSSavePanel* sPanel = [NSSavePanel savePanel];
	[sPanel setAllowedFileTypes:fileTypes];
	[sPanel setAlphaValue:0.95];
	[sPanel setTitle:@"Select a filename to export to"];
	
	if( [sPanel runModalForDirectory:nil file:T->name] == NSFileHandlingPanelOKButton )
	{
		NSBitmapImageRep* imgrep = [[NSBitmapImageRep alloc]
									initWithBitmapDataPlanes:NULL
									pixelsWide:T->width
									pixelsHigh:T->height
									bitsPerSample:8
									samplesPerPixel:3
									hasAlpha:NO
									isPlanar:NO
									colorSpaceName:NSDeviceRGBColorSpace
									bytesPerRow:0
									bitsPerPixel:0];
		
		byte* dst = [imgrep bitmapData];
		memcpy( dst, T->RGBBytes, (T->width * T->height) * 3 );
		
		NSImage* img = [[NSImage alloc] initWithSize:NSMakeSize( T->width, T->height )];
		[img addRepresentation:imgrep];
		
		NSArray* representations = [img representations];
		NSData* bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSPNGFileType properties:nil];
		[bitmapData writeToFile:[sPanel filename] atomically:YES];
	}
}

- (IBAction)onToolsTexturesDelete:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	
	TTexture* T = [map findTextureByName:[map->selMgr getSelectedTextureName]];
	
	if( T )
	{
		[map->texturesFromWADs removeObject:T];
	}
	
	[map registerTexturesWithViewports:NO];
	
	[map redrawTextureViewports];
}

- (IBAction)onToolsTexturesRename:(id)sender
{
	// Look for currently selected texture and put it's name into the text field
	
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	
	TDlgRenameDelegate* delegate = [dlgRenameTexture delegate];
	
	delegate->texture = [map findTextureByName:[map->selMgr getSelectedTextureName]];
	
	if( delegate->texture )
	{
		[delegate->nameTextField setStringValue:delegate->texture->name];
	
		MAPWindow* mapwindow = (MAPWindow*)[map windowForSheet];
		[NSApp beginSheet:dlgRenameTexture modalForWindow:mapwindow modalDelegate:self didEndSelector:NULL contextInfo:nil];
	}
}

- (IBAction)onEditUndo:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	
	[map->historyMgr undo];
	[map refreshInspectors];
}

- (IBAction)onEditRedo:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	
	[map->historyMgr redo];
	[map refreshInspectors];
}

- (IBAction)onEditSelectAll:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	
	[map selectAll];
	
	[map redrawLevelViewports];
	[map refreshInspectors];
}

- (IBAction)onEditSelectMatching:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	
	[map selectMatching];
	
	[map redrawLevelViewports];
	[map refreshInspectors];
}

- (IBAction)onEditSelectWholeEntity:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	
	[map selectMatchingWithinEntity];
	
	[map redrawLevelViewports];
	[map refreshInspectors];
}

- (IBAction)onEditDeselect:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	
	[map deselect];
	
	[map redrawLevelViewports];
	[map refreshInspectors];
}

- (IBAction)onEditHideSelected:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map hideSelected];
}

- (IBAction)onEditIsolateSelected:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map isolateSelected];
}

- (IBAction)onEditShowAll:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map showAll];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	return YES;
}

- (IBAction)onCreateEntityItem:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	
	NSString* ecn = [sender title];
	[map createEntityFromSelections:ecn];
	
	[map redrawLevelViewports];
}

// Takes all selected brushes and moves them into the first selected brush entity we can find.

- (IBAction)onJoin:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map->historyMgr startRecord:@"Join"];

	NSMutableArray* selectedEntities = [map->selMgr getSelectedEntities];
	TEntity* primaryEntity = [map findBestSelectedBrushBasedEntity];
	
	for( TEntity* E in selectedEntities )
	{
		if( E != primaryEntity )
		{
			NSMutableArray* tempBrushes = [NSMutableArray arrayWithArray:E->brushes];
			for( TBrush* B in tempBrushes )
			{
				if( [map->selMgr isSelected:B] )
				{
					[map->historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_AddBrushToEntity Object:B Owner:primaryEntity]];
					[map->historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_RemoveBrushFromEntity Object:B Owner:E]];
					
					[map destroyObject:B];
					[primaryEntity->brushes addObject:B];
				}
			}
		}
	}
	
	[map->historyMgr stopRecord];
	
	[map refreshInspectors];
}

- (IBAction)onSplit:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map->historyMgr startRecord:@"Split"];
	
	[map createEntityFromSelections:@"worldspawn"];

	[map->historyMgr stopRecord];

	[map redrawLevelViewports];
}

- (IBAction)OnToolsEntityQuickGroupCreate:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map->historyMgr startRecord:@"Create Quick Group"];

	int quickGroupID = [[TGlobal G] generateQuickGroupID];
	
	for( TEntity* E in map->entities )
	{
		if( [map->selMgr isSelected:E] && [E isPointEntity] )
		{
			E->quickGroupID = quickGroupID;
		}
		
		for( TBrush* B in E->brushes )
		{
			if( [map->selMgr isSelected:B] )
			{
				B->quickGroupID = quickGroupID;
			}
		}
	}
	
	[map->historyMgr stopRecord];
	
	[map refreshInspectors];
	[map redrawLevelViewports];
}

- (IBAction)OnToolsEntityQuickGroupSelect:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map->historyMgr startRecord:@"Select Quick Group"];
	NSMutableArray* sels = [map->selMgr getSelections:TSC_Level];
	
	for( id obj in sels )
	{
		[self selectQuickGroupID:[obj getQuickGroupID]];
	}
	
	[map->historyMgr stopRecord];

	[map refreshInspectors];
	[map redrawLevelViewports];
}

-(void) selectQuickGroupID:(int)InQuickGroupID
{
	if( InQuickGroupID == -1 )
	{
		return;
	}
	
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];

	for( TEntity* E in map->entities )
	{
		if( E->quickGroupID == InQuickGroupID )
		{
			[map->selMgr addSelection:E];
		}
		
		for( TBrush* B in E->brushes )
		{
			if( B->quickGroupID == InQuickGroupID )
			{
				[map->selMgr addSelection:B];
			}
		}
	}
}

- (IBAction)OnToolsEntityQuickGroupDelete:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map->historyMgr startRecord:@"Delete Quick Group"];
	
	for( TEntity* E in map->entities )
	{
		if( [map->selMgr isSelected:E] && [E isPointEntity] )
		{
			E->quickGroupID = -1;
		}
		
		for( TBrush* B in E->brushes )
		{
			if( [map->selMgr isSelected:B] )
			{
				B->quickGroupID = -1;
			}
		}
	}
	
	[map->historyMgr stopRecord];
	
	[map refreshInspectors];
	[map redrawLevelViewports];
}


- (IBAction)onToolsTexturesSynchronizeBrowser:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map synchronizeTextureBrowserWithSelectedFaces];
}

- (IBAction)onToolsCSGHollowSelected:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map csgHollowSelected];
}

- (IBAction)onToolsCSGCreateClipBrush:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map csgCreateClipBrush];
}

- (IBAction)onToolsCSGMergeConvexHull:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map csgMergeConvexHull];
}

- (IBAction)onToolsCSGMergeBoundingBox:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map csgMergeBoundingBox];
}

- (IBAction)onToolsCSGSubtractFromWorld:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map csgSubtractFromWorld];
}
- (IBAction)onToolsCSGClipAgainstWorld:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map csgClipAgainstWorld];
}

- (IBAction)onToolsCSGBevel:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map csgBevel];
}

- (IBAction)onToolsCSGExtrude:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map csgExtrude];
}

- (IBAction)onToolsCSGSplit:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map csgSplit];
}

- (IBAction)onToolsCSGTriangulateFan:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map csgTriangulateFan];
}

- (IBAction)onToolsCSGTriangulateFromCenter:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map csgTriangulateFromCenter];
}

- (IBAction)onToolsCSGOptimize:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map csgOptimize];
}

- (IBAction)onToolsTransformMirrorX:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map mirrorSelectedX:YES Y:NO Z:NO];
}

- (IBAction)onToolsTransformMirrorY:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map mirrorSelectedX:NO Y:YES Z:NO];
}

- (IBAction)onToolsTransformMirrorZ:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map mirrorSelectedX:NO Y:NO Z:YES];
}

- (IBAction)OnPreferences:(id)sender
{
	[preferencesPanel makeKeyAndOrderFront:nil];
	[[NSApplication sharedApplication] runModalForWindow:preferencesPanel];
}

-(IBAction) OnEditTextureLock:(id)sender
{
	NSMenuItem* mi = (NSMenuItem*)sender;
	
	[TGlobal G]->bTextureLock = ![TGlobal G]->bTextureLock;
	
	[mi setState:([TGlobal G]->bTextureLock ? NSOnState : NSOffState)];
}

-(IBAction) OnEditQuantizeVerts:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map quantizeVerts];
}

- (IBAction)OnToolsAutoTargetEntities:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	
	// Grab a list of all target and targetname values
	
	NSMutableArray* targets = [NSMutableArray new];
	NSMutableArray* targetnames = [NSMutableArray new];
	
	for( TEntity* E in map->entities )
	{
		NSString* target = [E->keyvalues valueForKey:@"target"];
		if( [target length] > 0 )
		{
			[targets addObject:target];
		}

		NSString* targetname = [E->keyvalues valueForKey:@"targetname"];
		if( [targetname length] > 0 )
		{
			[targetnames addObject:targetname];
		}
	}
	
	while( TRUE )
	{
		NSString* target = [NSString stringWithFormat:@"T_%d", [[TGlobal G] generateTargetID]];
		
		if( [targets containsObject:target] == NO && [targetnames containsObject:target] == NO )
		{
			NSMutableArray* selectedEntities = [map->selMgr getSelectedEntities];
			
			if( [selectedEntities count] > 1 )
			{
				BOOL bFirstEntity = YES;
				
				for( TEntity* E in selectedEntities )
				{
					if( bFirstEntity == YES )
					{
						bFirstEntity = NO;
						[E->keyvalues setObject:[target mutableCopy] forKey:@"target"];
					}
					else
					{
						[E->keyvalues setObject:[target mutableCopy] forKey:@"targetname"];
					}
				}
			}
			
			break;
		}
	}
	
	[map refreshInspectors];
	[map redrawLevelViewports];
}

- (IBAction)OnToolsDropPathCorner:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map->historyMgr startRecord:@"Drop Path Corner"];

	NSMutableArray* selections = [map->selMgr getSelectedEntities];
	
	for( TEntity* E in selections )
	{
		TVec3D* center = [E getCenter];
		TVec3D* extents = [E getExtents];
		
		TVec3D* loc = [[TVec3D alloc] initWithX:center->x - (extents->x * 0.5f) Y:center->y - (extents->y * 0.5f) Z:center->z + (extents->z * 0.5f)];
		TEntity* PC = [map addNewEntity:@"path_corner"];
		PC->location = loc;
	}
	
	[map->historyMgr stopRecord];
	[map redrawLevelViewports];
}

- (IBAction)OnToolsCreateRoute:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	//[map->historyMgr startRecord:@"Create Route"];
	
	NSMutableArray* selections = [map->selMgr getSelectedEntities];
	
	NSMutableArray* pathCorners = [NSMutableArray new];
	TEntity* firstPathCorner = nil;
	
	for( TEntity* E in selections )
	{
		if( [E->entityClass->name isEqualToString:@"path_corner"] )
		{
			if( firstPathCorner == nil )
			{
				firstPathCorner = E;
			}
			
			[pathCorners addObject:E];
		}
	}
	
	int e;
	for( e = 0 ; e < [pathCorners count] ; ++e )
	{
		TEntity* E0 = [pathCorners objectAtIndex:e];
		TEntity* E1 = [pathCorners objectAtIndex:(e+1)%[pathCorners count]];

		NSString* target = [NSString stringWithFormat:@"T_%d", [[TGlobal G] generateTargetID]];
		[E0->keyvalues setObject:[target mutableCopy] forKey:@"target"];
		[E1->keyvalues setObject:[target mutableCopy] forKey:@"targetname"];
	}
	
	//[map->historyMgr stopRecord];
	[map redrawLevelViewports];
}

-(void) populateCreateEntityMenu:(MAPDocument*)InMAP
{
	NSEnumerator *enumerator = [InMAP->entityClasses keyEnumerator];
	id obj;
	NSMutableArray* sortedClassNames = [NSMutableArray new];
	
	// Sort classnames by name
	
	while( obj = [enumerator nextObject] )
	{
		[sortedClassNames addObject:[obj lowercaseString]];
	}
	
	[sortedClassNames sortUsingSelector:@selector(compare:)];
	
	// Build the menu from the sorted classname list

	[createEntityMenu setSubmenu:[NSMenu new]];
	NSString* prevRootName = @"";
	NSMenu* subMenu = [createEntityMenu submenu];
	
	for( NSString* S in sortedClassNames )
	{
		if( [S isEqualToString:@"class_unknown"] )
		{
			continue;
		}
		
		if( [S rangeOfString:@"_"].location != NSNotFound )
		{
			NSScanner* scanner = [NSScanner scannerWithString:S];
			NSString* rootName;
			[scanner scanUpToString: @"_" intoString:&rootName];
			
			if( [rootName isEqualToString:prevRootName] == NO )
			{
				prevRootName = [rootName mutableCopy];
				NSMenuItem* wk = [[createEntityMenu submenu] addItemWithTitle:rootName action:nil keyEquivalent:@""];
				[wk setSubmenu:[NSMenu new]];
				subMenu = [wk submenu];
			}
		}
		else
		{
			subMenu = [createEntityMenu submenu];
		}
		
		[subMenu addItemWithTitle:[S mutableCopy] action:@selector(onCreateEntityItem:) keyEquivalent:@""];
	}
}

@end
