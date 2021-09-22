import * as React from 'react';
import { Asset } from 'expo-asset';
import * as ImagePicker from 'expo-image-picker';

import { StyleSheet, View, Text, Alert, Button, Image } from 'react-native';
import MediapipeFacemesh from 'react-native-mediapipe-facemesh';

const FacemeshTester = React.memo((props: {
  uri?: string
}) => {
  const { uri } = props;
  const [result, setResult] = React.useState<number[][][][]>();

  return <View>
    <Button title='Run Facemesh' onPress={async () => {
      if (!uri) return;
      const res = await MediapipeFacemesh.runFaceMeshWithFiles({ files: [uri] });
      if (!res) {
        console.log('result nil');
        return;
      }
      setResult(res);

      console.log('results shape', getShape(res));
      console.log('results are', res);
    }} />
    <Image source={{ uri: uri }} style={{ width: 320, height: 320 }} resizeMode='contain' />
  </View>
})
function getShape(obj:any[]): number[]|undefined {
  const dims : number[] = [];
  if(obj.length) {
    dims.push(obj.length);
    if(obj.length > 0) {
      const nextShapes = getShape(obj[0]);
      if(nextShapes) {
        dims.push(...nextShapes);
      }
    }
  }
  else {
    return undefined;
  }
}
export default FacemeshTester;