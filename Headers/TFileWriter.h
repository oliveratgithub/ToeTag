
@interface TFileWriter : NSObject
{
@public
	NSFileHandle* fileHandle;
}

-(void) openFile:(NSString*)InFilename;
-(void) closeFile;

-(void) saveFile:(NSString*)InFilename;

@end
