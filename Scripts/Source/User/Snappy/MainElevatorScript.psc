scriptName Snappy:MainElevatorScript extends ObjectReference

customevent PowerChange

struct ButtonData
    ObjectReference ref = none hidden
    Activator button
    string node
endstruct

;-- Properties --------------------------------------
group AutoFill
    Keyword property WorkshopCanBePowered auto const mandatory
    { Used to check if this elevator requires power. }
    GlobalVariable property Snappy_ElevatorSpeedMult auto const mandatory
    GlobalVariable property Snappy_ElevatorPlayMuzakOnlyWhileMoving auto const mandatory
endgroup
group Required collapsedonref
    string[] Property FloorAnims auto const mandatory
    { This array stores Floors anim strings
        they should be 1 lower in index than the floor number
        EG: Index 0 == Level01 }
    string Property Done = "Done" auto const hidden
    { 'Done' event. }
    Message Property ElevatorMsg1 auto const mandatory
    { Message to show when choosing number of floors. }
    Activator Property Skeleton auto const mandatory
    { Skeleton for the elevator. }
    Static Property Car01 auto const mandatory
    { Elevator car. }
    Static Property ElevatorPanel auto const mandatory
    { Panel for the buttons inside the car. }
    Static Property ShaftDoor auto const mandatory
    { Shaft doorway. }
    ButtonData[] property MyButtons auto mandatory
endgroup
group Optional collapsedonref
    Activator property PlayerOnElevatorTrigger = none auto const
    { Trigger to keep track if player is on an elevator. Moves with the car. }
    Door Property DoorIn = none auto const
    { Door for elevator Car }
    Door Property DoorOut = none auto const
    { Door for shaft doorways }
    Form Property CarLight = none auto const
    { Light source for the car }
    float property CarLightZOffset = -38.0 auto const
    Static Property ShaftFloor = none auto const
    { Shaft Floor }
    Static Property ShaftTop = none auto const
    { Shaft Top/Ceiling }
    Static Property ShaftDoor1 = none auto const
    { Bottom Shaft Doorway }
    Form Property HatchDoor = none auto const
    { Elevator hatch - Door }
    Sound Property AltSound = none auto const
    { Alternative elevator sound }
    Sound Property Muzak = none auto const
    { Looping sound for muzak }
    string Property CarNode = "Car01" auto const
    { node in the nif to the place the car at }
    string Property DoorInNode = "DoorWayNode01" auto const
    { node in the nif to place inner door at}
    string Property RootNode = "RootNode" auto const
    { node in the nif to place skeleton at }
    string Property ShaftNode = "NavCutterNode0" auto const
    { node in the nif to place shaft walls at - without last digit }
    string Property FloorNode = "ShaftFloor" auto const
    { node in the nif to place shaft floor at }
    string Property PanelNode = "Button03" auto const
    { node in the nif to place button panel at }
    string Property DoorOutNode = "DoorWayNode0" auto const
    { node in the nif to place outer doors at - without last digit }
    Message property Snappy_ElevatorRequiresPowerMessage = none auto const
    { Message to show if the elevator requires power, but does not have. }
    float Property ElevatorSpeed = 3.0 auto
    { The time it takes the elevator car to go up or down one floor. }
endgroup

bool property PlayMuzakOnlyWhileMoving hidden
    bool function get()
        return Snappy_ElevatorPlayMuzakOnlyWhileMoving.GetValue() != 0
    endfunction
endproperty

int floorCount = 0
int currentFloor = 1
int muzakSoundInstance = 0

ObjectReference mySkeletonRef = none
ObjectReference myElevatorCarRef = none
ObjectReference myPlayerTriggerRef = none
ObjectReference myCarLightRef = none
ObjectReference myInsideDoorRef = none
ObjectReference myHatchDoorRef = none
ObjectReference myTopShaftRef = none
ObjectReference myFloorShaftRef = none
ObjectReference myPanelRef = none
ObjectReference[] myShaftDoorwayRefs = none
ObjectReference[] myShaftDoorRefs = none

function AdjustElevatorSpeed(int aiCurrentFloor, int aiDestinationFloor)
    mySkeletonRef.SetAnimationVariableFloat("fSpeed", (Math.abs(aiDestinationFloor - aiCurrentFloor) * ElevatorSpeed) / Snappy_ElevatorSpeedMult.GetValue())
endfunction

function InitializeElevator()
    if (!mySkeletonRef)
        ; Show messagebox to choose number of floors.
        floorCount = ElevatorMsg1.Show()

        ; Skeleton
        mySkeletonRef = self.PlaceAtNode(RootNode, Skeleton, abAttach = true)
        Debug.TraceSelf(self, "InitializeElevator", "mySkeletonRef: " + mySkeletonRef)
        mySkeletonRef.WaitFor3DLoad()

        ; Elevator car.
        myElevatorCarRef = mySkeletonRef.PlaceAtNode(CarNode, Car01, abAttach = true)
        Debug.TraceSelf(self, "InitializeElevator", "myElevatorCarRef: " + myElevatorCarRef)

        ; Player trigger, but only if we want it.
        if (PlayerOnElevatorTrigger)
            myPlayerTriggerRef = mySkeletonRef.PlaceAtNode(CarNode, PlayerOnElevatorTrigger, abAttach = true)
            Debug.TraceSelf(self, "InitializeElevator", "myPlayerTriggerRef: " + myPlayerTriggerRef)
        endif
        Debug.TraceConditional(self + "-->InitializeElevator(): no player-on-elevator trigger", !PlayerOnElevatorTrigger)

        ; Light, but only if we want it.
        if (CarLight)
            myCarLightRef = mySkeletonRef.PlaceAtNode("BulbBase01", CarLight)
            Debug.TraceSelf(self, "InitializeElevator", "myCarLightRef: " + myCarLightRef)
            myCarLightRef.WaitFor3DLoad()
            myCarLightRef.SetPosition(myCarLightRef.x, myCarLightRef.y, myCarLightRef.z + CarLightZOffset)
            myCarLightRef.AttachTo(mySkeletonRef)
        endif
        Debug.TraceConditional(self + "-->InitializeElevator(): no car light", !CarLight)

        ; Hatch, but only if we want it.
        if (HatchDoor)
            myHatchDoorRef = mySkeletonRef.PlaceAtNode("Car01", HatchDoor, abAttach = true)
            Debug.TraceSelf(self, "InitializeElevator", "myHatchDoorRef: " + myHatchDoorRef)
        endif
        Debug.TraceConditional(self + "-->InitializeElevator(): no hatch", !HatchDoor)

        ; Elevator panel.
        myPanelRef = mySkeletonRef.PlaceAtNode(PanelNode, ElevatorPanel, abAttach = true)
        myPanelRef.WaitFor3DLoad()
        Debug.TraceSelf(self, "InitializeElevator", "myPanelRef: " + myPanelRef)

        myShaftDoorwayRefs = new ObjectReference[floorCount]
        myShaftDoorRefs = new ObjectReference[floorCount]

        int i = 0
        while (i < floorCount)
            int floorNumber = i + 1

            ; Place shaft doorways.
            if (i == 0 && ShaftDoor1) ; if different 1st floor shaft.
                myShaftDoorwayRefs[i] = self.PlaceAtNode(ShaftNode + floorNumber, ShaftDoor1, abAttach = true)
            else
                myShaftDoorwayRefs[i] = self.PlaceAtNode(ShaftNode + floorNumber, ShaftDoor, abAttach = true)
            endif
            Debug.TraceSelf(self, "InitializeElevator", "myShaftDoorwayRefs[" + i + "]: " + myShaftDoorwayRefs[i])

            ; Place outside doors, but only if we want them.
            if (DoorOut)
                myShaftDoorRefs[i] = self.PlaceAtNode(DoorOutNode + floorNumber, DoorOut, abAttach = true)
                Debug.TraceSelf(self, "InitializeElevator", "myShaftDoorRefs[" + i + "]: " + myShaftDoorRefs[i])
                myShaftDoorRefs[i].WaitFor3DLoad()
                ; Block activation for all doors except the bottom one.
                myShaftDoorRefs[i].BlockActivation(i != 0, i != 0)
                ; Open the bottom door only.
                ;myShaftDoorRefs[i].SetOpen(i == 0)
            endif
            Debug.TraceConditional(self + "-->InitializeElevator(): no outside doors", !DoorOut)

            ; Place inside buttons.
            MyButtons[i].ref = myPanelRef.PlaceAtNode(MyButtons[i].node, MyButtons[i].button, abAttach = true)
            Debug.TraceSelf(self, "InitializeElevator", "MyButtons[" + i + "].ref: " + MyButtons[i].ref)
            MyButtons[i].ref.WaitFor3DLoad()
            ;MyButtons[i].ref.PlayAnimation("StartOff")
            (MyButtons[i].ref as Snappy:ElevatorInButtonScript).InitializeElevator(self)

            i += 1
        endwhile

        ; Top shaft, but only if we want it.
        if (ShaftTop)
            myTopShaftRef = self.PlaceAtNode(ShaftNode + (floorCount + 1), ShaftTop, abAttach = true)
            Debug.TraceSelf(self, "InitializeElevator", "myTopShaftRef: " + myTopShaftRef)
        endif
        Debug.TraceConditional(self + "-->InitializeElevator(): no top shaft", !ShaftTop)
        ; Floor shaft, but only if we want it.
        if (ShaftFloor)
            myFloorShaftRef = self.PlaceAtNode(FloorNode, ShaftFloor, abAttach = true)
            Debug.TraceSelf(self, "InitializeElevator", "myFloorShaftRef: " + myFloorShaftRef)
        endif
        Debug.TraceConditional(self + "-->InitializeElevator(): no floor shaft", !ShaftFloor)

        ; Place inner door and open it.
        if (DoorIn)
            myInsideDoorRef = mySkeletonRef.PlaceAtNode(DoorInNode, DoorIn, abAttach = true)
            Debug.TraceSelf(self, "InitializeElevator", "myInsideDoorRef: " + myInsideDoorRef)
            myInsideDoorRef.WaitFor3DLoad()
            myInsideDoorRef.BlockActivation(true, true)
            myInsideDoorRef.SetOpen()
        endif
        Debug.TraceConditional(self + "-->InitializeElevator(): no inner door", !DoorIn)
    endif
endfunction

int function GetCallButtonFloor(float afZPosition)
    int i = 1
    while (i < floorCount)
        ; Check if between current (i) floor and previous (i - 1).
        if (afZPosition >= myShaftDoorwayRefs[i - 1].z && afZPosition < myShaftDoorwayRefs[i].z)
            return i
        endif
        i += 1
    endwhile
    ; Default to bottom floor.
    return 1
endfunction

function StartFlashing(float afDuration)
    self.PlayGamebryoAnimation("Play", true)
    self.StartTimer(afDuration)
endfunction
function StopFlashing()
    self.PlayGamebryoAnimation("Stop", true)
endfunction
function SetGlowing(bool abShouldGlow)
    if (abShouldGlow)
        self.PlayGamebryoAnimation("On", true)
    else
        self.PlayGamebryoAnimation("Stop", true)
    endif
endfunction

event OnTimer(int aiTimerID)
    StopFlashing()
endevent

function PowerButtons(bool shouldBePowered)
    if (self.HasKeyword(WorkshopCanBePowered))
        var[] args = new var[1]
        args[0] = shouldBePowered
        self.SendCustomEvent("PowerChange", args)
    endif
endfunction

function PlayMuzak(bool abShouldPlay)
    ; Ignore if Muzak sound is not set.
    if (Muzak)
        if (abShouldPlay && muzakSoundInstance == 0)
            muzakSoundInstance = Muzak.Play(myElevatorCarRef)
        elseif (!abShouldPlay && muzakSoundInstance != 0)
            Sound.StopInstance(muzakSoundInstance)
            muzakSoundInstance = 0
        endif
    endif
endfunction

function DoFloorChange(int aiFloorToGoTo)
    if (aiFloorToGoTo != currentFloor)
        ; Close doors.
        if (DoorOut)
            ObjectReference doorOutRef = myShaftDoorRefs[currentFloor - 1]
            doorOutRef.BlockActivation(true, true)
            doorOutRef.SetOpen(false)
            ; Not sure why, but the outside doors don't seem to close unless they disabled and re-enabled.
            doorOutRef.Disable()
            doorOutRef.EnableNoWait()
            Utility.Wait(0.3)
        endif
        if (myInsideDoorRef)
            myInsideDoorRef.SetOpen(false)
            Utility.Wait(0.9)
        endif

        if (!PlayMuzakOnlyWhileMoving)
            ; Start muzak.
            PlayMuzak(true)
        endif

        int platformSoundInstance = 0
        if (AltSound) ; Stop sound from hkx and play alternative sound.
            Utility.Wait(0.3)
            mySkeletonRef.PlayAnimation("SoundStop")
            platformSoundInstance = AltSound.Play(myElevatorCarRef)
        endif

        ; Adjust elevator speed.
        AdjustElevatorSpeed(currentFloor, aiFloorToGoTo)
        ; Move the car.
        mySkeletonRef.PlayAnimationAndWait(FloorAnims[aiFloorToGoTo - 1], Done)

        if (AltSound)
            Sound.StopInstance(platformSoundInstance)
        endif


        if (!PlayMuzakOnlyWhileMoving)
            ; Stop muzak.
            PlayMuzak(false)
        endif

        ; Open doors
        if (myInsideDoorRef)
            myInsideDoorRef.SetOpen()
            Utility.Wait(0.3)
        endif
        if (DoorOut)
            ObjectReference doorOutRef = myShaftDoorRefs[aiFloorToGoTo - 1]
            doorOutRef.SetOpen()
            doorOutRef.BlockActivation(false, false)
        endif

        currentFloor = aiFloorToGoTo
    else
        ; If we are already at the floor just open the doors.
        if (DoorOut)
            ObjectReference doorOutRef = myShaftDoorRefs[currentFloor - 1]
            doorOutRef.SetOpen()
        endif
    endif
endfunction
bool function GoToFloor(int aiFloorToGoTo)
    ; Ignore unless in 'Ready' state.
    return true
endfunction

function TurnOn()
    if (myCarLightRef)
        ;myCarLightRef.PlayAnimation("LightOn01")
    endif
    PowerButtons(true)
endfunction
function TurnOff()
    if (myCarLightRef)
        ;myCarLightRef.PlayAnimation("LightOff01")
    endif
    PowerButtons(false)
endfunction

function DestroyElevator()
    int i = floorCount
    while (i > 0)
        i -= 1
        MyButtons[i].ref.Delete()
    endwhile
    MyButtons = none

    if (myShaftDoorRefs)
        i = floorCount
        while (i > 0)
            i -= 1
            myShaftDoorRefs[i].Delete()
        endwhile
        myShaftDoorRefs = none
    endif

    i = floorCount
    while (i > 0)
        i -= 1
        myShaftDoorwayRefs[i].Delete()
    endwhile
    myShaftDoorwayRefs = none

    myPanelRef.Delete()
    myPanelRef = none
    if (myFloorShaftRef)
        myFloorShaftRef.Delete()
        myFloorShaftRef = none
    endif
    if (myTopShaftRef)
        myTopShaftRef.Delete()
        myTopShaftRef = none
    endif
    if (myHatchDoorRef)
        myHatchDoorRef.Delete()
        myHatchDoorRef = none
    endif
    if (myInsideDoorRef)
        myInsideDoorRef.Delete()
        myInsideDoorRef = none
    endif
    if (myCarLightRef)
        myCarLightRef.Delete()
        myCarLightRef = none
    endif
    if (myPlayerTriggerRef)
        myPlayerTriggerRef.Delete()
        myPlayerTriggerRef = none
    endif
    myElevatorCarRef.Delete()
    myElevatorCarRef = none
    mySkeletonRef.Delete()
    mySkeletonRef = none

    Debug.Trace(self + " destroyed!")
endfunction

event ObjectReference.OnWorkshopMode(ObjectReference akSender, bool abStart)
    if (abStart)
        self.Enable()
    else
        self.Disable()
    endif
endevent

event OnPowerOn(ObjectReference akPowerGenerator)
    TurnOn()
endevent
event OnPowerOff()
    TurnOff()
endevent

event OnWorkshopObjectPlaced(ObjectReference akWorkshopRef)
    Debug.Trace(self + " placed.")
    self.RegisterForRemoteEvent(akWorkshopRef, "OnWorkshopMode")
    self.InitializeElevator()
    self.TurnOn()
    if (!PlayMuzakOnlyWhileMoving)
        PlayMuzak(true)
    endif
    self.GoToState("Ready")
endevent

event OnWorkshopObjectDestroyed(ObjectReference akWorkshopRef)
    Debug.Trace(self + ": has received OnWorkshopObjectDestroyed.")
    self.Gotostate("Scrapped")
    self.UnregisterForAllEvents()
    self.TurnOff()
    PlayMuzak(false)
    self.DestroyElevator()
endevent

auto state Busy
    ; Empty state to ignore go to floor requests.
endstate

state Ready
    bool function GoToFloor(int aiFloorToGoTo)
        self.GoToState("Busy")

        if (false && self.HasKeyword(WorkshopCanBePowered) && !self.IsPowered()) ; Always false for now.
            if (Snappy_ElevatorRequiresPowerMessage)
                Snappy_ElevatorRequiresPowerMessage.Show()
            endif
        else
            self.DoFloorChange(aiFloorToGoTo)
        endif

        self.GoToState("Ready")

        return false
    endfunction
endstate

state Scrapped
    event OnPowerOn(ObjectReference akPowerGenerator)
        ; Ignore event.
    endevent
    event OnPowerOff()
        ; Ignore event.
    endevent
endstate
