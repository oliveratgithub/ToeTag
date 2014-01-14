
@implementation TLOGWriter

static TLOGWriter* GLog = nil;
static int GLogIndent = 0;

-(id) initWithFilename:(NSString*)InFilename
{
	[super init];
	
	[self openFile:InFilename];
	
	return self;
}

@end

// ------------------------------------------------------

void LOG_IN()
{
	GLogIndent++;
}

void LOG_OUT()
{
	GLogIndent--;
}

void LOG( NSString *format, ... )
{
	if( GLog == nil )
	{
		NSString* quakeDir = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"quakeDirectory"];
		GLog = [[TLOGWriter alloc] initWithFilename:[NSString stringWithFormat:@"%@/toetag.log", quakeDir ]];
	}
	
	va_list argList;
	va_start( argList, format );
	
	NSString* fmt = [NSString stringWithFormat:@"%@\n", format];
	
	int x;
	for( x = 0 ; x < GLogIndent ; ++x )
	{
		fmt = [@"  " stringByAppendingString:fmt];
	}
	
	NSString* string = [[NSString alloc] initWithFormat:fmt arguments:argList];
	
	va_end( argList );
	
	[GLog->fileHandle writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
	[GLog->fileHandle synchronizeFile];
	
	NSLog( @"LOG : %@", string );
}

void WARN( NSString *format, ... )
{
	if( GLog == nil )
	{
		NSString* quakeDir = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"quakeDirectory"];
		GLog = [[TLOGWriter alloc] initWithFilename:[NSString stringWithFormat:@"%@/toetag.log", quakeDir ]];
	}
	
	va_list argList;
	va_start( argList, format );
	
	NSString* fmt = [NSString stringWithFormat:@"WARNING : %@\n", format];
	
	int x;
	for( x = 0 ; x < GLogIndent ; ++x )
	{
		fmt = [@"  " stringByAppendingString:fmt];
	}
	
	NSString* string = [[NSString alloc] initWithFormat:fmt arguments:argList];
	
	va_end( argList );
	
	[GLog->fileHandle writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
	[GLog->fileHandle synchronizeFile];

	NSLog( @"WARN : %@", string );
}

void ERROR( NSString *format, ... )
{
	if( GLog == nil )
	{
		NSString* quakeDir = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"quakeDirectory"];
		GLog = [[TLOGWriter alloc] initWithFilename:[NSString stringWithFormat:@"%@/toetag.log", quakeDir ]];
	}
	
	va_list argList;
	va_start( argList, format );
	
	NSString* fmt = [NSString stringWithFormat:@"!! ERROR : %@\n", format];
	
	int x;
	for( x = 0 ; x < GLogIndent ; ++x )
	{
		fmt = [@"  " stringByAppendingString:fmt];
	}
	
	NSString* string = [[NSString alloc] initWithFormat:fmt arguments:argList];
	
	va_end( argList );
	
	[GLog->fileHandle writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
	[GLog->fileHandle synchronizeFile];

	NSLog( @"ERROR : %@", string );
}
