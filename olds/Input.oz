functor
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
in

%%%% Style of game %%%%

   IsTurnByTurn = false

%%%% Description of the map %%%%

   NRow = 8%10
   NColumn = 8%10

   % Map = [[0 0 0 0 0 0 0 0 0 0]
   %    	  [0 0 0 0 0 0 0 0 0 0]
   %    	  [0 0 0 1 1 0 0 0 0 0]
   %    	  [0 0 1 1 0 0 1 0 0 0]
   %    	  [0 0 0 0 0 0 0 0 0 0]
   %    	  [0 0 0 0 0 0 0 0 0 0]
   %    	  [0 0 0 1 0 0 1 1 0 0]
   %    	  [0 0 1 1 0 0 1 0 0 0]
   %    	  [0 0 0 0 0 0 0 0 0 0]
   %    	  [0 0 0 0 0 0 0 0 0 0]]
   Map = [  [0 0 0 0 0 0 0 0]
            [0 0 1 1 0 0 0 0]
            [0 1 1 0 0 1 0 0]
            [0 0 0 0 0 0 0 0]
            [0 0 0 0 0 0 0 0]
            [0 0 1 0 0 1 1 0]
            [0 1 1 0 0 1 0 0]
            [0 0 0 0 0 0 0 0]]

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
