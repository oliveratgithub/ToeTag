
@implementation TOrthoLevelView

-(void) awakeFromNib
{
	[super awakeFromNib];
	
	projectionComponent = [[TOrthoProjComponent alloc] initWithOwner:self];
	renderComponent = [[TRenderLevelOrthoComponent alloc] initWithOwner:self];
	renderGridComponent = [[TRenderGridOrthoComponent alloc] initWithOwner:self];
	orientation = TO_Top_XZ;
	bPlacingRotationPivot = NO;
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

- (IBAction)onOrientationChange:(id)sender
{
	switch( [sender selectedSegment] )
	{
		case 0:
			orientation = TO_Top_XZ;
			break;

		case 1:
			orientation = TO_Front_XY;
			break;

		case 2:
			orientation = TO_Side_YZ;
			break;
	}
	
	[self display];
}

-(void) draw:(MAPDocument*)InMAP
{
	glRenderMode( GL_RENDER );
	
	// -----------------------------------------------------
	// Draw the base world pass
	
	[projectionComponent apply:NO];
	[self drawWorld:InMAP SelectedState:NO];

	// -----------------------------------------------------
	// Clear the depth buffer so that selections will pop to the front in the ortho views
	
	glClear( GL_DEPTH_BUFFER_BIT );

	// -----------------------------------------------------
	// Draw the selection highlights pass
	
	glDepthMask( FALSE );			// Stop writing to the depth buffer
	
	[projectionComponent apply:NO];
	[self drawWorld:InMAP SelectedState:YES];
	
	glDepthMask( TRUE );

	// Draw pivot location if it is non-nil
	
	if( [TGlobal G]->pivotLocation != nil )
	{
		glClear( GL_DEPTH_BUFFER_BIT );
		
		glDisable( GL_TEXTURE_2D );
		glLineWidth( 2.0f );
		glColor3f( 1, 0, 0 );
		
		TVec3D* pivot = [TGlobal G]->pivotLocation;
		float sz = 8.0f * orthoZoom;
		
		glBegin( GL_LINES );
		{
			glVertex3f( pivot->x - sz, pivot->y, pivot->z );
			glVertex3f( pivot->x + sz, pivot->y, pivot->z );

			glVertex3f( pivot->x, pivot->y - sz, pivot->z );
			glVertex3f( pivot->x, pivot->y + sz, pivot->z );

			glVertex3f( pivot->x, pivot->y, pivot->z - sz );
			glVertex3f( pivot->x, pivot->y, pivot->z + sz );
		}
		glEnd();
		
		glColor3f( 1, 1, 1 );
		glLineWidth( 1.0f );
		glEnable( GL_TEXTURE_2D );
	}
	
	// Draw special indicators based on the start/end point
	
	if( startPoint != nil && endPoint != nil )
	{
		glClear( GL_DEPTH_BUFFER_BIT );
		
		glDisable( GL_TEXTURE_2D );
		glLineWidth( 2.0f );
		glColor3f( 1, 0, 0 );
		
		switch( ownerMouseAction )
		{
			case TMA_SetClipPoints:
			{
				// Compute the middle point and draw a normal arrow, showing which side of the plane will be doing the clipping
				float sz = [[TVec3D subtractA:endPoint andB:startPoint] getSizeSquared] / 4.0f;
				TVec3D* mid = [TVec3D addA:startPoint andB:[TVec3D scale:[TVec3D subtractA:endPoint andB:startPoint] By:0.5]];
				TVec3D* arrowHead = [TVec3D addA:mid andB:[TVec3D scale:clipPlane->normal By:sz]];
				
				glBegin( GL_LINES );
				{
					glVertex3fv( &startPoint->x );
					glVertex3fv( &endPoint->x );
					
					glVertex3fv( &mid->x );
					glVertex3fv( &arrowHead->x );
				}
				glEnd();
			}
			break;

			case TMA_BoxSelection:
			{
				TBBox* bbox = [TBBox new];
				[bbox addVertex:startPoint];
				[bbox addVertex:endPoint];
				
				glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
				[TRenderUtilBox drawBoxBBox:bbox];

				glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
				glColor4f( 1, 0, 0, 0.25 );
				[TRenderUtilBox drawBoxBBox:bbox];
			}
			break;
		}
		
		glColor3f( 1, 1, 1 );
		glLineWidth( 1.0f );
		glEnable( GL_TEXTURE_2D );
	}
	
	// -----------------------------------------------------
	// Finish up
	
	glSwapAPPLE();
}

- (void)scrollWheel:(NSEvent *)theEvent
{
	orthoZoom += theEvent.deltaY / -25.0f;
	
	if( orthoZoom < 0 )
	{
		orthoZoom = 0.05;
	}
	
	[self display];
}

-(void) mouseDown:(NSEvent *)theEvent
{
	[TGlobal G]->currentLevelView = self;
	
	BOOL bShiftDown = ([theEvent modifierFlags] & NSShiftKeyMask) ? YES : NO;
	BOOL bCmdDown = ([theEvent modifierFlags] & NSCommandKeyMask) ? YES : NO;
	BOOL bOptionDown = ([theEvent modifierFlags] & NSAlternateKeyMask) ? YES : NO;
	BOOL bCtrlDown = ([theEvent modifierFlags] & NSControlKeyMask) ? YES : NO;
	BOOL bDoubleClick = ([theEvent clickCount] == 2) ? YES : NO;
	
	NSPoint event_location = [theEvent locationInWindow];
	NSPoint local_point = [self convertPoint:event_location fromView:nil];
	NSSize size = [self frame].size;
	
	TVec3D *XVec, *YVec;
	float XDelta, YDelta;
	MAPDocument* map = [[[self window] windowController] document];
    BOOL bCaptureMouse = YES;
	int mouseAction = TMA_Select;
	
	// Figure out where in the world the user clicked
	
	TVec3D *worldMouseClickLocation;
	
	switch( orientation )
	{
		case TO_Top_XZ:
		{
			local_point.x = (((local_point.x - (size.width / 2)) * orthoZoom) - cameraLocation->x);
			local_point.y = (((local_point.y - (size.height / 2)) * orthoZoom) - cameraLocation->z);
			
			worldMouseClickLocation = [[TVec3D alloc] initWithX:local_point.x Y:0 Z:local_point.y];
		}
		break;
			
		case TO_Side_YZ:
		{
			local_point.x = (((local_point.x - (size.width / 2)) * orthoZoom) - cameraLocation->z);
			local_point.y = (((local_point.y - (size.height / 2)) * orthoZoom) + cameraLocation->y);
			
			worldMouseClickLocation = [[TVec3D alloc] initWithX:0 Y:-local_point.y Z:local_point.x];
		}
		break;
			
		case TO_Front_XY:
		{
			local_point.x = (((local_point.x - (size.width / 2)) * orthoZoom) - cameraLocation->x);
			local_point.y = (((local_point.y - (size.height / 2)) * orthoZoom) + cameraLocation->y);
			
			worldMouseClickLocation = [[TVec3D alloc] initWithX:local_point.x Y:-local_point.y Z:0];
		}
		break;
	}
	
	if( bPlacingRotationPivot )
	{
		mouseAction = TMA_SetPivotLocation;
		[TGlobal G]->pivotLocation = [map snapVtxToGrid:worldMouseClickLocation];
		[map redrawLevelViewports];
		
		return;
	}
	
	if( bCmdDown && !bCtrlDown && (bOptionDown || bShiftDown) )
	{
		if( bOptionDown )
		{
			mouseAction = TMA_SetClipPoints;
		}
		else
		{
			mouseAction = TMA_BoxSelection;
		}
		
		ownerMouseAction = mouseAction;
		
		// Set up for dragging later on
		
		switch( orientation )
		{
			case TO_Top_XZ:
				XVec = [[TVec3D alloc] initWithX:1 Y:0 Z:0];
				YVec = [[TVec3D alloc] initWithX:0 Y:0 Z:1];
				break;
				
			case TO_Front_XY:
				XVec = [[TVec3D alloc] initWithX:1 Y:0 Z:0];
				YVec = [[TVec3D alloc] initWithX:0 Y:-1 Z:0];
				break;
				
			case TO_Side_YZ:
				XVec = [[TVec3D alloc] initWithX:0 Y:0 Z:1];
				YVec = [[TVec3D alloc] initWithX:0 Y:-1 Z:0];
				break;
		}
		
		XDelta = YDelta = 0;
		
		// Assign the world location to the appropriate clipping point
		
		if( startPoint != nil && endPoint != nil )
		{
			startPoint = endPoint = nil;
		}

		if( startPoint == nil )
		{
			startPoint = [worldMouseClickLocation mutableCopy];
			
			if( mouseAction != TMA_BoxSelection )
			{
				startPoint = [map snapVtxToGrid:startPoint];
			}
		}
		else
		{
			endPoint = [worldMouseClickLocation mutableCopy];
			
			// Update the clipping plane
			
			TVec3D* thirdPoint;
			
			switch( orientation )
			{
				case TO_Top_XZ:
					thirdPoint = [TVec3D addA:startPoint andB:[[TVec3D alloc] initWithX:0 Y:16 Z:0]];
					break;
					
				case TO_Front_XY:
					thirdPoint = [TVec3D addA:startPoint andB:[[TVec3D alloc] initWithX:0 Y:0 Z:16]];
					break;
					
				case TO_Side_YZ:
					thirdPoint = [TVec3D addA:startPoint andB:[[TVec3D alloc] initWithX:-16 Y:0 Z:0]];
					break;
			}
			
			clipPlane = [[TPlane alloc] initFromTriangleA:startPoint B:endPoint C:thirdPoint];
			clipFlippedPlane = [[TPlane alloc] initFromTriangleA:endPoint B:startPoint C:thirdPoint];
		}
	}
	else if( !bOptionDown && bCtrlDown && !bShiftDown )
	{
		[map->historyMgr startRecord:@"Drag"];
		
		mouseAction = TMA_DragSelection;
		
		switch( orientation )
		{
			case TO_Top_XZ:
				XVec = [[TVec3D alloc] initWithX:1 Y:0 Z:0];
				YVec = [[TVec3D alloc] initWithX:0 Y:0 Z:1];
				break;
				
			case TO_Front_XY:
				XVec = [[TVec3D alloc] initWithX:1 Y:0 Z:0];
				YVec = [[TVec3D alloc] initWithX:0 Y:-1 Z:0];
				break;

			case TO_Side_YZ:
				XVec = [[TVec3D alloc] initWithX:0 Y:0 Z:1];
				YVec = [[TVec3D alloc] initWithX:0 Y:-1 Z:0];
				break;
		}
		
		XDelta = YDelta = 0;
		
		// If the CMD key is down, the user is trying to drag faces on the selected brushes.  This routine
		// will select faces based on the click location of the mouse in the window.
		
		if( bCmdDown )
		{
			event_location = [theEvent locationInWindow];
			local_point = [self convertPoint:event_location fromView:nil];
			size = [self frame].size;
			
			switch( orientation )
			{
				case TO_Top_XZ:
				{
					local_point.x = (((local_point.x - (size.width / 2)) * orthoZoom) - cameraLocation->x);
					local_point.y = (((local_point.y - (size.height / 2)) * orthoZoom) - cameraLocation->z);
					
					worldMouseClickLocation = [[TVec3D alloc] initWithX:local_point.x Y:0 Z:local_point.y];
				}
				break;

				case TO_Side_YZ:
				{
					local_point.x = (((local_point.x - (size.width / 2)) * orthoZoom) - cameraLocation->z);
					local_point.y = (((local_point.y - (size.height / 2)) * orthoZoom) + cameraLocation->y);
					
					worldMouseClickLocation = [[TVec3D alloc] initWithX:0 Y:-local_point.y Z:local_point.x];
				}
				break;
					
				case TO_Front_XY:
				{
					local_point.x = (((local_point.x - (size.width / 2)) * orthoZoom) - cameraLocation->x);
					local_point.y = (((local_point.y - (size.height / 2)) * orthoZoom) + cameraLocation->y);
					
					worldMouseClickLocation = [[TVec3D alloc] initWithX:local_point.x Y:-local_point.y Z:0];
				}
				break;
			}
			
			[map->selMgr unselectAll:TSC_Face];
			[map->selMgr unselectAll:TSC_Vertex];
			
			for( TEntity* E in map->entities )
			{
				for( TBrush* B in E->brushes )
				{
					if( [map->selMgr isSelected:B] )
					{
						switch( orientation )
						{
							case TO_Top_XZ:
								worldMouseClickLocation->y = [B getCenter]->y;
								break;
								
							case TO_Side_YZ:
								worldMouseClickLocation->x = [B getCenter]->x;
								break;
								
							case TO_Front_XY:
								worldMouseClickLocation->z = [B getCenter]->z;
								break;
						}
						
						for( TFace* F in B->faces )
						{
							if( [F->normal getVertexSide:worldMouseClickLocation] == S_Front )
							{
								[map->selMgr addSelection:F];
							}
						}
					}
				}
			}
		}

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
			{
				switch( mouseAction )
				{
					case TMA_DragSelection:
					{
						float dx = [theEvent deltaX], dy = [theEvent deltaY];
						
						XDelta += dx * orthoZoom;
						YDelta += dy * orthoZoom;
						
						float xdir = (XDelta < 0.0) ? -1 : 1;
						float ydir = (YDelta < 0.0) ? -1 : 1;
						
						if( fabs(XDelta) > (map->gridSz / 3.0) )
						{
							xdir *= roundf(fabs(XDelta) / (map->gridSz / 3.0));
							[map DragSelectionsBy:[[TVec3D alloc] initWithX:(XVec->x * map->gridSz) * xdir Y:(XVec->y * map->gridSz) * xdir Z:(XVec->z * map->gridSz) * xdir]];
							XDelta = 0;
							YDelta /= 2;
						}
						if( fabs(YDelta) > (map->gridSz / 3.0) )
						{
							ydir *= roundf(fabs(YDelta) / (map->gridSz / 3.0));
							[map DragSelectionsBy:[[TVec3D alloc] initWithX:(YVec->x * map->gridSz) * ydir Y:(YVec->y * map->gridSz) * ydir Z:(YVec->z * map->gridSz) * ydir]];
							XDelta /= 2;
							YDelta = 0;
						}
						
						[map redrawLevelViewports];
					}
					break;
						
					case TMA_BoxSelection:
					{
						if( endPoint == nil && startPoint != nil )
						{
							endPoint = [startPoint mutableCopy];
						}
						
						if( endPoint != nil )
						{
							// Drag the end clipping point
							
							float dx = [theEvent deltaX], dy = [theEvent deltaY];
							
							XDelta += dx * orthoZoom;
							YDelta += dy * orthoZoom;
							
							float xdir = (XDelta < 0.0) ? -1 : 1;
							float ydir = (YDelta < 0.0) ? -1 : 1;
							
							if( fabs(XDelta) )
							{
								xdir *= fabs(XDelta);
								
								endPoint->x += XVec->x * xdir;
								endPoint->y += XVec->y * xdir;
								endPoint->z += XVec->z * xdir;
								
								XDelta = 0;
							}
							if( fabs(YDelta) )
							{
								ydir *= fabs(YDelta);
								
								endPoint->x += YVec->x * ydir;
								endPoint->y += YVec->y * ydir;
								endPoint->z += YVec->z * ydir;
								
								YDelta = 0;
							}
							
							// Finish
							
							[map redrawLevelViewports];
						}
					}
					break;
						
					case TMA_SetClipPoints:
					{
						if( endPoint == nil && startPoint != nil )
						{
							endPoint = [startPoint mutableCopy];
						}
						
						if( endPoint != nil )
						{
							// Drag the end clipping point
							
							float dx = [theEvent deltaX], dy = [theEvent deltaY];
							
							XDelta += dx * orthoZoom;
							YDelta += dy * orthoZoom;
							
							float xdir = (XDelta < 0.0) ? -1 : 1;
							float ydir = (YDelta < 0.0) ? -1 : 1;
							
							if( fabs(XDelta) > (map->gridSz / 3.0) )
							{
								xdir *= roundf(fabs(XDelta) / (map->gridSz / 3.0));
								
								endPoint->x += (XVec->x * map->gridSz) * xdir;
								endPoint->y += (XVec->y * map->gridSz) * xdir;
								endPoint->z += (XVec->z * map->gridSz) * xdir;
								
								XDelta = 0;
							}
							if( fabs(YDelta) > (map->gridSz / 3.0) )
							{
								ydir *= roundf(fabs(YDelta) / (map->gridSz / 3.0));
								
								endPoint->x += (YVec->x * map->gridSz) * ydir;
								endPoint->y += (YVec->y * map->gridSz) * ydir;
								endPoint->z += (YVec->z * map->gridSz) * ydir;
								
								YDelta = 0;
							}
						
							// Recompute clipping plane
							
							TVec3D* thirdPoint;
							
							switch( orientation )
							{
								case TO_Top_XZ:
									thirdPoint = [TVec3D addA:startPoint andB:[[TVec3D alloc] initWithX:0 Y:16 Z:0]];
									break;
									
								case TO_Front_XY:
									thirdPoint = [TVec3D addA:startPoint andB:[[TVec3D alloc] initWithX:0 Y:0 Z:16]];
									break;
									
								case TO_Side_YZ:
									thirdPoint = [TVec3D addA:startPoint andB:[[TVec3D alloc] initWithX:-16 Y:0 Z:0]];
									break;
							}
							
							clipPlane = [[TPlane alloc] initFromTriangleA:startPoint B:endPoint C:thirdPoint];
							clipFlippedPlane = [[TPlane alloc] initFromTriangleA:endPoint B:startPoint C:thirdPoint];
							
							// Finish
							
							[map redrawLevelViewports];
						}
					}
					break;
				}
			}
			break;
				
			case NSLeftMouseUp:
			{
				// Hook up the mouse to the cursor and show the cursor
				
				CGAssociateMouseAndMouseCursorPosition( TRUE );
				CGDisplayShowCursor( kCGDirectMainDisplay );
				
				event_location = [theEvent locationInWindow];
				local_point = [self convertPoint:event_location fromView:nil];
				
				switch( mouseAction )
				{
					case TMA_Select:
					{
						if( [self selectAtX:local_point.x Y:local_point.y DoubleClick:bDoubleClick ModifierFlags:[theEvent modifierFlags] Category:TSC_Vertex] == 0 )
						{
							if( [self selectAtX:local_point.x Y:local_point.y DoubleClick:bDoubleClick ModifierFlags:[theEvent modifierFlags] Category:TSC_Edge] == 0 )
							{
								[self selectAtX:local_point.x Y:local_point.y DoubleClick:bDoubleClick ModifierFlags:[theEvent modifierFlags] Category:TSC_Level];
							}
						}
					}
					break;
						
					case TMA_DragSelection:
					{
						[map->historyMgr stopRecord];
					}
					break;
						
					case TMA_SetClipPoints:
					{
						[map redrawLevelViewports];
					}
					break;

					case TMA_BoxSelection:
					{
						[map->historyMgr startRecord:@"Box Select"];
						
						TBBox* bbox = [TBBox new];
						[bbox addVertex:startPoint];
						[bbox addVertex:endPoint];
						
						NSMutableArray* planes = [NSMutableArray new];
						
						TVec3D *v0, *v1, *v2, *v3, *v4, *v5, *v6, *v7;
						
						switch( orientation )
						{
							case TO_Top_XZ:
							{
								v0 = [[TVec3D alloc] initWithX:bbox->min->x Y:-WORLD_SZ Z:bbox->min->z];
								v1 = [[TVec3D alloc] initWithX:bbox->max->x Y:-WORLD_SZ Z:bbox->min->z];
								v2 = [[TVec3D alloc] initWithX:bbox->max->x Y:-WORLD_SZ Z:bbox->max->z];
								v3 = [[TVec3D alloc] initWithX:bbox->min->x Y:-WORLD_SZ Z:bbox->max->z];
								
								v4 = [[TVec3D alloc] initWithX:bbox->min->x Y:WORLD_SZ Z:bbox->min->z];
								v5 = [[TVec3D alloc] initWithX:bbox->max->x Y:WORLD_SZ Z:bbox->min->z];
								v6 = [[TVec3D alloc] initWithX:bbox->max->x Y:WORLD_SZ Z:bbox->max->z];
								v7 = [[TVec3D alloc] initWithX:bbox->min->x Y:WORLD_SZ Z:bbox->max->z];
							}
								break;
								
							case TO_Front_XY:
							{
								v0 = [[TVec3D alloc] initWithX:bbox->min->x Y:bbox->min->y Z:WORLD_SZ];
								v1 = [[TVec3D alloc] initWithX:bbox->max->x Y:bbox->min->y Z:WORLD_SZ];
								v2 = [[TVec3D alloc] initWithX:bbox->max->x Y:bbox->max->y Z:WORLD_SZ];
								v3 = [[TVec3D alloc] initWithX:bbox->min->x Y:bbox->max->y Z:WORLD_SZ];
								
								v4 = [[TVec3D alloc] initWithX:bbox->min->x Y:bbox->min->y Z:-WORLD_SZ];
								v5 = [[TVec3D alloc] initWithX:bbox->max->x Y:bbox->min->y Z:-WORLD_SZ];
								v6 = [[TVec3D alloc] initWithX:bbox->max->x Y:bbox->max->y Z:-WORLD_SZ];
								v7 = [[TVec3D alloc] initWithX:bbox->min->x Y:bbox->max->y Z:-WORLD_SZ];
							}
								break;
								
							case TO_Side_YZ:
							{
								v0 = [[TVec3D alloc] initWithX:WORLD_SZ Y:bbox->min->y Z:bbox->min->z];
								v1 = [[TVec3D alloc] initWithX:WORLD_SZ Y:bbox->max->y Z:bbox->min->z];
								v2 = [[TVec3D alloc] initWithX:WORLD_SZ Y:bbox->max->y Z:bbox->max->z];
								v3 = [[TVec3D alloc] initWithX:WORLD_SZ Y:bbox->min->y Z:bbox->max->z];
								
								v4 = [[TVec3D alloc] initWithX:-WORLD_SZ Y:bbox->min->y Z:bbox->min->z];
								v5 = [[TVec3D alloc] initWithX:-WORLD_SZ Y:bbox->max->y Z:bbox->min->z];
								v6 = [[TVec3D alloc] initWithX:-WORLD_SZ Y:bbox->max->y Z:bbox->max->z];
								v7 = [[TVec3D alloc] initWithX:-WORLD_SZ Y:bbox->min->y Z:bbox->max->z];
							}
								break;
						}
						
						[planes addObject:[[TPlane alloc] initFromTriangleA:v2 B:v1 C:v0]];
						[planes addObject:[[TPlane alloc] initFromTriangleA:v5 B:v6 C:v7]];
						[planes addObject:[[TPlane alloc] initFromTriangleA:v0 B:v1 C:v5]];
						[planes addObject:[[TPlane alloc] initFromTriangleA:v1 B:v2 C:v6]];
						[planes addObject:[[TPlane alloc] initFromTriangleA:v2 B:v3 C:v7]];
						[planes addObject:[[TPlane alloc] initFromTriangleA:v3 B:v0 C:v4]];
						
						TBrush* boxSelectBrush = [TBrush createBrushFromPlanes:planes MAP:map];
						[boxSelectBrush finalizeInternals];
						
						[map->selMgr unselectAll:TSC_Level];
						
						for( TEntity* E in map->entities )
						{
							if( [E isPointEntity] )
							{
								if( [boxSelectBrush isPointInside:E->location] )
								{
									[map->selMgr addSelection:E];
								}
							}
							else
							{
								for( TBrush* B in E->brushes )
								{
									if( [B doesBrushIntersect:boxSelectBrush] )
									{
										[map->selMgr addSelection:B];
									}
								}
							}
						}
						
						[map->historyMgr stopRecord];
						
						startPoint = nil;
						endPoint = nil;
						
						[map redrawLevelViewports];
					}
				}
				
				bCaptureMouse = NO;
			}
			break;
		}
		
		[map->selMgr markTexturesOnSelectedDirtyRenderArray];
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
					switch( orientation )
					{
						case TO_Top_XZ:
							cameraLocation->x += ([theEvent deltaX] * orthoZoom);
							cameraLocation->z += ([theEvent deltaY] * orthoZoom);
							break;

						case TO_Front_XY:
							cameraLocation->x += ([theEvent deltaX] * orthoZoom);
							cameraLocation->y -= ([theEvent deltaY] * orthoZoom);
							break;
							
						case TO_Side_YZ:
							cameraLocation->y -= ([theEvent deltaY] * orthoZoom);
							cameraLocation->z += ([theEvent deltaX] * orthoZoom);
							break;
					}
				}
				else if( mouseAction == TMA_RotateSelection )
				{
					float dx = [theEvent deltaX];
					
					XDelta += dx;
					
					float xdir = (XDelta < 0.0) ? -1 : 1;
					
					if( fabs(XDelta) > (map->gridSz / 1.0f) )
					{
						switch( orientation )
						{
							case TO_Top_XZ:
								[map rotateSelectionsByX:0 Y:(xdir * -15.0) Z:0];
								break;
								
							case TO_Front_XY:
								[map rotateSelectionsByX:0 Y:0 Z:(xdir * 15.0)];
								break;
								
							case TO_Side_YZ:
								[map rotateSelectionsByX:(xdir * -15.0) Y:0 Z:0];
								break;
						}
						
						XDelta = 0;
					}
					
					[map redrawLevelViewports];
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
	switch( orientation )
	{
		case TO_Side_YZ:
			return [[TVec3D alloc] initWithX:0 Y:-1 Z:1];
			
		case TO_Front_XY:
			return [[TVec3D alloc] initWithX:1 Y:-1 Z:0];
	}

	return [[TVec3D alloc] initWithX:1 Y:0 Z:1];
}

-(NSMutableString*) exportToText
{
	NSMutableString* string = [NSMutableString string];
	
	[string appendFormat:@"// CONFIG_VIEWPORT:2D %f %f %f %d %f\n", cameraLocation->x, cameraLocation->y, cameraLocation->z, orientation, orthoZoom ];
	
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
	
	if( [subchunks count] > 0 && [[subchunks objectAtIndex:0] isEqualToString:@"2D"] )
	{
		cameraLocation = [[TVec3D alloc] initWithX:[[subchunks objectAtIndex:1] floatValue] Y:[[subchunks objectAtIndex:2] floatValue] Z:[[subchunks objectAtIndex:3] floatValue]];
		orientation = [[subchunks objectAtIndex:4] intValue];
		orthoZoom = [[subchunks objectAtIndex:5] floatValue];
		
		[orientationCtrl setSelectedSegment:orientation];
		
		[orientationCtrl display];
	}
}

- (void)keyDown:(NSEvent *)theEvent
{
	MAPDocument* map = [[[self window] windowController] document];
	
	BOOL bOptionDown = ([theEvent modifierFlags] & NSAlternateKeyMask) ? YES : NO;
	BOOL bCtrlDown = ([theEvent modifierFlags] & NSControlKeyMask) ? YES : NO;
	
	switch( [theEvent keyCode] )
	{
		case 35:	// P
		{
			bPlacingRotationPivot = YES;
			return;
		}
		break;
			
		case 53:	// escape
		{
			// Clear rotation pivot, if present
			
			if( [TGlobal G]->pivotLocation != nil )
			{
				[TGlobal G]->pivotLocation = nil;
				
				[map redrawLevelViewports];
				
				return;
			}
			
			// Clear special markers, if present
			
			if( startPoint != nil )
			{
				startPoint = nil;
				endPoint = nil;
				
				[map redrawLevelViewports];
				
				return;
			}
		}
		break;
			
		case 36:	// enter
		{
			if( endPoint != nil )
			{
				switch( ownerMouseAction )
				{
					case TMA_SetClipPoints:
					{
						if( bOptionDown )
						{
							[map csgClipSelectedBrushesAgainstPlane:clipFlippedPlane flippedPlane:clipPlane split:bCtrlDown];
						}
						else
						{
							[map csgClipSelectedBrushesAgainstPlane:clipPlane flippedPlane:clipFlippedPlane split:bCtrlDown];
						}
						
						startPoint = nil;
						endPoint = nil;
					}
					break;
				}
				
				[map redrawLevelViewports];
				
				return;
			}
		}
		break;
	}
	
	[super keyDown:theEvent];
}

- (void)keyUp:(NSEvent *)theEvent
{
	switch( [theEvent keyCode] )
	{
		case 35:	// P
		{
			bPlacingRotationPivot = NO;
			return;
		}
		break;
	}
	
	[super keyUp:theEvent];
}
			
@end
