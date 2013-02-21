$:.unshift File.join(File.dirname(__FILE__), '..')
require 'test/unit'
require 'api/lib/validator'

module MojuraAPI

  class ValidatorTester < Test::Unit::TestCase

    def test_matches_regexp
      assert(Validator.matches_regexp('This is a test of the JavaScript RegExp object', /\bt[a-z]+\b/))
      assert(!Validator.matches_regexp('This is a test of the JavaScript RegExp object', /\bt[0-9]+\b/))
    end

    def test_is_required
      assert(Validator.is_required('test'))
      assert(Validator.is_required(0))
      assert(Validator.is_required(-1))
      assert(Validator.is_required(1))
      assert(Validator.is_required(0.000001))
      assert(Validator.is_required(1))
      assert(!Validator.is_required(nil))
    end

    def test_is_numeric
      assert(Validator.is_numeric('0'))
      assert(Validator.is_numeric('-12'))
      assert(Validator.is_numeric(12))
      assert(!Validator.is_numeric(1.2))
      assert(!Validator.is_numeric('1.2'))
      assert(!Validator.is_numeric('true'))
      assert(!Validator.is_numeric(true))
      assert(!Validator.is_numeric(nil))
      assert(!Validator.is_numeric({}))
      assert(!Validator.is_numeric([]))
    end

    def test_is_email
      # Source for (in)valid adresses: http://en.wikipedia.org/wiki/Email_address
      # Regular expression of mail doesn't get follow all rules, which are commented. Acceptable marge
      assert(Validator.is_email('niceandsimple@example.com'))
      assert(Validator.is_email('simplewith+symbol@example.com'))
      assert(Validator.is_email('less.common@example.com'))
      assert(Validator.is_email('a.little.more.unusual@dept.example.com'))
      # assert(Validator.is_email("'@[10.10.10.10]"))
      # assert(Validator.is_email("user@[IPv6:2001:db8:1ff::a0b:dbd0]"))
      # assert(Validator.is_email("\"much.more\ unusual\"@example.com"))
      # assert(Validator.is_email("\"very.unusual.@.unusual.com\"@example.com"))
      # assert(Validator.is_email("\"very.(),:;<>[]\\\".VERY.\\\"very@\\\\\\ \\\"very\\\".unusual\"@strange.example.com"))
      # assert(Validator.is_email("0@a"))
      # assert(Validator.is_email("!#\$%&'*+-/=?^_`{}|~@example.org"))
      # assert(Validator.is_email("\"()<>[]:,;@\\\"!#\$%&'*+-/=?^_`{}|\ \ ~\ \ \ ?\ \ \ ^_`{}|~.a\"@example.org"))
      # assert(Validator.is_email("\"\"@example.org"))
      # assert(Validator.is_email("postbox@com"))

      assert(!Validator.is_email('Abc.example.com'))
      # assert(!Validator.is_email("Abc.@example.com"))
      # assert(!Validator.is_email("Abc..123@example.com"))
      assert(!Validator.is_email('A@b@c@example.com'))
      assert(!Validator.is_email("a\"b(c)d,e:f;g<h>i[j\k]l@example.com"))
      assert(!Validator.is_email("just\"not\"right@example.com"))
      assert(!Validator.is_email("this is\"not\allowed@example.com"))
      assert(!Validator.is_email("\"this\\ still\\\"not\\\\allowed@example.com"))

    end

    def test_is_website
      assert(Validator.is_website_url('http://www.osingasoftware.nl'))
      assert(Validator.is_website_url('http://www.cmd.tech.nhl.nl'))
      assert(Validator.is_website_url('http://www.cmd.tech.nhl.nl/?test=sadlifjamwlrjasvlusmvietia&amp;afdsasdfasl.kjfasfasdf'))
      assert(!Validator.is_website_url('www.osingasoftware.nl'))
      assert(!Validator.is_website_url('taco@osisoft.nl'))
      assert(!Validator.is_website_url(123))
      assert(!Validator.is_website_url(true))
      assert(!Validator.is_website_url(nil))
      assert(!Validator.is_website_url({}))
      assert(!Validator.is_website_url([]))
    end

    def test_in_array
      assert(Validator.in_array('test', ['test', 'test 2']))
      assert(!Validator.in_array('test', ['test 1', 'test 2']))
      assert(Validator.in_array(5, [1, 1, 2, 3, 5, 8]))
      assert(!Validator.in_array(6, [1, 1, 2, 3, 5, 8]))
      assert(!Validator.in_array('test', []))
      assert(!Validator.in_array('test', nil))
      assert(!Validator.in_array('test', {test: 'test'}))
      assert(!Validator.in_array('test', {test: 'test 1'}))
      assert(!Validator.in_array([2, 5], [1, 1, 2, 3, 5, 8]))
      assert(Validator.in_array([2, 5], [[1, 1], [2, 5]]))
      assert(!Validator.in_array([6, 5], [1, 1, 2, 3, 5, 8]))
      assert(!Validator.in_array([6, 5], nil))
    end

  end

end