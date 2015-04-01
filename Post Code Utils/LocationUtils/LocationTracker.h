//
//  LocationTracker.h
// PabloAlejandro
//
//  Created by PabloAlejandro
//  Copyright (c) 2014 PabloAlejandro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

/**
 * Enumeration defining type of location updates
 */
typedef enum : NSInteger {
    
    /** No location tracking */
    LocationServiceTrackNone,
    /** Custom-defined location updates */
    LocationServiceTrackStandardUpdates,
    /** Track significant updates. See Apple Documentation */
    LocationServiceTrackSignificantUpdates,
    /** Low accuracy custom-defined location updates */
    LocationServiceTrackGPSBigUpdates,
    
} LocationServiceTrackerType;

/**
 * Interface to track location updates. This interface is defined as a singleton in the application and can be initialized (typically in the AppDelegate) to start
 * observing location changes. The class automatically adjusts its behavior in the foreground or background depending on how it is configured.
 * When new location and heading values are received, notifications are posted and observers can be notified.
 */
@interface LocationTracker : NSObject <CLLocationManagerDelegate>

/**
 * Return unique LocationTracker instance. Do not call init... methods.
 * @return Unique LocationTracker instance.
 */
+ (LocationTracker *)sharedInstance;

/**
 * When a location update is received, a new notification with name locationUpdateNotificationName is posted. Interested parties can listen to this.
 * @return name for posted notification name
 */
+ (NSString *)locationUpdateNotificationName;

/**
 * Name for the new location as received in userInfo when a new location update is posted.
 * @return key name that can be used to query userInfo
 */
+ (NSString *)newLocationUserInfoDictionaryKey;

/**
 * Name for the old location as received in userInfo when a new location update is posted.
 * @return key name that can be used to query userInfo
 */
+ (NSString *)oldLocationUserInfoDictionaryKey;

/**
 * When a heading update is received, a new message with name headingUpdateNotificationName is posted. Interested parties can listen to this.
 * @return name for posted notification name
 */
+ (NSString *)headingUpdateNotificationName;

+ (NSString *)headingUserInfoDictionaryKey;

/**
 * We use it to reactivate the location updates when the app background time expires
 */
- (void)backgroundTimerExpired;

/**
 * Type of tracking to perform in background
 */
@property (nonatomic) LocationServiceTrackerType backgroundTrackingType;
/**
 * Type of tracking to perform in foreground
 */
@property (nonatomic) LocationServiceTrackerType foregroundTrackingType;

/**
 * Whether the user denied permission to use location services.
 */
@property (readonly) BOOL userLocationDenied;

/**
 * We store the last location received
 */
@property (strong) CLLocation *lastStoredLocation;

@end
