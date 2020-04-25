functor
import
    GUI
    Input
    PlayerManager
    System
    Browser
    OS
define
    GUIPort = {GUI.portWindow} % Starting the GUI port window
    SimulPort
    PlayerList
    Nth
    PlayerListGen
    ExplosionHandling
    SurfaceListGen
    SurfaceListModif
    NextId
    SimulateThinking
    LastSurvivor
    BroadcastMessage
    MessageHandling
    GameTurnByTurn
    SimulGaming
    GameSimultaneous
    Main
in
    fun {Nth L N}
      case L
      of H|T then
          if N==1 then H
          else {Nth T N-1} end
      else nil end
    end

    fun {PlayerListGen I A}
        if I>Input.nbPlayer then A
        else
            P = {PlayerManager.playerGenerator {Nth Input.players Input.nbPlayer+1-I} {Nth Input.colors Input.nbPlayer+1-I} Input.nbPlayer+1-I}
            in
            {PlayerListGen I+1 P|A}
        end
    end

    fun {SurfaceListGen I A}
        if I>Input.nbPlayer then A
        else
            P = 0
        in
            {SurfaceListGen I+1 P|A}
        end
    end

    fun {SurfaceListModif L Id M C} % List, ID, Modif (1 = -1, 2 = Input.turnSurface-1), Current
        case {Nth L C}
        of nil then nil
        else
            if(C == Id) then
                case M
                of 1 then ~1|{SurfaceListModif L Id M C+1}
                [] 2 then Input.turnSurface-1|{SurfaceListModif L Id M C+1}
                [] 3 then  {Nth L C}-1|{SurfaceListModif L Id M C+1}
                else error
                end
            else {Nth L C}|{SurfaceListModif L Id M C+1}
            end
        end
    end

    fun {NextId ID PlayerDeadList}
        A = (ID + 1) mod Input.nbPlayer
        R
        in
        if A == 0 then R = Input.nbPlayer
        else R = A
        end

        if {Nth PlayerDeadList R} == ~1 then {NextId R PlayerDeadList} % checking if the player is dead
        else R % the player is alive and can play
        end

    end

    proc {SimulateThinking}
        Wait = ({OS.rand} mod (Input.thinkMin - Input.thinkMax)) + Input.thinkMin
        in
        {Delay Wait}
    end

    fun {LastSurvivor L}
            fun {Sum L A}
                case L
                of H|T then {Sum T A+H}
                else A end
            end
            N
        in
            N = {Sum L 0}
            (N + Input.nbPlayer) =< 1
    end

    proc {BroadcastMessage M PlayerDeadList} % broadcast a message to all players
        % TODO : maybe use a thread to be sure that Send does not block
        % thread
            for J in 1..Input.nbPlayer do
                if  {Nth PlayerDeadList J} \= ~1 then
                    {Send {Nth PlayerList J} M}
                else skip end
            end
        % end
    end

    fun {MessageHandling M PlayerDeadList}
        {BroadcastMessage M PlayerDeadList} % in all cases (death or damageTaken, the message is broadcasted to all players)
        case M
        of sayDeath(I) then
            {Send GUIPort removePlayer(I)}
            {SurfaceListModif PlayerDeadList I.id 1 1}
        [] sayDamageTaken(I _ Life) then
            {Send GUIPort lifeUpdate(I Life)}
            PlayerDeadList
        else
            PlayerDeadList
        end
    end

    fun {ExplosionHandling Kind PlayerDeadList I AttackerID Position}
            Mes
        in
            if I>Input.nbPlayer then PlayerDeadList
            else
                case Kind
                of mine then
                    {Send {Nth PlayerList I} sayMineExplode(AttackerID Position Mes)}
                    {ExplosionHandling Kind {MessageHandling Mes PlayerDeadList} I+1 AttackerID Position}
                else  % missile
                    {Send {Nth PlayerList I} sayMissileExplode(AttackerID Position Mes)}
                    {ExplosionHandling Kind {MessageHandling Mes PlayerDeadList} I+1 AttackerID Position}
                end
            end
    end

    proc {GameTurnByTurn Step CurrentId Surface PlayerDeadList} % similar to a stream in the way it works
        if {LastSurvivor PlayerDeadList} then {System.show onePlayerRemaining}
        else
            if {Nth PlayerDeadList CurrentId} == ~1 then {GameTurnByTurn step1 {NextId CurrentId PlayerDeadList} Surface PlayerDeadList} % if the player is dead we go to the next one
            else
                case Step
                of endTurn then % end of turn
                    {System.show playerTurnOver#CurrentId}
                    if {LastSurvivor PlayerDeadList} then
                        {System.show onePlayerRemaining} % if all players are dead then the procedure is over
                    else
                        {GameTurnByTurn step1 {NextId CurrentId PlayerDeadList} Surface PlayerDeadList}
                    end
                [] H then
                    case H
                    of step1 then % checks if the submarine is at the surface
                        if {Nth Surface CurrentId} == 0 then % it is the firt turn / the submarine has finished waiting and is granted the permission to dive
                            {Send {Nth PlayerList CurrentId} dive}
                            {GameTurnByTurn endTurn CurrentId {SurfaceListModif Surface CurrentId 1 1} PlayerDeadList} % the CurrentId element of surface is -1
                        elseif {Nth Surface CurrentId} > 0 then % the submarine is at the surface and still has to wait
                            {GameTurnByTurn endTurn CurrentId {SurfaceListModif Surface CurrentId 3 1} PlayerDeadList}
                        else {GameTurnByTurn step3 CurrentId Surface PlayerDeadList} %the submarine is underwater (Surface == -1) and can carry on with his turn
                        end
                    [] step3 then %asks the submarine to choose his directions
                        I P D % id, new position and direction
                        in
                        {Send {Nth PlayerList CurrentId} move(I P D)}
                        case D
                        of surface then
                            {Send GUIPort surface(I)}
                            {BroadcastMessage saySurface(I) PlayerDeadList}
                            {GameTurnByTurn endTurn CurrentId {SurfaceListModif Surface CurrentId 2 1} PlayerDeadList} % the turn is over and counts as the first turn spend at the surface
                        else % north east south west
                            {Send GUIPort movePlayer(I P)}
                            {BroadcastMessage sayMove(I D) PlayerDeadList}
                            {GameTurnByTurn step6 CurrentId Surface PlayerDeadList}
                        end
                    [] step6 then % the submarine is authorised to charge an item
                        I K % id, kindItem
                        in
                        %{System.show heyStep6Here#CurrentId}
                        {Send  {Nth PlayerList CurrentId} chargeItem(I K)}
                        case K
                        of null then skip % no item was produced so there is no radio broadcast
                        else % an item reached the amount of load(s) necessary to be produced
                          {BroadcastMessage sayCharge(I K) PlayerDeadList}
                        end
                        {GameTurnByTurn step7 CurrentId Surface PlayerDeadList}
                    [] step7 then % the submarine is authorised to fire an item
                        I K NewPlayerDeadList % id, kindFire, P in all the below: Position/Row/Column
                        in
                        {Send  {Nth PlayerList CurrentId} fireItem(I K)}
                        case K
                        of mine(1:P) then
                            {Send GUIPort putMine(I P)}
                            {BroadcastMessage sayMinePlaced(I) PlayerDeadList}
                            NewPlayerDeadList = PlayerDeadList
                        [] missile(1:P) then
                            {Send GUIPort explosion(I P)} %not mandatory
                            NewPlayerDeadList = {ExplosionHandling missile PlayerDeadList 1 I P}
                        [] drone(row P) then
                            for J in 1..Input.nbPlayer do
                                IdPlayer Ans % Id, Answer
                                in
                                {Send {Nth PlayerList J} sayPassingDrone(drone(row P) IdPlayer Ans)}
                                {Send {Nth PlayerList CurrentId} sayAnswerDrone(drone(row P) IdPlayer Ans)}
                            end
                            {Send GUIPort drone(I drone(row P))}
                            NewPlayerDeadList = PlayerDeadList
                        [] drone(column P) then
                            for J in 1..Input.nbPlayer do
                                IdPlayer Ans % Id, Answer
                                in
                                {Send {Nth PlayerList J} sayPassingDrone(drone(column P) IdPlayer Ans)}
                                {Send {Nth PlayerList CurrentId} sayAnswerDrone(drone(column P) IdPlayer Ans)}
                            end
                            {Send GUIPort drone(I drone(column P))}
                            NewPlayerDeadList = PlayerDeadList
                        [] sonar then
                            for J in 1..Input.nbPlayer do
                                IdPlayer Ans % Id, Answer
                                in
                                {Send {Nth PlayerList J} sayPassingSonar(IdPlayer Ans)}
                                {Send {Nth PlayerList CurrentId} sayAnswerSonar(IdPlayer Ans)}
                            end
                            {Send GUIPort sonar(I)}
                            NewPlayerDeadList = PlayerDeadList
                        else % K== null no item was fired
                            NewPlayerDeadList = PlayerDeadList
                        end
                        {GameTurnByTurn step8 CurrentId Surface NewPlayerDeadList}

                    []step8 then
                        I M NewPlayerDeadList % Id, Mine
                        in
                        {Send {Nth PlayerList CurrentId} fireMine(I M)}
                        case M
                        of mine(P) then
                            {Send GUIPort removeMine(I P)}
                            {Send GUIPort explosion(I P)} %not mandatory
                            NewPlayerDeadList = {ExplosionHandling mine PlayerDeadList 1 I P}
                        else % Mine = null, the player didn't detonated one of his mines
                            NewPlayerDeadList = PlayerDeadList
                        end
                        {GameTurnByTurn endTurn CurrentId Surface NewPlayerDeadList}
                    else {System.show gameStepError#H}
                    end
                else {System.show gameStepError}
                end
            end
        end
    end

    proc {SimulGaming Step CurrentId Surface} % CurrentId constant, Surface is just a number not an array and Dead is a boolean
        PlayerDeadList
        AmIDead
        in
        {SimulateThinking}
        {Send {Nth PlayerList CurrentId} isDead(AmIDead)}
        {Send SimulPort AmIDead#CurrentId}
        {Send SimulPort pdl#PlayerDeadList}
        if {LastSurvivor PlayerDeadList} then
            {System.show lastSurvivor#CurrentId}
            {Send SimulPort nil}
        elseif {Nth PlayerDeadList CurrentId} == ~1 then
            {System.show thisIsTheEndForMe#CurrentId}
        else
            case Step
            of H then
                case H
                of step1 then % checks if the submarines are at the surface
                    {System.show step1#CurrentId}
                    if Surface == 0 then % it is the firt turn / the submarine has finished waiting and is granted the permission to dive
                        {Send {Nth PlayerList CurrentId} dive}
                        {SimulGaming step3 CurrentId ~1}
                    elseif Surface > 0 then % the submarine is at the surface and still has to wait
                        {Delay Surface*1000} %waiting at the surface
                        {SimulGaming step1 CurrentId 0}
                    else {SimulGaming step3 CurrentId Surface} %the submarine is underwater (Surface == -1) and can carry on with his turn
                    end
                [] step3 then %asks the submarine to choose his directions
                    I P D % id, new position and direction
                    in
                    {System.show step3#CurrentId}
                    {Send {Nth PlayerList CurrentId} move(I P D)}
                    case D
                    of surface then
                        {System.show surface#I}
                        {Send GUIPort surface(I)}
                        {BroadcastMessage saySurface(I) PlayerDeadList}
                        {SimulGaming step1 CurrentId Input.turnSurface} % the turn is over and counts as the first turn spend at the surface
                    else % north east south west
                        {Send GUIPort movePlayer(I P)}
                        {BroadcastMessage sayMove(I P) PlayerDeadList}
                        {SimulGaming step6 CurrentId Surface}
                    end
                [] step6 then % the submarine is authorised to charge an item
                    I K % id, kindItem
                    in
                    {System.show step6#CurrentId}
                    %{System.show heyStep6Here#CurrentId}
                    {Send  {Nth PlayerList CurrentId} chargeItem(I K)}
                    case K
                    of null then skip % no item was produced so there is no radio broadcast
                    else % an item reached the amount of load(s) necessary to be produced
                        {BroadcastMessage sayCharge(I K) PlayerDeadList}
                    end
                    {SimulGaming step7 CurrentId Surface}
                [] step7 then % the submarine is authorised to fire an item
                    I K NewPlayerDeadList % id, kindFire, P in all the below: Position/Row/Column
                    in
                    {System.show step7#CurrentId}
                    {Send  {Nth PlayerList CurrentId} fireItem(I K)}
                    case K
                    of mine(1:P) then
                        {Send GUIPort putMine(I P)}
                        {BroadcastMessage sayMinePlaced(I) PlayerDeadList}
                        NewPlayerDeadList = PlayerDeadList
                    [] missile(1:P) then
                        {Send GUIPort explosion(I P)} %not mandatory
                        {System.show explosionHandling#missile#before}
                        NewPlayerDeadList = {ExplosionHandling missile PlayerDeadList 1 I P}
                        {System.show explosionHandling#missile#after}
                    [] drone(row P) then
                        for J in 1..Input.nbPlayer do
                            IdPlayer Ans % Id, Answer
                            in
                            {Send {Nth PlayerList J} sayPassingDrone(drone(row P) IdPlayer Ans)}
                            {Send {Nth PlayerList CurrentId} sayAnswerDrone(drone(row P) IdPlayer Ans)}
                        end
                        {Send GUIPort drone(I drone(row P))}
                        NewPlayerDeadList = PlayerDeadList
                    [] drone(column P) then
                        for J in 1..Input.nbPlayer do
                            IdPlayer Ans % Id, Answer
                            in
                            {Send {Nth PlayerList J} sayPassingDrone(drone(column P) IdPlayer Ans)}
                            {Send {Nth PlayerList CurrentId} sayAnswerDrone(drone(column P) IdPlayer Ans)}
                        end
                        {Send GUIPort drone(I drone(column P))}
                        NewPlayerDeadList = PlayerDeadList
                    [] sonar then
                        for J in 1..Input.nbPlayer do
                            IdPlayer Ans % Id, Answer
                            in
                            {Send {Nth PlayerList J} sayPassingSonar(IdPlayer Ans)}
                            {Send {Nth PlayerList CurrentId} sayAnswerSonar(IdPlayer Ans)}
                        end
                        {Send GUIPort sonar(I)} % not mandatory
                        NewPlayerDeadList = PlayerDeadList
                    else % K== null no item was fired
                        NewPlayerDeadList = PlayerDeadList
                    end
                    {SimulGaming step8 CurrentId Surface}
                []step8 then
                    I M NewPlayerDeadList % Id, Mine
                    in
                    {System.show step8#CurrentId}
                    {System.show PlayerDeadList}
                    {Send {Nth PlayerList CurrentId} fireMine(I M)}
                    case M
                    of mine(P) then
                        {Send GUIPort removeMine(I P)}
                        {Send GUIPort explosion(I P)}
                        {System.show explosionHandling#mine#before}
                        NewPlayerDeadList = {ExplosionHandling mine PlayerDeadList 1 I P}
                        {System.show explosionHandling#mine#after}
                    else % Mine = null, the player didn't detonated one of his mines<''
                        NewPlayerDeadList = PlayerDeadList
                    end
                    {SimulGaming step1 CurrentId Surface}
                else {System.show gameStepError#H}
                end
            else {System.show gameStepError}
            end
        end
    end

    proc {GameSimultaneous Stream PlayerDeadList}
        {System.show simulStreamIn#Stream}
        case Stream
        of  H|T then
            {System.show H}
            case H
            of false#_ then
                {GameSimultaneous T PlayerDeadList}
            [] true#I then
                {GameSimultaneous T {SurfaceListModif PlayerDeadList I 1 1}}
            [] pdl#K then
                K = PlayerDeadList
                {GameSimultaneous T PlayerDeadList}
            else % nil
                {System.show gameSimulOver}
            end
        else
            {GameSimultaneous Stream PlayerDeadList}
        end
    end

    proc {Main}
        {System.show beginning}

        PlayerList = {PlayerListGen 1 nil}

        {System.show PlayerList}

        {Send GUIPort buildWindow}

        for P in PlayerList do % the players choose their position & appear on the grid
            Id Pos
        in
            {Send P initPosition(Id Pos)}
            {Browser.browse 'initPosition'#Id#Pos}
            {Send GUIPort initPlayer(Id Pos)}
        end

        if Input.isTurnByTurn then
            {GameTurnByTurn step1 1 {SurfaceListGen 1 nil} {SurfaceListGen 1 nil}}
        else
            SimulStream
            in
            SimulPort = {NewPort SimulStream}

            for N in 1..Input.nbPlayer do
                thread
                    {System.show launchingThread#N}
                    {SimulGaming step1 N 0}
                end
            end

            {System.show launchingMainThread}
            {GameSimultaneous SimulStream {SurfaceListGen 1 nil}}

            {System.show parallelFinished}
        end

        {System.show '======= Main finished ======='}
        for P in PlayerList do % the players choose their position & appear on the grid
            Answer
        in
            {Send P isDead(Answer)}
            if Answer then 
                ID Pos in
                {Send P initPosition(ID Pos)}
                {Browser.browse dead#ID}
            else 
                ID Pos in
                {Send P initPosition(ID Pos)}
                {Browser.browse winner#ID}
            end
        end
    end

    {Main}
end
