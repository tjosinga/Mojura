module Screenplay

	class SignoffActor < Actor

		def play(params, input)
			return Cast.get(:api).play({ path: 'signoff' }, {})
		end

	end

end