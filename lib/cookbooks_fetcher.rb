class CookbooksFetcher < EasyLogger
  
  # constructor method
  def initialize(facility_log_level)
    @facility_log_level = facility_log_level
    super(facility_log_level)
  end
  
  def fetch(cookbooks_src, cookbooks_dest='/usr/src/chef-cookbooks', archive=true)
    logger = EasyLogger.new(@facility_log_level)    
    if Process.uid != 0
      cookbooks_dest = "#{File.expand_path("~")}/chef-cookbooks"
    end
    system("mkdir -p #{cookbooks_dest}")
    logger.log "Cookbooks destination: #{cookbooks_dest}.", [ 'verbose', 'debug' ]
    repos_name = File.basename(cookbooks_src).gsub('.git', '')
    logger.log "Inspecting repos, '#{repos_name}'..."
    if File.exists?("#{cookbooks_dest}/#{repos_name}/.git")
      logger.log "Pulling '#{repos_name}' (instead of cloning)..", 'verbose'
      pull_cmd = "cd #{cookbooks_dest}/#{repos_name} && git pull 2>&1"
      pull = "[git] " + `#{pull_cmd}`; result=$?.success?
      if result
        logger.log pull
      else
        logger.log pull, 'error'
        raise "Failed to pull git repository!"
      end
    elsif archive
      system("cd #{cookbooks_dest}; git clone --depth=1 #{cookbooks_src}")
      #system("git archive --format=tar --remote=#{opts[:fetch]} master | tar -xf -")
    else
      system("cd #{cookbooks_dest}; git clone #{cookbooks_src}")
    end
  end

end