
@implementation TDEFReader

-(void) loadFile:(NSString*)InFilename MAP:(MAPDocument*)InMAP
{
	[self openFile:InFilename];
	[self loadFromFileHandle:InMAP];
}	
	
-(void) loadFileFromResources:(NSString*)InFilename MAP:(MAPDocument*)InMAP
{
	[self openFileFromResources:InFilename];
	[self loadFromFileHandle:InMAP];
}
	
-(void) loadFromFileHandle:(MAPDocument*)InMAP
{
	NSData* data = [fileHandle readDataToEndOfFile];
	NSString* fileContents = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSArray* fileLines = [fileContents componentsSeparatedByString:@"\n"];
	
	TEntityClass* entityClass = nil;

	for( NSString* line in fileLines )
	{
		line = [line stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \t\r\n"]];
		
		if( [line length] == 0 )
		{
			// skip blank lines
		}
		else if( [line length] > 1 && [[line substringToIndex:2] isEqualToString:@"//"] )
		{
			// skip comments
		}
		else if( [line length] >= 8 && [[line substringToIndex:8] isEqualToString:@"/*QUAKED"] )
		{
			entityClass = [TEntityClass new];
			
			NSScanner* scanner = [NSScanner scannerWithString:line];
			
			[scanner scanString:@"/*QUAKED " intoString:nil];
			[scanner scanUpToString: @" " intoString:&entityClass->name];
			[scanner scanString:@"(" intoString:nil];
			[scanner scanFloat:&entityClass->color->x];
			[scanner scanFloat:&entityClass->color->y];
			[scanner scanFloat:&entityClass->color->z];

			if( [line rangeOfString:@"?"].location == NSNotFound )
			{
				// Point entity
				
				[scanner scanString:@") (" intoString:nil];
				[scanner scanFloat:&entityClass->szMin->x];
				[scanner scanFloat:&entityClass->szMin->y];
				[scanner scanFloat:&entityClass->szMin->z];
				[scanner scanString:@") (" intoString:nil];
				[scanner scanFloat:&entityClass->szMax->x];
				[scanner scanFloat:&entityClass->szMax->y];
				[scanner scanFloat:&entityClass->szMax->z];
				
				entityClass->szMin = [entityClass->szMin swizzleFromQuake];
				entityClass->szMax = [entityClass->szMax swizzleFromQuake];
				
				[scanner scanString:@")" intoString:nil];
			}
			else
			{
				// Brush entity
				
				[scanner scanString:@") ?" intoString:nil];
			}

			// Spawn flags
			
			NSString* spawnFlags = @"";
			[scanner scanUpToString:@"\n" intoString:&spawnFlags];
			
			if( [spawnFlags length] > 0 )
			{
				NSArray* chunks = [spawnFlags componentsSeparatedByString: @" "];

				int bit = 1;
				for( NSString* S in chunks )
				{
					NSMutableString* MS = [S mutableCopy];
					[MS replaceOccurrencesOfString:@"_" withString:@" " options:NSLiteralSearch range:NSMakeRange( 0, [S length] ) ];
					
					[entityClass->spawnFlags setObject:MS forKey:[NSNumber numberWithInt:bit]];
					bit *= 2;
				}
			}

			[entityClass->spawnFlags setObject:@"Not In Easy Skill" forKey:[NSNumber numberWithInt:SF_NotInEasy]];
			[entityClass->spawnFlags setObject:@"Not In Normal Skill" forKey:[NSNumber numberWithInt:SF_NotInNormal]];
			[entityClass->spawnFlags setObject:@"Not In Hard/Nightmare Skill" forKey:[NSNumber numberWithInt:SF_NotInHardNightmare]];
			[entityClass->spawnFlags setObject:@"Not In Deathmatch" forKey:[NSNumber numberWithInt:SF_NotInDeathmatch]];
		}
		else if( [line length] >= 2 && [[line substringToIndex:2] isEqualToString:@"*/"] )
		{
			[entityClass finalizeInternals];
			
			[InMAP->entityClasses removeObjectForKey:[entityClass->name uppercaseString]];
			[InMAP->entityClasses setObject:entityClass forKey:[entityClass->name uppercaseString]];
			entityClass = nil;
		}
		else
		{
			if( entityClass != nil )
			{
				[entityClass->descText addObject:line];
			}
		}
	}

	[self closeFile];
}

@end
