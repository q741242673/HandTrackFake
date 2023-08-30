# HandTrackFake
Fake hand tracking module for visionOS, in order to debug hand tracking on visionOS simulator.  
This module uses VNHumanHandPoseObservation on iPad device to capture finger movement.  
Then send that hand tracking data to visionOS simulator on Mac via bluetooth.  
All you need is iPad (or iPhone) and Mac, to debug visionOS hand tracking.  
  
- Aug/30/2023: Now TrackingSender works on Mac Catalyst using mac front camera.  

## HandTrackFake module
HandTrackFake.swift
## Sample project
### TrackingSender
 - Capture your hand movement using iPad front camera.
 - Encode hand tracking data (2D) into Json.
 - Send that Json to TrackingReceiver.app via bluetooth.
### TrackingReceiver
 - Receive hand tracking data (Json) from TrackingSender.app via bluetooth.
 - Decode Json data into hand tracking data (3D).
 - Display hands (finger positions) on visionOS simulator display.
