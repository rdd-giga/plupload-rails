class Downloader
  module Misc
    def process_misc
      @logger.title "Processing misc of #{@branch} branch"

      misc_path = @save_paths[:misc]
      misc_files = get_tree_files('js', /\.(swf|xap)\z/i)

      download_files('js', misc_files).each do |name, content|
        save_file("#{misc_path}/#{File.basename(name)}", content)
      end
    end
  end
end
