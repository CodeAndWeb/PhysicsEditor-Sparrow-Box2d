//
//  Sparrow_Box2DAppDelegate.mm
//  Sparrow-Box2D
//
//  Created by Grzesiek Frydrych on 11-05-12.
//  Copyright 2011 Grzesiek Frydrych. All rights reserved.
//

#import "Sparrow_Box2DAppDelegate.h"
#import "MainView.h"
#import "Sparrow.h"


@implementation Sparrow_Box2DAppDelegate

- (id)init
{
    if ((self = [super init]))
    {
        mWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        mSparrowView = [[SPView alloc] initWithFrame:mWindow.bounds]; 
        [mWindow addSubview:mSparrowView];
    }
    return self;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
    SP_CREATE_POOL(pool);    
    
    [SPStage setSupportHighResolutions:YES];
    
    // We don't need audio in this example
//    [SPAudioEngine start];
    
    MainView *game = [[MainView alloc] init];        
    mSparrowView.stage = game;
    mSparrowView.multipleTouchEnabled = NO;
    mSparrowView.frameRate = 60.0f;
    [game release];
    
    [mWindow makeKeyAndVisible];
    [mSparrowView start];
    
    SP_RELEASE_POOL(pool);
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application 
{    
    [mSparrowView stop];
}

- (void)applicationDidBecomeActive:(UIApplication *)application 
{
	[mSparrowView start];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    [SPPoint purgePool];
    [SPRectangle purgePool];
    [SPMatrix purgePool];    
}

- (void)dealloc 
{
//    [SPAudioEngine stop];
    [mSparrowView release];
    [mWindow release];    
    [super dealloc];
}

@end
