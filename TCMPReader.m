
@implementation TCMPReader

-(void) loadFile:(NSString*)InFilename MAP:(MAPDocument*)InMAP
{
	LOG( @"Reading CMP file : %@", InFilename );
	LOG_IN();
	
	[self openFile:InFilename];
	
	if( fileHandle == nil )
	{
		// file not found
		return;
	}
	
	[self loadFromFileHandle:InMAP];

	LOG_OUT();
}	
	
-(void) loadFileFromResources:(NSString*)InFilename MAP:(MAPDocument*)InMAP
{
	LOG( @"Reading CMP file from resources : %@", InFilename );
	LOG_IN();
	
	[self openFileFromResources:InFilename];
	[self loadFromFileHandle:InMAP];
	
	LOG_OUT();
}
	
-(void) loadFromFileHandle:(MAPDocument*)InMAP
{
	NSData* data = [fileHandle readDataToEndOfFile];
	NSString* fileContents = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSArray* fileLines = [fileContents componentsSeparatedByString:@"\n"];
	
	TEntityClass* entityClass = nil;

	for( NSString* line in fileLines )
	{
		line = [line stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \t\r\n"]];
		
		if( [line length] == 0 )
		{
			// skip blank lines
		}
		else if( [line length] > 1 && [[line substringToIndex:2] isEqualToString:@"//"] )
		{
			// skip comments
		}
		else if( [line length] >= 6 && [[line substringToIndex:6] isEqualToString:@"TOETAG"] )
		{
			NSString* entityClassName;
			NSScanner* scanner = [NSScanner scannerWithString:line];
			
			[scanner scanString:@"TOETAG " intoString:nil];
			[scanner scanUpToString: @" " intoString:&entityClassName];
			entityClass = [InMAP findEntityClassByName:entityClassName];
			
			if( entityClass == nil )
			{
				WARN( @"Entity class unknown : %@", entityClassName );
			}
			else
			{
				LOG( @"%@", entityClass->name );
			}
			LOG_IN();
		}
		else if( [line length] > 0 && [[line substringToIndex:1] isEqualToString:@"}"] )
		{
			entityClass = nil;
			LOG_OUT();
		}
		else if( [line length] > 0 && [[line substringToIndex:1] isEqualToString:@"{"] )
		{
			// skip opening brace
		}
		else
		{
			if( entityClass == nil )
			{
				continue;
			}
			
			NSArray* chunks = [line componentsSeparatedByString:@"="];
			NSString* componentName = [chunks objectAtIndex:0];
			
			if( [componentName isEqualToString:@"arrow"] )
			{
				LOG( @"arrow" );
				
				TEntityClassRenderComponentArrow* ECRC = [TEntityClassRenderComponentArrow new];
				ECRC->entityClassOwner = entityClass;
				[entityClass->renderComponenents addObject:ECRC];
			}
			else if( [componentName isEqualToString:@"mdl"] )
			{
				TEntityClassRenderComponentMDL* ECRC = [TEntityClassRenderComponentMDL new];
				ECRC->entityClassOwner = entityClass;
				NSArray* subchunks = [[chunks objectAtIndex:1] componentsSeparatedByString:@","];
				
				LOG( @"MDL: %@ (skin: %d)", [subchunks objectAtIndex:0], ECRC->skinIdx );
				
				TMDLTocEntry* tocentry = [[TGlobal G]->MDLTableOfContents objectForKey:[subchunks objectAtIndex:0]];
				
				ECRC->skinIdx = [[subchunks objectAtIndex:1] intValue];
				
				TPAKReader* reader = [TPAKReader new];
				ECRC->model = [reader loadMDL:tocentry->PAKFilename Offset:tocentry->offset Size:tocentry->sz];
				[ECRC->model finalizeInternals];
				 
				[entityClass->renderComponenents addObject:ECRC];
			}
			else if( [componentName isEqualToString:@"emodel"] )
			{
				TEntityClassRenderComponentEMDL* ECRC = [TEntityClassRenderComponentEMDL new];
				ECRC->entityClassOwner = entityClass;
				NSArray* subchunks = [[chunks objectAtIndex:1] componentsSeparatedByString:@","];
				TEMDLReader* reader = [TEMDLReader new];
				
				LOG( @"EMDL: %@", [subchunks objectAtIndex:0] );
				
				for( NSString* S in subchunks )
				{
					NSArray* echunks = [S componentsSeparatedByString:@":"];
					
					TEModel* emodel = [TEModel new];
					
					[reader loadFile:[NSString stringWithFormat:@"%@.map", [echunks objectAtIndex:0]] MAP:InMAP BMDL:emodel];
					emodel->spawnFlagBit = [[echunks objectAtIndex:1] intValue];
					
					[emodel->brush generateTexCoords:InMAP];
					[ECRC->emodels addObject:emodel];
				}
				
				[entityClass->renderComponenents addObject:ECRC];
			}
			else if( [componentName isEqualToString:@"editoronly"] )
			{
				entityClass->bEditorOnly = [[chunks objectAtIndex:1] isEqualToString:@"true"];
			}
		}
	}

	[self closeFile];
}

@end
