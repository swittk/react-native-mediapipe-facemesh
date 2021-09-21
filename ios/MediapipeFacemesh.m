#import "MediapipeFacemesh.h"
#import "FaceMeshIOSLibFramework.h"
#import "ChunkBasedFaceMeshRunner.h"

@implementation MediapipeFacemesh

RCT_EXPORT_MODULE()

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
    ChunkBasedFaceMeshRunner *runner = [ChunkBasedFaceMeshRunner new];
    [[[runner processFilesAtPaths:filePaths]
      then:^id _Nullable(NSArray<NSArray<NSArray<NSArray<NSNumber *>*>*>*>* value) {
        resolve(value);
        return nil;
    }] catch:^(NSError * _Nonnull error) {
        reject(@"SKMediapipeLibraryError", @"An error occured in Switt's Mediapipe Library", error);
    }];
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
    ChunkBasedFaceMeshRunner *runner = [ChunkBasedFaceMeshRunner new];
    [[[runner processImages:images]
      then:^id _Nullable(NSArray<NSArray<NSArray<NSArray<NSNumber *>*>*>*>* value) {
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
