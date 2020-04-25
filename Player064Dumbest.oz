functor
import
    Input
    System
    OS
    Browser
export
    portPlayer:StartPlayer
define
    %InitPlayer
    InitPosition
    GetID
    Move
    Dive
    ChargeItem
    FireItem
    FireMine
    IsDead
    MissileExploded
    MineExploded
    PassingDrone
    PassingSonar

    TreatStream
    StartPlayer
    
    RandPosition 
    Get
    UpdateMap
    Abs
    ManhattanDistance

    % PlayerState : player(i:id p:position m:map s:surface/diving)
    % EnemiesState : row corresponding to the player with id row
    % [[isSurface Path Mines Missiles Drones]
    %  [isSurface Path Mines Missiles Drones]
    %  [isSurface Path Mines Missiles Drones]
    %  [isSurface Path Mines Missiles Drones]
    %  ... ]
in
    % State : Done
    fun {InitPosition}
        {RandPosition}
    end

    fun {GetID ID Player}
        if Player.health==0 then
            null
        else
            ID
        end
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


    fun {ChargeItem ChargingItems Charged}
        case ChargingItems
        of H|T then
            case H
            of Type#Charges then
                if Charges==Input.Type then H|{ChargeItem T Charged}
                else
                    if Charges+1 == Input.Type then 
                        Charged=Type
                        (Type#Charges+1)|T
                    else 
                        Charged=null 
                        (Type#Charges+1)|T
                    end
                end
            else H|{ChargeItem T Charged} end
        else 
            Charged=null 
            nil
        end
    end

    fun {FireItem ChargingItems PlayerPos Fired}
        fun {Fire Kind}
            fun {CheckPosition Pos}
                Row = {Get Pos.x Input.map}
                Slot = {Get Pos.y Row}
            in
                if Slot==1 then false
                else true end
            end
            fun {LaunchMine}
                ManhattanRange = (Input.maxDistanceMine-Input.minDistanceMine+1)
                X Y SgnX SgnY Pt
            in
                X = ({OS.rand} mod ManhattanRange) + Input.minDistanceMine
                SgnX = (({OS.rand} mod 2) * 2) - 1
                if X < ManhattanRange then
                    Y = ({OS.rand} mod (ManhattanRange - X)) + Input.minDistanceMine
                    SgnY = (({OS.rand} mod 2) * 2) - 1
                else
                    Y = 0
                    SgnY = 0
                end

                Pt = pt(x:PlayerPos.x + SgnX*X y:PlayerPos.y + SgnY*Y)
                if {CheckPosition Pt} then mine(Pt)
                else {LaunchMine} end
            end
            fun {LaunchMissile}
                    X Y SgnX SgnY Pt
                    ManhattanRange = (Input.maxDistanceMine-Input.minDistanceMine+1)
                in
                    X = ({OS.rand} mod Input.maxDistanceMissile) + Input.minDistanceMissile
                    SgnX = (({OS.rand} mod 2) * 2) - 1
                    if X<ManhattanRange then
                        Y = ({OS.rand} mod (Input.maxDistanceMissile - X)) + Input.minDistanceMissile
                        SgnY = (({OS.rand} mod 2) * 2) - 1
                    else 
                        Y = 0
                        SgnY = 0
                    end
                    
                    Pt = pt(x:PlayerPos.x + SgnX*X y:PlayerPos.y + SgnY*Y)
                    if {CheckPosition Pt} then missile(Pt)
                    else {LaunchMissile} end
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
            case Kind
            of mine then {LaunchMine}
            [] missile then {LaunchMissile}
            [] drone then {LaunchDrone}
            else sonar end
        end
    in
        case ChargingItems
        of H|T then
            case H
            of Type#Charges then
                if Charges==Input.Type then Fired={Fire Type} (Type#0)|T
                else H|{FireItem T PlayerPos Fired} end
            else H|{FireItem T PlayerPos Fired} end
        else 
            Fired=null 
            nil
        end
    end

    fun {FireMine PlacedMines FiredMine}
        case PlacedMines
        of H|T then FiredMine=H T
        else FiredMine=null PlacedMines end
    end

    fun {IsDead Health}
        Health == 0
    end

    fun {MissileExploded MissilePos ID Player}
        fun {TakeDamage PlayerPos}
            Dist = {ManhattanDistance PlayerPos MissilePos}
        in
            if Dist >= 2 then 0
            elseif Dist >= 1 then 1 
            else 2 end
        end
    in
        case Player
        of player(pos:P map:_ state:_ health:H) then 
            Damage = {TakeDamage P}
        in
            if Damage >= H then sayDeath(ID)
            elseif Damage > 0 then sayDamageTaken(ID Damage H-Damage)
            else null end
        end
    end

    fun {MineExploded MinePos ID Player AttackerID}
        {MissileExploded MinePos ID Player}
    end

    fun {PassingDrone Drone Player}
        case Drone
        of drone(row R) then R == Player.pos.x
        [] drone(column C) then C == Player.pos.y
        else false end
    end

    fun {PassingSonar Player}
        Choose = {OS.rand} mod 2
    in
        if Choose < 1 then
            R = ({OS.rand} mod Input.nRow) + 1
        in
            pt(x:R y:Player.pos.y)
        else 
            C = ({OS.rand} mod Input.nColumn) + 1
        in
            pt(x:Player.pos.x y:C)
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

    fun {Abs X}
        if X>0 then X
        else ~1*X end
    end

    fun {ManhattanDistance P1 P2}
        {Abs (P1.x-P2.x)} + {Abs (P1.y-P2.y)}
    end

    proc{TreatStream ID Stream Player Items} % as as many parameters as you want
        case Stream
        of nil then {System.show playerStream#'nil'} skip
        [] H|T then
            case H
            of initPosition(I NewPos) then
                I = {GetID ID Player}
                NewPos={InitPosition}
                {TreatStream T ID player(pos:NewPos map:Input.map state:Player.state health:Player.health) Items}
            [] move(I NewPos Dir) then
                NewMap NewState
            in
                move(pos:NewPos dir:Dir map:NewMap) = {Move Player.pos Player.map Player.state}

                I = {GetID ID Player}
                if Dir == surface then NewState=surface
                else NewState=diving end

                {TreatStream T ID player(pos:NewPos map:NewMap state:NewState health:Player.health) Items}
            [] dive then 
                NewMap NewState
            in
                dive(m:NewMap s:NewState) = {Dive Player.map Player.state}
                {TreatStream T ID player(pos:Player.pos map:NewMap state:NewState health:Player.health) Items}
            [] chargeItem(I KindItem) then 
                I = {GetID ID Player}
                {TreatStream T ID Player items(charging:{ChargeItem Items.charging KindItem} placed:Items.placed)}
            [] fireItem(I KindFire) then 
                NewChargingItems in
                NewChargingItems = {FireItem Items.charging Player.pos KindFire}
                I = {GetID ID Player}
                case KindFire 
                of mine(_) then {TreatStream ID T Player items(charging:NewChargingItems placed:KindFire|Items.placed)}
                else {TreatStream T ID Player items(charging:NewChargingItems placed:Items.placed)} end             
            [] fireMine(I Mine) then 
                NewPlacedItems = {FireMine Items.placed Mine}
            in
                I = {GetID ID Player}
                {TreatStream T ID Player items(charging:Items.charging placed:NewPlacedItems)}
            [] isDead(Answer) then 
                Answer = {IsDead Player.health}
                {TreatStream T ID Player Items}
            [] sayMove(I Dir) then 
                % To be implemented
                {TreatStream T ID Player Items}
            [] saySurface(I) then 
                % To be implemented
                {TreatStream T ID Player Items}
            [] sayCharge(I KindItem) then
                % To be implemented
                {TreatStream T ID Player Items}
            [] sayMinePlaced(I) then 
                % To be implemented
                {TreatStream T ID Player Items}
            [] sayMissileExplode(I Pos Msg) then
                Msg = {MissileExploded Pos ID Player}
                case Msg
                of sayDamageTaken(_ _ L) then {TreatStream T ID player(pos:Player.pos map:Player.map state:Player.state health:L) Items}
                [] null then {TreatStream T ID Player Items}
                else {TreatStream T ID player(pos:Player.pos map:Player.map state:Player.state health:0) Items} end
            [] sayMineExplode(I Pos Msg) then 
                Msg = {MineExploded Pos ID Player I}
                case Msg
                of sayDamageTaken(_ _ L) then {TreatStream T ID player(pos:Player.pos map:Player.map state:Player.state health:L) Items}
                [] null then {TreatStream T ID Player Items}
                else {TreatStream ID T player(pos:Player.pos map:Player.map state:Player.state health:0) Items} end
            [] sayPassingDrone(Drone I Answer) then 
                I = {GetID ID Player}
                Answer = {PassingDrone Drone Player}
                {TreatStream T ID Player Items}
            [] sayAnswerDrone(Drone I Answer) then 
                % To be implemented
                {TreatStream T ID Player Items}
            [] sayPassingSonar(I Answer) then
                I = {GetID ID Player}
                Answer = {PassingSonar Player}
                {TreatStream T ID Player Items}
            [] sayAnswerSonar(I Answer) then
                % To be implemented
                {TreatStream T ID Player Items}
            [] sayDeath(I) then
                % To be implemented
                {TreatStream T ID Player Items}
            [] sayDamageTaken(I Damage LifeLeft) then
                % To be implemented
                {TreatStream T ID Player Items}
            else {System.show error(where:'player -> TreatStream' who:ID what:H)} {TreatStream T ID Player Items} end
        else {TreatStream Stream ID Player Items} end
    end

    fun{StartPlayer Color ID}
        Stream
        Port
    in
        {NewPort Stream Port}
        thread
            {TreatStream Stream 
                        id(id:ID color:Color name:'Dumbest')
                        player(pos:_ map:Input.map state:diving health:Input.maxDamage) 
                        items(charging:[missile#0 mine#0 sonar#0 drone#0] placed:nil) 
                        }
        end
        Port
    end
end
