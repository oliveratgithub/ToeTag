
@implementation TEntityClassRenderComponentArrow

-(id) init
{
	[super init];
	
	return self;
}

-(void) drawSelectionHighlights:(MAPDocument*)InMAP Entity:(TEntity*)InEntity
{
	float X = 0;
	
	float Y = [[InEntity valueForKey:@"angle" defaultValue:@"0"] floatValue];
	
	if( Y == -1 )
	{
		Y = 0;
		X = -90;
	}
	
	if( Y == -2 )
	{
		Y = 0;
		X = 90;
	}
	
	glRotatef( X, 1, 0, 0 );
	glRotatef( Y, 0, 1, 0 );
	
	glDisable( GL_TEXTURE_2D );
	glLineWidth( 3.0f );
	glColor3f( 1, 1, 1 );
	
	glBegin( GL_LINES );
	{
		glVertex3f( 16, 0, 0 );
		glVertex3f( 32, 0, 0 );
		
		glVertex3f( 32, 0, 0 );
		glVertex3f( 24, 8, 0 );
		
		glVertex3f( 32, 0, 0 );
		glVertex3f( 24, -8, 0 );
		
		glVertex3f( 32, 0, 0 );
		glVertex3f( 24, 0, 8 );
		
		glVertex3f( 32, 0, 0 );
		glVertex3f( 24, 0, -8 );
	}
	glEnd();
	
	glRotatef( -X, 1, 0, 0 );
	glRotatef( -Y, 0, 1, 0 );

	glLineWidth( 1.0f );
	glEnable( GL_TEXTURE_2D );
}

@end

