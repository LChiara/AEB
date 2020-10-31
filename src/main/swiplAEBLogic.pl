statusOn(1).
statusOff(0).
headwayOffset(3.7).
driverBrake(4).
timeToReact(1.2).

run(MioDistance, MioVelocity, EgoVelocity, PB1Decel, PB2Decel, FBDecel, Stop, Collision, FCWActivate, AEBStatus, Deceleration):-
    detectStop(EgoVelocity, Stop),
    calculateTTC(MioDistance, MioVelocity, TTC, Collision),
    getOutputs(EgoVelocity, TTC, PB1Decel, PB2Decel, FBDecel, FCWActivate, AEBStatus, Deceleration),
    !.

run(_, _, _, _, _, _, _, _, _, _, _):-!.

detectStop(EgoVelocity, Stop) :-
    EgoVelocity < 0.1,
    statusOn(Stop).
detectStop(_, Stop):-
    statusOff(Stop).

calculateTTC(MioDistance, MioVelocity, TTC, Collision):-
    abs(MioVelocity) > 100,
    calculateTTC(MioDistance, 100, TTC, Collision).
calculateTTC(MioDistance, MioVelocity, TTC, Collision):-
    abs(MioVelocity) < 0.01,
    calculateTTC(MioDistance, 0.01, TTC, Collision).
calculateTTC(MioDistance, MioVelocity, TTC, Collision):-
    headwayOffset(X),
    RelativeDistance is MioDistance-X,
    Q is RelativeDistance/abs(MioVelocity),
    TTC is Q*sign(MioVelocity),
    detectCollision(MioDistance, Collision).

detectCollision(MioDistance, Collision):-
    MioDistance < 0.1,
    !,
    statusOn(Collision).
detectCollision(_, Collision):-
    statusOff(Collision).


getOutputs(MioVelocity, TTC, _, _, _, 1, 0, DriverDeceleration):-
    driverBrake(DriverDeceleration),
    timeToReact(ReactionTime),
    isTimeToStopLessThanTTC(MioVelocity, ReactionTime, TTC, DriverDeceleration, _).

getOutputs(MioVelocity, TTC, PB1Deceleration, _, _, 1, 1, PB1Deceleration):-
    isTimeToStopLessThanTTC(MioVelocity, 0, TTC, PB1Deceleration, _).

getOutputs(MioVelocity, TTC, _, PB2Deceleration, _, 1, 2, PB2Deceleration):-
    isTimeToStopLessThanTTC(MioVelocity, 0, TTC, PB2Deceleration, _).

getOutputs(MioVelocity, TTC, _, _, FBDeceleration, 1, 3, FBDeceleration):-
    isTimeToStopLessThanTTC(MioVelocity, 0, TTC, FBDeceleration, _).


getOutputs(MioVelocity, TTC, PB1Deceleration, PB2Deceleration, _, 1, 1, PB1Deceleration):-
    isTimeToStopLessThanTTC(MioVelocity, 0, TTC, PB1Deceleration, TimePB1Stop),
    isTimeToStopLessThanTTC(MioVelocity, 0, TTC, PB2Deceleration, TimePB2Stop),
    TimePB1Stop < TimePB2Stop.

getOutputs(MioVelocity, TTC, _, PB2Deceleration, FBDeceleration, 1, 2, PB2Deceleration):-
    isTimeToStopLessThanTTC(MioVelocity, 0, TTC, PB2Deceleration, TimePB2Stop),
    isTimeToStopLessThanTTC(MioVelocity, 0, TTC, FBDeceleration, TimeEBStop),
    TimePB2Stop < TimeEBStop.
getOutputs(MioVelocity, TTC, _, _, FBDeceleration, 1, 3, FBDeceleration):-
    isTimeToStopLessThanTTC(MioVelocity, 0, TTC, FBDeceleration, _).

getOutputs(MioVelocity, TTC, _, _, _, 0, 0, 0):-
    timeToReact(ReactionTime),
    driverBrake(DriverDeceleration),
    \+ isTimeToStopLessThanTTC(MioVelocity, ReactionTime, TTC, DriverDeceleration, _).

getOutputs(_, _, _, _, _, 0, 0, _).

isTimeToStopLessThanTTC(Velocity, ReactionTime, TTC, Deceleration, StopTime):-
    calculateStopTime(Velocity, ReactionTime, Deceleration, StopTime),
    TTC < 0,
    abs(TTC) < StopTime.
isTimeToStopLessThanTTC(_, _, _, _):-!.

calculateStopTime(Velocity, ReactionTime, Deceleration, TimeToStop):-
    TimeToStop is ReactionTime + (Velocity/Deceleration).
