
@implementation TTriangle

-(id) init
{
	[super init];
	
	ownerFace = nil;
	connectedFaces[0] = connectedFaces[1] = connectedFaces[2] = nil;
	
	return self;
}

@end

@implementation TPolyMesh

-(id) init
{
	[super init];
	
	return self;
}

// Returns a string that represents this entity in Quake MAP text format.  This is the
// same text that would be read or written to a MAP file.

-(NSMutableString*) exportToText
{
	TVec3D *v0, *v1, *v2;
	NSMutableString* string = [NSMutableString string];
	
	// Export the triangle mesh in a more or less normal MAP format except that we use square brackets instead of curly.  This
	// allows QBSP to ignore them without too much hassle.
	
	[string appendString:@"\t[\n"];
	
	[string appendString:@"\t// TAGS\n"];
	 
	for( TFace* F in faces )
	{
		BOOL bFirstVert = YES;
		
		for( TVec3D* V in F->verts )
		{
			if( bFirstVert )
			{
				[string appendFormat:@"\t\t%d ", [F->verts count]];
				bFirstVert = NO;
			}
			
			v0 = [V swizzleToQuake];
			[string appendFormat:@"( %d %d %d ) ", (int)roundf(v0->x), (int)roundf(v0->y), (int)roundf(v0->z)];
			[v0 swizzleFromQuake];
		}
	 
		[string appendFormat:@"%@ %d %d %d %f %f\n", F->textureName, (int)F->uoffset, (int)F->voffset, (int)F->rotation, F->uscale, F->vscale];
	}
	 
	[string appendString:@"\t]\n"];

	for( TFace* F in faces )
	{
		[string appendString:@"\t{\n"];
		[string appendString:@"\t// TAGS TB:1\n"];

		// Normal face
		
		v0 = [[F->verts objectAtIndex:0] swizzleToQuake];
		v1 = [[F->verts objectAtIndex:1] swizzleToQuake];
		v2 = [[F->verts objectAtIndex:2] swizzleToQuake];
		
		[string appendFormat:@"\t\t( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %@ %d %d %d %f %f\n",
		 (int)(v2->x), (int)(v2->y), (int)(v2->z),
		 (int)(v1->x), (int)(v1->y), (int)(v1->z),
		 (int)(v0->x), (int)(v0->y), (int)(v0->z),
		 F->textureName,
		 (int)F->uoffset, (int)F->voffset, (int)F->rotation, F->uscale, F->vscale];
		
		[v0 swizzleFromQuake];
		[v1 swizzleFromQuake];
		[v2 swizzleFromQuake];
		
		// Determine the middle of the face
		
		TVec3D* midV = [F getCenter];
		
		// Move the midpoint backwards along the normal
		
		midV = [TVec3D addA:midV andB:[TVec3D scale:F->normal->normal By:-4.0f]];

		// Side faces
		
		NSString* texName = [F->textureName mutableCopy];
		
		if( [[texName substringToIndex:1] isEqualToString:@"*"] == NO && [[[texName substringToIndex:3] lowercaseString] isEqualToString:@"sky"] == NO )
		{
			texName = @"SKIP";
		}
		
		int v;
		for( v = 0 ; v < [F->verts count] ; ++v )
		{
			v0 = [F->verts objectAtIndex:v];
			v1 = [F->verts objectAtIndex:(v+1)%[F->verts count]];
			v2 = [midV mutableCopy];
		
			v0 = [v0 swizzleToQuake];
			v1 = [v1 swizzleToQuake];
			v2 = [v2 swizzleToQuake];
			
			[string appendFormat:@"\t\t( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %@ 0 0 0 1.0 1.0\n",
			 (int)(v2->x), (int)(v2->y), (int)(v2->z),
			 (int)(v0->x), (int)(v0->y), (int)(v0->z),
			 (int)(v1->x), (int)(v1->y), (int)(v1->z),
			 texName];
			
			[v0 swizzleFromQuake];
			[v1 swizzleFromQuake];
			[v2 swizzleFromQuake];
		}
		
		[string appendString:@"\t}\n"];
	}
	
	return string;
}

@end
