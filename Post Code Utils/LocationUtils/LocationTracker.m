//
//  LocationTracker.m
//  PabloAlejandro
//
//  Created by PabloAlejandro
//  Copyright (c) 2014 PabloAlejandro. All rights reserved.
//

#import "LocationTracker.h"

#import <CoreLocation/CoreLocation.h>
#import <NotificationCenter/NotificationCenter.h>

#define kLocationTrackerUpdateLocationEvent @"LocationTrackerLocationUpdateEvent"
#define kDictionaryKeyUserInfoUpdateNewLocation @"NewLocation"
#define kDictionaryKeyUserInfoUpdateOldLocation @"OldLocation"

#define kLocationTrackerUpdateHeadingEvent @"LocationTrackerHeadingUpdateEvent"
#define kDictionaryKeyUserInfoUpdateHeading @"Heading"

@implementation LocationTracker {
    
    LocationServiceTrackerType currentTrackingType;
    
    CLLocationManager *locationManager;
}

@synthesize userLocationDenied = _userLocationDenied;

@synthesize backgroundTrackingType = _backgroundTrackingType;
@synthesize foregroundTrackingType = _foregroundTrackingType;

#pragma mark - initialisation

// Singleton creation
+ (LocationTracker *)sharedInstance {
    
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{instance = self.new;});
    return instance;
}

- (void)dealloc {
    
    [self unregisterNotifications];
}

- (id)init {
    
    if ((self = [super init])) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    
    [self initLocationManager];
    
    [self registerNotifications];
}

- (void)initLocationManagerWithDelay
{
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidBecomeActiveNotification object:self userInfo:nil];
}

- (void)initLocationManager
{
    locationManager = [CLLocationManager new];
    locationManager.delegate = self;
    
    //if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
    if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [locationManager requestWhenInUseAuthorization];
        //[locationManager requestAlwaysAuthorization];
    }
    
    if ([locationManager respondsToSelector:@selector(setPausesLocationUpdatesAutomatically:)]) {
        [locationManager setPausesLocationUpdatesAutomatically:YES];
    }
}

- (void)stopLocationService {
    
    if (locationManager != nil) {
        [locationManager stopUpdatingLocation];
        [locationManager stopUpdatingHeading];
        [locationManager stopMonitoringSignificantLocationChanges];
        locationManager.delegate = nil;
        locationManager = nil;
    }
}

- (void)registerNotifications {
    
    [self unregisterNotifications];
    
    // Add observers to application state changes
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(applicationDidEnterBackground:)
                                                name:UIApplicationDidEnterBackgroundNotification
                                              object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(applicationDidBecomeActive:)
                                                name:UIApplicationDidBecomeActiveNotification
                                              object:nil];
}

- (void)unregisterNotifications {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)applicationDidBecomeActive:(id)sender {
    
    [self setTrackingType:self.foregroundTrackingType];
}

- (void)applicationDidEnterBackground:(id)sender {

    [self setTrackingType:self.backgroundTrackingType];
}

- (void)backgroundTimerExpired {
    
    [self setTrackingType:self.backgroundTrackingType];
}

#pragma mark - Public methods

- (void)setTrackingType:(LocationServiceTrackerType)trackingType {
    
    // Start again
    currentTrackingType = trackingType;
    
    switch (trackingType) {
        case LocationServiceTrackNone:
            NSLog(@"LocationServiceTrackNone");
            [self stopLocationService];
            break;
            
        case LocationServiceTrackStandardUpdates:
            NSLog(@"LocationServiceTrackStandardUpdates");
            [self startStandardUpdates];
            break;
            
        case LocationServiceTrackSignificantUpdates:
            NSLog(@"LocationServiceTrackSignificantUpdates");
            [self startSignificantChangeUpdates];
            break;
            
        case LocationServiceTrackGPSBigUpdates:
            NSLog(@"LocationServiceTrackGPSBigUpdates");
            [self startGPSBigUpdates];
            break;
    }
}

- (void)startSignificantChangeUpdates
{
    NSLog(@"%s", __func__);
    
    // Create the location manager if this object does not
    // already have one.
    if (!locationManager) {
        [self initLocationManager];
    }
    
    [locationManager startMonitoringSignificantLocationChanges];
    
    // We cannot desactivate it, so we set a high distance to prevent to get notifications
    [locationManager stopUpdatingLocation];         // We stop it since it needs too much battery
    [locationManager stopUpdatingHeading];
}

- (void)startStandardUpdates
{
    NSLog(@"%s", __func__);
    
    // Create the location manager if this object does not
    // already have one.
    if (!locationManager) {
        [self initLocationManager];
    }
    
    if ([CLLocationManager locationServicesEnabled]) {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.distanceFilter = 10;
        [locationManager startUpdatingLocation];
    }
    
    if ([CLLocationManager headingAvailable]) {
        locationManager.headingFilter = .1;
        locationManager.headingOrientation = CLDeviceOrientationFaceUp | CLDeviceOrientationPortrait;
        [locationManager startUpdatingHeading];
    }
}

- (void)startGPSBigUpdates
{
    NSLog(@"%s", __func__);
    
    // Create the location manager if this object does not
    // already have one.
    if (!locationManager) {
        [self initLocationManager];
    }
    
    if ([CLLocationManager locationServicesEnabled]) {
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        locationManager.distanceFilter = 100;
        [locationManager startUpdatingLocation];
    }
    
    [locationManager stopUpdatingHeading];
}

- (void)startConstantUpdates
{
    NSLog(@"%s", __func__);
    
    // Create the location manager if this object does not
    // already have one.
    if (!locationManager) {
        [self initLocationManager];
    }
    
    if ([CLLocationManager locationServicesEnabled]) {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.distanceFilter = 0;
        [locationManager startUpdatingLocation];
    }
    
    if ([CLLocationManager headingAvailable]) {
        [locationManager stopUpdatingHeading];
    }
}

#pragma mark - CLLocationManagerDelegate methods

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager
{
    return !manager.heading;
    
    /*
    if(!manager.heading) return YES;                            // Got nothing, We can assume we got to calibrate.
    else if( manager.heading.headingAccuracy < 0 ) return YES;  // 0 means invalid heading, need to calibrate
    else if( manager.heading.headingAccuracy > 15 )return YES;  // 5 degrees is a small value correct for my needs, too.
    else return NO;                                             // All is good. Compass is precise enough.
    */
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"%s location update failed -> %@", __func__, error);
    
    if (error.code == kCLErrorDenied) {
        _userLocationDenied = YES;
        [self stopLocationService];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    _userLocationDenied = NO;
    
    self.lastStoredLocation = [locations lastObject];
    
    NSDictionary *dictionary = @{ kDictionaryKeyUserInfoUpdateNewLocation : self.lastStoredLocation };
    
    NSLog(@"%s Sending location update notification...", __func__);
        
    [[NSNotificationCenter defaultCenter] postNotificationName:kLocationTrackerUpdateLocationEvent object:self userInfo:dictionary];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)heading
{
    NSDictionary *dictionary = @{ kDictionaryKeyUserInfoUpdateHeading : heading };
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kLocationTrackerUpdateHeadingEvent object:self userInfo:dictionary];
}

+ (NSString *)locationUpdateNotificationName {
    return kLocationTrackerUpdateLocationEvent;
}

+ (NSString *)headingUpdateNotificationName {
    return kLocationTrackerUpdateHeadingEvent;
}

+ (NSString *)newLocationUserInfoDictionaryKey {
    
    return kDictionaryKeyUserInfoUpdateNewLocation;
}

+ (NSString *)oldLocationUserInfoDictionaryKey {
    
    return kDictionaryKeyUserInfoUpdateOldLocation;
}

+ (NSString *)headingUserInfoDictionaryKey {
    
    return kDictionaryKeyUserInfoUpdateHeading;
}

@end
