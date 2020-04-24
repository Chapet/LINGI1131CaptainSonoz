functor
import
	PlayerBasicAI
	Player064Overkill
	Player064Dumbest
	System
export
	playerGenerator:PlayerGenerator
define
	PlayerGenerator
in
	fun{PlayerGenerator Kind Color ID}
		case Kind
		of player1 then {Player064Dumbest.portPlayer Color ID}
		[] player2 then {Player064Overkill.portPlayer Color ID}
		[] player3 then {PlayerBasicAI.portPlayer Color ID}
		else playerNotMatching
		end
	end
end
