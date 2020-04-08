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

        {System.show sending}
        for I in 1..5 do
            X Y Z
        in
            {Delay 1000}
            {Send {Nth PlayerList 2} move(X Y Z)}
            {Browser.browse move(I)#X#Y#Z}
            {Delay 1000}
            {Send GUIPort movePlayer(X Y)}
        end


        finished
    end

    {System.show {Main}}
end
