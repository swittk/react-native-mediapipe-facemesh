# react-native-mediapipe-facemesh

Mediapipe Facemesh fplugin or React Native

WIP
Currently can build, but crashes due to `glog` mutex somehow being stupid and throwing SIGABRT (abort()) when calling inside the react native bridge.
I suspect MediaPipe usage of glog might conflict with React Native's extensive usage.

Changing this zone at /ios/Pods/glog/src/base/mutex.h makes it work (Basically making glog's mutex useless).
From 
```
#define SAFE_PTHREAD(fncall)  do {   /* run fncall if is_safe_ is true */  \
  if (is_safe_ && fncall(&mutex_) != 0) abort();                           \
} while (0)
```
to
```
#define SAFE_PTHREAD(fncall)  do {   /* run fncall if is_safe_ is true */  \
if (is_safe_ && fncall(&mutex_) != 0) {} /*{ printf("killing app because is safe and fncall is not zero :("); abort();}*/\
} while (0)
```

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
