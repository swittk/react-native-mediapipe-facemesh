import { NativeModules } from 'react-native';

type MediapipeFacemeshType = {
  multiply(a: number, b: number): Promise<number>;
};

const { MediapipeFacemesh } = NativeModules;

export default MediapipeFacemesh as MediapipeFacemeshType;
