functor
import
    Input
    System
export
    portPlayer:StartPlayer
define
    StartPlayer
    TreatStream
    InitPosition
    % player(i:id p:position)
in
    % TODO : Determiner position initiale
    fun {InitPosition PlayerState}
      case PlayerState
      of player(i:ID p:_) then
        {System.show initPosition#PlayerState}
        player(i:ID p:pt(x:3 y:3))
      else PlayerState end
    end

    proc{TreatStream Stream PlayerState} % as as many parameters as you want
        case Stream
        of nil then {System.show playerStream#'nil'} skip
        [] H|T then
            %{System.show playerStream#H#PlayerState}
            case H
            of initPosition(X Y) then
                NewState={InitPosition PlayerState}
            in
                X = PlayerState.i
                Y = NewState.p
                {TreatStream T NewState}
            [] move(ID Pos Dir) then ...
            [] dive then ...
            [] chargeItem(ID KindItem) then ...
            [] fireItem(ID KindFire) then ...
            [] fireMine(ID Mine) then ...
            [] isDead(Answer) then ...
            [] sayMove(ID Dir) then ...
            [] saySurface(ID) then ...
            [] sayCharge(ID KindItem) then ...
            [] sayMinePlaced(ID) then ...
            [] sayMissileExplode(ID Pos Msg) then ...
            [] sayMineExplode(ID Pos Msg) then ...
            [] sayPassingDrone(Drone ID Answer) then ...
            [] sayAnswerDrone(Drone ID Answer) then ...
            [] sayPassingSonar(ID Answer) then ...
            [] sayAnswerSonar(ID Answer) then ...
            [] sayDeath(ID) then ...
            [] sayDamageTaken(ID Damage LifeLeft) then ...
            else {System.show error#H} skip end
        else {TreatStream Stream PlayerState} end
    end

    fun{StartPlayer Color ID}
        Stream
        Port
    in
        {NewPort Stream Port}
        thread
            {TreatStream Stream player(i:id(id:ID color:Color name:'Name') p:_)}
        end
        Port
    end
end
