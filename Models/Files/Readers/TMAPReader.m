
@implementation TMAPReader

-(void) loadFile:(NSString*)InFilename MAP:(MAPDocument*)InMAP
{
	[self openTextFile:InFilename];
	
	char cline[LINE_BUFFER_SZ];
	
	// First scan the file and look for any "wad" key/value entries.  This is necessary because textures have to be loaded first
	// so that texture mapping can be done properly.  I wish there was a better way but I don't see it right now.

	while( !feof( fileHandle ) )
	{
		fgets( cline, LINE_BUFFER_SZ, fileHandle );
		
		NSString* line = [NSString stringWithUTF8String:cline];
		line = [line stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \t\r\n"]];
		
		if( [line length] > 0 && [[line substringToIndex:1] isEqualToString:@"\""] )
		{
			// Reading a key/value for the current entity
			
			NSScanner* scanner = [NSScanner scannerWithString:line];
			NSString *key, *value;
			
			[scanner scanString:@"\"" intoString:nil];
			[scanner scanUpToString: @"\"" intoString:&key];
			[scanner scanString:@"\"" intoString:nil];
			[scanner scanString:@"\"" intoString:nil];
			[scanner scanUpToString: @"\"" intoString:&value];
			
			if( [key isEqualToString:@"wad"] )
			{
				[InMAP loadWAD:value];
			}
		}
	}

	NSMutableString* FinalText = [NSMutableString string];
	
	// Move back to the beginning of the file and read the MAP file in.
	//
	// The MAP file is read into one large string called FinalText which is then passed
	// to MAPDocument's ImportEntitiesFromText for actual parsing.
	
	fseek( fileHandle, 0, SEEK_SET );
	
	while( !feof( fileHandle ) )
	{
		fgets( cline, LINE_BUFFER_SZ, fileHandle );
		
		NSString* line = [NSString stringWithUTF8String:cline];
		line = [line stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \t\r\n"]];
		
		if( [line length] == 0 || [[line substringToIndex:1] isEqualToString:@"/"] )
		{
			// skip blank lines and comments
		}
		else
		{
			[FinalText appendFormat:@"%@\n", line];
		}
	}
	
	[InMAP importEntitiesFromText:FinalText SelectAfterImport:NO];
	
	[self closeFile];
}

@end
