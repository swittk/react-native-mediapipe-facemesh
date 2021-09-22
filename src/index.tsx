import { NativeModules } from 'react-native';

type MediapipeFacemeshType = {
  // multiply(a: number, b: number): Promise<number>;
  /**
   * @param args files: URLs of files to process
   * @returns a [frames, faces, points, 3 (point_x_y_z)] tensor (array)
   */
  runFaceMeshWithFiles(args: { files: string[] }): Promise<number[][][][]>;
  /**
   * @param base64Images Base 64 images of frames wanted to process
   * @returns a [frames, faces, points, 3 (point_x_y_z)] tensor (array)
   */
  runFaceMeshWithBase64Images(args: { base64Images: string[] }): Promise<number[][][][]>;


  /** Debug */
  tryJustAlloc(args: { lib?: boolean }): Promise<void>;
};

const { MediapipeFacemesh } = NativeModules;

export default MediapipeFacemesh as MediapipeFacemeshType;
