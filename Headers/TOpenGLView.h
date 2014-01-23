
@class TRenderComponent;
@class TRenderGridComponent;
@class TProjComponent;
@class TVec3D;
@class MAPDocument;

@interface TOpenGLView : NSOpenGLView
{
@public
	BOOL bReadyToRender;
	
	TRenderComponent* renderComponent;
	TRenderGridComponent* renderGridComponent;
	TProjComponent* projectionComponent;
	
	TVec3D* cameraLocation;
	TVec3D* cameraRotation;
	TVec3D* cameraLimits;
	
	EOrientation orientation;
	
	// Zoom factor for orthographic views
	float orthoZoom;
	
	BOOL bDocInitDone;
}

-(void) documentInit;
-(void) draw:(MAPDocument*)InMAP;
-(void) drawWorld:(MAPDocument*)InMAP SelectedState:(BOOL)InSelect;
-(void) drawForPick:(MAPDocument*)InMAP Category:(ESelectCategory)InCategory;
-(void) refreshCameraLimits;
-(int) selectAtX:(float)InX Y:(float)InY DoubleClick:(BOOL)InDoubleClick ModifierFlags:(NSUInteger)InModFlags Category:(ESelectCategory)InCategory;
-(void)drawRect:(NSRect)bounds;
-(void) scrollToSelectedTexture;
-(TVec3D*) getAxisMask;
-(void) registerTextures;
-(NSMutableString*) exportToText;
-(void) importFromText:(NSString*)InText;
-(BOOL) isOrthoView;
	
@end
