//
//  SubroutineModel.m
//  seeker1
//
//  Created by Troy Stribling on 12/19/10.
//  Copyright 2010 imaginary products. All rights reserved.
//

//-----------------------------------------------------------------------------------------------------------------------------------
#import "SubroutineModel.h"
#import "SeekerDbi.h"
#import "ProgramNgin.h"
#import "CodeModel.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface SubroutineModel (PrivateAPI)

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation SubroutineModel

//-----------------------------------------------------------------------------------------------------------------------------------
@synthesize pk;
@synthesize codeListing;
@synthesize subroutineName;

//===================================================================================================================================
#pragma mark SubroutineModel PrivateAPI

//===================================================================================================================================
#pragma mark SubroutineModel

//-----------------------------------------------------------------------------------------------------------------------------------
+ (void)insertSubroutine:(NSMutableArray*)_subroutine withName:(NSString*)_name {
    SubroutineModel* subroutineModel = [self findByName:_name];
    if (subroutineModel) {
        subroutineModel.codeListing = [CodeModel instructionsToCodeListing:_subroutine];
        subroutineModel.subroutineName = _name;
        [subroutineModel update];
    } else {
        subroutineModel = [[[SubroutineModel alloc] init] autorelease];
        subroutineModel.codeListing = [CodeModel instructionsToCodeListing:_subroutine];
        subroutineModel.subroutineName = _name;
        [subroutineModel insert];
    }
}

//-----------------------------------------------------------------------------------------------------------------------------------
+ (SubroutineModel*)createSubroutineWithName:(NSString*)_name {
    SubroutineModel* subroutineModel = [[[SubroutineModel alloc] init] autorelease];
    subroutineModel.codeListing = nil;
    subroutineModel.subroutineName = _name;
    [subroutineModel insert];
    return subroutineModel;
}

//-----------------------------------------------------------------------------------------------------------------------------------
+ (NSInteger)count {
	return [[SeekerDbi instance]  selectIntExpression:@"SELECT COUNT(pk) FROM subroutines"];
}

//-----------------------------------------------------------------------------------------------------------------------------------
+ (void)drop {
	[[SeekerDbi instance]  updateWithStatement:@"DROP TABLE subroutines"];
}

//-----------------------------------------------------------------------------------------------------------------------------------
+ (void)create {
	[[SeekerDbi instance]  updateWithStatement:@"CREATE TABLE subroutines (pk integer primary key, codeListing text, subroutineName text)"];
}

//-----------------------------------------------------------------------------------------------------------------------------------
+ (void)destroyAll {
	[[SeekerDbi instance]  updateWithStatement:@"DELETE FROM subroutines"];
}

//-----------------------------------------------------------------------------------------------------------------------------------
+ (SubroutineModel*)findByName:(NSString*)_subroutineName {
	NSString* selectStatement = [NSString stringWithFormat:@"SELECT * FROM subroutines WHERE subroutineName = '%@'", _subroutineName];
	SubroutineModel* model = [[[SubroutineModel alloc] init] autorelease];
	[[SeekerDbi instance] selectForModel:[SubroutineModel class] withStatement:selectStatement andOutputTo:model];
    if (model.pk == 0) {
        model = nil;
    }
	return model;
}

//-----------------------------------------------------------------------------------------------------------------------------------
+ (NSMutableArray*)findAll {
	NSMutableArray* output = [NSMutableArray arrayWithCapacity:10];	
	[[SeekerDbi instance] selectAllForModel:[SubroutineModel class] withStatement:@"SELECT * FROM subroutines" andOutputTo:output];
	return output;
}

//-----------------------------------------------------------------------------------------------------------------------------------
+ (NSMutableArray*)findAllByName:(NSString*)_subroutineName {
	NSString* selectStatement = [NSString stringWithFormat:@"SELECT * FROM subroutines WHERE subroutineName <> '%@'", _subroutineName];
    NSMutableArray* output = [NSMutableArray arrayWithCapacity:10];	
    [[SeekerDbi instance] selectAllForModel:[SubroutineModel class] withStatement:selectStatement andOutputTo:output];
    return output;
}

//-----------------------------------------------------------------------------------------------------------------------------------
+ (NSMutableArray*)modelsToInstructions:(NSMutableArray*)_models forLevel:(NSInteger)_level {
	NSMutableArray* instructionSets = [NSMutableArray arrayWithCapacity:10];
	for (SubroutineModel* model in _models) {
        if ([model.subroutineName hasPrefix:@"mis-"]) {
            NSString* levelPrefix = [NSString stringWithFormat:@"mis-%d", _level];
            if ([model.subroutineName hasPrefix:levelPrefix]) {
                [instructionSets addObject:[NSArray arrayWithObjects:[NSNumber numberWithInt:SubroutineProgramInstruction], model.subroutineName, nil]];
            }
                
        } else {
            [instructionSets addObject:[NSArray arrayWithObjects:[NSNumber numberWithInt:SubroutineProgramInstruction], model.subroutineName, nil]];
        }
    }
    return instructionSets;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------------------------------------------------------------
- (void)insert {
    NSString* insertStatement;
    if (self.codeListing) {
        insertStatement = [NSString stringWithFormat:@"INSERT INTO subroutines (codeListing, subroutineName) values ('%@', '%@')", self.codeListing, self.subroutineName];	
    } else {
        insertStatement = [NSString stringWithFormat:@"INSERT INTO subroutines (subroutineName) values ('%@')", self.subroutineName];	
    }
    [[SeekerDbi instance]  updateWithStatement:insertStatement];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)destroy {	
	NSString* destroyStatement = [NSString stringWithFormat:@"DELETE FROM subroutines WHERE pk = %d", self.pk];	
	[[SeekerDbi instance]  updateWithStatement:destroyStatement];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)load {
    NSString* selectStatement = [NSString stringWithFormat:@"SELECT * FROM subroutines WHERE subroutineName = '%@'", self.subroutineName];
	[[SeekerDbi instance] selectForModel:[SubroutineModel class] withStatement:selectStatement andOutputTo:self];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)update {
    NSString* updateStatement = [NSString stringWithFormat:@"UPDATE subroutines SET codeListing = '%@', subroutineName = '%@' WHERE pk = %d", self.codeListing, 
                                 self.subroutineName, self.pk];
	[[SeekerDbi instance] updateWithStatement:updateStatement];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (NSMutableArray*)codeListingToInstrictions {
    return [CodeModel codeListingToInstructions:self.codeListing];
}

//===================================================================================================================================
#pragma mark WebgnosusDbiDelegate

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)setAttributesWithStatement:(sqlite3_stmt*)statement {
	self.pk = (int)sqlite3_column_int(statement, 0);
	const char* codeListingVal = (const char* )sqlite3_column_text(statement, 1);
	if (codeListingVal != NULL) {		
		self.codeListing = [NSString stringWithUTF8String:codeListingVal];
	}
	const char* subroutineNameVal = (const char* )sqlite3_column_text(statement, 2);
	if (subroutineNameVal != NULL) {		
		self.subroutineName = [NSString stringWithUTF8String:subroutineNameVal];
	}
}

//-----------------------------------------------------------------------------------------------------------------------------------
+ (void)collectAllFromResult:(sqlite3_stmt*)result andOutputTo:(NSMutableArray*)output {
	SubroutineModel* model = [[SubroutineModel alloc] init];
	[model setAttributesWithStatement:result];
	[output addObject:model];
    [model release];
}

//-----------------------------------------------------------------------------------------------------------------------------------
+ (void)collectFromResult:(sqlite3_stmt*)result andOutputTo:(id)output {
	[output setAttributesWithStatement:result];
}

@end
