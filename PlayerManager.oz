functor
import
	PlayerBasicAI
	SimplestPlayer
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
		of player1 then {SimplestPlayer.portPlayer Color ID}
		[] player2 then {PlayerBasicAI.portPlayer Color ID}
		[] player3 then {PlayerBasicAI.portPlayer Color ID}
		else playerNotMatching
		end
	end
end
