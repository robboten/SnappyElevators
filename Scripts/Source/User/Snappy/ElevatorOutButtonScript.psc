scriptname Snappy:ElevatorOutButtonScript extends Snappy:ElevatorInButtonScript

import Math

Keyword property Snappy_ElevatorKeyword auto const mandatory
{ Give this keyword to all elevators with MainElevatorScript. }
Message property Snappy_CallButtonNotRespondingMessage = none auto const
{ Message to show if no elevator is linked to this button. E.g. 'Not responding.'. }
float property ElevatorFlashDuration = 2.33 auto const
{ Elevator will flash for this long after being linked to this button. }
float property ButtonZOffset = 0.0 auto const
{ The offset from the root node to the z position of the center of the actual button. }
string property StartOffAnimation = "" auto

; Snappy:ElevatorInButtonScript override.
function InitializeElevator(Snappy:MainElevatorScript akElevatorRef)
    parent.InitializeElevator(akElevatorRef)
    FloorNumber = akElevatorRef.GetCallButtonFloor(z + ButtonZOffset)
    Debug.Trace("My floor number is " + FloorNumber)
    akElevatorRef.StartFlashing(ElevatorFlashDuration)
endfunction

; Does not return the actual distance. Square roots are expensive!
float function GetRelativeXYDistanceToSelf(ObjectReference akOther)
    return pow(x - akOther.x, 2) + pow(y - akOther.y, 2)
endfunction

bool function FindElevator()
    ObjectReference[] elevatorRefs = self.FindAllReferencesWithKeyword(Snappy_ElevatorKeyword, 1024.0)
    Debug.Notification("Found " + elevatorRefs.Length + " elevators.")
    if (elevatorRefs.Length > 0)
        ObjectReference elevatorRef = none
        float currentDist = 0.0
        int i = 0
        while (i < elevatorRefs.Length)
            if (elevatorRefs[i].IsEnabled())
                if (!elevatorRef)
                    elevatorRef = elevatorRefs[i]
                    currentDist = GetRelativeXYDistanceToSelf(elevatorRef)
                else
                    float newDist = GetRelativeXYDistanceToSelf(elevatorRefs[i])
                    if (newDist < currentDist)
                        elevatorRef = elevatorRefs[i]
                        currentDist = newDist
                    endif
                endif
            endif
            i += 1
        endwhile

        if (elevatorRef)
            InitializeElevator(elevatorRef as Snappy:MainElevatorScript)
            return true
        endif
    endif

    return false
endfunction
bool function FindNewElevator()
    ClearElevator()
    return FindElevator()
endfunction

; Snappy:ElevatorInButtonScript override.
auto state Ready
    ; Snappy:ElevatorInButtonScript override.
    function HandleActivation(ObjectReference akActionRef)
        ; Check if we have a linked elevator.
        if (self.GetElevator())
            parent.HandleActivation(akActionRef)
        ; If we don't have an elevator, show the 'Not responding.' message.
        elseif (Snappy_CallButtonNotRespondingMessage)
            Snappy_CallButtonNotRespondingMessage.Show()
        endif
    endfunction
endstate

event OnWorkshopObjectGrabbed(ObjectReference akWorkshopRef)
    Snappy:MainElevatorScript elevatorRef = self.GetElevator()
    if (elevatorRef)
        elevatorRef.StartFlashing(ElevatorFlashDuration)
    endif
endevent
event OnWorkshopObjectMoved(ObjectReference akWorkshopRef)
    FindNewElevator()
endevent
event OnWorkshopObjectPlaced(ObjectReference akWorkshopRef)
    if (StartOffAnimation != "")
        self.PlayAnimation(StartOffAnimation)
    endif
    FindElevator()
endevent
