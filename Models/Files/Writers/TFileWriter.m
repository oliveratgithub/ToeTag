
@implementation TFileWriter

-(void) openFile:(NSString*)InFilename
{
	// The file must be created before the NSFileHandle will successfully open it for writing.
	// Seems stupid but that's the only way I could get it to work.
	NSFileManager* fm = [NSFileManager defaultManager];
	[fm createFileAtPath:InFilename contents:nil attributes:nil];
	
	fileHandle = [NSFileHandle fileHandleForWritingAtPath:InFilename];
}

-(void) closeFile
{
	[fileHandle closeFile];
}

-(void) saveFile:(NSString*)InFilename
{
}

@end
