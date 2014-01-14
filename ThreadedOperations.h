
@interface NSOperationCreateBrushFromPlanes : NSOperation
{
	MAPDocument* map;
	NSMutableArray* clipPlanes;
	TEntity* entity;
	BOOL bSelectAfterImport;
	int quickGroupID;
}

-(id) initWithMap:(MAPDocument*)InMap ClipPlanes:(NSMutableArray*)InClipPlanes quickGroupID:(int)InQuickGroupID Entity:(TEntity*)InEntity SelectAfterImport:(BOOL)InSelectAfterImport;

@end

// ------------------------------------------------------

@interface NSOperationGenerateMipMaps : NSOperation
{
	TTexture* texture;
	int dsize;
}

-(id) initWithTexture:(TTexture*)InTexture DiskSize:(int)InDiskSize;

@end

// ------------------------------------------------------
