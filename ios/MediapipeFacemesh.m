#import "MediapipeFacemesh.h"
#import <FaceMeshIOSLibFramework/FaceMeshIOSLibFramework.h>
#import "ChunkBasedFaceMeshRunner.h"

@implementation MediapipeFacemesh {
    ChunkBasedFaceMeshRunner *runner;
}

RCT_EXPORT_MODULE()

-(BOOL)requiresMainQueueSetup {
    return YES;
}

// Example method
// See // https://reactnative.dev/docs/native-modules-ios
RCT_REMAP_METHOD(multiply,
                 multiplyWithA:(nonnull NSNumber*)a withB:(nonnull NSNumber*)b
                 withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)
{
    NSNumber *result = @([a floatValue] * [b floatValue]);
    
    resolve(result);
}

RCT_REMAP_METHOD(runFaceMeshWithFiles,
                 runFaceMeshWithFiles:(nonnull NSDictionary *)argumentsDict
                 withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)
{
    NSArray <NSString *>*filePaths = argumentsDict[@"files"];
    if(!filePaths) {
        NSError *error = [[NSError alloc] initWithDomain:@"SKRNFaceMesh" code:404 userInfo:nil];
        reject(@"NO_FILE_PATH", @"No File Path specified", error);
        return;
    }
    runner = [ChunkBasedFaceMeshRunner new];
    [[[runner processFilesAtPaths:filePaths]
      then:^id _Nullable(NSArray<NSArray<NSArray<NSArray<NSNumber *>*>*>*>* value) {
        NSLog(@"result from runner %@", value);
        resolve(value);
        return nil;
    }] catch:^(NSError * _Nonnull error) {
        reject(@"SKMediapipeLibraryError", @"An error occured in Switt's Mediapipe Library", error);
    }];
}

// This is for checking the crash that occurs whenever I allocate FaceMeshIOSLib (  `[FaceMeshIOSLib new]`  )
// The crash ends up to be from the logging library, `glog`, from its Lock() method which calls SAFE_PTHREAD internally.
// I suspect that somehow Mediapipe static library and React native are both obtaining the same locks and thus screwing up.
// Right now the fix is to Pods/glog/src/base/mutex.h and replace the MACRO line `if (is_safe_ && fncall(&mutex_) != 0)...` with a dumb {}

RCT_REMAP_METHOD(tryJustAlloc,
                 tryJustAllocWithOptions:(nonnull NSDictionary *)argumentsDict
                 withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)
{
    if(argumentsDict[@"lib"]) {
        FaceMeshIOSLib *lib = [FaceMeshIOSLib new];
        NSLog(@"allocated lib successfully");
        //        [self performSelector:@selector(whatdafak) withObject:nil afterDelay:10];
    }
    else {
        ChunkBasedFaceMeshRunner *runner = [ChunkBasedFaceMeshRunner new];
        NSLog(@"allocated runner successfully");
    }
}

RCT_REMAP_METHOD(runFaceMeshWithBase64Images,
                 runFaceMeshWithBase64Images:(nonnull NSDictionary *)argumentsDict
                 withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)
{
    NSArray <NSString *>*base64Images = argumentsDict[@"base64Images"];
    if(!base64Images) {
        NSError *error = [[NSError alloc] initWithDomain:@"SKRNFaceMesh" code:404 userInfo:nil];
        reject(@"NO_BASE64_IMAGES", @"No Images specified", error);
        return;
    }
    
    NSMutableArray <UIImage *>*images = [NSMutableArray new];
    for(NSString *b64 in base64Images) {
        [images addObject:[self decodeBase64ToImage:b64]];
    }
    runner = [ChunkBasedFaceMeshRunner new];
    [[[runner processImages:images]
      then:^id _Nullable(NSArray<NSArray<NSArray<NSArray<NSNumber *>*>*>*>* value) {
        NSLog(@"result from runner %@", value);
        resolve(value);
        return nil;
    }] catch:^(NSError * _Nonnull error) {
        reject(@"SKMediapipeLibraryError", @"An error occured in Switt's Mediapipe Library", error);
    }];
}

- (UIImage *)decodeBase64ToImage:(NSString *)strEncodeData {
    NSData *data = [[NSData alloc]initWithBase64EncodedString:strEncodeData options:NSDataBase64DecodingIgnoreUnknownCharacters];
    return [UIImage imageWithData:data];
}

@end
