
@implementation TRenderGridOrthoComponent

-(void) draw:(MAPDocument*)InMAP
{
	glDisable( GL_TEXTURE_2D );
	
	glPushMatrix();
	
	int x;
	float pos;
	
	int editorGridSZ = InMAP->gridSz;
	
	int gridSz = 16;							// 16 seems to be a good base to start with here (magic number, by design)
	gridSz *= ownerView->orthoZoom / 4.0f;		// Dividing the zoom by 4 allows the switching to bigger sizes to happen at a reasonable rate
	gridSz = [TGlobal findClosestPowerOfTwo:gridSz];
	gridSz = MAX( gridSz, editorGridSZ );
	
	// Minor grid lines
	
	glColor3f( 0.8, 0.8, 0.8 );
	
	glBegin( GL_LINES );
	{
		for( x = 0 ; x < (WORLD_SZ_HALF / gridSz) ; x++ )
		{
			pos = (x + 1 ) * gridSz;
			
			switch( ownerView->orientation )
			{
				case TO_Top_XZ:
					
					glVertex3f( pos, 0, -WORLD_SZ_HALF );
					glVertex3f( pos, 0, WORLD_SZ_HALF );
					
					glVertex3f( -WORLD_SZ_HALF, 0, pos );
					glVertex3f( WORLD_SZ_HALF, 0, pos );
					
					break;
					
				case TO_Front_XY:
					
					glVertex3f( pos, -WORLD_SZ_HALF, 0 );
					glVertex3f( pos, WORLD_SZ_HALF, 0 );
					
					glVertex3f( -WORLD_SZ_HALF, pos, 0 );
					glVertex3f( WORLD_SZ_HALF, pos, 0 );
					
					break;
					
				case TO_Side_YZ:
					
					glVertex3f( 0, -WORLD_SZ_HALF, pos );
					glVertex3f( 0, WORLD_SZ_HALF, pos );
					
					glVertex3f( 0, pos, -WORLD_SZ_HALF );
					glVertex3f( 0, pos, WORLD_SZ_HALF );
					
					break;
			}
			
			pos = (x + 1 ) * -gridSz;

			switch( ownerView->orientation )
			{
				case TO_Top_XZ:
					
					glVertex3f( pos, 0, -WORLD_SZ_HALF );
					glVertex3f( pos, 0, WORLD_SZ_HALF );
					
					glVertex3f( -WORLD_SZ_HALF, 0, pos );
					glVertex3f( WORLD_SZ_HALF, 0, pos );
					
					break;
					
				case TO_Front_XY:

					glVertex3f( pos, -WORLD_SZ_HALF, 0 );
					glVertex3f( pos, WORLD_SZ_HALF, 0 );
					
					glVertex3f( -WORLD_SZ_HALF, pos, 0 );
					glVertex3f( WORLD_SZ_HALF, pos, 0 );
					
					break;
					
				case TO_Side_YZ:
					
					glVertex3f( 0, -WORLD_SZ_HALF, pos );
					glVertex3f( 0, WORLD_SZ_HALF, pos );
					
					glVertex3f( 0, pos, -WORLD_SZ_HALF );
					glVertex3f( 0, pos, WORLD_SZ_HALF );
					
					break;
			}
		}
	}
	glEnd();

	// Major grid lines
	
	glColor3f( 0.7, 0.7, 0.7 );
	
	glBegin( GL_LINES );
	{
		for( x = 0 ; x < (WORLD_SZ_HALF / gridSz) ; x += 8 )
		{
			pos = (x + 0 ) * gridSz;
			
			switch( ownerView->orientation )
			{
				case TO_Top_XZ:
					
					glVertex3f( pos, 0, -WORLD_SZ_HALF );
					glVertex3f( pos, 0, WORLD_SZ_HALF );
					
					glVertex3f( -WORLD_SZ_HALF, 0, pos );
					glVertex3f( WORLD_SZ_HALF, 0, pos );
					
					break;
					
				case TO_Front_XY:
					
					glVertex3f( pos, -WORLD_SZ_HALF, 0 );
					glVertex3f( pos, WORLD_SZ_HALF, 0 );
					
					glVertex3f( -WORLD_SZ_HALF, pos, 0 );
					glVertex3f( WORLD_SZ_HALF, pos, 0 );
					
					break;
					
				case TO_Side_YZ:
					
					glVertex3f( 0, -WORLD_SZ_HALF, pos );
					glVertex3f( 0, WORLD_SZ_HALF, pos );
					
					glVertex3f( 0, pos, -WORLD_SZ_HALF );
					glVertex3f( 0, pos, WORLD_SZ_HALF );
					
					break;
			}
			
			pos = (x + 0 ) * -gridSz;
			
			switch( ownerView->orientation )
			{
				case TO_Top_XZ:
					
					glVertex3f( pos, 0, -WORLD_SZ_HALF );
					glVertex3f( pos, 0, WORLD_SZ_HALF );
					
					glVertex3f( -WORLD_SZ_HALF, 0, pos );
					glVertex3f( WORLD_SZ_HALF, 0, pos );
					
					break;
					
				case TO_Front_XY:
					
					glVertex3f( pos, -WORLD_SZ_HALF, 0 );
					glVertex3f( pos, WORLD_SZ_HALF, 0 );
					
					glVertex3f( -WORLD_SZ_HALF, pos, 0 );
					glVertex3f( WORLD_SZ_HALF, pos, 0 );
					
					break;
					
				case TO_Side_YZ:
					
					glVertex3f( 0, -WORLD_SZ_HALF, pos );
					glVertex3f( 0, WORLD_SZ_HALF, pos );
					
					glVertex3f( 0, pos, -WORLD_SZ_HALF );
					glVertex3f( 0, pos, WORLD_SZ_HALF );
					
					break;
			}
		}
	}
	glEnd();
	
	// Major axis lines
	
	glClear( GL_DEPTH_BUFFER_BIT );
	
	glBegin( GL_LINES );
	{	
		glColor3f( .75, 0, 0 );
		glVertex3f( -WORLD_SZ_HALF, 0, 0 );
		glVertex3f( WORLD_SZ_HALF, 0, 0 );
		
		glColor3f( 0, .75, 0 );
		glVertex3f( 0, -WORLD_SZ_HALF, 0 );
		glVertex3f( 0, WORLD_SZ_HALF, 0 );
		
		glColor3f( 0, 0, .75 );
		glVertex3f( 0, 0, -WORLD_SZ_HALF );
		glVertex3f( 0, 0, WORLD_SZ_HALF );
	}
	glEnd();
	
	glPopMatrix();
	
	glColor3f( 1, 1, 1 );
	glLineWidth( 1.0 );
}

@end
