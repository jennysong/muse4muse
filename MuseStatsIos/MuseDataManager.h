#import <Foundation/Foundation.h>
#import "Muse.h"
#import "AppDelegate.h"

//sphero
#import <UIKit/UIKit.h>
//


@interface MuseDataManager : NSObject<
IXNMuseDataListener, IXNMuseConnectionListener
>

// Designated initializer.
- (instancetype)initWithDelegate:(AppDelegate *)delegate;
- (void)receiveMuseDataPacket:(IXNMuseDataPacket *)packet;
- (void)receiveMuseArtifactPacket:(IXNMuseArtifactPacket *)packet;
- (void)receiveMuseConnectionPacket:(IXNMuseConnectionPacket *)packet;

@end