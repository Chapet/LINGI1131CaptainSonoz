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
            X Y
        in
            {Send P initPosition(X Y)}
            {Send GUIPort initPlayer(X Y)}
        end

        {Launch Input.isTurnByTurn}

        finished
    end

    {System.show {Main}}
end
