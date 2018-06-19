scriptname Snappy:TestTrigger extends ObjectReference

event OnTriggerEnter(ObjectReference akActionRef)
    (akActionRef as Actor).Kill()
    Debug.MessageBox("Something entered the trigger box!")
endevent

event OnTriggerLeave(ObjectReference akActionRef)
    Debug.Notification("Something left the trigger box!")
endevent
