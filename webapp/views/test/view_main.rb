require 'ubbparser'

module MojuraWebApp

	class TestView < BaseView

		def render
			return render_selectfile
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

		def render_selectfile
			WebApp.page.include_locale(:system)
			html = "<script type='text/javascript' >

			function TestSelectFile() {
				Locale.ensureLoaded('files', {loaded: function() {
						url = \"views/files/coworkers/select_file.mustache?static_only=true\"
						$.get(url, {cache: false},function (template) {
							strs = Locale.rawStrings([\"system\", \"files\"]);

							html = Mustache.to_html(template, strs);
							$(\".test_container\").html(html);
							SelectFile.show({multi: true, confirmed: function (ids) {alert(\"yes\\n\" + ids); }});
					}).error(function () {
						$ (\".test_container\").html(\"\");
					});
				}});
			}

      </script><a class='btn' onclick='TestSelectFile(); return false'>Test</a><div class='test_container'></div>"
			return html
		end

		WebApp.register_view('test', TestView)

	end


end