
#import "TVec3D.h"

@class TOpenGLView;
@class MAPDocument;
@class TEntity;
@class TRenderComponent;
@class TBrush;
@class TEntityClass;

// ------------------------------------------------------

@interface TRenderArray : NSObject
{
@public
	float* data;		// The data blob (consists of verts, uvs, colors)
	int currentIdx;				// How many elements we current have in the data blob
	int maxIdx;					// How many elements are currently allocated
	
	ERenderArrayElementType type;	// What type of elements we are storing in the data blob
	int numFloatsPerElement;		// The number of floats per element
	
@private
	int GROW_SZ;			// How many elements to add to the data blob if we need to reallocate
}

-(id) initWithElementType:(ERenderArrayElementType)InType;
-(void) resetToStart;
-(void) addElement:(int)InNumElements, ...;
-(void) draw:(GLuint)InPrimType;

@end

// ------------------------------------------------------

@interface TPreferencesTools : NSObject
{
}

+(BOOL) isQuakeDirectoryValid:(NSUserDefaultsController*)InUDC;

@end

// ------------------------------------------------------

@interface TBBox : NSObject
{
@public
	TVec3D *min, *max;
}

-(void) addVertex:(TVec3D*)In;
-(TVec3D*) getCenter;
-(TVec3D*) getExtents;
-(void) expandBy:(float)In;

@end

// ------------------------------------------------------

@interface TMDLTocEntry : NSObject
{
@public
	NSString* PAKFilename;	// The full pathname of the PAK file this MDL lives in
	int offset, sz;			// The offset to and size of the MDL in the PAK file
}

@end

// ------------------------------------------------------
// A triangle model read from the PAK files in the quake/id1 directory.

@interface TMDL : NSObject
{
@public
	NSMutableArray* skinTextures;		// (TTexture*) The skins found in the MDL file
	NSMutableArray* triangles;			// (TVec3D*) Contains XYZ coords as well as UVs in sets of 3 for each triangle
	
	float *verts, *uvs;
	int elementCount;					// The number of verts that are going to be passed to glDrawArrays
	int primType;
}

-(void) finalizeInternals;

@end

// ------------------------------------------------------
// A brush model read from MAP files stored as resources
// These are for entities like health and ammo

@interface TEModel : NSObject
{
@public
	int spawnFlagBit;		// The spawn flag that must be set before this emodel will draw for the parent entity
	TBrush* brush;			// The brush containing the faces that make up this emodel
}

@end

// ------------------------------------------------------

@interface TGlobal : NSObject
{
@public
	TVec3D* LevelRenderLightDir;
	
	// Drawing routines check this var to see if they should do any rendering or not (> 1 == no drawing allowed).
	int drawingPausedRefCount;
	
	// The last quick group ID that was used
	int lastQuickGroupID;
	
	// The last name that was assigned for the purposes of OpenGL picking
	GLuint lastPickName;
	
	// Are we marking textures as "in use" during rendering?
	BOOL bTrackingTextureUsage;
	
	// The last mru click count assigned to a texture
	unsigned int lastMRUClickCount;
	
	// The last target id that was generated
	unsigned int lastTargetID;
	
	// Table of contents for all PAK files in the Quake directory.  These will be loaded as they are
	// requested by entity class render components.
	NSMutableDictionary* MDLTableOfContents;
	
	// Temp objects
	TVec3D *colorWhite, *colorBlack, *colorLtGray, *colorMedGray, *colorDkGray, *colorSelectedBrush, *colorSelectedBrushHalf;
	
	// Extents that cover the entire world
	TVec3D* worldExtents;
	
	// Axis vectors that are referenced during things like mouse drags or texture mapping
	NSMutableArray *baseAxis, *dragAxis;
	
	// The current level editing viewport.  This is set manually at various times so this
	// is not 100% reliable.  Make sure that you know it's been set before relying on it.
	TOpenGLView* currentLevelView;
	
	// The rendering component that is currently drawing.  This is used to look up
	// display list IDs for various classes.
	TRenderComponent* currentRenderComponent;
	
	// If YES, then texture locking is on.
	BOOL bTextureLock;
	
	// The pivot point for rotating entities
	TVec3D* pivotLocation;

	// Standard settings for all strings used via OpenGL
	NSMutableDictionary* standardStringAttribs;

	// The Quake palette
	//byte palette[768];
	//__strong byte* palette;
	NSMutableArray* palette;
}

-(void) loadMDLTableOfContents;
-(void) precacheResources:(MAPDocument*)InMAP;
-(int) generateQuickGroupID;
-(GLuint) generatePickName;
-(unsigned int) generateMRUClickCount;
-(unsigned int) generateTargetID;
-(void) cacheTextureFromResources:(NSString*)InName MAP:(MAPDocument*)InMAP;
-(byte) getBestPaletteIndexForR:(int)InR G:(int)InG B:(int)InB AllowFullbrights:(BOOL)InAllowFullbrights;

+(TGlobal*) G;
+(int) findClosestPowerOfTwo:(int)InValue;
+(int) findBestPowerOfTwo:(int)InValue;
+(MAPDocument*) getMAP;
+(void) logOpenGLErrors;

@end
