
// A 3D viewport for editing levels.

@interface TLevelView : TOpenGLView
{

}

-(void) documentInit;
-(void) dragAxisFromDir:(TVec3D*)InDir OutX:(TVec3D**)OutX OutY:(TVec3D**)OutY;
-(TVec3D*) getAxisMask;
-(NSMutableString*) exportToText;
-(void) importFromText:(NSString*)InText;

@end
