
@implementation TEMDLReader

-(void) loadFile:(NSString*)InFilename MAP:(MAPDocument*)InMAP BMDL:(TEModel*)InEModel
{
	LOG( @"Reading EMDL file from resources : %@", InFilename );
	LOG_IN();
	
	[self openFileFromResources:InFilename];
	
	NSData* data = [fileHandle readDataToEndOfFile];
	NSString* fileContents = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSArray* fileLines = [fileContents componentsSeparatedByString:@"\n"];
	
	NSMutableArray* clipPlanes = nil;

	BOOL bParsingBrush;
	
	for( NSString* line in fileLines )
	{
		line = [line stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \t\r\n"]];
		
		if( [line length] == 0 || [[line substringToIndex:1] isEqualToString:@"/"] )
		{
			// skip blank lines
		}
		else if( [line isEqualToString:@"{"] )
		{
			// Start a new brush
			clipPlanes = [NSMutableArray new];
			
			bParsingBrush = YES;
		}
		else if( [line isEqualToString:@"}"] )
		{
			bParsingBrush = NO;
			
			InEModel->brush = [TBrush createBrushFromPlanes:clipPlanes MAP:InMAP];
		}
		else if( [[line substringToIndex:1] isEqualToString:@"("] )
		{
			// Reading a plane for the current brush

			NSScanner* scanner = [NSScanner scannerWithString:line];
			TVec3D* v1 = [TVec3D new];
			TVec3D* v2 = [TVec3D new];
			TVec3D* v3 = [TVec3D new];
			NSString* texName;
			int uoffset, voffset, rotation;
			float uscale, vscale;

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
			
			TPlane* plane = [[TPlane alloc] initFromTriangleA:v1 B:v2 C:v3];

			plane->textureName = [texName mutableCopy];
			plane->uoffset = uoffset;
			plane->voffset = voffset;
			plane->rotation = rotation;
			plane->uscale = uscale;
			plane->vscale = vscale;

			[clipPlanes addObject:plane];
		}
	}
	
	[self closeFile];
	
	LOG_OUT();
}

@end
