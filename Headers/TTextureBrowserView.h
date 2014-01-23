
// A 2D viewport that displays the set of loaded textures.

@interface TTextureBrowserView : TOpenGLView
{
@public
	NSString* texNameFilter;
	ETextureBrowserUsageFilter usageFilter;
}

- (IBAction)onZoomSliderChange:(id)sender;
- (IBAction)onFilterTextChanged:(id)sender;
- (IBAction)onFilterChanged:(id)sender;

-(void) documentInit;
-(void) refreshCameraLimits;
-(void) scrollToSelectedTexture;

- (void) toggleQuickLook;
- (void)quickLookSelectedItems;

@end
