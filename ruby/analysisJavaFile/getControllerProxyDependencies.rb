#!/usr/bin/env ruby

require 'writeexcel'

class FileParser
	def initialize(codeDir)
		@codeDir = codeDir;
		@currentDir = File.dirname(__FILE__);
  	end

  	def parse()
		getAllControllerFiles
		parseControllerFile
  	end

	def getAllControllerFiles()
		Dir.chdir(@codeDir);

		@controllerFiles = Dir.glob("**/*Controller.java")
		if (@controllerFiles.size == 0)
			puts "can find any controller files in #{@codeDir}"
			exit 1
		end
	end

	def parseControllerFile()
		urlDep = Hash.new {|hsh, key| hsh[key] = [] }

		@controllerFiles.each {|javaFile|
			baseUrl = nil
			dependProxy = []
			dependBiz = []
			dependDao = []
			urlPath = []
			IO.foreach(@codeDir + File::SEPARATOR + javaFile) { |javaCodeLine| 
				if ( javaCodeLine =~ /^\s*@Path\("(.*)"\)/ )
					baseUrl ||= $1
					if !baseUrl.end_with? "/"
						baseUrl << "/"
					end
				elsif ( javaCodeLine =~ /^\s*import .*\.(.*Proxy);/ )
					dependProxy << $1
				elsif ( javaCodeLine =~ /^\s*import .*\.(.*Biz);/ )
					dependBiz << $1
				elsif ( javaCodeLine =~ /^\s*import .*\.(.*DAO);/ )
					dependDao << $1
				elsif ( javaCodeLine =~ /^\s*@Get\("(.*)"\)/ || javaCodeLine =~ /^\s*@Post\("(.*)"\)/)
					subUrl = $1
					if !subUrl.end_with? "/"
						subUrl << "/"
					end

					if !subUrl.eql? "/"
						subUrl = baseUrl + subUrl
					end

					
					urlPath << subUrl
				end
			}
			urlPath.uniq!

			allDep = []
			allDep << dependProxy.uniq
			allDep << dependBiz.uniq
			allDep << dependDao.uniq

			urlPath.each { |url|
				urlDep[url] << allDep
			}
		}

		urlDep.each {|url, dep|
			puts url
			puts dep
			puts
		}
	end

end



codeDir = ARGV[0];

fp = FileParser.new(codeDir)
fp.parse