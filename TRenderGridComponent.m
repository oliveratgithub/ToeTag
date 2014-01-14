
@implementation TRenderGridComponent

-(void) draw:(MAPDocument*)InMAP
{
	glDisable( GL_TEXTURE_2D );
	
	float gridAlpha = 0.25f;
	
	glPushMatrix();
	
	glLineWidth( 2 );
	glBegin( GL_LINES );
	{	
		glColor4f( 1,0,0,gridAlpha );
		glVertex3f( 0, 0, 0 );
		glVertex3f( WORLD_SZ_HALF, 0, 0 );
		
		glColor4f( 0,1,0,gridAlpha );
		glVertex3f( 0, 0, 0 );
		glVertex3f( 0, WORLD_SZ_HALF, 0 );
		
		glColor4f( 0,0,1,gridAlpha );
		glVertex3f( 0, 0, 0 );
		glVertex3f( 0, 0, WORLD_SZ_HALF );
	}
	glEnd();
	
	glLineWidth( 1 );
	glBegin( GL_LINES );
	{	
		glColor4f( .75,0,0,gridAlpha );
		glVertex3f( -WORLD_SZ_HALF, 0, 0 );
		glVertex3f( 0, 0, 0 );
		
		glColor4f( 0,.75,0,gridAlpha );
		glVertex3f( 0, -WORLD_SZ_HALF, 0 );
		glVertex3f( 0, 0, 0 );
		
		glColor4f( 0,0,.75,gridAlpha );
		glVertex3f( 0, 0, -WORLD_SZ_HALF );
		glVertex3f( 0, 0, 0 );
	}
	glEnd();
	
	glPopMatrix();	
}

@end
