class Downloader
  module Javascripts
    def process_javascripts
      @logger.title "Processing javascripts of #{@branch} branch"

      js_path = @save_paths[:js]
      js_files = get_tree_files('js', /\.js\z/i).reject { |f| f =~ /\/?i18n\//i && f !~ /\/?i18n\/(en|zh_CN)\.js/i }

      download_files('js', js_files).each do |name, content|
        if name.include?('i18n/')
          save_file("#{js_path}/i18n/#{File.basename(name)}", content)
        else
          save_file("#{js_path}/#{File.basename(name)}", content)
        end
      end


      @logger.title "Generate plupload.full.js for easy to use"

      moxie_file = "#{js_path}/moxie.js"
      plupload_file = "#{js_path}/plupload.dev.js"

      moxie_content = File.read(moxie_file)
      plupload_content = File.read(plupload_file)
      save_file("#{js_path}/plupload.full.js", "#{moxie_content}\n\n#{plupload_content}")
    end
  end
end
