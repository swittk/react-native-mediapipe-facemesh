import * as React from 'react';
import { Asset } from 'expo-asset';
import * as ImagePicker from 'expo-image-picker';

import { StyleSheet, View, Text, Alert, Button, Image } from 'react-native';
import MediapipeFacemesh from 'react-native-mediapipe-facemesh';
import FacemeshTester from './FacemeshTester';

async function pickImage() {
  let { status, canAskAgain } = await ImagePicker.getMediaLibraryPermissionsAsync();
  if (status != 'granted') {
    if (!canAskAgain) {
      Alert.alert('Cannot pick, permission was denied, please open settings');
      return;
    }
    ({ status } = await ImagePicker.requestMediaLibraryPermissionsAsync());
  }
  if (status != 'granted') {
    Alert.alert('Cannot browse, no permission');
    return;
  }
  const result = await ImagePicker.launchImageLibraryAsync({ mediaTypes: ImagePicker.MediaTypeOptions.Images });
  if (result.cancelled) {
    return;
  }
  const uri = result.uri;
  return uri;
}

export default function App() {
  const [imgPath, setImgPath] = React.useState<string>();
  React.useEffect(() => {
    // MediapipeFacemesh.multiply(3, 7).then(setResult);
  }, []);

  return (
    <View style={styles.container}>
      <Button title='Try alloc' onPress={async () => {
        await MediapipeFacemesh.tryJustAlloc({ lib: true });
        Alert.alert('OK');
      }} />
      <Button title='Pick image' onPress={async () => {
        const res = await pickImage();
        if (!res) return;
        setImgPath(res);
      }} />
      <FacemeshTester uri={imgPath} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
