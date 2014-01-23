
@class MAPDocument;
@class TEntityClass;

@interface TVisibility : NSObject
{
@public
	NSMutableDictionary* hiddenObjects;
	MAPDocument* map;
}

-(id) initWithMAP:(MAPDocument*)InMap;
-(BOOL) hasNeededSelectors:(id)InObject;
-(BOOL) isVisible:(id)InObject;
-(void) hide:(id)InObject;
-(void) show:(id)InObject;
-(void) showAll;

@end
