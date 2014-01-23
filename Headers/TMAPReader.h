
@class TBrush;
@class MAPDocument;
@class TEntity;

@interface TMAPReader : TFileReader
{
@public
}

-(void) loadFile:(NSString*)InFilename MAP:(MAPDocument*)InMAP;

@end
