
@interface TFaceInspectorDelegate : NSResponder
{
@public
	int UOffset, VOffset, Rotation;
	float UScale, VScale;

	IBOutlet NSPanel* paneFaceInspector;
}

-(void) refreshInspectors;

-(IBAction) OnDefault:(id)sender;

-(IBAction) OnUOffsetChange:(id)sender;
-(IBAction) OnUOffsetUpDown:(id)sender;

-(IBAction) OnVOffsetChange:(id)sender;
-(IBAction) OnVOffsetUpDown:(id)sender;

-(IBAction) OnRotationChange:(id)sender;
-(IBAction) OnRotationUpDown:(id)sender;
-(IBAction) OnRotationSlider:(id)sender;

-(IBAction) OnUScaleChange:(id)sender;
-(void) applyUScale:(float)InScale;
-(IBAction) OnUScaleUpDown:(id)sender;
-(IBAction) OnUScaleFlip:(id)sender;
-(IBAction) OnUScaleDouble:(id)sender;
-(IBAction) OnUScaleHalf:(id)sender;
-(IBAction) OnUScaleOne:(id)sender;

-(IBAction) OnVScaleChange:(id)sender;
-(void) applyVScale:(float)InScale;
-(IBAction) OnVScaleUpDown:(id)sender;
-(IBAction) OnVScaleFlip:(id)sender;
-(IBAction) OnVScaleDouble:(id)sender;
-(IBAction) OnVScaleHalf:(id)sender;
-(IBAction) OnVScaleOne:(id)sender;

@end
