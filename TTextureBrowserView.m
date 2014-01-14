
@implementation TTextureBrowserView

-(void) awakeFromNib
{
	[super awakeFromNib];
	
	renderComponent = [[TRenderTextureBrowserComponent alloc] initWithOwner:self];
	projectionComponent = [[TTextureBrowserProjComponent alloc] initWithOwner:self];
	renderGridComponent = nil;
	
	texNameFilter = @"";
	usageFilter = TBUF_All;

	if( [[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/QuickLookUI.framework"] load] )
	{
		[[[QLPreviewPanel sharedPreviewPanel] windowController] setDelegate:self];
	}
}

- (NSRect)previewPanel:(NSPanel*)panel frameForURL:(NSURL*)URL
{
	MAPDocument* map = [[[self window] windowController] document];
	NSMutableArray* selections = [map->selMgr getSelections:TSC_Texture];
	
	NSRect rc = NSMakeRect( 0,0,0,0 );

	if( [selections count] > 0 )
	{
		TTexture* T = [selections objectAtIndex:0];
		
		rc = NSMakeRect( T->lastXPos + 2.0, -T->lastYPos - cameraLocation->y + 2.0, T->width * orthoZoom, T->height * orthoZoom );
		
		NSPoint windowPoint = [self convertPoint:rc.origin toView:nil];
		rc.origin = [[self window] convertBaseToScreen:windowPoint];
		rc.origin.y -= rc.size.height;
	}
	
	return rc;
}

-(BOOL) acceptsFirstResponder
{
	return YES;
}

- (BOOL)isOpaque
{
	return YES;
}

-(void) documentInit
{
	MAPDocument* map = [[[self window] windowController] document];
	[map->textureViewports addObject:self];
}

- (void)scrollWheel:(NSEvent *)theEvent
{
	cameraLocation->y += theEvent.deltaY * -4.0f;
	
	[self refreshCameraLimits];
	[self display];
}

- (IBAction)onZoomSliderChange:(id)sender
{
	orthoZoom = [sender floatValue];
	
	[self refreshCameraLimits];
	[self display];
}

- (IBAction)onFilterChanged:(id)sender
{
	usageFilter = [sender selectedSegment];
	
	[self refreshCameraLimits];
	[self display];
}

- (IBAction)onFilterTextChanged:(id)sender
{
	texNameFilter = [[sender stringValue] mutableCopy];
	
	cameraLocation->y = 0;
	
	[self display];
}

-(void) refreshCameraLimits
{
	[renderComponent drawWithoutOutput];

	if( cameraLocation->y < 0 )
	{
		cameraLocation->y = 0;
	}
	if( cameraLocation->y > cameraLimits->y )
	{
		cameraLocation->y = cameraLimits->y;
	}
}

-(void) mouseDown:(NSEvent *)theEvent
{
	MAPDocument* map = [[[self window] windowController] document];
	BOOL bDoubleClick = ([theEvent clickCount] == 2) ? YES : NO;
	[TGlobal G]->currentLevelView = self;
	
	NSPoint event_location = [theEvent locationInWindow];
	NSPoint local_point = [self convertPoint:event_location fromView:nil];
	
	[self selectAtX:local_point.x Y:local_point.y DoubleClick:bDoubleClick ModifierFlags:[theEvent modifierFlags] Category:TSC_Texture];
	
	[map applySelectedTexture];
	[self quickLookSelectedItems];

	[self display];
}

-(void) scrollToSelectedTexture
{
	MAPDocument* map = [[[self window] windowController] document];

	[self refreshCameraLimits];
	
	TTexture* T = [map findTextureByName:[map->selMgr getSelectedTextureName]];
	cameraLocation->y = -T->lastYPos;
	
	[[self window] flushWindow];
}

-(void) toggleQuickLook
{
	if( [[QLPreviewPanel sharedPreviewPanel] isOpen] )
	{
		[[QLPreviewPanel sharedPreviewPanel] closeWithEffect:2];
	}
	else
	{
		// Otherwise, set the current items
		[self quickLookSelectedItems];
		
		// And then display the panel
		[[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFrontWithEffect:2];
		
		// Restore the focus to our window to demo the selection changing, scrolling (left/right)
		// and closing (space) functionality
		[[self window] makeKeyWindow];
	}
}

- (void)quickLookSelectedItems
{
	MAPDocument* map = [[[self window] windowController] document];
	NSMutableArray* URLs = [NSMutableArray new];
	NSMutableArray* selections = [map->selMgr getSelections:TSC_Texture];
	
	for( TTexture* T in selections )
	{
		NSString* basePath = NSTemporaryDirectory();
		NSString* filename = [NSString stringWithFormat:@"%@%@.jpeg", basePath, T->name];
		
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
		NSData* bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:nil];
		[bitmapData writeToFile:filename atomically:YES];
		
		[URLs addObject:[NSURL fileURLWithPath:filename]];
	}
	
	// The code above just gathers an array of NSURLs representing the selected items,
	// to set here
	[[QLPreviewPanel sharedPreviewPanel] setURLs:URLs currentIndex:0 preservingDisplayState:YES];
}

- (void)keyDown:(NSEvent *)theEvent
{
	[TGlobal G]->currentLevelView = self;
	
	switch( [theEvent keyCode] )
	{
		case 49:	// space bar
		{
			[self toggleQuickLook];
		}
		break;
			
		default:
			[super keyDown:theEvent];
			break;
	}
}

@end
