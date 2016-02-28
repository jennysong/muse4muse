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

//        case IXNMuseDataPacketTypeAccelerometer:
//            NSLog(@"a%@",packet.values[0]);
//            NSLog(@"b%@",packet.values[1]);
//            NSLog(@"c%@",packet.values[2]);
//            break;
//        case IXNMuseDataPacketTypeEeg:
//            NSLog(@"a%@",packet.values[0]);
//            NSLog(@"b%@",packet.values[1]);
//            NSLog(@"c%@",packet.values[2]);
//            NSLog(@"d%@",packet.values[3]);
//            break;
        case IXNMuseDataPacketTypeDroppedAccelerometer:
            NSLog(@"2");
            break;
        case IXNMuseDataPacketTypeDroppedEeg:
            NSLog(@"3");
            break;
        case IXNMuseDataPacketTypeQuantization:
            NSLog(@"4");
            break;
        case IXNMuseDataPacketTypeDrlRef:
            NSLog(@"5");
            break;
//        case IXNMuseDataPacketTypeAlphaAbsolute:
//            NSLog(@"AlphaAbsolute:%@",packet.values[0]);
//            break;
//        case IXNMuseDataPacketTypeBetaAbsolute:
//            NSLog(@"BetaAbsolute:%@",packet.values[0]);
//            break;
//        case IXNMuseDataPacketTypeDeltaAbsolute:
//            NSLog(@"DeltaAbsolute:%@",packet.values[0]);
//            break;
//        case IXNMuseDataPacketTypeThetaAbsolute:
//            NSLog(@"ThetaAbsolute:%@",packet.values[0]);
//            break;
//        case IXNMuseDataPacketTypeGammaAbsolute:
//            NSLog(@"GammaAbsolute:%@",packet.values[0]);
//            break;
        case IXNMuseDataPacketTypeAlphaRelative:
            NSLog(@"AlphaRelative:%@",packet.values[0]);
            self.alphaRelative = packet.values[0];
            break;
        case IXNMuseDataPacketTypeBetaRelative:
            NSLog(@"BetaRelative:%@",packet.values[0]);
            self.betaRelative = packet.values[0];
            break;
        case IXNMuseDataPacketTypeDeltaRelative:
            NSLog(@"DeltaRelative:%@",packet.values[0]);
            self.deltaRelative = packet.values[0];
            break;
        case IXNMuseDataPacketTypeThetaRelative:
            NSLog(@"ThetaRelative:%@",packet.values[0]);
            self.thetaRelative = packet.values[0];
            break;
        case IXNMuseDataPacketTypeGammaRelative:
            NSLog(@"GammaRelative:%@",packet.values[0]);
            self.gammarRelative = packet.values[0];
            break;
        case IXNMuseDataPacketTypeAlphaScore:
            NSLog(@"16");
            break;
        case IXNMuseDataPacketTypeBetaScore:
            NSLog(@"17");
            break;
        case IXNMuseDataPacketTypeDeltaScore:
            NSLog(@"18");
            break;
        case IXNMuseDataPacketTypeThetaScore:
            NSLog(@"19");
            break;
        case IXNMuseDataPacketTypeGammaScore:
            NSLog(@"20");
            break;
        case IXNMuseDataPacketTypeHorseshoe:
            NSLog(@"21");
            break;
        case IXNMuseDataPacketTypeArtifacts:
            NSLog(@"22");
            break;
        case IXNMuseDataPacketTypeMellow:
            NSLog(@"23");
            break;
        case IXNMuseDataPacketTypeConcentration:
            NSLog(@"24");
            break;
        default:
            break;
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
        [_robot driveWithHeading:0.0 andVelocity:0.1];
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
    [_robot driveWithHeading:0.0 andVelocity:0.1];
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
