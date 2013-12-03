FRIDAY, JUNE 10, 2011

Acoustic Echo Cancelation working
Acoustic Echo Cancellation is part of Flash Player 10.3.
Users are able to enjoy live audio/video communication without the risk of acoustic feedback. Previous post on Flash vs. AEC.

It's a bit tricky to implement yet.

First get the latest Flash Player Content Debugger 10.3.181.22, not the incubator version.

With the current Build of the Flex SDK (4.5.0.20967) that's also shipped with Flash Builder 4.5, you need to add this playerglobal.swc to the SDK's /frameworks/libs/player/10.3/ directory.

Add additional mxmlc compiler arguments with your IDE or directly to the actionscript properties file.
// Specifies the version of Flash Player that you want to target with the application, targets the correct playerglobal.swc.
-target-version=10.3

// Specifies the SWF file format version of the output SWF file.
-swf-version=12

Then use this code snippet in your ActionScript Class.
...
// Gets reference to the Microphone instance with enhanced options.
var microphone:Microphone = Microphone.getEnhancedMicrophone(deviceIndex);
microphone.codec = SoundCodec.SPEEX;
var enhancedOptions = new MicrophoneEnhancedOptions();

// Sets AEC mode for users without a headset.
enhancedOptions.mode = MicrophoneEnhancedMode.FULL_DUPLEX;
microphone.enhancedOptions = enhancedOptions;
...

Have fun!

Example ChatRoom using Red5 Media Server running on an Amazon EC2 instance and Adobe Cirrus rendezvous service. It's based on the direct RTMFP peer-to-peer connection feature of Adobe Flash Player 10

POSTED BY JOACHIM AT 8:54 AM 2 COMMENTS: LINKS TO THIS POST 
LABELS: ACTIONSCRIPT, AEC, CIRRUS, EXAMPLES, FLASH, FLASH MEDIA INTERACTIVE SERVER, RED5, RTMFP
WEDNESDAY, DECEMBER 15, 2010

Acoustic Echo Cancellation support for Flash Player
If you ever developed a Flash application with live audio/video communication you probably ran into trouble with acoustic echo/feedback.
The flash.media.useEchoSuppression property doesn't solve the problem Flash Player had no AEC support.
Maybe you tried some workarounds but faced the requirement that the user had to use a headset for a good experience.

Please read my latest post about the current implementation of the AEC feature.

Fortunately AEC support will be part of a Flash Player version in 2011.
MicrophoneEnhancedOptions and MicrophoneEnhancedMode are not included in the current beta version of the Flash Player (10.2) but according to this Jira ticket from the Adobe Flash Player Bug and Issue Management System this feature is developed and will be part of an upcoming player version in 2011.

The code, when both speaker and microphone are used simultaneously, might look like this:

...
import flash.media.Microphone;
import flash.media.MicrophoneEnhancedMode;
import flash.media.MicrophoneEnhancedOptions;
import flash.media.SoundCodec;
...
var microphone:Microphone = Microphone.getEnhancedMicrophone(deviceIndex);
microphone.codec = SoundCodec.SPEEX;
var enhancedOptions = new MicrophoneEnhancedOptions();
enhancedOptions.mode = MicrophoneEnhancedMode.FULL_DUPLEX;
microphone.enhancedOptions = enhancedOptions;
...
Example chat room using Red5 and Adobe Cirrus aka Stratus rendezvous service, i created for a small ActionScript 3 VideoChatAPI in February 2009.
I developed it for a collaboration software of Dorian. It's using the direct RTMFP peer to peer connection feature of Flash Player 10, the 10.1 multicast feature is not suitable in this case.

POSTED BY JOACHIM AT 7:40 AM 4 COMMENTS: LINKS TO THIS POST 
LABELS: ACTIONSCRIPT, AEC, CIRRUS, EXAMPLES, FLASH, FLASH MEDIA INTERACTIVE SERVER, RED5, RTMFP