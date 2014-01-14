
@implementation TPreferencesPanelDelegate

- (BOOL)windowShouldClose:(id)sender
{
	// The controls (sadly) don't send their values unless the user presses ENTER so manually grab and save them
	
	NSString* wk;
	
	wk = [quakeDirTextField stringValue];
	[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:wk forKey:@"quakeDirectory"];
	
	// Verify preferences
	
	if( [TPreferencesTools isQuakeDirectoryValid:[NSUserDefaultsController sharedUserDefaultsController]] == NO )
	{
		NSBeginAlertSheet(@"ToeTag", @"OK", nil, nil, sender, nil, nil, nil, nil, @"Quake could not be found in that directory." );
		return NO;
	}
	
	[[NSApplication sharedApplication] stopModal];
	
	return YES;
}

-(IBAction) OnBrowseForDirectory:(id)sender
{
	NSOpenPanel* oPanel = [NSOpenPanel openPanel];
	
	[oPanel setCanChooseDirectories:YES];
	[oPanel setCanChooseFiles:NO];
	[oPanel setAllowsMultipleSelection:NO];
	[oPanel setTitle:@"Select Quake Directory"];
	
	if( [oPanel runModalForDirectory:nil file:nil types:nil] == NSOKButton )
	{
		[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:[oPanel directory] forKey:@"quakeDirectory"];
	}
}

@end
