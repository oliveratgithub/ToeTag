
@implementation TEntityClass

-(id) init
{
	[super init];
	
	name = @"";
	color = [TVec3D new];
	szMin = [TVec3D new];
	szMax = [TVec3D new];
	descText = [NSMutableArray new];
	spawnFlags = [NSMutableDictionary new];
	modelName = @"";
	emodelChoices = [NSMutableArray new];
	renderComponenents = [NSMutableArray new];
	bEditorOnly = NO;
	
	return self;
}

// Returns an alpha value that the class should be drawn using.  This allows things like
// triggers to be translucent.

-(float) getSuggestedAlpha
{
	float alpha = 1.0f;
	
	if( [name length] > 6 && [[name substringToIndex:7] isEqualToString:@"trigger"] )
	{
		alpha = 0.25f;
	}
	
	return alpha;
}

-(int) getWidth
{
	return abs(szMin->x) + abs(szMax->x);
}

-(int) getHeight
{
	return abs(szMin->y) + abs(szMax->y);
}

-(int) getDepth
{
	return abs(szMin->z) + abs(szMax->z);
}

-(void) finalizeInternals
{
	boundingBoxFaces = [NSMutableArray new];
	
	// Create a set of faces that can be used for rendering this entity.  We only
	// do this for point entities as bmodel/emodel entities already have faces.

	if( [self getWidth] > 0 )
	{
		TFace* face;
		
		face = [TFace new];
		[face->verts addObject:[[TVec3D alloc] initWithX:szMin->x Y:szMax->y Z:szMin->z ]];
		[face->verts addObject:[[TVec3D alloc] initWithX:szMin->x Y:szMin->y Z:szMin->z ]];
		[face->verts addObject:[[TVec3D alloc] initWithX:szMax->x Y:szMin->y Z:szMin->z ]];
		[face->verts addObject:[[TVec3D alloc] initWithX:szMax->x Y:szMax->y Z:szMin->z ]];
		[face finalizeInternals];
		[boundingBoxFaces addObject:face];

		face = [TFace new];
		[face->verts addObject:[[TVec3D alloc] initWithX:szMin->x Y:szMin->y Z:szMax->z ]];
		[face->verts addObject:[[TVec3D alloc] initWithX:szMin->x Y:szMax->y Z:szMax->z ]];
		[face->verts addObject:[[TVec3D alloc] initWithX:szMax->x Y:szMax->y Z:szMax->z ]];
		[face->verts addObject:[[TVec3D alloc] initWithX:szMax->x Y:szMin->y Z:szMax->z ]];
		[face finalizeInternals];
		[boundingBoxFaces addObject:face];

		face = [TFace new];
		[face->verts addObject:[[TVec3D alloc] initWithX:szMin->x Y:szMin->y Z:szMin->z ]];
		[face->verts addObject:[[TVec3D alloc] initWithX:szMin->x Y:szMax->y Z:szMin->z ]];
		[face->verts addObject:[[TVec3D alloc] initWithX:szMin->x Y:szMax->y Z:szMax->z ]];
		[face->verts addObject:[[TVec3D alloc] initWithX:szMin->x Y:szMin->y Z:szMax->z ]];
		[face finalizeInternals];
		[boundingBoxFaces addObject:face];

		face = [TFace new];
		[face->verts addObject:[[TVec3D alloc] initWithX:szMax->x Y:szMax->y Z:szMin->z ]];
		[face->verts addObject:[[TVec3D alloc] initWithX:szMax->x Y:szMin->y Z:szMin->z ]];
		[face->verts addObject:[[TVec3D alloc] initWithX:szMax->x Y:szMin->y Z:szMax->z ]];
		[face->verts addObject:[[TVec3D alloc] initWithX:szMax->x Y:szMax->y Z:szMax->z ]];
		[face finalizeInternals];
		[boundingBoxFaces addObject:face];

		face = [TFace new];
		[face->verts addObject:[[TVec3D alloc] initWithX:szMin->x Y:szMin->y Z:szMin->z ]];
		[face->verts addObject:[[TVec3D alloc] initWithX:szMin->x Y:szMin->y Z:szMax->z ]];
		[face->verts addObject:[[TVec3D alloc] initWithX:szMax->x Y:szMin->y Z:szMax->z ]];
		[face->verts addObject:[[TVec3D alloc] initWithX:szMax->x Y:szMin->y Z:szMin->z ]];
		[face finalizeInternals];
		[boundingBoxFaces addObject:face];

		face = [TFace new];
		[face->verts addObject:[[TVec3D alloc] initWithX:szMin->x Y:szMax->y Z:szMax->z ]];
		[face->verts addObject:[[TVec3D alloc] initWithX:szMin->x Y:szMax->y Z:szMin->z ]];
		[face->verts addObject:[[TVec3D alloc] initWithX:szMax->x Y:szMax->y Z:szMin->z ]];
		[face->verts addObject:[[TVec3D alloc] initWithX:szMax->x Y:szMax->y Z:szMax->z ]];
		[face finalizeInternals];
		[boundingBoxFaces addObject:face];
	}
}

-(void) draw:(MAPDocument*)InMAP Entity:(TEntity*)InEntity
{
	BOOL bDrawBoundingBox = YES;
	
	for( TEntityClassRenderComponent* ECRC in renderComponenents )
	{
		[ECRC draw:InMAP Entity:InEntity];
		
		if( ECRC->bNegatesBoundingBox == YES )
		{
			bDrawBoundingBox = NO;
		}
	}
	
	if( bDrawBoundingBox == NO )
	{
		return;
	}
	
	// --------------------------
	// Bounding Box
	
	// Remove rotations before drawing bounding boxes
	
	glRotatef( -InEntity->rotation->y, 0, 1, 0 );
	glDisable( GL_TEXTURE_2D );
	
	for( TFace* F in boundingBoxFaces )
	{
		glColor3f( color->x * F->lightValue, color->y * F->lightValue, color->z * F->lightValue );
		
		glBegin( GL_TRIANGLE_FAN );
		{
			for( TVec3D* V in F->verts )
			{
				glVertex3fv( &V->x );
			}
		}
		glEnd();
	}
}

-(void) drawSelectionHighlights:(MAPDocument*)InMAP Entity:(TEntity*)InEntity
{
	// Remove rotation before drawing selection highlights
	
	glRotatef( -InEntity->rotation->y, 0, 1, 0 );

	// Render components with highlights
	
	for( TEntityClassRenderComponent* ECRC in renderComponenents )
	{
		[ECRC drawSelectionHighlights:InMAP Entity:InEntity];
	}
	
	// --------------------------
	// Bounding box

	glLineWidth( 2.0 );
	glDisable( GL_CULL_FACE );
	glDisable( GL_TEXTURE_2D );
	
	// Draw the wireframe
	
	glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
	
	if( [self hasMDLComponent] )
	{
		glColor3fv( &color->x );
	}
	else
	{
		glColor3f( 1, 1, 1 );
	}
	
	glBegin( GL_QUADS );
	{
		for( TFace* F in boundingBoxFaces )
		{
			for( TVec3D* V in F->verts )
			{
				glVertex3fv( &V->x );
			}
		}
	}
	glEnd();

	// Draw the bounding box again as filled, translucent polygons
	
	glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
	
	glColor4f( color->x, color->y, color->z, 0.2f );
	
	glBegin( GL_QUADS );
	{
		for( TFace* F in boundingBoxFaces )
		{
			for( TVec3D* V in F->verts )
			{
				glVertex3fv( &V->x );
			}
		}
	}
	glEnd();
	
	glEnable( GL_TEXTURE_2D );
	glEnable( GL_CULL_FACE );
	glLineWidth( 1.0 );
}

-(void) drawOrthoSelectionHighlights:(MAPDocument*)InMAP Entity:(TEntity*)InEntity
{
	glDisable( GL_TEXTURE_2D );
	glColor3f( 1, 1, 1 );
	
	// --------------------------
	// Draw the entity again, only this time in white.  Don't bother drawing
	// non-MDL classes here as we're just drawing the box shape again and it will
	// get overwritten below.

	if( [self hasMDLComponent] == YES )
	{
		[self drawWire:InMAP Entity:InEntity];
	}
	
	// --------------------------
	// Remove rotation before drawing remaining selection highlights
	
	glRotatef( -InEntity->rotation->y, 0, 1, 0 );
	
	// Render components with highlights
	
	for( TEntityClassRenderComponent* ECRC in renderComponenents )
	{
		[ECRC drawSelectionHighlights:InMAP Entity:InEntity];
	}
	
	glLineWidth( 2.0 );
	
	// --------------------------
	// Bounding box
	
	// Draw the wireframe
	
	glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
	glDisable( GL_TEXTURE_2D );
	
	glBegin( GL_QUADS );
	{
		for( TFace* F in boundingBoxFaces )
		{
			for( TVec3D* V in F->verts )
			{
				glVertex3fv( &V->x );
			}
		}
	}
	glEnd();
	
	glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
	
	// Draw the bounding box again as filled, translucent polygons
	
	glColor4f( color->x, color->y, color->z, 0.2f );

	glBegin( GL_QUADS );
	{
		for( TFace* F in boundingBoxFaces )
		{
			for( TVec3D* V in F->verts )
			{
				glVertex3fv( &V->x );
			}
		}
	}
	glEnd();
	
	glEnable( GL_TEXTURE_2D );
	glLineWidth( 1.0 );
}

-(void) drawWire:(MAPDocument*)InMAP Entity:(TEntity*)InEntity
{
	glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
	
	BOOL bDrawBoundingBox = YES;
	
	for( TEntityClassRenderComponent* ECRC in renderComponenents )
	{
		[ECRC drawWire:InMAP Entity:InEntity];
		
		if( ECRC->bNegatesBoundingBox )
		{
			bDrawBoundingBox = NO;
		}
	}
	
	if( bDrawBoundingBox )
	{
		// Bounding box
		
		glBegin( GL_QUADS );
		{
			for( TFace* F in boundingBoxFaces )
			{
				for( TVec3D* V in F->verts )
				{
					glVertex3fv( &V->x );
				}
			}
		}
		glEnd();
	}
}

-(void) drawForPick:(TEntity*)InEntity MAP:(MAPDocument*)InMAP Category:(ESelectCategory)InCategory
{
	BOOL bDrawBoundingBox = YES;
	
	for( TEntityClassRenderComponent* ECRC in renderComponenents )
	{
		[ECRC drawForPick:InMAP Entity:InEntity];
		
		if( ECRC->bNegatesBoundingBox )
		{
			bDrawBoundingBox = NO;
		}
	}
	
	if( bDrawBoundingBox )
	{
		// Bounding box
		
		glBegin( GL_QUADS );
		{
			for( TFace* F in boundingBoxFaces )
			{
				for( TVec3D* V in F->verts )
				{
					glVertex3fv( &V->x );
				}
			}
		}
		glEnd();
	}
}

// Returns YES if this class is a point class

-(BOOL) isPointClass
{
	if( [self getWidth] > 0 )
	{
		return YES;
	}
	
	return NO;
}

// Returns YES if this entity class has an arrow rendering component

-(BOOL) hasArrowComponent
{
	for( TEntityClassRenderComponent* ECRC in renderComponenents )
	{
		if( [ECRC isKindOfClass:[TEntityClassRenderComponentArrow class]] )
		{
			return YES;
		}
	}
	
	return NO;
}

// Returns YES if this entity class has an MDL rendering component

-(BOOL) hasMDLComponent
{
	for( TEntityClassRenderComponent* ECRC in renderComponenents )
	{
		if( [ECRC isKindOfClass:[TEntityClassRenderComponentMDL class]] )
		{
			return YES;
		}
	}
	
	return NO;
}

@end
