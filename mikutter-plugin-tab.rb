# coding: UTF-8


Plugin.create(:mikutter_plugin) {
  @plugin_user = User.new(:id => -33993,
                          :idname => "plugin",
                          :name => "プラグイン情報",
                          :profile_image_url => File.join(File.dirname(__FILE__), "plugin.png"))

  tab(:plugin, "プラグイン") {
    set_icon File.join(File.dirname(__FILE__), "plugin.png")
    timeline(:plugin)
  }

  def val_or_none(str)
    if str
      str
    else
      "（なし）"
    end
  end

  Delayer.new {
    Plugin.instances.each { |plugin|
      spec = Miquire::Plugin.get_spec_by_slug(plugin.name)
      if spec && spec[:kind] != :bundle

      message = <<EOF
#{val_or_none(spec[:name])}(#{val_or_none(spec[:slug])})
作者：#{val_or_none(spec[:author])}
バージョン：#{val_or_none(spec[:version])}

#{val_or_none(spec[:description])}
EOF
      msg = Message.new(:system => true, :message => message)

      msg[:user] = @plugin_user

      def msg.repliable?
        false
      end

      timeline(:plugin) << msg
      end
    }
  }

  def get_all_widgets(root, klass)
    proc = lambda { |widget|
      result = []

      begin
        widget.each_forall { |child|
          if child.is_a?(klass)
            result << child
          end

          if child.is_a?(::Gtk::Container)
            result += proc.call(child)
          end
        }
      rescue => e
      end

      result
    }

    proc.call(root)
  end

Delayer.new { |servie|

  command(:plugin_jiman,
          name: _("プラグイン自慢"),
          condition: lambda{ |opt| Plugin::Command[:HasOneMessage].call(opt) && opt.messages[0][:user] == @plugin_user },
          visible: true,
          role: :timeline) { |opt|
postbox = Plugin[:gtk].widgetof(Plugin::GUI::Postbox.cuscaded.values[0])
#postbox = get_all_widgets(Plugin[:gtk].widgetof(Plugin::GUI::Window.instance(:default)), ::Gtk::PostBox)[0]

postbox.widget_post.buffer.text = opt.messages[0].to_s + "\n#mikutter_plugin"
}
          }
}
