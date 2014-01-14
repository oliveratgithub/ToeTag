
@implementation TRenderUtilBox

// Draws a box at the current location

+(void) drawBoxWidth:(int)InW Height:(int)InH Depth:(int)InD
{
	TVec3D *min = [[TVec3D alloc] initWithX:-(InW/2) Y:-(InH/2) Z:-(InD/2)], *max = [[TVec3D alloc] initWithX:(InW/2) Y:(InH/2) Z:(InD/2)];
	
	[self drawBoxMin:min Max:max];
}

+(void) drawBoxBBox:(TBBox*)InBBox
{
	[self drawBoxMin:InBBox->min Max:InBBox->max];
}

+(void) drawBoxMin:(TVec3D*)InMin Max:(TVec3D*)InMax
{
	glBegin( GL_QUADS );
	{
		glVertex3fv( &InMin->x );
		glVertex3f( InMin->x, InMax->y, InMin->z );
		glVertex3f( InMax->x, InMax->y, InMin->z );
		glVertex3f( InMax->x, InMin->y, InMin->z );
		
		glVertex3f( InMin->x, InMax->y, InMax->z );
		glVertex3f( InMin->x, InMin->y, InMax->z );
		glVertex3f( InMax->x, InMin->y, InMax->z );
		glVertex3fv( &InMax->x );
		
		glVertex3f( InMin->x, InMax->y, InMin->z );
		glVertex3fv( &InMin->x );
		glVertex3f( InMin->x, InMin->y, InMax->z );
		glVertex3f( InMin->x, InMax->y, InMax->z );
		
		glVertex3f( InMax->x, InMin->y, InMin->z );
		glVertex3f( InMax->x, InMax->y, InMin->z );
		glVertex3fv( &InMax->x );
		glVertex3f( InMax->x, InMin->y, InMax->z );
		
		glVertex3f( InMin->x, InMin->y, InMax->z );
		glVertex3fv( &InMin->x );
		glVertex3f( InMax->x, InMin->y, InMin->z );
		glVertex3f( InMax->x, InMin->y, InMax->z );
		
		glVertex3f( InMin->x, InMax->y, InMin->z );
		glVertex3f( InMin->x, InMax->y, InMax->z );
		glVertex3fv( &InMax->x );
		glVertex3f( InMax->x, InMax->y, InMin->z );
	}
	glEnd();
}
@end
