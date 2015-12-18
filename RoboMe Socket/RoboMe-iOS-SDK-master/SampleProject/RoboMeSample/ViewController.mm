//
//  ViewController.m
//  RoboMeBasicSample
//
//  Copyright (c) 2013 WowWee Group Limited. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"
#include <ifaddrs.h>
#include <arpa/inet.h>

#define WELCOME_MSG  0
#define ECHO_MSG     1
#define WARNING_MSG  2

#define READ_TIMEOUT 15.0
#define READ_TIMEOUT_EXTENSION 10.0

#define FORMAT(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]
#define PORT 1234


@interface ViewController () {
    dispatch_queue_t socketQueue;
    NSMutableArray *connectedSockets;
    BOOL isRunning;
    
    GCDAsyncSocket *listenSocket;
    GCDAsyncSocket *sparkSocket;
    GCDAsyncSocket *androidSocket;
    
    AVAudioRecorder *recorder;
    
    AVAudioPlayer *player;
}


@property (nonatomic, strong) RoboMe *roboMe;

@property(nonatomic, strong) CommandPlayer *commandPlayer;



@end

@implementation ViewController

@synthesize musicPlayer;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // create RoboMe object
    self.roboMe = [[RoboMe alloc] initWithDelegate: self];
    
    // start listening for events from RoboMe
    [self.roboMe startListening];
    

    
    
    
    // Do any additional setup after loading the view, typically from a nib.
    socketQueue = dispatch_queue_create("socketQueue", NULL);
    
    listenSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:socketQueue];
    
    sparkSocket =[[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:socketQueue];
    
    // Setup an array to store all accepted client connections
    connectedSockets = [[NSMutableArray alloc] initWithCapacity:1];
    
    isRunning = NO;
    
    NSLog(@"%@", [self getIPAddress]);
    
    [self toggleSocketState];   //Statrting the Socket
    
    self.commandPlayer = [[CommandPlayer alloc]init];
    
    // Set the audio file
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               @"MyAudioMemo.m4a",
                               nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    
    // Setup audio session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    // Define the recorder setting
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
    
    // Initiate and prepare the recorder
    recorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:NULL];
    recorder.delegate = self;
    recorder.meteringEnabled = YES;
    [recorder prepareToRecord];
    
        musicPlayer = [MPMusicPlayerController iPodMusicPlayer];

    [self perform:@"SEND"];

    
}

// Print out given text to text view
- (void)displayText: (NSString *)text {
    NSString *outputTxt = [NSString stringWithFormat: @"%@\n%@", self.outputTextView.text, text];
    
    // print command to output box
    [self.outputTextView setText: outputTxt];
    
    // scroll to bottom
    [self.outputTextView scrollRangeToVisible:NSMakeRange([self.outputTextView.text length], 0)];
}

#pragma mark - RoboMeConnectionDelegate

// Event commands received from RoboMe
- (void)commandReceived:(IncomingRobotCommand)command {
    // Display incoming robot command in text view
    [self displayText: [NSString stringWithFormat: @"Received: %@" ,[RoboMeCommandHelper incomingRobotCommandToString: command]]];
    
    // To check the type of command from RoboMe is a sensor status use the RoboMeCommandHelper class
    if([RoboMeCommandHelper isSensorStatus: command]){
        // Read the sensor status
        SensorStatus *sensors = [RoboMeCommandHelper readSensorStatus: command];
        
        // Update labels
        [self.edgeLabel setText: (sensors.edge ? @"ON" : @"OFF")];
        [self.chest20cmLabel setText: (sensors.chest_20cm ? @"ON" : @"OFF")];
        [self.chest50cmLabel setText: (sensors.chest_50cm ? @"ON" : @"OFF")];
        [self.cheat100cmLabel setText: (sensors.chest_100cm ? @"ON" : @"OFF")];
    }
}

- (void)volumeChanged:(float)volume {
    if([self.roboMe isRoboMeConnected] && volume < 0.75) {
        [self displayText: @"Volume needs to be set above 75% to send commands"];
    }
}

- (void)roboMeConnected {
    [self displayText: @"RoboMe Connected!"];
}

- (void)roboMeDisconnected {
    [self displayText: @"RoboMe Disconnected"];
}

#pragma mark -
#pragma mark User-Defined Robo Movement

- (NSString *)direction:(NSString *)message {
    
    return @"";
}

-(void)sendToKafka:(NSString *)data{
    
}

- (void)perform:(NSString *)command {
    
    NSString *cmd = [command uppercaseString];
    if ([cmd isEqualToString:@"LEFT"]) {
        [self log:@"playing song before"];
                [self.commandPlayer playCommand:@"ring.mp3"];
        [self.roboMe sendCommand:kRobot_TurnLeft90Degrees];
    } else if ([cmd isEqualToString:@"RIGHT"]) {
        [self.roboMe sendCommand: kRobot_TurnRight90Degrees];
    } else if ([cmd isEqualToString:@"BACKWARD"]) {
        [self.roboMe sendCommand: kRobot_MoveBackwardFastest];
    } else if ([cmd isEqualToString:@"FORWARD"]) {
        [self.roboMe sendCommand: kRobot_MoveForwardFastest];
    }
//    else if([cmd isEqualToString:@"STOP"]){
//        [self.commandPlayer playCommand:@"ring.mp3"];
//        [self.roboMe sendCommand:kRobot_Stop];
//    }
    else if([cmd isEqualToString:@"RECORD"]){
        if (player.playing) {
            [player stop];
        }
        if (!recorder.recording) {
            AVAudioSession *session = [AVAudioSession sharedInstance];
            [session setActive:YES error:nil];
            [recorder record];
        } else {
            [recorder pause];
        }
    }else if([cmd isEqualToString:@"RECOMMEND"]){
//        if (player.playing) {
//            [player stop];
//        }
//        if (!recorder.recording) {
//            AVAudioSession *session = [AVAudioSession sharedInstance];
//            [session setActive:YES error:nil];
//            [recorder record];
//
//        } else {
//            [recorder pause];
//        }
    }
else if([cmd isEqualToString:@"CLASSIFY"]){
    if (player.playing) {
        [player stop];
    }
    if (!recorder.recording) {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setActive:YES error:nil];
        [recorder record];

    } else {
        [recorder pause];
    }
}
    else if([cmd isEqualToString:@"STOP"]){
        [recorder stop];
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setActive:NO error:nil];
    }else if([cmd isEqualToString:@"PLAY"]){
        if (!recorder.recording) {
            player = [[AVAudioPlayer alloc] initWithContentsOfURL:recorder.url error:nil];
            [self log:@"%@"];
            [player setDelegate:self];
            [player play];
            
            
        }
    }
    else if ([cmd isEqualToString:@"SEND"]){
        
        NSData *data = [NSData dataWithContentsOfFile:@"ring.mp3"];
        NSUInteger len = [data length];
        Byte *byteData = (Byte*)malloc(len);
        memcpy(byteData, [data bytes], len);
        
        NSString *welcomeMsg = @"recommend\r\n";
        NSData *welcomeData = [welcomeMsg dataUsingEncoding:NSUTF8StringEncoding];
        
        NSLog(@"%@",sparkSocket);
        
//        [sparkSocket readDataWithTimeout:READ_TIMEOUT tag:0];
//        
//        [sparkSocket writeData:welcomeData withTimeout:-1 tag:WELCOME_MSG];
//                sparkSocket.delegate = self;
        
        
        

    }
    else if ([cmd containsString:@"RECOMMEND"]){
//        [self.commandPlayer playCommand:@"ring.mp3"];
        
        NSLog(@"Command: %@",cmd);
        
       // NSString *recommendations = [cmd 	substringFromIndex:[cmd rangeOfString:@"::"].location];
        
        NSArray *recommendedSongs = [cmd componentsSeparatedByString:@"::"];
        NSLog(@"first element: %@",recommendedSongs[0]);
         NSLog(@"second element: %@",recommendedSongs[1]);
        NSString *filename1 = [recommendedSongs[1] lowercaseString];
        [self.commandPlayer playCommand:filename1];
         NSLog(@"third element: %@",recommendedSongs[2]);
        NSString *filename2 = [recommendedSongs[2] lowercaseString];
        [self.commandPlayer playCommand:filename2];
         NSLog(@"fourth element: %@",recommendedSongs[3]);
         NSLog(@"fifth element: %@",recommendedSongs[4]);
         NSLog(@"sixth element: %@",recommendedSongs[5]);
         NSLog(@"first element: %@",recommendedSongs[0]);
    }
    
}
#pragma mark - Button callbacks

// The methods below send the desired command to RoboMe.
// Typically you would want to start a timer to repeatly send the
// command while the button is held down. For simplicity this wasn't
// included however if you do decide to implement this we recommand
// sending commands every 500ms for smooth movement.
// See RoboMeCommandHelper.h for a full list of robot commands
- (IBAction)moveForwardBtnPressed:(UIButton *)sender {
    // Adds command to the queue to send to the robot
    [self.roboMe sendCommand: kRobot_MoveForwardFastest];
}

- (IBAction)moveBackwardBtnPressed:(UIButton *)sender {
    [self.roboMe sendCommand: kRobot_MoveBackwardFastest];
}

- (IBAction)turnLeftBtnPressed:(UIButton *)sender {
    [self.roboMe sendCommand: kRobot_TurnLeftFastest];
}

- (IBAction)turnRightBtnPressed:(UIButton *)sender {
    [self.roboMe sendCommand: kRobot_TurnRightFastest];
}

- (IBAction)headUpBtnPressed:(UIButton *)sender {
    [self.roboMe sendCommand: kRobot_HeadTiltAllUp];
}

- (IBAction)headDownBtnPressed:(UIButton *)sender {
    [self.roboMe sendCommand: kRobot_HeadTiltAllDown];
}
#pragma mark -
#pragma mark Socket

- (void)toggleSocketState
{
    if(!isRunning)
    {
        NSError *error = nil;
        if(![listenSocket acceptOnPort:PORT error:&error])
        {
            [self log:FORMAT(@"Error starting server: %@", error)];
            return;
        }
        
        [self log:FORMAT(@"Echo server started on port %hu", [listenSocket localPort])];
        isRunning = YES;
    }
    else
    {
        // Stop accepting connections
        [listenSocket disconnect];
        
        // Stop any client connections
        @synchronized(connectedSockets)
        {
            NSUInteger i;
            for (i = 0; i < [connectedSockets count]; i++)
            {
                // Call disconnect on the socket,
                // which will invoke the socketDidDisconnect: method,
                // which will remove the socket from the list.
                [[connectedSockets objectAtIndex:i] disconnect];
            }
        }
        
        [self log:@"Stopped Echo server"];
        isRunning = false;
    }
}

- (void)log:(NSString *)msg {
    NSLog(@"--> %@", msg);
}

- (NSString *)getIPAddress
{
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if( temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    
    return address;
}

#pragma mark -
#pragma mark GCDAsyncSocket Delegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    // This method is executed on the socketQueue (not the main thread)
    
    @synchronized(connectedSockets)
    {
        [connectedSockets addObject:newSocket];
    }
    
    NSString *host = [newSocket connectedHost];
    UInt16 port = [newSocket connectedPort];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            [self log:FORMAT(@"Accepted client %@:%hu", host, port)];
        }
    });
    
    
   if ([host isEqualToString:@"10.205.0.14"]) {
    //  if ([host isEqualToString:@"192.168.0.19"]) {
        androidSocket = newSocket;
        //        androidIP = host;
    } else {
        sparkSocket = newSocket;
    }
    
    NSString *welcomeMsg = @"Welcome to the AsyncSocket Echo Server\r\n";
    NSData *welcomeData = [welcomeMsg dataUsingEncoding:NSUTF8StringEncoding];
    
    [newSocket writeData:welcomeData withTimeout:-1 tag:WELCOME_MSG];
    
    
    [newSocket readDataWithTimeout:READ_TIMEOUT tag:0];
    newSocket.delegate = self;
    
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    // This method is executed on the socketQueue (not the main thread)
    
    if (tag == ECHO_MSG)
    {
        [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:100 tag:0];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    
    NSLog(@"== didReadData %@ ==", sock.description);
    
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:msg];
    AVSpeechSynthesizer *syn = [[AVSpeechSynthesizer alloc] init];
    //[syn speakUtterance:utterance];
    
    [self log:msg];
    
    //[sock writeData:@"ringsfortesting" withTimeout:READ_TIMEOUT tag:0];
    
    NSString *warningMsg = @"ringsfortesting";
    NSData *warningData = [warningMsg dataUsingEncoding:NSUTF8StringEncoding];
    
   // [sock writeData:warningData withTimeout:-1 tag:WARNING_MSG];
    
    if([msg isEqualToString:@"send"]){
        
        if ([[sock connectedHost] isEqualToString:[androidSocket connectedHost]]) {
            //
            NSLog(@"helloooooo");
            if (sparkSocket != nil) {
               
                //NSString *warningMsg = @"classify::classical.00000.au";
                NSString *warningMsg = @"classify";
                NSData *warningData = [warningMsg dataUsingEncoding:NSUTF8StringEncoding];
                
                [sparkSocket writeData:warningData  withTimeout:-1 tag:WARNING_MSG];
                [sparkSocket writeData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:1];
            } else {
                NSLog(@"Check for Spark socket");
            }
            
        } else  {
            NSString *welcomeMsg = msg;
            NSData *welcomeData = [welcomeMsg dataUsingEncoding:NSUTF8StringEncoding];
            
            
            [sock readDataWithTimeout:READ_TIMEOUT tag:0];
            
            [sock writeData:welcomeData withTimeout:-1 tag:WELCOME_MSG];
            sock.delegate = self;
            
        }

    }
    else if([msg isEqualToString:@"recommend"]){
        
        if ([[sock connectedHost] isEqualToString:[androidSocket connectedHost]]) {
            //
            NSLog(@"helloooooo");
            if (sparkSocket != nil) {
                
                NSString *warningMsg = @"recommend";
                NSData *warningData = [warningMsg dataUsingEncoding:NSUTF8StringEncoding];
                
                [sparkSocket writeData:warningData  withTimeout:-1 tag:WARNING_MSG];
                [sparkSocket writeData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:1];
            } else {
                NSLog(@"Check for Spark socket");
            }
            
        } else  {
            NSString *welcomeMsg = msg;
            NSData *welcomeData = [welcomeMsg dataUsingEncoding:NSUTF8StringEncoding];
            
            
            [sock readDataWithTimeout:READ_TIMEOUT tag:0];
            
            [sock writeData:welcomeData withTimeout:-1 tag:WELCOME_MSG];
            sock.delegate = self;
            
        }
        
    }
    
    [self perform:msg];
    [sock readDataWithTimeout:READ_TIMEOUT tag:0];
}

/**
 * This method is called if a read has timed out.
 * It allows us to optionally extend the timeout.
 * We use this method to issue a warning to the user prior to disconnecting them.
 **/
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length
{
    if (elapsed <= READ_TIMEOUT)
    {
        NSString *warningMsg = @"Are you still there?\r\n";
        NSData *warningData = [warningMsg dataUsingEncoding:NSUTF8StringEncoding];
        
        [sock writeData:warningData withTimeout:-1 tag:WARNING_MSG];
        
        return READ_TIMEOUT_EXTENSION;
    }
    
    return 0.0;
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    if (sock != listenSocket)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            @autoreleasepool {
                [self log:FORMAT(@"Client Disconnected")];
            }
        });
        
        @synchronized(connectedSockets)
        {
            [connectedSockets removeObject:sock];
        }
    }
}

@end
