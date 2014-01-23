
// A 2D viewport for editing levels.

@interface TOrthoLevelView : TOpenGLView
{
@public
	IBOutlet NSSegmentedControl* orientationCtrl;
	
	EMouseAction ownerMouseAction;	// The mouse action that owns the start/end points
	TVec3D *startPoint, *endPoint;
	TPlane *clipPlane, *clipFlippedPlane;
	BOOL bPlacingRotationPivot;
}

-(void) documentInit;
-(void) draw:(MAPDocument*)InMAP;
- (IBAction)onOrientationChange:(id)sender;
-(TVec3D*) getAxisMask;
-(NSMutableString*) exportToText;
-(void) importFromText:(NSString*)InText;

@end
