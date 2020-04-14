functor
import
    Input
    System
    OS
    Browser
export
    portPlayer:StartPlayer
define
    InitPlayer
    InitPosition
    Move
    Dive
    ChargeItem
    FireItem

    TreatStream
    StartPlayer
    
    RandPosition 
    Get
    UpdateMap

    ID
    % PlayerState : player(i:id p:position m:map s:surface/diving)
    % EnemiesState : row corresponding to the player with id row
    % [[isSurface Path Mines Missiles Drones]
    %  [isSurface Path Mines Missiles Drones]
    %  [isSurface Path Mines Missiles Drones]
    %  [isSurface Path Mines Missiles Drones]
    %  ... ]
in
    proc {InitPlayer I}
        ID = I 
    end

    % State : Done
    fun {InitPosition}
        {RandPosition}
    end

    fun {Move OldPos OldMap OldState}
        fun {ChooseNewPosition ListDir}
            X Y Row Slot
        in
            %{System.show ListDir#Map}
            if ListDir==nil then newPosition(dir:surface pos:OldPos)
            else
                case ListDir.1
                of north then
                    if OldPos.x == 1 then {ChooseNewPosition ListDir.2}
                    else
                        Y = OldPos.y
                        X = OldPos.x-1
                        Row = {Get X OldMap}
                        Slot = {Get Y Row}
                        if Slot == 0 then newPosition(dir:north pos:pt(x:X y:Y))
                        else {ChooseNewPosition ListDir.2} end
                    end
                [] east then
                    if OldPos.y == Input.nColumn then {ChooseNewPosition ListDir.2}
                    else
                        Y = OldPos.y+1
                        X = OldPos.x
                        Row = {Get X OldMap}
                        Slot = {Get Y Row}
                        if Slot == 0 then newPosition(dir:east pos:pt(x:X y:Y))
                        else {ChooseNewPosition ListDir.2} end
                    end
                [] south then
                    if OldPos.x == Input.nRow then {ChooseNewPosition ListDir.2}
                    else
                        Y = OldPos.y
                        X = OldPos.x+1
                        Row = {Get X OldMap}
                        Slot = {Get Y Row}
                        if Slot == 0 then newPosition(dir:south pos:pt(x:X y:Y))
                        else {ChooseNewPosition ListDir.2} end
                    end
                else
                    if OldPos.y == 1 then {ChooseNewPosition ListDir.2}
                    else
                        Y = OldPos.y-1
                        X = OldPos.x
                        Row = {Get X OldMap}
                        Slot = {Get Y Row}
                        if Slot == 0 then newPosition(dir:west pos:pt(x:X y:Y))
                        else {ChooseNewPosition ListDir.2} end
                    end
                end
            end
        end
        NewPos
    in
        {System.show 'choosing new position'}
        NewPos = {ChooseNewPosition [north east south west]}
        {System.show 'new position chosen'#NewPos}
        move(pos:NewPos.pos dir:NewPos.dir map:{UpdateMap OldMap OldPos.x OldPos.y})
    end

    % State : Done
    fun {Dive Map State}
        case State
        of surface then 
            dive(m:Input.map s:diving)
        else dive(m:Map s:diving) end
    end


    fun {ChargeItem Items}
        case Items
        of items(mines#N1 missiles#N2 drones#N3 sonars#N4) then
            R = {OS.rand} mod 4
            N
        in
            if R < 1 then 
                N = (N1 mod Input.mine)+1
                if N >= Input.mine then charged(mine items(mines#N missiles#N2 drones#N3 sonars#N4))
                else charged(null items(mines#N missiles#N2 drones#N3 sonars#N4)) end
            elseif R < 2 then 
                N = (N2 mod Input.missile)+1
                if N >= Input.missile then charged(missile items(mines#N1 missiles#N drones#N3 sonars#N4))
                else charged(null items(mines#N1 missiles#N drones#N3 sonars#N4)) end
            elseif R < 3 then 
                N = (N3 mod Input.drone)+1
                if N >= Input.drone then charged(drone items(mines#N1 missiles#N2 drones#N sonars#N4))
                else charged(null items(mines#N1 missiles#N2 drones#N sonars#N4)) end
            else
                N = (N4 mod Input.sonar)+1
                if N >= Input.sonar then charged(sonar items(mines#N1 missiles#N2 drones#N3 sonars#N))
                else charged(null items(mines#N1 missiles#N2 drones#N3 sonars#N)) end
            end
        end
    end

    fun {FireItem Items Pos}
        fun {PlaceMine}
            X = ({OS.rand} mod Input.maxDistanceMine) + Input.minDistanceMine
            Y = ({OS.rand} mod (Input.maxDistanceMine - X)) + Input.minDistanceMine
            SgnX = (({OS.rand} mod 2) * 2) - 1
            SgnY = (({OS.rand} mod 2) * 2) - 1
        in
            mine(pt(x:Pos.x + SgnX*X y:Pos.y + SgnY*Y))
        end
        fun {LaunchMissile}
            X = ({OS.rand} mod Input.maxDistanceMissile) + Input.minDistanceMissile
            Y = ({OS.rand} mod (Input.maxDistanceMissile - X)) + Input.minDistanceMissile
            SgnX = (({OS.rand} mod 2) * 2) - 1
            SgnY = (({OS.rand} mod 2) * 2) - 1
        in
            missile(pt(x:Pos.x + SgnX*X y:Pos.y + SgnY*Y))
        end
        fun {LaunchDrone}
            B = {OS.rand} mod 2
        in
            if B < 1 then
                Row = ({OS.rand} mod Input.nRow) + 1
            in
                drone(row Row)
            else 
                Column = ({OS.rand} mod Input.nColumn) + 1
            in
                drone(column Column)
            end
        end
    in
        case Items
        of items(mines#N1 missiles#N2 drones#N3 sonars#N4) then
            R = {OS.rand} mod 4
        in
            if R < 1 then 
                if N1 >= Input.mine then fired({PlaceMine} items(mines#(N1-Input.mine) missiles#N2 drones#N3 sonars#N4))
                else fired(null Items) end
            elseif R < 2 then 
                if N2 >= Input.missile then fired({LaunchMissile} items(mines#N1 missiles#(N2-Input.missile) drones#N3 sonars#N4))
                else fired(null Items) end
            elseif R < 3 then 
                if N3 >= Input.drone then fired({LaunchDrone} items(mines#N1 missiles#N2 drones#(N3-Input.drone) sonars#N4))
                else fired(null Items) end
            else
                if N4 >= Input.sonar then fired(sonar items(mines#N1 missiles#N2 drones#N3 sonars#(N4-Input.sonar)))
                else fired(null Items) end
            end
        end
    end

    fun {UpdateMap Map X Y}
        fun {UpdateRow R Y}
            case R
            of H|T then
                if Y==1 then
                    if H==1 then 0|T
                    else 1|T end
                else H|{UpdateRow T Y-1} end
            else nil end
        end
    in
        %{Browser.browse Map#X#Y}
        case Map
        of H|T then
            if X==1 then {UpdateRow H Y}|T
            else H|{UpdateMap T X-1 Y} end
        else nil end
    end

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

    proc{TreatStream Stream Pos Map State Items} % as as many parameters as you want
        case Stream
        of nil then {System.show playerStream#'nil'} skip
        [] H|T then
            %{Browser.browse playerStream#H}
            case H
            of initPosition(I NewPos) then
                I = ID
                NewPos={InitPosition}
                {TreatStream T NewPos Input.map diving Items}
            [] move(I NewPos Dir) then
                NewMap NewState
            in
                {System.show 'moving'}
                move(pos:NewPos dir:Dir map:NewMap) = {Move Pos Map State}
                {System.show 'moved'}

                I = ID
                if Dir == surface then NewState=surface
                else NewState=diving end

                {TreatStream T NewPos NewMap NewState Items}
            [] dive then 
                NewMap NewState
            in
                dive(m:NewMap s:NewState) = {Dive Map State}
                {TreatStream T Pos NewMap NewState Items}
            [] chargeItem(ID KindItem) then 
                NewItems in
                charged(KindItem NewItems) = {ChargeItem Items}
                {TreatStream T Pos Map State NewItems}
            [] fireItem(ID KindFire) then 
                NewItems in
                fired(KindFire NewItems) = {ChargeItem Items}
                {TreatStream T Pos Map State NewItems}
            % [] fireMine(ID Mine) then {TreatStream T Pos Map State}
            % [] isDead(Answer) then {TreatStream T Pos Map State}
            % [] sayMove(ID Dir) then {TreatStream T Pos Map State}
            % [] saySurface(ID) then {TreatStream T Pos Map State}
            % [] sayCharge(ID KindItem) then {TreatStream T Pos Map State}
            % [] sayMinePlaced(ID) then {TreatStream T Pos Map State}
            % [] sayMissileExplode(ID Pos Msg) then {TreatStream T Pos Map State}
            % [] sayMineExplode(ID Pos Msg) then {TreatStream T Pos Map State}
            % [] sayPassingDrone(Drone ID Answer) then {TreatStream T Pos Map State}
            % [] sayAnswerDrone(Drone ID Answer) then {TreatStream T Pos Map State}
            % [] sayPassingSonar(ID Answer) then {TreatStream T Pos Map State}
            % [] sayAnswerSonar(ID Answer) then {TreatStream T Pos Map State}
            % [] sayDeath(ID) then {TreatStream T Pos Map State}
            % [] sayDamageTaken(ID Damage LifeLeft) then {TreatStream T Pos Map State}
            else {System.show error(where:'player -> TreatStream')} {TreatStream T Pos Map State Items} end
        else {TreatStream Stream Pos Map State Items} end
    end

    fun{StartPlayer Color ID}
        Stream
        Port
    in
        {NewPort Stream Port}
        thread
            {InitPlayer id(id:ID color:Color name:'Name')}
            {TreatStream Stream _ Input.map diving items(mines#0 missiles#0 drones#0 sonars#0)}
        end
        Port
    end
end
