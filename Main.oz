functor
import
    GUI
    Input
    PlayerManager
    System
define
    GUIPort = {GUI.portWindow} % Starting the GUI port window
    PlayerList
    PlayerDeadList
    Nth
    PlayerListGen
    SurfaceListGen
    SurfaceListModif
    NextId
    AllDead
    BroadcastMessage
    MessageHandling
    GameTurnByTurn
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
            P = {PlayerManager.playerGenerator {Nth Input.players I} {Nth Input.colors I} I}
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

    fun{NextId ID}
        A = (ID + 1) mod Input.nbPlayer
        R
        in
        if A == 0 then R = Input.nbPlayer
        else R = A
        end

        if {Nth PlayerDeadList R} == ~1 then {NextId R} % checking if the player is dead
        else R % the player is alive and can play
        end

    end

    fun {AllDead L}
        case L
        of nil then true
        [] H|T then
            if H == 0 then false
            else {AllDead T}
            end
        else true
        end
    end

    proc{BroadcastMessage M} % broadcast a message to all players
        % TODO : maybe use a thread to be sure that Send does not block
        thread 
            for J in 1..Input.nbPlayer do
                {Send {Nth PlayerList J} M}
            end
        end
    end

    proc{MessageHandling M}
        case M
        of sayDeath(I) then
            {Send GUIPort removePlayer(I)}
            PlayerDeadList = {SurfaceListModif PlayerDeadList I 1 1}
        else skip
        end

        {BroadcastMessage M} % in all cases (death or damageTaken, the message is broadcasted to all players)
    end

    proc{GameTurnByTurn Step CurrentId Surface} % similar to a stream in the way it works
        case Step % correspond aux steps du pdf de projet (parfois il y a plusieur steps en 1 c'est pr ça que je saute certains chiffres)
        of endTurn then % end of turn
            {System.show playerTurnOver#CurrentId}
            if {AllDead PlayerDeadList} then skip % if all players are dead then the procedure is over
            else 
                %{System.show Surface#atEndTurn} 
                {GameTurnByTurn step1 {NextId CurrentId} Surface}
            end
        [] H then
            case H
            of step1 then % checks if the submarine is at the surface
                {System.show step1#CurrentId}
                if {Nth Surface CurrentId} == 0 then % it is the firt turn / the submarine has finished waiting and is granted the permission to dive
                    {Send {Nth PlayerList CurrentId} dive}
                    {GameTurnByTurn endTurn CurrentId {SurfaceListModif Surface CurrentId 1 1}} % the CurrentId element of surface is -1
                elseif {Nth Surface CurrentId} > 0 then % the submarine is at the surface and still has to wait
                    {GameTurnByTurn endTurn CurrentId {SurfaceListModif Surface CurrentId 3 1}}
                else {GameTurnByTurn step3 CurrentId Surface} %the submarine is underwater (Surface == -1) and can carry on with his turn
                end
            [] step3 then %asks the submarine to choose his directions
                I P D % id, new position and direction
                in
                {System.show step3#CurrentId}
                %{System.show CurrentId#atStep3}
                {Send {Nth PlayerList CurrentId} move(I P D)}
                %{Delay 5000}
                %{System.show move(I P D)#CurrentId}
                case D
                of surface then
                    {Send GUIPort surface(I)}
                    {BroadcastMessage saySurface(I)}
                    %{System.show {SurfaceListModif Surface CurrentId 2 1}}
                    {GameTurnByTurn endTurn CurrentId {SurfaceListModif Surface CurrentId 2 1}} % the turn is over and counts as the first turn spend at the surface
                else % north east south west
                    {Send GUIPort movePlayer(I P)}
                    {BroadcastMessage sayMove(I P)}
                    %{System.show Surface}
                    {GameTurnByTurn step6 CurrentId Surface}
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
                  {BroadcastMessage sayCharge(I K)}
                end
                {GameTurnByTurn step7 CurrentId Surface}
            [] step7 then % the submarine is authorised to fire an item
                I K % id, kindFire, P in all the below: Position/Row/Column
                in
                {System.show step7#CurrentId}
                {Send  {Nth PlayerList CurrentId} fireItem(I K)}
                case K
                of mine(1:P) then
                    {Send GUIPort putMine(I P)}
                    {BroadcastMessage sayMinePlaced(I)}
                [] missile(1:P) then
                    %{Send GUIPort explosion(CurrentId P)} not mandatory
                    for J in 1..Input.nbPlayer do
                        Msg % Message
                        in
                        {Send {Nth PlayerList J} sayMissileExplode(I P Msg)}
                        {MessageHandling Msg}
                    end
                [] drone(row:P) then
                    for J in 1..Input.nbPlayer do
                        IdPlayer Ans % Id, Answer
                        in
                        %{Send GUIPort drone(CurrentId drone(row:P))} % not mandatory
                        {Send {Nth PlayerList J} sayPassingDrone(drone(row:P) IdPlayer Ans)}
                        {Send {Nth PlayerList CurrentId} sayAnswerDrone(drone(row:P) IdPlayer Ans)}
                    end
                [] drone(column:P) then
                    for J in 1..Input.nbPlayer do
                        IdPlayer Ans % Id, Answer
                        in
                        %{Send GUIPort drone(CurrentId drone(column:P))} % not mandatory
                        {Send {Nth PlayerList J} sayPassingDrone(drone(column:P) IdPlayer Ans)}
                        {Send {Nth PlayerList CurrentId} sayAnswerDrone(drone(column:P) IdPlayer Ans)}
                    end
                [] sonar then
                    for J in 1..Input.nbPlayer do
                        IdPlayer Ans % Id, Answer
                        in
                        %{Send GUIPort sonar(CurrentId)} % not mandatory
                        {Send {Nth PlayerList J} sayPassingSonar(IdPlayer Ans)}
                        {Send {Nth PlayerList CurrentId} sayAnswerSonar(IdPlayer Ans)}
                    end
                else % K== null no item was fired
                    skip
                end
                {GameTurnByTurn step8 CurrentId Surface}

            []step8 then
                I M % Id, Mine
                in
                {System.show step8#CurrentId}
                {Send {Nth PlayerList CurrentId} fireMine(I M)}
                case M
                of mine(P) then
                    {Send GUIPort removeMine(I P)}
                    %{Send GUIPort explosion(CurrentId P)} not mandatory
                    for J in 1..Input.nbPlayer do
                        Mes % Message
                        in
                        {Send {Nth PlayerList J} sayMineExplode(I P Mes)}
                        {MessageHandling Mes}
                    end
                else % Mine = null, the player didn't detonated one of his mines
                    skip
                end
                {GameTurnByTurn endTurn CurrentId Surface}
            else {System.show gameStepError#H}
            end
        else {System.show gameStepError}
        end
    end

    proc {GameSimultaneous PlayerList}
      skip
    end

    fun {Main}
        PlayerList = {PlayerListGen 1 nil}
        PlayerDeadList = {SurfaceListGen 1 nil}

        {Send GUIPort buildWindow}

        for P in PlayerList do % the players choose their position & appear on the grid
            Id Pos
        in
            {Send P initPosition(Id Pos)}
            {Send GUIPort initPlayer(Id Pos)}
        end

        if Input.isTurnByTurn then {GameTurnByTurn step1 1 {SurfaceListGen 1 nil}}
        else {GameSimultaneous PlayerList}
        end

        /*{Delay 5000}
        {System.show sending}
        for I in 1..64 do
            X Y Z MyPlayer = {Nth PlayerList 2}
        in
            {Send {Nth PlayerList 2} move(X Y Z)}
            {Browser.browse move(I)#X#Y#Z}
            {Delay 128}
            if Z==surface then {Send GUIPort surface(X)}
            else skip end
            {Send GUIPort movePlayer(X Y)}
            {Delay 128}
        end*/

        finished
    end

    {System.show {Main}}
end
