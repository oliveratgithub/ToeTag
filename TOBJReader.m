
@implementation TOBJReader

-(void) loadFile:(NSString*)InFilename MAP:(MAPDocument*)InMAP TriangleMesh:(TPolyMesh*)InTriangleMesh
{
	LOG( @"Reading OBJ file : %@", InFilename );
	LOG_IN();
	
	[self openFile:InFilename];
	
	NSData* data = [fileHandle readDataToEndOfFile];
	NSString* fileContents = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSArray* fileLines = [fileContents componentsSeparatedByString:@"\n"];
	
	NSMutableArray* verts;
	
	for( NSString* line in fileLines )
	{
		line = [line stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \t\r\n"]];
		
		if( [line length] == 0 || [[line substringToIndex:1] isEqualToString:@"/"] )
		{
			// skip blank lines
		}
		else if( [[line substringToIndex:2] isEqualToString:@"g "] )
		{
			verts = [NSMutableArray new];
		}
		else if( [[line substringToIndex:2] isEqualToString:@"v "] )
		{
			NSScanner* scanner = [NSScanner scannerWithString:line];
			TVec3D* vtx = [TVec3D new];
			
			[scanner scanString:@"v " intoString:nil];
			[scanner scanFloat:&vtx->x];
			[scanner scanFloat:&vtx->y];
			[scanner scanFloat:&vtx->z];
			
			[verts addObject:vtx];
		}
		else if( [[line substringToIndex:2] isEqualToString:@"f "] )
		{
			NSArray* chunks = [line componentsSeparatedByString:@" "];
			int x, count = [chunks count] - 1;
			TFace* face = [TFace new];
			TVec3D* vtx;
			
			for( x = 1 ; x <= count ; ++x )
			{
				NSArray* subchunks = [[chunks objectAtIndex:x] componentsSeparatedByString:@"/"];

				vtx = [[verts objectAtIndex:([[subchunks objectAtIndex:0] intValue] - 1)] mutableCopy];
				
				[face->verts addObject:vtx];
			}
			
			face->textureName = @"TOETAGDEFAULT";
			[face finalizeInternals];
			
			[InTriangleMesh->faces addObject:face];
		}
	}
	
	[self closeFile];
	
	[InTriangleMesh finalize];
	
	LOG_OUT();
}

@end
