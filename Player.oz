functor
import
    Input
    System
    OS
    Browser
export
    portPlayer:StartPlayer
define
    StartPlayer
    TreatStream
    InitPosition
    RandPosition
    Move
    Get
    % PlayerState : player(i:id p:position)
    % EnemiesState : row corresponding to the player with id row
    % [[isSurface Path Mines Missiles Drones]
    %  [isSurface Path Mines Missiles Drones]
    %  [isSurface Path Mines Missiles Drones]
    %  [isSurface Path Mines Missiles Drones]
    %  ... ]
in
    fun {Get N M}
        case M
        of H|T then
            if N==1 then H
            else {Get N-1 T} end
        else nil end
    end
    % State : Done
    fun {RandPosition}

        Y = ({OS.rand} mod Input.nColumn) + 1
        X = ({OS.rand} mod Input.nRow) + 1
        Row
        Slot
    in
        Row = {Get X Input.map}
        Slot = {Get Y Row}
        if Slot==0 then pt(x:X y:Y)
        else {RandPosition} end
    end

    % State : Done
    fun {InitPosition PlayerState}
        case PlayerState
        of player(i:ID p:_) then
            Pos = {RandPosition}
        in
            %{System.show PlayerState#initPosition#Pos}
            player(i:ID p:Pos)
        else PlayerState end
    end

    fun {Move PlayerState Pos Dir}
        fun {ChooseNewPosition ListDir}
            X Y Row Slot
        in
            if ListDir==nil then PlayerState.p
            else
                case ListDir.1
                of north then
                    if PlayerState.p.x == 1 then {ChooseNewPosition ListDir.2}
                    else
                        Y = PlayerState.p.y
                        X = PlayerState.p.x-1
                        Row = {Get X Input.map}
                        Slot = {Get Y Row}
                        if Slot == 0 then newPosition(dir:north pos:pt(x:X y:Y))
                        else {ChooseNewPosition ListDir.2} end
                    end
                [] east then
                    if PlayerState.p.y == Input.nColumn then {ChooseNewPosition ListDir.2}
                    else
                        Y = PlayerState.p.y+1
                        X = PlayerState.p.x
                        Row = {Get X Input.map}
                        Slot = {Get Y Row}
                        if Slot == 0 then newPosition(dir:east pos:pt(x:X y:Y))
                        else {ChooseNewPosition ListDir.2} end
                    end
                [] south then
                    if PlayerState.p.x == Input.nRow then {ChooseNewPosition ListDir.2}
                    else
                        Y = PlayerState.p.y
                        X = PlayerState.p.x+1
                        Row = {Get X Input.map}
                        Slot = {Get Y Row}
                        if Slot == 0 then newPosition(dir:south pos:pt(x:X y:Y))
                        else {ChooseNewPosition ListDir.2} end
                    end
                else
                    if PlayerState.p.y == 1 then {ChooseNewPosition ListDir.2}
                    else
                        Y = PlayerState.p.y-1
                        X = PlayerState.p.x
                        Row = {Get X Input.map}
                        Slot = {Get Y Row}
                        if Slot == 0 then newPosition(dir:west pos:pt(x:X y:Y))
                        else {ChooseNewPosition ListDir.2} end
                    end
                end
            end
        end
        NewState Tmp
    in
        {System.show 'Choosing new position ...'}
        Tmp = {ChooseNewPosition [north east south west]}
        NewState = player(i:PlayerState.i p:Tmp.pos)
        Pos = Tmp.pos
        Dir = Tmp.dir
        {System.show 'New position chosen'}
        NewState
    end

    proc{TreatStream Stream PlayerState} % as as many parameters as you want
        case Stream
        of nil then {System.show playerStream#'nil'} skip
        [] H|T then
            {Browser.browse playerStream#H}
            case H
            of initPosition(X Y) then
                NewState={InitPosition PlayerState}
            in
                X = PlayerState.i
                Y = NewState.p
                {TreatStream T NewState}
            [] move(ID Pos Dir) then
                NewState = {Move PlayerState Pos Dir}
            in
                ID = NewState.i
                {TreatStream T NewState}
            [] dive then {TreatStream T PlayerState}
            [] chargeItem(ID KindItem) then {TreatStream T PlayerState}
            [] fireItem(ID KindFire) then {TreatStream T PlayerState}
            [] fireMine(ID Mine) then {TreatStream T PlayerState}
            [] isDead(Answer) then {TreatStream T PlayerState}
            [] sayMove(ID Dir) then {TreatStream T PlayerState}
            [] saySurface(ID) then {TreatStream T PlayerState}
            [] sayCharge(ID KindItem) then {TreatStream T PlayerState}
            [] sayMinePlaced(ID) then {TreatStream T PlayerState}
            [] sayMissileExplode(ID Pos Msg) then {TreatStream T PlayerState}
            [] sayMineExplode(ID Pos Msg) then {TreatStream T PlayerState}
            [] sayPassingDrone(Drone ID Answer) then {TreatStream T PlayerState}
            [] sayAnswerDrone(Drone ID Answer) then {TreatStream T PlayerState}
            [] sayPassingSonar(ID Answer) then {TreatStream T PlayerState}
            [] sayAnswerSonar(ID Answer) then {TreatStream T PlayerState}
            [] sayDeath(ID) then {TreatStream T PlayerState}
            [] sayDamageTaken(ID Damage LifeLeft) then {TreatStream T PlayerState}
            else {System.show error(where:'player -> TreatStream')} {TreatStream T PlayerState} end
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
