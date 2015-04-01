//
//  MapViewController.m
//  Post Code
//
//  Created by Pablo Alejandro Perez Martinez on 27/09/14.
//  Copyright (c) 2014 Pablo A. Pérez-Martínez. All rights reserved.
//

#import "MapViewController.h"
#import "LocationTracker.h"

#import <MapKit/MapKit.h>

@interface MapViewController () <MKMapViewDelegate, UISearchBarDelegate>

@property (nonatomic, strong) IBOutlet MKMapView *map;
@property (nonatomic, strong) IBOutlet UISearchBar *bar;
@property (nonatomic, strong) IBOutlet UILabel *postCodeLabel;
@property (nonatomic, strong) IBOutlet UILabel *coordinateLabel;
@property (nonatomic, strong) IBOutlet UILabel *addressLabel;
@property (nonatomic, strong) IBOutlet UIView *postCodeView;
@property (nonatomic, strong) IBOutlet UIVisualEffectView *mapVisualEffectView;

@end

@implementation MapViewController {
    BOOL firstView;
}

@synthesize map;
@synthesize bar;
@synthesize postCodeLabel;
@synthesize coordinateLabel;
@synthesize addressLabel;
@synthesize mapVisualEffectView;
@synthesize postCodeView;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setup];
}

- (void)viewDidAppear:(BOOL)animated
{
    //[self centerMapOnUserLocation];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Class private methods

- (void)setup
{
    firstView = true;
    
    [self blurMap: NO];
    
    [self setPostCodeViewUp];
    
    [self registerNotifications];
}

- (void)registerNotifications
{
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(locationUpdated:)
                                                name:[LocationTracker locationUpdateNotificationName]
                                              object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(applicationDidBecomeActive:)
                                                name:UIApplicationDidBecomeActiveNotification
                                              object:nil];
}

- (void)applicationDidBecomeActive:(id)sender
{
    [self centerMapOnUserLocation];
}

- (void)locationUpdated:(NSNotification *)notification {
    
    NSLog(@"%s: Location update received...", __func__);
    
    //CLLocation *location = [notification.userInfo objectForKey:[LocationTracker newLocationUserInfoDictionaryKey]];
    
    if(firstView)
        [self centerMapOnUserLocation];
}

- (void)setPostCodeViewUp
{
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:postCodeView.bounds];
    postCodeView.layer.masksToBounds = NO;
    postCodeView.layer.shadowColor = [UIColor blackColor].CGColor;
    postCodeView.layer.shadowOffset = CGSizeMake(0.0f, .1f);
    postCodeView.layer.shadowOpacity = 0.5f;
    postCodeView.layer.shadowPath = shadowPath.CGPath;
}

- (void)centerMapOnUserLocation
{
    NSLog(@"%s", __func__);
    
    CLLocation *location = [LocationTracker sharedInstance].lastStoredLocation;
    
    if(!location)
        return;
    
    [self centerMapInCoordinate:location.coordinate];
}

- (void)centerMapInCoordinate:(CLLocationCoordinate2D)coordinate
{
    if(firstView) {
        
        firstView = false;
        
        MKCoordinateRegion region;
        MKCoordinateSpan span;
        span.latitudeDelta = .001;
        span.longitudeDelta = .001;
        region.span = span;
        region.center = coordinate;
        
        [self.map setRegion:region animated:YES];
    } else {
        [self.map setCenterCoordinate:coordinate animated:YES];
    }
    
}

- (IBAction)centerMapButtonPressed:(id)sender
{
    [self centerMapOnUserLocation];
}

- (void)postCodeForLocation:(CLLocationCoordinate2D)coordinate completionHandler:(void (^)(NSString *postCode, NSError *error))completionHandler
{
    CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    CLGeocoder *reverseGeocoder = [CLGeocoder new];
    if(reverseGeocoder) {
        [reverseGeocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
            if(placemarks.count > 0 && !error) {
                CLPlacemark *placemark = [placemarks firstObject];
                NSString *postCode = [placemark postalCode];
                completionHandler(postCode, error);
            } else {
                completionHandler(nil, error);
            }
        }];
    }
}

- (void)addressForLocation:(CLLocationCoordinate2D)coordinate completionHandler:(void (^)(NSString *address, NSError *error))completionHandler
{
    CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    CLGeocoder *reverseGeocoder = [CLGeocoder new];
    if(reverseGeocoder) {
        [reverseGeocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
            if(placemarks.count > 0 && !error) {
                CLPlacemark *placemark = [placemarks firstObject];
                NSMutableString *address = [NSMutableString new];
                [address appendString:[placemark thoroughfare] ? [NSString stringWithFormat:@"%@ ", [placemark thoroughfare]] : @""];
                [address appendString:[placemark locality] ? [NSString stringWithFormat:@"%@ ", [placemark locality]] : @""];
                [address appendString:[placemark country] ? [NSString stringWithFormat:@"%@ ", [placemark country]] : @""];
                
                completionHandler(address, error);
            } else {
                completionHandler(nil, error);
            }
        }];
    }
}

- (void)addressAndPostcodeForLocation:(CLLocationCoordinate2D)coordinate completionHandler:(void (^)(NSString *address, NSString *postCode, NSError *error))completionHandler
{
    CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    CLGeocoder *reverseGeocoder = [CLGeocoder new];
    if(reverseGeocoder) {
        [reverseGeocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
            if(placemarks.count > 0 && !error) {
                CLPlacemark *placemark = [placemarks firstObject];
                NSString *postCode = [placemark postalCode];
                NSMutableString *address = [NSMutableString new];
                
                [address appendString:[placemark thoroughfare] ? [NSString stringWithFormat:@"%@, ", [placemark thoroughfare]] : @""];
                
                [address appendString:[placemark subLocality] ? [NSString stringWithFormat:@"%@, ", [placemark subLocality]] : @""];
                
                [address appendString:[placemark locality] ? [NSString stringWithFormat:@"%@, ", [placemark locality]] : @""];
                
                [address appendString:[placemark administrativeArea] ? [NSString stringWithFormat:@"%@, ", [placemark administrativeArea]] : @""];
                
                [address appendString:[placemark country] ? [NSString stringWithFormat:@"%@", [placemark country]] : @""];
                
                completionHandler(address, postCode, error);
            } else {
                completionHandler(nil, nil, error);
            }
        }];
    }
}

- (void)coordinateForPostcodeOrAddress:(NSString *)address completionHandler:(void (^)(CLLocationCoordinate2D coordinate, NSError *error))completionHandler
{
    CLGeocoder *reverseGeocoder = [CLGeocoder new];
    if(reverseGeocoder) {
        [reverseGeocoder geocodeAddressString:address completionHandler:^(NSArray *placemarks, NSError *error){
            
            CLLocationCoordinate2D coordinate;
            
            if(placemarks.count > 0 && !error) {
                CLPlacemark *placemark = [placemarks firstObject];
                coordinate = [[placemark location] coordinate];
            } else if(!error) {
                error = [NSError errorWithDomain:@"No location data" code:0 userInfo:nil];
            }
            
            completionHandler(coordinate, error);
        }];
    }
}

- (void)showPostCode:(NSString *)postCode address:(NSString *)address
{
    NSLog(@"%s", __func__);
    
    postCodeLabel.text = postCode;
    addressLabel.text = address;
}

- (void)showCoordinate:(CLLocationCoordinate2D)coordinate
{
    coordinateLabel.text = [NSString stringWithFormat:@"(%.4f, %.4f)", coordinate.latitude, coordinate.longitude];
}

- (void)hideKeyboardAndShowMap
{
    [self blurMap:NO];
    
    [bar resignFirstResponder];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    NSLog(@"%s", __func__);
    
    [self blurMap:YES];
    
    return YES;
}

- (void)blurMap:(BOOL)blur
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:.5];
    [UIView  setAnimationDelegate:self];
    mapVisualEffectView.alpha = blur;
    [UIView commitAnimations];
}

#pragma mark - MKMapViewDelegate methods

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    CLLocationCoordinate2D coordinate = map.centerCoordinate;
    
    [self showCoordinate:coordinate];
    
    [self addressAndPostcodeForLocation:coordinate completionHandler:^(NSString *address, NSString *postCode, NSError *error){
        if(!error) {
            [self showPostCode:postCode address:address];
        }
    }];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self hideKeyboardAndShowMap];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self hideKeyboardAndShowMap];
    
    [self coordinateForPostcodeOrAddress:searchBar.text completionHandler:^(CLLocationCoordinate2D coordinate, NSError *error) {
        if(!error) {
            [self centerMapInCoordinate:coordinate];
        }
    }];
}

@end
