ScriptName Snappy:MainElevatorScript extends ObjectReference hidden

;-- Structs -----------------------------------------
Struct ButtonData
	Activator Button
	string Node
	Keyword LinkKeyword
	bool AttachToTrack
EndStruct

;-- Properties --------------------------------------
Group Required_Properties collapsedonref
	string[] Property FloorAnims Auto Const mandatory
	{ This array stores Floors anim strings
		they should be 1 lower in index than the floor number
		EG: Index 0 == Level01 }
	string Property Done = "Done" Auto Const hidden
	;Activator Property PlatformHelperFree Auto Const mandatory
	Message Property ElevatorMsg1 Auto Const mandatory
	;{ platform helper Activator }
	;Activator Property Button01 Auto Const mandatory
	Static Property Car01 Auto Const mandatory
	{ Elevator Car - Static }
	Static Property ElevatorPanel Auto Const mandatory
	{ Panel for the buttons inside the car }
	Activator Property Skeleton Auto Const mandatory
	{ Skeleton for the elevator }
	Keyword Property LinkCustom10 Auto Const mandatory
	{ Keyword Link to the inner door }
	Keyword Property LinkCustom11 Auto Const mandatory
	 { Keyword Link to the car }
	 Keyword Property LinkCustom12 Auto Const mandatory
 	 { Keyword Link to the skeleton }
	 int Property nrFloors = 0 auto hidden
EndGroup

Group Optional_Properties collapsedonref
	Door Property DoorIn Auto conditional
	{ Door for elevator Car }
	Door Property DoorOut Auto conditional
	{ Door for shaft doorways }
	Static Property shaftFloor Auto conditional
	{ Shaft Floor }
	Static Property shaftTop Auto conditional
	{ Shaft Top/Ceiling }
	Static Property shaftDoor1 Auto conditional
	{ Bottom Shaft Doorway }
	Static Property shaftDoor Auto conditional
	{ Shaft Doorway }
	Static Property shaftWall Auto conditional
	{ Shaft Walls }
	Door Property hatchDoor Auto conditional
	{ Elevator hatch - Door }
	Static Property hatch Auto conditional
	{ Elevator hatch - Static}
	Sound Property AltSound Auto conditional
	{ Alternative elevator sound }
	Sound Property Muzak Auto
	{ Looping sound for muzak }
	string Property SoundNode = "SoundNode01" Auto conditional
	{ node in the nif to the sound source }
	string Property CarNode = "Car01" Auto conditional
	{ node in the nif to the place the car at }
	string Property DoorInNode = "DoorWayNode01" Auto conditional
	{ node in the nif to place inner door at}
	string Property RootNode = "RootNode" Auto conditional
	{ node in the nif to place skeleton at }
	string Property ShaftNode = "NavCutterNode0" Auto conditional
	{ node in the nif to place shaft walls at - without last digit }
	string Property FloorNode = "ShaftFloor" Auto conditional
	{ node in the nif to place shaft floor at }
	string Property PanelNode = "Button03" Auto conditional
	{ node in the nif to place button panel at }
	string Property DoorOutNode = "DoorWayNode0" Auto conditional
	{ node in the nif to place outer doors at - without last digit }
	Float Property fSpeed = 8.0 const auto conditional
	{ Speed of the car higher is slower }
	EffectShader Property HighlightUnpoweredFX Auto Const
	{ Effect Shader to highlight unpowered objects - unused atm }
	Keyword Property BlockWorkshopInteractionKeyword const auto
EndGroup

;-- Variables ---------------------------------------
ButtonData[] Property MyButtons Auto
bool buttonsPlaced = False
int CurrentFloor = 1
int MuzakSoundInstance
ObjectReference[] doorOutRef
ObjectReference[] tempParts

;-- Functions ---------------------------------------

Function PlaceButtons()
	Self.BlockActivation(True, True)
	ObjectReference doorInRef = none
	ObjectReference skeletonRef = none
	
	; show messagebox to choose nr of floors
	nrFloors = ElevatorMsg1.Show()

	If (!buttonsPlaced && (nrFloors>1))
		buttonsPlaced = True

		Self.AddKeyword(LinkCustom12) ;add keyword to find with placeable buttons

		; place skeleton
		skeletonRef = Self.PlaceAtNode(RootNode, Skeleton, 1, False, False, False, True)
		skeletonRef.SetLinkedRef(Self, None)
		Self.SetLinkedRef(skeletonRef, LinkCustom12)
		Debug.Trace("Current movement speed: " + skeletonRef.GetAnimationVariableFloat("fspeed"))
		skeletonRef.SetAnimationVariableFloat("fspeed", fSpeed)

		; place car
		ObjectReference carRef = none
		carRef = skeletonRef.PlaceAtNode(CarNode, Car01, 1, False, False, False, True)
		carRef.SetLinkedRef(skeletonRef, None)
		skeletonRef.SetLinkedRef(carRef, LinkCustom11)

		if (hatch || hatchDoor)
			ObjectReference hatchRef = None
			If (hatch)
				hatchRef = skeletonRef.PlaceAtNode("Car01", hatch, 1, False, False, False, True)
			ElseIf(hatchDoor)
				hatchRef = skeletonRef.PlaceAtNode("Car01", hatchDoor, 1, False, False, False, True)
			endif
			hatchRef.SetLinkedRef(Self, None)
			;Self.SetLinkedRef(hatchRef, None)
			hatchRef.AddKeyword(BlockWorkshopInteractionKeyword)
		endif

		; place panel
		ObjectReference panelRef = none
		panelRef = skeletonRef.PlaceAtNode(PanelNode, ElevatorPanel, 1, False, False, False, True)
		panelRef.SetLinkedRef(skeletonRef, None)
		panelRef.SetLinkedRef(Self, None)
		panelRef.RegisterForRemoteEvent(Self as ObjectReference, "OnWorkshopObjectDestroyed")

		ObjectReference shaftDoorRef = none
		ObjectReference tempRef = none
		ObjectReference currentButton = None
		int i = 1
		While (i <= nrFloors)
			; place shaft doorways
			if (shaftDoor1 && i==1) ;if different 1st floor shaft
				shaftDoorRef = Self.PlaceAtNode(ShaftNode + i , shaftDoor1, 1, False, False, False, True)
			Else
				shaftDoorRef = Self.PlaceAtNode(ShaftNode + i , shaftDoor, 1, False, False, False, True)
			endif
			shaftDoorRef.SetLinkedRef(Self as ObjectReference, None)

			; place outer doors
			If (DoorOut)
				tempRef = Self.PlaceAtNode(DoorOutNode + i , DoorOut, 1, False, False, False, True)
				tempRef.SetLinkedRef(Self as ObjectReference, None)
				tempRef.BlockActivation(False, True)
				tempRef.AddKeyword(BlockWorkshopInteractionKeyword)
				doorOutRef.add(tempRef)
				doorOutRef[0].PlayGamebryoAnimation("Open")
				if (doorOutRef[0].GetOpenState() != 1)
					doorOutRef[0].SetOpen(True)
				EndIf
			endif

			; place inside buttons - i-1 because of index starts with 0 instead of 1
			currentButton = panelRef.PlaceAtNode(MyButtons[i-1].Node, MyButtons[i-1].Button as Form, 1, False, False, False, True) ;inside buttons
			currentButton.SetLinkedRef(skeletonRef, None)
			currentButton.SetLinkedRef(Self, None)
			skeletonRef.SetLinkedRef(currentButton, MyButtons[i-1].LinkKeyword)
			currentButton.RegisterForRemoteEvent(Self as ObjectReference, "OnWorkshopObjectDestroyed")

			i += 1
		EndWhile

		; place shaft Top/Floor
		If (shaftTop)
			ObjectReference shaftTopRef = Self.PlaceAtNode(ShaftNode+i, shaftTop, 1, False, False, False, True)
			shaftTopRef.SetLinkedRef(Self as ObjectReference, None)
		endif

		If (shaftFloor)
			ObjectReference shaftFloorRef = Self.PlaceAtNode(FloorNode, shaftFloor, 1, False, False, False, True)
			shaftFloorRef.SetLinkedRef(Self as ObjectReference, None)
		endif

		; place inner door and open it
		If (DoorIn)
			doorInRef = skeletonRef.PlaceAtNode(DoorInNode, DoorIn, 1, False, False, False, True)
			doorInRef.BlockActivation(False, True)
			doorInRef.SetLinkedRef(skeletonRef, None)
			skeletonRef.SetLinkedRef(doorInRef, LinkCustom10)
			doorInRef.SetLinkedRef(Self, None)
			doorInRef.AddKeyword(BlockWorkshopInteractionKeyword)
			doorInRef.PlayGamebryoAnimation("Open")
			;Failsafe: Make absolutely sure the doors are open.
				if (doorInRef.GetOpenState() != 1)
					doorInRef.SetOpen(True)
				EndIf
		endif
	EndIf
EndFunction

Function SetCallButtonsOff(bool TurnButtonsOff)
	ObjectReference skeletonRef = Self.GetLinkedRef(LinkCustom12)
	ObjectReference currentButton = None

	int I = 0
	int Count = nrFloors + nrFloors*2 ; inside buttons for each level + the extra 2 outside buttons

	While (I < Count)
		If (MyButtons[I].AttachToTrack)
			currentButton = skeletonRef.GetLinkedRef(MyButtons[I].LinkKeyword)
			If (TurnButtonsOff)
				currentButton.DisableNoWait(False)
			Else
				currentButton.MoveToNode(skeletonRef, MyButtons[I].Node, "")
				currentButton.EnableNoWait(False)
			EndIf
		EndIf
		I += 1
	EndWhile
EndFunction

Function glow(String anim)
		PlayGamebryoAnimation(anim)
EndFunction

;not sure I'll keep the power option or not... either way change loop length to current
Function PowerButtons(bool shouldBePowered)
	ObjectReference skeletonRef = Self.GetLinkedRef(LinkCustom12)
	int I = 0
	int Count = MyButtons.length
	While (I < Count)
		(skeletonRef.GetLinkedRef(MyButtons[I].LinkKeyword) as Snappy:ElevatorInButtonScript).SetHasPower(shouldBePowered)
		I += 1
	EndWhile
EndFunction

Function DoFloorChange(int floorToGoTo)
	ObjectReference skeletonRef = Self.GetLinkedRef(LinkCustom12)
	ObjectReference doorInRef = skeletonRef.GetLinkedRef(LinkCustom10)

	If (floorToGoTo != CurrentFloor)
		;close doors
		If (DoorOut)
			doorOutRef[CurrentFloor-1].SetOpen(False)
			Utility.Wait(0.3)
		EndIf
		If (DoorIn)
			doorInRef.PlayGamebryoAnimation("Close", true, 1.0)
			Utility.Wait(0.9)
		EndIf

		; move the elevator car
		int PlatformSoundInstance = 0

		if(AltSound) ;stop sound from hkx and play alternative
			Utility.Wait(0.3)
			skeletonRef.PlayAnimation("SoundStop")
			PlatformSoundInstance = AltSound.Play(skeletonRef.GetLinkedRef(LinkCustom11) as ObjectReference)
		EndIf

		; move the car
		skeletonRef.PlayAnimationAndWait(FloorAnims[floorToGoTo - 1], Done)

		if(AltSound)
			Sound.StopInstance(PlatformSoundInstance)
		EndIf

		;open doors
		If (DoorIn)
			doorInRef.PlayGamebryoAnimation("Open", true, afEaseInTime = 1.0)
			Utility.Wait(0.3)
		EndIf

		If (DoorOut)
			doorOutRef[floorToGoTo - 1].PlayGamebryoAnimation("Open", true, afEaseInTime = 1.0)
			if (doorOutRef[floorToGoTo - 1].GetOpenState() != 1)
				doorOutRef[floorToGoTo - 1].SetOpen(True)
			endif
		EndIf

		CurrentFloor = floorToGoTo
		;Self.SyncNavCutFloor()
	EndIf
EndFunction

bool Function GoToFloor(int floorToGoTo)
	Self.GoToState("Busy")

	;If (Self.IsPowered())
		Self.DoFloorChange(floorToGoTo)
	;Else
		;Snappy_ElevatorRequiresPowerMessage.Show(0, 0, 0, 0, 0, 0, 0, 0, 0)
	;EndIf

	Self.GoToState("Ready")
	return False
EndFunction

Function DestroyElevator()
	ObjectReference skeletonRef = Self.GetLinkedRef(LinkCustom12)
	Debug.Trace(skeletonRef)
	ObjectReference[] LinkedRefs = Self.GetRefsLinkedToMe()
	int i = 0
	while (i < LinkedRefs.length)
		LinkedRefs[i].Delete()
		i += 1
	endwhile

	skeletonRef.GetLinkedRef(LinkCustom11).Delete() ; not sure if this is needed... delete car...

	skeletonRef.ResetKeyword(LinkCustom12) ;remove or reset?
	skeletonRef.RemoveKeyword(LinkCustom12)
	Self.RemoveKeyword(LinkCustom12)

	If (Muzak as bool)
		Sound.StopInstance(MuzakSoundInstance)
	EndIf

	skeletonRef.Delete()
	skeletonRef = None

	doorOutRef.Clear()
	buttonsPlaced = False
EndFunction

;-- Events ---------------------------------------
Event OnCellAttach()
	;Debug.MessageBox("cell attach") some leftovers? This triggers for all built elevators and not only the current... why?
		If (!buttonsPlaced)
			Self.PlaceButtons()
			Self.BlockActivation(True, True)
		EndIf
EndEvent

Event OnInit()
	doorOutRef = new ObjectReference[0]
	Self.RegisterForMenuOpenCloseEvent("WorkshopMenu")
EndEvent

Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
	If (asMenuName == "WorkshopMenu")
			If (abOpening)
				Self.enable()
			Else
				Self.disable()
			EndIf
	EndIf
EndEvent

Event OnPowerOn(ObjectReference akPowerGenerator)
	ObjectReference skeletonRef = Self.GetLinkedRef(LinkCustom12)
	skeletonRef.PlayAnimation("LightOn01")
	Self.PowerButtons(True)
	If (Muzak)
		MuzakSoundInstance = Muzak.Play(skeletonRef.GetLinkedRef(LinkCustom11) as ObjectReference)
	EndIf
EndEvent

Event OnPowerOff()
	ObjectReference skeletonRef = Self.GetLinkedRef(LinkCustom12)
	skeletonRef.PlayAnimation("LightOff01")
	Self.PowerButtons(False)
	If (Muzak as bool)
		Sound.StopInstance(MuzakSoundInstance)
	EndIf
EndEvent

Event OnWorkshopObjectPlaced(ObjectReference akReference)
	Debug.Trace("Placed")
	Self.PlaceButtons()
	;Self.PlaceNavCuts()
	Self.BlockActivation(True, True)
EndEvent

Event OnWorkshopObjectGrabbed(ObjectReference akReference)
	;Self.SetCallButtonsOff(True)
	;Self.SetNavCutOff(True)
	Debug.Trace("Grabbed")
	DestroyElevator()
EndEvent

Event OnWorkshopObjectMoved(ObjectReference akReference)
	;Self.SetCallButtonsOff(False)
	Self.PlaceButtons()
	Self.GoToState("WaitingForActivate")
	Debug.Trace("moved")
EndEvent

Event OnWorkshopObjectDestroyed(ObjectReference akReference)
	DestroyElevator()

	UnregisterForMenuOpenCloseEvent("WorkshopMenu")
	Delete()
EndEvent

Event ObjectReference.onActivate(ObjectReference akSender, ObjectReference akActionRef)
	; Empty function
EndEvent


;-- States -------------------------------------------
State Busy
	bool Function GoToFloor(int floorToGoTo)
		return True
	EndFunction
EndState

Auto State Ready
	Event OnEndState(string asNewState)
		; Empty function
	EndEvent
EndState
