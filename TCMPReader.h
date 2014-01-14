
@class MAPDocument;
@class TMDLTocEntry;
@class TEntityClassRenderComponentMDL;

@interface TCMPReader : TFileReader
{
}

-(void) loadFileFromResources:(NSString*)InFilename MAP:(MAPDocument*)InMAP;
-(void) loadFile:(NSString*)InFilename MAP:(MAPDocument*)InMAP;

-(void) loadFromFileHandle:(MAPDocument*)InMAP;

@end
