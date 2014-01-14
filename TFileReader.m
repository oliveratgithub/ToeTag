
@implementation TFileReader

-(void) openFileFromResources:(NSString*)InFilename
{
	NSString *filename = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], InFilename];
	fileHandle = [NSFileHandle fileHandleForReadingAtPath:filename];
}

-(void) openFile:(NSString*)InFilename
{
	fileHandle = [NSFileHandle fileHandleForReadingAtPath:InFilename];
}

-(void) closeFile
{
	[fileHandle closeFile];
}

-(void) loadFile:(NSString*)InFilename
{
}

@end
