package
{
	import flash.events.MouseEvent;
	import flash.events.NetStatusEvent;
	import flash.events.StatusEvent;
	import flash.external.ExternalInterface;
	import flash.media.Camera;
	import flash.media.Microphone;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.system.Capabilities;
	import flash.system.Security;
	import flash.utils.Timer;
	import flash.utils.setInterval;
	import flash.media.SoundCodec;
	import flash.media.MicrophoneEnhancedOptions;
	import flash.media.MicrophoneEnhancedMode;
	
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.Text;
	import mx.controls.TextInput;
	import mx.core.Application;
	import mx.core.FlexGlobals;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	import mx.events.FlexEvent;

	public class ChatController extends Application
	{
		Security.LOCAL_TRUSTED;
		
		private var nc:NetConnection = null;
		private var camera:Camera;
		private var microphone:Microphone;
		private var nsPublish:NetStream = null;                      
		private var nsPlay:NetStream = null;
		private var videoCamera:Video;
		private var videoRemote:Video;
		private var isEnabled:Boolean;
		public var videoRemoteContainer:UIComponent;
		public var videoCameraContainer:UIComponent;
		public var doPublish:Button;
		public var doSubscribe:Button;
		public var connectButton:Button;
		public var fpsText:Text;
		public var bufferLenText:Text;
		public var connectStr:TextInput;
		public var publishName:TextInput;
		public var subscribeName:TextInput;
		public var playerVersion:Text;
		public var prompt:Text;

		public function ChatController()
		{
			addEventListener(FlexEvent.APPLICATION_COMPLETE,mainInit); 	
		}

		
		private function mainInit(event:FlexEvent):void
		{
			subscribeName.text =  FlexGlobals.topLevelApplication.parameters.userId;
			publishName.text = FlexGlobals.topLevelApplication.parameters.userId;
			playerVersion.text = Capabilities.version+" (Flex)";
			stage.align = "MC";
			stage.scaleMode = "showAll";

			

			
			
			connectStr.text = String(FlexGlobals.topLevelApplication.parameters.location) //"rtmp://localhost/videochat";
			//Alert.show( String(FlexGlobals.topLevelApplication.parameters.location), "test", Alert.YES|Alert.NO|Alert.CANCEL);
			connectButton.addEventListener(MouseEvent.CLICK, doConnect);

			doPublish.addEventListener(MouseEvent.CLICK, publish);
			
			doSubscribe.addEventListener(MouseEvent.CLICK, subscribe);

		
			enablePlayControls(false);
			

			if(FlexGlobals.topLevelApplication.parameters.type == "publishVideo"){
				videoCamera = new Video(480, 360);
				videoCameraContainer.addChild(videoCamera);
				videoRemoteContainer.visible = false;
				startCamera();
				doConnect();
			}
			else if(FlexGlobals.topLevelApplication.parameters.type == "publishAudio"){
				startMicrophone();
				doConnect();
			}
			else if(FlexGlobals.topLevelApplication.parameters.type == "subscribeVideo"){
				videoCameraContainer.visible = false;
				videoRemote = new Video(480, 360);
				videoRemoteContainer.addChild(videoRemote);
				nc = new NetConnection();
				nc.connect(connectStr.text);
				nc.addEventListener(NetStatusEvent.NET_STATUS, ncOnStatus);
			}
			else if(FlexGlobals.topLevelApplication.parameters.type == "subscribeAudio"){
				nc = new NetConnection();
				nc.connect(connectStr.text);
				nc.addEventListener(NetStatusEvent.NET_STATUS, ncOnStatus);
			}
			
		}
		
		private function startCamera():void
		{	
			// get the default Flash camera and microphone
			camera = Camera.getCamera();
			camera.addEventListener(StatusEvent.STATUS, this.onCamStatus);
			// here are all the quality and performance settings that we suggest
			camera.setMode(480, 360, 15, false);
			camera.setQuality(0, 80); //Vorherwar 0,80
			camera.setKeyFrameInterval(15); // vorher war 30
		}
		public static const POLL_INTERVAL:uint = 300;

		private function startMicrophone():void
		{	
			microphone = Microphone.getEnhancedMicrophone();
			var options:MicrophoneEnhancedOptions = new MicrophoneEnhancedOptions();
			options.mode = MicrophoneEnhancedMode.FULL_DUPLEX;
			microphone.enhancedOptions = options;
			//microphone.rate = 11; // Philipp Seeser Added 13.08.2013
			microphone.setSilenceLevel(0); // origin it was 0
			microphone.codec = SoundCodec.SPEEX; // Philipp Seeser Added 13.08.2013
			microphone.encodeQuality = 8; // Philipp Seeser Added 13.08.2013
			microphone.framesPerPacket = 2; // Philipp Seeser Added 13.08.2013
			//microphone.setLoopBack(true); // Philipp Seeser Added
			microphone.setUseEchoSuppression(true); // Philipp Seeser Added
			microphone.addEventListener(StatusEvent.STATUS, this.onMicStatus);
			var micActivity:Boolean = false;
			setInterval(
				function():void {
					if(microphone.activityLevel > 0){
						ExternalInterface.call("activityLevel",microphone.activityLevel);
						micActivity = true;
					}else if(micActivity){
						ExternalInterface.call("activityLevel",microphone.activityLevel);
						micActivity = false;
					}
					
				},
				POLL_INTERVAL);
		}
		private function onCamStatus(event:StatusEvent):void
		{
			if (event.code == "Camera.Unmuted")
			{
				ExternalInterface.call("startCamera");
			} 
		}
		private function onMicStatus(event:StatusEvent):void
		{
			if (event.code == "Microphone.Unmuted")
			{
				ExternalInterface.call("startMicrophone");
			} 
		}

		

		
		private function ncOnStatus(infoObject:NetStatusEvent):void
		{
			trace("nc: "+infoObject.info.code+" ("+infoObject.info.description+")");
			if (infoObject.info.code == "NetConnection.Connect.Success"){
				ExternalInterface.call("rtmpConnectionSuccess");
				if(FlexGlobals.topLevelApplication.parameters.type == "publishVideo" ||FlexGlobals.topLevelApplication.parameters.type == "publishAudio" ){
					publish();
				}
				else if(FlexGlobals.topLevelApplication.parameters.type == "subscribeVideo" || FlexGlobals.topLevelApplication.parameters.type == "subscribeAudio"){
					subscribe();
				}
				
			}
			else if (infoObject.info.code == "NetConnection.Connect.Failed")
				ExternalInterface.call("rtmpConnectionFailed");
			else if (infoObject.info.code == "NetConnection.Connect.Rejected")
				ExternalInterface.call("rtmpConnectionFailed");
			else if (infoObject.info.code == "NetConnection.Connect.Closed"){
				ExternalInterface.call("rtmpConnectionFailed");
				this.mainInit(null);
			}
		}
		
		private function doConnect(event:MouseEvent = null):void
		{
			// connect to the Wowza Media Server
			if (nc == null)
			{
				// create a connection to the wowza media server
				nc = new NetConnection();
				nc.connect(connectStr.text);
				
				// get status information from the NetConnection object
				nc.addEventListener(NetStatusEvent.NET_STATUS, ncOnStatus);
				
				connectButton.label = "Stop";
				
				// uncomment this to monitor frame rate and buffer length
				//setInterval(updateStreamValues, 500);
				if(FlexGlobals.topLevelApplication.parameters.type == "publishVideo"){
					videoCamera.clear();
					videoCamera.attachCamera(camera);
				}
				
				enablePlayControls(true);
				
			}
			else
			{
				nsPublish = null;
				nsPlay = null;
		
				videoCamera.attachCamera(null);
				videoCamera.clear();
				
				videoRemote.attachNetStream(null);
				videoRemote.clear();
				
				nc.close();
				nc = null;
				
				enablePlayControls(false);
		
				doSubscribe.label = 'Play';
				doPublish.label = 'Publish';
				
				connectButton.label = "Connect";
				prompt.text = "";
			}
		}
		
		private function enablePlayControls(isEnable:Boolean):void
		{
			doPublish.enabled = isEnable;
			doSubscribe.enabled = isEnable;
			publishName.enabled = isEnable;
			subscribeName.enabled = isEnable;
		}
		
		// function to monitor the frame rate and buffer length
		private function updateStreamValues():void
		{
			if (nsPlay != null)
			{
				fpsText.text = (Math.round(nsPlay.currentFPS*1000)/1000)+" fps";
				bufferLenText.text = (Math.round(nsPlay.bufferLength*1000)/1000)+" secs";
			}
			else
			{
				fpsText.text = "";
				bufferLenText.text = "";
			}
		}
		
		private function nsPlayOnStatus(infoObject:NetStatusEvent):void
		{
			trace("nsPlay: "+infoObject.info.code+" ("+infoObject.info.description+")");
			if (infoObject.info.code == "NetStream.Play.StreamNotFound" || infoObject.info.code == "NetStream.Play.Failed")
				prompt.text = infoObject.info.description;
		}
		
		private function subscribe(event:MouseEvent = null):void
		{
			if (doSubscribe.label == 'Play')
			{
				// create a new NetStream object for video playback
				nsPlay = new NetStream(nc);
				
				// trace the NetStream status information
				nsPlay.addEventListener(NetStatusEvent.NET_STATUS, nsPlayOnStatus);
				
				var nsPlayClientObj:Object = new Object();
				nsPlay.client = nsPlayClientObj;
				nsPlayClientObj.onMetaData = function(infoObject:Object):void
				{
					trace("onMetaData");
					
					// print debug information about the metaData
					for (var propName:String in infoObject)
					{
						trace("  "+propName + " = " + infoObject[propName]);
					}
				};		
		
				// set the buffer time to zero since it is chat
				nsPlay.bufferTime = 0;
				
				// subscribe to the named stream
				nsPlay.play(subscribeName.text);
				videoRemote.attachNetStream(nsPlay);
				// attach to the stream
				if(FlexGlobals.topLevelApplication.parameters.type == "subscribeVideo"){
					videoRemote.attachNetStream(nsPlay);
				}
				
				doSubscribe.label = 'Stop';
			}
			else
			{		
				// here we are shutting down the connection to the server
				videoRemote.attachNetStream(null);
				nsPlay.play(null);
				nsPlay.close();
		
				doSubscribe.label = 'Play';
			}
		}
		
		private function nsPublishOnStatus(infoObject:NetStatusEvent):void
		{
			trace("nsPublish: "+infoObject.info.code+" ("+infoObject.info.description+")");
			if (infoObject.info.code == "NetStream.Play.StreamNotFound" || infoObject.info.code == "NetStream.Play.Failed")
				prompt.text = infoObject.info.description;
		}
		
		public function publish(event:MouseEvent = null):void
		{
			if (doPublish.label == 'Publish')
			{
				// create a new NetStream object for video publishing
				nsPublish = new NetStream(nc);
				
				nsPublish.addEventListener(NetStatusEvent.NET_STATUS, nsPublishOnStatus);
				
				// set the buffer time to zero since it is chat
				nsPublish.bufferTime = 0;
			
				// publish the stream by name
				nsPublish.publish(publishName.text);
				
				// add custom metadata to the stream
				var metaData:Object = new Object();
				metaData["description"] = "Chat using VideoChat example."
				nsPublish.send("@setDataFrame", "onMetaData", metaData);
		
				// attach the camera and microphone to the server
				if(FlexGlobals.topLevelApplication.parameters.type == "publishVideo"){
				nsPublish.attachCamera(camera);
					if(!camera.muted){
						ExternalInterface.call("startCamera");
					}
				}
				if(FlexGlobals.topLevelApplication.parameters.type == "publishAudio"){
					nsPublish.attachAudio(microphone);
					if(!microphone.muted){
						ExternalInterface.call("startMicrophone");
					}
				}
				
				doPublish.label = 'Stop';
			}
			else
			{
				// here we are shutting down the connection to the server
				nsPublish.attachCamera(null);
				nsPublish.attachAudio(null);
				nsPublish.publish("null");
				nsPublish.close();
		
				doPublish.label = 'Publish';
			}
		}
		
	}
}