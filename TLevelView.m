
@implementation TLevelView

-(void) awakeFromNib
{
	[super awakeFromNib];
	
	renderComponent = [[TRenderLevelTexturedComponent alloc] initWithOwner:self];
	
	orientation = TO_Perspective;

	cameraLocation->x = 0;
	cameraLocation->y = 0;
	cameraLocation->z = 0;
	
	cameraRotation->x = 0;
	cameraRotation->y = 0;
	cameraRotation->z = 0;
}

- (BOOL)isOpaque
{
	return YES;
}

-(void) documentInit
{
	MAPDocument* map = [[[self window] windowController] document];
	
	// Register with the MAP document
	
	[map->levelViewports addObject:self];
	[map->textureViewports addObject:self];
	
	// Config lines
	
	for( NSString* S in map->configLines )
	{
		[self importFromText:S];
	}
}

- (void)scrollWheel:(NSEvent *)theEvent
{
	TVec3D* dir = [TVec3D dirFromYaw:cameraRotation->y];
	
	cameraLocation->x += dir->x * [theEvent deltaY] * 4.0f;
	cameraLocation->z += dir->z * [theEvent deltaY] * 4.0f;
	
	[self display];
}

-(void) dragAxisFromDir:(TVec3D*)InDir OutX:(TVec3D**)OutX OutY:(TVec3D**)OutY
{
	float bestaxis, dot, best, i;
	
	best = 0;
	bestaxis = 0;
	
	for( i = 0 ; i < 6 ; i++ )
	{
		dot = [TVec3D dotA:InDir andB:[[TGlobal G]->dragAxis objectAtIndex:(i * 3)]];
		
		if( dot > best )
		{
			best = dot;
			bestaxis = i;
		}
	}
	
	TVec3D* x = [[TGlobal G]->dragAxis objectAtIndex:(bestaxis*3)+1];
	TVec3D* y = [[TGlobal G]->dragAxis objectAtIndex:(bestaxis*3)+2];
	
	*OutX = [x mutableCopy];
	*OutY = [y mutableCopy];
}

-(void) mouseDown:(NSEvent *)theEvent
{
	[TGlobal G]->currentLevelView = self;
	
	BOOL bDoubleClick = ([theEvent clickCount] == 2) ? YES : NO;
	TVec3D *XVec, *YVec;
	float XDelta, YDelta;
	MAPDocument* map = [[[self window] windowController] document];
    BOOL bCaptureMouse = YES;
	int mouseAction = TMA_Select;
	
	if( ([theEvent modifierFlags] & NSAlternateKeyMask) && !([theEvent modifierFlags] & NSControlKeyMask) )
	{
		mouseAction = TMA_RotateCamera;
	}
	else if( [theEvent modifierFlags] & NSShiftKeyMask )
	{
		mouseAction = TMA_SelectFace;
	}
	else if( [theEvent modifierFlags] & NSControlKeyMask )
	{
		[map->historyMgr startRecord:@"Drag"];
		
		mouseAction = TMA_DragSelection;
		
		TVec3D* dir = [TVec3D dirFromYaw:cameraRotation->y];
		XVec = [TVec3D new];
		YVec = [TVec3D new];
		[self dragAxisFromDir:dir OutX:&XVec OutY:&YVec];
		
		XDelta = YDelta = 0.0;
		
		// Convert any existing selected faces into vertex selections.  This is how
		// we allow the user to select faces and drag them.

		for( TEntity* E in map->entities )
		{
			for( TBrush* B in E->brushes )
			{
				for( TFace* F in B->faces )
				{
					if( [map->selMgr isSelected:F] )
					{
						[map->selMgr addSelection:B];
						
						for( TVec3D* V in F->verts )
						{
							[B selectVertsNear:V MAP:map];
						}
						
						[map->selMgr removeSelection:F];
					}
				}
			}
		}
	}

	// Unhook the mouse from the cursor and hide the cursor
	
	CGAssociateMouseAndMouseCursorPosition( FALSE );
	CGDisplayHideCursor( kCGDirectMainDisplay );
	
	while( bCaptureMouse )
	{
		theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];

		switch( [theEvent type] )
		{
			case NSLeftMouseDragged:

				if( mouseAction == TMA_RotateCamera )
				{
					cameraRotation->x += [theEvent deltaY] / 2.0;
					cameraRotation->y += [theEvent deltaX] / 2.0;
					
					[self display];
				}
				else if( mouseAction == TMA_DragSelection )
				{
					float dx = [theEvent deltaX], dy = [theEvent deltaY];
					
					XDelta += dx;
					YDelta += dy;
					
					float xdir = (XDelta < 0.0) ? -1 : 1;
					float ydir = (YDelta < 0.0) ? -1 : 1;
					
					if( [theEvent modifierFlags] & NSAlternateKeyMask )
					{
						if( fabs(YDelta) > (map->gridSz / 3.0) )
						{
							ydir *= roundf(fabs(YDelta) / (map->gridSz / 3.0));
							[map DragSelectionsBy:[[TVec3D alloc] initWithX:0 Y:map->gridSz * -ydir Z:0]];
							XDelta = YDelta = 0;
						}
					}
					else
					{
						if( fabs(XDelta) > (map->gridSz / 3.0) || fabs(YDelta) > (map->gridSz / 3.0) )
						{
							xdir *= roundf(fabs(XDelta) / (map->gridSz / 3.0));
							ydir *= roundf(fabs(YDelta) / (map->gridSz / 3.0));
							
							if( fabs(XDelta) > fabs(YDelta) )
							{
								[map DragSelectionsBy:[[TVec3D alloc] initWithX:(XVec->x * map->gridSz) * xdir Y:(XVec->y * map->gridSz) * xdir Z:(XVec->z * map->gridSz) * xdir]];
								XDelta = 0;
								YDelta /= 2;
							}
							else
							{
								[map DragSelectionsBy:[[TVec3D alloc] initWithX:(YVec->x * map->gridSz) * ydir Y:(YVec->y * map->gridSz) * ydir Z:(YVec->z * map->gridSz) * ydir]];
								XDelta /= 2;
								YDelta = 0;
							}
						}
					}
				}
				break;

			case NSLeftMouseUp:

				// Hook up the mouse to the cursor and show the cursor
				
				CGAssociateMouseAndMouseCursorPosition( TRUE );
				CGDisplayShowCursor( kCGDirectMainDisplay );

				NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
				
				if( mouseAction == TMA_Select )
				{
					if( [self selectAtX:mouseLoc.x Y:mouseLoc.y DoubleClick:bDoubleClick ModifierFlags:[theEvent modifierFlags] Category:TSC_Vertex] == 0 )
					{
						if( [self selectAtX:mouseLoc.x Y:mouseLoc.y DoubleClick:bDoubleClick ModifierFlags:[theEvent modifierFlags] Category:TSC_Edge] == 0 )
						{
							[self selectAtX:mouseLoc.x Y:mouseLoc.y DoubleClick:bDoubleClick ModifierFlags:[theEvent modifierFlags] Category:TSC_Level];
						}
					}
				}
				else if( mouseAction == TMA_SelectFace )
				{
					[self selectAtX:mouseLoc.x Y:mouseLoc.y DoubleClick:bDoubleClick ModifierFlags:[theEvent modifierFlags] Category:TSC_Face];
				}
				else if( mouseAction == TMA_DragSelection )
				{
					[map->historyMgr stopRecord];
				}
				
				bCaptureMouse = NO;
				break;
		}
		
		[map->selMgr markTexturesOnSelectedDirtyRenderArray];
		[map redrawLevelViewports];
	}
}

-(void) otherMouseDown:(NSEvent *)theEvent
{
	[TGlobal G]->currentLevelView = self;
	
	MAPDocument* map = [[[self window] windowController] document];
    BOOL bCaptureMouse = YES;
	int mouseAction = TMA_Select;
	float XDelta;
	
	if( [theEvent modifierFlags] & NSAlternateKeyMask )
	{
		mouseAction = TMA_PanCamera;
	}
	else if( [theEvent modifierFlags] & NSControlKeyMask )
	{
		[map->historyMgr startRecord:@"Rotate"];
		
		mouseAction = TMA_RotateSelection;
		XDelta = 0;
	}
	
	// Unhook the mouse from the cursor and hide the cursor
	
	CGAssociateMouseAndMouseCursorPosition( FALSE );
	CGDisplayHideCursor( kCGDirectMainDisplay );
	
	while( bCaptureMouse )
	{
		theEvent = [[self window] nextEventMatchingMask: NSOtherMouseUpMask | NSOtherMouseDraggedMask];
		
		switch( [theEvent type] )
		{
			case NSOtherMouseDragged:
			{
				if( mouseAction == TMA_PanCamera )
				{
					TVec3D* dir = [TVec3D crossA:[TVec3D dirFromYaw:cameraRotation->y] andB:[[TVec3D alloc] initWithX:0 Y:1 Z:0] ];
					
					cameraLocation->x -= dir->x * [theEvent deltaX];
					cameraLocation->z -= dir->z * [theEvent deltaX];
					
					cameraLocation->y -= [theEvent deltaY];
				}
				else if( mouseAction == TMA_RotateSelection )
				{
					float dx = [theEvent deltaX];
					
					XDelta += dx;
					
					float xdir = (XDelta < 0.0) ? -1 : 1;
					
					if( fabs(XDelta) > (map->gridSz / 2.0f) )
					{
						[map rotateSelectionsByX:0 Y:(xdir * 15.0) Z:0];
						XDelta = 0;
						
						[map redrawLevelViewports];
					}
				}
				
				[self display];
			}
			break;
				
			case NSOtherMouseUp:
			{	
				// Hook up the mouse to the cursor and show the cursor
				
				CGAssociateMouseAndMouseCursorPosition( TRUE );
				CGDisplayShowCursor( kCGDirectMainDisplay );
				
 				if( mouseAction == TMA_RotateSelection )
				{
					[map->historyMgr stopRecord];
				}
				
				bCaptureMouse = NO;
 			}
			break;
		}
	}
}

-(TVec3D*) getAxisMask
{
	return [[TVec3D alloc] initWithX:1 Y:0 Z:1];
}

-(NSMutableString*) exportToText
{
	NSMutableString* string = [NSMutableString string];
	
	[string appendFormat:@"// CONFIG_VIEWPORT:3D %f %f %f %f %f %f\n", cameraLocation->x, cameraLocation->y, cameraLocation->z, cameraRotation->x, cameraRotation->y, cameraRotation->z ];
	
	return string;
}

-(void) importFromText:(NSString*)InText
{
	NSArray* chunks = [InText componentsSeparatedByString:@":"];
	
	if( [[chunks objectAtIndex:0] isEqualToString:@"// CONFIG_VIEWPORT"] == NO )
	{
		return;
	}
	
	NSArray* subchunks = [[chunks objectAtIndex:1] componentsSeparatedByString:@" "];
	
	if( [subchunks count] > 0 && [[subchunks objectAtIndex:0] isEqualToString:@"3D"] )
	{
		cameraLocation = [[TVec3D alloc] initWithX:[[subchunks objectAtIndex:1] floatValue] Y:[[subchunks objectAtIndex:2] floatValue] Z:[[subchunks objectAtIndex:3] floatValue]];
		cameraRotation = [[TVec3D alloc] initWithX:[[subchunks objectAtIndex:4] floatValue] Y:[[subchunks objectAtIndex:5] floatValue] Z:[[subchunks objectAtIndex:6] floatValue]];
		
		[[self window] flushWindow];
	}
}

@end
