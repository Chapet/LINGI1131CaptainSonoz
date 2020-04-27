functor
import
    Input
    System
    OS
export
    portPlayer:StartPlayer
define
    %InitPlayer
    InitOthers
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
    IsFreeSlot

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

    fun {InitOthers I Acc NbStarts}
        if I>Input.nbPlayer then Acc
        else 
            {InitOthers I+1 other(alive:true path:nil map:Input.map nbStarts:NbStarts)|Acc NbStarts}
        end
    end

    fun {Move OldPos OldMap OldState}
            fun {ChooseNewPosition ListDir}
                    X Y 
                in
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
            fun {RandomDirections Directions Acc}
                    fun {Length L Acc}
                        case L
                        of H|T then {Length T Acc+1}
                        else Acc end
                    end
                    fun {GetAndRemoveNth N Directions Output}
                        case Directions
                        of H|T then 
                            if N==1 then Output=H T
                            else H|{GetAndRemoveNth N-1 T Output} end
                        else Output=nil nil end
                    end
                in
                    case Directions
                    of nil then Acc
                    else
                            Rand = ({OS.rand} mod {Length Directions 0}) + 1
                            NewDir NewDirections
                        in
                            NewDirections = {GetAndRemoveNth Rand Directions NewDir}
                            {RandomDirections NewDirections NewDir|Acc}
                    end
            end
            NewPos
        in
            %NewPos = {ChooseNewPosition [north east south west]}
            NewPos = {ChooseNewPosition {RandomDirections [north east south west] nil}}
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

    fun {FireItem ChargingItems PlayerPos Fired Others}
            fun {Fire Kind}
                    fun {SelectPlayers NbStartingPos Others Acc}
                        case Others
                        of H|T then
                            if H.nbStarts == NbStartingPos then {SelectPlayers NbStartingPos T H|Acc}
                            else {SelectPlayers NbStartingPos T Acc} end
                        else Acc end
                    end
                    fun {AllPossibleInitPositions Other Min Max}
                            fun {IsPossibleSlot X Y M}
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
                                    Slot = {Get Y Row}
                                    if Slot==0 then true
                                    else true end
                            end
                            fun {SelectOnMap X Y Map Acc}
                                if Y>Input.nColumn then
                                    if X==Input.nRow then Acc
                                    else {SelectOnMap X+1 1 Map Acc} end
                                else
                                    if {IsPossibleSlot X Y Map} then {SelectOnMap X Y+1 Map pt(x:X y:Y)|Acc} 
                                    else {SelectOnMap X Y+1 Map Acc} end
                                end
                            end
                        in
                            case Other
                            of other(alive:_ path:_ map:M nbStarts:_) then {SelectOnMap 1 1 M nil} end
                    end
                    fun {ReversePath Path Position}
                        case Path
                        of north|T then {ReversePath T pt(x:Position.x+1 y:Position.y)}
                        [] east|T then {ReversePath T pt(x:Position.x y:Position.y-1)}
                        [] south|T then {ReversePath T pt(x:Position.x-1 y:Position.y)}
                        [] west|T then {ReversePath T pt(x:Position.x y:Position.y+1)}
                        else Position end
                    end
                    fun {WithinReach Position MinRange MaxRange}
                        if {ManhattanDistance PlayerPos Position} =< MaxRange + 1 andthen {ManhattanDistance PlayerPos Position} >= MinRange-1 then true
                        else false end
                    end
                    fun {Loop N Type}
                        % if I>N then null
                        % else
                        BestOpponentPosition MinRange MaxRange in
                        if Type==missile then MinRange=Input.minDistanceMissile MaxRange=Input.maxDistanceMissile 
                        else MinRange=Input.minDistanceMine MaxRange=Input.maxDistanceMine end

                        for break:Break I in 1..(N+1) do %all possible number of starting points
                            if I=<N then
                                Opponents = {SelectPlayers I Others nil} in
                                for Opp in Opponents do % Every opponent with maximum I starting points
                                    InitPositions = {AllPossibleInitPositions Opp MinRange MaxRange} in
                                    for InitPos in InitPositions do % Every possible starting point for opponent Opp
                                        CurrentPos = {ReversePath Opp.path InitPos} in
                                        if {WithinReach CurrentPos MinRange MaxRange} andthen {IsFreeSlot CurrentPos.x CurrentPos.y Input.map} then BestOpponentPosition = CurrentPos {Break} end
                                    end
                                end
                            else BestOpponentPosition = null end
                        end
                        BestOpponentPosition
                            % if Other \= null then 
                            %     InitPositions = {AllPossibleInitPositions Other Min Max nil} in
                            %     if InitPos \= null then {ReversePath Other.path InitPos}
                            %     else {Loop I+1 N Min Max} end
                            % else {Loop I+1 N Min Max} end 
                        %end
                    end
                    fun {RandomPosition Min Max}
                            X Y SgnX SgnY Pt IsFree
                            ManhattanRange = (Max-Min+1)
                        in
                            X = ({OS.rand} mod Max) + Min
                            SgnX = (({OS.rand} mod 2) * 2) - 1
                            if X<ManhattanRange then
                                Y = ({OS.rand} mod (Max - X)) + Min
                                SgnY = (({OS.rand} mod 2) * 2) - 1
                            else 
                                Y = 0
                                SgnY = 0
                            end
                            
                            Pt = pt(x:PlayerPos.x + SgnX*X y:PlayerPos.y + SgnY*Y)
                            IsFree = {IsFreeSlot Pt.x Pt.y Input.map}
                            if IsFree==indexOutOfBound then {RandomPosition Min Max}
                            elseif IsFree then Pt
                            else {RandomPosition Min Max} end
                    end   
                    fun {FindHitPosition OppPosition MinRange MaxRange}
                            fun {NearestX}
                                if {Abs OppPosition.x-PlayerPos.x} > MaxRange then 
                                    if OppPosition.x > PlayerPos.x then PlayerPos.x+MaxRange
                                    else PlayerPos.x-MaxRange end
                                else OppPosition.x end
                            end
                            fun {FindY CurrentY}
                                if {ManhattanDistance pt(x:X y:CurrentY) PlayerPos} > MaxRange then
                                    if CurrentY<PlayerPos.y then {FindY CurrentY+1}
                                    else {FindY CurrentY-1} end
                                else 
                                    if {ManhattanDistance pt(x:X y:CurrentY) PlayerPos} < MinRange then 
                                        if CurrentY<PlayerPos.y then {FindY CurrentY-1}
                                        else {FindY CurrentY+1} end
                                    else CurrentY end
                                end
                            end
                            X Y
                        in
                            X = {NearestX}
                            Y = {FindY OppPosition.y}
                            {System.show '===== current position '#PlayerPos.x#PlayerPos.y#' ====='} 
                            {System.show '===== hit position '#X#Y#' ====='}
                            pt(x:X y:Y)
                    end
                    fun {LaunchMine}
                            N = (Input.nRow * Input.nColumn) div 5
                            OppPosition = {Loop N mine}
                        in     
                            {System.show '===== mine -> OppPosition'#OppPosition#' with N '#N#' ====='}              
                            if OppPosition==null then null %mine({RandomPosition Input.minDistanceMine  Input.maxDistanceMine})
                            else mine({FindHitPosition OppPosition Input.minDistanceMine Input.maxDistanceMine}) end
                    end
                    fun {LaunchMissile}                                  
                            N = (Input.nRow * Input.nColumn) div 5
                            OppPosition = {Loop N missile}
                        in   
                            {System.show '===== missile -> OppPosition'#OppPosition#' with N '#N#' ====='}                     
                            if OppPosition==null then null %missile({RandomPosition Input.minDistanceMissile  Input.maxDistanceMissile})
                            else missile({FindHitPosition OppPosition Input.minDistanceMissile Input.maxDistanceMissile}) end
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
                    if Charges==Input.Type then 
                        {System.show '===== firing'#Type#' ====='}
                        Fired={Fire Type} 
                        {System.show '===== fired'#Fired#' ====='}
                        if Fired \= null then (Type#0)|T
                        else H|T end
                    else H|{FireItem T PlayerPos Fired Others} end
                else H|{FireItem T PlayerPos Fired Others} end
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
                        if X<1 orelse X>Input.nRow orelse Y<1 orelse Y>Input.nColumn then true
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
                    fun {DeduceStartPoint X Y P M NewFree CurrentFree}
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
                            %{System.show 'deduce '#H#X#Y#A#B} 
                            if {IsImpossibleSlot A B M} then
                                NewFree = CurrentFree 
                                M
                            else {DeduceStartPoint A B T M NewFree CurrentFree} end
                        else
                            if {IsImpossibleSlot X Y M} then
                                NewFree = CurrentFree 
                                M
                            else
                                NewFree = CurrentFree-1
                                %{System.show 'locking position -> new free'#NewFree} 
                                {LockPosition X Y M} 
                            end
                        end
                    end
                    fun {CheckPositions X Y OldMap CurrentFree}
                        %{System.show 'checkPositions'#X#Y}
                        if (Y>Input.nColumn andthen X==0) orelse (Y>Input.nColumn andthen X>Input.nRow) orelse (Y>Input.nColumn+1) then
                            if X>Input.nRow then /*{System.show 'checkPositions -> final free'#CurrentFree}*/ NewNbStarts=CurrentFree OldMap
                            elseif  X==Input.nRow then {CheckPositions X+1 1 OldMap CurrentFree}
                            else {CheckPositions X+1 0 OldMap CurrentFree} end
                        else 
                            if {IsImpossibleSlot X Y OldMap} then
                                NewFree NewMap={DeduceStartPoint X Y Path OldMap NewFree CurrentFree} in
                                %{System.show 'checkPositions -> update'#NewFree#CurrentFree}
                                {CheckPositions X Y+1 NewMap NewFree}
                            else {CheckPositions X Y+1 OldMap CurrentFree} end
                        end
                    end
                in
                    {CheckPositions 0 1 Map OldNbStarts}
            end
            proc {SweepPrintRow Rows}
                proc{SweepPrintCols Cols}
                    {System.show Cols}
                end
                in
                case Rows
                of R|Rs then {SweepPrintCols R} {SweepPrintRow Rs}
                else skip end
            end
            fun {SearchPlayer I L}
                case L
                of H|T then 
                    if I==ID then 
                        NewNbStarts in
                        if H.alive andthen H.nbStarts > 1 then
                            Tmp = {UpdateOtherMap H.map Dir|H.path NewNbStarts H.nbStarts} in 
                            if NewNbStarts < 2 then {System.show '===== player found '#I#' ====='} {SweepPrintRow Tmp} end
                            other(alive:H.alive path:Dir|H.path map:Tmp nbStarts:NewNbStarts)|T
                        else H|T end
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
            if {IsFreeSlot X Y Input.map} then {NbStartPoints X Y+1 Acc+1}
            else {NbStartPoints X Y+1 Acc} end
        end
    end

    fun {IsFreeSlot X Y M}
            fun {Get N M}
                case M
                of H|T then
                    if N<1 then indexOutOfBound                  
                    elseif N==1 then H
                    else {Get N-1 T} end
                else indexOutOfBound end
            end
            Row 
            Slot
        in
            Row = {Get X M}
            if Row==indexOutOfBound then {System.show indexOutOfBound} false
            else 
                Slot = {Get Y Row}
                if Slot==indexOutOfBound then {System.show indexOutOfBound} false
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
            case H
            of initPosition(I NewPos) then
                I = {GetID ID Player}
                NewPos={InitPosition}
                {TreatStream T ID player(pos:NewPos map:Input.map state:Player.state health:Player.health) Items Others}
            [] move(I NewPos Dir) then
                NewMap NewState
            in
                move(pos:NewPos dir:Dir map:NewMap) = {Move Player.pos Player.map Player.state}

                I = {GetID ID Player}
                if Dir == surface then NewState=surface
                else NewState=diving end

                {TreatStream T ID player(pos:NewPos map:NewMap state:NewState health:Player.health) Items Others}
            [] dive then 
                NewMap NewState
            in
                dive(m:NewMap s:NewState) = {Dive Player.map Player.state}
                {TreatStream T ID player(pos:Player.pos map:NewMap state:NewState health:Player.health) Items Others}
            [] chargeItem(I KindItem) then 
                I = {GetID ID Player}
                {TreatStream T ID Player items(charging:{ChargeItem Items.charging KindItem} placed:Items.placed) Others}
            [] fireItem(I KindFire) then 
                NewChargingItems in
                NewChargingItems = {FireItem Items.charging Player.pos KindFire Others}
                I = {GetID ID Player}
                {System.show '===== fireItem '#KindFire#' =====' }
                case KindFire 
                of mine(_) then {TreatStream ID T Player items(charging:NewChargingItems placed:KindFire|Items.placed) Others}
                else {TreatStream T ID Player items(charging:NewChargingItems placed:Items.placed) Others} end             
            [] fireMine(I Mine) then 
                NewPlacedItems = {FireMine Items.placed Mine}
            in
                I = {GetID ID Player}
                {TreatStream T ID Player items(charging:Items.charging placed:NewPlacedItems) Others}
            [] isDead(Answer) then 
                Answer = {IsDead Player.health}
                {TreatStream T ID Player Items Others}
            [] sayMove(I Dir) then 
                NewOthers = {UpdateDirections I.id Dir Others} in
                {System.show overkill#H}
                {System.show '===== new others ====='}
                for Other in NewOthers do
                    {System.show 'Other is alive '#Other.alive}
                    {System.show 'Other nb starts '#Other.nbStarts}
                end
                {System.show '===== new others ====='}
                {TreatStream T ID Player Items NewOthers}
            [] saySurface(I) then 
                {TreatStream T ID Player Items {UpdateDirections I surface Others}}
            [] sayCharge(I KindItem) then
                {TreatStream T ID Player Items Others}
            [] sayMinePlaced(I) then 
                {TreatStream T ID Player Items Others}
            [] sayMissileExplode(I Pos Msg) then
                Msg = {MissileExploded Pos ID Player}
                if I==ID andthen {ManhattanDistance Player.pos Pos} < 2 then {System.show '====== RIP : self damage ======'} end
                case Msg
                of sayDamageTaken(_ _ L) then {TreatStream T ID player(pos:Player.pos map:Player.map state:Player.state health:L) Items Others}
                [] null then {TreatStream T ID Player Items Others}
                else {TreatStream T ID player(pos:Player.pos map:Player.map state:Player.state health:0) Items Others} end
            [] sayMineExplode(I Pos Msg) then 
                Msg = {MineExploded Pos ID Player I}
                if I==ID andthen {ManhattanDistance Player.pos Pos} < 2 then {System.show '====== RIP : self damage ======'} end
                case Msg
                of sayDamageTaken(_ _ L) then {TreatStream T ID player(pos:Player.pos map:Player.map state:Player.state health:L) Items Others}
                [] null then {TreatStream T ID Player Items Others}
                else {TreatStream ID T player(pos:Player.pos map:Player.map state:Player.state health:0) Items Others} end
            [] sayPassingDrone(Drone I Answer) then 
                I = {GetID ID Player}
                Answer = {PassingDrone Drone Player}
                {TreatStream T ID Player Items Others}
            [] sayAnswerDrone(Drone I Answer) then 
                % To be implemented
                {TreatStream T ID Player Items Others}
            [] sayPassingSonar(I Answer) then
                I = {GetID ID Player}
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
            else {System.show error(where:'player -> TreatStream' who:ID what:H)} {TreatStream T ID Player Items Others} end
        else {TreatStream Stream ID Player Items Others} end
    end

    fun{StartPlayer Color ID}
            Stream
            Port
        in
            {NewPort Stream Port}
            thread
                {TreatStream Stream 
                            id(id:ID color:Color name:'Overkill')
                            player(pos:_ map:Input.map state:diving health:Input.maxDamage) 
                            items(charging:[missile#0 mine#0 drone#0 sonar#0] placed:nil) 
                            {InitOthers 1 nil {NbStartPoints 1 1 0}}
                            }
            end
            Port
    end
end


% TODO
% - Quadrillé map avec mines : à faire exploser quand un jouer est proche
% - Ne pas lancé missile si pas sûr
% - Améliorer mouvement aléatoire