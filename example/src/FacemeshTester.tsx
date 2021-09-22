import * as React from 'react';
import { Asset } from 'expo-asset';
import * as ImagePicker from 'expo-image-picker';

import { StyleSheet, View, Text, Alert, Button, Image, StyleProp, ViewStyle } from 'react-native';
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
      console.log('results shape', getShape(res)); //  [ 1, 1, 468, 3 ]
      setResult(res);
      // console.log('results are', res);
    }} />
    <RenderFaceBox
      face={result?.[0][0]}
      imageUri={uri}
    />
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
    return dims;
  }
  else {
    return undefined;
  }
}
export default FacemeshTester;



export const RenderFaceBox = React.memo((props: {
  face?: number[][],
  style?: StyleProp<ViewStyle>,
  imageUri?: string
}) => {
  const {
    style,
    face,
    imageUri
  } = props;
  const [imSize, setImSize] = React.useState({ width: 250, height: 250 });
  React.useEffect(() => {
    if (!imageUri) return;
    (async () => {
      const prom = new Promise<{ width: number, height: number }>((resolve, reject) => {
        Image.getSize(imageUri, (w, h) => {
          resolve({ width: w, height: h });
        }, reject);
      });
      const size = await prom;
      setImSize(size);
    })();
  }, [imageUri]);
  // shape of FaceMesh output is expected to be (1,1,1,1404)
  // console.log('rendered', faces.length, 'faces');
  // const validArray = React.useMemo(() => {
  //   return arrayEqual(face.shape, [1, 1, 1, 1404]);
  // }, [face]);
  const landmarkCircles = React.useMemo(()=>{
    if(!face) return undefined;
    const alldata = face;
    const datalen = alldata.length;
    const landmarkCircles: JSX.Element[] = [];
    for (let i = 0; i < datalen; i += 1) {
      const point = alldata[i];
      const x = point[0];
      const y = point[1];
      // const z = data[i + 2];
      landmarkCircles.push(<View
        key={`landmark_${i}`}
        style={{
          width: 1.5, height: 1.5, borderRadius: 0.5,
          left: `${x * 100}%`,
          top: `${y * 100}%`,
          backgroundColor: 'blue',
          position: 'absolute'
        }}
      />);
    }
    return landmarkCircles;
  }, [face]);

  return <View
    style={[{ width: 250, height: 250 }, style]}
  >
    <Image source={{ uri: imageUri }} style={{ aspectRatio: imSize.width / imSize.height, flex: 1 }} resizeMode='contain' />
    <View style={StyleSheet.absoluteFill} pointerEvents='none'>
      <View style={{ aspectRatio: imSize.width / imSize.height, flex: 1 }}>
        {landmarkCircles}
      </View>
    </View>
  </View>;
})
