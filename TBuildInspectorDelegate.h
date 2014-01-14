
@class TVec3D;

@interface TBuildInspectorDelegate : NSResponder
{
@public
	IBOutlet NSTextView* outputTextView;
	
	TVec3D* leakLocation;
}

-(IBAction) OnJumpToLeak:(id)sender;

@end
