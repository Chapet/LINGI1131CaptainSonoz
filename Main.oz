functor
import
    GUI
    Input
    PlayerManager
    System
    Browser
define
    GUIPort = {GUI.portWindow} % Starting the GUI port window
    PlayerList
    Nth
    PlayerListGen
    Launch
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

    proc {Launch GameType}
        skip
    end

    fun {Main}
        PlayerList = {PlayerListGen 1 nil}

        {Send GUIPort buildWindow}

        for P in PlayerList do
            Id Pos
        in
            {Send P initPosition(Id Pos)}
            {Send GUIPort initPlayer(Id Pos)}
        end

        %{Launch Input.isTurnByTurn}

        {Delay 5000}
        {System.show sending}
        for I in 1..64 do
            X Y Z MyPlayer = {Nth PlayerList 2}
        in
            {Send MyPlayer move(X Y Z)}
            %{Browser.browse move(I)#X#Y#Z}
            if Z==surface then 
                {Send GUIPort surface(X)}
                {Send MyPlayer chargeItem()}
                {Delay 1024}
                {Send MyPlayer dive}
            else 
                {Send GUIPort movePlayer(X Y)} 
            end
        end

        finished
    end

    {System.show {Main}}
end

