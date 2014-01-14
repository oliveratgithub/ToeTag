
int getProcessorCount()
{
	int count;
	size_t size = sizeof( count );
	
	if( sysctlbyname("hw.ncpu",&count,&size,NULL,0) )
	{
		return 1;
	}
	
	return count;
}

int main( int argc, char *argv[] )
{
	CFBundleRef bundle = CFBundleGetMainBundle();
	
	CFStringRef version = CFBundleGetValueForInfoDictionaryKey( bundle, kCFBundleVersionKey );
	NSString* quakeDir = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"quakeDirectory"];

	LOG( @"Welcome to ToeTag" );
	LOG( @"Version: %@", version );
	LOG( @"Started at: %@", [[NSDate date] description] );
	LOG( @"Quake directory: %@", quakeDir );
	
	CFByteOrder byteorder = CFByteOrderGetCurrent();
	NSString* order = @"Unknown";
	switch( byteorder )
	{
		case CFByteOrderLittleEndian:
			order = @"Little";
			break;
			
		case CFByteOrderBigEndian:
			order = @"Big";
			break;
	}
	LOG( @"Host Endianness : %@", order );
	
	return NSApplicationMain( argc, (const char **) argv );
}
