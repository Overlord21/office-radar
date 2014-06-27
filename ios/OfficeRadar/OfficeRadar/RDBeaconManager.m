
#import <Foundation/Foundation.h>
#import "RDBeaconManager.h"
#import "RDConstants.h"

@implementation RDBeaconManager

- (RDBeaconManager *)initWithDatabase:(CBLDatabase *)database
{
    if (self = [super init]) {
        self.database = database;
        self.estimoteBeaconManager = [[ESTBeaconManager alloc] init];
        self.estimoteBeaconManager.delegate = self;
    }
    return self;
}

- (void) observeDatabase {
    
    [[NSNotificationCenter defaultCenter] addObserverForName: kCBLDatabaseChangeNotification
                                                      object: [self database]
                                                       queue: nil
                                                  usingBlock: ^(NSNotification *n) {
                                                      NSArray* changes = n.userInfo[@"changes"];
                                                      for (int i=0; i<changes.count; i++) {
                                                          [self handleDbChange:changes[i]];
                                                      }
                                                  }
     ];
    
}

- (void) handleDbChange:(CBLDatabaseChange *)change {
    
    NSLog(@"Document '%@' changed.", change.documentID);
    
    // if it's not type=beacon, ignore it
    CBLDocument *changedDoc = [[self database] documentWithID:[change documentID]];
    NSString *docType = (NSString *)[changedDoc propertyForKey:kDocType];
    
    // if it's not a beacon doc (possibly because it has been deleted and lost its type field)
    // then ignore it
    if (![docType isEqualToString:kDocTypeBeacon]) {
        return;
    }
    
    NSString *uuidStr = (NSString *) [changedDoc propertyForKey:kFieldUuid];
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidStr];
    NSNumber *major = (NSNumber *) [changedDoc propertyForKey:kFieldMajor];
    NSNumber *minor = (NSNumber *) [changedDoc propertyForKey:kFieldMinor];
    
    // otherwise if its a beacon doc, register it with core location
    // TODO: research dupe registration of core location and see if it causes issues
    ESTBeaconRegion *beaconRegion = [[ESTBeaconRegion alloc] initWithProximityUUID:uuid
                                                                 major:[major intValue]
                                                                 minor:[minor intValue]
                                                            identifier:@"RegionIdentifier"];
    beaconRegion.notifyOnEntry = YES;
    beaconRegion.notifyOnExit = YES;
    
    [self.estimoteBeaconManager startMonitoringForRegion:beaconRegion];
    
    
}



#pragma mark - ESTBeaconManager delegate

- (void)beaconManager:(ESTBeaconManager *)manager didEnterRegion:(ESTBeaconRegion *)region
{
    UILocalNotification *notification = [UILocalNotification new];
    notification.alertBody = @"OfficeRadar: enter";
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

- (void)beaconManager:(ESTBeaconManager *)manager didExitRegion:(ESTBeaconRegion *)region
{
    UILocalNotification *notification = [UILocalNotification new];
    notification.alertBody = @"OfficeRadar: exit";
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}


@end