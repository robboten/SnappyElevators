scriptname Snappy:ElevatorInButtonScript extends ObjectReference
;based on the DLC05 elevator scripts

string property ButtonStartAnimation = "Play02" auto
{ Animation for the buttons to play when on }
string property ButtonStopAnimation = "Play02" auto
{ Animation for the buttons to play when stopped }
string property ButtonPressAnimation = "Play01" auto const
string property ButtonPressEvent = "End" auto const
{ If not an empty string, the button press animation will wait for this event. }
string property ButtonIdleAnimation = "Play02" auto const
{ Animation for the buttons to play when idling with power }
string property ButtonPowerOffAnimation = "Play02" auto const
{ Animation for the buttons to play when not powered }

int property FloorNumber = 1 auto

bool hasPower = true

Snappy:MainElevatorScript myElevatorRef = none
Snappy:MainElevatorScript function GetElevator()
    return myElevatorRef
endfunction
function ClearElevator()
    if (myElevatorRef)
        ;self.UnregisterForRemoteEvent(myElevatorRef, "OnWorkshopObjectDestroyed")
        self.UnregisterForCustomEvent(myElevatorRef, "PowerChange")
    endif
    myElevatorRef = none
endfunction

function InitializeElevator(Snappy:MainElevatorScript akElevatorRef)
    myElevatorRef = akElevatorRef
    ;self.RegisterForRemoteEvent(akElevatorRef, "OnWorkshopObjectDestroyed")
    self.RegisterForCustomEvent(akElevatorRef, "PowerChange")
endfunction

function SetHasPower(bool shouldBePowered)
    hasPower = shouldBePowered
    if (hasPower)
        self.PlayAnimation(ButtonIdleAnimation)
    else
        self.PlayAnimation(ButtonPowerOffAnimation)
    endif
endfunction

function HandleActivation(ObjectReference akActionRef)
endfunction

auto state Ready
    function HandleActivation(ObjectReference akActionRef)
        self.GoToState("Busy")

        ; Play the button press animation.
        self.PlayAnimationAndWait(ButtonPressAnimation, ButtonPressEvent)

        myElevatorRef.GoToFloor(FloorNumber)

        Utility.Wait(1.0)

        if (ButtonStopAnimation != "")
            self.PlayAnimation(ButtonStopAnimation)
        endif

        self.GoToState("Ready")
    endfunction
endstate

state Busy
    ; Empty state to prevent activation script.
endstate

event OnActivate(ObjectReference akActivator)
    HandleActivation(akActivator)
endevent

event Snappy:MainElevatorScript.PowerChange(Snappy:MainElevatorScript akSender, var[] akArgs)
    SetHasPower(akArgs[0] as bool)
endevent
