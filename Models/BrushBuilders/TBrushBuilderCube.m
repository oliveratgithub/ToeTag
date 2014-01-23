
@implementation TBrushBuilderCube

// Creates a brush and returns it.  It does NOT add it into the worldspawn automatically.

-(TBrush*) build:(MAPDocument*)InMAP Location:(TVec3D*)InLocation Extents:(TVec3D*)InExtents Args:(NSArray*)InArgs
{
	int width = InExtents->x;
	int height = InExtents->y;
	int depth = InExtents->z;
	
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
	
	TBrush* brush = [TBrush new];
	TVec3D *min = [[TVec3D alloc] initWithX:-0.5f Y:-0.5f Z:-0.5f], *max = [[TVec3D alloc] initWithX:0.5f Y:0.5f Z:0.5f];
	TFace* face;

	face = [TFace new];
	face->textureName = [InMAP->selMgr getSelectedTextureName];
	[face->verts addObject:[[TVec3D alloc] initWithX:min->x Y:min->y Z:min->z]];
	[face->verts addObject:[[TVec3D alloc] initWithX:min->x Y:max->y Z:min->z]];
	[face->verts addObject:[[TVec3D alloc] initWithX:max->x Y:max->y Z:min->z]];
	[face->verts addObject:[[TVec3D alloc] initWithX:max->x Y:min->y Z:min->z]];
	[brush->faces addObject:face];
	
	face = [TFace new];
	face->textureName = [InMAP->selMgr getSelectedTextureName];
	[face->verts addObject:[[TVec3D alloc] initWithX:min->x Y:max->y Z:max->z]];
	[face->verts addObject:[[TVec3D alloc] initWithX:min->x Y:min->y Z:max->z]];
	[face->verts addObject:[[TVec3D alloc] initWithX:max->x Y:min->y Z:max->z]];
	[face->verts addObject:[[TVec3D alloc] initWithX:max->x Y:max->y Z:max->z]];
	[brush->faces addObject:face];
	
	face = [TFace new];
	face->textureName = [InMAP->selMgr getSelectedTextureName];
	[face->verts addObject:[[TVec3D alloc] initWithX:min->x Y:max->y Z:min->z]];
	[face->verts addObject:[[TVec3D alloc] initWithX:min->x Y:min->y Z:min->z]];
	[face->verts addObject:[[TVec3D alloc] initWithX:min->x Y:min->y Z:max->z]];
	[face->verts addObject:[[TVec3D alloc] initWithX:min->x Y:max->y Z:max->z]];
	[brush->faces addObject:face];
	
	face = [TFace new];
	face->textureName = [InMAP->selMgr getSelectedTextureName];
	[face->verts addObject:[[TVec3D alloc] initWithX:max->x Y:min->y Z:min->z]];
	[face->verts addObject:[[TVec3D alloc] initWithX:max->x Y:max->y Z:min->z]];
	[face->verts addObject:[[TVec3D alloc] initWithX:max->x Y:max->y Z:max->z]];
	[face->verts addObject:[[TVec3D alloc] initWithX:max->x Y:min->y Z:max->z]];
	[brush->faces addObject:face];
	
	face = [TFace new];
	face->textureName = [InMAP->selMgr getSelectedTextureName];
	[face->verts addObject:[[TVec3D alloc] initWithX:min->x Y:min->y Z:max->z]];
	[face->verts addObject:[[TVec3D alloc] initWithX:min->x Y:min->y Z:min->z]];
	[face->verts addObject:[[TVec3D alloc] initWithX:max->x Y:min->y Z:min->z]];
	[face->verts addObject:[[TVec3D alloc] initWithX:max->x Y:min->y Z:max->z]];
	[brush->faces addObject:face];
	
	face = [TFace new];
	face->textureName = [InMAP->selMgr getSelectedTextureName];
	[face->verts addObject:[[TVec3D alloc] initWithX:min->x Y:max->y Z:min->z]];
	[face->verts addObject:[[TVec3D alloc] initWithX:min->x Y:max->y Z:max->z]];
	[face->verts addObject:[[TVec3D alloc] initWithX:max->x Y:max->y Z:max->z]];
	[face->verts addObject:[[TVec3D alloc] initWithX:max->x Y:max->y Z:min->z]];
	[brush->faces addObject:face];
	
	// Scale the brush and move it into the proper location
	
	for( TFace* F in brush->faces )
	{
		NSMutableArray* tempV = [NSMutableArray arrayWithArray:F->verts];
		F->verts = [NSMutableArray new];
		
		for( TVec3D* V in tempV )
		{
			TVec3D* vtx = [V mutableCopy];
			
			vtx->x *= width;
			vtx->y *= height;
			vtx->z *= depth;
			
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
