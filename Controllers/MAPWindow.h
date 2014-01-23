
@class TOrthoLevelView;

@interface MAPWindow : NSWindow
{
@public
	IBOutlet NSPanel* panelFaceInspector;
	IBOutlet NSPanel* panelEntityInspector;
	IBOutlet NSPanel* panelBuildInspector;
	
	NSMutableArray* visiblePanels;
	
	ERebuildOption rebuildOption;
	NSMutableString* buildResultString;
	IBOutlet NSButton* jumpToLeakButton;
}

- (IBAction)OnShowFaceInspector:(id)sender;
- (IBAction)OnShowEntityInspector:(id)sender;
- (IBAction)OnShowBuildInspector:(id)sender;

-(void) refreshInspectors;

- (IBAction)onHideSelected:(id)sender;
- (IBAction)onIsolate:(id)sender;
- (IBAction)onShowAll:(id)sender;
- (IBAction)onRebuildOption:(id)sender;
- (IBAction)onCompile:(id)sender;
- (IBAction)onPlayLevel:(id)sender;
- (IBAction)onEntityFilter:(id)sender;
- (IBAction)onShowEditorEntitiesOnly:(id)sender;
-(NSString*) runTask:(NSString*)InApp UseBSPFile:(BOOL)bUseBSPFile Args:(NSArray*)InArgs;
-(void) emitHeaderToBuildResults:(NSString*)InText;
-(void) emitTextToBuildResults:(NSString*)InText;
- (IBAction)OnToolsBrushBuildersCube:(id)sender;
- (IBAction)OnToolsBrushBuildersWedge:(id)sender;
- (IBAction)OnToolsBrushBuildersCylinder6:(id)sender;
- (IBAction)OnToolsBrushBuildersCylinder8:(id)sender;
- (IBAction)OnToolsBrushBuildersCylinder12:(id)sender;
- (IBAction)OnToolsBrushBuildersSpike3:(id)sender;
- (IBAction)OnToolsBrushBuildersSpike4:(id)sender;
- (IBAction)OnToolsBrushBuildersSpike8:(id)sender;
- (IBAction)OnToolsBrushBuildersSpike12:(id)sender;
-(void) buildBrush:(TBrushBuilder*)InBrushBuilder Args:(NSArray*)InArgs;

@end
