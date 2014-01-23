
@class TBrush;
@class MAPDocument;
@class TEntity;
@class TEModel;

@interface TEMDLReader : TFileReader
{
@public
}

-(void) loadFile:(NSString*)InFilename MAP:(MAPDocument*)InMAP BMDL:(TEModel*)InEModel;

@end
