//
//  Interaxon, Inc. 2015
//  MuseStatsIos
//

#import "LoggingListener.h"

@interface LoggingListener () {
    dispatch_once_t _connectedOnceToken;
}
@property (nonatomic) BOOL lastBlink;
@property (nonatomic) BOOL sawOneBlink;
@property (nonatomic, weak) AppDelegate* delegate;
@property (nonatomic) id<IXNMuseFileWriter> fileWriter;
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
        case IXNMuseDataPacketTypeEeg:
            NSLog(@"a%@",packet.values[0]);
            NSLog(@"b%@",packet.values[1]);
            NSLog(@"c%@",packet.values[2]);
            NSLog(@"d%@",packet.values[3]);
            break;
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
        case IXNMuseDataPacketTypeAlphaAbsolute:
            NSLog(@"6");
            break;
        case IXNMuseDataPacketTypeBetaAbsolute:
            NSLog(@"7");
            break;
        case IXNMuseDataPacketTypeDeltaAbsolute:
            NSLog(@"8");
            break;
        case IXNMuseDataPacketTypeThetaAbsolute:
            NSLog(@"9");
            break;
        case IXNMuseDataPacketTypeGammaAbsolute:
            NSLog(@"10");
            break;
        case IXNMuseDataPacketTypeAlphaRelative:
            NSLog(@"11");
            break;
        case IXNMuseDataPacketTypeBetaRelative:
            NSLog(@"12");
            break;
        case IXNMuseDataPacketTypeDeltaRelative:
            NSLog(@"13");
            break;
        case IXNMuseDataPacketTypeThetaRelative:
            NSLog(@"14");
            break;
        case IXNMuseDataPacketTypeGammaRelative:
            NSLog(@"15");
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

@end
