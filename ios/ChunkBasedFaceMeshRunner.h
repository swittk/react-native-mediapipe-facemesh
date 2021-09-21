//
//  ChunkBasedFaceMeshRunner.h
//  react-native-mediapipe-facemesh
//
//  Created by Switt Kongdachalert on 21/9/2564 BE.
//

#import <Foundation/Foundation.h>
#import "FaceMeshIOSLibFramework.h"
#import "FBLPromises.h"

NS_ASSUME_NONNULL_BEGIN

@interface ChunkBasedFaceMeshRunner : NSObject <FaceMeshIOSLibDelegate>
@property (retain) FaceMeshIOSLib *faceMesh;
/** If our runner is currently processing a batch of data */
@property (nonatomic) BOOL isRunning;
@property (readonly) NSInteger numInRunningChunk;

/** Array, dimensions = (frames, faces, points, x/y/z)*/
-(FBLPromise <NSArray <NSArray<NSArray<NSArray <NSNumber *>*>*>*>*>*)processFilesAtPaths:(NSArray <NSString *>*)filePaths;
-(void)resetModel;
-(FBLPromise <NSArray <NSArray<NSArray<NSArray <NSNumber *>*>*>*>*>*)processImages:(NSArray <UIImage *>*)images;
@end

NS_ASSUME_NONNULL_END
