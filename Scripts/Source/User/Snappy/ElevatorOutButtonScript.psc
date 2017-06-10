Scriptname Snappy:ElevatorOutButtonScript extends ObjectReference
;based on the DLC05 elevator scripts

;-- Properties --------------------------------------
Message Property ElevatorBtnMsg1 Auto Const mandatory
{ message to display when placed }
int Property FloorNumber = 1 Auto Hidden ;default floor nr
Snappy:MainElevatorScript Property elevatorScript Auto hidden;link to the elevatorScript
Keyword Property LinkCustom05 Auto Const ; different keywords for different floors or same for all?
{ keyword link to the button }
Keyword Property LinkCustom12 Auto Const
{ keyword link to the elevator }
Activator Property elevator Auto Const mandatory
{ what to look for when placing the button }
string Property PlayAnimation = "Play02" Auto conditional
{ Animation for the buttons to play when on }

bool hasPower
Function SetHasPower(bool shouldBePowered)
	hasPower = shouldBePowered
	if hasPower
		PlayAnimation("Play02")
	else
		PlayAnimation("StartOff")
	endif
EndFunction

;-- Events ---------------------------------------
Event OnWorkshopObjectGrabbed(ObjectReference akReference)
	;highlight elevator when grabbed
  elevatorScript.glow("Play")
EndEvent

Event OnWorkshopObjectMoved(ObjectReference akReference)
	;stop highlight when placed again
  elevatorScript.glow("Stop")
EndEvent

Event OnWorkshopObjectPlaced(ObjectReference akReference)
	ObjectReference elevatorRef = Game.FindClosestReferenceOfTypeFromRef(elevator, Self, 1024.0).GetLinkedRef(LinkCustom12)

	if(elevatorRef!=None)
		elevatorScript = elevatorRef as Snappy:MainElevatorScript
		elevatorScript.glow("On")

		int nrFloors = elevatorScript.nrFloors ; get elevator nr of floors

	  FloorNumber = ElevatorBtnMsg1.Show() ;show floor nr popup
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
			if (GetLinkedRef() as Snappy:MainElevatorScript).GoToFloor(FloorNumber)
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
	Delete()
EndEvent
