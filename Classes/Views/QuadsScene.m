//
//  QuadsScene.m
//  seeker1
//
//  Created by Troy Stribling on 12/23/10.
//  Copyright 2010 imaginary products. All rights reserved.
//

//-----------------------------------------------------------------------------------------------------------------------------------
#import "QuadsScene.h"
#import "StatusDisplay.h"
#import "TouchUtils.h"
#import "LevelModel.h"
#import "MissionsScene.h"
#import "TermMenuView.h"

//-----------------------------------------------------------------------------------------------------------------------------------
#define kQUAD_IMAGE_YDELTA  75.0f

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

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation QuadsScene

//-----------------------------------------------------------------------------------------------------------------------------------
@synthesize statusDisplay;
@synthesize tharsisSprite;
@synthesize memnoniaSprite;
@synthesize elysiumSprite;
@synthesize displayedQuad;
@synthesize screenCenter;
@synthesize firstTouch;
@synthesize menu;

//===================================================================================================================================
#pragma mark QuadsScene PrivateAPI

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)initQuads {
    
    NSInteger levelsUnlocked = [LevelModel count];
    NSInteger quadsUnlocked = levelsUnlocked / kMISSIONS_PER_QUAD;
    CGFloat quadShiftDelta = self.tharsisSprite.contentSize.height + kQUAD_IMAGE_YDELTA;
    
    self.displayedQuad = TharsisQuadType;
    self.tharsisSprite.position = self.screenCenter;
    [self addChild:self.tharsisSprite z:-1];

    if (quadsUnlocked >= 1) {
        self.memnoniaSprite = [[[CCSprite alloc] initWithFile:@"memnonia.png"] autorelease];
    } else {
        self.memnoniaSprite = [[[CCSprite alloc] initWithFile:@"memnonia-locked.png"] autorelease];
    }
    if (quadsUnlocked >= 2) {
        self.elysiumSprite = [[[CCSprite alloc] initWithFile:@"elysium.png"] autorelease];
    } else {
        self.elysiumSprite = [[[CCSprite alloc] initWithFile:@"elysium-locked.png"] autorelease];
    }    
    self.memnoniaSprite.anchorPoint = CGPointMake(0.5f, 0.5f);
    self.tharsisSprite.anchorPoint = CGPointMake(0.5f, 0.5f);
    
    CGPoint nextPosition = CGPointMake(self.screenCenter.x, self.screenCenter.y - quadShiftDelta);
    self.memnoniaSprite.position = nextPosition;
    [self addChild:self.memnoniaSprite z:-1];

    nextPosition = CGPointMake(self.screenCenter.x, self.screenCenter.y - 2 * quadShiftDelta);
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
        self.statusDisplay = [StatusDisplay create];
        [self.statusDisplay insert:self];
        [self.statusDisplay addTerminalText:@"$ main"];
        [self.statusDisplay addTerminalText:@"$"];
        [self.statusDisplay test];
        [self initQuads];
        self.menu = [TermMenuView create];
        [self.menu quadsInitItems];
        [self schedule:@selector(nextFrame:)];
    }
	return self;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void) nextFrame:(ccTime)dt {
}

//-----------------------------------------------------------------------------------------------------------------------------------
-(void) ccTouchesBegan:(NSSet*)touches withEvent:(UIEvent *)event {
	self.firstTouch = [TouchUtils locationFromTouches:touches]; 
}    

//-----------------------------------------------------------------------------------------------------------------------------------
-(void) ccTouchesEnded:(NSSet*)touches withEvent:(UIEvent *)event {
	CGPoint touchLocation = [TouchUtils locationFromTouches:touches];
    if ([self.menu isInMenuRect:self.firstTouch]) {
        [self.menu showMenu];
    } else if (self.menu.menuIsOpen) {
        [self.menu hideMenu];
    } else {
        CGPoint touchDelta = ccpSub(touchLocation, self.firstTouch);
        if (abs(touchDelta.y) < 10) {
            if ([self displayedQuadIsUnlocked]) {
                [[CCDirector sharedDirector] replaceScene:[MissionsScene scene]];
            }
        } else if (touchDelta.y < 0) {
            [self backwardQuads];
        } else {
            [self fowardQuads];
        }
    }
}    

//-----------------------------------------------------------------------------------------------------------------------------------
-(void) ccTouchesMoved:(NSSet*)touches withEvent:(UIEvent *)event {
}

@end