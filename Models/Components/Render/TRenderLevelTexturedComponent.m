
@implementation TRenderLevelTexturedComponent

-(void) beginDraw:(BOOL)InSelect
{
	[super beginDraw:InSelect];
	
	[TGlobal G]->currentRenderComponent = self;
	
	glClearColor( .15, .15, .15, 0 );
	
	if( !InSelect )
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

	glEnable( GL_TEXTURE_2D );
	
	if( !InSelect )
	{
		// Mark all textures as not "in use" before drawing the world.
		
		[TGlobal G]->bTrackingTextureUsage = YES;
		
		for( TTexture* T in InMAP->texturesFromWADs )
		{
			if( T->bDirtyRenderArray )
			{
				[T->renderArray resetToStart];
			}
			
			T->bInUse = NO;
		}
		
		// Fill up render arrays for each texture
		
		TVec3D *v0, *v1, *v2;
		
		for( TEntity* E in [InMAP _visibleEntities] )
		{
			for( TBrush* B in [E _visibleBrushes:InMAP] )
			{
				for( TFace* F in B->faces )
				{
					TTexture* T = [InMAP findTextureByName:F->textureName];
					
					if( T && T->bDirtyRenderArray )
					{
						if( !InMAP->bShowEditorOnlyEntities && [[T->name lowercaseString] isEqualToString:@"clip"] )
						{
							continue;
						}
						
						if( T->renderArray == nil )
						{
							T->renderArray = [[TRenderArray alloc] initWithElementType:RAET_VertUVColor];
						}
						
						v0 = v1 = v2 = nil;
						
						for( TVec3D* V in F->verts )
						{
							if( !v0 )
							{
								v0 = V;
							}
							else if( !v1 )
							{
								v1 = V;
							}
							else
							{
								v2 = V;
								
								[T->renderArray addElement:8, v0->x, v0->y, v0->z, v0->u, v0->v, F->lightValue, F->lightValue, F->lightValue];
								[T->renderArray addElement:8, v1->x, v1->y, v1->z, v1->u, v1->v, F->lightValue, F->lightValue, F->lightValue];
								[T->renderArray addElement:8, v2->x, v2->y, v2->z, v2->u, v2->v, F->lightValue, F->lightValue, F->lightValue];
								
								v1 = v2;
							}
						}
					}
				}
			}
		}
		
		for( TTexture* T in InMAP->texturesFromWADs )
		{
			T->bDirtyRenderArray = NO;
		}
		
		// Draw the polygons representing the world
		
		glColor3f( 1, 1, 1 );
		
		for( TTexture* T in InMAP->texturesFromWADs )
		{
			if( T->renderArray != nil && T->renderArray->currentIdx > 0 )
			{
				[T bind];
				[T->renderArray draw:GL_TRIANGLES];
			}
		}
		
		InMAP->bLevelGeometryIsDirty = NO;
	}

	// Point entities
	
	glDisable( GL_TEXTURE_2D );
	
	for( TEntity* E in [InMAP _visibleEntities] )
	{
		if( [E isPointEntity] )
		{
			glColor3fv( &E->entityClass->color->x );
			glPushMatrix();
			
			if( InSelect == YES )
			{
				if( [InMAP->selMgr isSelected:E] )
				{
					[E drawSelectionHighlights:InMAP];
				}
			}
			
			// Apply the entities transforms
			glTranslatef( E->location->x, E->location->y, E->location->z );
			glRotatef( E->rotation->y, 0, 1, 0 );
			
			if( InSelect == YES )
			{
				if( [InMAP->selMgr isSelected:E] )
				{
					[E->entityClass drawSelectionHighlights:InMAP Entity:E];
				}
			}
			else
			{
				[E->entityClass draw:InMAP Entity:E];
			}
			
			glPopMatrix();
		}
	}
	
	// Brush entities

	glEnable( GL_TEXTURE_2D );
	
	for( TEntity* E in [InMAP _visibleEntities] )
	{
		BOOL bIsWorldspawn = [E->entityClass->name isEqualToString:@"worldspawn"];
		
		if( ![E isPointEntity] )
		{
			glColor3fv( &E->entityClass->color->x );
			BOOL bDrewEntityHighlights = NO;
			
			for( TBrush* B in [E _visibleBrushes:InMAP] )
			{
				if( InSelect == YES )
				{
					if( [InMAP->selMgr isSelected:B] )
					{
						[B drawSelectionHighlights:InMAP];
						
						// This makes sure we only draw the entity highlights (like targetting lines) one time per entity
						if( bDrewEntityHighlights == NO )
						{
							bDrewEntityHighlights = YES;
							[E drawSelectionHighlights:InMAP];
						}
					}
					else
					{
						// Selected faces
						
						for( TFace* F in B->faces )
						{
							if( [InMAP->selMgr isSelected:F] )
							{
								[F drawSelectionHighlights:InMAP];
							}							
						}

					}
				}
				else
				{
					// For bmodels that are not the worldspawn, draw a highlighted outline in their entityclass color
					
					if( bIsWorldspawn == NO )
					{
						glDepthRange (0.1, .9995);
						[B drawHighlightedOutline:InMAP Color:E->entityClass->color];
						glDepthRange (0.1, 1.0);
					}
				}
			}
		}
	}
	
	glDisable( GL_TEXTURE_2D );
	
	[TGlobal G]->bTrackingTextureUsage = NO;

	// Give the MAP a chance to draw anything it needs to
	
	if( InSelect )
	{
		glDepthRange (0.1, 1.0);
		[InMAP drawPointFile];
	}
}

-(void) drawForPick:(MAPDocument*)InMAP Category:(ESelectCategory)InCategory
{
	for( TEntity* E in [InMAP _visibleEntities] )
	{
		glPushMatrix();
		
		[E drawForPick:InMAP Category:InCategory];
		
		glPopMatrix();
	}
}

@end

