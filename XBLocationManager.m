#import "XBLocationManager.h"
#import "SBAppSwitcherModel.h"

#include <dlfcn.h>

typedef NSDictionary *(* NSDIiiPTR)(int, int);
static NSDIiiPTR CLCopyAppsUsingLocation;

@implementation XBLocationManager

@synthesize appList;
@synthesize locationApps;

#pragma mark Singleton Methods

+(id)sharedManager {
    static XBLocationManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    [sharedManager updateLocationApps];
    [sharedManager updateAppList];
    return sharedManager;
}

+(void)load {
    CLCopyAppsUsingLocation = (NSDIiiPTR)dlsym(RTLD_DEFAULT, "CLCopyAppsUsingLocation");
}

-(void)updateLocationApps {
    if (CLCopyAppsUsingLocation == NULL) {
        return;
    }
    self.locationApps = [CLCopyAppsUsingLocation(0, 0) autorelease];
}

-(void)updateAppList {
    Class SBAppSwitcherModel = NSClassFromString(@"SBAppSwitcherModel");
    self.appList = [[SBAppSwitcherModel sharedInstance] identifiers];
}

-(NSString *)iconForIndex:(NSUInteger)index {
    NSString *bundle = [self.appList objectAtIndex:index];
    if (bundle) {
        NSDictionary *app = [self.locationApps objectForKey:bundle];
        int started = [[app objectForKey:@"LocationTimeStarted"] intValue];
        int stopped = [[app objectForKey:@"LocationTimeStopped"] intValue];

        /*
        NSLog(@"%@ Background: %d Time: %d", bundle, started, [[app objectForKey:@"LocationTimeStarted"] intValue]);
        NSLog(@"%@ BackgroundStopped: %d Time Stopped: %d", bundle, stopped, [[app objectForKey:@"LocationTimeStopped"] intValue]);
        */
        if (started != 0) {
            return @"LocationActive";
        } else if (stopped != 0) {
            return @"LocationRecent";
        }
    }
    return nil;
}

-(void)dealloc {
    [self.locationApps release];
    [self.appList release];

    [super dealloc];
}

@end
