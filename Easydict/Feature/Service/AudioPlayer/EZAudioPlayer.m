//
//  EZAudioPlayer.m
//  Easydict
//
//  Created by tisfeng on 2022/12/13.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZAudioPlayer.h"
#import "EZAppleService.h"
#import <AVFoundation/AVFoundation.h>

@interface EZAudioPlayer ()

@property (nonatomic, strong) EZAppleService *appleService;
@property (nonatomic, strong) AVPlayer *player;

@end

@implementation EZAudioPlayer

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

#pragma mark - Getter

- (EZAppleService *)appleService {
    if (!_appleService) {
        _appleService = [[EZAppleService alloc] init];
    }
    return _appleService;
}

- (AVPlayer *)player {
    if (!_player) {
        _player = [[AVPlayer alloc] init];
    }
    return _player;
}

#pragma mark - Public Mehods

- (void)playSystemTextAudio:(NSString *)text {
    [self.appleService playTextAudio:text fromLanguage:EZLanguageAuto];
}

/// Play system text audio.
- (void)playSystemTextAudio:(NSString *)text fromLanguage:(EZLanguage)from {
    [self.appleService playTextAudio:text fromLanguage:from];
}

/// Play text URL audio.
- (void)playTextAudio:(NSString *)text
             audioURL:(nullable NSString *)audioURL
         fromLanguage:(EZLanguage)language
               serive:(nullable EZQueryService *)service {
    if (!text.length) {
        NSLog(@"playTextAudio is empty");
        return;
    }
    
    if (audioURL.length) {
        BOOL useCache = NO;
        BOOL usPhonetic = YES;
        [self getUseCache:&useCache usPhonetic:&usPhonetic audioURL:audioURL fromService:service];
        [self playTextAudio:text
                   audioURL:audioURL
               fromLanguage:language
                   useCache:useCache
                 usPhonetic:usPhonetic
                serviceType:service.serviceType];
        return;
    }
    
    if (!service) {
        [self playSystemTextAudio:text fromLanguage:language];
        return;
    }
    
    [service textToAudio:text fromLanguage:language completion:^(NSString *_Nullable url, NSError *_Nullable error) {
        if (!error && url.length) {
            if (service.serviceType == EZServiceTypeYoudao) {
                BOOL useCache = NO;
                BOOL usPhonetic = YES;
                [self getUseCache:&useCache usPhonetic:&usPhonetic audioURL:url fromService:service];
                [self playTextAudio:text
                           audioURL:url
                       fromLanguage:language
                           useCache:useCache
                         usPhonetic:usPhonetic
                        serviceType:service.serviceType];
            } else {
                [self playRemoteAudio:url];
            }
        } else {
            NSLog(@"获取音频 URL 失败 %@", error);
            [self playSystemTextAudio:text fromLanguage:language];
        }
    }];
}


/// Get &useCache and &usPhonetic from service.
- (void)getUseCache:(BOOL *)useCache
         usPhonetic:(BOOL *)usPhonetic
           audioURL:(NSString *)audioURL
        fromService:(EZQueryService *)service {
    if (service.serviceType == EZServiceTypeYoudao) {
        *useCache = YES;
        
        // uk https://dict.youdao.com/dictvoice?audio=class&type=1
        
        // get type from audioURL
        NSString *type = [audioURL componentsSeparatedByString:@"&type="].lastObject;
        // if type is 1, use ukPhonetic
        if ([type isEqualToString:@"1"]) {
            *usPhonetic = NO;
        }
    }
}


- (void)playTextAudio:(NSString *)text
             audioURL:(nullable NSString *)audioURL
         fromLanguage:(EZLanguage)language
             useCache:(BOOL)useCache
           usPhonetic:(BOOL)usPhonetic
          serviceType:(EZServiceType)serviceType {
    NSLog(@"play audio url: %@", audioURL);
    
    [self.player pause];
    
    NSString *filePath = [self getWordAudioFilePath:text usPhonetic:usPhonetic serviceType:serviceType];
    // if audio file exist, play it
    if (useCache && [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [self playLocalAudioFile:filePath];
        return;
    }
    
    if (!audioURL.length) {
        if (!text.length) {
            return;
        }
        
        [self playSystemTextAudio:text];
        return;
    }
    
    // Since some of Youdao's audio cannot be played directly, it needs to be downloaded first, such as 'set'.
    if ([serviceType isEqualToString:EZServiceTypeYoudao]) {
        NSURL *URL = [NSURL URLWithString:audioURL];
        [self downloadWordAudio:text audioURL:URL autoPlay:YES usPhonetic:usPhonetic serviceType:serviceType];
    } else {
        [self playRemoteAudio:audioURL];
    }
}

- (void)downloadWordAudio:(NSString *)word
                 audioURL:(NSURL *)url
                 autoPlay:(BOOL)autoPlay
               usPhonetic:(BOOL)usPhonetic
              serviceType:(EZServiceType)serviceType {
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSString *filePath = [self getWordAudioFilePath:word usPhonetic:usPhonetic serviceType:serviceType];
        return [NSURL fileURLWithPath:filePath];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        NSLog(@"File downloaded to: %@", filePath);
        [self playLocalAudioFile:filePath.path];
    }];
    [downloadTask resume];
}

/// Play local audio file
- (void)playLocalAudioFile:(NSString *)filePath {
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSLog(@"playLocalAudioFile not exist: %@", filePath);
        return;
    }
    
    NSURL *url = [NSURL fileURLWithPath:filePath];
    [self playAudioWithURL:url];
}

/// Play audio with remote url string.
- (void)playRemoteAudio:(NSString *)urlString {
    if (!urlString.length) {
        return;
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    [self playAudioWithURL:url];
}

/// Play audio with NSURL
- (void)playAudioWithURL:(NSURL *)url {
    [self.player pause];
    [self.player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:url]];
    [self.player play];
}

// Get app cache directory
- (NSString *)getCacheDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

// Get audio file directory, if not exist, create it.
- (NSString *)getAudioDirectory {
    NSString *cachesDirectory = [self getCacheDirectory];
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSString *audioDirectory = [cachesDirectory stringByAppendingPathComponent:bundleID];
    audioDirectory = [audioDirectory stringByAppendingPathComponent:@"audio"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:audioDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:audioDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return audioDirectory;
}

// Get word audio file path
- (NSString *)getWordAudioFilePath:(NSString *)word
                        usPhonetic:(BOOL)usPhonetic
                       serviceType:(EZServiceType)serviceType {
    NSString *audioDirectory = [self getAudioDirectory];
    
    NSString *audioFileName = [NSString stringWithFormat:@"%@_%@_%@", word, serviceType, usPhonetic ? @"us" : @"uk"];
    
    // m4a
    NSString *m4aFilePath = [audioDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m4a", audioFileName]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:m4aFilePath]) {
        return m4aFilePath;
    }
    
    // mp3
    NSString *mp3FilePath = [audioDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp3", audioFileName]];
    return mp3FilePath;
}

- (BOOL)isAudioFilePlayable:(NSURL *)filePathURL {
    OSStatus status;
    AudioFileID audioFile;
    AudioFileTypeID fileType;
    
    NSLog(@"kAudioFileWAVEType: %d", kAudioFileWAVEType);
    
    status = AudioFileOpenURL((__bridge CFURLRef)filePathURL, kAudioFileReadPermission, 0, &audioFile);
    if (status == noErr) {
        UInt32 size = sizeof(fileType);
        status = AudioFileGetProperty(audioFile, kAudioFilePropertyFileFormat, &size, &fileType);
        if (status == noErr) {
            if (fileType == kAudioFileAAC_ADTSType) {
                NSLog(@"Audio file is of type: AAC ADTS");
            } else if (fileType == kAudioFileAIFFType) {
                NSLog(@"Audio file is of type: AIFF");
            } else if (fileType == kAudioFileCAFType) {
                NSLog(@"Audio file is of type: CAF");
            } else if (fileType == kAudioFileMP3Type) {
                NSLog(@"Audio file is of type: MP3");
            } else if (fileType == kAudioFileMPEG4Type) {
                NSLog(@"Audio file is of type: MP4");
            } else if (fileType == kAudioFileWAVEType) {
                NSLog(@"Audio file is of type: WAVE");
            } else {
                NSLog(@"Audio file is of an unknown type");
            }
        } else {
            NSLog(@"Error getting audio file property: %d", (int)status);
            return NO;
        }
    } else {
        NSLog(@"Error opening audio file type: %d", (int)status);
        return NO;
    }
    return YES;
}

@end
