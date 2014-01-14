
@implementation TProjComponent

-(id)initWithOwner:(TOpenGLView*)InOwnerView
{
	[super init];
	
	ownerView = InOwnerView;
	
	return self;
}

-(void) apply:(BOOL)InPickMode
{
	NSSize size = [ownerView frame].size;

	// Projection
	
	glMatrixMode( GL_PROJECTION );
	glLoadIdentity();
	
	if( InPickMode )
	{
		GLint viewport[4];
		glGetIntegerv( GL_VIEWPORT, viewport );
		gluPickMatrix( mouseX, viewport[3] - mouseY, PICK_AREA_SZ, PICK_AREA_SZ, viewport );
	}
	
	gluPerspective( 90.0, size.width / (float)size.height, 10.0f, WORLD_SZ );

	// Camera
	
	glMatrixMode( GL_MODELVIEW );
	glLoadIdentity();
	glRotatef( ownerView->cameraRotation->x, 1, 0, 0 );
	glRotatef( ownerView->cameraRotation->y, 0, 1, 0 );
	glTranslatef( ownerView->cameraLocation->x, ownerView->cameraLocation->y, ownerView->cameraLocation->z );
}

-(int) pickAtX:(float)InX Y:(float)InY DoubleClick:(BOOL)InDoubleClick ModifierFlags:(NSUInteger)InModFlags Category:(ESelectCategory)InCategory
{
	MAPDocument* map = [[[ownerView window] windowController] document];
	
	memset( buffer, 0, sizeof(GLuint) * GL_PICK_BUFFER_SZ );
	
	glSelectBuffer( GL_PICK_BUFFER_SZ, buffer );
	
	glInitNames();
	
	glRenderMode( GL_SELECT );
	
	mouseX = InX;
	mouseY = InY;
	
	[self apply:YES];
	[ownerView drawForPick:map Category:InCategory];
	
	int hits = glRenderMode( GL_RENDER );
	
	if( hits > 0 )
	{
		[map->historyMgr startRecord:@"pickAtX"];
		
		NSMutableArray* selections = [NSMutableArray new];
		
		int s;
		NSNumber* closestSelectName = [NSNumber new];
		float closestZ = 1.0f;
		
		NSMutableArray* selectedBrushes = [map->selMgr getSelectedBrushes];
		
		// Special case #1 : Selecting faces when brushes are currently selected
		//
		// If the user has brushes selected and they are trying to select a face, check for faces
		// that were clicked belonging to the selected brushes first.  This is most likely what the user wants
		// to have happen.
		
		if( [selectedBrushes count] > 0 && InCategory == TSC_Face )
		{
			for( s = 0 ; s < hits*4 ; s += 4 )
			{
				float zmin = buffer[s+1] / (float)0xffffffff;
				NSNumber* selectName = [NSNumber numberWithUnsignedInt:buffer[s+3]];
				
				NSObject* obj = [map findObjectByPickName:selectName];
				
				if( [obj isKindOfClass:[TFace class]] )
				{
					TFace* face = (TFace*)obj;
					
					for( TBrush* B in selectedBrushes )
					{
						if( [B->faces containsObject:face] )
						{
							if( zmin < closestZ )
							{
								closestZ = zmin;
								closestSelectName = [selectName copy];
							}
						}
					}
				}
			}
			
			if( closestZ != 1.0f )
			{
				[selections addObject:closestSelectName];
			}
		}
		
		// If no special case selections have been made yet, do the normal selection criteria.
		
		if( [selections count] == 0 )
		{
			for( s = 0 ; s < hits*4 ; s += 4 )
			{
				float zmin = buffer[s+1] / (float)0xffffffff;
				NSNumber* selectName = [NSNumber numberWithUnsignedInt:buffer[s+3]];
				
				switch( InCategory )
				{
					case TSC_Edge:
					case TSC_Vertex:
					{
						// When selecting verts, we want every vert that the mouse was on top of.
						
						[selections addObject:[selectName copy]];
					}
					break;
						
					default:
					{
						// When NOT selecting verts, we only want the closest hit.
						
						if( zmin < closestZ )
						{
							closestZ = zmin;
							closestSelectName = [selectName copy];
						}
					}
					break;
				}
			}
		}
		
		// If we aren't selecting verts, we only want the closest selection so add that one into the array.
		
		if( InCategory != TSC_Vertex && InCategory != TSC_Edge )
		{
			[selections addObject:closestSelectName];
		}
		
		if( (InModFlags & NSAlternateKeyMask) )
		{
			for( NSNumber* pickName in selections )
			{
				TVec3D* locationToSnapToGrid = [map getLocationForPickName:pickName];
				TVec3D* snapDelta = [TVec3D subtractA:[map snapVtxToGrid:locationToSnapToGrid] andB:locationToSnapToGrid];
				
				[map DragSelectionsBy:snapDelta];
				
				// We only care about the first thing the user clicked
				break;
			}
		}
		else
		{
			// Some selection categories remove selections in other categories
			
			switch( InCategory )
			{
				case TSC_Level:
					[map->selMgr unselectAll:TSC_Face];
					[map->selMgr unselectAll:TSC_Vertex];
					break;
					
				case TSC_Face:
					
					// If the user is SHIFT+CMD clicking a face, check to see if any brushes are selected.  If so,
					// convert them to selected faces before proceeding.
					
					if( (InModFlags & NSCommandKeyMask) )
					{
						for( TEntity* E in map->entities )
						{
							for( TBrush* B in E->brushes )
							{
								if( [map->selMgr isSelected:B] )
								{
									for( TFace* F in B->faces )
									{
										[map->selMgr addSelection:F];
									}
								}
							}
						}
					}
					
					[map->selMgr unselectAll:TSC_Level];
					[map->selMgr unselectAll:TSC_Vertex];
					break;

				case TSC_Edge:
				case TSC_Vertex:
					[map->selMgr unselectAll:TSC_Face];
					break;
			}
			
			// Holding down CMD will toggle selections.  Otherwise, everything is deselected before selecting the new thing.
			//
			// NOTE: The texture browser only allows one texture to be seleced at a time.
			
			if( !(InModFlags & NSCommandKeyMask) || InCategory == TSC_Texture )
			{
				switch( InCategory )
				{
					case TSC_Edge:
						[map->selMgr unselectAll:TSC_Vertex];
						break;
						
					default:
						[map->selMgr unselectAll:InCategory];
						break;
				}
			}
			
			// Check first to see if any verts were clicked.  If so, ignore clicked edges.  This allows
			// verts to have a higher click priority than edges.

			BOOL bHasVertSelections = NO;
			
			for( NSNumber* pickName in selections )
			{
				NSObject* obj = [map findObjectByPickName:pickName];
				
				if( [obj isKindOfClass:[TVec3D class]] )
				{
					bHasVertSelections = YES;
					break;
				}
			}
			
			BOOL bFirstEdge = YES;
			BOOL bEdgeIsSelected;
			
			for( NSNumber* pickName in selections )
			{
				NSObject* obj = [map findObjectByPickName:pickName];
				
				if( [obj isKindOfClass:[TEdge class]] )
				{
					// If the user has clicked verts along with edges, we ignore the edges to give the verts priority.
					
					if( bHasVertSelections )
					{
						continue;
					}
					
					TEdge* G = (TEdge*)obj;
					TBrush* ownerBrush = nil;
					selectedBrushes = [map->selMgr getSelectedBrushes];
					
					// Find the brush that contains the clicked edge
					
					for( TBrush* B in selectedBrushes )
					{
						if( [B->faces containsObject:G->ownerFace] )
						{
							ownerBrush = B;
							break;
						}
					}
					
					// Get the 2 verts that make up the edge and determine if the edge is selected.  We
					// consider an edge to be selected in this case if both verts are selected.
					
					TVec3D* v0 = [G->ownerFace->verts objectAtIndex:G->verts[0]];
					TVec3D* v1 = [G->ownerFace->verts objectAtIndex:G->verts[1]];
					
					if( bFirstEdge )
					{
						bEdgeIsSelected = ([map->selMgr isSelected:v0] && [map->selMgr isSelected:v1]) ? YES : NO;
						bFirstEdge = NO;
					}
					
					// Get an array of all of the verts that are relevant to the end points of the edge.  This
					// allows us to select all of the verts that are at the same location.
					
					NSMutableArray* relevantVerts = [NSMutableArray new];
					
					[relevantVerts addObjectsFromArray:[ownerBrush getVertsNear:v0]];
					[relevantVerts addObjectsFromArray:[ownerBrush getVertsNear:v1]];
					
					// Process selections for every relevant vert.
					
					for( TVec3D* V in relevantVerts )
					{
						if( (InModFlags & NSCommandKeyMask) )
						{
							if( bEdgeIsSelected )
							{
								[map->selMgr removeSelection:V];
							}
							else
							{
								[map->selMgr addSelection:V];
							}
						}
						else
						{
							[map->selMgr addSelection:V];
						}
					}
					
				}
				else
				{
					if( (InModFlags & NSCommandKeyMask) && InCategory != TSC_Texture )
					{
						[map->selMgr toggleSelection:obj];
					}
					else
					{
						[map->selMgr addSelection:obj];
					}
				}
			}
		}
		
		[map redrawTextureViewports];
			
		[map->historyMgr stopRecord];
	}
	
	[map refreshInspectors];
	
	return hits;
}

@end

