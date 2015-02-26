$:.unshift File.join(File.dirname(__FILE__), '..')
require 'test/unit'
require 'middleware/formatter'
require 'rack'

$xml_sample = '<?xml version=\'1.0\' standalone=\'yes\'?>
<items>
  <item>
    <firstname>Taco</firstname>
    <birthyear>1977</birthyear>
    <lastname>Osinga</lastname>
    <siblings>
      <sibling>Frank</sibling>
      <sibling>Rens</sibling>
      <sibling>Douwe Freerk</sibling>
    </siblings>
  </item>
  <item>
    <firstname>Chantal</firstname>
    <birthyear>1978</birthyear>
    <lastname>Osinga-Albers</lastname>
    <siblings>
    </siblings>
  </item>
  <item>
    <firstname>Hannah</firstname>
    <birthyear>2006</birthyear>
    <lastname>Osinga</lastname>
    <siblings>
      <sibling>Sara</sibling>
      <sibling>Ruben</sibling>
    </siblings>
  </item>
</items>
'

$json_sample = "[{\"firstname\":\"Taco\",\"birthyear\":1977,\"lastname\":\"Osinga\",\"siblings\":[\"Frank\",\"Rens\",\"Douwe Freerk\"]},{\"firstname\":\"Chantal\",\"birthyear\":1978,\"lastname\":\"Osinga-Albers\",\"siblings\":[]},{\"firstname\":\"Hannah\",\"birthyear\":2006,\"lastname\":\"Osinga\",\"siblings\":[\"Sara\",\"Ruben\"]}]"

$csv_sample = "firstname,birthyear,lastname,siblings
Taco,1977,Osinga,\"Frank, Rens, Douwe Freerk\"
Chantal,1978,Osinga-Albers,\"\"
Hannah,2006,Osinga,\"Sara, Ruben\"
"

module Mojura

	class FormatterTester < Test::Unit::TestCase

		# noinspection RubyStringKeysInHashInspection
		@@env = {
			'rack.version' => Rack::VERSION,
			'rack.input' => StringIO.new,
			'rack.errors' => StringIO.new,
			'rack.multithread' => true,
			'rack.multiprocess' => true,
			'rack.run_once' => false,
		}

		def get_sample
			return [{firstname: 'Taco', birthyear: 1977, lastname: 'Osinga', siblings: ['Frank', 'Rens', 'Douwe Freerk']},
			        {firstname: 'Chantal', birthyear: 1978, lastname: 'Osinga-Albers', siblings: []},
			        {firstname: 'Hannah', birthyear: 2006, lastname: 'Osinga', siblings: %w(Sara Ruben)}]
		end

		def test_to_json
			assert_equal($json_sample, Formatter.new(nil).to_json(self.get_sample))
		end

		def test_to_xml
			# assert_equal($xml_sample, Formatter.new(nil).to_xml(self.get_sample))
		end

		def test_to_csv
			assert_equal($csv_sample, Formatter.new(nil).to_csv(self.get_sample, @@env))
		end

		def test_to_vcard
		end

	end

end
