
@implementation TRenderLevelOrthoComponent

-(void) beginDraw:(BOOL)InSelect
{
	[super beginDraw:InSelect];
	
	[TGlobal G]->currentRenderComponent = self;
	
	glClearColor( 0.85, 0.85, 0.85, 0 );
	
	if( InSelect )
	{
		glClear( GL_DEPTH_BUFFER_BIT );
	}
	else
	{
		glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
	}
}

-(void) draw:(MAPDocument*)InMAP SelectedState:(BOOL)InSelect
{
	if( [TGlobal G]->drawingPausedRefCount > 0 )
	{
		return;
	}
	
	// Ortho level viewports are wireframe
	
	glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );

	// Level
	
	for( TEntity* E in [InMAP _visibleEntities] )
	{
		glPushMatrix();
		
		glColor3fv( &E->entityClass->color->x );
		
		if( [E isPointEntity] )
		{
			if( InSelect == YES )
			{
				if( [InMAP->selMgr isSelected:E] )
				{
					[E drawSelectionHighlights:InMAP];
				}
			}
			
			glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
			
			glTranslatef( E->location->x, E->location->y, E->location->z );
			glRotatef( E->rotation->y, 0, 1, 0 );
			
			if( InSelect == YES )
			{
				if( [InMAP->selMgr isSelected:E] )
				{
					[E->entityClass drawOrthoSelectionHighlights:InMAP Entity:E];
				}
			}
			else
			{
				[E->entityClass draw:InMAP Entity:E];
			}
			
			glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
		}
		else
		{
			BOOL bDrewEntityHighlights = NO;
			
			for( TBrush* B in [E _visibleBrushes:InMAP] )
			{
				if( InSelect == YES )
				{
					if( [InMAP->selMgr isSelected:B] )
					{
						[B drawOrthoSelectionHighlights:InMAP];
						
						// This makes sure we only draw the entity highlights (like targetting lines) one time per entity
						if( bDrewEntityHighlights == NO )
						{
							bDrewEntityHighlights = YES;
							[E drawSelectionHighlights:InMAP];
						}
					}

					for( TFace* F in B->faces )
					{
						if( [InMAP->selMgr isSelected:F] )
						{
							[F drawOrthoSelectionHighlights:InMAP];
						}
					}
				}
				else
				{
					for( TFace* F in B->faces )
					{
						glBegin( GL_LINE_LOOP );
						
						for( TVec3D* V in F->verts )
						{
							glVertex3fv( &V->x );
						}
						
						glEnd();
					}
				}
			}
		}
		
		glPopMatrix();
	}
	
	// Clean up
	
	glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
}

-(void) drawForPick:(MAPDocument*)InMAP Category:(ESelectCategory)InCategory
{
	// Ortho level viewports are wireframe
	
	glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
	
	// Level
	
	for( TEntity* E in [InMAP _visibleEntities] )
	{
		glPushMatrix();
		
		[E drawWireForPick:InMAP Category:InCategory];
		
		glPopMatrix();
	}
	
	// Clean up
	
	glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
}

@end
