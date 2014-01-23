
@class TBrush;
@class TEntity;
@class MAPDocument;

@interface TDEFReader : TFileReader
{
@public
}

-(void) loadFileFromResources:(NSString*)InFilename MAP:(MAPDocument*)InMAP;
-(void) loadFile:(NSString*)InFilename MAP:(MAPDocument*)InMAP;

-(void) loadFromFileHandle:(MAPDocument*)InMAP;

@end
