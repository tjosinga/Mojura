module Screenplay

	class SigninActor < Actor

		attr_reader :users

		def configure(config)
			@users = config
		end

		def play(params, input)
			username = params[:as]
			password = @users[username.to_sym]
			salt_data = Cast.get(:api).play({ path: 'salt' }, {})
			realm = salt_data['realm']
			salt = salt_data['salt']
			digest = Digest::MD5.hexdigest("#{username}:#{realm}:#{password}").to_s
			iterations = 500 + (username + realm).length
			password = OpenSSL::PKCS5.pbkdf2_hmac_sha1(digest, salt, iterations, 64).unpack('H*')[0]
			return Cast.get(:api).play({ path: 'authenticate', data: {username: username, password: password} }, {})
		end

	end

end