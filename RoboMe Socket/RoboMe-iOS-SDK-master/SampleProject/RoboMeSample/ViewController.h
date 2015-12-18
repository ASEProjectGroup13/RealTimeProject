//
//  ViewController.h
//  RoboMeBasicSample
//
//  Copyright (c) 2013 WowWee Group Limited. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RoboMe/RoboMe.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface ViewController : UIViewController <RoboMeDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate, MPMediaPickerControllerDelegate>{
    MPMusicPlayerController *musicPlayer;
}

@property (weak, nonatomic) IBOutlet UITextView *outputTextView;
@property (nonatomic, retain) MPMusicPlayerController *musicPlayer;

@property (weak, nonatomic) IBOutlet UILabel *edgeLabel;
@property (weak, nonatomic) IBOutlet UILabel *chest20cmLabel;
@property (weak, nonatomic) IBOutlet UILabel *chest50cmLabel;
@property (weak, nonatomic) IBOutlet UILabel *cheat100cmLabel;

@end
