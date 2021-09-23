//
//  ChunkBasedFaceMeshRunner.m
//  react-native-mediapipe-facemesh
//
//  Created by Switt Kongdachalert on 21/9/2564 BE.
//

#import "ChunkBasedFaceMeshRunner.h"


#define sizeof_array(ARRAY) (sizeof(ARRAY)/sizeof(ARRAY[0]))
// Sourced mostly from mediapipe's converter (https://github.com/google/mediapipe/blob/ecb5b5f44ab23ea620ef97a479407c699e424aa7/mediapipe/objc/util.cc)
// Using this instead of my own converter makes the code finally work..
CFDictionaryRef GetCVPixelBufferAttributesForGlCompatibility() {
  static CFDictionaryRef attrs = NULL;
  if (!attrs) {
    CFDictionaryRef empty_dict = CFDictionaryCreate(
        kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks,
        &kCFTypeDictionaryValueCallBacks);

    // To ensure compatibility with CVOpenGLESTextureCache, these attributes
    // should be present. However, on simulator this IOSurface attribute
    // actually causes CVOpenGLESTextureCache to fail. b/144850076
    const void* keys[] = {
#if !TARGET_IPHONE_SIMULATOR
      kCVPixelBufferIOSurfacePropertiesKey,
#endif  // !TARGET_IPHONE_SIMULATOR

#if TARGET_OS_OSX
      kCVPixelFormatOpenGLCompatibility,
#else
      kCVPixelFormatOpenGLESCompatibility,
#endif  // TARGET_OS_OSX
    };

    const void* values[] = {
#if !TARGET_IPHONE_SIMULATOR
      empty_dict,
#endif  // !TARGET_IPHONE_SIMULATOR
      kCFBooleanTrue
    };

    attrs = CFDictionaryCreate(
        kCFAllocatorDefault, keys, values, sizeof_array(values),
        &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFRelease(empty_dict);
  }
  return attrs;
}

// Sourced mostly from mediapipe's converter (https://github.com/google/mediapipe/blob/ecb5b5f44ab23ea620ef97a479407c699e424aa7/mediapipe/objc/util.cc)
// Using this instead of my own converter makes the code finally work..
CVPixelBufferRef CreateCVPixelBufferFromCGImage(
    CGImageRef image) {
  size_t width = CGImageGetWidth(image);
  size_t height = CGImageGetHeight(image);
  CVPixelBufferRef pixel_buffer;

  CVReturn status = CVPixelBufferCreate(
      kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA,
      GetCVPixelBufferAttributesForGlCompatibility(), &pixel_buffer);
    assert(status == kCVReturnSuccess);
//      << "failed to create pixel buffer: " << status;
  status = CVPixelBufferLockBaseAddress(pixel_buffer, 0);
    assert(status == kCVReturnSuccess);
//      << "CVPixelBufferLockBaseAddress failed: " << status;

  void* base_address = CVPixelBufferGetBaseAddress(pixel_buffer);
  CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
  size_t bytes_per_row = CVPixelBufferGetBytesPerRow(pixel_buffer);
  CGContextRef context = CGBitmapContextCreate(
      base_address, width, height, 8, bytes_per_row, color_space,
      kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
  CGRect rect = CGRectMake(0, 0, width, height);
  CGContextClearRect(context, rect);
  CGContextDrawImage(context, rect, image);

  CGContextRelease(context);
  CGColorSpaceRelease(color_space);
  status = CVPixelBufferUnlockBaseAddress(pixel_buffer, 0);
    assert(status == kCVReturnSuccess);
//      << "CVPixelBufferUnlockBaseAddress failed: " << status;
    return pixel_buffer;
}


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
    dispatch_async(dispatch_get_main_queue(), ^{
//        NSLog(@"received faces %@", faces);
        [chunkFaceResults addObject:[self numberOnlyLandmarksForFrameOut:faces]];
        if(chunkFaceResults.count >= self.numInRunningChunk) {
            // Done
            [self fulfillRunningChunk];
        }

    });
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
//        NSLog(@"image %@", image);
        CVPixelBufferRef buffer = CreateCVPixelBufferFromCGImage([self orientationUpImage:image].CGImage);//[self createIOSurfaceBackedPixelBufferFromCGImage:image.CGImage];
//        NSLog(@"buffer %ld", CVPixelBufferGetWidth(buffer));
        [faceMesh processVideoFrame:buffer];
//        NSLog(@"sent in frame, the delegate is %@", faceMesh.delegate);
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
        CVPixelBufferRef buffer = CreateCVPixelBufferFromCGImage([self orientationUpImage:image].CGImage);
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
- (CVPixelBufferRef)createIOSurfaceBackedPixelBufferFromCGImage:(CGImageRef)image
{
    CGImageRetain(image);
    NSDictionary *options = @{
                              (NSString*)kCVPixelBufferCGImageCompatibilityKey : @YES,
                              (NSString*)kCVPixelBufferCGBitmapContextCompatibilityKey : @YES,
                              (NSString*)kCVPixelBufferIOSurfacePropertiesKey: @{}
                              };

    CVPixelBufferRef pxbuffer = NULL;
    
    // Mediapipe only supports BGRA/RGBA (`failed: Only BGRA/RGBA textures are supported`)
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, CGImageGetWidth(image),
                        CGImageGetHeight(image),
                                          kCVPixelFormatType_32BGRA, //kCVPixelFormatType_32ABGR,//kCVPixelFormatType_32ARGB,
                                          (__bridge CFDictionaryRef) options,
                        &pxbuffer);
    if (status!=kCVReturnSuccess) {
        NSLog(@"Operation failed");
    }
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);

    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, CVPixelBufferGetWidth(pxbuffer),
                                                 CVPixelBufferGetHeight(pxbuffer), 8, CVPixelBufferGetBytesPerRow(pxbuffer), rgbColorSpace,
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
    CGImageRelease(image);
    return pxbuffer;
}

-(UIImage *)orientationUpImage:(UIImage *)image {
    if(image.imageOrientation == UIImageOrientationUp) {
        return image;
    }
    CGSize size = image.size;
    if(image.scale != 1) {
        size.width *= image.scale;
        size.height *= image.scale;
    }
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0,0,size.width,size.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


@end
