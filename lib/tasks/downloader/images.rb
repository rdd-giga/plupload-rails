class Downloader
  module Images
    def process_images
      # jquery.plupload.queue && jquery.ui.plupload
      @logger.title "Processing images of #{@branch} branch"

      img_path = @save_paths[:img]
      img_files = get_tree_files('js', /\.(gif|png|jpg|jpeg)\z/i)

      download_files('js', img_files).each do |name, content|
        save_file("#{img_path}/#{File.basename(name)}", content)
      end
    end
  end
end
