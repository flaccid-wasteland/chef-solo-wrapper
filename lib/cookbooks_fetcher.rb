class CookbooksFetcher
  # constructor method
  def initialize()
    
  end
  
  def fetch(cookbooks_src, cookbooks_dest, archive=true)
    if Process.uid != 0
       cookbooks_dest = "#{File.expand_path("~")}/chef-cookbooks"
    end
    system("mkdir -p #{cookbooks_dest}")
    puts "Cookbooks destination: #{cookbooks_dest}."
    if archive
       system("cd #{cookbooks_dest}; git clone --depth=1 #{cookbooks_src}")
       #system("git archive --format=tar --remote=#{opts[:fetch]} master | tar -xf -")
    else
      system("cd #{cookbooks_dest}; git clone #{cookbooks_src}")
    end
    exit
  end
  
end