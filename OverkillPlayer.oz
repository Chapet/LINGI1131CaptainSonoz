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
    InitOthers
    InitPosition
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
    OtherIsDead
    UpdateDirections

    TreatStream
    StartPlayer
    
    RandPosition 
    UpdateMap
    Abs
    ManhattanDistance
    NbStartPoints
    GetSlot
    Append

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

    fun {InitOthers I Acc NbStarts}
        if I>Input.nbPlayers then Acc
        else 
            {InitOthers I+1 other(alive:Input.maxDamage path:nil map:Input.map nbStarts:NbStarts)|Acc}
        end
    end

    fun {Move OldPos OldMap OldState}
            fun {ChooseNewPosition ListDir}
                X Y 
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
                            if {IsFreeSlot X Y OldMap} then newPosition(dir:north pos:pt(x:X y:Y))
                            else {ChooseNewPosition ListDir.2} end
                        end
                    [] east then
                        if OldPos.y == Input.nColumn then {ChooseNewPosition ListDir.2}
                        else
                            Y = OldPos.y+1
                            X = OldPos.x
                            if {IsFreeSlot X Y OldMap}  then newPosition(dir:east pos:pt(x:X y:Y))
                            else {ChooseNewPosition ListDir.2} end
                        end
                    [] south then
                        if OldPos.x == Input.nRow then {ChooseNewPosition ListDir.2}
                        else
                            Y = OldPos.y
                            X = OldPos.x+1
                            if {IsFreeSlot X Y OldMap}  then newPosition(dir:south pos:pt(x:X y:Y))
                            else {ChooseNewPosition ListDir.2} end
                        end
                    else
                        if OldPos.y == 1 then {ChooseNewPosition ListDir.2}
                        else
                            Y = OldPos.y-1
                            X = OldPos.x
                            if {IsFreeSlot X Y OldMap}  then newPosition(dir:west pos:pt(x:X y:Y))
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
            of I#N then
                if N==Input.I then H|{ChargeItem T Charged}
                else
                    if N+1 == Input.I then 
                        Charged=I 
                        (I#N+1)|T
                    else 
                        Charged=null 
                        (I#N+1)|T
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
                    fun {LaunchMine}
                            ManhattanRange = (Input.maxDistanceMine-Input.minDistanceMine+1)
                            X Y SgnX SgnY Pt Tmp
                        in
                            X = ({OS.rand} mod ManhattanRange) + Input.minDistanceMine
                            SgnX = (({OS.rand} mod 2) * 2) - 1
                            if X < ManhattanRange then
                                Y = ({OS.rand} mod (ManhattanRange - X)) + Input.minDistanceMine
                                SgnY = (({OS.rand} mod 2) * 2) - 1
                                Pt = pt(x:PlayerPos.x + SgnX*X y:PlayerPos.y + SgnY*Y)
                            else
                                Pt = pt(x:PlayerPos.x + SgnX*X y:PlayerPos.y)
                            end

                            Tmp = {IsFreeSlot Pt.x Pt.y Input.map}
                            if Tmp==indexOutOfBound then {LaunchMine}
                            elseif Tmp then mine(Pt)
                            else {LaunchMine} end
                    end
                    fun {LaunchMissile}
                            X = ({OS.rand} mod Input.maxDistanceMissile) + Input.minDistanceMissile
                            Y = ({OS.rand} mod (Input.maxDistanceMissile - X)) + Input.minDistanceMissile
                            SgnX = (({OS.rand} mod 2) * 2) - 1
                            SgnY = (({OS.rand} mod 2) * 2) - 1
                            Pt = pt(x:PlayerPos.x + SgnX*X y:PlayerPos.y + SgnY*Y)
                            Tmp
                        in
                            Tmp = {IsFreeSlot Pt.x Pt.y Input.map}
                            if Tmp==indexOutOfBound then {LaunchMissile}
                            elseif Tmp then missile(Pt)
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
                    {System.show firing#Kind}
                    case Kind
                    of mine then {LaunchMine}
                    [] missile then {LaunchMissile}
                    [] drone then {LaunchDrone}
                    else sonar end
            end
        in
            case ChargingItems
            of H|T then
                {System.show fireItem#H}
                case H
                of I#N then
                    if N==Input.I then Fired={Fire I} (I#0)|T
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

    fun {OtherIsDead ID Others}
            fun {Loop L I}
                case L
                of H|T then
                    if I==ID then other(alive:false path:H.path map:H.map)|T
                    else H|{Loop T I+1} end
                else nil end
            end
        in
            {Loop Others 1}
    end

    fun {UpdateDirections ID Dir Others}         
            fun {UpdateOtherMap Map Path NewNbStarts OldNbStarts}
                    fun {IsImpossibleSlot X Y M}
                        if X<1 orelse X>Input.nRow then true
                        elseif Y<1 orelse Y>Input.nColumn then true
                        elseif {IsFreeSlot X Y M} then false
                        else true end
                    end
                    fun {LockPosition X Y M}
                            fun {LockRow I M}
                                case M
                                of R|Rs then 
                                    if I==X then {LockCol 1 R}|Rs
                                    else R|{LockRow I+1 Rs} end
                                else nil end
                            end
                            fun {LockCol J Row}
                                case Row
                                of C|Cs then 
                                    if J==Y then (~1)|Cs
                                    else C|{LockCol J+1 Cs} end
                                    else nil end
                            end
                        in
                            {LockRow 1 M}
                    end
                    fun {DeduceStartPoint X Y P M NewFree OldFree}
                        case P
                        of H|T then
                            A B in
                            case H
                            of north then
                                A = X+1
                                B = Y
                            [] east then
                                A = X
                                B = Y-1
                            [] south then
                                A = X-1
                                B = Y
                            [] west then
                                A = X
                                B = Y+1
                            else 
                                A=X 
                                B=Y                       
                            end
                            if {IsImpossibleSlot A B M} then
                                NewFree = OldFree 
                                M
                            else {DeduceStartPoint A B T M NewFree OldFree} end
                        else
                            NewFree = OldFree-1 
                            {LockPosition X Y M} 
                        end
                    end
                    fun {CheckPositions X Y M CurrentFree}
                        if (Y>Input.nColumn andthen X==0) orelse (Y>Input.nColumn andthen X>Input.nRow) orelse (Y>Input.nColumn+1) then
                            if X>Input.nRow then NewNbStarts=CurrentFree M
                            elseif  X==Input.nRow then {CheckPositions X+1 1 M CurrentFree}
                            else {CheckPositions X+1 0 M CurrentFree} end
                        else 
                            if {IsImpossibleSlot X Y M} then
                            Tmp in
                            {CheckPositions X Y+1 {DeduceStartPoint X Y Path M Tmp CurrentFree} Tmp}
                            else {CheckPositions X Y+1 M CurrentFree} end
                        end
                    end
                in
                    {CheckPositions 0 1 Map OldNbStarts}
            end
            fun {SearchPlayer I L}
                case L
                of H|T then 
                    if I==ID then 
                    NewNbStarts in
                    other(alive:H.alive path:Dir|H.path map:{UpdateOtherMap H.map Dir|H.path NewNbStarts H.nbStarts} nbStarts:NewNbStarts)|T
                    else H|{SearchPlayer I+1 T} end
                else nil end
            end
        in
            {SearchPlayer 1 Others}
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
   
    % State : Done
    fun {RandPosition}
            Y = ({OS.rand} mod Input.nColumn) + 1
            X = ({OS.rand} mod Input.nRow) + 1
            B = {IsFreeSlot X Y Input.map} 
        in
            if B==indexOutOfBound then {RandPosition}
            elseif B then pt(x:X y:Y)
            else {RandPosition} end
    end

    fun {Abs X}
        if X>0 then X
        else ~1*X end
    end

    fun {ManhattanDistance P1 P2}
        {Abs (P1.x-P2.x)} + {Abs (P1.y-P2.y)}
    end

    fun {NbStartPoints X Y Acc}
        if Y>Input.nColumn then
            if X==Input.nRow then Acc
            else {NbStartPoints X+1 1 Acc} end
        else 
            if {IsFreeSlot X Y Input.map} then {NbStartPoints X Y+1 Acc}
            else {NbStartPoints X Y+1 Acc+1} end
        end
    end

    fun {IsFreeSlot X Y M}
            fun {Get N M}
                case M
                of H|T then
                    if N==1 then H
                    else {Get N-1 T} end
                else indexOutOfBound end
            end
            Row 
            Slot
        in
            Row = {Get X M}
            if Row==indexOutOfBound then {System.show indexOutOfBound} indexOutOfBound
            else 
                Slot = {Get Y Row}
                if Slot==indexOutOfBound then {System.show indexOutOfBound} indexOutOfBound
                elseif Slot==1 then false
                else true end
            end
   end

    fun {Append L1 L2}
        case L1
        of H|T then H|{Append T L2}
        else L2 end
    end

    proc{TreatStream ID Stream Player Items Others} % as as many parameters as you want
        case Stream
        of nil then {System.show playerStream#'nil'} skip
        [] H|T then
            {System.show myPlayer#H}
            case H
            of initPosition(I NewPos) then
                I = ID
                NewPos={InitPosition}
                {TreatStream T ID player(pos:NewPos map:Input.map state:Player.state health:Player.health) Items Others}
            [] move(I NewPos Dir) then
                NewMap NewState
            in
                %{System.show 'moving'}
                move(pos:NewPos dir:Dir map:NewMap) = {Move Player.pos Player.map Player.state}
                %{System.show 'moved'}

                I = ID
                if Dir == surface then NewState=surface
                else NewState=diving end

                {TreatStream T ID player(pos:NewPos map:NewMap state:NewState health:Player.health) Items Others}
            [] dive then 
                NewMap NewState
            in
                dive(m:NewMap s:NewState) = {Dive Player.map Player.state}
                {TreatStream T ID player(pos:Player.pos map:NewMap state:NewState health:Player.health) Items Others}
            [] chargeItem(I KindItem) then 
                I = ID
                {TreatStream T ID Player items(charging:{ChargeItem Items.charging KindItem} placed:Items.placed) Others}
            [] fireItem(I KindFire) then 
                NewChargingItems in
                {System.show myPlayer#fireItem(charging:Items.charging pos:Player.pos)}
                NewChargingItems = {FireItem Items.charging Player.pos KindFire}
                {System.show myPlayer#fireItem(KindFire NewChargingItems)}
                I = ID
                case KindFire 
                of mine(_) then {TreatStream ID T Player items(charging:NewChargingItems placed:KindFire|Items.placed) Others}
                else {TreatStream T ID Player items(charging:NewChargingItems placed:Items.placed) Others} end             
            [] fireMine(I Mine) then 
                NewPlacedItems = {FireMine Items.placed Mine}
            in
                I = ID
                {TreatStream T ID Player items(charging:Items.charging placed:NewPlacedItems) Others}
            [] isDead(Answer) then 
                Answer = {IsDead Player.health}
                {TreatStream T ID Player Items Others}
            [] sayMove(I Dir) then 
                % To be implemented
                {TreatStream T ID Player Items Others}
            [] saySurface(I) then 
                % To be implemented
                {TreatStream T ID Player Items Others}
            [] sayCharge(I KindItem) then
                % To be implemented
                {TreatStream T ID Player Items Others}
            [] sayMinePlaced(I) then 
                % To be implemented
                {TreatStream T ID Player Items Others}
            [] sayMissileExplode(I Pos Msg) then
                Msg = {MissileExploded Pos ID Player}
                case Msg
                of sayDamageTaken(_ _ L) then {TreatStream T ID player(pos:Player.pos map:Player.map state:Player.state health:L) Items Others}
                [] null then {TreatStream T ID Player Items Others}
                else {TreatStream T ID player(pos:Player.pos map:Player.map state:Player.state health:0) Items Others} end
            [] sayMineExplode(I Pos Msg) then 
                Msg = {MineExploded Pos ID Player I}
                case Msg
                of sayDamageTaken(_ _ L) then {TreatStream T ID player(pos:Player.pos map:Player.map state:Player.state health:L) Items Others}
                [] null then {TreatStream T ID Player Items Others}
                else {TreatStream ID T player(pos:Player.pos map:Player.map state:Player.state health:0) Items Others} end
            [] sayPassingDrone(Drone I Answer) then 
                I = ID
                Answer = {PassingDrone Drone Player}
                {TreatStream T ID Player Items Others}
            [] sayAnswerDrone(Drone I Answer) then 
                % To be implemented
                {TreatStream T ID Player Items Others}
            [] sayPassingSonar(I Answer) then
                I = ID
                Answer = {PassingSonar Player}
                {TreatStream T ID Player Items Others}
            [] sayAnswerSonar(I Answer) then
                % To be implemented
                {TreatStream T ID Player Items Others}
            [] sayDeath(I) then
                % To be implemented
                {TreatStream T ID Player Items {OtherIsDead I Others}}
            [] sayDamageTaken(I Damage LifeLeft) then
                % To be implemented
                {TreatStream T ID Player Items Others}
            else {System.show error(where:'player -> TreatStream')} {TreatStream T ID Player Items} end
        else {TreatStream Stream ID Player Items} end
    end

    fun{StartPlayer Color ID}
            Stream
            Port
        in
            {NewPort Stream Port}
            thread
                {TreatStream Stream 
                            id(id:ID color:Color name:'Name')
                            player(pos:_ map:Input.map state:diving health:Input.maxDamage) 
                            items(charging:[mine#0 missile#0 drone#0 sonar#0] placed:nil) 
                            {InitOthers 1 nil {NbStartPoints 1 1 0}}
                            }
            end
            Port
    end
end
