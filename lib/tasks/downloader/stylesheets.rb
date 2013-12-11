class Downloader
  module Stylesheets
    def process_stylesheets
      # jquery.plupload.queue && jquery.ui.plupload
      @logger.title "Processing stylesheets of #{@branch} branch"

      css_path = @save_paths[:css]
      css_files = get_tree_files('src', /\.css\z/i)

      download_files('src', css_files).each do |name, content|
        save_file("#{css_path}/#{File.basename(name)}", content.gsub('../img/', '../images/'))
      end
    end
  end
end
