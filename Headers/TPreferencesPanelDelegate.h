
@interface TPreferencesPanelDelegate : NSResponder
{
@public
	IBOutlet NSTextField* quakeDirTextField;
	IBOutlet NSPanel* preferencesPanel;
}

-(IBAction) OnBrowseForDirectory:(id)sender;

@end
