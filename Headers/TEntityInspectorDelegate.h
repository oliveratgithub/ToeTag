
@interface TEntityInspectorDelegate : NSResponder
{
@public
	
	IBOutlet NSPanel* panelEntityInspector;
	NSMutableArray* selectedEntities;
	NSMutableArray* entityClasses;
	NSMutableArray* keyvalueStrings;
	
	// Key/Value panel
	
	NSMutableDictionary* keyvalues;
	IBOutlet NSTableView* keyvalueTableView;
	
	// Spawn Flag panel
	
	IBOutlet NSButton *SFCheck1, *SFCheck2, *SFCheck4, *SFCheck8, *SFCheck16, *SFCheck32, *SFCheck64, *SFCheck128, *SFCheck256, *SFCheck512, *SFCheck1024;
	IBOutlet NSTextField *SFText1, *SFText2, *SFText4, *SFText8, *SFText16, *SFText32, *SFText64, *SFText128, *SFText256, *SFText512, *SFText1024;
	
	// Description panel
	
	IBOutlet NSTextView* descTextView;

	// Other
	
	NSMutableDictionary* mapBitToCheck;
	NSMutableDictionary* mapBitToText;
}

-(void) refreshInspectors;
-(void) addToSpawnFlags:(int)InBit;
-(void) removeFromSpawnFlags:(int)InBit;

- (IBAction)onCheckBox1:(id)sender;
- (IBAction)onCheckBox2:(id)sender;
- (IBAction)onCheckBox4:(id)sender;
- (IBAction)onCheckBox8:(id)sender;
- (IBAction)onCheckBox16:(id)sender;
- (IBAction)onCheckBox32:(id)sender;
- (IBAction)onCheckBox64:(id)sender;
- (IBAction)onCheckBox128:(id)sender;
- (IBAction)onCheckBox256:(id)sender;
- (IBAction)onCheckBox512:(id)sender;
- (IBAction)onCheckBox1024:(id)sender;

- (IBAction)onUpButton:(id)sender;
- (IBAction)onDownButton:(id)sender;
- (IBAction)onAngleSlider:(id)sender;

- (IBAction)onNewButton:(id)sender;
- (IBAction)onDeleteButton:(id)sender;
-(void) deleteKeyValueAtRow:(int)InRow;

@end
