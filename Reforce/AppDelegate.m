//
//  AppDelegate.m
//  Reforce
//
//  Created by Akhil Stanislavose on 18/04/14.
//  Copyright (c) 2014 Akhil Stanislavose. All rights reserved.
//

#import "AppDelegate.h"

#import "DDLog.h"
#import "DDTTYLogger.h"
#import "RHTTPConnection.h"

#import "HTTPServer+Reforce.h"
#import "RHTTPConnection.h"

#import "Presentation.h"
#import "Settings.h"

#import <JPSVolumeButtonHandler.h>

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;


@implementation AppDelegate {
    JPSVolumeButtonHandler *_volumeButtonHandler;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.

    [self setupHttpServer];
    [self setupVolumeButtons];

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [httpServer stop];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    if ([[Settings sharedManager] isUploadEnabled])
        [self startHttpServer];

    [self setupVolumeButtons];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(void) setupHttpServer {

    [DDLog addLogger:[DDTTYLogger sharedInstance]];

    httpServer = [[HTTPServer alloc] init];

    [httpServer setType:@"_http._tcp."];

    NSString *docRoot = [[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:@"web"] stringByDeletingLastPathComponent];
	DDLogInfo(@"Setting document root: %@", docRoot);

	[httpServer setDocumentRoot:docRoot];

    [httpServer setPort:5000];

	[httpServer setConnectionClass:[RHTTPConnection class]];

    if ([[Settings sharedManager] isUploadEnabled])
        [self startHttpServer];
}

-(void) startHttpServer {
    if (httpServer.isRunning)
        return;

    NSError *error = nil;
    if(![httpServer start:&error])
        DDLogError(@"Error starting HTTP Server: %@", error);
}

-(void) stopHttpServer {
    if (httpServer.isRunning)
        [httpServer stop];
}

-(void)setHttpServerRootTo:(NSString *)path {
    DDLogInfo(@"Setting document root: %@", path);
    [httpServer setDocumentRoot:path];
}

-(void)resetHttpServerRoot {
    NSString *docRoot = [[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:@"web"] stringByDeletingLastPathComponent];
	DDLogInfo(@"Setting document root: %@", docRoot);

	[httpServer setDocumentRoot:docRoot];
}

- (void)setupVolumeButtons
{
    _volumeButtonHandler = [JPSVolumeButtonHandler volumeButtonHandlerWithUpBlock:^{
        [httpServer sendMessageToWebsockets:@"r"];
    } downBlock:^{
        [httpServer sendMessageToWebsockets:@"l"];
    }];
}


@end
