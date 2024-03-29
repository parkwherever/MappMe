//
//  MainMenuViewController.m
//  MappMe
//
//  Created by Parker Spielman on 4/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MainMenuViewController.h"

@interface MainMenuViewController (){
    IBOutlet UIButton* hometownBtn;
    IBOutlet UIButton* currentLocationBtn;
    IBOutlet UIButton* collegeBtn;
    IBOutlet UIButton* highschoolBtn;
}

@end

@implementation MainMenuViewController

@synthesize container;
@synthesize delegate;
@synthesize selectedLocType;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //FIXME highlight of selected buttons
        currentLocationBtn.selected = TRUE;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
#pragma mark - control logic
-(void)updateButtonHighlight
{
    switch (self.selectedLocType) {
        case tHomeTown:
            hometownBtn.highlighted = TRUE;
            break;
        case tCurrentLocation:
            currentLocationBtn.highlighted = TRUE;
            break;
        case tCollege:
            collegeBtn.highlighted = TRUE;
            break;
        case tHighSchool:
            highschoolBtn.highlighted = TRUE;
            break;
        default:
            break;
    }
}

- (IBAction)showHomeTown:(id)sender
{
    [self.delegate didSelectLocType:tHomeTown];
    [self.container closeMenu];
}

- (IBAction)showCurrentLocation:(id)sender
{
    [self.delegate didSelectLocType:tCurrentLocation];
    [self.container closeMenu];
    
}

- (IBAction)showCollege:(id)sender
{
    [self.delegate didSelectLocType:tCollege];
    [self.container closeMenu];
}

- (IBAction)showHighSchool:(id)sender
{
    [self.delegate didSelectLocType:tHighSchool];
    [self.container closeMenu];
}

@end
