/*
 * The main view controller of the app.
 * It is responsible for fetching data from facebook. Creating annotations and
 * addig these annotations to map view with animation.
 */

#import "MainViewController.h"
#import "DebugLog.h"
#import "MappMeAppDelegate.h"
#import "Timer.h"
#import "MyAnnotation.h"
#import "WebViewController.h"
#import "ListViewController.h"
#import "FacebookDataHandler.h"
#import "ZoomHelper.h"

#import <QuartzCore/QuartzCore.h>

@interface MainViewController()

-(void)showPins;
/*View Change Methods*/
-(void)showLocationType:(locTypeEnum)locType;
-(void)showHometown;
-(void)showCurrentLoc;
-(void)showHighSchool;
-(void)showCollege;
-(void)showGrad;

@end


@implementation MainViewController{
    MappMeAppDelegate *delegate;
    MBProgressHUD *HUD;
    NSMutableArray * annotations;
    NSString *selectedCity;
    NSString *selectedPerson;
    locTypeEnum currDisplayedType;
    
    IBOutlet UITableView *tableView;
    
    //Display private variables
    UIView *displayTypeContainer;
    UIView *personSearchContainer;
    BOOL displayTypeContainerIsShown;
    BOOL isFriendAnnotationType;
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [mapView setDelegate:self];
    annotations = [[NSMutableArray alloc]initWithCapacity:20];
    delegate = (MappMeAppDelegate *)[[UIApplication sharedApplication] delegate];
    HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:HUD];
    
    // Regiser for HUD callbacks so we can remove it from the window at the right time
    HUD.delegate = self;
    
    //Set Bools for view methods
    displayTypeContainerIsShown = FALSE;
    
    // Show the HUD while the provided method executes in a new thread
    [HUD showWhileExecuting:@selector(fetchAndProcess) onTarget:self withObject:nil animated:YES];
}

-(void) viewWillAppear:(BOOL)animated{
    [[self navigationController] setNavigationBarHidden:TRUE animated:TRUE];
}

-(void) viewWillDisappear:(BOOL)animated{
    [[self navigationController] setNavigationBarHidden:FALSE animated:TRUE];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    mapView = nil;
    locationTypeBtn = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


#pragma mark - Transition Functions
//All functions involving transition to another screen should go below

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
    if ([segue.identifier isEqualToString:@"showdetaillist"]) {
        ListViewController *controller = segue.destinationViewController;
        controller.selectedCity = selectedCity;
    } else if ([segue.identifier isEqualToString:@"showwebview"]){
        NSString *fId =[delegate.mainDataManager.peopleContainer getIdFromName:selectedPerson];
		NSString *urlStr = [[NSString alloc] initWithFormat:@"%@%@",@"http://m.facebook.com/profile.php?id=",fId];
		NSURL *url =[[NSURL alloc] initWithString:urlStr];
        WebViewController *controller = segue.destinationViewController;
        controller.url = url;
    } else if ([segue.identifier isEqualToString:@"searchview"]){
        FriendSearchViewController* controller = segue.destinationViewController;
        controller.searchDelegate = self;
    }
} 


/*
 * This method is invoked when the accesory button on annotation view is tapped.
 * Takes the user into a list of friends or the friend's facebook page directly
 */
- (void) showDetail:(id)sender {
//   
    NSArray *annotationStrings = [((UIButton*)sender).currentTitle componentsSeparatedByString:@"?"];
	selectedCity = [annotationStrings objectAtIndex:0];
    NSString * city_id = [delegate.mainDataManager.placeContainer getIdFromPlace:selectedCity];

    NSDictionary * currentGrouping = [delegate.mainDataManager.peopleContainer getCurrentGrouping];
    NSDictionary * peopleInPlace = [currentGrouping objectForKey:city_id];
	if([peopleInPlace count]>1){
        [self performSegueWithIdentifier:@"showdetaillist" sender:nil];
	}
	//only one person, go to the facebook page directly.!
	else {
		selectedPerson= [annotationStrings objectAtIndex:1] ;
        [self performSegueWithIdentifier:@"showwebview" sender:nil];
	}
}

#pragma mark - Methods to put pins when location type is changed

-(void)showHometown{
    [self showLocationType:tHomeTown];
}
-(void)showCurrentLoc{
    [self showLocationType:tCurrentLocation];
} 
-(void)showHighSchool{
    [self showLocationType:tHighSchool];
}
-(void)showCollege{
    [self showLocationType:tCollege];
}
-(void)showGrad{
    [self showLocationType:tGradSchool];
}

#pragma mark - Custom Person Search and Button Views 
-(NSArray*) getFriendsInCity:(NSString*) cityName{
    NSString * city_id = [delegate.mainDataManager.placeContainer getIdFromPlace:selectedCity];
    
    NSDictionary * currentGrouping = [delegate.mainDataManager.peopleContainer getCurrentGrouping];
    return [[currentGrouping objectForKey:city_id] allObjects];
}


//Helper method to create buttons for the location type menu (Used in showLocationMenu)
-(UIButton*) createButton:(NSString*)title yCordinate:(CGFloat)yCor locType: (locTypeEnum) locType {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [btn setTitle:title forState:UIControlStateNormal];
    btn.frame = CGRectMake(30.0, yCor, 180.0, 40.0);
    btn.highlighted = (locType == currDisplayedType);
    btn.enabled = (locType != currDisplayedType);
    return btn;
}

//Create a round close button to be used in location type menu
-(UIButton*) createCloseBtn {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.contentMode = UIViewContentModeScaleToFill;
    [button setBackgroundImage:[UIImage imageNamed:@"close.png"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(closeLocationMenu) forControlEvents:UIControlEventTouchUpInside];
    button.frame = CGRectMake(205, -15.0, 50.0, 50.0);//width and height should be same value
    button.layer.cornerRadius = 25;//half of the width
    return button;
}

-(void) closeLocationMenu {
    if(displayTypeContainerIsShown){
      [displayTypeContainer removeFromSuperview];
      displayTypeContainerIsShown = FALSE;
    }
}

//Adds subview of menu selection for current location, hometown, high school, etc.
-(IBAction)showLocationMenu{
    //Don't add subview twice
    if(displayTypeContainerIsShown){
        return;
    }
    displayTypeContainerIsShown = TRUE;
    
    displayTypeContainer = [[UIView alloc] initWithFrame:CGRectMake(40, 90, 240, 280)];
    [displayTypeContainer setAlpha:0.0];
    [displayTypeContainer.layer setBackgroundColor:[[UIColor clearColor] CGColor]];
    
    
    UIView *displayTypeView= [[UIView alloc] initWithFrame:CGRectMake(0, 0, 240, 280)];
    [displayTypeView setAlpha:0.65];
    [displayTypeContainer addSubview:displayTypeView];
    
    [displayTypeContainer addSubview:[self createCloseBtn]];
    
    /*Navigation Buttons*/
    UIButton *curButton = [self createButton:@"Current Location" yCordinate:20 locType:tCurrentLocation];
    [curButton addTarget:self action:@selector(showCurrentLoc) forControlEvents:UIControlEventTouchDown];
    [displayTypeContainer addSubview:curButton];
    
    UIButton *homeButton = [self createButton:@"Hometown" yCordinate:70 locType:tHomeTown];
    [homeButton addTarget:self  action:@selector(showHometown) forControlEvents:UIControlEventTouchDown];
    [displayTypeContainer addSubview:homeButton];
    
    UIButton *highButton = [self createButton:@"High School" yCordinate:120 locType:tHighSchool];
    [highButton addTarget:self  action:@selector(showHighSchool) forControlEvents:UIControlEventTouchDown];
    [displayTypeContainer addSubview:highButton];

    UIButton *collButton = [self createButton:@"College" yCordinate:170 locType:tCollege];
    [collButton addTarget:self  action:@selector(showCollege) forControlEvents:UIControlEventTouchDown];
    [displayTypeContainer addSubview:collButton];

    UIButton *gradButton = [self createButton:@"Graduate School" yCordinate:220 locType:tGradSchool];
    [gradButton addTarget:self  action:@selector(showGrad) forControlEvents:UIControlEventTouchDown];
    [displayTypeContainer addSubview:gradButton];
    /*End Navigation Buttons*/

    //Rounded Container Corners
    CALayer *dtc = displayTypeView.layer;
    [dtc setMasksToBounds:YES];
    [dtc setCornerRadius:8.0f];
    [dtc setBorderWidth:2.0f];
    [dtc setBorderColor: [[UIColor blackColor] CGColor]];
    [dtc setBackgroundColor: [[UIColor blueColor] CGColor]];
    
    //Add View To Screen
    [self.view addSubview:displayTypeContainer];
    [UIView beginAnimations:nil context:nil];
    [displayTypeContainer setAlpha:1.0];
    [UIView commitAnimations];

}


#pragma mark - Map pins methods
-(void)makeAnnotationFromDict:(NSDictionary*)groupings{
    //Using class as wrapper to process instances of itself
    annotations = [[NSMutableArray alloc] initWithCapacity:[[delegate.mainDataManager peopleContainer] getNumPeople]];
    NSArray* annotationItems = [MyAnnotation makeAnnotationFromDict:groupings]; 
    [annotations addObjectsFromArray:annotationItems];
}
-(void)getLocationsForFriend:(Friend *)friend{  
     annotations = [[NSMutableArray alloc] initWithCapacity:10];
    [annotations addObjectsFromArray:[MyAnnotation getLocationsForFriend:friend]];
}
-(void)showPins
{
    [mapView addAnnotations:annotations];
    [ZoomHelper zoomToFitAnnoations:mapView];
}
-(void)clearMap{
    [mapView removeAnnotations:annotations];
}
-(void)showLocationType:(locTypeEnum)locType{
    [[delegate.mainDataManager peopleContainer] printGroupings:locType];
    [self closeLocationMenu];
    [self clearMap];
    currDisplayedType = locType;
    isFriendAnnotationType = FALSE;
    NSString * buttonLabel= [LocationTypeEnum getNameFromEnum:currDisplayedType];
    [locationTypeBtn setTitle:buttonLabel forState:UIControlStateNormal];
    [locationTypeBtn setTitle:buttonLabel forState:UIControlStateHighlighted];
    [locationTypeBtn setTitle:buttonLabel forState:UIControlStateDisabled];
    [locationTypeBtn setTitle:buttonLabel forState:UIControlStateSelected];
    switch(locType){
        case tHomeTown:
            [self makeAnnotationFromDict:[delegate.mainDataManager.peopleContainer getFriendGroupingForLocType:tHomeTown]];
            break;
        case tCurrentLocation:
            [self makeAnnotationFromDict:[delegate.mainDataManager.peopleContainer getFriendGroupingForLocType:tCurrentLocation]];
            break;
        case tHighSchool:
            [self makeAnnotationFromDict:[delegate.mainDataManager.peopleContainer getFriendGroupingForLocType:tHighSchool]];
            break;
        case tCollege:
            [self makeAnnotationFromDict:[delegate.mainDataManager.peopleContainer getFriendGroupingForLocType:tCollege]];
            break;
        case tGradSchool:
            [self makeAnnotationFromDict:[delegate.mainDataManager.peopleContainer getFriendGroupingForLocType:tGradSchool]];
            break;
        case tWork:
           [self makeAnnotationFromDict:[delegate.mainDataManager.peopleContainer getFriendGroupingForLocType:tWork]];
            break;
        default:
            DebugLog(@"Warning: hitting default case");
    }
    [self showPins];
}

#pragma mark - main data processing dispatch
- (void)fetchAndProcess {
    Timer * t = [[Timer alloc] init];
    /*Call Methods for info*/
    FacebookDataHandler *fbDataHandler = [[FacebookDataHandler alloc] init];
    [fbDataHandler getCurrentLocation];
    [fbDataHandler getHometownLocation];
    [fbDataHandler getEducationInfo];

    [self performSelectorOnMainThread:@selector(showCurrentLoc) withObject:nil waitUntilDone:NO];
    int time = [t endTimerAndGetTotalTime];
    DebugLog(@"Total App Loadtime: %i",time);
}

#pragma mark MKMapViewDelegate
/*
 * This method will enable animation of dropping pins
 */
- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views { 
    MKAnnotationView *aV; 
    for (aV in views) {
        CGRect endFrame = aV.frame;
        
        aV.frame = CGRectMake(aV.frame.origin.x, aV.frame.origin.y - 230.0, aV.frame.size.width, aV.frame.size.height);
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.45];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [aV setFrame:endFrame];
        [UIView commitAnimations];
        
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(MyAnnotation *)annotation
{
	// if it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
	// try to dequeue an existing pin view first
	static NSString* AnnotationIdentifier = @"AnnotationIdentifier";
    
	UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
	NSString *cityNameAndFName=[[NSString alloc] initWithFormat:@"%@?%@",annotation.title,annotation.subtitle];
	[rightButton setTitle:cityNameAndFName forState:UIControlStateNormal];
	[rightButton addTarget:self
					action:@selector(showDetail:)
		  forControlEvents:UIControlEventTouchUpInside];
    
//	if (annotation.type==0){
//        
//        //The only reason we still need this duplicate block is that MKPinAnnotationView seem to 
//        //have a sequential animation that looks better.
//        
//		MKPinAnnotationView* pinView = [[MKPinAnnotationView alloc]
//										 initWithAnnotation:annotation reuseIdentifier:AnnotationIdentifier];
//		pinView.animatesDrop=YES;
//		pinView.canShowCallout=YES;
//		pinView.pinColor=MKPinAnnotationColorGreen;
//		pinView.rightCalloutAccessoryView = rightButton;
//        
//		UIImageView *profileIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"profile.png"]];
//		pinView.leftCalloutAccessoryView = profileIconView;
//        
//		return pinView;
//	}
//    
//	else{
    MKAnnotationView* pinView = [[MKPinAnnotationView alloc]
									  initWithAnnotation:annotation reuseIdentifier:AnnotationIdentifier];
    pinView.canShowCallout=YES;
    //check for different type of pin (sizes)
    
    pinView.rightCalloutAccessoryView = rightButton;
    pinView.image = [MyAnnotation getPinImage:annotation.type isFriendLocationType:isFriendAnnotationType];
   
    UIImageView *profileIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"profile.png"]];
    pinView.leftCalloutAccessoryView = profileIconView;
    //  pinView.tag = @"moreThanOnePerson";
    
    return pinView;
}

#pragma mark - FriendSearchViewControllerDelegate methods
- (void)didSelectFriend:(NSString *)uid {
    [self.navigationController popViewControllerAnimated:TRUE];
    [self clearMap];
    isFriendAnnotationType = TRUE;
    Friend* friend = [delegate.mainDataManager.peopleContainer getFriendFromId:uid];
    [self getLocationsForFriend: friend];
    [self showPins];
    NSString * buttonLabel= friend.name;
    [locationTypeBtn setTitle:buttonLabel forState:UIControlStateNormal];
    [locationTypeBtn setTitle:buttonLabel forState:UIControlStateHighlighted];
    [locationTypeBtn setTitle:buttonLabel forState:UIControlStateDisabled];
    [locationTypeBtn setTitle:buttonLabel forState:UIControlStateSelected];
}

@end
