//
//  Interaxon, Inc. 2015
//  MuseStatsIos
//

#import "LoggingListener.h"
#import <RobotKit/RobotKit.h>

@interface LoggingListener () {
    dispatch_once_t _connectedOnceToken;
}
@property (nonatomic) BOOL lastBlink;
@property (nonatomic) BOOL sawOneBlink;
@property (nonatomic, weak) AppDelegate* delegate;
@property (nonatomic) id<IXNMuseFileWriter> fileWriter;

@property (nonatomic) id alphaRelative;
@property (nonatomic) id betaRelative;
@property (nonatomic) id thetaRelative;
@property (nonatomic) id deltaRelative;
@property (nonatomic) id gammarRelative;

@property (nonatomic) float headPosition;


@property (nonatomic) BOOL ledOn;
@property (strong, nonatomic) IBOutlet UILabel* connectionLabel;
@property (strong, atomic) RKConvenienceRobot* robot;

@end

@implementation LoggingListener

- (instancetype)initWithDelegate:(AppDelegate *)delegate {
    _delegate = delegate;
    /**
     * Set <key>UIFileSharingEnabled</key> to true in Info.plist if you want
     * to see the file in iTunes
     */
    //    NSArray *paths = NSSearchPathForDirectoriesInDomains(
    //        NSDocumentDirectory, NSUserDomainMask, YES);
    //    NSString *documentsDirectory = [paths objectAtIndex:0];
    //    NSString *filePath =
    //        [documentsDirectory stringByAppendingPathComponent:@"new_muse_file.muse"];
    //    self.fileWriter = [IXNMuseFileFactory museFileWriterWithPathString:filePath];
    //    [self.fileWriter addAnnotationString:1 annotation:@"fileWriter created"];
    //    [self.fileWriter flush];
    [[RKRobotDiscoveryAgent sharedAgent] addNotificationObserver:self selector:@selector(handleRobotStateChangeNotification:)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    return self;
}

- (void)receiveMuseDataPacket:(IXNMuseDataPacket *)packet {
    switch (packet.packetType) {
        case IXNMuseDataPacketTypeBattery:
            NSLog(@"battery packet received");
            //            [self.fileWriter addDataPacket:1 packet:packet];
            break;
        case IXNMuseDataPacketTypeAlphaRelative:
            //NSLog(@"%@",packet.values[0]);
            self.alphaRelative = packet.values[0];
            break;
        case IXNMuseDataPacketTypeBetaRelative:
            self.betaRelative = packet.values[0];
            break;
        case IXNMuseDataPacketTypeDeltaRelative:
            self.deltaRelative = packet.values[0];
            break;
        case IXNMuseDataPacketTypeThetaRelative:
            self.thetaRelative = packet.values[0];
            break;
        case IXNMuseDataPacketTypeGammaRelative:
            self.gammarRelative = packet.values[0];
            [self analyzeRelativeData];
            break;
        default:
            break;
    }
}

- (void) analyzeRelativeData {
    NSLog(@"AlphaRelative:%@",self.alphaRelative);
    NSLog(@"BetaRelative:%@",self.betaRelative);
    NSLog(@"DeltaRelative:%@",self.deltaRelative);
    NSLog(@"ThetaRelative:%@",self.thetaRelative);
    NSLog(@"GammarRelative:%@",self.gammarRelative);
    NSArray *data = @[self.alphaRelative,self.betaRelative,self.deltaRelative,self.thetaRelative,self.gammarRelative];
    NSArray *sortedData = [data sortedArrayUsingSelector: @selector(compare:)];
//    for (id sD in sortedData) {
//        NSLog(@"%@",sD);
//    }
    
    
    if([sortedData[4] isEqualToValue: data[0]]){
        [_robot sendCommand:[RKRGBLEDOutputCommand commandWithRed:0 green:1 blue:0]];
        if ([self.alphaRelative floatValue] >= 0.5){
            NSLog(@"TURN!!");
        };
//        NSLog(@"alpha");
    }
    else if ([sortedData[4] isEqualToValue: data[1]]){
        [_robot sendCommand:[RKRGBLEDOutputCommand commandWithRed:0 green:0 blue:1]];
        if ([self.betaRelative floatValue] >= 0.3){
            NSLog(@"GO!!");
            [_robot driveWithHeading:self.headPosition andVelocity:0.1];
        };
//        NSLog(@"beta");
    }
    else if ([sortedData[4] isEqualToValue: data[2]]){
        [_robot sendCommand:[RKRGBLEDOutputCommand commandWithRed:1 green:0 blue:0]];
        if ([self.DeltaRelative floatValue] >= 0.23){
            NSLog(@"GO!!");
            [_robot driveWithHeading:self.headPosition andVelocity:0.1];
        };
//        NSLog(@"delta");
        
    }
    else if ([sortedData[4] isEqualToValue: data[3]]){
        [_robot sendCommand:[RKRGBLEDOutputCommand commandWithRed:1 green:1 blue:0]];
//        NSLog(@"theta");
    }
    
    else if ([sortedData[4] isEqualToValue: data[4]]){
        [_robot sendCommand:[RKRGBLEDOutputCommand commandWithRed:.5 green:.5 blue:.5]];
        if ([self.gammarRelative floatValue] >= 0.3){
            NSLog(@"GO FASTER!!");
            [_robot driveWithHeading:self.headPosition andVelocity:0.3];
        };
//        NSLog(@"gammar");
    }
}

- (void)receiveMuseArtifactPacket:(IXNMuseArtifactPacket *)packet {
    if (!packet.headbandOn)
        return;
    if (!self.sawOneBlink) {
        self.sawOneBlink = YES;
        self.lastBlink = !packet.blink;
    }
    if (self.lastBlink != packet.blink) {
        if (packet.blink)
            NSLog(@"blink");
            self.headPosition = self.headPosition + 45.0;
            [_robot driveWithHeading:self.headPosition andVelocity:0.0];
        self.lastBlink = packet.blink;
    }
}

- (void)receiveMuseConnectionPacket:(IXNMuseConnectionPacket *)packet {
    NSString *state;
    switch (packet.currentConnectionState) {
        case IXNConnectionStateDisconnected:
            state = @"disconnected";
            //            [self.fileWriter addAnnotationString:1 annotation:@"disconnected"];
            //            [self.fileWriter flush];
            break;
        case IXNConnectionStateConnected:
            state = @"connected";
            //            [self.fileWriter addAnnotationString:1 annotation:@"connected"];
            self.headPosition = 0.0;
            break;
        case IXNConnectionStateConnecting:
            state = @"connecting";
            //            [self.fileWriter addAnnotationString:1 annotation:@"connecting"];
            break;
        case IXNConnectionStateNeedsUpdate: state = @"needs update"; break;
        case IXNConnectionStateUnknown: state = @"unknown"; break;
        default: NSAssert(NO, @"impossible connection state received");
    }
    NSLog(@"connect: %@", state);
    if (packet.currentConnectionState == IXNConnectionStateConnected) {
        [self.delegate sayHi];
    } else if (packet.currentConnectionState == IXNConnectionStateDisconnected) {
        // XXX IMPORTANT
        // -connect, -disconnect, and -execute *MUST NOT* be on any code path
        // that starts with a connection event listener, except through an
        // asynchronous scheduled event, such as the below call to reconnect.
        //
        // These messages can cause this connection listener to synchronously
        // fire, without giving the OS a chance to clean up resources or
        // perform scheduled IO. This is a known issue that will be fixed in a
        // future release of the SDK.
        [self.delegate performSelector:@selector(reconnectToMuse)
                            withObject:nil
                            afterDelay:0];
    }
}

- (void)handleRobotStateChangeNotification:(RKRobotChangedStateNotification*)n {
    switch(n.type) {
        case RKRobotConnecting:
            [self handleConnecting];
            break;
        case RKRobotOnline: {
            // Do not allow the robot to connect if the application is not running
            RKConvenienceRobot *convenience = [RKConvenienceRobot convenienceWithRobot:n.robot];
            if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
                [convenience disconnect];
                return;
            }
            self.robot = convenience;
            [self handleConnected];
            break;
        }
        case RKRobotDisconnected:
            [self handleDisconnected];
            self.robot = nil;
            [RKRobotDiscoveryAgent startDiscovery];
            break;
        default:
            break;
    }
}
- (void)handleConnecting {
    [_connectionLabel setText:[NSString stringWithFormat:@"%@ Connecting", _robot.robot.name]];
}
- (void)handleConnected {
    [_connectionLabel setText:_robot.robot.name];
    [self toggleLED];
    NSLog(@"sphero connected");
    [_robot driveWithHeading:self.headPosition andVelocity:0.1];
}
- (void)handleDisconnected {
    _connectionLabel.text = @"Disconnected";
    [self startDiscovery];
    NSLog(@"sphero DISconnected");
}
- (void)toggleLED {
    if(!_robot || ![_robot isConnected]) return; // stop the toggle if no robot.
    
    if (_ledOn) {
        [_robot setLEDWithRed:0 green:0 blue:0];
    }
    else {
        [_robot setLEDWithRed:0 green:0 blue:1];
    }
    _ledOn = !_ledOn;
    [self performSelector:@selector(toggleLED) withObject:nil afterDelay:0.5];
}
- (void)startDiscovery {
    _connectionLabel.text = @"Discovering Robots";
    [RKRobotDiscoveryAgent startDiscovery];
}
- (void)appWillResignActive:(NSNotification*)n {
    [RKRobotDiscoveryAgent stopDiscovery];
    [_connectionLabel setText:@"Sleeping"];
    [RKRobotDiscoveryAgent disconnectAll];
}
- (void)appDidBecomeActive:(NSNotification*)n {
    [self startDiscovery];
}
@end
