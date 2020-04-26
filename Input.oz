functor
import
   OS
export
   isTurnByTurn:IsTurnByTurn
   nRow:NRow
   nColumn:NColumn
   map:Map
   nbPlayer:NbPlayer
   players:Players
   colors:Colors
   thinkMin:ThinkMin
   thinkMax:ThinkMax
   turnSurface:TurnSurface
   maxDamage:MaxDamage
   missile:Missile
   mine:Mine
   sonar:Sonar
   drone:Drone
   minDistanceMine:MinDistanceMine
   maxDistanceMine:MaxDistanceMine
   minDistanceMissile:MinDistanceMissile
   maxDistanceMissile:MaxDistanceMissile
   guiDelay:GUIDelay
define
   IsTurnByTurn
   NRow
   NColumn
   Map
   NbPlayer
   Players
   Colors
   ThinkMin
   ThinkMax
   TurnSurface
   MaxDamage
   Missile
   Mine
   Sonar
   Drone
   MinDistanceMine
   MaxDistanceMine
   MinDistanceMissile
   MaxDistanceMissile
   GUIDelay

   MapGenerator
   IslandCoefficient
   UseMapGenerator
   DefaultMap
in
   fun {MapGenerator}
         fun {WhichType}
               Rand = {OS.rand} mod 100
               Coeff
            in
               if IslandCoefficient<0 orelse IslandCoefficient>25 then Coeff=15
               else Coeff = IslandCoefficient end
               
               if Rand < Coeff then 1
               else 0 end
         end
         fun {LoopRow R}
            if R>NRow then nil
            else {LoopCol 1}|{LoopRow R+1} end
         end
         fun {LoopCol C}
            if C>NColumn then nil
            else {WhichType}|{LoopCol C+1} end
         end
      in
         if UseMapGenerator then {LoopRow 1}
         else DefaultMap end
   end

%%%% Style of game %%%%

   IsTurnByTurn = false

%%%% Description of the map %%%%

   NRow = 10
   NColumn = 10
   IslandCoefficient = 15 % Between 0 and 25
   UseMapGenerator = true % if false, make sure that NRow and NColumn match the default map

   DefaultMap = [[0 0 0 0 0 0 0 0 0 0]
                 [0 0 0 0 0 0 0 0 0 0]
                 [0 0 0 1 1 0 0 0 0 0]
                 [0 0 1 1 0 0 1 0 0 0]
                 [0 0 0 0 0 0 0 0 0 0]
                 [0 0 0 0 0 0 0 0 0 0]
                 [0 0 0 1 0 0 1 1 0 0]
                 [0 0 1 1 0 0 1 0 0 0]
                 [0 0 0 0 0 0 0 0 0 0]
                 [0 0 0 0 0 0 0 0 0 0]]

   Map = {MapGenerator}

%%%% Players description %%%%

   NbPlayer = 3
   Players = [player1 player2 player3]
   Colors = [yellow green red]

%%%% Thinking parameters (only in simultaneous) %%%%

   ThinkMin = 100
   ThinkMax = 300

%%%% Surface time/turns %%%%

   TurnSurface = 3

%%%% Life %%%%

   MaxDamage = 2

%%%% Number of load for each item %%%%

   Missile = 3
   Mine = 3
   Sonar = 3
   Drone = 3

%%%% Distances of placement %%%%

   MinDistanceMine = 1
   MaxDistanceMine = 2
   MinDistanceMissile = 1
   MaxDistanceMissile = 4

%%%% Waiting time for the GUI between each effect %%%%

   GUIDelay = 300 % ms

end
