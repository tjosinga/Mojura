require 'ubbparser'

module MojuraWebApp

	class TestView < BaseView

		def render
		  return render_sceditor
		end



		def render_thread
			return '<pre class=\'code\'>' + JSON.pretty_generate(Thread.current[:mojura]) + '</pre>'
		end

		def render_carousel
 			text = "Dit is een [carousel height=300 width=400][img]http://twitter.github.com/bootstrap/assets/img/bootstrap-mdo-sfmoma-03.jpg[/img]\n[img]http://twitter.github.com/bootstrap/assets/img/bootstrap-mdo-sfmoma-02.jpg[/img][/carousel]"
 			return UBBParser.parse(text) + '<br /><br />'
		end

		def render_sceditor
		  WebApp.page.include_script_link('ext/sceditor/jquery.sceditor.min.js')
		  WebApp.page.include_style_link('ext/sceditor/themes/default.min.css')


		  html = "<script type='text/javascript' >

			$(document).ready(function() {
 				$(\"textarea\").sceditor({plugins: 'bbcode', width: '100%', height: '200px'});
			});
      </script><textarea id='myeditor' style='height: 600px width: 500px'></textarea>"
		  return html
		end


		WebApp.register_view('test', TestView)

	end


end