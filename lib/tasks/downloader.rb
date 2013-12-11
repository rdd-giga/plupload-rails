require 'fileutils'
require 'open-uri'
require 'forwardable'
require 'json'

require_relative 'downloader/logger'
require_relative 'downloader/javascripts'
require_relative 'downloader/stylesheets'
require_relative 'downloader/images'
require_relative 'downloader/misc'

class Downloader
  extend Forwardable
  include Javascripts
  include Stylesheets
  include Images
  include Misc

  def initialize(branch)
    @repo = 'moxiecode/plupload'
    @branch ||= 'master'

    @git_raw_host = 'https://raw.github.com'
    @git_api_host = 'https://api.github.com/repos'

    @save_paths = { js: 'vendor/assets/javascripts',
                    css: 'vendor/assets/stylesheets',
                    img: 'vendor/assets/images',
                    misc: 'vendor/assets/misc'}

    @cache_path = 'tmp/downloader-cache'

    @logger = Logger.new(repo: @repo, branch: @branch, save_paths: @save_paths, cache_path: @cache_path)
  end

  def process
    process_javascripts
    process_stylesheets
    process_images
    process_misc

    # sync version following plupload
    save_version
  end

  def save_file(path, content, mode='w')
    FileUtils.mkdir_p File.dirname(path)

    File.open(path, mode) { |f| f.write content }
  end

  def save_version
    plupload = "#{@save_paths[:js]}/plupload.min.js"
    file = 'lib/plupload/rails/version.rb'

    version = File.read(plupload).match(/\*\s+(v|ver|version)([\d.]+)/i)
    if version.length == 3
      content = File.read(file).sub(/VERSION\s*=\s*('|")[\d.]+\1/, "VERSION = \"#{version[2]}\"")

      File.open(file, 'w') { |f| f.write content }
    else
    end
  end

protected
  def get_file(url)
    cache_file = "./#{@cache_path}/#{URI(url).path}"
    FileUtils.mkdir_p File.dirname(cache_file)

    if File.exists?(cache_file)
      @logger.cache cache_file

      return File.read(cache_file, mode: 'rb')
    end

    @logger.remote url
    content = open(url).read
    File.open(cache_file, 'wb') { |f| f.write content }
    content
  end

  def get_json(url)
    JSON.parse get_file(url)
  end

  def get_branch_sha
    git = "git ls-remote 'https://github.com/#{@repo}' | awk '/#{@branch}/ {print $1}'"

    unless @branch_sha
      @logger.remote git

      @branch_sha ||= %x[#{git}].chomp
      raise "Cannot get branch sha using #{git}" unless $?.success?
    end

    @branch_sha
  end

  def get_trees
    @repo_trees ||= get_json("#{@git_api_host}/#{@repo}/git/trees/#{get_branch_sha}")
  end

  def get_tree_sha(tree)
    return tree.fetch('sha', nil) if tree.is_a?(Hash)

    get_trees['tree'].find { |t| t['path'] == tree }['sha']
  end

  def get_tree_files(dir, file_type_regex, file_path_prefix='')
    tree_files = get_json("#{@git_api_host}/#{@repo}/git/trees/#{get_tree_sha(dir)}")

    files = tree_files['tree'].select { |f| f['type'] == 'blob' && f['path'] =~ file_type_regex }.map { |f| f['path'] }
    if dir.is_a?(Hash)
      path = dir.fetch('path', '')
      unless path.empty?
        file_path_prefix = file_path_prefix.empty? ? path : "#{file_path_prefix}/#{path}"

        files.map! { |f| "#{file_path_prefix}/#{f}" }
      end
    end

    # find out all of files hidden in the sub folders recursive
    tree_files['tree'].select { |f| f['type'] == 'tree' }.map { |f| files += get_tree_files(f, file_type_regex, file_path_prefix)}

    files
  end

  def download_files(dir, files)
    tree_files = read_cache_files(dir, files)
    if tree_files.empty?
      tree_path = "#{@git_raw_host}/#{@repo}/#{get_branch_sha}/#{dir}"
      @logger.title "\tdownload #{files.join(',')} from #{tree_path}"

      tree_files = {}
      files.map do |name|
        Thread.start {
          content = open("#{tree_path}/#{name}").read
          Thread.exclusive { tree_files[name] = content }
        }
      end.each(&:join)

      write_cache_files(dir, tree_files)
    end

    tree_files
  end

  def get_cache_path(path)
    "#{@cache_path}/#{@repo}/#{get_branch_sha}/#{path}"
  end

  def read_cache_files(path, files)
    cache_path = get_cache_path(path)

    cache_files = {}
    if File.directory?(cache_path)
      files.each do |name|
        cache_file = "#{cache_path}/#{File.basename(name)}"

        cache_files[name] = File.read(cache_file, mode: 'rb') if File.exists?(cache_file)
      end
    end

    (cache_files.size == files.size) ? cache_files : {}
  end

  def write_cache_files(path, files)
    cache_path = get_cache_path(path)
    FileUtils.mkdir_p cache_path

    files.each do |name, content|
      File.open("#{cache_path}/#{File.basename(name)}", 'wb') { |f| f.write content }
    end
  end
end
