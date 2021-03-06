//
//  SubroutineModel.h
//  seeker1
//
//  Created by Troy Stribling on 12/19/10.
//  Copyright 2010 imaginary products. All rights reserved.
//

//-----------------------------------------------------------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import <sqlite3.h>

//-----------------------------------------------------------------------------------------------------------------------------------

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface SubroutineModel : NSObject {
    NSInteger pk;
    NSString* codeListing;
    NSString* subroutineName;
}

//-----------------------------------------------------------------------------------------------------------------------------------
@property (nonatomic, assign) NSInteger pk;
@property (nonatomic, retain) NSString* codeListing;
@property (nonatomic, retain) NSString* subroutineName;

//-----------------------------------------------------------------------------------------------------------------------------------
+ (void)insertSubroutine:(NSMutableArray*)_function withName:(NSString*)_name;
+ (SubroutineModel*)createSubroutineWithName:(NSString*)_name;
+ (NSInteger)count;
+ (void)drop;
+ (void)create;
+ (void)destroyAll;
+ (SubroutineModel*)findByName:(NSString*)_subroutineName;
+ (NSMutableArray*)findAll;
+ (NSMutableArray*)findAllByName:(NSString*)_subroutineName;
+ (NSMutableArray*)modelsToInstructions:(NSMutableArray*)_models forLevel:(NSInteger)_level;

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)insert;
- (void)destroy;
- (void)load;
- (void)update;
- (NSMutableArray*)codeListingToInstrictions;

@end
