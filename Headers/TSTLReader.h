
@class TPolyMesh;
@class MAPDocument;
@class TEntity;
@class TEModel;

@interface TSTLReader : TFileReader
{
@public
}

-(void) loadFile:(NSString*)InFilename MAP:(MAPDocument*)InMAP TriangleMesh:(TPolyMesh*)InTriangleMesh;

@end
