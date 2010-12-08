//
//  TerminalViewController.m
//  seeker1
//
//  Created by Troy Stribling on 12/5/10.
//  Copyright 2010 imaginary products. All rights reserved.
//

//-----------------------------------------------------------------------------------------------------------------------------------
#import "TerminalViewController.h"
#import "FunctionsViewController.h"
#import "ViewControllerManager.h"
#import "TerminalCell.h"
#import "CellUtils.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TerminalViewController (PrivateAPI)

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TerminalViewController

//-----------------------------------------------------------------------------------------------------------------------------------
@synthesize programView;
@synthesize containerView;
@synthesize programListing;
@synthesize functionUpdate;
@synthesize rowUpdated;

//===================================================================================================================================
#pragma mark TerminalViewController PrivateAPI

//===================================================================================================================================
#pragma mark TerminalViewController

//-----------------------------------------------------------------------------------------------------------------------------------
+ (id)inView:(UIView*)_containerView {
    return [[TerminalViewController alloc] initWithNibName:@"TerminalViewController" bundle:nil inView:_containerView];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil inView:(UIView*)_containerView {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        self.containerView = _containerView;
        self.view.frame = self.containerView.frame;
        self.programListing = [NSMutableArray arrayWithCapacity:10];
    }
    return self;
}

//===================================================================================================================================
#pragma mark UIViewController

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad {
    [TerminalLauncherView inView:self.view andDelegate:self];
    self.programView.separatorColor = [UIColor blackColor];
    [super viewDidLoad];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated {
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
#pragma mark LauncherViewDelegate 

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)viewTouchedNamed:(NSString*)name {
    if ([name isEqualToString:@"back"]) {
        [self.view removeFromSuperview];
    } else if ([name isEqualToString:@"run"]) {
    }
}

//===================================================================================================================================
#pragma mark UITableViewDataSource

//-----------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.programListing count] + 1;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TerminalCell* cell = (TerminalCell*)[CellUtils createCell:[TerminalCell class] forTableView:tableView];
    if (indexPath.row == [self.programListing count]) {
        cell.lineLabel.text = @"$";
    } else {
        cell.lineLabel.text = [NSString stringWithFormat:@"$ %@", [self.programListing objectAtIndex:indexPath.row]];
    }
    return cell;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
    }   
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath*)toIndexPath {
}


//-----------------------------------------------------------------------------------------------------------------------------------
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

//===================================================================================================================================
#pragma mark UITableViewDelegate

//-----------------------------------------------------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.rowUpdated = indexPath.row;
    [[ViewControllerManager instance] showFunctionsView:self];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return kTERMINAL_LINE_CELL_HEIGHT;
}

//===================================================================================================================================
#pragma mark NSObject

@end

