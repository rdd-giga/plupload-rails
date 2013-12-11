require 'term/ansicolor'

class Downloader
  class Logger
    include Term::ANSIColor

    def initialize(options)
      @options = options

      puts bold("Download plupload assets from github")
      puts "\trepos: #{options[:repo]}"
      puts "\tbranch: #{options[:branch]}"
      puts dark("\tcache path: #{options[:cache_path]}")
      puts dark("\tsave path:")
      options[:save_paths].each do |type, path|
        puts dark("\t\t#{type} files are saved to #{path}")
      end
    end

    def title(message)
      puts bold(message)
    end

    def debug(message)
      puts dark("\t#{message}")
    end

    def input(message)
      puts green("\t<<< #{message}")
    end

    def output(message)
      puts blue("\t>>> #{message}")
    end

    def cache(message)
      puts yellow("\t[CACHED] #{message}")
    end

    def remote(message)
      puts red("\t[REMOTE] #{message} ...")
    end

  protected
    def puts(*args)
      STDOUT.puts(*args) unless @options[:slience]
    end
  end
end
