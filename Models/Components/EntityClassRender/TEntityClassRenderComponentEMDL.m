
@implementation TEntityClassRenderComponentEMDL

-(id) init
{
	[super init];
	
	emodels = [NSMutableArray new];
	bNegatesBoundingBox = YES;
	
	return self;
}

-(void) draw:(MAPDocument*)InMAP Entity:(TEntity*)InEntity
{
	glEnable( GL_TEXTURE_2D );
	
	TEModel* emodel = nil;
	
	int x;
	for( x = 1 ; x < [emodels count] ; ++x )
	{
		TEModel* EMDL = [emodels objectAtIndex:x];
		
		if( (InEntity->spawnFlags & EMDL->spawnFlagBit) > 0 )
		{
			emodel = EMDL;
		}
	}

	if( emodel == nil && [emodels count] > 0 )
	{
		emodel = [emodels objectAtIndex:0];
	}
		
	if( emodel != nil )
	{
		[self drawEMDL:emodel MAP:InMAP Entity:InEntity];
	}
}

-(void) drawWire:(MAPDocument*)InMAP Entity:(TEntity*)InEntity
{
	[self draw:InMAP Entity:InEntity];
	
	glDisable( GL_TEXTURE_2D );
}

-(void) drawForPick:(MAPDocument*)InMAP Entity:(TEntity*)InEntity
{
	[self draw:InMAP Entity:InEntity];
}

-(void) drawEMDL:(TEModel*)InEModel MAP:(MAPDocument*)InMAP Entity:(TEntity*)InEntity
{
	glTranslatef( entityClassOwner->szMin->x, entityClassOwner->szMin->y, entityClassOwner->szMin->z );
	
	for( TFace* F in InEModel->brush->faces )
	{
		[[InMAP findTextureByName:F->textureName] bind];
		glColor3f( F->lightValue, F->lightValue, F->lightValue );
		
		glBegin( GL_TRIANGLE_FAN );
		{
			for( TVec3D* V in F->verts )
			{
				glTexCoord2fv( &V->u );
				glVertex3fv( &V->x );
			}
		}				
		glEnd();
	}
}

@end

