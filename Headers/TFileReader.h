
@interface TFileReader : NSObject
{
@public
	NSFileHandle* fileHandle;
}

-(void) openFileFromResources:(NSString*)InFilename;
-(void) openFile:(NSString*)InFilename;
-(void) closeFile;

-(void) loadFile:(NSString*)InFilename;

@end
