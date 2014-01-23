
@class MAPDocument;

@interface NSImage (ProportionalScaling)

// creates a copy of the current image while maintaining
// proportions. also centers image, if necessary

- (NSImage*)imageByScalingProportionallyToSize:(NSSize)aSize;

@end

@interface TWADReader : TFileReader
{
@public
	wadhead_t* WADHeader;
	wadentry_t* WADEntries;
}

-(BOOL) loadFile:(NSString*)InFilename Map:(MAPDocument*)InMap;

@end
