
@implementation TBookmark

-(id) init
{
	[super init];
	
	perspectiveLocation = [TVec3D new];
	perspectiveRotation = [TVec3D new];
	orthoLocation = [TVec3D new];
	orthoZoom = 1.0f;
	
	return self;
}

-(id) initWithPerspectiveLocation:(TVec3D*)InPerspectiveLocation PerspectiveRotation:(TVec3D*)InPerspectiveRotation OrthoLocation:(TVec3D*)InOrthoLocation OrthoZoom:(float)InOrthoZoom
{
	[super init];
	
	perspectiveLocation = [InPerspectiveLocation mutableCopy];
	perspectiveRotation = [InPerspectiveRotation mutableCopy];
	orthoLocation = [InOrthoLocation mutableCopy];
	orthoZoom = InOrthoZoom;
	
	return self;
}

@end

// ------------------------------------------------------

@implementation TPlaneX

-(id) init
{
	[super init];
	
	vertCount = 0;
	facesLeftUncut = 1.0f;
	
	return self;
}

-(float) getWeight
{
	float score = 0.0f;
	
	score += (vertCount - facesLeftUncut);
	
	if( fabs(normal->x) == 1.0f || fabs(normal->y) == 1.0f || fabs(normal->z) == 1.0f )
	{
		score += 20.f;
	}
	
	return score;
}

// Sort XPlanes by vertex count

- (NSComparisonResult)compareByVertexCount:(TPlaneX*)InPlane
{
	// Multiply by -1 so that we sort in descending order (this sorts the larger ones first)
	
	return ([self getWeight] - [InPlane getWeight]) * -1;
}

@end

// ------------------------------------------------------

@implementation TEdgeX

-(BOOL) isEqualTo:(TEdgeX*)In
{
	if( (In->start == start && In->end == end) || (In->start == end && In->end == start ) )
	{
		return YES;
	}
	
	return NO;
}

@end

// ------------------------------------------------------

@implementation MAPDocument

- (id)init
{
    self = [super init];
	
    if( self )
	{
		entities = [NSMutableArray new];
		entityClasses = [NSMutableDictionary new];
		texturesFromWADs = [NSMutableArray new];
		levelViewports = [NSMutableArray new];
		textureViewports = [NSMutableArray new];
		configLines = [NSMutableArray new];
	
		// Make sure special global items are cached.  This loads things like entity emodels (health, ammo, etc) and their
		// respective textures into the global cache.
		
		[[TGlobal G] precacheResources:self];
		
		// Selection manager
		selMgr = [[TSelection alloc] initWithMAP:self];
		
		// Visibility manager
		visMgr = [[TVisibility alloc] initWithMAP:self];
		
		// Undo/redo manager
		historyMgr = [[THistory alloc] initWithMAP:self];

		// Misc
		
		gridSz = 16;
		
		// We handle undo/redo ourselves so we tell the document that there is no undo manager.  This
		// allows us to prompt the user to save dirty documents and things like that.
		[self setUndoManager:nil];
		
		pointFileRA = [[TRenderArray alloc] initWithElementType:RAET_Vert];
		
		bookmarks = [NSMutableDictionary new];
		
		filterOption = EF_All;
		bShowEditorOnlyEntities = YES;
		bLevelGeometryIsDirty = FALSE;
    }
	
    return self;
}

- (NSString *)windowNibName
{
    return @"MAPDocument";
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	NSMutableString* levelstring = [NSMutableString string];

	[self purgeBadBrushesAndEntities];

	// Let the viewports save their settings first
	
	for( TOpenGLView* VW in levelViewports )
	{
		[levelstring appendString:[VW exportToText]];
	}
	
	// Bookmarks
	
	NSEnumerator *enumerator = [bookmarks keyEnumerator];
	id obj;
	
	while( obj = [enumerator nextObject] )
	{
		NSString *key;
		TBookmark* BM;
		
		key = obj;
		BM = [bookmarks objectForKey:key];
		
		[levelstring appendFormat:@"// CONFIG_BOOKMARK:%@ %f %f %f %f %f %f %f %f %f %f\n",
			key,
			BM->perspectiveLocation->x, BM->perspectiveLocation->y, BM->perspectiveLocation->z,
			BM->perspectiveRotation->x, BM->perspectiveRotation->y, BM->perspectiveRotation->z,
			BM->orthoLocation->x, BM->orthoLocation->y, BM->orthoLocation->z,
			BM->orthoZoom];
	}
		
	// Now export the entities
	
	for( TEntity* E in entities )
	{
		[levelstring appendString:[E exportToText:YES]];
	}
	
	[self updateChangeCount:NSChangeCleared];
	
	return [levelstring dataUsingEncoding:NSUTF8StringEncoding];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	BOOL ret = NO;
	
	NSMutableString *fileContents = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	if( fileContents )
	{
		[self sortTexturesBySize];
		
		TDEFReader* defreader = [TDEFReader new];
		[defreader loadFileFromResources:@"worldspawn.def" MAP:self];
		
		// Import the level text
		
		[self importEntitiesFromText:fileContents SelectAfterImport:NO];
		[entities sortUsingSelector:@selector(compareByClassName:)];
		[self refreshEntityClasses];
		
		// Clean up
		
		[self purgeBadBrushesAndEntities];
		
		bLevelGeometryIsDirty = YES;
		
		ret = YES;
	}
	
    if( outError != NULL )
	{
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	return ret;
}

- (id)initWithType:(NSString *)typeName error:(NSError **)outError
{
	[super initWithType:typeName error:outError];
	
	TDEFReader* defreader = [TDEFReader new];
	[defreader loadFileFromResources:@"worldspawn.def" MAP:self];
	
	// Create the worldspawn entity since we have to have one by default
	
	[self addNewEntity:@"worldspawn"];
	[self refreshEntityClasses];
	
	return self;
}

-(void) refreshEntityClasses
{
	entityClasses = [NSMutableDictionary new];
	
	TDEFReader* defreader = [TDEFReader new];
	TCMPReader* cmpreader = [TCMPReader new];
	
	TEntity* worldspawn = [self findEntityByClassName:@"worldspawn"];
	NSString* quakeDir = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"quakeDirectory"];
	
	NSString* gameName = @"";
	if( worldspawn )
	{
		gameName = [worldspawn->keyvalues valueForKey:@"_game"];
	}
	
	// ===
	// ENTITY CLASSES
	
	// Quake
	
	[defreader loadFileFromResources:@"quake.def" MAP:self];
	
	// Mod
	
	if( [gameName length] > 0 )
	{
		// Read all of the DEF files in the mod directory
		
		NSDirectoryEnumerator* dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:[NSString stringWithFormat:@"%@/%@/", quakeDir, gameName]];
		
		NSString* file;
		while( file = [dirEnum nextObject] )
		{
			if( [[[file uppercaseString] pathExtension] isEqualToString:@"DEF"] )
			{
				NSString* filename = [NSString stringWithFormat:@"%@/%@/%@", quakeDir, gameName, file];
				[defreader loadFile:filename MAP:self];
			}
		}
	}
	
	// ===
	// ENTITY CLASS COMPONENTS
	//
	// It's important to read the components in after all of the DEF files have been read.  Doing it in the wrong
	// order causes the standard Quake entities to not have MDLs assigned to them.
	
	// Quake
	
	[cmpreader loadFileFromResources:@"toetag.cmp" MAP:self];
	
	// Mod
	
	if( [gameName length] > 0 )
	{
		// Read the component file for the mod if it's there
		
		NSString* cmpfilename = [NSString stringWithFormat:@"%@/%@/toetag.cmp", quakeDir, gameName];
		[cmpreader loadFile:cmpfilename MAP:self];
	}
	
	// ===
	// FINALIZE
	
	// Give each entity the chance to find it's entity class again
	
	for( TEntity* E in entities )
	{
		[E finalizeInternals:self];
	}
	
	// UI
	
	[self registerTexturesWithViewports:YES];
	[self populateCreateEntityMenu];
}

-(NSMutableArray*) _visibleEntities
{	
	NSMutableArray* visibleEntities = [NSMutableArray new];
	
	for( TEntity* E in entities )
	{
		// Manually hidden entities
		
		if( ![visMgr isVisible:E] )
		{
			continue;
		}
		
		// Skill level filtering
		
		switch( filterOption )
		{
			case EF_Easy:
			{
				if( E->spawnFlags & SF_NotInEasy )
				{
					continue;
				}
			}
			break;

			case EF_Normal:
			{
				if( E->spawnFlags & SF_NotInNormal )
				{
					continue;
				}
			}
			break;
				
			case EF_HardNightmare:
			{
				if( E->spawnFlags & SF_NotInHardNightmare )
				{
					continue;
				}
			}
			break;

			case EF_Deathmatch:
			{
				int DMFlags = SF_NotInEasy | SF_NotInNormal | SF_NotInHardNightmare;
				if( !((E->spawnFlags&DMFlags) == DMFlags || !(E->spawnFlags&DMFlags)) )
				{
					continue;
				}
			}
			break;
		}
		
		// "Editor Only" filtering
		
		if( bShowEditorOnlyEntities == NO && E->entityClass->bEditorOnly == YES )
		{
			continue;
		}
		
		// Entity is visible
		
		[visibleEntities addObject:E];
	}
	
	return visibleEntities;
}

// Finds the first instance of an entity of type InClassName.

-(TEntity*) findEntityByClassName:(NSString*)InClassName
{
	for( TEntity* E in entities )
	{
		if( [InClassName isEqualToString:[E valueForKey:@"classname" defaultValue:@"??"]] )
		{
			return E;
		}
	}
	
	return nil;
}

// This is the same as findEntityByClassName except that if the entity doesn't exist, it is created before the function returns.

-(TEntity*) getEntityByClassName:(NSString*)InClassName
{
	TEntity* entity = [self findEntityByClassName:InClassName];
	
	if( entity == nil )
	{
		entity = [self addNewEntity:InClassName];
	}
	
	return entity;
}

// Adds a new entity of InClassName to the entity list.  The new entity is then returned to the caller.

-(TEntity*) addNewEntity:(NSString*)InClassName
{
	TEntity* ent = [TEntity new];
	[ent setKey:@"classname" Value:InClassName];
	[ent finalizeInternals:self];
	
	[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_CreateEntity Object:ent]];
	
	[entities addObject:ent];

	return ent;
}

// Removes an entity from the world

-(void) destroyEntity:(TEntity*)InEntity
{
	// The worldspawn can't be destroyed
	if( [InEntity->entityClass->name isEqualToString:@"worldspawn"] )
	{
		return;
	}
	
	[historyMgr startRecord:@"Delete Entity"];
	[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_DeleteEntity Object:InEntity]];
	
	[entities removeObject:InEntity];
	
	[historyMgr stopRecord];
}

// Removes a brush from the world

-(void) destroyBrush:(TBrush*)InBrush InEntity:(TEntity*)InEntity
{
	[historyMgr startRecord:@"Delete Brush"];
	[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_DeleteBrush Object:InBrush Owner:InEntity]];
	
	if( InEntity == nil )
	{
		for( TEntity* E in entities )
		{
			[E->brushes removeObject:InBrush];
		}
	}
	else
	{
		[InEntity->brushes removeObject:InBrush];
	}
	
	[historyMgr stopRecord];
}

-(void) destroyObject:(NSObject*)InObject
{
	NSMutableArray* ents = [NSMutableArray arrayWithArray:entities];
	
	[selMgr removeSelection:InObject];
	
	for( TEntity* E in ents )
	{
		// Is it an entity?
		
		if( [E isEqual:InObject] )
		{
			[self destroyEntity:E];
			break;
		}
		
		// Is it a brush?
		
		NSMutableArray* tempB = [NSMutableArray arrayWithArray:E->brushes];
		
		for( TBrush* B in tempB )
		{
			if( [B isEqual:InObject] )
			{
				// Delete the brush
				[self destroyBrush:B InEntity:E];

				// If the entity has no brushes left, delete it as well
				if( [E->brushes count] == 0 )
				{
					[self destroyEntity:E];
				}
				
				break;
			}
		}
	}

	[self refreshInspectors];
}

-(TEntityClass*) getEntityClassFor:(NSObject*)InObject
{
	for( TEntity* E in entities )
	{
		// Is it an entity?
		
		if( [E isEqual:InObject] )
		{
			return E->entityClass;
		}
		
		// Is it a brush?
		
		for( TBrush* B in E->brushes )
		{
			if( [B isEqual:InObject] )
			{
				return E->entityClass;
			}
		}
	}

	// If no entity class could be located, assume the worldspawn
	
	TEntity* worldspawn = [self findEntityByClassName:@"worldspawn"];
	return worldspawn->entityClass;
}

-(TEntity*) getEntityFor:(NSObject*)InObject
{
	for( TEntity* E in entities )
	{
		// Is it an entity?
		
		if( [E isEqual:InObject] )
		{
			return E;
		}
		
		// Is it a brush?
		
		for( TBrush* B in E->brushes )
		{
			if( [B isEqual:InObject] )
			{
				return E;
			}

			// Is it a vertex?
			
			if( [InObject isKindOfClass:[TVec3D class]] )
			{
				for( TFace* F in B->faces )
				{
					for( TVec3D* V in F->verts )
					{
						if( [V isAlmostEqualTo:(TVec3D*)InObject] )
						{
							return E;
						}
					}
				}
			}
		}
	}
	
	// If no entity could be located, assume the worldspawn
	
	TEntity* worldspawn = [self findEntityByClassName:@"worldspawn"];
	return worldspawn;
}

-(void) destroyAllSelected
{
	[historyMgr startRecord:@"Delete All"];
	
	// Delete the selected objects from the level
	
	NSMutableArray* sels = [selMgr getSelections:TSC_Level];
	[selMgr unselectAll:TSC_Level];
	[selMgr unselectAll:TSC_Face];
	[selMgr unselectAll:TSC_Vertex];
	
	for( NSObject* O in sels )
	{
		[self destroyObject:O];
	}

	[historyMgr stopRecord];
}

-(id) findObjectByPickName:(NSNumber*)InPickName
{
	for( TEntity* E in entities )
	{
		if( E->pickName != nil && ![E->pickName compare:InPickName] )
		{
			return E;
		}
		
		for( TBrush* B in E->brushes )
		{
			if( B->pickName != nil && ![B->pickName compare:InPickName] )
			{
				return B;
			}
			
			for( TFace* F in B->faces )
			{
				if( F->pickName != nil && ![F->pickName compare:InPickName] )
				{
					return F;
				}

				for( TEdge* G in F->edges )
				{
					if( G->pickName != nil && ![G->pickName compare:InPickName] )
					{
						return G;
					}
				}
				
				for( TVec3D* V in F->verts )
				{
					if( V->pickName != nil && ![V->pickName compare:InPickName] )
					{
						return V;
					}
				}
			}
		}
	}
	
	for( TTexture* T in texturesFromWADs )
	{
		if( T->pickName != nil && ![T->pickName compare:InPickName] )
		{
			return T;
		}
	}
	
	// A pick name with no valid object is scary
	assert( FALSE );
}

-(TVec3D*) getLocationForPickName:(NSNumber*)InPickName
{
	for( TEntity* E in entities )
	{
		if( E->pickName != nil && ![E->pickName compare:InPickName] )
		{
			return E->location;
		}
		
		for( TBrush* B in E->brushes )
		{
			if( B->pickName != nil && ![B->pickName compare:InPickName] )
			{
				return [((TFace*)[B->faces objectAtIndex:0])->verts objectAtIndex:0];
			}
			
			for( TFace* F in B->faces )
			{
				if( F->pickName != nil && ![F->pickName compare:InPickName] )
				{
					return [F->verts objectAtIndex:0];
				}
				
				for( TVec3D* V in F->verts )
				{
					if( V->pickName != nil && ![V->pickName compare:InPickName] )
					{
						return V;
					}
				}
			}
		}
	}

	return [TVec3D new];
}

-(TTexture*) findTextureByName:(NSString*)InName
{
	TTexture* texture = [textureLookUps objectForKey:[InName uppercaseString]];
	
	if( texture == nil )
	{
		texture = [textureLookUps objectForKey:@"TOETAGDEFAULT"];
	}
	
	return texture;
}

-(void) removeTextureByName:(NSString*)InName
{
	TTexture* texture = [textureLookUps objectForKey:[InName uppercaseString]];
	
	if( texture != nil )
	{
		[textureLookUps removeObjectForKey:[InName uppercaseString]];
		[texturesFromWADs removeObject:texture];
	}
}

-(BOOL) doesTextureExist:(NSString*)InName
{
	TTexture* texture = [textureLookUps objectForKey:[InName uppercaseString]];

	if( texture == nil )
	{
		return NO;
	}
	
	return YES;
}

-(void) sortTexturesBySize
{
	[texturesFromWADs sortUsingSelector:@selector(compareBySize:)]; 
	
	textureLookUps = [NSMutableDictionary new];
	for( TTexture* T in texturesFromWADs )
	{
		[textureLookUps setObject:T forKey:[T->name uppercaseString]];
	}
}

// Removes all currently loaded textures that came from WADs

-(void) clearLoadedTextures
{
	NSMutableArray* textures = [texturesFromWADs mutableCopy];
	
	for( TTexture* T in textures )
	{
		if( T->bShowInBrowser )
		{
			[texturesFromWADs removeObject:T];
		}
	}
	
	[self sortTexturesBySize];
}

// Loads a WAD and adds it's textures to the pool

-(BOOL) loadWAD:(NSString*)InName
{
	BOOL bWadLoaded = NO;
	TEntity* worldspawn = [self findEntityByClassName:@"worldspawn"];
	NSString* gameName = [worldspawn->keyvalues valueForKey:@"_game"];
	
	// Try to load the WAD from the Quake directory
	
	bWadLoaded = [self loadWADFullPath:[NSString stringWithFormat:@"%@/ID1/%@", [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"quakeDirectory"], InName]];

	// Try to load from the game/mod directory
	
	if( !bWadLoaded && [gameName length] > 0 )
	{
		bWadLoaded = [self loadWADFullPath:[NSString stringWithFormat:@"%@/%@/%@", [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"quakeDirectory"], gameName, InName]];
	}
	
	// Try to load from a direct path
	
	if( !bWadLoaded )
	{
		bWadLoaded = [self loadWADFullPath:InName];
	}
	
	return bWadLoaded;
}

-(BOOL) loadWADFullPath:(NSString*)InFilename
{
	TWADReader* wadreader = [TWADReader new];
	if( [wadreader loadFile:InFilename Map:self] == NO )
	{
		return NO;
	}

	[self sortTexturesBySize];

	// Refresh the texture mapping on all brushes.  We have to do this because the mapping will
	// be wrong if the brush couldn't find it's texture previously or the texture size is changing now.
	
	for( TEntity* E in entities )
	{
		for( TBrush* B in E->brushes )
		{
			[B generateTexCoords:self];
		}
	}
	
	[self registerTexturesWithViewports:NO];
	
	[self markAllTexturesDirtyRenderArray];
	
	return YES;
}

-(void) saveWADFullPath:(NSString*)InFilename
{
	TWADWriter* wadwriter = [TWADWriter new];
	[wadwriter saveFile:InFilename Map:self];

	[self markAllTexturesDirtyRenderArray];
}

// Redraws all viewports related to this view that are showing the level

-(void) redrawLevelViewports
{
	for( TOpenGLView* VW in levelViewports )
	{
		[VW prepareOpenGL];
		[VW display];
	}
}

// Redraws all viewports related to this view that are displaying textures

-(void) redrawTextureViewports
{
	for( TOpenGLView* VW in textureViewports )
	{
		[VW prepareOpenGL];
		[VW display];
	}
}

-(void) registerTexturesWithViewports:(BOOL)InRedrawViewports
{
	[self sortTexturesBySize];
	
	for( TOpenGLView* VW in textureViewports )
	{
		[VW registerTextures];
		
		if( InRedrawViewports )
		{
			[[VW window] flushWindow];
		}
	}
}

-(void) DragSelectionsBy:(TVec3D*)InOffset
{
	[historyMgr startRecord:@"Drag"];
	
	BOOL bHasVertexSelections = [selMgr hasSelectionsInCategory:TSC_Vertex];
	BOOL bHasFaceSelections = [selMgr hasSelectionsInCategory:TSC_Face];
	
	for( TEntity* E in entities )
	{
		if( !bHasVertexSelections && [E isPointEntity] )
		{
			if( [selMgr isSelected:E] )
			{
				E->location = [TVec3D addA:E->location andB:InOffset];
				[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_DragEntity Object:E Data:InOffset]];
			}
		}
		else
		{
			for( TBrush* B in E->brushes )
			{
				if( [selMgr isSelected:B] && !bHasVertexSelections && !bHasFaceSelections )
				{
					[B dragBy:InOffset MAP:self];
					[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_DragBrush Object:B Data:InOffset]];
				}
				
				for( TFace* F in B->faces )
				{
					int vertsMoved = 0;
					
					for( TVec3D* V in F->verts )
					{
						if( [selMgr isSelected:V] )
						{
							V->x += InOffset->x;
							V->y += InOffset->y;
							V->z += InOffset->z;
							
							[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_DragVertex Object:V Owner:B Data:InOffset]];
							
							vertsMoved++;
						}
					}
					
					// If every vertex on the face was moved by the same amount, apply texture locking
					
					if( vertsMoved == [F->verts count] )
					{
						[F maintainTextureLockAfterDrag:InOffset];
					}
					
					if( vertsMoved > 0 )
					{
						[F generateTexCoords:self];
					}
				}
			}
		}
	}

	[historyMgr stopRecord];
}

-(TVec3D*) getUsableOrigin
{
	TVec3D* origin = [TVec3D new];
	int count = 0;
	
	if( [TGlobal G]->pivotLocation != nil )
	{
		origin = [[TGlobal G]->pivotLocation mutableCopy];
	}
	else
	{
		for( TEntity* E in entities )
		{
			if( [E isPointEntity] )
			{
				if( [selMgr isSelected:E] )
				{
					origin = [TVec3D addA:origin andB:E->location];
					count++;
				}
			}
			else
			{
				for( TBrush* B in E->brushes )
				{
					if( [selMgr isSelected:B] )
					{
						origin = [TVec3D addA:origin andB:[B getCenter]];
						count++;
					}
				}
			}
		}
		
		origin = [TVec3D scale:origin By:(1.0f / count)];
	}
	
	return origin;
}

-(void) rotateSelectionsByX:(float)InPitch Y:(float)InYaw Z:(float)InRoll
{
	[historyMgr startRecord:@"Rotate"];
	
	TVec3D* origin = [self getUsableOrigin];
	
	// Now rotate all selected entities both around their local coordinate system
	// and the center of the selection in the world coordinate system.

	TMatrix* worldToLocal = [TMatrix translateWithX:-origin->x Y:-origin->y Z:-origin->z];
	TMatrix* localToWorld = [TMatrix translateWithX:origin->x Y:origin->y Z:origin->z];
	TMatrix* rotX = [TMatrix rotateX:InPitch];
	TMatrix* rotY = [TMatrix rotateY:InYaw];
	TMatrix* rotZ = [TMatrix rotateZ:InRoll];
	
	for( TEntity* E in entities )
	{ 
		if( [E isPointEntity] )
		{
			if( [selMgr isSelected:E] )
			{
				// Only affect the entity YAW if the entity has a bmodel (or if it has no models of any kind).  These are the only entities that
				// support rotation values.
				
				if( [E->entityClass hasArrowComponent] )
				{
					TVec3D* newRotation = [[TVec3D alloc] initWithX:E->rotation->x Y:E->rotation->y + InYaw Z:E->rotation->z];
					
					[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_RotateEntity Object:E OldData:[E->rotation mutableCopy] NewData:[newRotation mutableCopy]]];
					
					E->rotation = newRotation;
					[E matchUpKeyValuesToLiterals];
				}
				   
				// Now rotation the locations of the entities around the center of the current selection.
				
				TVec3D* oldLocation = [E->location mutableCopy];
				
				E->location = [worldToLocal transformVector:E->location];
				E->location = [rotX transformVector:E->location];
				E->location = [rotY transformVector:E->location];
				E->location = [rotZ transformVector:E->location];
				E->location = [localToWorld transformVector:E->location];
				
				[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_DragEntity Object:E Data:[TVec3D subtractA:E->location andB:oldLocation]]];
			}
		}
		else
		{
			for( TBrush* B in E->brushes )
			{
				if( [selMgr isSelected:B] )
				{
					for( TFace* F in B->faces )
					{
						NSMutableArray* oldVerts = [NSMutableArray new];
						NSMutableArray* newVerts = [NSMutableArray new];
						
						for( TVec3D* V in F->verts )
						{
							TVec3D* vtx = [V mutableCopy];
							
							[oldVerts addObject:[V mutableCopy]];
							
							vtx = [worldToLocal transformVector:vtx];
							vtx = [rotX transformVector:vtx];
							vtx = [rotY transformVector:vtx];
							vtx = [rotZ transformVector:vtx];
							vtx = [localToWorld transformVector:vtx];
							
							V->x = vtx->x;
							V->y = vtx->y;
							V->z = vtx->z;

							[newVerts addObject:[V mutableCopy]];
						}
						
						[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_ModifyFaceVerts Object:F OldData:oldVerts NewData:newVerts]];
						
						[F generateTexCoords:self];
					}
				}
			}
		}
	}
	
	[historyMgr stopRecord];
}

// Makes a duplicate of all selected entities, offsetting the new copies by the grid size on the XZ axis

-(void) duplicateSelected
{
	[historyMgr startRecord:@"Duplicate"];
	
	[self copy:self];
	
	[selMgr unselectAll:TSC_Level];
	[selMgr unselectAll:TSC_Face];
	[selMgr unselectAll:TSC_Vertex];
	
	[self paste:self];
	
	TVec3D* drag = [[TVec3D alloc] initWithX:gridSz Y:gridSz Z:gridSz];
	drag = [TVec3D multiplyA:drag andB:[[TGlobal G]->currentLevelView getAxisMask]];
	
	[self DragSelectionsBy:[[TVec3D alloc] initWithX:drag->x Y:drag->y Z:drag->z]];
	
	[historyMgr stopRecord];
	
	[self refreshInspectors];
}

- (void)cut:(id)sender
{
	[historyMgr startRecord:@"Cut"];
	
	[self copy:self];
	[self destroyAllSelected];
	
	[self markAllTexturesDirtyRenderArray];
	[self redrawLevelViewports];

	[historyMgr stopRecord];

	[self refreshInspectors];
}

- (void)copy:(id)sender
{
	NSPasteboard* pb = [NSPasteboard generalPasteboard];
	NSArray *types = [NSArray arrayWithObjects:NSStringPboardType, nil];
	[pb declareTypes:types owner:self];	

	NSMutableString* stringData = [NSMutableString string];
	
	NSMutableArray* selectedFaces = [selMgr getSelections:TSC_Face];
	
	if( [selectedFaces count] > 0 )
	{
		// NOTE: Face text starts with "#"
		
		TFace* F = [selectedFaces objectAtIndex:0];
		[stringData appendFormat:@"#%@,%d,%d,%d,%f,%f", F->textureName, F->uoffset, F->voffset, F->rotation, F->uscale, F->vscale ];
	}
	else
	{
		// NOTE: Entity text starts with "{"
		
		for( TEntity* E in entities )
		{
			if( [E isPointEntity] )
			{
				if( [selMgr isSelected:E] )
				{
					[stringData appendString:[E exportToText:NO]];
				}
			}
			else
			{
				BOOL bEntityHeaderExported = NO;
				
				for( TBrush* b in E->brushes )
				{
					if( [selMgr isSelected:b] )
					{
						// The first brush that gets exported needs to spit out the header info for it's parent entity.
						
						if( bEntityHeaderExported == NO )
						{
							[stringData appendString:@"{\n"];
							[stringData appendString:[E exportKeyValuesToText]];
							
							bEntityHeaderExported = YES;
						}
						
						// Export the brush
						
						[stringData appendString:[b exportToText]];
					}
				}

				// If an entity header was exported, close it up before leaving.
				
				if( bEntityHeaderExported == YES )
				{
					[stringData appendString:@"}\n"];
				}
			}
		}
	}
	
	[pb setString:stringData forType:NSStringPboardType];
}

- (void)paste:(id)sender
{
	[TGlobal G]->drawingPausedRefCount++;
	
	[historyMgr startRecord:@"Paste"];
	
	NSPasteboard* pb = [NSPasteboard generalPasteboard];
	NSArray *types = [NSArray arrayWithObjects:NSStringPboardType, nil];
	NSString *bestType = [pb availableTypeFromArray:types];
	
	if (bestType != nil)
	{
		NSString* text = [pb stringForType:NSStringPboardType];
		
		if( [[text substringToIndex:1] isEqualToString:@"#"] )
		{
			// NOTE: Face text starts with "#"
			
			NSScanner* scanner = [NSScanner scannerWithString:text];
			NSString *textureName;
			int UOffset, VOffset, Rotation;
			float UScale, VScale;
			
			[scanner scanString:@"#" intoString:nil];
			[scanner scanUpToString:@"," intoString:&textureName];
			[scanner scanString:@"," intoString:nil];
			[scanner scanInt:&UOffset];
			[scanner scanString:@"," intoString:nil];
			[scanner scanInt:&VOffset];
			[scanner scanString:@"," intoString:nil];
			[scanner scanInt:&Rotation];
			[scanner scanString:@"," intoString:nil];
			[scanner scanFloat:&UScale];
			[scanner scanString:@"," intoString:nil];
			[scanner scanFloat:&VScale];
			
			[historyMgr startRecord:@"Paste Face Attributes"];
			
			for( TEntity* E in entities )
			{
				for( TBrush* B in E->brushes )
				{
					for( TFace* F in B->faces )
					{
						if( [selMgr isSelected:B] || [selMgr isSelected:F] )
						{
							[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_ModifyFaceTextureAttribs Object:F
							    OldData:[NSArray arrayWithObjects:
										 [F->textureName mutableCopy],
										 [NSNumber numberWithInt:F->uoffset],
										 [NSNumber numberWithInt:F->voffset],
										 [NSNumber numberWithInt:F->rotation],
										 [NSNumber numberWithFloat:F->uscale],
										 [NSNumber numberWithFloat:F->vscale], nil]
								NewData:[NSArray arrayWithObjects:
										 [textureName mutableCopy],
										 [NSNumber numberWithInt:UOffset],
										 [NSNumber numberWithInt:VOffset],
										 [NSNumber numberWithInt:Rotation],
										 [NSNumber numberWithFloat:UScale],
										 [NSNumber numberWithFloat:VScale], nil]]
							 ];
							
							F->textureName = [textureName mutableCopy];
							F->uoffset = UOffset;
							F->voffset = VOffset;
							F->rotation = Rotation;
							F->uscale = UScale;
							F->vscale = VScale;
							
							[F generateTexCoords:self];
						}
					}
				}
			}
			
			[historyMgr stopRecord];
			
			[self markAllTexturesDirtyRenderArray];
		}
		else
		{
			[selMgr unselectAll:TSC_Level];
			[selMgr unselectAll:TSC_Face];
			[selMgr unselectAll:TSC_Vertex];
			
			// NOTE: Entity text starts with "{"
			
			[self importEntitiesFromText:[text mutableCopy] SelectAfterImport:YES];
			[entities sortUsingSelector:@selector(compareByClassName:)];
		}
	}
	
	[self maybeCreateNewQuickGroupID];
	
	[historyMgr stopRecord];

	[TGlobal G]->drawingPausedRefCount--;

	[self refreshInspectors];
	[self redrawTextureViewports];
}

// Looks at all selected entities/brushes and if they all have the same quickgroup ID, a new one is generated for them.
// If the IDs differ, we remove them instead.

-(void) maybeCreateNewQuickGroupID
{
	int lastQuickgroupID = -1;
	BOOL bResetAll = NO;
	
	for( TEntity* E in entities )
	{
		if( [selMgr isSelected:E] )
		{
			if( lastQuickgroupID == -1 )
			{
				lastQuickgroupID = E->quickGroupID;
			}
			else
			{
				if( lastQuickgroupID != E->quickGroupID )
				{
					bResetAll = YES;
					break;
				}
			}
		}
		
		for( TBrush* B in E->brushes )
		{
			if( [selMgr isSelected:B] )
			{
				if( lastQuickgroupID == -1 )
				{
					lastQuickgroupID = B->quickGroupID;
				}
				else
				{
					if( lastQuickgroupID != B->quickGroupID )
					{
						bResetAll = YES;
						break;
					}
				}
			}
		}
	}
	
	if( lastQuickgroupID != -1 )
	{
		if( bResetAll )
		{
			for( TEntity* E in entities )
			{
				if( [selMgr isSelected:E] && [E isPointEntity] )
				{
					E->quickGroupID = -1;
				}
				
				for( TBrush* B in E->brushes )
				{
					if( [selMgr isSelected:B] )
					{
						B->quickGroupID = -1;
					}
				}
			}
		}
		else
		{
			int quickGroupID = [[TGlobal G] generateQuickGroupID];
			
			for( TEntity* E in entities )
			{
				if( [selMgr isSelected:E] && [E isPointEntity] )
				{
					E->quickGroupID = quickGroupID;
				}
				
				for( TBrush* B in E->brushes )
				{
					if( [selMgr isSelected:B] )
					{
						B->quickGroupID = quickGroupID;
					}
				}
			}
		}
	}
}

-(void) importEntitiesFromText:(NSMutableString*)InText SelectAfterImport:(BOOL)InSelectAfterImport
{
	[TGlobal G]->drawingPausedRefCount++;
	
	NSMutableArray* lines = [[InText componentsSeparatedByString: @"\n"] mutableCopy];
	
	NSMutableString* entityText = [NSMutableString string];
	int depth = 0;
	
	for( NSString* line in lines )
	{
		line = [line stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \t\r\n"]];
		
		if( [line length] > 9 && [[line substringToIndex:10] isEqualToString:@"// CONFIG_"] )
		{
			[configLines addObject:line];
		}
		else if( [line length] == 0 )
		{
			// skip blank lines
		}
		else if( [[line substringToIndex:1] isEqualToString:@"{"] )
		{
			[entityText appendFormat:@"%@\n", line];
			
			depth++;
		}
		else if( [line isEqualToString:@"}"] )
		{
			[entityText appendFormat:@"%@\n", line];
			
			depth--;
			
			if( depth == 0 )
			{
				[self importSingleEntityFromText:entityText SelectAfterImport:InSelectAfterImport];
				entityText = [NSMutableString string];
			}
		}
		else
		{
			[entityText appendFormat:@"%@\n", line];
		}
	}
	
	// Restore items from the config lines

	bookmarks = [NSMutableDictionary new];
	
	for( NSString* S in configLines )
	{
		NSArray* chunks = [S componentsSeparatedByString:@":"];
		
		if( [[chunks objectAtIndex:0] isEqualToString:@"// CONFIG_BOOKMARK"] == YES )
		{
			NSArray* subchunks = [[chunks objectAtIndex:1] componentsSeparatedByString:@" "];
			
			if( [subchunks count] > 0 )
			{
				TBookmark* BM = [TBookmark new];
				
				NSString* key = [subchunks objectAtIndex:0];
				
				BM->perspectiveLocation->x = [[subchunks objectAtIndex:1] floatValue];
				BM->perspectiveLocation->y = [[subchunks objectAtIndex:2] floatValue];
				BM->perspectiveLocation->z = [[subchunks objectAtIndex:3] floatValue];
				
				BM->perspectiveRotation->x = [[subchunks objectAtIndex:4] floatValue];
				BM->perspectiveRotation->y = [[subchunks objectAtIndex:5] floatValue];
				BM->perspectiveRotation->z = [[subchunks objectAtIndex:6] floatValue];
				
				BM->orthoLocation->x = [[subchunks objectAtIndex:7] floatValue];
				BM->orthoLocation->y = [[subchunks objectAtIndex:8] floatValue];
				BM->orthoLocation->z = [[subchunks objectAtIndex:9] floatValue];
				
				BM->orthoZoom = [[subchunks objectAtIndex:10] floatValue];
											  
				[bookmarks setObject:BM forKey:key];
			}
		}
	}
	
	if( [pendingWADName length] > 0 )
	{
		// If the WAD is different from what is currently loaded, load the new WAD.
		// TODO: might be nice if this would append the new WAD rather than just loading the new one.  Then ask the user to save the newly merged WAD afterwards.
		
		if( [pendingWADName isEqualToString:lastLoadedWADName] == NO )
		{
			[self loadWAD:pendingWADName];
			lastLoadedWADName = [pendingWADName mutableCopy];
		}
	}
	
	[TGlobal G]->drawingPausedRefCount--;
}

// Creates a single entity from the Quake MAP text in InText

-(void) importSingleEntityFromText:(NSMutableString*)InText SelectAfterImport:(BOOL)InSelectAfterImport
{
	NSMutableArray* lines = [[InText componentsSeparatedByString: @"\n"] mutableCopy];
	TEntity* entity = nil;
	
	// Scan the text ahead of time and find the classname.  If this is a worldspawn, the contents of InText
	// will be merged into our existing worldspawn.  Otherwise, a new entity is created.
	//
	// If there is no worldspawn at the moment, the import code will create it.
	
	BOOL bHasClassname = NO;
	BOOL bIsWorldspawn = NO;
	NSString *key, *value;
	NSScanner* scanner;
	
	NSString *wad = @"", *game = @"";
	
	for( NSString* S in lines )
	{
		S = [S stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \t\r\n"]];
		
		if( [S length] > 0 && [[S substringToIndex:1] isEqualToString:@"\""] )
		{
			// Reading a key/value for the current entity
			
			scanner = [NSScanner scannerWithString:S];
			
			[scanner scanString:@"\"" intoString:nil];
			[scanner scanUpToString: @"\"" intoString:&key];
			[scanner scanString:@"\"" intoString:nil];
			[scanner scanString:@"\"" intoString:nil];
			[scanner scanUpToString: @"\"" intoString:&value];
			
			if( bHasClassname == NO && [key isEqualToString:@"classname"] )
			{
				bHasClassname = YES;
				
				if( [value isEqualToString:@"worldspawn"] )
				{
					bIsWorldspawn = YES;
					entity = [self getEntityByClassName:@"worldspawn"];
				}
			}
			if( [key isEqualToString:@"wad"] )
			{
				wad = value;
			}
			if( [key isEqualToString:@"_game"] )
			{
				game = value;
			}
		}
	}
	
	// If the text doesn't specify a classname, force it to be the worldspawn.
	
	if( bHasClassname == NO )
	{
		entity = [self getEntityByClassName:@"worldspawn"];
		bIsWorldspawn = YES;
	}
	
	// Load the WAD file.  Load it here after all of the keys have been read so that the _game key will
	// be set if present in the MAP.
	//
	// We set the "_game" key/value here in case 
	
	if( bIsWorldspawn && [wad length] > 0 )
	{
		TEntity* worldspawn = [self findEntityByClassName:@"worldspawn"];
		
		if( [game length] > 0 )
		{
			[worldspawn->keyvalues setValue:game forKey:@"_game"];
		}
		
		pendingWADName = [wad mutableCopy];
	}
	
	// Read the lines and parse the entity
	
	NSMutableArray* clipPlanes = nil;
	NSMutableArray* polygons = nil;
	TVec3D *v1, *v2, *v3;
	NSString* texName;
	int depth = 0, uoffset, voffset, rotation, brushQuickGroupID;
	BOOL bTemporaryBrush = NO;
	float uscale, vscale;
	TPlane* plane;
	
	//NSOperationQueue* queue = [NSOperationQueue new];
	
	for( NSString* S in lines )
	{
		S = [S stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \t\r\n"]];
		
		if( [S length] == 0 )
		{
			// skip blank lines
		}
		else if( [[S substringToIndex:1] isEqualToString:@"/"] )
		{
			// Parse out special tags
			
			if( depth > 1 )
			{
				brushQuickGroupID = -1;
				bTemporaryBrush = NO;
				
				NSArray* chunks = [S componentsSeparatedByString:@" "];
				
				for( NSString* SS in chunks )
				{
					NSArray* subchunks = [SS componentsSeparatedByString:@":"];
					
					if( [[subchunks objectAtIndex:0] isEqualToString:@"QG"] )
					{
						brushQuickGroupID = [[subchunks objectAtIndex:1] intValue];
					}
					
					if( [[subchunks objectAtIndex:0] isEqualToString:@"TB"] )
					{
						if( [[subchunks objectAtIndex:1] boolValue] == YES )
						{
							bTemporaryBrush = YES;
						}
					}
				}
			}
			else
			{
				NSArray* chunks = [S componentsSeparatedByString:@" "];
				
				for( NSString* SS in chunks )
				{
					NSArray* subchunks = [SS componentsSeparatedByString:@":"];
					
					if( [[subchunks objectAtIndex:0] isEqualToString:@"QG"] )
					{
						entity->quickGroupID = [[subchunks objectAtIndex:1] intValue];
					}
				}
			}
		}
		else if( [[S substringToIndex:1] isEqualToString:@"["] )
		{
			if( depth > 0 )
			{
				// Starting a new triangle mesh within the current entity
				polygons = [NSMutableArray new];
				clipPlanes = nil;
			}
			
			depth++;
		}
		else if( [S isEqualToString:@"]"] )
		{
			if( depth > 1 )
			{
				TPolyMesh* TM = [TPolyMesh new];
				
				for( TFace* F in polygons )
				{
					[TM->faces addObject:F];
				}
				
				[TM finalizeInternals];
				[TM generateTexCoords:self];
				
				[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_AddBrush Object:TM Owner:entity]];
				[entity->brushes addObject:TM];
				
				polygons = nil;
			}
		}
		else if( [[S substringToIndex:1] isEqualToString:@"{"] )
		{
			if( depth == 0 )
			{
				// Starting a new entity
				if( entity == nil )
				{
					entity = [TEntity new];
				}
			}
			else
			{
				// Starting a new brush within the current entity
				clipPlanes = [NSMutableArray new];
				polygons = nil;
			}
			
			depth++;
		}
		else if( [S isEqualToString:@"}"] )
		{
			if( depth > 1 && clipPlanes != nil )
			{
				if( bTemporaryBrush == NO )
				{
					//[queue addOperation:[[NSOperationCreateBrushFromPlanes alloc] initWithMap:self ClipPlanes:clipPlanes quickGroupID:brushQuickGroupID Entity:entity SelectAfterImport:InSelectAfterImport]];

					///*
					{
						TBrush* brush = [TBrush createBrushFromPlanes:clipPlanes MAP:self];
						
						[entity->brushes addObject:brush];
						[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_AddBrush Object:brush Owner:entity]];
						
						brush->quickGroupID = brushQuickGroupID;
						
						if( InSelectAfterImport == YES )
						{
							[selMgr addSelection:brush];
						}
						
						//NSLog( @"Brush created from %d planes", [clipPlanes count] );
					}
					//*/
				}
				clipPlanes = nil;
			}
			else
			{
				//[queue waitUntilAllOperationsAreFinished];
				
				[entity finalizeInternals:self];
				
				// Only add the entity to the entity list if it is not the worldspawn.
				// Having mutiple worldspawns around leads to all sorts of bad behavior.
				
				if( !bIsWorldspawn )
				{
					[entities addObject:entity];
					
					[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_AddEntity Object:entity]];
					
					if( InSelectAfterImport == YES )
					{
						[selMgr addSelection:entity];
					}
				}
				
				// Break out special key/values that we need for the editor
				entity->location = [[entity valueVectorForKey:@"origin" defaultValue:@"0 0 0"] mutableCopy];
				entity->location = [entity->location swizzleFromQuake];
				
				entity->rotation->y = [[entity valueForKey:@"angle" defaultValue:@"0"] floatValue];
				
				entity->spawnFlags = [[entity valueForKey:@"spawnflags" defaultValue:@"0"] intValue];
				
				entity = nil;
			}
			
			depth--;
		}
		else if( [[S substringToIndex:1] isEqualToString:@"\""] )
		{
			// Reading a key/value for the current entity
			
			scanner = [NSScanner scannerWithString:S];
			
			[scanner scanString:@"\"" intoString:nil];
			[scanner scanUpToString: @"\"" intoString:&key];
			[scanner scanString:@"\"" intoString:nil];
			[scanner scanString:@"\"" intoString:nil];
			[scanner scanUpToString: @"\"" intoString:&value];
			
			[entity->keyvalues setValue:value forKey:key];
		}
		else if( [[S substringToIndex:1] isEqualToString:@"("] || polygons != nil )
		{
			scanner = [NSScanner scannerWithString:S];
			
			if( clipPlanes != nil )
			{
				// Reading a plane for the current brush
				
				v1 = [TVec3D new];
				v2 = [TVec3D new];
				v3 = [TVec3D new];
				
				[scanner scanString:@"( " intoString:nil];
				[scanner scanFloat:&(v1->x)];
				[scanner scanFloat:&(v1->y)];
				[scanner scanFloat:&(v1->z)];
				[scanner scanString:@") ( " intoString:nil];
				[scanner scanFloat:&(v2->x)];
				[scanner scanFloat:&(v2->y)];
				[scanner scanFloat:&(v2->z)];
				[scanner scanString:@") ( " intoString:nil];
				[scanner scanFloat:&(v3->x)];
				[scanner scanFloat:&(v3->y)];
				[scanner scanFloat:&(v3->z)];
				[scanner scanString:@")" intoString:&texName];
				[scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" "] intoString:&texName];
				[scanner scanInt:&uoffset];
				[scanner scanInt:&voffset];
				[scanner scanInt:&rotation];
				[scanner scanFloat:&uscale];
				[scanner scanFloat:&vscale];
				
				v1 = [v1 swizzleFromQuake];
				v2 = [v2 swizzleFromQuake];
				v3 = [v3 swizzleFromQuake];
			
				plane = [[TPlane alloc] initFromTriangleA:v1 B:v2 C:v3];
				
				plane->textureName = [texName mutableCopy];
				plane->uoffset = uoffset;
				plane->voffset = voffset;
				plane->rotation = rotation;
				plane->uscale = uscale;
				plane->vscale = vscale;
				
				[clipPlanes addObject:plane];
			}
			else
			{
				// Read a polygon for the current polygon mesh
				
				int numVerts;
				TFace* face = [TFace new];
				
				[scanner scanInt:&numVerts];
				
				int x;
				for( x = 0 ; x < numVerts ; ++x )
				{
					TVec3D* vtx = [TVec3D new];
					
					[scanner scanString:@"( " intoString:nil];
					[scanner scanFloat:&(vtx->x)];
					[scanner scanFloat:&(vtx->y)];
					[scanner scanFloat:&(vtx->z)];
					[scanner scanString:@") " intoString:nil];
					
					[face->verts addObject:[vtx swizzleFromQuake]];
				}

				[scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" "] intoString:&texName];
				[scanner scanInt:&uoffset];
				[scanner scanInt:&voffset];
				[scanner scanInt:&rotation];
				[scanner scanFloat:&uscale];
				[scanner scanFloat:&vscale];
				
				face->textureName = [texName mutableCopy];
				face->uoffset = uoffset;
				face->voffset = voffset;
				face->rotation = rotation;
				face->uscale = uscale;
				face->vscale = vscale;
				
				[face finalizeInternals];

				[polygons addObject:face];
			}
		}
	}
	
	[self refreshInspectors];
}

// Applys the currently selected texture to whichever brushes and faces are selected

-(void) applySelectedTexture
{
	[historyMgr startRecord:@"Apply Texture"];

	NSString* texturename = [selMgr getSelectedTextureName];
	
	TTexture* T = [self findTextureByName:texturename];
	
	if( T != nil )
	{
		T->mruClickCount = [[TGlobal G] generateMRUClickCount];
		
		for( TEntity* E in entities )
		{
			for( TBrush* B in E->brushes )
			{
				for( TFace* F in B->faces )
				{
					if( [selMgr isSelected:B] || [selMgr isSelected:F] )
					{
						[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_ModifyFaceTextureName Object:F OldData:[F->textureName mutableCopy] NewData:[texturename mutableCopy]]];
 						[F markDirtyRenderArray];
						F->textureName = [texturename mutableCopy];
						[F markDirtyRenderArray];
						
						[F generateTexCoords:self];
					}
				}
			}
		}
		
		[historyMgr stopRecord];
		
		[self redrawLevelViewports];
	}
}

-(void) offsetSelectedTexturesByU:(int)InU V:(int)InV
{
	[historyMgr startRecord:@"Offset Texture"];
	
	for( TEntity* E in entities )
	{
		for( TBrush* B in E->brushes )
		{
			for( TFace* F in B->faces )
			{
				if( [selMgr isSelected:B] || [selMgr isSelected:F] )
				{
					[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_ModifyFaceTextureAttribs Object:F
					   OldData:[NSArray arrayWithObjects:
								[F->textureName mutableCopy],
								[NSNumber numberWithInt:F->uoffset],
								[NSNumber numberWithInt:F->voffset],
								[NSNumber numberWithInt:F->rotation],
								[NSNumber numberWithFloat:F->uscale],
								[NSNumber numberWithFloat:F->vscale], nil]
					   NewData:[NSArray arrayWithObjects:
								[F->textureName mutableCopy],
								[NSNumber numberWithInt:F->uoffset + InU],
								[NSNumber numberWithInt:F->voffset + InV],
								[NSNumber numberWithInt:F->rotation],
								[NSNumber numberWithFloat:F->uscale],
								[NSNumber numberWithFloat:F->vscale], nil]]
					];
					
					F->uoffset += InU;
					F->voffset += InV;
					
					[F generateTexCoords:self];
				}
			}
		}
	}
	
	[historyMgr stopRecord];
}

-(void) rotateSelectedTexturesBy:(int)InAngle
{
	[historyMgr startRecord:@"Rotate Texture"];
	
	for( TEntity* E in entities )
	{
		for( TBrush* B in E->brushes )
		{
			for( TFace* F in B->faces )
			{
				if( [selMgr isSelected:B] || [selMgr isSelected:F] )
				{
					[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_ModifyFaceTextureAttribs Object:F
					   OldData:[NSArray arrayWithObjects:
								[F->textureName mutableCopy],
								[NSNumber numberWithInt:F->uoffset],
								[NSNumber numberWithInt:F->voffset],
								[NSNumber numberWithInt:F->rotation],
								[NSNumber numberWithFloat:F->uscale],
								[NSNumber numberWithFloat:F->vscale], nil]
					   NewData:[NSArray arrayWithObjects:
								[F->textureName mutableCopy],
								[NSNumber numberWithInt:F->uoffset],
								[NSNumber numberWithInt:F->voffset],
								[NSNumber numberWithInt:F->rotation + InAngle],
								[NSNumber numberWithFloat:F->uscale],
								[NSNumber numberWithFloat:F->vscale], nil]]
					 ];
					F->rotation += InAngle;
					
					[F generateTexCoords:self];
				}
			}
		}
	}
	
	[historyMgr stopRecord];
}

-(void) setSelectedTextureRotation:(int)InAngle
{
	[historyMgr startRecord:@"Rotate Texture"];
	
	for( TEntity* E in entities )
	{
		for( TBrush* B in E->brushes )
		{
			for( TFace* F in B->faces )
			{
				if( [selMgr isSelected:B] || [selMgr isSelected:F] )
				{
					[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_ModifyFaceTextureAttribs Object:F
					   OldData:[NSArray arrayWithObjects:
								[F->textureName mutableCopy],
								[NSNumber numberWithInt:F->uoffset],
								[NSNumber numberWithInt:F->voffset],
								[NSNumber numberWithInt:F->rotation],
								[NSNumber numberWithFloat:F->uscale],
								[NSNumber numberWithFloat:F->vscale], nil]
					   NewData:[NSArray arrayWithObjects:
								[F->textureName mutableCopy],
								[NSNumber numberWithInt:F->uoffset],
								[NSNumber numberWithInt:F->voffset],
								[NSNumber numberWithInt:InAngle],
								[NSNumber numberWithFloat:F->uscale],
								[NSNumber numberWithFloat:F->vscale], nil]]
					 ];
					F->rotation = InAngle;
					
					[F generateTexCoords:self];
				}
			}
		}
	}
	
	[historyMgr stopRecord];
}

-(void) scaleSelectedTexturesByU:(float)InU V:(float)InV
{
	[historyMgr startRecord:@"Scale Texture"];
	
	for( TEntity* E in entities )
	{
		for( TBrush* B in E->brushes )
		{
			for( TFace* F in B->faces )
			{
				if( [selMgr isSelected:B] || [selMgr isSelected:F] )
				{
					[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_ModifyFaceTextureAttribs Object:F
					   OldData:[NSArray arrayWithObjects:
								[F->textureName mutableCopy],
								[NSNumber numberWithInt:F->uoffset],
								[NSNumber numberWithInt:F->voffset],
								[NSNumber numberWithInt:F->rotation],
								[NSNumber numberWithFloat:F->uscale],
								[NSNumber numberWithFloat:F->vscale], nil]
					   NewData:[NSArray arrayWithObjects:
								[F->textureName mutableCopy],
								[NSNumber numberWithInt:F->uoffset],
								[NSNumber numberWithInt:F->voffset],
								[NSNumber numberWithInt:F->rotation],
								[NSNumber numberWithFloat:F->uscale * InU],
								[NSNumber numberWithFloat:F->vscale * InV], nil]]
					 ];
					F->uscale *= InU;
					F->vscale *= InV;
					
					[F generateTexCoords:self];
				}
			}
		}
	}
	
	[historyMgr stopRecord];
}

-(void) resetSelectedFacesUOffset:(BOOL)InUOffset VOffset:(BOOL)InVOffset Rotation:(BOOL)InRotation UScale:(BOOL)InUScale VScale:(BOOL)InVScale
{
	[historyMgr startRecord:@"Reset Texture Alignment"];
	
	for( TEntity* E in entities )
	{
		for( TBrush* B in E->brushes )
		{
			for( TFace* F in B->faces )
			{
				if( [selMgr isSelected:B] || [selMgr isSelected:F] )
				{
					[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_ModifyFaceTextureAttribs Object:F
					   OldData:[NSArray arrayWithObjects:
								[F->textureName mutableCopy],
								[NSNumber numberWithInt:F->uoffset],
								[NSNumber numberWithInt:F->voffset],
								[NSNumber numberWithInt:F->rotation],
								[NSNumber numberWithFloat:F->uscale],
								[NSNumber numberWithFloat:F->vscale], nil]
					   NewData:[NSArray arrayWithObjects:
								[F->textureName mutableCopy],
								[NSNumber numberWithInt:(InUOffset ? 0 : F->uoffset)],
								[NSNumber numberWithInt:(InVOffset ? 0 : F->voffset)],
								[NSNumber numberWithInt:(InRotation ? 0 : F->rotation)],
								[NSNumber numberWithFloat:(InUScale ? 0.0f : F->uscale)],
								[NSNumber numberWithFloat:(InVScale ? 0.0f : F->vscale)], nil]]
					 ];

					if( InUOffset )		F->uoffset = 0;
					if( InVOffset )		F->voffset = 0;
					if( InRotation )	F->rotation = 0;
					if( InUScale )		F->uscale = 1.0;
					if( InVScale )		F->vscale = 1.0;
					
					[F generateTexCoords:self];
				}
			}
		}
	}
	
	[historyMgr stopRecord];
}

// Used by other classes to let the map document know that selections within the level have changed.

-(void) refreshInspectors
{
	MAPWindow* mapwindow = (MAPWindow*)[self windowForSheet];
	[mapwindow refreshInspectors];
}

-(void) createEntityFromSelections:(NSString*)InEntityClassName
{
	[historyMgr startRecord:@"Create Entity"];
	NSMutableArray* newSelections = [NSMutableArray new];
	
	TEntityClass* ec = [[TGlobal getMAP] findEntityClassByName:InEntityClassName];
	TEntity* newEntity = nil;
	NSArray* tempE = [NSArray arrayWithArray:entities];
	
	if( [InEntityClassName isEqualToString:@"worldspawn"] )
	{
		// If the user selects "worldspawn" from the class menu, just use
		// the existing worldspawn.
		
		newEntity = [self findEntityByClassName:@"worldspawn"];
	}
	else if( [ec isPointClass] == NO )
	{
		// If we're not creating a point class entity, create the entity ahead of time.
		// This is necessary because we may have to add multiple brushes to the new
		// entity.
		
		newEntity = [self addNewEntity:InEntityClassName];
	}
	
	for( TEntity* E in tempE )
	{
		if( [ec isPointClass] )
		{
			if( [E isPointEntity] )
			{
				if( [selMgr isSelected:E] )
				{
					[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_ChangeEntityClassname Object:E OldData:[E->entityClass->name mutableCopy] NewData:[InEntityClassName mutableCopy]]];
					[E->keyvalues setObject:[InEntityClassName mutableCopy] forKey:@"classname"];
					[E finalizeInternals:self];
					
					[newSelections addObject:E];
				}
			}
			else
			{
				NSArray* tempB = [NSArray arrayWithArray:E->brushes];
				
				for( TBrush* B in tempB )
				{
					if( [selMgr isSelected:B] )
					{
						newEntity = [self addNewEntity:InEntityClassName];
						newEntity->location = [B getCenter];
						[newEntity finalizeInternals:self];
						
						[newSelections addObject:newEntity];
						
						[self destroyObject:B];
						
						newEntity = nil;
					}
				}
			}
		}
		else
		{
			if( [E isPointEntity] == NO )
			{
				NSArray* tempB = [NSArray arrayWithArray:E->brushes];
				
				for( TBrush* B in tempB )
				{
					if( [selMgr isSelected:B] )
					{
						[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_AddBrushToEntity Object:B Owner:newEntity]];
						[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_RemoveBrushFromEntity Object:B Owner:E]];
						
						[newSelections addObject:B];
						[newEntity->brushes addObject:B];
						
						[E->brushes removeObject:B];
					}
				}
				
				// If the brush entity gave up all of it's brushes, it needs to go away.
				
				if( [E->brushes count] == 0 )
				{
					[self destroyObject:E];
				}
			}
		}
	}
	
	// If we created a brush entity at the start of this function, finalize it now.
	
	if( [ec isPointClass] == NO )
	{
		[newEntity finalizeInternals:self];
	}
	
	// Run a clean up here to remove any brush based entities that are now brushless
	
	tempE = [NSArray arrayWithArray:entities];
	
	for( TEntity* E in tempE )
	{
		if( [E isPointEntity] == NO && [E->brushes count] == 0 )
		{
			[self destroyEntity:E];
			
			// This entity may have been a newly created one that now is being deleted.  In that case
			// it would be in the newSelections array, so it and it's brushes need to be removed from
			// there before going forward.
			
			[newSelections removeObject:E];
			
			for( TBrush* B in E->brushes )
			{
				[newSelections removeObject:B];
			}
		}
	}
	
	// Unselect everything in the level so we can start fresh
	
	[selMgr unselectAll:TSC_Level];
	[selMgr unselectAll:TSC_Face];
	[selMgr unselectAll:TSC_Vertex];
	
	// Select all of the new entities/brushes that were created
	
	for( NSObject* O in newSelections )
	{
		[selMgr addSelection:O];
	}
	
	[self refreshInspectors];

	[historyMgr stopRecord];

	[entities sortUsingSelector:@selector(compareByClassName:)];
}

-(NSMutableArray*) getTexturesForWritingToWAD
{
	NSMutableArray* textures = [NSMutableArray new];
	
	for( TTexture* T in texturesFromWADs )
	{
		if( T->bShowInBrowser )
		{
			[textures addObject:T];
		}
	}
	
	return textures;
}

-(int) snapScalarToGrid:(float)InValue
{
	if( InValue > 0 )
	{
		InValue += (gridSz / 2.0f);
	}
	else
	{
		InValue -= (gridSz / 2.0f);
	}
	
	return (int)(InValue - (((int)InValue) % ((int)gridSz)));
}

-(TVec3D*) snapVtxToGrid:(TVec3D*)InValue
{
	return [[TVec3D alloc] initWithX:[self snapScalarToGrid:InValue->x] Y:[self snapScalarToGrid:InValue->y] Z:[self snapScalarToGrid:InValue->z]];
}

-(void) deleteEmptyBrushEntities
{
	NSMutableArray* tempEntities = [NSArray arrayWithArray:entities];
	
	for( TEntity* E in tempEntities )
	{
		if( [E isPointEntity] == NO && [E->brushes count] == 0 )
		{
			[self destroyEntity:E];
		}
	}
}

// Looks for selected faces in the world and selects their texture in the texture browser.  The browser
// window is then scrolled so that the selected texture is visible.

-(void) synchronizeTextureBrowserWithSelectedFaces
{
	for( TEntity* E in entities )
	{
		for( TBrush* B in E->brushes )
		{
			for( TFace* F in B->faces )
			{
				if( [selMgr isSelected:F] )
				{
					[selMgr unselectAll:TSC_Texture];
					[selMgr addSelection:[self findTextureByName:F->textureName]];
					[self scrollToSelectedTexture];
				}
			}
		}
	}
	
	[self redrawTextureViewports];
}

// Adjusts the view so that the selected texture is visible.

-(void) scrollToSelectedTexture
{
	for( TOpenGLView* VW in textureViewports )
	{
		[VW scrollToSelectedTexture];
	}
	
	[self redrawTextureViewports];
}

// Selects every visible object

-(void) selectAll
{
	[historyMgr startRecord:@"Select All"];

	[selMgr unselectAll:TSC_Level];
	[selMgr unselectAll:TSC_Face];
	[selMgr unselectAll:TSC_Vertex];
	
	for( TEntity* E in [self _visibleEntities] )
	{
		[selMgr addSelection:E];
		
		for( TBrush* B in [E _visibleBrushes:self] )
		{
			[selMgr addSelection:B];
		}
	}
	
	[historyMgr stopRecord];
	
	[self refreshInspectors];
	[self redrawLevelViewports];
}

// Selects things that match the current selection.  This is context sensitive
// in that it will select in this order:
//
// 1) Faces with matching textures
// 2) Entities of matching classnames

-(void) selectMatching
{
	[historyMgr startRecord:@"Select Matching"];
	
	if( [[TGlobal G]->currentLevelView isKindOfClass:[TTextureBrowserView class]] )
	{
		NSString* texturename = [[selMgr getSelectedTextureName] uppercaseString];
		
		[selMgr unselectAll:TSC_Level];
		[selMgr unselectAll:TSC_Face];
		[selMgr unselectAll:TSC_Vertex];
		
		for( TEntity* E in [self _visibleEntities] )
		{
			for( TBrush* B in [E _visibleBrushes:self] )
			{
				for( TFace* F in B->faces )
				{
					if( [F->textureName isEqualToString:texturename] )
					{
						[selMgr addSelection:F];
					}
				}
			}
		}
	}
	else
	{
		if( [selMgr hasSelectionsInCategory:TSC_Face] )
		{
			// Select faces that have the same texture as the selected faces
			
			NSMutableArray* selectedFaces = [selMgr getSelections:TSC_Face];
			NSMutableArray* textureNames = [NSMutableArray new];
			
			for( TFace* F in selectedFaces )
			{
				if( [textureNames containsObject:F->textureName] == NO )
				{
					[textureNames addObject:F->textureName];
				}
			}
			
			[selMgr unselectAll:TSC_Level];
			[selMgr unselectAll:TSC_Face];
			[selMgr unselectAll:TSC_Vertex];
			
			for( TEntity* E in [self _visibleEntities] )
			{
				for( TBrush* B in [E _visibleBrushes:self] )
				{
					for( TFace* F in B->faces )
					{
						if( [textureNames containsObject:F->textureName] )
						{
							[selMgr addSelection:F];
						}
					}
				}
			}
		}
		else
		{
			// Select entities of the same entity class
			
			NSMutableArray* classes = [selMgr getSelectedEntityClasses];
			
			[selMgr unselectAll:TSC_Level];
			[selMgr unselectAll:TSC_Face];
			[selMgr unselectAll:TSC_Vertex];
			
			for( TEntity* E in entities )
			{
				if( [classes containsObject:E->entityClass] )
				{
					[selMgr addSelection:E];
					
					for( TBrush* B in E->brushes )
					{
						[selMgr addSelection:B];
					}
				}
			}
		}
	}
	
	[historyMgr stopRecord];
	
	[self refreshInspectors];
	[self redrawLevelViewports];
}

// Selects all the brushes that are inside of the selected entities.

-(void) selectMatchingWithinEntity
{
	[historyMgr startRecord:@"Select Entire Entity"];

	NSMutableArray* selectedEntities = [selMgr getSelectedEntities];
	
	for( TEntity* E in selectedEntities )
	{
		for( TBrush* B in E->brushes )
		{
			[selMgr addSelection:B];
		}
	}
	
	[historyMgr stopRecord];
	
	[self refreshInspectors];
	[self redrawLevelViewports];
}

-(void) deselect
{
	// If there are vertices or faces selected, deselect those first but leave the selected brushes alone.
	// This mean that if you want to deselect absolutely everything, you'll need to
	// hit ESC twice.
	
	if( [selMgr hasSelectionsInCategory:TSC_Vertex] || [selMgr hasSelectionsInCategory:TSC_Face] )
	{
		[selMgr unselectAll:TSC_Vertex];
		[selMgr unselectAll:TSC_Face];
	}
	else
	{
		[selMgr unselectAll:TSC_Level];
	}
	
	[selMgr unselectAll:TSC_Face];
	
	[self redrawLevelViewports];
	[self refreshInspectors];
}

-(void) csgCreateClipBrush
{
	[historyMgr startRecord:@"CSG Create Clip Brush"];
	
	NSMutableArray* selectedBrushes = [NSMutableArray new];
	
	for( TEntity* E in entities )
	{
		for( TBrush* B in E->brushes )
		{
			if( [selMgr isSelected:B] )
			{
				[selectedBrushes addObject:B];
			}
		}
	}
	
	TEntity* E = [self findBestSelectedBrushBasedEntity];
	TBrush* newBrush = [self createConvexHull:selectedBrushes useBrushPlanesFirst:NO];
	
	[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_AddBrush Object:newBrush Owner:E]];
	[E->brushes addObject:newBrush];
	
	for( TFace* F in newBrush->faces )
	{
		F->textureName = @"CLIP";
	}
	
	[newBrush generateTexCoords:self];
	
	[selMgr addSelection:newBrush];
	
	[historyMgr stopRecord];
	
	[self redrawLevelViewports];
}

-(void) csgMergeConvexHull
{
	[historyMgr startRecord:@"CSG Merge Convex Hull"];
	
	NSMutableArray* selectedBrushes = [NSMutableArray new];
	
	for( TEntity* E in entities )
	{
		for( TBrush* B in E->brushes )
		{
			if( [selMgr isSelected:B] )
			{
				[selectedBrushes addObject:B];
			}
		}
	}
	
	TEntity* E = [self findBestSelectedBrushBasedEntity];
	TBrush* newBrush = [self createConvexHull:selectedBrushes useBrushPlanesFirst:NO];
	
	[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_AddBrush Object:newBrush Owner:E]];
	[E->brushes addObject:newBrush];
	
	[selMgr addSelection:newBrush];
	
	// Delete the originally selected brushes
	
	for( TBrush* B in selectedBrushes )
	{
		[selMgr removeSelection:B];
		[self destroyObject:B];
	}

	[historyMgr stopRecord];

	[self redrawLevelViewports];
}

-(void) addPlaneIfUnique:(TPlane*)InPlane array:(NSMutableArray*)InArray
{
	for( TPlane* P in InArray )
	{
		if( [P isAlmostEqualTo:InPlane] )
		{
			return;
		}
	}
	
	[InArray addObject:InPlane];
}

-(TBrush*) createConvexHull:(NSMutableArray*)InBrushes useBrushPlanesFirst:(BOOL)InUseBrushPlanesFirst
{
	NSMutableArray* vertexCloud = [NSMutableArray new];
	NSMutableArray* faceCloud = [NSMutableArray new];
	
	for( TBrush* B in InBrushes )
	{
		for( TFace* F in B->faces )
		{
			for( TVec3D* V in F->verts )
			{
				BOOL bIsInCloud = NO;
				
				for( TVec3D* VV in vertexCloud )
				{
					if( [VV isAlmostEqualTo:V] )
					{
						bIsInCloud = YES;
						break;
					}
				}
				
				if( bIsInCloud == NO )
				{
					[vertexCloud addObject:[V mutableCopy]];
					[faceCloud addObject:F];
				}
			}
		}
	}

	// Get the center of the selection
	
	TVec3D* center = [TVec3D new];

	for( TVec3D* V in vertexCloud )
	{
		center = [TVec3D addA:V andB:center];
	}
	
	center = [TVec3D scale:center By:1.0f / (float)[vertexCloud count]];
	
	// Offset the cloud so that it is centered on the world origin
	
	NSMutableArray* wkCloud = [NSMutableArray arrayWithArray:vertexCloud];
	vertexCloud = [NSMutableArray new];
	
	for( TVec3D* V in wkCloud )
	{
		TVec3D* vtx = [TVec3D subtractA:V andB:center];
		[vertexCloud addObject:vtx];
	}
	
	// Now that we have a cloud of unique vertices, we need to generate a list of planes that form
	// the best convex hull for them.  The only way that I can see here is brute force.
	//
	// Planes in this list must not have any of the other vertices in front of them.
	
	NSMutableArray* planes = [NSMutableArray new];

	// If we are forcing the use of the brush planes in the creation of the hull, add those to the array first.
	
	if( InUseBrushPlanesFirst )
	{
		for( TBrush* B in InBrushes )
		{
			for( TFace* F in B->faces )
			{
				TVec3D* v0 = [TVec3D subtractA:[F->verts objectAtIndex:0] andB:center];
				TVec3D* v1 = [TVec3D subtractA:[F->verts objectAtIndex:1] andB:center];
				TVec3D* v2 = [TVec3D subtractA:[F->verts objectAtIndex:2] andB:center];

				TPlane* plane = [[TPlane alloc] initFromTriangleA:v0 B:v2 C:v1];
				[plane copyTexturingAttribsFrom:F];
				
				[self addPlaneIfUnique:plane array:planes];
			}
		}
	}
	
	// If a set of starter planes was passed in, add those in first.
	
	int x;
	TVec3D* V0;
	TFace* face;
	
	for( x = 0 ; x < [vertexCloud count] ; ++x )
	{
		V0 = [vertexCloud objectAtIndex:x];
		face = [faceCloud objectAtIndex:x];
		
		for( TVec3D* V1 in vertexCloud )
		{
			if( [V1 isAlmostEqualTo:V0] == NO  )
			{
				for( TVec3D* V2 in vertexCloud )
				{
					if( [V2 isAlmostEqualTo:V0] == NO && [V2 isAlmostEqualTo:V1] == NO )
					{
						TPlane *plane, *flippedplane;
						
						plane = [[TPlane alloc] initFromTriangleA:V0 B:V1 C:V2];
						[plane copyTexturingAttribsFrom:face];
						 
						flippedplane = [[TPlane alloc] initFromTriangleA:V1 B:V0 C:V2];
						[flippedplane copyTexturingAttribsFrom:face];
						
						if( [plane->normal getSize] == 0 )
						{
							plane = nil;
						}
						
						if( [flippedplane->normal getSize] == 0 )
						{
							flippedplane = nil;
						}
						
						if( plane == nil && flippedplane == nil )
						{
							continue;
						}
						
						ESide side;
						
						for( TVec3D* V in vertexCloud )
						{
							if( [V isAlmostEqualTo:V0] == NO && [V isAlmostEqualTo:V1] == NO && [V isAlmostEqualTo:V2] == NO )
							{
								if( plane != nil )
								{
									side = [plane getVertexSide:V];
									if( side == S_Front )
									{
										plane = nil;
									}
								}
								
								if( flippedplane != nil )
								{
									side = [flippedplane getVertexSide:V];
									if( side == S_Front )
									{
										flippedplane = nil;
									}
								}
								
								if( plane == nil && flippedplane == nil )
								{
									break;
								}
							}
						}
						
						if( plane != nil )
						{
							[self addPlaneIfUnique:plane array:planes];
						}
						
						if( flippedplane != nil )
						{
							[self addPlaneIfUnique:flippedplane array:planes];
						}
					}
				}
			}
		}
	}
	
	// Using the planes we selected, create a new brush to replace the selected group
	
	TBrush* newBrush = [TBrush createBrushFromPlanes:planes MAP:self];
	
	// Move the vertices back to the proper spot in worldspace
	
	for( TFace* F in newBrush->faces )
	{
		for( TVec3D* V in F->verts )
		{
			TVec3D* vtx = [TVec3D addA:V andB:center];
			
			V->x = vtx->x;
			V->y = vtx->y;
			V->z = vtx->z;
		}
	}
	
	[newBrush generateTexCoords:self];
	
	return newBrush;
}

-(void) csgMergeBoundingBox
{
	[historyMgr startRecord:@"CSG Merge Bounding Box"];
	
	// Generate a vertex cloud
	
	NSMutableArray* vertexCloud = [NSMutableArray new];
	NSMutableArray* faceCloud = [NSMutableArray new];
	NSMutableArray* selectedBrushes = [NSMutableArray new];
	
	for( TEntity* E in entities )
	{
		for( TBrush* B in E->brushes )
		{
			if( [selMgr isSelected:B] )
			{
				[selectedBrushes addObject:B];
				
				for( TFace* F in B->faces )
				{
					for( TVec3D* V in F->verts )
					{
						BOOL bIsInCloud = NO;
						
						for( TVec3D* VV in vertexCloud )
						{
							if( [VV isAlmostEqualTo:V] )
							{
								bIsInCloud = YES;
								break;
							}
						}
						
						if( bIsInCloud == NO )
						{
							[vertexCloud addObject:[V mutableCopy]];
							[faceCloud addObject:F];
						}
					}
				}
			}
		}
	}
	
	// Get the bounding box of the vertex cloud
	
	TBBox* bbox = [TBBox new];
	
	for( TVec3D* V in vertexCloud )
	{
		[bbox addVertex:V];
	}
	
	// Create a new cube brush that surrounds the vertex cloud
	
	TEntity* E = [self findBestSelectedBrushBasedEntity];
	TBrushBuilderCube* bbc = [TBrushBuilderCube new];
	TBrush* brush = [bbc build:self Location:[bbox getCenter] Extents:[bbox getExtents] Args:NULL];
	
	[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_AddBrush Object:brush Owner:E]];
	[E->brushes addObject:brush];
	
	[brush generateTexCoords:self];
	
	// Delete the originally selected brushes
	
	for( TBrush* B in selectedBrushes )
	{
		[selMgr removeSelection:B];
		[self destroyObject:B];
	}
	
	[historyMgr stopRecord];
	
	[self redrawLevelViewports];
}

-(void) csgSubtractFromWorld
{
	[historyMgr startRecord:@"CSG Subtract From World"];
	
	NSMutableArray* carvers = [NSMutableArray new];
	
	// Get a list of all brushes that will be used to carve the unselected brushes
	
	for( TEntity* E in entities )
	{
		for( TBrush* B in E->brushes )
		{
			if( [selMgr isSelected:B] )
			{
				[carvers addObject:B];
			}
		}
	}
	
	// Carve all unselected brushes against the carver planes
	
	for( TBrush* CarverBrush in carvers )
	{
		NSMutableArray* tempEntities = [NSMutableArray arrayWithArray:[self _visibleEntities]];
		for( TEntity* E in tempEntities )
		{
			NSMutableArray* tempB = [NSMutableArray arrayWithArray:[E _visibleBrushes:self]];
			for( TBrush* B in tempB )
			{
				if( [selMgr isSelected:B] == NO )
				{
					BOOL bRemoveOriginal = NO;
					
					// Only clip this brush if it is overlapping the carver brush.
					
					if( [B doesBrushIntersect:CarverBrush] )
					{
						bRemoveOriginal = YES;
						[self subtractBrush:CarverBrush FromBrush:B Entity:E];
					}
					
					if( bRemoveOriginal )
					{
						[selMgr removeSelection:B];
						[self destroyObject:B];
					}
				}
			}
		}
	}
	
	[historyMgr stopRecord];
	
	[self redrawLevelViewports];
}

-(void) subtractBrush:(TBrush*)InCarver FromBrush:(TBrush*)InBrush Entity:(TEntity*)InEntity
{
	TBrush* remainderBrush = [InBrush mutableCopy];
	
	// Sort the faces of this brush before doing the cutting so that the largest faces (by area)
	// are processed first.  This minimizes cuts and damage to the level.
	
	NSMutableArray* sortedFaces = [NSMutableArray new];
	
	for( TFace* CF in InCarver->faces )
	{
		[sortedFaces addObject:[CF mutableCopy]];
	}
	
	[sortedFaces sortUsingSelector:@selector(compareByArea:)];
	
	for( TFace* CarverFace in sortedFaces )
	{
		// Only clip against this face if the brush we are clipping intersects with it.
		
		if( [remainderBrush doesFaceIntersect:CarverFace] )
		{	
			TPlane* planeFront = [[TPlane alloc] initFromTriangleA:[CarverFace->verts objectAtIndex:0] B:[CarverFace->verts objectAtIndex:1] C:[CarverFace->verts objectAtIndex:2]];
			TPlane* planeBack = [[TPlane alloc] initFromTriangleA:[CarverFace->verts objectAtIndex:2] B:[CarverFace->verts objectAtIndex:1] C:[CarverFace->verts objectAtIndex:0]];
			
			[planeFront copyTexturingAttribsFrom:CarverFace];
			[planeBack copyTexturingAttribsFrom:CarverFace];
			
			TBrush* frontBrush = [remainderBrush carveBrushAgainstPlane:planeFront MAP:self];
			remainderBrush = [remainderBrush carveBrushAgainstPlane:planeBack MAP:self];
			
			if( [frontBrush->faces count] > 3 )
			{
				[InEntity->brushes addObject:frontBrush];
				[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_AddBrush Object:frontBrush Owner:InEntity]];
			}
		}
	}
}

-(void) csgClipAgainstWorld
{
	[historyMgr startRecord:@"CSG Clip Against World"];
	
	NSMutableArray* carvers = [NSMutableArray new];
	
	// Get a list of all brushes that will be used to carve the selected brushes
	
	for( TEntity* E in [self _visibleEntities] )
	{
		for( TBrush* B in [E _visibleBrushes:self] )
		{
			if( [selMgr isSelected:B] == NO )
			{
				[carvers addObject:B];
			}
		}
	}
	
	NSMutableArray* newSelections = [NSMutableArray new];
	
	// Carve all selected brushes against the carver planes
	
	for( TEntity* E in entities )
	{
		NSMutableArray* tempB = [NSMutableArray arrayWithArray:E->brushes];
		for( TBrush* B in tempB )
		{
			if( [selMgr isSelected:B] == YES )
			{
				BOOL bRemoveOriginal = NO;
				TBrush* remainderBrush = [B mutableCopy];
				
				for( TBrush* CB in carvers )
				{
					// Only clip this brush if it is overlapping the carver brush.
					
					if( [B doesBrushIntersect:CB] )
					{
						bRemoveOriginal = YES;
						
						// Sort the faces of this brush before doing the cutting so that the largest faces (by area)
						// are processed first.  This minimizes cuts and damage to the level.
						
						NSMutableArray* sortedFaces = [NSMutableArray new];
						
						for( TFace* CF in CB->faces )
						{
							[sortedFaces addObject:[CF mutableCopy]];
						}
						
						[sortedFaces sortUsingSelector:@selector(compareByArea:)];
						
						for( TFace* CF in sortedFaces )
						{
							// Only clip against this face if the brush we are clipping intersects with it.
							
							if( [remainderBrush doesFaceIntersect:CF] )
							{	
								TPlane* planeFront = [[TPlane alloc] initFromTriangleA:[CF->verts objectAtIndex:0] B:[CF->verts objectAtIndex:1] C:[CF->verts objectAtIndex:2]];
								TPlane* planeBack = [[TPlane alloc] initFromTriangleA:[CF->verts objectAtIndex:2] B:[CF->verts objectAtIndex:1] C:[CF->verts objectAtIndex:0]];
								
								[planeFront copyTexturingAttribsFrom:CF];
								[planeBack copyTexturingAttribsFrom:CF];
								
								TBrush* frontBrush = [remainderBrush carveBrushAgainstPlane:planeFront MAP:self];
								remainderBrush = [remainderBrush carveBrushAgainstPlane:planeBack MAP:self];
								
								if( [frontBrush->faces count] > 3 )
								{
									[newSelections addObject:frontBrush];
									
									[E->brushes addObject:frontBrush];
									[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_AddBrush Object:frontBrush Owner:E]];
								}
							}
						}
					}
				}
				
				if( bRemoveOriginal )
				{
					[selMgr removeSelection:B];
					[self destroyObject:B];
				}
			}
		}
	}
	
	for( TBrush* B in newSelections )
	{
		[selMgr addSelection:B];
	}
	
	[historyMgr stopRecord];
	
	[self redrawLevelViewports];
}

-(void) csgBevel
{
	[historyMgr startRecord:@"CSG Bevel"];
	
	NSMutableArray* newSelections = [NSMutableArray new];
	
	NSMutableArray* tempE = [NSMutableArray arrayWithArray:entities];
	for( TEntity* E in tempE )
	{
		NSMutableArray* tempB = [NSMutableArray arrayWithArray:E->brushes];
		for( TBrush* B in tempB )
		{
			BOOL bDeleteOriginal = NO;
			
			if( [selMgr isSelected:B] )
			{
				NSMutableArray* edges = [B getUniqueSelectedEdges:self];
				
				if( [edges count] > 0 )
				{
					TBrush* beveledBrush = [B mutableCopy];
					bDeleteOriginal = YES;
					
					for( TEdge* G in edges )
					{
						TVec3D* v0 = [G->ownerFace->verts objectAtIndex:G->verts[0]];
						TVec3D* v1 = [G->ownerFace->verts objectAtIndex:G->verts[1]];
						
						TVec3D* vn0 = [B getVertexNormal:v0];
						TVec3D* vn1 = [B getVertexNormal:v1];
						
						TVec3D* edgeV0 = [TVec3D scale:[TVec3D addA:v0 andB:v1] By:0.5f];
						TVec3D* edgeN0 = [[TVec3D scale:[TVec3D addA:vn0 andB:vn1] By:0.5f] normalize];
						TVec3D* edgeVec = [[TVec3D subtractA:v1 andB:v0] normalize];
						TVec3D* edgeN1 = [TVec3D crossA:edgeN0 andB:edgeVec];
						TVec3D* edgeV2 = [TVec3D addA:edgeV0 andB:[TVec3D scale:edgeN1 By:16.0f]];
						TVec3D* delta = [TVec3D scale:edgeN0 By:-gridSz];
						
						TPlane* planeBack = [[TPlane alloc] initFromTriangleA:[TVec3D addA:v1 andB:delta] B:[TVec3D addA:v0 andB:delta] C:[TVec3D addA:edgeV2 andB:delta]];
						[planeBack copyTexturingAttribsFrom:G->ownerFace];
						
						beveledBrush = [beveledBrush carveBrushAgainstPlane:planeBack MAP:self];
					}
					
					if( [beveledBrush->faces count] > 3 )
					{
						[newSelections addObject:beveledBrush];
						[beveledBrush finalizeInternals];
						[E->brushes addObject:beveledBrush];
						[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_AddBrush Object:beveledBrush Owner:E]];
					}
					
					if( bDeleteOriginal )
					{
						[self destroyObject:B];
					}
				}
			}
		}
	}
	
	for( TBrush* B in newSelections )
	{
		[selMgr addSelection:B];
	}
	
	[historyMgr stopRecord];
	
	[self redrawLevelViewports];
}

-(void) csgExtrude
{
	[historyMgr startRecord:@"CSG Extrude"];
	
	NSMutableArray* newSelections = [NSMutableArray new];
	
	for( TEntity* E in entities )
	{
		NSMutableArray* tempB = [NSMutableArray arrayWithArray:E->brushes];
		for( TBrush* B in tempB )
		{
			for( TFace* F in B->faces )
			{
				if( [selMgr isSelected:F] )
				{
					NSMutableArray* planes = [NSMutableArray new];
					
					TFace* face1 = [F mutableCopy];
					[face1 flip];
					TFace* face2 = [F mutableCopy];
					
					for( TVec3D* V in face2->verts )
					{
						V->x += face2->normal->normal->x * gridSz;
						V->y += face2->normal->normal->y * gridSz;
						V->z += face2->normal->normal->z * gridSz;
					}
					
					[face2 finalizeInternals];
					
					[planes addObject:[[TPlane alloc] initFromTriangleA:[face1->verts objectAtIndex:2] B:[face1->verts objectAtIndex:1] C:[face1->verts objectAtIndex:0]]];
					[planes addObject:[[TPlane alloc] initFromTriangleA:[face2->verts objectAtIndex:2] B:[face2->verts objectAtIndex:1] C:[face2->verts objectAtIndex:0]]];
					
					int x1, x2;
					for( x1 = 0, x2 = ([face2->verts count] - 1) ; x1 < [face1->verts count] ; ++x1, --x2 )
					{
						TVec3D* v0 = [face1->verts objectAtIndex:x1];
						TVec3D* v1 = [face1->verts objectAtIndex:((x1 + 1) % [face1->verts count])];
						TVec3D* v2 = [face2->verts objectAtIndex:((x2 - 1) % [face2->verts count])];
						
						[planes addObject:[[TPlane alloc] initFromTriangleA:v0 B:v1 C:v2]];
					}
					
					for( TPlane* P in planes )
					{
						[P copyTexturingAttribsFrom:F];
					}
										
					TBrush* newBrush = [TBrush createBrushFromPlanes:planes MAP:self];
					
					[newBrush clearPickNames];
					[newBrush finalizeInternals];

					[newSelections addObject:newBrush];
					[E->brushes addObject:newBrush];
					[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_AddBrush Object:newBrush Owner:E]];
				}
			}
		}
	}
	
	[selMgr unselectAll:TSC_Level];
	[selMgr unselectAll:TSC_Face];
	[selMgr unselectAll:TSC_Vertex];
	
	for( TBrush* B in newSelections )
	{
		[selMgr addSelection:B];
	}
	
	[historyMgr stopRecord];
	
	[self redrawLevelViewports];
}

-(void) csgSplit
{
	[historyMgr startRecord:@"CSG Split"];
	
	for( TEntity* E in entities )
	{
		NSMutableArray* tempB = [NSMutableArray arrayWithArray:E->brushes];
		for( TBrush* B in tempB )
		{
			if( [selMgr isSelected:B] )
			{
				BOOL bBreak = NO;
				BOOL bDeleteOriginal = NO;
				
				for( TFace* F in B->faces )
				{
					if( bBreak )
					{
						break;
					}
					
					for( TEdge* G in F->edges )
					{
						if( [G isSelected:self] )
						{
							bDeleteOriginal = YES;
							
							TVec3D* v0 = [F->verts objectAtIndex:G->verts[0]];
							TVec3D* v1 = [F->verts objectAtIndex:G->verts[1]];
							
							TVec3D* vn0 = [B getVertexNormal:v0];
							TVec3D* vn1 = [B getVertexNormal:v1];
							
							TVec3D* edgeV0 = [TVec3D scale:[TVec3D addA:v0 andB:v1] By:0.5f];
							TVec3D* edgeN0 = [[TVec3D scale:[TVec3D addA:vn0 andB:vn1] By:0.5f] normalize];
							TVec3D* edgeVec = [[TVec3D subtractA:v1 andB:v0] normalize];
							TVec3D* edgeN1 = [TVec3D crossA:edgeN0 andB:edgeVec];
							
							TVec3D* edgeV1 = [TVec3D addA:edgeV0 andB:[TVec3D scale:edgeN0 By:16.0f]];
							TVec3D* edgeV2 = [TVec3D addA:edgeV0 andB:[TVec3D scale:edgeN1 By:16.0f]];
							
							TPlane* planeFront = [[TPlane alloc] initFromTriangleA:edgeV0 B:edgeV1 C:edgeV2];
							TPlane* planeBack = [[TPlane alloc] initFromTriangleA:edgeV2 B:edgeV1 C:edgeV0];
							
							[planeFront copyTexturingAttribsFrom:F];
							[planeBack copyTexturingAttribsFrom:F];
							
							TBrush* frontBrush = [B carveBrushAgainstPlane:planeFront MAP:self];
							TBrush* backBrush = [B carveBrushAgainstPlane:planeBack MAP:self];
							
							if( [frontBrush->faces count] > 3 )
							{
								[frontBrush finalizeInternals];
								[E->brushes addObject:frontBrush];
								[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_AddBrush Object:frontBrush Owner:E]];
								[selMgr addSelection:frontBrush];
							}
							if( [backBrush->faces count] > 3 )
							{
								[backBrush finalizeInternals];
								[E->brushes addObject:backBrush];
								[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_AddBrush Object:backBrush Owner:E]];
								[selMgr addSelection:backBrush];
							}
							
							// We only process the first selected edge in each brush.  It's too complicated to keep track of multiple
							// edge selections and splitting multiple times within the same brush.
							
							bBreak = YES;
							break;
						}
					}
				}
				
				if( bDeleteOriginal )
				{
					[self destroyObject:B];
				}
			}
		}
	}
	
	[selMgr unselectAll:TSC_Vertex];
	
	[historyMgr stopRecord];
	
	[self redrawLevelViewports];
}

-(void) csgTriangulateFan
{
	[historyMgr startRecord:@"Triangulate To Fan"];

	for( TEntity* E in entities )
	{
		for( TBrush* B in E->brushes )
		{
			NSMutableArray* tempF = [NSMutableArray	arrayWithArray:B->faces];
			
			for( TFace* F in tempF )
			{
				if( [selMgr isSelected:B] || [selMgr isSelected:F] )
				{
					TVec3D* v0 = [F->verts objectAtIndex:0];
					TVec3D* v1 = [F->verts objectAtIndex:1];
					TVec3D* v2;
					int v;
					
					for( v = 2 ; v < [F->verts count] ; ++v )
					{
						v2 = [F->verts objectAtIndex:v];
						
						TFace* FF = [TFace new];
						
						[FF copyTexturingAttribsFrom:F];
						[FF->verts addObject:v0];
						[FF->verts addObject:v1];
						[FF->verts addObject:v2];
						
						[FF finalizeInternals];
						 
						[B->faces addObject:FF];
						
						v1 = v2;
					}
					
					[B->faces removeObject:F];
				}
			}
		}
	}
	
	[historyMgr stopRecord];
	
	[self redrawLevelViewports];
}
	
-(void) csgTriangulateFromCenter
{
	[historyMgr startRecord:@"Triangulate From Center"];
	
	
	
	[historyMgr stopRecord];
	
	[self redrawLevelViewports];
}

-(void) csgOptimize
{
	[historyMgr startRecord:@"Optimize"];
	
	
	
	[historyMgr stopRecord];
	
	[self redrawLevelViewports];
}

-(void) csgHollowSelected
{
	[historyMgr startRecord:@"CSG Hollow Selected"];
	
	NSMutableArray* selectedBrushes = [NSMutableArray new];
	
	// Get a list of all selected brushes
	
	for( TEntity* E in entities )
	{
		for( TBrush* B in E->brushes )
		{
			if( [selMgr isSelected:B] )
			{
				[selectedBrushes addObject:B];
			}
		}
	}
	
	// Hollow out selected brushes
	
	for( TEntity* E in entities )
	{
		NSMutableArray* tempB = [NSMutableArray arrayWithArray:E->brushes];
		for( TBrush* B in tempB )
		{
			BOOL bRemoveOriginal = NO;
			
			if( [selMgr isSelected:B] )
			{
				bRemoveOriginal = YES;
				
				// Create a smaller version of this brush.  Move each face backwards along it's normal 16 units.
				
				TBrush* smallBrush = [B mutableCopy];
				
				for( TFace* F in smallBrush->faces )
				{
					for( TVec3D* V in F->verts )
					{
						NSMutableArray* connectedFaces = [B getFacesConnectedToVertex:V];
						
						for( TFace* CF in connectedFaces )
						{
							V->x -= (CF->normal->normal->x * gridSz);
							V->y -= (CF->normal->normal->y * gridSz);
							V->z -= (CF->normal->normal->z * gridSz);
						}
					}
				}
				
				[smallBrush finalizeInternals];

				[self subtractBrush:smallBrush FromBrush:B Entity:E];
			}
			
			if( bRemoveOriginal )
			{
				[self destroyObject:B];
			}
		}
	}

	[historyMgr stopRecord];
	
	[self refreshInspectors];
	[self redrawLevelViewports];
}

-(void) csgClipSelectedBrushesAgainstPlane:(TPlane*)InPlane flippedPlane:(TPlane*)InFlippedPlane split:(BOOL)InSplit
{
	[historyMgr startRecord:@"Clip Against Plane"];
	
	NSMutableArray* newSelections = [NSMutableArray new];
	
	NSMutableArray* tempE = [NSMutableArray arrayWithArray:entities];
	for( TEntity* E in tempE )
	{
		NSMutableArray* tempB = [NSMutableArray arrayWithArray:E->brushes];
		for( TBrush* B in tempB )
		{
			BOOL bDeleteOriginal = NO;
			
			if( [selMgr isSelected:B] )
			{
				TBrush* clippedBrush = [B mutableCopy];
				bDeleteOriginal = YES;
				
				clippedBrush = [clippedBrush carveBrushAgainstPlane:InPlane MAP:self];
				
				if( [clippedBrush->faces count] > 3 )
				{
					[newSelections addObject:clippedBrush];
					[clippedBrush finalizeInternals];
					[E->brushes addObject:clippedBrush];
					[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_AddBrush Object:clippedBrush Owner:E]];
				}
				
				if( InSplit )
				{
					clippedBrush = [B mutableCopy];
					clippedBrush = [clippedBrush carveBrushAgainstPlane:InFlippedPlane MAP:self];
					
					if( [clippedBrush->faces count] > 3 )
					{
						[newSelections addObject:clippedBrush];
						[clippedBrush finalizeInternals];
						[E->brushes addObject:clippedBrush];
						[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_AddBrush Object:clippedBrush Owner:E]];
					}
				}
				
				if( bDeleteOriginal )
				{
					[self destroyObject:B];
				}
			}
		}
	}
	
	for( TBrush* B in newSelections )
	{
		[selMgr addSelection:B];
	}
	
	[historyMgr stopRecord];
	
	[self redrawLevelViewports];
}

// Looks through all the selected brushes in the word and finds the
// best brush based entity class among them.  If none can be found,
// the worldspawn will be returned.

-(TEntity*) findBestSelectedBrushBasedEntity
{
	NSMutableArray* selectedClasses = [selMgr getSelectedEntityClasses];
	TEntityClass* ec = nil;
	
	// Look for a brush based entity that is NOT the worldspawn first
	
	for( TEntityClass* EC in selectedClasses )
	{
		if( [EC isPointClass] == NO && [EC->name isEqualToString:@"worldspawn"] == NO )
		{
			ec = EC;
			break;
		}
	}
	
	if( ec != nil )
	{
		// Find the first selected entity of the class we want
		
		NSMutableArray* selectedEntities = [selMgr getSelectedEntities];
		
		for( TEntity* E in selectedEntities )
		{
			if( [E->entityClass->name isEqualToString:ec->name] )
			{
				return E;
			}
		}
	}
	
	// Couldn't find a good brush based entity so just return the worldspawn
	
	return [self findEntityByClassName:@"worldspawn"];
}

-(void) playLevelInQuake
{
	// Extract various names and paths that we need here
	
	NSString* mapFilename = [[self fileURL] absoluteString];
	mapFilename = [mapFilename substringFromIndex:16];		// Remove "file:/localhost" from the start
	NSString* mapName = [[mapFilename lastPathComponent] stringByDeletingPathExtension];
	NSString* quakeDir = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"quakeDirectory"];
	
	// Default the game to "quake.app" and the command line to empty
	
	NSString* appName = @"quake";
	NSString* cmdLine = @"";
	
	// See if the user has specified overrides in the worldspawn k/vs
	
	TEntity* E = [self getEntityByClassName:@"worldspawn"];
	if( E != nil )
	{
		// Game
		
		NSString* value = [E->keyvalues valueForKey:@"_quake"];
		if( value != nil && [value length] > 0 )
		{
			appName = [value mutableCopy];
		}
		
		// Command line
		
		value = [E->keyvalues valueForKey:@"_cmdline"];
		if( value != nil && [value length] > 0 )
		{
			cmdLine = [value mutableCopy];
		}
		
		// Game
		
		value = [E->keyvalues valueForKey:@"_game"];
		if( value != nil && [value length] > 0 )
		{
			// prepend a "-game <xxx>" to the start of the commandline if the user specifies one
			
			cmdLine = [NSString stringWithFormat:@"-game %@ %@", value, cmdLine];
		}
	}
	
	NSString* quakeApp = [NSString stringWithFormat:@"%@/%@.app/Contents/MacOS/%@", quakeDir, appName, appName];
	
	// Build the argument array
	
	NSMutableArray* chunks = [[cmdLine componentsSeparatedByString:@" "] mutableCopy];
	
	NSMutableArray* args = [NSMutableArray new];
	
	for( NSString* S in chunks )
	{
		[args addObject:S];
	}
	
	[args addObject:@"+map"];
	[args addObject:mapName];
	
	// Run the game
	
	[NSTask launchedTaskWithLaunchPath:quakeApp arguments:args];
}

// Looks for a pointfile for the loaded map.  If it finds one, it loads it into an array of vertices

-(void) loadPointFile
{
	// Extract various names and paths that we need here
	
	NSString* mapFilename = [[self fileURL] absoluteString];
	mapFilename = [mapFilename substringFromIndex:16];		// Remove "file:/localhost" from the start
	NSString* pointFilename = [NSString stringWithFormat:@"%@.pts", [mapFilename stringByDeletingPathExtension]];
	
	NSString* lines = [NSString stringWithContentsOfFile:pointFilename];
	NSArray* chunks = [lines componentsSeparatedByString:@"\n"];

	[pointFileRA resetToStart];
	
	for( NSString* S in chunks )
	{
		if( [S length] > 0 )
		{
			NSScanner* scanner = [NSScanner scannerWithString:S];
			
			TVec3D* vtx = [TVec3D new];
			
			[scanner scanFloat:&vtx->x];
			[scanner scanFloat:&vtx->y];
			[scanner scanFloat:&vtx->z];
			
			vtx = [vtx swizzleFromQuake];

			[pointFileRA addElement:3, vtx->x, vtx->y, vtx->z];
		}
	}
	
	[self redrawLevelViewports];
}

-(void) clearPointFile
{
	[pointFileRA resetToStart];
}

-(void) drawPointFile
{
	if( pointFileRA == nil )
	{
		return;
	}
	
	glDisable( GL_TEXTURE_2D );
	
	glColor3f( 0, 0, 0 );
	glDepthMask( FALSE );

	[pointFileRA draw:GL_POINTS];
	
	glDepthMask( TRUE );
	glColor3f( 1, 1, 1 );
	glPointSize( 2.0f );
	
	[pointFileRA draw:GL_POINTS];
	
	glPointSize( POINT_SZ );
	glEnable( GL_TEXTURE_2D );
}

-(void) jumpCamerasTo:(TVec3D*)InLocation
{
	for( TOpenGLView* VW in levelViewports )
	{
		VW->cameraLocation = [InLocation mutableCopy];
		[VW display];
	}
}

// Performs a mass clean up of the level before saving it out to MAP format.  This gets rid of all brushes that have less than 4 faces
// and all brush based entities that have no brushes.

-(void) purgeBadBrushesAndEntities
{
	NSMutableArray* tempE = [NSMutableArray arrayWithArray:entities];
	for( TEntity* E in tempE )
	{
		if( [E isPointEntity] == 0 && [E->brushes count] == 0 )
		{
			[self destroyObject:E];
		}
		else
		{
			NSMutableArray* tempB = [NSMutableArray arrayWithArray:E->brushes];
			for( TBrush* B in tempB )
			{
				if( [B->faces count] < 4 )
				{
					[self destroyObject:B];
				}
			}
		}
	}
}

-(TEntityClass*) findEntityClassByName:(NSString*)InName
{
	return [entityClasses objectForKey:[InName uppercaseString]];
}

// Builds the Entity menu of class names

-(void) populateCreateEntityMenu
{
	NSApplication* app = [NSApplication sharedApplication];
	[[app delegate] populateCreateEntityMenu:self];
}

// Records a new bookmark (or overwrites an existing one if InKey already exists)

-(void) setBookmark:(NSString*)InKey
{
	TBookmark* BM = [[TBookmark alloc] initWithPerspectiveLocation:perspectiveViewport->cameraLocation
									PerspectiveRotation:perspectiveViewport->cameraRotation
										  OrthoLocation:orthoViewport->cameraLocation
											  OrthoZoom:orthoViewport->orthoZoom];

	[bookmarks removeObjectForKey:InKey];
	[bookmarks setObject:BM forKey:InKey];
}

// Moves the viewports to a saved bookmark

-(void) jumpToBookmark:(NSString*)InKey
{
	TBookmark* BM = [bookmarks objectForKey:InKey];
	
	if( BM != nil )
	{
		perspectiveViewport->cameraLocation = [BM->perspectiveLocation mutableCopy];
		perspectiveViewport->cameraRotation = [BM->perspectiveRotation mutableCopy];
		
		orthoViewport->cameraLocation = [BM->orthoLocation mutableCopy];
		orthoViewport->orthoZoom = BM->orthoZoom;
	}
	
	[self redrawLevelViewports];
}

-(void) quantizeVerts
{
	[historyMgr startRecord:@"Quantize"];
	
	BOOL bHasVertexSelections = [selMgr hasSelectionsInCategory:TSC_Vertex];
	TVec3D* snappedVtx;
	
	for( TEntity* E in entities )
	{
		for( TBrush* B in E->brushes )
		{
			for( TFace* F in B->faces )
			{
				for( TVec3D* V in F->verts )
				{
					if( (bHasVertexSelections && [selMgr isSelected:V]) || (!bHasVertexSelections && [selMgr isSelected:B]) )
					{
						snappedVtx = [self snapVtxToGrid:V];
						[historyMgr addAction:[[THistoryAction alloc] initWithType:TUAT_DragVertex Object:V Owner:B Data:[TVec3D subtractA:snappedVtx andB:V]]];
						
						V->x = snappedVtx->x;
						V->y = snappedVtx->y;
						V->z = snappedVtx->z;
					}
				}
			}
		}
	}
	
	[historyMgr stopRecord];
	
	[self redrawLevelViewports];
}

-(void) mirrorSelectedX:(BOOL)InX Y:(BOOL)InY Z:(BOOL)InZ
{
	[historyMgr startRecord:@"Mirror"];
	
	TVec3D* origin = [self getUsableOrigin];
	
	for( TEntity* E in entities )
	{
		if( [selMgr isSelected:E] )
		{
			TVec3D* loc = [TVec3D subtractA:E->location andB:origin];
			
			if( InX )
			{
				loc->z *= -1;
				
				if( [E->entityClass hasArrowComponent] )
				{
					E->rotation->y + 180;
				}
			}
			if( InY )
			{
				loc->x *= -1;
			}
			if( InZ )
			{
				loc->x *= -1;
				
				if( [E->entityClass hasArrowComponent] )
				{
					E->rotation->y + 180;
				}
			}
			
			E->location = [TVec3D addA:loc andB:origin];

			[E matchUpKeyValuesToLiterals];
		}
		else
		{
		}
	}
	
	[historyMgr stopRecord];
	
	[self redrawLevelViewports];
}

-(void) markAllTexturesDirtyRenderArray
{
	for( TTexture* T in texturesFromWADs )
	{
		T->bDirtyRenderArray = YES;
	}
}

-(void) hideSelected
{
	[historyMgr startRecord:@"Hide Selected"];
	
	for( TEntity* E in entities )
	{
		if( [selMgr isSelected:E] )
		{
			[visMgr hide:E];
		}
		
		for( TBrush* B in E->brushes )
		{
			if( [selMgr isSelected:B] )
			{
				[visMgr hide:B];
			}
		}
	}
	
	[self refreshInspectors];
	[self redrawLevelViewports];
	
	[historyMgr stopRecord];
}

-(void) isolateSelected
{
	[historyMgr startRecord:@"Isolate"];
	
	[visMgr showAll];
	
	for( TEntity* E in entities )
	{
		if( [E isPointEntity] == YES )
		{
			if( [selMgr isSelected:E] == NO )
			{
				[visMgr hide:E];
			}
		}
		else
		{
			for( TBrush* B in E->brushes )
			{
				if( [selMgr isSelected:B] == NO )
				{
					[visMgr hide:B];
				}
			}
		}
	}
	
	[self refreshInspectors];
	[self redrawLevelViewports];
	
	[historyMgr stopRecord];
}

-(void) showAll
{
	[historyMgr startRecord:@"Show All"];
	
	[visMgr showAll];
	
	[self redrawLevelViewports];
	[historyMgr stopRecord];
}

@end

