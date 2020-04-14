functor
import
    GUI
    Input
    PlayerManager
    System
define
    GUIPort = {GUI.portWindow} % Starting the GUI port window
    PlayerList
    Nth
    PlayerListGen
    SurfaceListGen
    SurfaceListModif
    NextId
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
            case C
            of Id then
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
        A = (ID + 1) mod 4
        in
        if A == 0 then
            1
        else
            A
        end
    end

    proc{BroadcastMessage M} % broadcast a message to all players
        for J in 1::Input.nbPlayer do
            {Send {Nth PlayerList J} M}
        end
    end

    proc{MessageHandling M}
        I
        in
        case M
        of sayDeath(I) then {Send GUIPort removePlayer(I)}
        else skip
        end

        {BroadcastMessage M} % in all cases (death or damageTaken, the message is broadcasted to all players)
    end

    proc{GameTurnByTurn Step CurrentId Surface} %stream qui peut s'arrêter
        case Step % correspond aux steps du pdf de projet (parfois il y a plusieur steps en 1 c'est pr ça que je saute certains chiffres)
        of nil then
            {System.show playerTurnOver#CurrentId}
            {GameTurnByTurn step1 {NextId CurrentId} Surface} % end of turn
        [] H then
            case H
            of step1 then % checks if the submarine is at the surface
                if {Nth Surface CurrentId} == 0 then % it is the firt turn / the submarine has finished waiting and is granted the permission to dive
                    {Send {Nth PlayerList CurrentId} dive}
                    {GameTurnByTurn nil CurrentId {SurfaceListModif Surface CurrentId 1 1}} % the CurrentId element of surface is -1
                elseif {Nth Surface CurrentId} > 0 then % the submarine is at the surface and still has to wait
                    {GameTurnByTurn nil CurrentId {SurfaceListModif Surface CurrentId 3 1}}
                else {GameTurnByTurn step3 CurrentId Surface} %the submarine is underwater (Surface == -1) and can carry on with his turn
                end
            [] step3 then %asks the submarine to choose his directions
                I P D % id, new position and direction
                in
                {Send {Nth PlayerList CurrentId} move(I P D)}
                case D
                of surface then
                    {Send GUIPort surface(I)}
                    {BroadcastMessage saySurface(I)}
                    {GameTurnByTurn nil CurrentId {SurfaceListModif Surface CurrentId 2 1}} % the turn is over and counts as the first turn spend at the surface
                else % north east south west
                    {Send GUIPort movePlayer(I P)}
                    {BroadcastMessage sayMove(I P)}
                    {GameTurnByTurn step6 I Surface}
                end
            [] step6 then % the submarine is authorised to charge an item
                I K % id, kindItem
                in
                {Send  {Nth PlayerList I} chargeItem(I K)}
                case K
                of null then skip % no item was produced so there is no radio broadcast
                else % an item reached the amount of load(s) necessary to be produced
                  {BroadcastMessage sayCharge(I K)}
                end
                {GameTurnByTurn step7 I Surface}
            [] step7 then % the submarine is authorised to fire an item
                I K P % id, kindFire, Position/Row/Column
                in
                {Send  {Nth PlayerList I} fireItem(I K)}
                case K
                of mine(1:P) then
                    {Send GUIPort putMine(I P)}
                    {BroadcastMessage sayMinePlaced(I)}
                [] missile(1:P) then
                    %{Send GUIPort explosion(CurrentId P)} not mandatory
                    for J in 1::Input.nbPlayer do
                        Msg % Message
                        in
                        {Send {Nth PlayerList J} sayMissileExplode(I P Msg)}
                        {MessageHandling Msg}
                    end
                [] drone(row:P) then
                    for J in 1::Input.nbPlayer do
                        IdPlayer Ans % Id, Answer
                        in
                        %{Send GUIPort drone(CurrentId drone(row:P))} % not mandatory
                        {Send {Nth PlayerList J} sayPassingDrone(drone(row:P) IdPlayer Ans)}
                        {Send {Nth PlayerList I} sayAnswerDrone(drone(row:P) IdPlayer Ans)}
                    end
                [] drone(column:P) then
                    for J in 1::Input.nbPlayer do
                        IdPlayer Ans % Id, Answer
                        in
                        %{Send GUIPort drone(CurrentId drone(column:P))} % not mandatory
                        {Send {Nth PlayerList J} sayPassingDrone(drone(column:P) IdPlayer Ans)}
                        {Send {Nth PlayerList CurrentId} sayAnswerDrone(drone(column:P) IdPlayer Ans)}
                    end
                [] sonar then
                    for J in 1::Input.nbPlayer do
                        IdPlayer Ans % Id, Answer
                        in
                        %{Send GUIPort sonar(CurrentId)} % not mandatory
                        {Send {Nth PlayerList J} sayPassingSonar(IdPlayer Ans)}
                        {Send {Nth PlayerList CurrentId} sayAnswerSonar(IdPlayer Ans)}
                    end
                else % K== null no item was fired
                    skip
                end
                {GameTurnByTurn step8 I Surface}

            []step8 then
                I M % Id, Mine
                in
                {Send {Nth PlayerList I} fireMine(I M)}
                case M
                of mine(P) then
                    {Send GUIPort removeMine(I P)}
                    %{Send GUIPort explosion(CurrentId P)} not mandatory
                    for J in 1::Input.nbPlayer do
                        Mes % Message
                        in
                        {Send {Nth PlayerList J} sayMineExplode(I P Mes)}
                        {MessageHandling Mes}
                    end
                else % Mine = null, the player didn't detonated one of his mines
                    skip
                end
                {GameTurnByTurn nil I Surface}
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
