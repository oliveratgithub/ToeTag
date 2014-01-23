
@class TBrushBuilder;
@class TOpenGLView;

@interface TApplicationDelegate : NSResponder
{
@public
	IBOutlet NSMenuItem* createEntityMenu;
	IBOutlet TOpenGLView* orthoViewport;
	BOOL bCreateEntityMenuInitialized;
	IBOutlet NSPanel* preferencesPanel;
	IBOutlet NSPanel* dlgRenameTexture;
}

- (IBAction)onFileOpenPointFile:(id)sender;
- (IBAction)onFileClearPointFile:(id)sender;
- (IBAction)onViewFaceInspector:(id)sender;
- (IBAction)onViewEntityInspector:(id)sender;
- (IBAction)onViewBuildInspector:(id)sender;
- (IBAction)onToolsTexturesOpen:(id)sender;
- (IBAction)onToolsTexturesAppend:(id)sender;
- (IBAction)onToolsTexturesSave:(id)sender;
- (IBAction)onToolsTexturesImport:(id)sender;
- (IBAction)onToolsTexturesImportWithFullbrights:(id)sender;
- (IBAction)onToolsTexturesExport:(id)sender;
- (IBAction)onToolsTexturesDelete:(id)sender;
- (IBAction)onToolsTexturesRename:(id)sender;
- (IBAction)onToolsTexturesSynchronizeBrowser:(id)sender;
- (IBAction)onEditUndo:(id)sender;
- (IBAction)onEditRedo:(id)sender;
- (IBAction)onEditSelectAll:(id)sender;
- (IBAction)onEditSelectMatching:(id)sender;
- (IBAction)onEditSelectWholeEntity:(id)sender;
- (IBAction)onEditDeselect:(id)sender;
- (IBAction)onEditHideSelected:(id)sender;
- (IBAction)onEditIsolateSelected:(id)sender;
- (IBAction)onEditShowAll:(id)sender;
- (IBAction)onCreateEntityItem:(id)sender;
- (IBAction)onJoin:(id)sender;
- (IBAction)onSplit:(id)sender;
- (IBAction)OnToolsEntityQuickGroupCreate:(id)sender;
- (IBAction)OnToolsEntityQuickGroupSelect:(id)sender;
- (IBAction)OnToolsEntityQuickGroupDelete:(id)sender;
- (IBAction)onToolsCSGHollowSelected:(id)sender;
- (IBAction)onToolsCSGCreateClipBrush:(id)sender;
- (IBAction)onToolsCSGMergeConvexHull:(id)sender;
- (IBAction)onToolsCSGMergeBoundingBox:(id)sender;
- (IBAction)onToolsCSGSubtractFromWorld:(id)sender;
- (IBAction)onToolsCSGClipAgainstWorld:(id)sender;
- (IBAction)onToolsCSGBevel:(id)sender;
- (IBAction)onToolsCSGExtrude:(id)sender;
- (IBAction)onToolsCSGSplit:(id)sender;
- (IBAction)onToolsCSGTriangulateFan:(id)sender;
- (IBAction)onToolsCSGTriangulateFromCenter:(id)sender;
- (IBAction)onToolsCSGOptimize:(id)sender;
- (IBAction)onToolsTransformMirrorX:(id)sender;
- (IBAction)onToolsTransformMirrorY:(id)sender;
- (IBAction)onToolsTransformMirrorZ:(id)sender;
- (IBAction)OnPreferences:(id)sender;
- (IBAction)OnEditTextureLock:(id)sender;
- (IBAction)OnEditQuantizeVerts:(id)sender;
- (IBAction)OnToolsAutoTargetEntities:(id)sender;
- (IBAction)OnToolsDropPathCorner:(id)sender;
- (IBAction)OnToolsCreateRoute:(id)sender;

-(void) selectQuickGroupID:(int)InQuickGroupID;
-(void) populateCreateEntityMenu:(MAPDocument*)InMAP;

@end
