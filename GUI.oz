functor
import
	QTk at 'x-oz://system/wp/QTk.ozf'
	Input
	System
export
	portWindow:StartWindow
define
	ExplosionImage = {QTk.newImage photo(file:'explosion.ppm')}
	DroneImage = {QTk.newImage photo(file:'drone.ppm')}
	SubmarineImage = {QTk.newImage photo(file:'submarine.ppm')}
	MineImage = {QTk.newImage photo(file:'mine.ppm')}

	StartWindow
	TreatStream

	RemoveItem
	RemovePath
	RemovePlayer

	Map = Input.map

	NRow = Input.nRow
	NColumn = Input.nColumn

	DrawSubmarine
	MoveSubmarine
	DrawMine
	RemoveMine
	DrawPath
	DrawExplosion
	DisplayDrone
	DisplaySonar

	BuildWindow

	Label
	Squares
	DrawMap

	StateModification

	UpdateLife
in

%%%%% Build the initial window and set it up (call only once)
	fun{BuildWindow}
		Grid GridScore SonarText Toolbar Desc DescScore Window
	in
		Toolbar=lr(glue:we tbbutton(text:"Quit" glue:w action:toplevel#close) label(handle:SonarText text:' ' glue:n))
		Desc=grid(handle:Grid height:500 width:500)
		DescScore=grid(handle:GridScore height:100 width:500)
		Window={QTk.build td(Toolbar Desc DescScore)}
		{Window show}

		% configure rows and set headers
		{Grid rowconfigure(1 minsize:50 weight:0 pad:5)}
		for N in 1..NRow do
			{Grid rowconfigure(N+1 minsize:50 weight:0 pad:5)}
			{Grid configure({Label N} row:N+1 column:1 sticky:wesn)}
		end
		% configure columns and set headers
		{Grid columnconfigure(1 minsize:50 weight:0 pad:5)}
		for N in 1..NColumn do
			{Grid columnconfigure(N+1 minsize:50 weight:0 pad:5)}
			{Grid configure({Label N} row:1 column:N+1 sticky:wesn)}
		end
		% configure scoreboard
		{GridScore rowconfigure(1 minsize:50 weight:0 pad:5)}
		for N in 1..(Input.nbPlayer) do
			{GridScore columnconfigure(N minsize:50 weight:0 pad:5)}
		end

		{DrawMap Grid}

		handle(grid:Grid score:GridScore sonar:SonarText)
	end

%%%%% Squares of water and island
	Squares = square(0:label(text:"" width:1 height:1 bg:c(102 102 255))
			 1:label(text:"" borderwidth:5 relief:raised width:1 height:1 bg:c(153 76 0))
			)

%%%%% Labels for rows and columns
	fun{Label V}
		label(text:V borderwidth:5 relief:raised bg:c(255 51 51) ipadx:5 ipady:5)
	end

%%%%% Function to draw the map
	proc{DrawMap Grid}
		proc{DrawColumn Column M N}
			case Column
			of nil then skip
			[] T|End then
				{Grid configure(Squares.T row:M+1 column:N+1 sticky:wesn)}
				{DrawColumn End M N+1}
			end
		end
		proc{DrawRow Row M}
			case Row
			of nil then skip
			[] T|End then
				{DrawColumn T M 1}
				{DrawRow End M+1}
			end
		end
	in
		{DrawRow Map 1}
	end

%%%%% Init the submarine
	fun{DrawSubmarine Grid ID Position}
		Handle HandlePath HandleScore X Y Id Color LabelSub LabelScore
	in
		pt(x:X y:Y) = Position
		id(id:Id color:Color name:_) = ID

		LabelSub = label(image:SubmarineImage handle:Handle borderwidth:5 relief:raised bg:Color ipadx:5 ipady:5)
		LabelScore = label(text:Input.maxDamage borderwidth:5 handle:HandleScore relief:solid bg:Color ipadx:5 ipady:5)
		HandlePath = {DrawPath Grid Color X Y}
		{Grid.grid configure(LabelSub row:X+1 column:Y+1 sticky:wesn)}
		{Grid.score configure(LabelScore row:1 column:Id sticky:wesn)}
		{HandlePath 'raise'()}
		{Handle 'raise'()}
		guiPlayer(id:ID score:HandleScore submarine:Handle mines:nil path:HandlePath|nil)
	end

	fun{MoveSubmarine Position}
		fun{$ Grid State}
			ID HandleScore Handle Mine Path NewPath X Y
		in
			guiPlayer(id:ID score:HandleScore submarine:Handle mines:Mine path:Path) = State
			pt(x:X y:Y) = Position
			NewPath = {DrawPath Grid ID.color X Y}
			{Grid.grid remove(Handle)}
			{Grid.grid configure(Handle row:X+1 column:Y+1 sticky:wesn)}
			{NewPath 'raise'()}
			{Handle 'raise'()}
			guiPlayer(id:ID score:HandleScore submarine:Handle mines:Mine path:NewPath|Path)
		end
	end

	fun{DrawMine Position}
		fun{$ Grid State}
			ID HandleScore Handle Mine Path LabelMine HandleMine X Y
			in
			guiPlayer(id:ID score:HandleScore submarine:Handle mines:Mine path:Path) = State
			pt(x:X y:Y) = Position
			LabelMine = label(image:MineImage handle:HandleMine borderwidth:5 relief:raised bg:ID.color ipadx:5 ipady:5)
			{Grid.grid configure(LabelMine row:X+1 column:Y+1)}
			{HandleMine 'raise'()}
			{Handle 'raise'()}
			guiPlayer(id:ID score:HandleScore submarine:Handle mines:mine(HandleMine Position)|Mine path:Path)
		end
	end

	local
		fun{RmMine Grid Position List}
			case List
			of nil then nil
			[] H|T then
				if (H.2 == Position) then
					{RemoveItem Grid H.1}
					T
				else
					H|{RmMine Grid Position T}
				end
			end
		end
	in
		fun{RemoveMine Position}
			fun{$ Grid State}
				ID HandleScore Handle Mine Path NewMine
				in
				guiPlayer(id:ID score:HandleScore submarine:Handle mines:Mine path:Path) = State
				NewMine = {RmMine Grid Position Mine}
				guiPlayer(id:ID score:HandleScore submarine:Handle mines:NewMine path:Path)
			end
		end
	end

	fun{DrawPath Grid Color X Y}
		Handle LabelPath
	in
		LabelPath = label(text:"" handle:Handle bg:Color)
		{Grid.grid configure(LabelPath row:X+1 column:Y+1)}
		Handle
	end

	proc {DrawExplosion Grid Position}
			X = Position.x Y = Position.y
			fun {IsFreeSlot X Y}
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
					Row = {Get X Input.map}
					if Row==indexOutOfBound then false
					else 
						Slot = {Get Y Row}
						if Slot==0 then true
						else false end
					end
			end
			fun {GenerateExplosions N}
				if N==0 then nil
				else
					Handle in
					label(image:ExplosionImage handle:Handle borderwidth:0 relief:raised bg:white ipadx:5 ipady:5)|{GenerateExplosions N-1}					
				end
			end
			proc {ShowExplosion E X Y}
				if {IsFreeSlot X-1 Y-1} then {Grid.grid configure(E row:X column:Y)} end
			end
			proc {ShowExplosions Explosions N}
				if N<1 then skip
				else
					case Explosions
					of E|Es then
						if N==5 then {ShowExplosion E X+1 Y+1} {RemoveExplosion E}
						elseif N==4 then {ShowExplosion E X Y+1} {RemoveExplosion E}
						elseif N==3 then {ShowExplosion E X+1 Y} {RemoveExplosion E}
						elseif N==2 then {ShowExplosion E X+2 Y+1} {RemoveExplosion E}
						else {ShowExplosion E X+1 Y+2} {RemoveExplosion E} end
						{ShowExplosions Es N-1}
					end
				end
			end
			proc {RemoveExplosion Explosion}
				thread {Delay Input.guiDelay} {RemoveItem Grid Explosion.handle} end
			end
			Explosion1 Explosion2 Explosion3 Explosion4 Explosion5 
			Explosions = [Explosion1 Explosion2 Explosion3 Explosion4 Explosion5]
			N = 5
		in
			Explosions = {GenerateExplosions N}
			{ShowExplosions Explosions N}
			{Delay Input.guiDelay}
	end

	proc {DisplayDrone Grid Drone}
		proc {Sweep IsRow Position Current Max}
			if Current > Max then skip
			else
				Handle in
				if IsRow then {Grid.grid configure(label(image:DroneImage handle:Handle borderwidth:2 relief:raised bg:c(255 255 255) ipadx:5 ipady:5) row:Position+1 column:Current+1)} 
				else {Grid.grid configure(label(image:DroneImage handle:Handle borderwidth:2 relief:raised bg:c(255 255 255) ipadx:5 ipady:5) row:Current+1 column:Position+1)} end
				thread {Delay Input.guiDelay} {RemoveItem Grid Handle} end
				{Sweep IsRow Position Current+1 Max}
			end
		end
		in
		case Drone
		of drone(row R) then {Sweep true R 1 Input.nColumn} {Delay Input.guiDelay}
		[] drone(column C) then {Sweep false C 1 Input.nRow} {Delay Input.guiDelay}
		else skip end
	end

	proc {DisplaySonar Grid ID}
		case ID
		of id(id:_ name:N color:C) then
			Handle in
			{Grid.sonar set('Sonar by '#N#' ('#C#')')}
			thread {Delay Input.guiDelay} {Grid.sonar set(' ')} end
		end
	end

	proc{RemoveItem Grid Handle}
		{Grid.grid forget(Handle)}
	end

	fun{RemovePath Grid State}
		ID HandleScore Handle Mine Path
	in
		guiPlayer(id:ID score:HandleScore submarine:Handle mines:Mine path:Path) = State
		for H in Path.2 do
	  		{RemoveItem Grid H}
		end
		guiPlayer(id:ID score:HandleScore submarine:Handle mines:Mine path:Path.1|nil)
	end

	fun{UpdateLife Life}
		fun{$ Grid State}
			HandleScore
			in
			guiPlayer(id:_ score:HandleScore submarine:_ mines:_ path:_) = State
			{HandleScore set(Life)}
	 		State
		end
	end

	fun{StateModification Grid WantedID State Fun}
		case State
		of nil then nil
		[] guiPlayer(id:ID score:_ submarine:_ mines:_ path:_)|Next then
			if (ID == WantedID) then
				{Fun Grid State.1}|Next
			else
				State.1|{StateModification Grid WantedID Next Fun}
			end
		end
	end

	fun{RemovePlayer Grid WantedID State}
		case State
		of nil then nil
		[] guiPlayer(id:ID score:HandleScore submarine:Handle mines:M path:P)|Next then
			if (ID == WantedID) then
				{HandleScore set(0)}
				for H in P do
			 		{RemoveItem Grid H}
				end
				for H in M do
			 		{RemoveItem Grid H.1}
				end
				{RemoveItem Grid Handle}
				Next
			else
				State.1|{RemovePlayer Grid WantedID Next}
			end
		end
	end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	fun{StartWindow}
		Stream
		Port
	in
		{NewPort Stream Port}
		thread
			{TreatStream Stream nil nil}
		end
		Port
	end

	proc{TreatStream Stream Grid State}
		case Stream
		of nil then skip
		[] buildWindow|T then NewGrid in
			NewGrid = {BuildWindow}
			{TreatStream T NewGrid State}
		[] initPlayer(ID Position)|T then NewState in
			%{System.show guiStream#ID#Position}
			NewState = {DrawSubmarine Grid ID Position}
			{TreatStream T Grid NewState|State}
		[] movePlayer(ID Position)|T then
			{TreatStream T Grid {StateModification Grid ID State {MoveSubmarine Position}}}
		[] lifeUpdate(ID Life)|T then
			{TreatStream T Grid {StateModification Grid ID State {UpdateLife Life}}}
			{TreatStream T Grid State}
		[] putMine(ID Position)|T then
			{TreatStream T Grid {StateModification Grid ID State {DrawMine Position}}}
		[] removeMine(ID Position)|T then
			{TreatStream T Grid {StateModification Grid ID State {RemoveMine Position}}}
		[] surface(ID)|T then
			{TreatStream T Grid {StateModification Grid ID State RemovePath}}
		[] removePlayer(ID)|T then
			{TreatStream T Grid {RemovePlayer Grid ID State}}
		[] explosion(ID Position)|T then
			{DrawExplosion Grid Position}
			{TreatStream T Grid State}
		[] drone(ID Drone)|T then
			{DisplayDrone Grid Drone}
			{TreatStream T Grid State}
		[] sonar(ID)|T then
			{DisplaySonar Grid ID}
			{TreatStream T Grid State}
		[] _|T then
			{TreatStream T Grid State}
		end
	end
end
