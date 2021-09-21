//
//  ChunkBasedFaceMeshRunner.m
//  react-native-mediapipe-facemesh
//
//  Created by Switt Kongdachalert on 21/9/2564 BE.
//

#import "ChunkBasedFaceMeshRunner.h"

@implementation ChunkBasedFaceMeshRunner {
    FBLPromise *runningChunkPromise;
    NSMutableArray <NSArray<NSArray<NSArray <NSNumber *>*>*>*>*chunkFaceResults;
}
-(id)init {
    self = [super init];
    if(!self) return nil;
    [self setupModel];
    chunkFaceResults = [NSMutableArray new];
    return self;
}
-(void)setupModel {
    FaceMeshIOSLib *faceMesh = [FaceMeshIOSLib new];
    faceMesh.delegate = self;
    [faceMesh startGraph];
    self.faceMesh = faceMesh;
}
-(void)resetModel {
    [self setupModel];
}
-(void)didReceiveFaces:(NSArray<NSArray<FaceMeshIOSLibFaceLandmarkPoint *>*>*)faces {
    [chunkFaceResults addObject:[self numberOnlyLandmarksForFrameOut:faces]];
    if(chunkFaceResults.count >= self.numInRunningChunk) {
        // Done
        [self fulfillRunningChunk];
    }
}
-(FBLPromise <NSArray <NSArray<NSArray<NSArray <NSNumber *>*>*>*>*>*)processFilesAtPaths:(NSArray <NSString *>*)filePaths
{
    if(self.isRunning) {
        FBLPromise *prom = [FBLPromise pendingPromise];
        NSLog(@"Error: currently running");
        [prom reject:[NSError errorWithDomain:@"SKRNMediapipeFacemesh" code:-1 userInfo:nil]];
        return prom;
    }
    chunkFaceResults = [NSMutableArray new];
    _numInRunningChunk = filePaths.count;
    self.isRunning = YES;
    
    runningChunkPromise = [FBLPromise pendingPromise];
    [self processFilesAtPathsQueuer:filePaths];
    return runningChunkPromise;
}
-(void)processFilesAtPathsQueuer:(NSArray <NSString *>*)filePaths {
    FaceMeshIOSLib *faceMesh = self.faceMesh;
    for(NSString *filePath in filePaths) {
        NSString *path = [filePath hasPrefix:@"file://"] ? [filePath substringFromIndex:7] : filePath;
        UIImage *image = [UIImage imageWithContentsOfFile:path];
        CVPixelBufferRef buffer = [self createPixelBufferFromCGImage:image.CGImage];
        [faceMesh processVideoFrame:buffer];
        CVPixelBufferRelease(buffer);
    }
}
-(FBLPromise <NSArray <NSArray<NSArray<NSArray <NSNumber *>*>*>*>*>*)processImages:(NSArray <UIImage *>*)images {
    if(self.isRunning) {
        FBLPromise *prom = [FBLPromise pendingPromise];
        NSLog(@"Error: currently running");
        [prom reject:[NSError errorWithDomain:@"SKRNMediapipeFacemesh" code:-1 userInfo:nil]];
        return prom;
    }
    chunkFaceResults = [NSMutableArray new];
    _numInRunningChunk = images.count;
    self.isRunning = YES;
    
    runningChunkPromise = [FBLPromise pendingPromise];
    [self processImagesQueuer:images];
    return runningChunkPromise;
}
-(void)processImagesQueuer:(NSArray <UIImage *>*)images {
    FaceMeshIOSLib *faceMesh = self.faceMesh;
    for(UIImage *image in images) {
        CVPixelBufferRef buffer = [self createPixelBufferFromCGImage:image.CGImage];
        [faceMesh processVideoFrame:buffer];
        CVPixelBufferRelease(buffer);
    }
}

-(NSArray <NSArray<NSArray <NSNumber *>*>*>*)numberOnlyLandmarksForFrameOut:
(NSArray<NSArray<FaceMeshIOSLibFaceLandmarkPoint *>*>*)frameOutput
{
    NSMutableArray <NSArray<NSArray <NSNumber *>*>*>*frameFaces = [NSMutableArray new];
    for(NSArray <FaceMeshIOSLibFaceLandmarkPoint *>*inFace in frameOutput) {
        NSMutableArray <NSArray <NSNumber *>*>*points = [NSMutableArray new];
        for(FaceMeshIOSLibFaceLandmarkPoint *inPoint in inFace) {
            [points addObject:@[@(inPoint.x), @(inPoint.y), @(inPoint.z)]];
        }
        [frameFaces addObject:points];
    }
    return frameFaces;
}
-(void)fulfillRunningChunk {
    self.isRunning = NO;
    [runningChunkPromise fulfill:chunkFaceResults];
}
- (CVPixelBufferRef)createPixelBufferFromCGImage:(CGImageRef)image
{
    NSDictionary *options = @{
                              (NSString*)kCVPixelBufferCGImageCompatibilityKey : @YES,
                              (NSString*)kCVPixelBufferCGBitmapContextCompatibilityKey : @YES,
                              };

    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, CGImageGetWidth(image),
                        CGImageGetHeight(image), kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                        &pxbuffer);
    if (status!=kCVReturnSuccess) {
        NSLog(@"Operation failed");
    }
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);

    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);

    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, CGImageGetWidth(image),
                                                 CGImageGetHeight(image), 8, 4*CGImageGetWidth(image), rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);

    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    CGAffineTransform flipVertical = CGAffineTransformMake( 1, 0, 0, -1, 0, CGImageGetHeight(image) );
    CGContextConcatCTM(context, flipVertical);
    CGAffineTransform flipHorizontal = CGAffineTransformMake( -1.0, 0.0, 0.0, 1.0, CGImageGetWidth(image), 0.0 );
    CGContextConcatCTM(context, flipHorizontal);

    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);

    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    return pxbuffer;
}

@end
