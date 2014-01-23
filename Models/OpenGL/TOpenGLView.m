
// Base class for all OpenGL views.  Child classes derive from this class
// and add components to customize themselves.

@implementation TOpenGLView

-(void) awakeFromNib
{
	// don't call this or bad things happen (i.e. the MAP window doesn't even appear)
	//[super awakeFromNib];
	
	renderComponent = [[TRenderComponent alloc] initWithOwner:self];
	renderGridComponent = [[TRenderGridComponent alloc] initWithOwner:self];
	projectionComponent = [[TProjComponent alloc] initWithOwner:self];
	
	cameraLocation = [TVec3D new];
	cameraRotation = [TVec3D new];
	cameraLimits = [TVec3D new];
	
	bDocInitDone = NO;
	bReadyToRender = NO;
}

-(BOOL) acceptsFirstResponder
{
	return YES;
}

-(void) documentInit
{
}

- (BOOL)isOpaque
{
	return YES;
}

- (BOOL)isFlipped
{
	return YES;
}

// Goes through a drawing cycle but doesn't make any OpenGL calls.  This function
// is purely used to set up camera limitations for viewports that need it.

-(void) refreshCameraLimits
{
}

-(void) drawRect:(NSRect)bounds
{
	MAPDocument* map = [[[self window] windowController] document];
	
	if( bDocInitDone == NO )
	{
		bDocInitDone = YES;
		[self documentInit];
		[self registerTextures];
		[self display];
	}
	
	if( bReadyToRender == NO )
	{
		bReadyToRender = YES;
		[self prepareOpenGL];
	}
	
	[self draw:map];
}

-(void) draw:(MAPDocument*)InMAP
{
	glRenderMode( GL_RENDER );
	
	// -----------------------------------------------------
	// Draw the base world pass
	
	glDepthRange( 0.1f, 1.0f );
	[projectionComponent apply:NO];
	[self drawWorld:InMAP SelectedState:NO];
	
	// -----------------------------------------------------
	// Draw the selection highlights pass
	
	glDepthRange( 0.1f, .9995f );	// Change the depth range so that highlighted lines and polys will pop forward slightly
	glDepthMask( FALSE );			// Stop writing to the depth buffer
	
	[projectionComponent apply:NO];
	[self drawWorld:InMAP SelectedState:YES];
	
	glDepthMask( TRUE );
	
	// -----------------------------------------------------
	// Text
	
	/*
	GLint matrixMode;
	GLfloat height, width;

    GLint viewport[4];
    glGetIntegerv(GL_VIEWPORT, viewport);
	
	width = viewport[2];
	height = viewport[3];
	
	// set orthograhic 1:1  pixel transform in local view coords
	glGetIntegerv (GL_MATRIX_MODE, &matrixMode);
	glMatrixMode (GL_PROJECTION);
	glPushMatrix();
	glLoadIdentity ();
	glMatrixMode (GL_MODELVIEW);
	glPushMatrix();
	glLoadIdentity ();
	glScalef (2.0f / width, -2.0f /  height, 1.0f);
	glTranslatef (-width / 2.0f, -height / 2.0f, 0.0f);
	
	glColor4f (1.0f, 1.0f, 1.0f, 1.0f);
	[titleString drawAtPoint:NSMakePoint( 0, 0 )];
	
	glPopMatrix(); // GL_MODELVIEW
	glMatrixMode (GL_PROJECTION);
	glPopMatrix();
	glMatrixMode (matrixMode);
	*/
	
	// -----------------------------------------------------
	// Finish up
	
	glSwapAPPLE();
}

-(void) drawWorld:(MAPDocument*)InMAP SelectedState:(BOOL)InSelect
{
	// Draw with render component
	
	[renderComponent beginDraw:InSelect];
	
	if( InSelect == NO && renderGridComponent != nil )
	{
		[renderGridComponent draw:InMAP];
		glClear( GL_DEPTH_BUFFER_BIT );
	}
	
	[renderComponent draw:InMAP SelectedState:InSelect];
	
	[renderComponent endDraw:InSelect];
}

-(void) drawForPick:(MAPDocument*)InMAP Category:(ESelectCategory)InCategory
{
	// Draw with render component
	
	[renderComponent beginDraw:NO];
	[renderComponent drawForPick:InMAP Category:InCategory];
	[renderComponent endDraw:NO];
}

-(int) selectAtX:(float)InX Y:(float)InY DoubleClick:(BOOL)InDoubleClick ModifierFlags:(NSUInteger)InModFlags Category:(ESelectCategory)InCategory
{
	if( [NSOpenGLContext currentContext] != [self openGLContext] )
	{
		[[self openGLContext] makeCurrentContext];
	}

	int count = [projectionComponent pickAtX:InX Y:InY DoubleClick:InDoubleClick ModifierFlags:InModFlags Category:InCategory];
	
	[NSOpenGLContext clearCurrentContext];
	
	return count;
}

-(void)prepareOpenGL
{
	glEnable( GL_BLEND );
	glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );

	glEnable( GL_DEPTH_TEST );
	glDepthFunc( GL_LEQUAL );

	glEnable( GL_TEXTURE_2D );
	
	glPointParameterf( GL_POINT_SIZE_MIN, POINT_SZ );
	glPointSize( POINT_SZ );
	glEnable( GL_CULL_FACE );
	glShadeModel( GL_FLAT );
	glDisable( GL_LIGHTING );
	glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_FASTEST );
	glDisable( GL_LINE_SMOOTH );
	glDisable( GL_POINT_SMOOTH );
	glDisable( GL_NORMALIZE );
}

-(void) registerTextures
{
	[[self openGLContext] makeCurrentContext];
	
	MAPDocument* map = [[[self window] windowController] document];
	
	// Load all MDL skins into this content
	
	NSEnumerator *enumerator = [map->entityClasses objectEnumerator];
	TEntityClass* EC;
	
	while( EC = [enumerator nextObject] )
	{
		for( TEntityClassRenderComponent* ECRC in EC->renderComponenents )
		{
			if( [ECRC isKindOfClass:[TEntityClassRenderComponentMDL class]] )
			{
				for( TTexture* T in ((TEntityClassRenderComponentMDL*)ECRC)->model->skinTextures )
				{
					[T registerWithCurrentOpenGLContext];
				}
			}
		}
	}
	
	for( TTexture* T in map->texturesFromWADs )
	{
		[T registerWithCurrentOpenGLContext];
	}

	[NSOpenGLContext clearCurrentContext];
}

-(void) reshape
{
	[super reshape];
	
	NSRect rc = [self bounds];
	MAPDocument* map = [[[self window] windowController] document];
	
	[[self openGLContext] update];
 	[[self openGLContext] makeCurrentContext];
	
	// Viewport size
	
	glViewport( 0, 0, rc.size.width, rc.size.height );

	// Refresh viewport internals.
	//
	// NOTE: Checking if the document is nil is important since this function will
	// still be run when a MAP document is being closed down.  In that situation,
	// there is no valid document anymore and the editor will crash the next time
	// the code tries to access it.
	
	if( map != nil )
	{
		[self refreshCameraLimits];
	}
}

- (void)keyDown:(NSEvent *)theEvent
{
	MAPDocument* map = [[[self window] windowController] document];

	BOOL bShiftDown = ([theEvent modifierFlags] & NSShiftKeyMask) ? YES : NO;
	BOOL bCmdDown = ([theEvent modifierFlags] & NSCommandKeyMask) ? YES : NO;
	BOOL bOptionDown = ([theEvent modifierFlags] & NSAlternateKeyMask) ? YES : NO;
	
	[TGlobal G]->currentLevelView = self;
	
	switch( [theEvent keyCode] )
	{
		case 53:	// escape
		{
			[map deselect];
		}
		break;

		case 51:	// delete
		{
			[map->historyMgr startRecord:@"Delete All"];
			
			[map destroyAllSelected];
			[map markAllTexturesDirtyRenderArray];
			[map redrawLevelViewports];

			[map->historyMgr stopRecord];
		}
		break;

		case 6:		// Z
		{
			if( bCmdDown && !bShiftDown )
			{
				[map->historyMgr undo];
				[map refreshInspectors];
			}
			else if( bCmdDown && bShiftDown )
			{
				[map->historyMgr redo];
				[map refreshInspectors];
			}
		}
		break;

		case 33:	// [
		{
			map->gridSz /= 2.0f;
			map->gridSz = MAX( map->gridSz, 1.0f );
			
			[map redrawLevelViewports];
		}
		break;
			
		case 30:	// ]
		{
			map->gridSz *= 2.0f;
			map->gridSz = MIN( map->gridSz, 256.0f );
			
			[map redrawLevelViewports];
		}
		break;
			
		case 49:	// space bar
		{
			[map duplicateSelected];
			[map redrawLevelViewports];
		}
		break;
			
		case 123:	// cursor left
		{
			if( !bCmdDown && !bOptionDown )
			{
				// OFFSET
				int offset = bShiftDown ? 4 : 1;
				
				[map offsetSelectedTexturesByU:offset V:0];
				[map redrawLevelViewports];
			}
			else if( bCmdDown && !bOptionDown )
			{
				// ROTATION
				int offset = bShiftDown ? 15 : 5;
				
				[map rotateSelectedTexturesBy:offset];
				[map redrawLevelViewports];
			}
			else if( bCmdDown && bOptionDown )
			{
				// SCALING (SHIFT = flip)
				float offset = bShiftDown ? -1.0f : 0.9f;
				
				[map scaleSelectedTexturesByU:offset V:1.0f];
				[map redrawLevelViewports];
			}
		}
		break;
			
		case 124:	// cursor right
		{
			if( !bCmdDown && !bOptionDown )
			{
				// OFFSET
				int offset = bShiftDown ? 4 : 1;
				
				[map offsetSelectedTexturesByU:-offset V:0];
				[map redrawLevelViewports];
			}
			else if( bCmdDown && !bOptionDown )
			{
				// ROTATION
				int offset = bShiftDown ? 15 : 5;
				
				[map rotateSelectedTexturesBy:-offset];
				[map redrawLevelViewports];
			}
			else if( bCmdDown && bOptionDown )
			{
				// SCALING (SHIFT = flip)
				float offset = bShiftDown ? -1.0f : 1.1f;
				
				[map scaleSelectedTexturesByU:offset V:1.0f];
				[map redrawLevelViewports];
			}
		}
		break;

		case 126:	// cursor up
		{
			if( !bCmdDown && !bOptionDown )
			{
				// OFFSET
				int offset = bShiftDown ? 4 : 1;
				
				[map offsetSelectedTexturesByU:0 V:offset];
				[map redrawLevelViewports];
			}
			else if( bCmdDown && bOptionDown )
			{
				// SCALING (SHIFT = flip)
				float offset = bShiftDown ? -1.0f : 1.1f;
				
				[map scaleSelectedTexturesByU:1.0f V:offset];
				[map redrawLevelViewports];
			}
		}
		break;
			
		case 125:	// cursor down
		{
			if( !bCmdDown && !bOptionDown )
			{
				// OFFSET
				int offset = bShiftDown ? 4 : 1;
				
				[map offsetSelectedTexturesByU:0 V:-offset];
				[map redrawLevelViewports];
			}
			else if( bCmdDown && bOptionDown )
			{
				// SCALING (SHIFT = flip)
				float offset = bShiftDown ? -1.0f : 0.9f;
				
				[map scaleSelectedTexturesByU:1.0f V:offset];
				[map redrawLevelViewports];
			}
		}
		break;
			
		case 15:	// R
		{
			float angle = 15;
			if( bShiftDown )
			{
				angle *= -1;
			}
			
			switch( orientation )
			{
				case TO_Top_XZ:
					[map rotateSelectionsByX:0 Y:-angle Z:0];
					break;
					
				case TO_Side_YZ:
					[map rotateSelectionsByX:angle Y:0 Z:0];
					break;
					
				case TO_Front_XY:
					[map rotateSelectionsByX:0 Y:0 Z:-angle];
					break;
					
				default:
					[map rotateSelectionsByX:0 Y:angle Z:0];
					break;
			}
			
			[map redrawLevelViewports];
		}
		break;
			
		case 17:	// T
		{
			if( !bShiftDown && bCmdDown && bOptionDown )
			{
				[map synchronizeTextureBrowserWithSelectedFaces];
			}
		}
		break;

		case 18:	// 1
			if( !bCmdDown && !bOptionDown )
			{
				map->gridSz = 1;
			}
			else if( bCmdDown && bOptionDown )
			{
				[map setBookmark:@"1"];
			}
			else if( bCmdDown && !bOptionDown )
			{
				[map jumpToBookmark:@"1"];
			}
			[map redrawLevelViewports];
			break;
			
		case 19:	// 2
			if( !bCmdDown && !bOptionDown )
			{
				map->gridSz = 2;
			}
			else if( bCmdDown && bOptionDown )
			{
				[map setBookmark:@"2"];
			}
			else if( bCmdDown && !bOptionDown )
			{
				[map jumpToBookmark:@"2"];
			}
			[map redrawLevelViewports];
			break;
			
		case 20:	// 3
			if( !bCmdDown && !bOptionDown )
			{
				map->gridSz = 4;
			}
			else if( bCmdDown && bOptionDown )
			{
				[map setBookmark:@"3"];
			}
			else if( bCmdDown && !bOptionDown )
			{
				[map jumpToBookmark:@"3"];
			}
			[map redrawLevelViewports];
			break;
			
		case 21:	// 4
			if( !bCmdDown && !bOptionDown )
			{
				map->gridSz = 8;
			}
			else if( bCmdDown && bOptionDown )
			{
				[map setBookmark:@"4"];
			}
			else if( bCmdDown && !bOptionDown )
			{
				[map jumpToBookmark:@"4"];
			}
			[map redrawLevelViewports];
			break;
			
		case 23:	// 5
			if( !bCmdDown && !bOptionDown )
			{
				map->gridSz = 16;
			}
			else if( bCmdDown && bOptionDown )
			{
				[map setBookmark:@"5"];
			}
			else if( bCmdDown && !bOptionDown )
			{
				[map jumpToBookmark:@"5"];
			}
			[map redrawLevelViewports];
			break;
			
		case 22:	// 6
			if( !bCmdDown && !bOptionDown )
			{
				map->gridSz = 32;
			}
			else if( bCmdDown && bOptionDown )
			{
				[map setBookmark:@"6"];
			}
			else if( bCmdDown && !bOptionDown )
			{
				[map jumpToBookmark:@"6"];
			}
			[map redrawLevelViewports];
			break;
			
		case 26:	// 7
			if( !bCmdDown && !bOptionDown )
			{
				map->gridSz = 64;
			}
			else if( bCmdDown && bOptionDown )
			{
				[map setBookmark:@"7"];
			}
			else if( bCmdDown && !bOptionDown )
			{
				[map jumpToBookmark:@"7"];
			}
			[map redrawLevelViewports];
			break;
			
		case 28:	// 8
			if( !bCmdDown && !bOptionDown )
			{
				map->gridSz = 128;
			}
			else if( bCmdDown && !bOptionDown )
			{
				[map setBookmark:@"8"];
			}
			else if( !bCmdDown && bOptionDown )
			{
				[map jumpToBookmark:@"8"];
			}
			[map redrawLevelViewports];
			break;
			
		case 25:	// 9
			if( !bCmdDown && !bOptionDown )
			{
				map->gridSz = 256;
			}
			else if( bCmdDown && bOptionDown )
			{
				[map setBookmark:@"9"];
			}
			else if( bCmdDown && !bOptionDown )
			{
				[map jumpToBookmark:@"9"];
			}
			[map redrawLevelViewports];
			break;
			
		case 29:	// 0
			if( !bCmdDown && !bOptionDown )
			{
				map->gridSz = 0;
			}
			else if( bCmdDown && bOptionDown )
			{
				[map setBookmark:@"0"];
			}
			else if( bCmdDown && !bOptionDown )
			{
				[map jumpToBookmark:@"0"];
			}
			[map redrawLevelViewports];
			break;
			
		default:
			[super keyDown:theEvent];
			break;
	}
}

-(void) scrollToSelectedTexture
{
}

// Returns a TVec3D containing 0 or 1 for each axis.  This allows ortho viewports
// to relate which axis they use and don't use.

-(TVec3D*) getAxisMask
{
	return [[TVec3D alloc] initWithX:1 Y:0 Z:1];
}

-(NSMutableString*) exportToText
{
	NSMutableString* string = [NSMutableString string];
	
	return string;
}

-(void) importFromText:(NSString*)InText
{
}
		 
-(BOOL) isOrthoView
{
	return NO;
}

@end
