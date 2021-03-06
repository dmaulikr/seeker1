//
//  MissionsScene.m
//  seeker1
//
//  Created by Troy Stribling on 12/23/10.
//  Copyright 2010 imaginary products. All rights reserved.
//

//-----------------------------------------------------------------------------------------------------------------------------------
#import "MissionsScene.h"
#import "NavigationDisplay.h"
#import "QuadsScene.h"
#import "LevelModel.h"
#import "UserModel.h"
#import "TouchUtils.h"
#import "MapScene.h"
#import "ProgramNgin.h"
#import "AudioManager.h"

//-----------------------------------------------------------------------------------------------------------------------------------
#define kMISSION_COLUMN_ADJUST  53.0
#define kMISSION_ROW_ADJUST     19.0
#define kMISSION_YOFFSET        13.0
#define kMISSION_XOFFSET        1.0

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface MissionsScene (PrivateAPI)

- (NSInteger)missionToLevel:(NSInteger)_mission;
- (NSInteger)positionToMission:(CGPoint)_position;
- (CGSize)missionSize;
- (CGPoint)missionToPosition:(NSInteger)_mission;
- (BOOL)missionIsUnlocked:(NSInteger)_mission;
- (void)loadMissions;
- (void)loadMission:(NSInteger)_mission;
- (CCSprite*)getMissionSprite:(NSInteger)_mission;
- (void)addMissionLabel:(NSInteger)_mission toSprite:(CCSprite*)_sprite;
- (void)addMissionScore:(NSInteger)_mission toSprite:(CCSprite*)_sprite;
- (void)backNavigation;

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MissionsScene

//-----------------------------------------------------------------------------------------------------------------------------------
@synthesize navigationDisplay;
@synthesize quadrangle;
@synthesize levelsUnlocked;
@synthesize screenSize;

//===================================================================================================================================
#pragma mark MissionsScene PrivateAPI

//-----------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)missionToLevel:(NSInteger)_mission {
    return kMISSIONS_PER_QUAD * self.quadrangle + _mission + 1;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)positionToMission:(CGPoint)_position {
    CGFloat displayOffset = self.navigationDisplay.contentSize.height;
    NSInteger missionWidth = (self.screenSize.width - kMISSION_ROW_ADJUST) / kMISSIONS_PER_ROW;
    NSInteger missionHeight = (self.screenSize.height - displayOffset - kMISSION_COLUMN_ADJUST) / kMISSIONS_ROWS;
    NSInteger missionColumn = _position.x / missionWidth;
    NSInteger missionRow = (self.screenSize.height - displayOffset-_position.y - kMISSION_COLUMN_ADJUST + kMISSION_YOFFSET) / missionHeight;
    return kMISSIONS_PER_ROW * missionRow + missionColumn;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (CGSize)missionSize {
    CGFloat displayOffset = self.navigationDisplay.contentSize.height;
    NSInteger missionWidth = (self.screenSize.width - kMISSION_ROW_ADJUST)/ kMISSIONS_PER_ROW;
    NSInteger missionHeight = (self.screenSize.height - displayOffset - kMISSION_COLUMN_ADJUST) / kMISSIONS_ROWS;
    return CGSizeMake(missionWidth, missionHeight);
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (CGPoint)missionToPosition:(NSInteger)_mission {
    CGFloat displayOffset = self.navigationDisplay.contentSize.height;
    NSInteger missionRow = _mission / kMISSIONS_PER_ROW;
    NSInteger missionColumn = _mission - missionRow * kMISSIONS_PER_ROW;
    CGSize missionSize = [self missionSize];
    return CGPointMake(0.5 * missionSize.width + missionColumn * missionSize.width + kMISSION_ROW_ADJUST / 2.0 + kMISSION_XOFFSET,  
                       self.screenSize.height - missionRow * missionSize.height - displayOffset - kMISSION_COLUMN_ADJUST - 0.5 * missionSize.height + kMISSION_YOFFSET);
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)loadMissions {
    self.quadrangle = [UserModel quadrangle];
    self.levelsUnlocked =[LevelModel count];
    for (int i = 0; i < kMISSIONS_PER_QUAD; i++) {
        [self loadMission:i];
    }
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)loadMission:(NSInteger)_mission {
    CCSprite* missionSprite = [self getMissionSprite:_mission];
    missionSprite.position = [self missionToPosition:_mission];
    [self addChild:missionSprite];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (BOOL)missionIsUnlocked:(NSInteger)_mission {
    NSInteger unlockedMissions = self.levelsUnlocked - kMISSIONS_PER_QUAD * self.quadrangle;
    if (_mission < unlockedMissions) {
        return YES;
    } else {
        return NO;
    }
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (CCSprite*)getMissionSprite:(NSInteger)_mission {
    CCSprite* sprite = nil;
    if ([self missionIsUnlocked:_mission]) {
        NSInteger maxLevel = [LevelModel maxLevel];
        NSInteger level = [self missionToLevel:_mission];
        NSInteger lastLevel = kMISSIONS_PER_QUAD * kQUADS_TOTAL;
        LevelModel* levelModel = [LevelModel findByLevel:level];
        if (levelModel.codeScore <= levelModel.expectedCodeScore && levelModel.completed && level != maxLevel) {
            sprite = [[[CCSprite alloc] initWithFile:@"mission-complete.png"] autorelease];
        } else if (level == lastLevel && [UserModel gameOver] ) {
            sprite = [[[CCSprite alloc] initWithFile:@"mission-complete.png"] autorelease];
        } else if (level == maxLevel) {
            sprite = [[[CCSprite alloc] initWithFile:@"mission-not-played.png"] autorelease];
        } else if (levelModel.completed) {
            sprite = [[[CCSprite alloc] initWithFile:@"mission-incomplete.png"] autorelease];
        } else {
            sprite = [[[CCSprite alloc] initWithFile:@"mission-failed.png"] autorelease];
        }
        [self addMissionLabel:_mission toSprite:sprite];
        [self addMissionScore:_mission toSprite:sprite];
    } else {
        sprite = [[[CCSprite alloc] initWithFile:@"mission-locked.png"] autorelease];
    }
    sprite.anchorPoint = CGPointMake(0.5, 0.5);
    return sprite;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)addMissionLabel:(NSInteger)_mission toSprite:(CCSprite*)_sprite {
    CCLabelTTF* missionLable = 
        [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", [self missionToLevel:_mission]] fontName:kGLOBAL_FONT fontSize:kGLOBAL_FONT_SIZE_LARGE];
    CGSize missionSize = [self missionSize];
    missionLable.anchorPoint = CGPointMake(0.5, 0.5);
    missionLable.position = CGPointMake(0.30*missionSize.width, 0.32*missionSize.height);
    missionLable.color = ccc3(0,0,0); 
    [_sprite addChild:missionLable];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)addMissionScore:(NSInteger)_mission toSprite:(CCSprite*)_sprite {
    NSInteger maxLevel = [LevelModel maxLevel];
    NSInteger level = [self missionToLevel:_mission];
    LevelModel* levelModel = [LevelModel findByLevel:level];
    NSInteger lastLevel = kMISSIONS_PER_QUAD * kQUADS_TOTAL;
    if (([levelModel completed] && level != maxLevel) || ([levelModel completed] && level == lastLevel)) {
        CCLabelTTF* missionScore = 
            [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", [levelModel score]] fontName:kGLOBAL_FONT fontSize:kGLOBAL_FONT_SIZE_MISSION];
        CGSize missionSize = [self missionSize];
        missionScore.anchorPoint = CGPointMake(0.5, 0.5);
        missionScore.position = CGPointMake(0.31*missionSize.width, -0.11*missionSize.height);
        missionScore.color = kCCLABEL_FONT_COLOR; 
        [_sprite addChild:missionScore];
    }
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)backNavigation {
    [[AudioManager instance] playEffect:SelectAudioEffectID];
    [[CCDirector sharedDirector] replaceScene:[QuadsScene scene]];
}

//===================================================================================================================================
#pragma mark MissionsScene

//-----------------------------------------------------------------------------------------------------------------------------------
+ (id)scene {
	CCScene *scene = [CCScene node];
	MissionsScene* layer = [MissionsScene node];
	[scene addChild:layer];
	return scene;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (id)init {
	if( (self=[super init] )) {
		self.screenSize = [[CCDirector sharedDirector] winSize];
        self.isTouchEnabled = YES;
        self.navigationDisplay = [NavigationDisplay createWithTarget:self andSelector:@selector(backNavigation)];
        [self.navigationDisplay insert:self];
        CCSprite* backgroundGrid = [CCSprite spriteWithFile:@"missions-background.png"];
        backgroundGrid.anchorPoint = CGPointMake(0.0, 0.0);
        backgroundGrid.position = CGPointMake(0.0, 0.0);
        [self addChild:backgroundGrid];
        [self loadMissions];
    }
	return self;
}

//-----------------------------------------------------------------------------------------------------------------------------------
-(void) ccTouchesBegan:(NSSet*)touches withEvent:(UIEvent *)event {
	CGPoint touchLocation = [TouchUtils locationFromTouches:touches];
    NSInteger mission = [self positionToMission:touchLocation];
    if ([self missionIsUnlocked:mission]) {
        NSInteger level = [self missionToLevel:mission];
        [[AudioManager instance] playEffect:SelectAudioEffectID];
        [ProgramNgin instance].programHalted = NO;
        [ProgramNgin instance].programRunning = NO;
        [UserModel setLevel:level];
        [[CCDirector sharedDirector] replaceScene:[MapScene scene]];
    }
}    

@end
