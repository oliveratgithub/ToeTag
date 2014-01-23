
@class TTriangleMesh;
@class MAPDocument;
@class TEntity;
@class TEModel;

@interface TOBJReader : TFileReader
{
@public
}

-(void) loadFile:(NSString*)InFilename MAP:(MAPDocument*)InMAP TriangleMesh:(TPolyMesh*)InTriangleMesh;

@end
