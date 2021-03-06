//
//  SeekerSprite.h
//  seeker1
//
//  Created by Troy Stribling on 11/23/10.
//  Copyright 2010 imaginary products. All rights reserved.
//

//-----------------------------------------------------------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "cocos2d.h"

//-----------------------------------------------------------------------------------------------------------------------------------
typedef enum tagSeekerBearing {
    NorthSeekerBearing,
    SouthSeekerBearing,
    EastSeekerBearing,
    WestSeekerBearing,
} SeekerBearing;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface SeekerSprite : CCSprite {
    SeekerBearing bearing;
    NSInteger expectedCodeScore;
    NSInteger codeScore;
    NSInteger energyTotal;
    NSInteger energy;
    NSInteger sampleSites;
    NSInteger sampleBin;
    NSInteger samplesCollected;
    NSInteger samplesReturned;
    NSInteger samplesRemaining;
    NSInteger sensorSites;
    NSInteger sensorBin;
    NSInteger sensorsPlaced;
    NSInteger sensorsRemaining;
    NSInteger speed;
    BOOL idle;
}

//-----------------------------------------------------------------------------------------------------------------------------------
@property (nonatomic, assign) SeekerBearing bearing;
@property (nonatomic, assign) NSInteger expectedCodeScore;
@property (nonatomic, assign) NSInteger codeScore;
@property (nonatomic, assign) NSInteger energyTotal;
@property (nonatomic, assign) NSInteger energy;
@property (nonatomic, assign) NSInteger sampleSites;
@property (nonatomic, assign) NSInteger sampleBin;
@property (nonatomic, assign) NSInteger samplesCollected;
@property (nonatomic, assign) NSInteger samplesReturned;
@property (nonatomic, assign) NSInteger samplesRemaining;
@property (nonatomic, assign) NSInteger sensorSites;
@property (nonatomic, assign) NSInteger sensorBin;
@property (nonatomic, assign) NSInteger sensorsPlaced;
@property (nonatomic, assign) NSInteger sensorsRemaining;
@property (nonatomic, assign) NSInteger speed;
@property (nonatomic, assign) BOOL idle;

//-----------------------------------------------------------------------------------------------------------------------------------
// initialize/reset
+ (id)create;
- (void)setToStartPoint:(CGPoint)_point withBearing:(NSString*)_bearing;
- (void)resetToStartPoint:(CGPoint)_point withBearing:(NSString*)_bearing;
- (void)initParams:(NSDictionary*)_site;
// instructions
- (CGPoint)positionDeltaAlongBearing:(CGSize)_delta;
- (CGPoint)nextPositionForDelta:(CGSize)_delta;
- (void)moveBy:(CGPoint)_delta;
- (BOOL)useEnergy:(CGFloat)_deltaEnergy;
- (BOOL)changeSpeed:(CGFloat)_deltaSpeed;
- (void)turnLeft;
- (BOOL)getSample;
- (void)emptySampleBin;
- (BOOL)putSensor;
// utils
- (void)loadSensorBin;
- (BOOL)isLevelCompleted;
- (BOOL)isSensorBinEmpty;
- (BOOL)isSampleBinFull;
- (NSInteger)score;
// rotate
- (void)rotate:(CGFloat)_angle;
- (CGFloat)rotationFromNorthToBearing:(SeekerBearing)_bearing;
- (CGFloat)rotationToNorthFromBearing;
// bearing
- (SeekerBearing)stringToBearing:(NSString*)_bearingString;
- (NSString*)bearingToString;

@end
