require 'ubbparser'

module MojuraWebApp

	class TestView < BaseView

		def render
			return render_spinner
		end

		def render_thread
			return '<pre class=\'code\'>' + JSON.pretty_generate(Thread.current[:mojura]) + '</pre>'
		end

		def render_carousel
			text = "Dit is een [carousel height=300 width=400][img]http://twitter.github.com/bootstrap/assets/img/bootstrap-mdo-sfmoma-03.jpg[/img]\n[img]http://twitter.github.com/bootstrap/assets/img/bootstrap-mdo-sfmoma-02.jpg[/img][/carousel]"
			return UBBParser.parse(text) + '<br /><br />'
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

		def render_spinner
			return "<span class='loading icon-spinner icon-spin icon-large'></span> Spinner test"
		end

		WebApp.register_view('test', TestView)

	end


end