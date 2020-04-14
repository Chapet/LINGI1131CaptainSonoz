functor
import
	PlayerBasicAI
	Player
	System
	%Player1
	%Player2
export
	playerGenerator:PlayerGenerator
define
	PlayerGenerator
in
	fun{PlayerGenerator Kind Color ID}
		case Kind
		of player2 then {Player.portPlayer Color ID}
		[] player1 then {Player.portPlayer Color ID}
		else playerNotMatching
		end
	end
end
