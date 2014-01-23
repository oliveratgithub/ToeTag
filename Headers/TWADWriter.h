
@class MAPDocument;

@interface TWADWriter : TFileWriter
{
}

-(void) saveFile:(NSString*)InFilename Map:(MAPDocument*)InMap;

@end
