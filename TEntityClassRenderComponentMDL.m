
@implementation TEntityClassRenderComponentMDL

-(id) init
{
	[super init];
	
	model = nil;
	skinIdx = 0;
	bNegatesBoundingBox = YES;
	
	return self;
}

-(void) draw:(MAPDocument*)InMAP Entity:(TEntity*)InEntity
{
	glEnable( GL_TEXTURE_2D );
	[self drawMDL:InMAP Entity:InEntity];
}

-(void) drawWire:(MAPDocument*)InMAP Entity:(TEntity*)InEntity
{
	glDisable( GL_TEXTURE_2D);
	[self drawMDL:InMAP Entity:InEntity];
}

-(void) drawForPick:(MAPDocument*)InMAP Entity:(TEntity*)InEntity
{
	[self draw:InMAP Entity:InEntity];
}

-(void) drawMDL:(MAPDocument*)InMAP Entity:(TEntity*)InEntity
{
	if( model == nil )
	{
		return;
	}
	
	glColor3f( 1, 1, 1 );
	
	[[model->skinTextures objectAtIndex:skinIdx] bind];
	
	glEnableClientState( GL_VERTEX_ARRAY );
	glEnableClientState( GL_TEXTURE_COORD_ARRAY );
	glDisableClientState( GL_COLOR_ARRAY );
	
    glVertexPointer( 3, GL_FLOAT, 0, model->verts );
    glTexCoordPointer( 2, GL_FLOAT, 0, model->uvs );
	
	glDrawArrays( model->primType, 0, model->elementCount );
}

@end

