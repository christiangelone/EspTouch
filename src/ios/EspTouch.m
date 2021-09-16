/********* EspTouch.m Cordova Plugin Implementation *******/
#import "EspTouch.h"

@interface EspTouchDelegateImpl : NSObject<ESPTouchDelegate>
@property (nonatomic, strong) CDVInvokedUrlCommand *command;
@property (nonatomic, weak) id <CDVCommandDelegate> commandDelegate;

@end
NSString *callback_ID;
@implementation EspTouchDelegateImpl

-(void) onEsptouchResultAddedWithResult: (ESPTouchResult *) result {
    NSString *InetAddress=[ESP_NetUtil descriptionInetAddr4ByData:result.ipAddrData];
    CDVPluginResult* pluginResult = nil;
    NSDictionary *dic =@{@"bssid":result.bssid,@"ip":InetAddress};
    NSLog(@"收到onEsptouchResultAddedWithResult bssid:%@ ip:%@",result.bssid,InetAddress);
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary: dic];
    [pluginResult setKeepCallbackAsBool:true];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callback_ID];
}
@end


@implementation EspTouch

- (void) start:(CDVInvokedUrlCommand *)command {
  [self.commandDelegate runInBackground:^{

    callback_ID = command.callbackId;
    NSString *apSsid = (NSString *)[command.arguments objectAtIndex:0];
    NSString *apBssid = (NSString *)[command.arguments objectAtIndex:1];
    NSString *apPwd = (NSString *)[command.arguments objectAtIndex:2];
    int taskCount = [[command.arguments objectAtIndex:3] intValue];
    BOOL broadcast = YES;
          
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
      NSLog(@"Executing task...");
      // execute the task
      NSArray *esptouchResultArray = [self executeForResultsWithSsid:apSsid bssid:apBssid password:apPwd taskCount:taskCount broadcast:broadcast];
      // show the result to the user in UI Main Thread
      dispatch_async(dispatch_get_main_queue(), ^{
        ESPTouchResult *firstResult = [esptouchResultArray objectAtIndex:0];
        // check whether the task is cancelled and no results received
        if (!firstResult.isCancelled) {
          if ([firstResult isSuc]) {
            ESPTouchResult *resultInArray = [esptouchResultArray objectAtIndex:0];
            NSString *ipaddr = [ESP_NetUtil descriptionInetAddr4ByData:resultInArray.ipAddrData];
            // device0 I think is suppose to be the index
            //NSString *result = [NSString stringWithFormat:@"Finished: device0,bssid=%@,InetAddress=%@.", resultInArray.bssid, ipaddr];
            CDVPluginResult* pluginResult = nil;
            NSDictionary *dic =@{@"bssid":resultInArray.bssid,@"ip":ipaddr};
            //NSLog(@"收到 json:%@",dic);
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dic];
                        
            [pluginResult setKeepCallbackAsBool:true];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                      
          } else {
            CDVPluginResult* pluginResult = nil;
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"Esptouch fail"];
            [pluginResult setKeepCallbackAsBool:true];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
          }
        } else {
          CDVPluginResult* pluginResult = nil;
          pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"Esptouch fail"];
          [pluginResult setKeepCallbackAsBool:true];
          [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }        
      });
    });
  }];
}


- (void) stop:(CDVInvokedUrlCommand *)command {
    [self._condition lock];
    if (self._esptouchTask != nil) {
        [self._esptouchTask interrupt];
    }
    [self._condition unlock];
    CDVPluginResult* pluginResult = nil;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: @"cancel success"];
    [pluginResult setKeepCallbackAsBool: true];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (NSArray *) executeForResultsWithSsid:(NSString *)apSsid bssid:(NSString *)apBssid password:(NSString *)apPwd taskCount:(int)taskCount broadcast:(BOOL)broadcast
{
    [self._condition lock];
    self._esptouchTask = [[ESPTouchTask alloc]initWithApSsid:apSsid andApBssid:apBssid andApPwd:apPwd];
    // set delegate
    EspTouchDelegateImpl *esptouchDelegate = [[EspTouchDelegateImpl alloc] init];
    [self._esptouchTask setEsptouchDelegate: esptouchDelegate];
    [self._esptouchTask setPackageBroadcast:broadcast];
    [self._condition unlock];
//    ESPTouchResult *ESPTR = self._esptouchTask.executeForResult;
    NSArray * esptouchResults = [self._esptouchTask executeForResults:taskCount];
    NSLog(@"executeForResult() result is: %@", esptouchResults);
    return esptouchResults;
}

@end
