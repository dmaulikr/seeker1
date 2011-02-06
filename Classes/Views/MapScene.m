//
//  MapScene.m
//  seeker1
//
//  Created by Troy Stribling on 11/14/10.
//  Copyright imaginary products 2010. All rights reserved.
//

//-----------------------------------------------------------------------------------------------------------------------------------
#import "MapScene.h"
#import "EndOfLevelScene.h"
#import "UserModel.h"
#import "LevelModel.h"
#import "ProgramModel.h"
#import "TermMenuView.h"
#import "SeekerSprite.h"
#import "StatusDisplay.h"
#import "ProgramNgin.h"
#import "TouchUtils.h"

//-----------------------------------------------------------------------------------------------------------------------------------
#define kMAP_INVERSE_PAN_SPEED   0.001
#define kEND_OF_LEVEL_COUNT      50
#define kSEEKER_DELTA_SPEED      5
#define kSEEKER_DELTA_ENERGY     2
#define kSEEKER_DELTA_ENERGY_MIN 1
#define kSEEKER_DELTA_ENERGY_MAX 4

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface MapScene (PrivateAPI)

// inialize
- (void)initLevel;
- (void)setSeekerStartPosition;
- (void)initStatusDisplay;
- (CCTMXTiledMap*)initMap;
- (void)centerTileMapOnStartPoint;
- (void)centerOnSeekerPosition;
// reset
- (void)resetMap;
- (void)resetSeekerStartPosition;
// coordinate transforms
- (CGPoint)getPointFromObjectPropertiesInScreenCoords:(NSDictionary*)dict;
- (CGPoint)getPointFromObjectPropertiesInTileCoords:(NSDictionary*)dict;
- (CGPoint)screenCoordsToTileCoords:(CGPoint)_point;
- (CGPoint)tileCoordsToTile:(CGPoint)point;
- (CGPoint)tileMapTranslatedToPoint:(CGPoint)_point;
// program instructions
- (BOOL)shouldMoveMap:(CGPoint)_delta;
- (BOOL)moveIsInPlayingAreaForData:(CGPoint)_delta;
- (void)executeSeekerInstruction:(ccTime)dt;
- (void)updatePathForPosition:(CGPoint)_position;
- (CGFloat)useEnergy:(NSInteger)_gradient;
- (NSInteger)speedDelta:(NSInteger)_gradient;
- (BOOL)isItemTile:(NSDictionary*)_itemProperties ofType:(NSString*)_itemType;
- (BOOL)isStationTile:(NSDictionary*)_itemProperties;
- (void)move;
- (void)moveMapTo:(CGPoint)_point withDuration:(CGFloat)_duration;
- (void)putSensor:(NSDictionary*)_properties atPoint:(CGPoint)_point;
- (void)getSample:(NSDictionary*)_properties atPoint:(CGPoint)_point;
- (void)halt;
- (NSInteger)mapIDToInteger:(NSString*)_mapID;
// display parameter updates
- (void)updateEnergy;
- (void)updateSpeed;
- (void)updateSensorCount;
- (void)updateSampleCount;
// seeker crash
- (void)crashCompleted;
- (void)crashHitMapBoundary;
- (void)crashNoEnergy;
- (void)crashSpeedHigh;
- (void)crashSpeedLow;
- (void)crashProgram;
- (void)crashTerrain;
- (void)crashSensorBinEmpty;
- (void)crashNoSensorSiteAtPosition;
- (void)crashSensorSiteAtPositionMissed;
- (void)crashSampleBinFull;
- (void)crashNoSampleAtPosition;
- (void)crashSampleAtPositionMissed;
// crash animations
- (void)fadeToRed;
// level completed animations
- (void)runLevelCompletedAnimation;
- (void)levelCompletedAnimation;
// menu
- (void)initTerminalItems;
- (void)addResetTerminalItems;
- (void)addRunTerminalItems;
// move map on touch
- (void)onTouchMoveMapUp;
- (void)onTouchMoveMapDown;
- (void)onTouchMoveMapLeft;
- (void)onTouchMoveMapRight;
- (void)onTouchMoveMap;
- (CGPoint)onTouchMoveDeltaToPlayingArea;
- (void)centerOnSeekerPosition;
- (CGFloat)panDuration:(CGPoint)_delta;

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MapScene

//-----------------------------------------------------------------------------------------------------------------------------------
@synthesize seeker1;
@synthesize statusDisplay;
@synthesize startSite;
@synthesize seekerPath;
@synthesize level;
@synthesize endOfMissionCounter;
@synthesize menu;
@synthesize screenCenter;
@synthesize firstTouch;
@synthesize onTouchMoveDelta;
@synthesize tileMapSize;
@synthesize tileMap;
@synthesize mapLayer;
@synthesize terrainLayer;
@synthesize itemsLayer;
@synthesize sandLayer;
@synthesize objectsLayer;
@synthesize crash;
@synthesize levelResetSeeker;
@synthesize levelResetMap;
@synthesize levelInitSeeker;
@synthesize levelInitialized;
@synthesize levelCrash;
@synthesize levelCompleted;
@synthesize nextLevel;
@synthesize movingMapOnTouch;
@synthesize centeringOnSeekerPosition;
@synthesize ignoreTouches;

//===================================================================================================================================
#pragma mark MapScene PrivateAPI
//-----------------------------------------------------------------------------------------------------------------------------------
// initialize
//-----------------------------------------------------------------------------------------------------------------------------------
#pragma mark initialize

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)initLevel {
    self.level = [UserModel level];
    [LevelModel insertForLevel:self.level];
    self.tileMap = [self initMap];
    CGSize tileMapTiles = self.tileMap.mapSize;
    CGSize tileMapTileSize = self.tileMap.tileSize;
    self.tileMapSize = CGSizeMake(tileMapTiles.width*tileMapTileSize.width, tileMapTiles.height*tileMapTileSize.height);
    [self centerTileMapOnStartPoint];
    [self.seekerPath removeAllObjects];
    ProgramModel* model = [ProgramModel findByLevel:self.level];
    if (model) {
        ProgramNgin* ngin = [ProgramNgin instance];
        NSMutableArray* programListing = [model codeListingToInstrictions];
        [ngin saveProgram:programListing];
        [ngin loadProgram:programListing];
        [self addRunTerminalItems];
        [self.menu addRunItems];
    } else {
        [self initTerminalItems];
        [self.menu mapInitItems];
    }
    [self addChild:self.tileMap z:-1 tag:kMAP];
    self.levelInitSeeker = YES;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (CCTMXTiledMap*)initMap {
    NSString* mapName = [NSString stringWithFormat:@"map-%d.tmx", self.level];
    CCTMXTiledMap* map = [CCTMXTiledMap tiledMapWithTMXFile:mapName];
    self.mapLayer = [map layerNamed:@"map"];
    self.terrainLayer = [map layerNamed:@"terrain"];
    self.itemsLayer = [map layerNamed:@"items"];
    self.sandLayer = [map layerNamed:@"sand"];
    self.objectsLayer = [map objectGroupNamed:@"objects"];
    self.startSite = [self.objectsLayer objectNamed:@"startSite"];
    return map;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)setSeekerStartPosition {
    self.levelInitSeeker = NO;
    self.seeker1 = [SeekerSprite create];
    [self.seeker1 initParams:self.startSite];
    [self initStatusDisplay];
    CGPoint startPoint = [self getPointFromObjectPropertiesInScreenCoords:self.startSite];
    NSString* bearing = [self.startSite valueForKey:@"bearing"];
    [self.seeker1 setToStartPoint:startPoint withBearing:bearing];
    self.levelInitialized = YES;
    [self addChild:self.seeker1 z:0];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)initStatusDisplay {
    [self.statusDisplay setDigits:self.seeker1.energyTotal forDisplay:EnergyDisplayType];
    [self.statusDisplay setDigits:self.seeker1.speed forDisplay:SpeedDisplayType];
    [self.statusDisplay setDigits:self.seeker1.sensorSites forDisplay:SensorDisplayType];
    [self.statusDisplay setDigits:self.seeker1.sampleSites forDisplay:SampleDisplayType];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)centerTileMapOnStartPoint {
    CGPoint startPoint = [self getPointFromObjectPropertiesInTileCoords:self.startSite];
    CGPoint mapTranslated = [self tileMapTranslatedToPoint:startPoint];
    [self moveMapTo:mapTranslated withDuration:1.0];
}

//-----------------------------------------------------------------------------------------------------------------------------------
// reset
//-----------------------------------------------------------------------------------------------------------------------------------
#pragma mark reset

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)resetMap {
    self.levelResetMap = NO;
    if (self.crash){
        [self.crash removeFromParentAndCleanup:YES];
        self.crash = nil;
    } else {
        [self.seeker1 removeFromParentAndCleanup:YES];
    }
    CCTMXTiledMap* newTileMap = [self initMap];
    [self addChild:newTileMap z:-1 tag:kMAP];
    [self.tileMap removeFromParentAndCleanup:YES];
    self.tileMap = newTileMap;
    [self centerTileMapOnStartPoint];
    [self initStatusDisplay];
    [self.seeker1 initParams:self.startSite];
    self.levelResetSeeker = YES;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)resetSeekerStartPosition {
    self.levelResetSeeker = NO;
    CGPoint startPoint = [self getPointFromObjectPropertiesInScreenCoords:self.startSite];
    NSString* bearing = [self.startSite valueForKey:@"bearing"];
    [self.seeker1 resetToStartPoint:startPoint withBearing:bearing];
    [self addChild:self.seeker1];
}

//-----------------------------------------------------------------------------------------------------------------------------------
// coordinate transforms
//-----------------------------------------------------------------------------------------------------------------------------------
#pragma mark coordinate transforms

//-----------------------------------------------------------------------------------------------------------------------------------
- (CGPoint)getPointFromObjectPropertiesInScreenCoords:(NSDictionary*)dict {
	CGFloat x = [[dict valueForKey:@"x"] floatValue];
    CGFloat y = [[dict valueForKey:@"y"] floatValue];
    CGPoint mapPos = self.tileMap.position;
	return CGPointMake(x + mapPos.x, y + mapPos.y);
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (CGPoint)getPointFromObjectPropertiesInTileCoords:(NSDictionary*)dict {
	CGFloat x = [[dict valueForKey:@"x"] floatValue];
    CGFloat y = [[dict valueForKey:@"y"] floatValue];
	return CGPointMake(x, y);
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (CGPoint)screenCoordsToTileCoords:(CGPoint)_screenPoint {
    CGPoint tileMapPos = self.tileMap.position;
    CGPoint screenCoords = ccpSub(_screenPoint, tileMapPos);
	return CGPointMake(screenCoords.x, self.tileMapSize.height - screenCoords.y);
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (CGPoint)tileCoordsToTile:(CGPoint)_point {
	CGFloat tileWidth = self.tileMap.tileSize.width;
	CGFloat tileHeight = self.tileMap.tileSize.height;	
	return CGPointMake((int)(_point.x/tileWidth), (int)(_point.y/tileHeight));
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (CGPoint)tileMapTranslatedToPoint:(CGPoint)_point {
    CGPoint mapTranslated = ccpSub(self.screenCenter, _point);
    if (_point.x < self.screenCenter.x) {
        mapTranslated.x = 0.0;
    } else if ((self.tileMapSize.width - _point.x) < self.screenCenter.x) {
        mapTranslated.x = - (self.tileMapSize.width - 2.0 * self.screenCenter.x);
    } 
    if (_point.y < self.screenCenter.y) {
        mapTranslated.y = 0.0;
    } else if ((self.tileMapSize.height - _point.y) < self.screenCenter.y) {
        mapTranslated.y = - (self.tileMapSize.height - 2.0 * self.screenCenter.y);
    } 
    return mapTranslated;
}

//-----------------------------------------------------------------------------------------------------------------------------------
// program instructions
//-----------------------------------------------------------------------------------------------------------------------------------
#pragma mark program instructions

//-----------------------------------------------------------------------------------------------------------------------------------
- (BOOL)shouldMoveMap:(CGPoint)_delta {
    CGPoint newPosition = ccpAdd([self screenCoordsToTileCoords:self.seeker1.position], CGPointMake(_delta.x, -_delta.y));
    CGPoint seekerScreen = self.seeker1.position;
    if (self.seeker1.bearing == WestSeekerBearing) {        
        if (newPosition.x < self.screenCenter.x) {
            return NO;
        } else if ((self.screenCenter.x - seekerScreen.x) < 0) {
            return NO;
        }
    } else if (self.seeker1.bearing == EastSeekerBearing) {
        if ((self.tileMapSize.width - newPosition.x) < self.screenCenter.x) {
            return NO;
        } else if ((self.screenCenter.x - seekerScreen.x) > 0) {
            return NO;
        }
    } else if (self.seeker1.bearing == NorthSeekerBearing) {
        if (newPosition.y < self.screenCenter.y) {
            return NO;
        } else if ((self.screenCenter.y - seekerScreen.y) > 0) {
            return NO;
        }
    } else if (self.seeker1.bearing == SouthSeekerBearing) {
        if ((self.tileMapSize.height - newPosition.y) < self.screenCenter.y) {
            return NO;
        } else if ((self.screenCenter.y - seekerScreen.y) < 0) {
            return NO;
        }
    }
    return YES;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (BOOL)moveIsInPlayingAreaForData:(CGPoint)_delta {
    CGPoint tilePosition = [self nextPositionForDelta:_delta];
    return [self positionIsInPlayingArea:tilePosition];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)executeSeekerInstruction:(ccTime)dt {
    [self addResetTerminalItems];
    [self.menu addResetItems];
    NSMutableArray* instructionSet = nil;
    ProgramNgin* ngin = [ProgramNgin instance];
    CGPoint seekerTile = [self getSeekerTile];
    NSDictionary* itemProperties = [self getTileProperties:seekerTile forLayer:self.itemsLayer];
    if ((instructionSet = [ngin nextInstruction:self])) {
        ProgramInstruction instruction = [[instructionSet objectAtIndex:0] intValue];
        switch (instruction) {
            case MoveProgramInstruction:
                [self move];
                break;
            case TurnLeftProgramInstruction:
                [self.seeker1 turnLeft];
                break;
            case PutSensorProgramInstruction:
                [self putSensor:itemProperties atPoint:seekerTile];
                break;
            case GetSampleProgramInstruction:
                [self getSample:itemProperties atPoint:seekerTile];
                break;
            case DoTimesProgramInstruction:
                break;
            case DoUntilProgramInstruction:
                break;
            default:
                break;
        }
    } else {
        [self halt];
        [self crashProgram];
    }
    if ([self isStationTile:itemProperties]) {
        [self.seeker1 emptySampleBin];
        [self.seeker1 loadSensorBin];
    }
    if ([self.seeker1 isLevelCompleted]) {
        [[ProgramNgin instance] stopProgram];
        [LevelModel completeLevel:self.level forSeeker:self.seeker1];
        [self levelCompletedAnimation];
    }
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)updatePathForPosition:(CGPoint)_position {
    [self.seekerPath addObject:[NSValue valueWithCGPoint:_position]];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (CGFloat)useEnergy:(NSInteger)_gradient {
    CGFloat delta = kSEEKER_DELTA_ENERGY;
    if (_gradient < 0) {
        delta = kSEEKER_DELTA_ENERGY_MIN;
    } else if (_gradient > 0) {
        delta = kSEEKER_DELTA_ENERGY_MAX;
    }
    return delta;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)speedDelta:(NSInteger)_gradient {
    NSInteger delta = kSEEKER_DELTA_SPEED;
    if (_gradient < 0) {
        delta = -delta;
    }
    return delta;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (BOOL)isItemTile:(NSDictionary*)_itemProperties ofType:(NSString*)_itemType {
    BOOL status = NO;
    if (_itemProperties) {
        NSString* itemID = [_itemProperties valueForKey:@"itemID"];
        if ([itemID isEqualToString:_itemType]) {
            status = YES;
        }            
    }
    return status;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (BOOL)isStationTile:(NSDictionary*)_itemProperties {
    return [self isItemTile:_itemProperties ofType:@"station"];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)move {
    CGPoint delta = [self moveDelta];
    if ([self moveIsInPlayingAreaForData:delta]) {
        NSInteger gradient = [self terrainGradient];
        CGFloat usedEnergy = [self useEnergy:gradient];
        if ([self.seeker1 useEnergy:usedEnergy]) {
            NSInteger deltaSpeed = [self speedDelta:gradient];
            if ([self.seeker1 changeSpeed:deltaSpeed]) {
                [self updateEnergy];
                [self updateSpeed];
                if ([self isTerrainClear:gradient]) {
                    if ([self shouldMoveMap:delta]) {
                        CGPoint mapPosition = ccpAdd(CGPointMake(-delta.x, -delta.y), self.tileMap.position);
                        [self moveMapTo:mapPosition withDuration:1.0];
                    } else {
                        [self.seeker1 moveBy:self.tileMap.tileSize];
                    }
                    CGPoint seekerTile = [self getSeekerTile];
                    [self updatePathForPosition:seekerTile];
                } else {
                    [self halt];
                    [self crashTerrain];
                }
            } else {
                [self halt];
                if (self.seeker1.speed == kSEEKER_MAX_SPEED) {
                    [self crashSpeedHigh];
                } else {
                    [self crashSpeedLow];
                }
            }
        } else {
            [self halt];
            [self crashNoEnergy];
        }
    } else {
        [self halt];
        [self crashHitMapBoundary];
    }
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)moveMapTo:(CGPoint)_point withDuration:(CGFloat)_duration {
	[tileMap stopAllActions];
	[tileMap runAction:[CCMoveTo actionWithDuration:_duration position:_point]];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)putSensor:(NSDictionary*)_properties atPoint:(CGPoint)_point {
    if (_properties) {
        NSString* itemID = [_properties valueForKey:@"itemID"];
        if ([itemID isEqualToString:@"sensorSite"]) {   
            if ([self.seeker1 putSensor]) {
                [self.itemsLayer removeTileAt:_point];
                [self.itemsLayer setTileGID:kMAP_SENSOR_GID at:_point];
                [self updateSensorCount];
            } else {
                [self halt];
                [self crashSensorBinEmpty];
            }
        } else {
            [self halt];
            [self crashNoSensorSiteAtPosition];
        }
    } else {
        [self halt];
        [self crashNoSensorSiteAtPosition];
    }
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)getSample:(NSDictionary*)_properties atPoint:(CGPoint)_point {
    if (_properties) {
        NSString* itemID = [_properties valueForKey:@"itemID"];
        if ([itemID isEqualToString:@"sample"]) {        
            if ([self.seeker1 getSample]) {
                [self.itemsLayer removeTileAt:_point];
                [self updateSampleCount];
            } else {
                [self halt];
                [self crashSampleBinFull];
            }
        } else {        
            [self halt];
            [self crashNoSampleAtPosition];
        }
    } else {  
        [self halt];
        [self crashNoSampleAtPosition];
    }
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)halt {
    [[ProgramNgin instance] haltProgram];
    [LevelModel incompleteLevel:self.level forSeeker:self.seeker1];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)mapIDToInteger:(NSString*)_mapID {
    NSInteger mapInt = 0;
    if ([_mapID isEqualToString:@"up-1"]) {
        mapInt =  5;
    } else if ([_mapID isEqualToString:@"up-2"]) {
        mapInt =  4;
    } else if ([_mapID isEqualToString:@"up-3"]) {
        mapInt = 3;
    } else if ([_mapID isEqualToString:@"up-4"]) {
        mapInt = 2;
    } else if ([_mapID isEqualToString:@"up-5"]) {
        mapInt = 1;
    }
    return mapInt;
}

//-----------------------------------------------------------------------------------------------------------------------------------
// display parameter updates
//-----------------------------------------------------------------------------------------------------------------------------------
#pragma mark display parameter updates

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)updateEnergy {
    [self.statusDisplay setDigits:self.seeker1.energy forDisplay:EnergyDisplayType]; 
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)updateSpeed {
    [self.statusDisplay setDigits:self.seeker1.speed forDisplay:SpeedDisplayType]; 
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)updateSensorCount {
    [self.statusDisplay setDigits:self.seeker1.sensorsRemaining forDisplay:SensorDisplayType]; 
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)updateSampleCount {
    [self.statusDisplay setDigits:self.seeker1.samplesRemaining forDisplay:SampleDisplayType]; 
}

//-----------------------------------------------------------------------------------------------------------------------------------
// seeker crashes
//-----------------------------------------------------------------------------------------------------------------------------------
#pragma mark seeker crashes

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)crashCompleted {
    self.levelCrash = NO;
    [self.seeker1 removeFromParentAndCleanup:YES];
    [[CCDirector sharedDirector] replaceScene: [EndOfLevelScene scene]];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)crashHitMapBoundary {
    [self fadeToRed];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)crashNoEnergy {
    [self fadeToRed];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)crashSpeedHigh {
    [self fadeToRed];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)crashSpeedLow {
    [self fadeToRed];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)crashProgram {
    [self fadeToRed];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)crashTerrain {
    [self fadeToRed];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)crashSensorBinEmpty {
    [self fadeToRed];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)crashNoSensorSiteAtPosition {
    [self fadeToRed];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)crashSensorSiteAtPositionMissed {
    [self fadeToRed];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)crashSampleBinFull {
    [self fadeToRed];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)crashNoSampleAtPosition {
    [self fadeToRed];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)crashSampleAtPositionMissed {
    [self fadeToRed];
}

//-----------------------------------------------------------------------------------------------------------------------------------
// crash animations
//-----------------------------------------------------------------------------------------------------------------------------------
#pragma mark crash animations

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)fadeToRed {
    NSString* seekerName = [NSString stringWithFormat:@"red-seeker-1-%@.png", [self.seeker1 bearingToString]];
    self.crash = [[[CCSprite alloc] initWithFile:seekerName] autorelease];  
    self.crash.opacity = 0;
    self.crash.position = self.seeker1.position;
    [self addChild:self.crash];
	[self.crash runAction:[CCFadeIn actionWithDuration:1.0]];
    self.levelCrash = YES;
}

//-----------------------------------------------------------------------------------------------------------------------------------
// level completed animations
//-----------------------------------------------------------------------------------------------------------------------------------
#pragma mark level completed animations

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)runLevelCompletedAnimation {
    self.levelCompleted = NO;
    [self.seeker1 rotate:360.0];
    self.nextLevel = YES;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)levelCompletedAnimation {
    self.levelCompleted = YES;
}

//-----------------------------------------------------------------------------------------------------------------------------------
// menu
//-----------------------------------------------------------------------------------------------------------------------------------
#pragma mark menu

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)initTerminalItems {
    [self.statusDisplay addTerminalText:@"~> main"];
    [self.statusDisplay addTerminalText:@"~> term"];
    [self.statusDisplay addTerminalText:@"~>"];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)addResetTerminalItems {
    [self.statusDisplay addTerminalText:@"~> main"];
    [self.statusDisplay addTerminalText:@"~> term"];
    [self.statusDisplay addTerminalText:@"~> rset"];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)addRunTerminalItems {
    [self.statusDisplay addTerminalText:@"~> main"];
    [self.statusDisplay addTerminalText:@"~> term"];
    [self.statusDisplay addTerminalText:@"~> run"];
}

//-----------------------------------------------------------------------------------------------------------------------------------
// move map on touch
//-----------------------------------------------------------------------------------------------------------------------------------
#pragma mark move map on touch

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)onTouchMoveMapUp {
    self.onTouchMoveDelta = CGPointMake(0.0, 1.5*self.screenCenter.y);
    self.movingMapOnTouch = YES;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)onTouchMoveMapDown {
    self.onTouchMoveDelta = CGPointMake(0.0, -1.5*self.screenCenter.y);
    self.movingMapOnTouch = YES;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)onTouchMoveMapLeft {
    self.onTouchMoveDelta = CGPointMake(-1.5*self.screenCenter.x, 0.0);
    self.movingMapOnTouch = YES;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)onTouchMoveMapRight {
    self.onTouchMoveDelta = CGPointMake(1.5*self.screenCenter.x, 0.0);
    self.movingMapOnTouch = YES;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)onTouchMoveMap {
    CGPoint tileMapPosition = self.tileMap.position;
    CGPoint delta = [self onTouchMoveDeltaToPlayingArea];
    CGPoint newTileMapPosition = ccpAdd(tileMapPosition, delta);
    CGFloat duration = [self panDuration:delta];
    if ([self.seeker1 parent]) {
        [self.seeker1 runAction:[CCMoveBy actionWithDuration:duration position:delta]];
    } else if (self.crash) {
        [self.crash runAction:[CCMoveBy actionWithDuration:duration position:delta]];
    }
    [self moveMapTo:newTileMapPosition withDuration:duration];
    self.movingMapOnTouch = NO;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (CGPoint)onTouchMoveDeltaToPlayingArea {
    CGPoint newTileMapPosition = ccpAdd(self.tileMap.position, self.onTouchMoveDelta);
    CGFloat xPos = MIN(0.0, newTileMapPosition.x);
    xPos = MAX(xPos, -(self.tileMapSize.width - 2.0*self.screenCenter.x - 1.0));
    CGFloat yPos = MIN(0.0, newTileMapPosition.y);
    yPos = MAX(yPos, -(self.tileMapSize.height - 2.0*self.screenCenter.y - 1.0));
    return ccpSub(CGPointMake(xPos, yPos), self.tileMap.position);
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)centerOnSeekerPosition {
    CGFloat duration = 0.0;
    CGPoint mapTranslated = CGPointMake(0.0, 0.0);
    CGPoint mapPosition = self.tileMap.position;
    if ([self.seeker1 parent]) {
        CGPoint seekerPosition = [self screenCoordsToTileCoords:self.seeker1.position];
        mapTranslated = [self tileMapTranslatedToPoint:CGPointMake(seekerPosition.x, self.tileMapSize.height - seekerPosition.y)];
        CGPoint delta = ccpSub(mapTranslated, mapPosition);
        duration = [self panDuration:delta];
        [self.seeker1 runAction:[CCMoveBy actionWithDuration:duration position:delta]];
    } else if (self.crash) {
        CGPoint crashPosition = [self screenCoordsToTileCoords:self.crash.position];
        mapTranslated = [self tileMapTranslatedToPoint:CGPointMake(crashPosition.x, self.tileMapSize.height - crashPosition.y)];
        CGPoint delta = ccpSub(mapTranslated, mapPosition);
        duration = [self panDuration:delta];
        [self.crash runAction:[CCMoveBy actionWithDuration:duration position:delta]];
    }
    [self moveMapTo:mapTranslated withDuration:duration];
    self.centeringOnSeekerPosition = NO;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (CGFloat)panDuration:(CGPoint)_delta {
    CGFloat distance = sqrt(pow(_delta.x, 2.0) + pow(_delta.y, 2.0));
    return distance * kMAP_INVERSE_PAN_SPEED;
}

//===================================================================================================================================
#pragma mark MapScene

//-----------------------------------------------------------------------------------------------------------------------------------
+ (id)scene {
	CCScene *scene = [CCScene node];
	MapScene *layer = [MapScene node];
	[scene addChild: layer];
	return scene;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (id)init {
	if((self=[super init])) {
        self.isTouchEnabled = YES;
		CGSize screenSize = [[CCDirector sharedDirector] winSize];
		self.screenCenter = CGPointMake(screenSize.width/2, screenSize.height/2);
        self.seekerPath = [NSMutableArray arrayWithCapacity:10];
        self.statusDisplay = [StatusDisplay create];
        self.menu = [TermMenuView create];
        self.menu.mapScene = self;
        self.levelResetSeeker = NO;
        self.levelResetMap = NO;
        self.levelInitSeeker = NO;
        self.levelInitialized = NO;
        self.levelCrash = NO;
        self.levelCompleted = NO;
        self.nextLevel = NO;
        self.movingMapOnTouch = NO;
        self.centeringOnSeekerPosition = NO;
        self.ignoreTouches = YES;
        self.endOfMissionCounter = 0;
        [self.statusDisplay insert:self];
        [[ProgramNgin instance] deleteProgram];
        [self initLevel];
        [self schedule:@selector(nextFrame:)];
	}
	return self;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void) nextFrame:(ccTime)dt {
    NSInteger mapActions = [self.tileMap numberOfRunningActions];
    NSInteger seekerActions = [self.seeker1 numberOfRunningActions];
    NSInteger crashActions = 0;
    if (self.crash) {crashActions = [self.crash numberOfRunningActions];}
	if (mapActions == 0 && seekerActions == 0 && crashActions == 0) {
        ProgramNgin* ngin = [ProgramNgin instance];
        if (self.levelInitSeeker) {
            [self setSeekerStartPosition];
        } else if (self.levelInitialized) {
            self.ignoreTouches = NO;
            self.levelInitialized = NO;
        } else if (self.levelCrash) {
            [self crashCompleted];
        } else if (self.levelResetMap) {
            [self resetMap];
        } else if (self.levelResetSeeker) {
            [self resetSeekerStartPosition];
        } else if (self.levelCompleted) {
            [self runLevelCompletedAnimation];
        } else if (self.endOfMissionCounter == kEND_OF_LEVEL_COUNT) {
            [[CCDirector sharedDirector] replaceScene: [EndOfLevelScene scene]];
        } else if (self.nextLevel) {
            self.endOfMissionCounter++;
        } else if (self.movingMapOnTouch) {
            [self onTouchMoveMap];
        } else if (self.centeringOnSeekerPosition) {
            [self centerOnSeekerPosition];
        } else if ([ngin programIsRunning]) {
            [self executeSeekerInstruction:dt];
        }
	}
}

//-----------------------------------------------------------------------------------------------------------------------------------
-(void) ccTouchesBegan:(NSSet*)touches withEvent:(UIEvent *)event {
    if (!self.ignoreTouches) {
        self.firstTouch = [TouchUtils locationFromTouches:touches]; 
    }
}    

//-----------------------------------------------------------------------------------------------------------------------------------
-(void) ccTouchesEnded:(NSSet*)touches withEvent:(UIEvent *)event {
    if (!self.ignoreTouches) {
        CGPoint touchLocation = [TouchUtils locationFromTouches:touches]; 
        if ([self.menu isInMenuRect:touchLocation]) {
            [self.menu showMenu];
        } else if (self.menu.menuIsOpen) {
            [self.menu hideMenu];
        } else {
            NSInteger numberOfTouches = [[touches anyObject] tapCount];
            CGPoint touchDelta = ccpSub(touchLocation, self.firstTouch);
            if (abs(touchDelta.y) > 20 || abs(touchDelta.x) > 20) {
                if (abs(touchDelta.y) > abs(touchDelta.x)) {
                    if (touchDelta.y > 0) {
                        [self onTouchMoveMapUp];
                    } else {
                        [self onTouchMoveMapDown];
                    }
                } else {
                    if (touchDelta.x > 0) {
                        [self onTouchMoveMapRight];
                    } else {
                        [self onTouchMoveMapLeft];
                    }
                }
            } else if (numberOfTouches == 2) {
                self.centeringOnSeekerPosition = YES;
            }
        }
    }
}    

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)resetLevel {
    self.levelResetMap = YES;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (NSDictionary*)getTileProperties:(CGPoint)_point forLayer:(CCTMXLayer*)_layer {
    NSDictionary* properties = nil;
    int tileGID = [_layer tileGIDAt:CGPointMake(_point.x, _point.y)];
    if (tileGID != 0) {
        properties = [self.tileMap propertiesForGID:tileGID];
    }
    return properties;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (CGPoint)getSeekerTile {
    return [self tileCoordsToTile:[self screenCoordsToTileCoords:self.seeker1.position]];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (BOOL)positionIsInPlayingArea:(CGPoint)_position {
    CGSize tiles = self.tileMap.mapSize; 
    if (_position.x < kMAP_EDGE_BUFFER || _position.x > (tiles.width - kMAP_EDGE_BUFFER - 1)) {
        return NO;
    } else if (_position.y < (kMAP_EDGE_BUFFER + 1) || _position.y > (tiles.height - kMAP_EDGE_BUFFER - 1)) {
        return NO;
    }
    return YES;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (CGPoint)moveDelta {
    return [self.seeker1 positionDeltaAlongBearing:self.tileMap.tileSize];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (CGPoint)nextPositionForDelta:(CGPoint)_delta {
    CGPoint newPosition = ccpAdd([self screenCoordsToTileCoords:self.seeker1.position], CGPointMake(_delta.x, -_delta.y));
    return [self tileCoordsToTile:newPosition];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (CGPoint)nextPosition {
    CGPoint delta = [self moveDelta];
    CGPoint newPosition = ccpAdd([self screenCoordsToTileCoords:self.seeker1.position], CGPointMake(delta.x, -delta.y));
    return [self tileCoordsToTile:newPosition];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)terrainGradient {
    NSInteger currentTerrain = 0;
    NSInteger nextTerrain = 0;
    CGPoint currentSeekerTile = self.seeker1.position;
    CGPoint nextSeekerTile = [self nextPosition];
    NSDictionary* currentTerrainProperties = [self getTileProperties:currentSeekerTile forLayer:self.terrainLayer];
    NSDictionary* nextTerrainProperties = [self getTileProperties:nextSeekerTile forLayer:self.terrainLayer];
    if (currentTerrainProperties) {
        NSString* currentTerrainID = [currentTerrainProperties valueForKey:@"mapID"];
        currentTerrain = [self mapIDToInteger:currentTerrainID];
    }
    if (nextTerrainProperties) {
        NSString* nextTerrainID = [nextTerrainProperties valueForKey:@"mapID"];
        nextTerrain = [self mapIDToInteger:nextTerrainID];
    }
    NSInteger gradient = nextTerrain - currentTerrain;
    return gradient;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (BOOL)isTerrainClear:(NSInteger)_gradient {
    BOOL isClear = YES;
    if (_gradient < -1 && _gradient > 1) {
        isClear = NO; 
    }
    return isClear;
}

@end
