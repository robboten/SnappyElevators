Scriptname Snappy:SnappyElevatorButtonScript3 extends ObjectReference

;-- Properties --------------------------------------
ObjectReference Property btnRef Auto Const
Message Property ElevatorBtnMsg1 Auto Const mandatory
Message Property ButtonText Auto Const mandatory
int Property FloorNumber = 1 Auto Hidden
Snappy:SnappyElevatorScript5 Property elevatorScript Auto

EffectShader Property HighlightUnpoweredFX Auto Const
{ Effect Shader to highlight unpowered objects }

Keyword Property LinkCustom05 Auto Const
Keyword Property LinkCustom12 Auto Const

Activator Property elevator Auto Const mandatory

string Property PlayAnimation = "Play02" Auto conditional
{ node in the nif to place outer doors at - without last digit }

bool hasPower
Function SetHasPower(bool shouldBePowered)
	hasPower = shouldBePowered
	if hasPower
		PlayAnimation("Play02")
	else
		PlayAnimation("StartOff")
	endif
EndFunction

;-- Variables ---------------------------------------
ObjectReference elevatorRef = None

;-- Events ---------------------------------------
Event OnWorkshopObjectGrabbed(ObjectReference akReference)
  ;ObjectReference elevatorRef = Game.FindClosestReferenceOfTypeFromRef(elevator, Self, 1024.0)
  elevatorScript.glow("Play")
EndEvent

Event OnWorkshopObjectMoved(ObjectReference akReference)
  ;ObjectReference elevatorRef = Game.FindClosestReferenceOfTypeFromRef(elevator, Self, 1024.0)
  elevatorScript.glow("Stop")
EndEvent

Event OnWorkshopObjectPlaced(ObjectReference akReference)
  elevatorRef = Game.FindClosestReferenceOfTypeFromRef(elevator, Self, 1024.0).GetLinkedRef(LinkCustom12)

	if(elevatorRef!=None)
		elevatorScript = elevatorRef as Snappy:SnappyElevatorScript5
		elevatorScript.glow("On")

		int nrFloors = elevatorScript.nrFloors ; get elevator nr of floors

	  FloorNumber = ElevatorBtnMsg1.Show() ;show floor nr popup
	  ;Self.SetActivateTextOverride(ButtonText) ; doesn't work as intended...
	  Self.SetLinkedRef(elevatorRef as ObjectReference, None)
	  elevatorRef.SetLinkedRef(Self, LinkCustom05)
	  Self.RegisterForRemoteEvent(Self as ObjectReference, "OnWorkshopObjectDestroyed")
	  PlayAnimation("StartOff")
		elevatorScript.glow("Stop")
	else
	    Debug.MessageBox("No Nearby Elevator Found!")
	endIf
	elevatorScript.glow("Stop")
EndEvent

Auto State Ready
	Event OnActivate(ObjectReference akActivator)
		GoToState("busy")
		;if hasPower
			;Play the button press anim
			PlayAnimation(PlayAnimation)
			;If the elevator is busy, immediately go back
			if (GetLinkedRef() as Snappy:SnappyElevatorScript5).GoToFloor(FloorNumber)
				Debug.Trace(self + ": myElevator is busy")
				utility.wait(1.0)
				PlayAnimation("StartOff")
				GoToState("Ready")
			else 	;This occurs if the elevator is NOT busy
					;and happens after it reaches the floor intended
				PlayAnimation("StartOff")
				GoToState("Ready")
			endif
		;else
		;	DLC05_ElevatorRequiresPowerMessage.Show()
			;GoToState("Ready")
		;endif
	EndEvent
EndState

State busy
EndState

Event ObjectReference.OnWorkshopObjectDestroyed(ObjectReference akSender, ObjectReference akActionRef)
	Debug.Trace(self + ": Has Received OnWorkshopObjectDestroyed !!!!!")
	elevatorRef = None
	elevatorRef.Delete()
	Delete()
EndEvent
