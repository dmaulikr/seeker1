//
//  EndOfSiteScene.m
//  seeker1
//
//  Created by Troy Stribling on 3/14/11.
//  Copyright 2011 imaginary products. All rights reserved.
//

//-----------------------------------------------------------------------------------------------------------------------------------
#import "EndOfSiteScene.h"
#import "QuadsScene.h"
#import "MainScene.h"
#import "UserModel.h"
#import "LevelModel.h"
#import "StatusDisplay.h"
#import "ViewControllerManager.h"
#import "AudioManager.h"

//-----------------------------------------------------------------------------------------------------------------------------------
#define kEND_OF_LEVEL_TICK_1    40
#define kEND_OF_LEVEL_TICK_2    90
#define kEND_OF_LEVEL_TICK_3    140


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface EndOfSiteScene (PrivateAPI)

- (void)insertCompletedDisplay;
- (void)insertNextDisplay;
- (void)insertNextMissionMenu;
- (void)nextMission;
- (void)insertNextSite;
- (void)insertTharsis:(CGPoint)_position;
- (void)insertMemnonia:(CGPoint)_position;
- (void)insertElysium:(CGPoint)_position;
- (void)insertGameOver;
- (void)doneWithGame;

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation EndOfSiteScene

//-----------------------------------------------------------------------------------------------------------------------------------
@synthesize statusDisplay;
@synthesize counter;
@synthesize showNextMenu;

//===================================================================================================================================
#pragma mark EndOfSiteScene PrivateAPI

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)insertCompletedDisplay {
    CGSize screenSize = [[CCDirector sharedDirector] winSize];
    CCSprite* sprite = [CCSprite spriteWithFile:@"completed-site.png"];
    sprite.position = CGPointMake(screenSize.width/2.0, 380.0f);
    [self addChild:sprite];
    CGPoint site_position = CGPointMake(screenSize.width/2.0, 355.0);
    NSInteger lastQuad = [UserModel quadrangle] - 1;
    if (![UserModel gameOver]) {
        switch (lastQuad) {
            case TharsisQuadType:
                [self insertTharsis:site_position];
                break;
            case MemnoniaQuadType:
                [self insertMemnonia:site_position];
                break;
            case ElysiumQuadType:
                [self insertElysium:site_position];
                break;
        }
    } else {
        [self insertElysium:site_position];
    }
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)insertNextDisplay {
    CGSize screenSize = [[CCDirector sharedDirector] winSize];
    CGPoint site_position = CGPointMake(screenSize.width/2.0, 190.0);
    NSInteger nextQuad = [UserModel quadrangle];
    if (![UserModel gameOver]) {
        switch (nextQuad) {
            case TharsisQuadType:
                break;
            case MemnoniaQuadType:
                [self insertNextSite];
                [self insertMemnonia:site_position];
                break;
            case ElysiumQuadType:
                [self insertNextSite];
                [self insertElysium:site_position];
                break;
        }
    } else  {
        self.showNextMenu = NO;
        [self insertGameOver];
    }
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)insertNextSite {
    CCSprite* sprite = [CCSprite spriteWithFile:@"next-site.png"];
    CGSize screenSize = [[CCDirector sharedDirector] winSize];
    sprite.position = CGPointMake(screenSize.width/2.0, 215.0f);
    [self addChild:sprite];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)insertTharsis:(CGPoint)_position {
    [[AudioManager instance] playEffect:ItemDisplayedAudioEffectID];
    CCSprite* titleSprite = [CCSprite spriteWithFile:@"tharsis-title.png"];
    titleSprite.position = _position;
    [self addChild:titleSprite];
    CCSprite* iconSprite = [CCSprite spriteWithFile:@"tharsis-icon.png"];
    iconSprite.position = CGPointMake(_position.x, _position.y - 70.0);
    [self addChild:iconSprite];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)insertMemnonia:(CGPoint)_position {
    [[AudioManager instance] playEffect:ItemDisplayedAudioEffectID];
    CCSprite* titleSprite = [CCSprite spriteWithFile:@"memnonia-title.png"];
    titleSprite.position = _position;
    [self addChild:titleSprite];
    CCSprite* iconSprite = [CCSprite spriteWithFile:@"memnonia-icon.png"];
    iconSprite.position = CGPointMake(_position.x, _position.y - 70.0);
    [self addChild:iconSprite];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)insertElysium:(CGPoint)_position {
    [[AudioManager instance] playEffect:ItemDisplayedAudioEffectID];
    CCSprite* titleSprite = [CCSprite spriteWithFile:@"elysium-title.png"];
    titleSprite.position = _position;
    [self addChild:titleSprite];
    CCSprite* iconSprite = [CCSprite spriteWithFile:@"elysium-icon.png"];
    iconSprite.position = CGPointMake(_position.x, _position.y - 70.0);
    [self addChild:iconSprite];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)insertGameOver {
    [[AudioManager instance] playEffect:ItemDisplayedAudioEffectID];
    CGSize screenSize = [[CCDirector sharedDirector] winSize];
    CCSprite* titleSprite = [CCSprite spriteWithFile:@"game-over.png"];
    titleSprite.position = CGPointMake(screenSize.width/2.0, 150.0);
    [self addChild:titleSprite];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)insertNextMissionMenu {
    [[AudioManager instance] playEffect:ItemDisplayedAudioEffectID];
    CCSprite* nextSprite = [CCSprite spriteWithFile:@"go-to-next-site.png"];
    CCSprite* nextSpriteSelected = [CCSprite spriteWithFile:@"go-to-next-site.png"];
    CCMenuItemLabel* nextItem = [CCMenuItemSprite itemFromNormalSprite:nextSprite selectedSprite:nextSpriteSelected target:self selector:@selector(nextMission)];
    CCMenu* menu = [CCMenu menuWithItems:nextItem, nil];
    [menu alignItemsHorizontallyWithPadding:90.0];
    menu.position = CGPointMake(245.0f, 35.0f);
    [self addChild:menu];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)insertDoneMenu {
    CCSprite* doneSprite = [CCSprite spriteWithFile:@"done-last-site.png"];
    CCSprite* doneSpriteSelected = [CCSprite spriteWithFile:@"done-last-site.png"];
    CCMenuItemLabel* doneItem = [CCMenuItemSprite itemFromNormalSprite:doneSprite selectedSprite:doneSpriteSelected target:self selector:@selector(doneWithGame)];
    CCMenu* menu = [CCMenu menuWithItems:doneItem, nil];
    [menu alignItemsHorizontallyWithPadding:90.0];
    menu.position = CGPointMake(245.0f, 35.0f);
    [self addChild:menu];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)nextMission {
    [TutorialSectionViewController nextLevel];
    [LevelModel insertForLevel:[UserModel level]];
    [[AudioManager instance] playEffect:SelectAudioEffectID];
    [[CCDirector sharedDirector] replaceScene: [QuadsScene scene]];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)doneWithGame {
    [[AudioManager instance] playEffect:SelectAudioEffectID];
    [[CCDirector sharedDirector] replaceScene: [MainScene scene]];
}

//===================================================================================================================================
#pragma mark EndOfSiteScene

//-----------------------------------------------------------------------------------------------------------------------------------
+ (id)scene {
	CCScene *scene = [CCScene node];
	EndOfSiteScene *layer = [EndOfSiteScene node];
	[scene addChild:layer];
	return scene;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (id)init {
	if((self=[super init])) {
        self.counter = 0;
        self.statusDisplay = [StatusDisplay createWithFile:@"empty-display.png"];
        [self.statusDisplay insert:self];
        [self.statusDisplay test];
        CCSprite* backgroundGrid = [CCSprite spriteWithFile:@"end-of-site-background.png"];
        backgroundGrid.anchorPoint = CGPointMake(0.0, 0.0);
        backgroundGrid.position = CGPointMake(0.0, 0.0);
        [self addChild:backgroundGrid];
        [self schedule:@selector(nextFrame:)];
        self.showNextMenu = YES;
    }
	return self;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void) nextFrame:(ccTime)dt {
    self.counter++;
    if (self.counter == kEND_OF_LEVEL_TICK_1) {
        [self insertCompletedDisplay];
        [self.statusDisplay test];
    } else if (self.counter == kEND_OF_LEVEL_TICK_2) {
        [self insertNextDisplay];
        [self.statusDisplay clear];
    } else if (self.counter == kEND_OF_LEVEL_TICK_3) {
        if (self.showNextMenu) {
            [self insertNextMissionMenu];
        } else {
            [self insertDoneMenu];
        }
        [self.statusDisplay test];
    }    
}

//-----------------------------------------------------------------------------------------------------------------------------------
-(void) ccTouchesBegan:(NSSet*)touches withEvent:(UIEvent *)event {
}    


@end
