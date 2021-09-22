# react-native-mediapipe-facemesh

Mediapipe Facemesh fplugin or React Native

WIP
Currently can build, but crashes due to `glog` mutex somehow being stupid and throwing SIGABRT (abort()) when calling inside the react native bridge.
I suspect MediaPipe usage of glog might conflict with React Native's extensive usage.

## Installation

```sh
npm install react-native-mediapipe-facemesh
```

## Usage

```js
import MediapipeFacemesh from "react-native-mediapipe-facemesh";

// ...

const result = await MediapipeFacemesh.multiply(3, 7);
```

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT
