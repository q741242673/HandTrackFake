# HandTrackFake
Simulate hand tracking movements for visionOS, in order to debug hand tracking on visionOS simulator.  
This module uses VNHumanHandPoseObservation on Mac/iPad to capture finger movement.  
Then send that hand tracking data to visionOS simulator on Mac via bluetooth.  
All you need is iPad (or iPhone) and Mac, to debug visionOS hand tracking.  
  
- Aug/30/2023: Now TrackingSender works on Mac Catalyst using mac front camera.  

## HandTrackFake module
HandTrackFake.swift
```swift
// Public properties
var enableFake = true
var rotateHands = false
var sessionState: MCSessionState = .notConnected
```

## Sample project
### TrackingSender
 - Capture your hand movement using iPad front camera.
 - Encode hand tracking data (2D) into Json.
 - Send that Json to TrackingReceiver.app via bluetooth.

AppDelegate.swift
```swift
let handTrackFake = HandTrackFake()
```

HandTrackingProvider.swift
```swift
// Activate fake data sender
if handTrackFake.enableFake {
    handTrackFake.initAsAdvertiser()
}

// Send fake data
let jsonStr = HandTrackJson2D(handTrackData: handJoints).jsonStr
handTrackFake.sendHandTrackData(jsonStr)
```

Info.plist
```
Privacy - Camera Usage Description
Privacy - Local Network Usage Description  
Bonjour services  
 - item 0 : _HandTrackFake._tcp  
 - item 1 : _HandTrackFake._udp  
```

### TrackingReceiver
 - Receive hand tracking data (Json) from TrackingSender.app via bluetooth.
 - Decode Json data into hand tracking data (3D).
 - Display hands (finger positions) on visionOS simulator display.

TrackingReceiverApp.swift
```swift
let handTrackFake = HandTrackFake()
```

ImmersiveView.swift
```swift
// Activate fake data browser
handTrackFake.initAsBrowser()

// Check connection status
let nowState = handTrackFake.sessionState

// Receive fake data, then convert to 3D hand tracking data
if handTrackFake.currentJsonString.count>0 {
    if let dt3D = HandTrackJson3D(jsonStr: handTrackFake.currentJsonString, rotate: handTrackFake.rotateHands) {
        let handCount = dt3D.handJoints.count
        if handCount>0 {
            fingerJoints1 = dt3D.handJoints[0]
        }
        if handCount>1 {
            fingerJoints2 = dt3D.handJoints[1]
        }
    }
}
```

Info.plist
```
Privacy - Local Network Usage Description  
Bonjour services  
 - item 0 : _HandTrackFake._tcp  
 - item 1 : _HandTrackFake._udp  
```

