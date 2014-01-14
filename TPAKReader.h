
@class MAPDocument;
@class TTexture;

@interface TPAKReader : TFileReader
{
@public
	pakheader_t* PAKHeader;
	pakentry_t* PAKEntries;
}

//-(void) loadFile:(NSString*)InFilename;
-(void) loadMDLTableOfContents:(NSString*)InFilename Into:(NSMutableDictionary*)InTableOfContents;
-(TMDL*) loadMDL:(NSString*)InFilename Offset:(int)InOffset Size:(int)InSize;

@end
