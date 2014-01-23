
@implementation TEntity

-(id) init
{
	[super init];
	
	keyvalues = [NSMutableDictionary new];
	brushes = [NSMutableArray new];
	
	location = [TVec3D new];
	rotation = [TVec3D new];
	spawnFlags = 0;
	pickName = nil;
	quickGroupID = -1;
	
	return self;
}

-(NSMutableArray*) _visibleBrushes:(MAPDocument*)InMAP
{
	NSMutableArray* visibleBrushes = [NSMutableArray new];
	
	for( TBrush* B in brushes )
	{
		if( [InMAP->visMgr isVisible:B] )
		{
			[visibleBrushes addObject:B];
		}
	}
	
	return visibleBrushes;
}

-(NSMutableArray*) _brushes
{
	NSMutableArray* brushlist = [NSMutableArray new];
	
	for( TBrush* B in brushes )
	{
		if( [B isKindOfClass:[TPolyMesh class]] == NO )
		{
			[brushlist addObject:B];
		}
	}
	
	return brushlist;
}

-(NSMutableArray*) _trianglemeshes
{
	NSMutableArray* meshlist = [NSMutableArray new];
	
	for( TBrush* B in brushes )
	{
		if( [B isKindOfClass:[TPolyMesh class]] == YES )
		{
			[meshlist addObject:B];
		}
	}
	
	return meshlist;
}

-(void) pushPickName
{
	if( pickName == nil )
	{
		pickName = [NSNumber numberWithUnsignedInt:[[TGlobal G] generatePickName]];
	}
	
	glPushName( [pickName unsignedIntValue] );
}

-(NSNumber*) getPickName
{
	if( pickName == nil )
	{
		pickName = [NSNumber numberWithUnsignedInt:[[TGlobal G] generatePickName]];
	}

	return pickName;
}

-(int) getQuickGroupID
{
	return quickGroupID;
}

-(ESelectCategory) getSelectCategory
{
	return TSC_Level;
}

-(void) selmgrWasUnselected
{
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	TEntity* newentity = [TEntity new];
	
	newentity->keyvalues = [keyvalues mutableCopy];
	newentity->brushes = [brushes mutableCopy];
	newentity->entityClass = entityClass;
	newentity->location = [location mutableCopy];
	newentity->rotation = [rotation mutableCopy];
	newentity->spawnFlags = spawnFlags;
	newentity->pickName = [pickName copy];
	
	return newentity;
}

-(void) drawForPick:(MAPDocument*)InMAP Category:(ESelectCategory)InCategory
{
	switch( InCategory )
	{
		case TSC_Level:
		{
			if( [self isPointEntity] )
			{
				glTranslatef( location->x, location->y, location->z );
				glRotatef( rotation->y, 0, 1, 0 );
				
				[self pushPickName];
				
				// Let the entity class handle the drawing of point entities
				[entityClass drawForPick:self MAP:InMAP Category:InCategory];
				
				glPopName();
			}
			else
			{
				for( TBrush* B in [self _visibleBrushes:InMAP] )
				{
					for( TFace* F in B->faces )
					{
						if( !InMAP->bShowEditorOnlyEntities && [[F->textureName lowercaseString] isEqualToString:@"clip"] )
						{
							continue;
						}
						
						[B pushPickName];
						
						glBegin( GL_TRIANGLE_FAN );
						{
							for( TVec3D* V in F->verts )
							{
								glVertex3fv( &V->x );
							}
						}
						glEnd();
						
						glPopName();
					}
				}
			}
		}
		break;
			
		case TSC_Face:
		{
			for( TBrush* B in [self _visibleBrushes:InMAP] )
			{
				// Faces
				
				for( TFace* F in B->faces )
				{
					if( !InMAP->bShowEditorOnlyEntities && [[F->textureName lowercaseString] isEqualToString:@"clip"] )
					{
						continue;
					}
					
					[F pushPickName];
					
					glBegin( GL_TRIANGLE_FAN );
					{
						for( TVec3D* V in F->verts )
						{
							glVertex3fv( &V->x );
						}
					}
					glEnd();
					
					glPopName();
				}
			}
		}
		break;
			
		case TSC_Edge:
		{
			for( TBrush* B in [self _visibleBrushes:InMAP] )
			{
				if( [InMAP->selMgr isSelected:B] )
				{
					[B drawEdgesForPick];
				}
			}
		}
		break;

		case TSC_Vertex:
		{
			for( TBrush* B in [self _visibleBrushes:InMAP] )
			{
				if( [InMAP->selMgr isSelected:B] )
				{
					[B drawVertsForPick];
				}
			}
		}
			break;
	}
}

-(void) drawWireForPick:(MAPDocument*)InMAP Category:(ESelectCategory)InCategory
{
	glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
	
	switch( InCategory )
	{
		case TSC_Level:
		{
			if( [self isPointEntity] )
			{
				glTranslatef( location->x, location->y, location->z );
				glRotatef( rotation->y, 0, 1, 0 );
				
				[self pushPickName];
				[entityClass drawForPick:self MAP:InMAP Category:InCategory];
				glPopName();
			}
			else
			{
				for( TBrush* B in [self _visibleBrushes:InMAP] )
				{
					[B pushPickName];
					
					for( TFace* F in B->faces )
					{
						glBegin( GL_LINE_LOOP );
						{
							for( TVec3D* V in F->verts )
							{
								glVertex3fv( &V->x );
							}
						}
						glEnd();
					}
					
					glPopName();
				}
			}
		}
		break;
			
		case TSC_Face:
		{
			for( TBrush* B in [self _visibleBrushes:InMAP] )
			{
				for( TFace* F in B->faces )
				{
					[F pushPickName];
					
					glBegin( GL_TRIANGLE_FAN );
					{
						for( TVec3D* V in F->verts )
						{
							glVertex3fv( &V->x );
						}
					}
					glEnd();
					
					glPopName();
				}
			}
		}
		break;

		case TSC_Edge:
		{
			for( TBrush* B in [self _visibleBrushes:InMAP] )
			{
				if( [InMAP->selMgr isSelected:B] )
				{
					[B drawEdgesForPick];
				}
			}
		}
		break;

			
		case TSC_Vertex:
		{
			for( TBrush* B in [self _visibleBrushes:InMAP] )
			{
				if( [InMAP->selMgr isSelected:B] )
				{
					[B drawVertsForPick];
				}
			}
		}
		break;
	}

	glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
}

// Should be called to finalize internal structures

-(void) finalizeInternals:(MAPDocument*)InMAP
{
	NSString* className = [keyvalues objectForKey:@"classname"];
	
	// Find the class info for this entity.
	
	entityClass = [InMAP findEntityClassByName:className];
	
	// The entity class couldn't be found, so go with something defaulted so that the editor won't crash.
	
	if( entityClass == nil )
	{
		entityClass = [TEntityClass new];
		entityClass->name = [className mutableCopy];
		entityClass->szMin = [[TVec3D alloc] initWithX:8 Y:8 Z:8];
		entityClass->szMax = [[TVec3D alloc] initWithX:-8 Y:-8 Z:-8];
		entityClass->color = [[TVec3D alloc] initWithX:0.75 Y:0.75 Z:0.75];
		
		[entityClass finalizeInternals];
	}
	
	// Reset the key/value for the classname to ensure that the case is correct.  This matters to Quake.
	
	[keyvalues setObject:[entityClass->name mutableCopy] forKey:@"classname"];
}	

-(void) setKey:(NSString*)InKey Value:(NSString*)InValue
{
	[keyvalues removeObjectForKey:InKey];
	[keyvalues setValue:InValue forKey:InKey];
}

-(NSString*) valueForKey:(NSString*)InKey defaultValue:(NSString*)InDefaultValue
{
	id value = [keyvalues valueForKey:InKey];
	
	if( value == nil )
	{
		return InDefaultValue;
	}
	
	return value;
}

-(TVec3D*) valueVectorForKey:(NSString*)InKey defaultValue:(NSString*)InDefaultValue
{
	id value = [keyvalues valueForKey:InKey];
	
	if( value == nil )
	{
		value = InDefaultValue;
	}
	
	NSScanner* scanner = [NSScanner scannerWithString:(NSString*)value];
	TVec3D* vector = [TVec3D new];
	
	[scanner scanFloat:&vector->x];
	[scanner scanFloat:&vector->y];
	[scanner scanFloat:&vector->z];
	
	return vector;
}

-(BOOL) isPointEntity
{
	return [entityClass isPointClass];
}

// Returns a string that represents this entity in Quake MAP text format.  This is the
// same text that would be read or written to a MAP file.

-(NSMutableString*) exportToText:(BOOL)InIncludeBrushes
{
	NSMutableString* string = [NSMutableString string];
	
	[string appendString:@"{\n"];
	
	[string appendString:@"// TAGS"];
	if( quickGroupID > -1 )
	{
		[string appendString:[NSString stringWithFormat:@" QG:%d", quickGroupID]];
	}
	[string appendString:@"\n"];
	
	[string appendString:[self exportKeyValuesToText]];

	// Point entities need to have certain key/values handled as special cases (i.e. swizzled), so do that now.
	
	if( InIncludeBrushes == YES )
	{
		for( TBrush* B in self._brushes )
		{
			[string appendString:[B exportToText]];
		}

		for( TPolyMesh* TM in self._trianglemeshes )
		{
			[string appendString:[TM exportToText]];
		}
	}
	
	[string appendString:@"}\n"];
	
	return string;
}

-(NSMutableString*) exportKeyValuesToText
{
	NSMutableString* string = [NSMutableString string];
	NSEnumerator *enumerator = [keyvalues keyEnumerator];
	id obj;
	
	while( obj = [enumerator nextObject] )
	{
		NSString *key, *value;
		
		key = obj;
		
		// Some keys require special handling and should be ignored here
		if( [key isEqualToString:@"spawnflags"]
			|| [key isEqualToString:@"origin"] )
		{
			continue;
		}
		else
		{
			value = [keyvalues valueForKey:key];
			[string appendFormat:@"\t\"%@\" \"%@\"\n", key, value];
		}
	}
	
	if( [self isPointEntity] )
	{
		// origin
		
		TVec3D* qlocation = [location swizzleToQuake];
		[string appendFormat:@"\t\"origin\" \"%d %d %d\"\n", (int)roundf(qlocation->x), (int)roundf(qlocation->y), (int)roundf(qlocation->z)];
		[location swizzleFromQuake];
	}
	
	// "spawnflags"
	
	[string appendFormat:@"\t\"spawnflags\" \"%d\"\n", spawnFlags];
	
	return string;
}

// Makes sure that special case key values match up with the current value of literals
	
-(void) matchUpKeyValuesToLiterals
{
	[self setKey:@"angle" Value:[NSString stringWithFormat:@"%d", (int)rotation->y]];
}

// Returns the center of this entity, in world space

-(TVec3D*) getCenter
{
	TBBox* bb = [self getBoundingBox];
	TVec3D* center = [bb getCenter];
	
	return center;
}

// Returns the extents of the this entities bounding box, in world space

-(TVec3D*) getExtents
{
	return [[self getBoundingBox] getExtents];
}

// Returns this entities bounding box, in world space

-(TBBox*) getBoundingBox
{
	TBBox* bbox = [TBBox new];
	
	if( [self isPointEntity] )
	{
		[bbox addVertex:[TVec3D addA:location andB:entityClass->szMin]];
		[bbox addVertex:[TVec3D addA:location andB:entityClass->szMax]];
	}
	else
	{
		for( TBrush* B in brushes )
		{
			TBBox* bb = [B getBoundingBox];
			
			[bbox addVertex:bb->min];
			[bbox addVertex:bb->max];
		}
	}
	
	return bbox;
}

-(void) drawSelectionHighlights:(MAPDocument*)InMAP
{
	// If this entity is targetting another, draw a box around the targetted entity a line from us to them
	
	NSString* targetname = [keyvalues valueForKey:@"target"];
	
	if( [targetname length] > 0 )
	{
		NSMutableArray* victims = [NSMutableArray new];
		
		for( TEntity* E in InMAP->entities )
		{
			if( [[E->keyvalues valueForKey:@"targetname"] isEqualToString:targetname] )
			{
				[victims addObject:E];
			}
		}
		
		glDisable( GL_TEXTURE_2D );
		
		for( TEntity* E in victims )
		{
			glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
			
			TVec3D* victimLoc = [E getCenter];
			
			TVec3D* Loc = [self getCenter];
			
			TBBox* bb = [E getBoundingBox];
			[bb expandBy:4.0f];
			
			// Draw the normal box/line
			glColor3f( 1.0f, 0.5f, 0.0f );
			[self drawTargetLineBoxFrom:Loc To:victimLoc Box:bb];
			
			// Draw the behind box/line
			glDepthFunc( GL_GREATER );
			glColor3f( 0.5f, 0.25f, 0.0f );
			[self drawTargetLineBoxFrom:Loc To:victimLoc Box:bb];
			glDepthFunc( GL_LEQUAL );
			
			// Draw the filled box
			glColor4f( 1.0f, 0.5f, 0.0f, .10f );
			glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
			[TRenderUtilBox drawBoxBBox:bb];
		}
		
		glEnable( GL_TEXTURE_2D );
		glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
	}
}

-(void) drawTargetLineBoxFrom:(TVec3D*)InFrom To:(TVec3D*)InTo Box:(TBBox*)InBox
{
	glBegin( GL_LINES );
	{
		glVertex3fv( &InFrom->x );
		glVertex3fv( &InTo->x );
	}
	glEnd();
	
	[TRenderUtilBox drawBoxBBox:InBox];
}

// Sort entities by class name

- (NSComparisonResult)compareByClassName:(TEntity*)InEntity
{
	// Force the worldspawn to the top of the array
	
	if( [InEntity->entityClass->name isEqualToString:@"worldspawn"] )
	{
		return NSOrderedDescending;
	}
	else if( [entityClass->name isEqualToString:@"worldspawn"] )
	{
		return NSOrderedAscending;
	}
	
	// Force all transparent entity classes to the end of the array (so the transparency will draw correctly)
	
	if( [InEntity->entityClass getSuggestedAlpha] < 1.0 )
	{
		return NSOrderedAscending;
	}
	else if( [entityClass getSuggestedAlpha] < 1.0 )
	{
		return NSOrderedDescending;
	}
	
	// Sort all other entities normally
	
	return [entityClass->name caseInsensitiveCompare:InEntity->entityClass->name];
}

-(void) markDirtyRenderArray
{
	for( TBrush* B in brushes )
	{
		[B markDirtyRenderArray];
	}
}

@end
