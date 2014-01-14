
@implementation TDlgRenameDelegate

-(IBAction) OnOK:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	NSString* newName = [[nameTextField stringValue] mutableCopy];
	
	if( [newName length] > 0 && [newName length] < 9 )
	{
		for( TEntity* E in map->entities )
		{
			for( TBrush* B in E->brushes )
			{
				for( TFace* F in B->faces )
				{
					if( [F->textureName isEqualToString:texture->name] )
					{
						F->textureName = [newName uppercaseString];
					}
				}
			}
		}

		texture->name = [newName uppercaseString];
	}
	
	[map registerTexturesWithViewports:YES];
	
	[renameTexturePanel orderOut:nil];
	[NSApp endSheet:renameTexturePanel];	
}

-(IBAction) OnCancel:(id)sender
{
	[renameTexturePanel orderOut:nil];
	[NSApp endSheet:renameTexturePanel];	
}

- (void)controlTextDidChange:(NSNotification*)aNotification
{
	// Limit the input to 8 characters as that's the MAX for Quake textures
	
	NSString* text = [[nameTextField stringValue] mutableCopy];
	
	if( [text length] > 16 )
	{
		text = [text substringToIndex:16];
		[nameTextField setStringValue:text];
	}
}

@end
