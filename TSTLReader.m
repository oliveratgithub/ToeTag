
@implementation TSTLReader

-(void) loadFile:(NSString*)InFilename MAP:(MAPDocument*)InMAP TriangleMesh:(TPolyMesh*)InTriangleMesh
{
	LOG( @"Reading STL file : %@", InFilename );
	LOG_IN();
	
	[self openFile:InFilename];
	
	NSData* data = [fileHandle readDataToEndOfFile];
	NSString* fileContents = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSArray* fileLines = [fileContents componentsSeparatedByString:@"\n"];
	
	TFace* face = nil;
	
	for( NSString* line in fileLines )
	{
		line = [line stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \t\r\n"]];
		
		if( [line length] == 0 || [[line substringToIndex:1] isEqualToString:@"/"] )
		{
			// skip blank lines
		}
		else if( [line isEqualToString:@"outer loop"] )
		{
			// Start a new triangle
			face = [TFace new];
		}
		else if( [[line substringToIndex:6] isEqualToString:@"vertex"] )
		{
			NSScanner* scanner = [NSScanner scannerWithString:line];
			TVec3D* vtx = [TVec3D new];

			[scanner scanString:@"vertex " intoString:nil];
			[scanner scanFloat:&vtx->x];
			[scanner scanFloat:&vtx->y];
			[scanner scanFloat:&vtx->z];
			
			[face->verts addObject:vtx];
		}
		else if( [line isEqualToString:@"endloop"] )
		{
			face->textureName = @"TOETAGDEFAULT";
			[face finalizeInternals];
			
			[InTriangleMesh->faces addObject:face];
			
			face = nil;
		}
	}
	
	[self closeFile];
	
	[InTriangleMesh finalize];
	
	LOG_OUT();
}

@end
