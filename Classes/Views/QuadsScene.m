//
//  QuadsScene.m
//  seeker1
//
//  Created by Troy Stribling on 12/23/10.
//  Copyright 2010 imaginary products. All rights reserved.
//

//-----------------------------------------------------------------------------------------------------------------------------------
#import "QuadsScene.h"
#import "MainScene.h"
#import "NavigationDisplay.h"
#import "TouchUtils.h"
#import "LevelModel.h"
#import "UserModel.h"
#import "MissionsScene.h"

//-----------------------------------------------------------------------------------------------------------------------------------
#define kQUAD_IMAGE_YDELTA  75.0f
#define kQUAD_IMAGE_XDELTA  -7.5f

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface QuadsScene (PrivateAPI)

- (void)initQuads;
- (BOOL)displayedQuadIsUnlocked;
- (void)fowardQuads;
- (void)backwardQuads;
- (void)shiftQuadsForward;
- (void)shiftQuadsBackward;
- (void)moveQuadsBy:(CGFloat)_delta withDuration:(CGFloat)_duration;
- (void)stopRunningQuads;
- (NSInteger)percentComplete:(NSInteger)_quad;
- (NSInteger)totalScore:(NSInteger)_quad;
- (void)addQuadStats:(NSInteger)_quad toSprite:(CCSprite*)_sprite;
- (void)addTitle;
- (void)backNavigation;

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation QuadsScene

//-----------------------------------------------------------------------------------------------------------------------------------
@synthesize navigationDisplay;
@synthesize tharsisSprite;
@synthesize memnoniaSprite;
@synthesize elysiumSprite;
@synthesize titleLabel;
@synthesize displayedQuad;
@synthesize screenCenter;
@synthesize firstTouch;
@synthesize setTitle;

//===================================================================================================================================
#pragma mark QuadsScene PrivateAPI

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)initQuads {    
    NSInteger levelsUnlocked = [LevelModel count];
    NSInteger quadsUnlocked = levelsUnlocked / kMISSIONS_PER_QUAD;
    CGFloat quadShiftDelta = self.tharsisSprite.contentSize.height + kQUAD_IMAGE_YDELTA;
    
    self.displayedQuad = TharsisQuadType;
    self.tharsisSprite.position = CGPointMake(self.screenCenter.x + kQUAD_IMAGE_XDELTA, self.screenCenter.y);
    [self addChild:self.tharsisSprite z:-1];

    if (quadsUnlocked >= 1) {
        self.memnoniaSprite = [[[CCSprite alloc] initWithFile:@"memnonia.png"] autorelease];
        [self addQuadStats:TharsisQuadType toSprite:self.memnoniaSprite];
    } else {
        self.memnoniaSprite = [[[CCSprite alloc] initWithFile:@"memnonia-locked.png"] autorelease];
    }
    if (quadsUnlocked >= 2) {
        self.elysiumSprite = [[[CCSprite alloc] initWithFile:@"elysium.png"] autorelease];
        [self addQuadStats:TharsisQuadType toSprite:self.elysiumSprite];
    } else {
        self.elysiumSprite = [[[CCSprite alloc] initWithFile:@"elysium-locked.png"] autorelease];
    }    
    self.memnoniaSprite.anchorPoint = CGPointMake(0.5f, 0.5f);
    self.tharsisSprite.anchorPoint = CGPointMake(0.5f, 0.5f);
    
    CGPoint nextPosition = CGPointMake(self.screenCenter.x + kQUAD_IMAGE_XDELTA, self.screenCenter.y - quadShiftDelta);
    self.memnoniaSprite.position = nextPosition;
    [self addChild:self.memnoniaSprite z:-1];

    nextPosition = CGPointMake(self.screenCenter.x + kQUAD_IMAGE_XDELTA, self.screenCenter.y - 2 * quadShiftDelta);
    self.elysiumSprite.position = nextPosition;
    [self addChild:self.elysiumSprite z:-1];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (BOOL)displayedQuadIsUnlocked {
    NSInteger levelsUnlocked = [LevelModel count];
    NSInteger quadsUnlocked = levelsUnlocked / kMISSIONS_PER_QUAD;
    if (self.displayedQuad <= quadsUnlocked) {
        return YES;
    } else {
        return NO;
    }

}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)fowardQuads {
    switch (self.displayedQuad) {
        case TharsisQuadType:
            self.displayedQuad  = MemnoniaQuadType;
            [self shiftQuadsForward];
            break;
        case MemnoniaQuadType:
            self.displayedQuad  = ElysiumQuadType;
            [self shiftQuadsForward];
            break;
        case ElysiumQuadType:
            break;
        default:
            break;
    }
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)backwardQuads {
    switch (self.displayedQuad) {
        case TharsisQuadType:
            break;
        case MemnoniaQuadType:
            self.displayedQuad  = TharsisQuadType;
            [self shiftQuadsBackward];
            break;
        case ElysiumQuadType:
            self.displayedQuad  = MemnoniaQuadType;
            [self shiftQuadsBackward];
            break;
        default:
            break;
    }
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)shiftQuadsForward {
    CGFloat quadShiftDelta = self.tharsisSprite.contentSize.height + kQUAD_IMAGE_YDELTA;
    [self moveQuadsBy:quadShiftDelta withDuration:0.2];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)shiftQuadsBackward {
    CGFloat quadShiftDelta = -(self.tharsisSprite.contentSize.height + kQUAD_IMAGE_YDELTA);
    [self moveQuadsBy:quadShiftDelta withDuration:0.2];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)moveQuadsBy:(CGFloat)_delta withDuration:(CGFloat)_duration {
    [self stopRunningQuads];
    
    CGPoint tharsisPosition = self.tharsisSprite.position;
    CGPoint tharsisNextPosition = CGPointMake(tharsisPosition.x, tharsisPosition.y + _delta);
	[self.tharsisSprite runAction:[CCMoveTo actionWithDuration:_duration position:tharsisNextPosition]];
    
    CGPoint memnoniaPosition = self.memnoniaSprite.position;
    CGPoint memnoniaNextPosition = CGPointMake(memnoniaPosition.x, memnoniaPosition.y + _delta);
	[self.memnoniaSprite runAction:[CCMoveTo actionWithDuration:_duration position:memnoniaNextPosition]];
    
    CGPoint elysiumPosition = self.elysiumSprite.position;
    CGPoint elysiumNextPosition = CGPointMake(elysiumPosition.x, elysiumPosition.y + _delta);
	[self.elysiumSprite runAction:[CCMoveTo actionWithDuration:_duration position:elysiumNextPosition]];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)stopRunningQuads {
    [self.tharsisSprite stopAllActions];
    [self.memnoniaSprite stopAllActions];
    [self.elysiumSprite stopAllActions];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)percentComplete:(NSInteger)_quad {
    NSInteger completedLevels = 0;
    NSMutableArray* levels = [LevelModel findAllByQudrangle:_quad];
    for (LevelModel* level in levels) {
        if (level.completed) {
            completedLevels++;
        }
    }
    return 100.0 * ((float)completedLevels/(float)kMISSIONS_PER_QUAD);
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)totalScore:(NSInteger)_quad {
    NSInteger score = 0;
    NSMutableArray* levels = [LevelModel findAllByQudrangle:_quad];
    for (LevelModel* level in levels) {
        score += level.score;
    }
    return score;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)addQuadStats:(NSInteger)_quad toSprite:(CCSprite*)_sprite {
    NSInteger perComp = [self percentComplete:_quad];
    NSInteger score = [self totalScore:_quad];
    CGSize spriteSize = _sprite.contentSize;

    CCLabel* scoreLable = [CCLabel labelWithString:[NSString stringWithFormat:@"Score:     %d", score] fontName:kGLOBAL_FONT fontSize:kGLOBAL_FONT_SIZE_MISSION];
    scoreLable.anchorPoint = CGPointMake(0.0, 0.0);
    scoreLable.position = CGPointMake(0.115*spriteSize.width, -0.05*spriteSize.height);
    scoreLable.color = kCCLABEL_FONT_COLOR; 
    [_sprite addChild:scoreLable];

    CCLabel* perCompLable = [CCLabel labelWithString:[NSString stringWithFormat:@"Completed: %d%%", perComp] fontName:kGLOBAL_FONT fontSize:kGLOBAL_FONT_SIZE_MISSION];
    perCompLable.anchorPoint = CGPointMake(0.0, 0.0);
    perCompLable.position = CGPointMake(0.115*spriteSize.width, -0.1*spriteSize.height);
    perCompLable.color = kCCLABEL_FONT_COLOR; 
    [_sprite addChild:perCompLable];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)addTitle {
    NSInteger levelsUnlocked = [LevelModel count];
    NSInteger quadsUnlocked = levelsUnlocked / kMISSIONS_PER_QUAD;
    if (quadsUnlocked >= self.displayedQuad) {
        self.titleLabel = [CCLabel labelWithString:@"Select Site" fontName:kGLOBAL_FONT fontSize:kGLOBAL_FONT_SIZE_LARGE];
        self.titleLabel.color = ccc3(0,170,0);    
    } else {
        self.titleLabel = [CCLabel labelWithString:@"Site Locked" fontName:kGLOBAL_FONT fontSize:kGLOBAL_FONT_SIZE_LARGE];
        self.titleLabel.color = ccc3(0,100,0);    
    }
    self.titleLabel.position = CGPointMake(self.screenCenter.x, 390.0f);
    [self addChild:self.titleLabel];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)backNavigation {
    [[CCDirector sharedDirector] replaceScene:[MainScene scene]];
}

//===================================================================================================================================
#pragma mark QuadsScene

//-----------------------------------------------------------------------------------------------------------------------------------
+ (id)scene {
	CCScene *scene = [CCScene node];
	QuadsScene *layer = [QuadsScene node];
	[scene addChild: layer];
	return scene;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (id)init {
	if( (self=[super init] )) {
        self.isTouchEnabled = YES;
		CGSize screenSize = [[CCDirector sharedDirector] winSize];
		self.screenCenter = CGPointMake(screenSize.width/2, screenSize.height/2);
        self.tharsisSprite = [[[CCSprite alloc] initWithFile:@"tharsis.png"] autorelease];
        self.tharsisSprite.anchorPoint = CGPointMake(0.5f, 0.5f);
        [self addQuadStats:TharsisQuadType toSprite:self.tharsisSprite];
        [self initQuads];
        [self addTitle];
        self.setTitle = NO;
        [self schedule:@selector(nextFrame:)];
        self.navigationDisplay = [NavigationDisplay createWithTarget:self andSelector:@selector(backNavigation)];
        [self.navigationDisplay insert:self];
    }
	return self;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void) nextFrame:(ccTime)dt {
    NSInteger runningActions = [self.tharsisSprite numberOfRunningActions];
    runningActions += [self.elysiumSprite numberOfRunningActions];
    runningActions += [self.memnoniaSprite numberOfRunningActions];
	if (runningActions == 0) {
        if (self.setTitle) {
            [self addTitle];
            self.setTitle = NO;
        } 
	}
}

//-----------------------------------------------------------------------------------------------------------------------------------
-(void) ccTouchesBegan:(NSSet*)touches withEvent:(UIEvent *)event {
	self.firstTouch = [TouchUtils locationFromTouches:touches]; 
}    

//-----------------------------------------------------------------------------------------------------------------------------------
-(void) ccTouchesEnded:(NSSet*)touches withEvent:(UIEvent *)event {
	CGPoint touchLocation = [TouchUtils locationFromTouches:touches];
    CGPoint touchDelta = ccpSub(touchLocation, self.firstTouch);
    if (abs(touchDelta.y) < 20) {
        if ([self displayedQuadIsUnlocked]) {
            [UserModel setQuadrangle:self.displayedQuad];
            [[CCDirector sharedDirector] replaceScene:[MissionsScene scene]];
        }
    } else if (touchDelta.y < 0) {
        [self.titleLabel removeFromParentAndCleanup:YES];
        [self backwardQuads];
        self.setTitle = YES;
    } else {
        [self.titleLabel removeFromParentAndCleanup:YES];
        [self fowardQuads];
        self.setTitle = YES;
    }
}    

//-----------------------------------------------------------------------------------------------------------------------------------
-(void) ccTouchesMoved:(NSSet*)touches withEvent:(UIEvent *)event {
}

@end
