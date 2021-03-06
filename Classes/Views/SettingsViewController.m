//
//  SettingsViewController.m
//  seeker1
//
//  Created by Troy Stribling on 3/3/11.
//  Copyright 2011 imaginary products. All rights reserved.
//

//-----------------------------------------------------------------------------------------------------------------------------------
#import "SettingsViewController.h"
#import "UserModel.h"
#import "LevelModel.h"
#import "ProgramModel.h"
#import "AudioManager.h"

//-----------------------------------------------------------------------------------------------------------------------------------
#define kSETTINGS_LAUNCHER_BACK_TAG     1

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface SettingsViewController (PrivateAPI)

- (void)showLevelManage;
- (void)hideLevelManage;

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation SettingsViewController

//-----------------------------------------------------------------------------------------------------------------------------------
@synthesize speedSlider;
@synthesize audioButton;
@synthesize resetLevelsButton;
@synthesize enableLevelsButton;
@synthesize containerView;

//===================================================================================================================================
#pragma mark SettingsViewController PrivateAPI

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)showLevelManage {
    self.resetLevelsButton.hidden = NO;
    self.enableLevelsButton.hidden = NO;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)hideLevelManage {
    self.resetLevelsButton.hidden = YES;
    self.enableLevelsButton.hidden = YES;
}

//===================================================================================================================================
#pragma mark SettingsViewController

//-----------------------------------------------------------------------------------------------------------------------------------
+ (id)inView:(UIView*)_containerView {
    SettingsViewController* viewController = 
        [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil inView:_containerView];
    return viewController;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil inView:(UIView*)_containerView {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        self.containerView = _containerView;
        self.view.frame = self.containerView.frame;
        UIImage* stetchLeftTrack = [[UIImage imageNamed:@"slider-left.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0];
        UIImage* stetchRightTrack = [[UIImage imageNamed:@"slider-right.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0];
        [self.speedSlider setMinimumTrackImage:stetchLeftTrack forState:UIControlStateNormal];
        [self.speedSlider setMaximumTrackImage:stetchRightTrack forState:UIControlStateNormal];
    }
    return self;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (IBAction)speedValueChanged:(UISlider*)sender {  
    CGFloat speedValue = [sender value];
    CGFloat newSpeed = kSEEKER_MIN_SPEED_SCALE + kSEEKER_DELTA_SPEED_SCALE * speedValue; 
    [UserModel setSpeedScaleFactor:newSpeed];
}  

//-----------------------------------------------------------------------------------------------------------------------------------
- (IBAction)audioButtonPushed:(UIButton*)sender { 
    if ([UserModel audioEnabled]) {
        [UserModel setAudioEnabled:NO];
        self.audioButton.selected = NO;
    } else {
        [UserModel setAudioEnabled:YES];
        self.audioButton.selected = YES;
    }
}  

//-----------------------------------------------------------------------------------------------------------------------------------
- (IBAction)resetButtonPushed:(UIButton*)sender {  
    [LevelModel destroyAll];
    [ProgramModel destroyAll];
    [UserModel disableTutorials];
}  

//-----------------------------------------------------------------------------------------------------------------------------------
- (IBAction)enableButtonPushed:(UIButton*)sender {  
    for (int i = 0; i < kMISSIONS_PER_QUAD * kQUADS_TOTAL; i++) {
        [LevelModel insertForLevel:(i+1)];
    }
    [UserModel enableTutorials];
}  

//===================================================================================================================================
#pragma mark UIViewController

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad {
    [super viewDidLoad];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated {
    self.speedSlider.value = ((float)[UserModel speedScaleFactor] - kSEEKER_MIN_SPEED_SCALE)/kSEEKER_DELTA_SPEED_SCALE;
    if ([UserModel audioEnabled]) {
        self.audioButton.selected = YES;
    } else {
        self.audioButton.selected = NO;
    }
    [self hideLevelManage];
	[super viewWillAppear:animated];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

//===================================================================================================================================
#pragma mark UIResponder

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    UITouch* touch = [touches anyObject];
    NSInteger numberOfTaps = [touch tapCount];
    NSInteger touchTag = touch.view.tag;
    switch (touchTag) {
        case kSETTINGS_LAUNCHER_BACK_TAG:
            [self.view removeFromSuperview];
            [[AudioManager instance] playEffect:SelectAudioEffectID];
            break;
        default:
            if (numberOfTaps == 3) {
                if ( self.resetLevelsButton.hidden) {
                    [self showLevelManage];
                } else {
                    [self hideLevelManage];
                }
            }
            break;
    }
}

@end
