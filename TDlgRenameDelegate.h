
@class TTexture;

@interface TDlgRenameDelegate : NSResponder
{
@public
	IBOutlet NSPanel* renameTexturePanel;
	IBOutlet NSTextField* nameTextField;
	
	TTexture* texture;
}

-(IBAction) OnOK:(id)sender;
-(IBAction) OnCancel:(id)sender;

- (void)controlTextDidChange:(NSNotification*)aNotification;

@end
