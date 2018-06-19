scriptname Snappy:ElevatorOutDoorScript extends ObjectReference const
{ Simple script to automatically close the elevator doors. }

float property AutoCloseTimeout = 5.0 auto const

event OnOpen(ObjectReference akActionRef)
    Debug.Trace(self + " opened by " + akActionRef)
    self.StartTimer(AutoCloseTimeout)
endevent
event OnClose(ObjectReference akActionRef)
    Debug.Trace(self + " closed by " + akActionRef)
    self.CancelTimer()
endevent

event OnTimer(int aiTimerID)
    self.SetOpen(false)
endevent
