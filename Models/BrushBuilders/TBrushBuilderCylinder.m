
@implementation TBrushBuilderCylinder

// Creates a brush and returns it.  It does NOT add it into the worldspawn automatically.

-(TBrush*) build:(MAPDocument*)InMAP Location:(TVec3D*)InLocation Extents:(TVec3D*)InExtents Args:(NSArray*)InArgs
{
	int width = InExtents->x;
	int height = InExtents->y;
	int depth = InExtents->z;
	int numsides = [[InArgs objectAtIndex:0] intValue];
	
	TMatrix* orientationMtx = [TMatrix new];
	
	if( [TGlobal G]->currentLevelView )
	{
		switch( [TGlobal G]->currentLevelView->orientation )
		{
			case TO_Side_YZ:
				
				width = InExtents->y;
				height = InExtents->x;
				depth = InExtents->z;
				
				orientationMtx = [TMatrix rotateZ:90];
				break;
				
			case TO_Front_XY:
				
				width = InExtents->x;
				height = InExtents->z;
				depth = InExtents->y;
				
				orientationMtx = [TMatrix rotateX:90];
				break;
		}
	}
	
	// Create vertex list
	
	TVec3D* vtx = [[TVec3D alloc] initWithX:1.0f Y:0 Z:0];
	TMatrix* mtx = [TMatrix rotateY:(360.0f / numsides)];

	NSMutableArray* verts = [NSMutableArray new];
	
	int x;
	for( x = 0 ; x < numsides ; ++x )
	{
		vtx = [mtx transformVector:vtx];
		[verts addObject:vtx];
	}
	
	TBrush* brush = [TBrush new];
	
	// Create top and bottom

	TFace* face;

	// Top
	
	face = [TFace new];
	face->textureName = [InMAP->selMgr getSelectedTextureName];
	for( TVec3D* V in verts )
	{
		[face->verts addObject:[TVec3D addA:V andB:[[TVec3D alloc] initWithX:0 Y:0.5f Z:0]]];
	}
	[brush->faces addObject:face];
	
	// Bottom
	
	face = [TFace new];
	face->textureName = [InMAP->selMgr getSelectedTextureName];
	for( x = [verts count] - 1 ; x > -1 ; --x )
	{
		[face->verts addObject:[TVec3D addA:[verts objectAtIndex:x] andB:[[TVec3D alloc] initWithX:0 Y:-0.5f Z:0]]];
	}
	[brush->faces addObject:face];
	
	// Sides
	
	for( x = 0 ; x < [verts count] ; ++x )
	{
		face = [TFace new];
		face->textureName = [InMAP->selMgr getSelectedTextureName];
		
		TVec3D* v0 = [verts objectAtIndex:x];
		TVec3D* v1 = [verts objectAtIndex:(x + 1) % [verts count]];
		
		[face->verts addObject:[TVec3D addA:v1 andB:[[TVec3D alloc] initWithX:0 Y:0.5f Z:0]]];
		[face->verts addObject:[TVec3D addA:v0 andB:[[TVec3D alloc] initWithX:0 Y:0.5f Z:0]]];
		[face->verts addObject:[TVec3D addA:v0 andB:[[TVec3D alloc] initWithX:0 Y:-0.5f Z:0]]];
		[face->verts addObject:[TVec3D addA:v1 andB:[[TVec3D alloc] initWithX:0 Y:-0.5f Z:0]]];

		[brush->faces addObject:face];
	}
	
	// Scale the brush and move it into the proper location
	
	for( TFace* F in brush->faces )
	{
		NSMutableArray* tempV = [NSMutableArray arrayWithArray:F->verts];
		F->verts = [NSMutableArray new];
		
		for( TVec3D* V in tempV )
		{
			vtx = [V mutableCopy];
			
			vtx->x *= width / 2;
			vtx->y *= height;
			vtx->z *= depth / 2;
			
			vtx = [orientationMtx transformVector:vtx];
			
			vtx = [TVec3D addA:vtx andB:InLocation];
			
			[F->verts addObject:vtx];
		}
	}

	// Finish up
	
	[brush finalizeInternals];
	
	[InMAP markAllTexturesDirtyRenderArray];
	
	return brush;
}

@end
