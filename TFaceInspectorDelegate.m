
@implementation TFaceInspectorDelegate

-(id) init
{
	[super init];
	
	UOffset = VOffset = 4;
	Rotation = 45;
	UScale = VScale = 1.0f;
	
	return self;
}

-(void) refreshInspectors
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	NSString* title;
	
	NSMutableArray* selectedFaces = [map->selMgr getSelections:TSC_Face];
	
	if( [selectedFaces count] == 0 )
	{
		title = @"Face Inspector";
	}
	else if( [selectedFaces count] == 1 )
	{
		TFace* face = [selectedFaces objectAtIndex:0];
		title = [NSString stringWithFormat:@"1 Face - %@", [face->textureName uppercaseString]];
	}
	else
	{
		title = [NSString stringWithFormat:@"%d Faces", [selectedFaces count]];
		
		TFace* face = [selectedFaces objectAtIndex:0];
		NSString* textureName = face->textureName;
		
		for( TFace* F in selectedFaces )
		{
			if( [F->textureName isEqualToString:textureName] == NO )
			{
				textureName = @"";
				break;
			}
		}
		
		if( [textureName length] > 0 )
		{
			title = [NSString stringWithFormat:@"%d Faces - %@", [selectedFaces count], [face->textureName uppercaseString]];
		}
	}

	[paneFaceInspector setTitle:title];
}
	
-(IBAction) OnDefault:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map resetSelectedFacesUOffset:YES VOffset:YES Rotation:YES UScale:YES VScale:YES];
	[map redrawLevelViewports];
}

// -----------------------------------------
// UOffset

-(IBAction) OnUOffsetChange:(id)sender
{
	UOffset = [[sender titleOfSelectedItem] intValue];
}

-(IBAction) OnUOffsetUpDown:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	
	[map offsetSelectedTexturesByU:[sender intValue] * UOffset V:0 ];
	[map redrawLevelViewports];
	
	[sender setIntValue:0];
}

// -----------------------------------------
// VOffset

-(IBAction) OnVOffsetChange:(id)sender
{
	VOffset = [[sender titleOfSelectedItem] intValue];
}

-(IBAction) OnVOffsetUpDown:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	
	[map offsetSelectedTexturesByU:0 V:[sender intValue] * VOffset ];
	[map redrawLevelViewports];
	
	[sender setIntValue:0];
}

// -----------------------------------------
// Rotation

-(IBAction) OnRotationChange:(id)sender
{
	Rotation = [[sender titleOfSelectedItem] intValue];
}

-(IBAction) OnRotationUpDown:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	
	[map rotateSelectedTexturesBy:[sender intValue] * Rotation ];
	[map redrawLevelViewports];
	
	[sender setIntValue:0];
}

-(IBAction) OnRotationSlider:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	
	[map setSelectedTextureRotation:[sender intValue] ];
	[map redrawLevelViewports];
}

// -----------------------------------------
// UScale

-(IBAction) OnUScaleChange:(id)sender
{
	UScale = [sender floatValue];
	
	if( UScale == 0.0 )
	{
		UScale = 1.0f;
		[sender setFloatValue:UScale];
	}
	
	[self applyUScale:UScale];
}

-(void) applyUScale:(float)InScale
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	
	[map scaleSelectedTexturesByU:InScale V:1.0 ];
	
	[map redrawLevelViewports];
}

-(IBAction) OnUScaleUpDown:(id)sender
{
	float scale = ([sender intValue] > 0) ? (abs([sender intValue]) * UScale) : (abs([sender intValue]) * (1.0f / UScale));
	
	[self applyUScale:scale];
	
	[sender setIntValue:0];
}

-(IBAction) OnUScaleFlip:(id)sender
{
	[self applyUScale:-1.0];
}

-(IBAction) OnUScaleDouble:(id)sender
{
	[self applyUScale:2.0];
}

-(IBAction) OnUScaleHalf:(id)sender
{
	[self applyUScale:0.5];
}

-(IBAction) OnUScaleOne:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map resetSelectedFacesUOffset:NO VOffset:NO Rotation:NO UScale:YES VScale:NO];
	[map redrawLevelViewports];
}

// -----------------------------------------
// VScale

-(IBAction) OnVScaleChange:(id)sender
{
	VScale = [sender floatValue];
	
	if( VScale == 0.0 )
	{
		VScale = 1.0f;
		[sender setFloatValue:UScale];
	}
	
	[self applyVScale:VScale];
}

-(void) applyVScale:(float)InScale
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	
	[map scaleSelectedTexturesByU:1.0 V:InScale ];
	
	[map redrawLevelViewports];
}

-(IBAction) OnVScaleUpDown:(id)sender
{
	float scale = ([sender intValue] > 0) ? (abs([sender intValue]) * VScale) : (abs([sender intValue]) * (1.0f / VScale));

	[self applyVScale:scale];
	
	[sender setIntValue:0];
}

-(IBAction) OnVScaleFlip:(id)sender
{
	[self applyVScale:-1.0];
}

-(IBAction) OnVScaleDouble:(id)sender
{
	[self applyVScale:2.0];
}

-(IBAction) OnVScaleHalf:(id)sender
{
	[self applyVScale:0.5];
}

-(IBAction) OnVScaleOne:(id)sender
{
	MAPDocument* map = [[NSDocumentController sharedDocumentController] currentDocument];
	[map resetSelectedFacesUOffset:NO VOffset:NO Rotation:NO UScale:NO VScale:YES];
	[map redrawLevelViewports];
}

@end
