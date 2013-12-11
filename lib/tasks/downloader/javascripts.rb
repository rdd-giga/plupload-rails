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
    end
  end
end
