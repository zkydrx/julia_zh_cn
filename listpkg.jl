
require("JSON")
require("Calendar")
using Calendar

function gen_listpkg()

	Pkg.update()
	io=open("packages/packagelist.rst","w+");
	print(io, "************\n 可用扩展包  \n************\n\n")
	cd(Pkg.dir()) do 
	for pkg in Pkg.Metadata.each_package()
		print(" 正在处理 $(pkg)\n")
		url = (Pkg.Metadata.pkg_url(pkg))
		maxv = Pkg.Metadata.versions([pkg])[end]
		url_reg = r"^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?"
		gh_path_reg_git=r"^/(.*)?/(.*)?.git$"
		gh_path_reg_http=r"^/(.*)?/(.*)?$"
		m=match(url_reg, url)
		host=m.captures[4]
		path=m.captures[5]
		scheme=m.captures[2]
		u=get_user_details_default()

		if ismatch(r"github\.com", host)
			m2 = match(gh_path_reg_git, path)
			user=m2.captures[1]
			repo=m2.captures[2]
			u=get_user_details_gh(user)
			gh_repo_url = "https://api.github.com/repos/$(user)/$(repo)"
			gh_contrib_url = "https://api.github.com/repos/$(user)/$(repo)/contributors"
			gh_repo=JSON.parse(readall(download_file(gh_repo_url)))
			gh_contrib=JSON.parse(readall(download_file(gh_contrib_url)))
			
			desc = get(gh_repo, "description", "No description provided")
			homepage = get(gh_repo, "homepage", nothing)
			html_url = gh_repo["html_url"]
		end
		print(io, "`$(pkg) <$(html_url)>`_\n"); 
		print(io, "_"^(length("`$(pkg) <$(html_url)>`_")) * "\n\n")
		print(io, "  .. image:: $(u[:avatar])\n     :height: 80px\n     :width: 80px\n     :align: right\n     :alt: $(u[:fullname])\n     :target: $(u[:url])\n\n")
		print(io, "  当前版本： ``$(maxv.version)``\n\n"); 
		print(io, "  $(desc) \n\n")
		print(io, "  维护者： `$(u[:fullname]) <$(u[:url])>`_\n\n") 
		
		if homepage != nothing && length(chomp(homepage)) > 0
			print(io, "  文档： `<$(homepage)>`_ \n\n")
		end
		print(io, "  依赖关系： ::\n\n" )
		ver_dir = "METADATA/$pkg/versions/$(maxv.version)/requires"
		any_ver = "任意版本"
		if isfile(ver_dir)
			vset = Pkg.Metadata.parse_requires(ver_dir)
			if length(vset) > 0
				for deps in vset
					print(io, "      $(deps.package)"); print(io, " "^(15-length(deps.package))); print(io, "$(length(deps.versions)>0 ? deps.versions : any_ver)\n")
				end
			else 
				print(io, "      无\n")
			end
		else 
			print(io, "      无\n")
		end
		print(io, "\n")

		if ismatch(r"github\.com", host)
			print(io, "  贡献者：\n\n")
			for contributor in gh_contrib 
				c_user = get(contributor, "login", "")
				u=get_user_details_gh(c_user)
				print(io, "    .. image:: $(u[:avatar])\n        :height: 40px\n        :width: 40px\n")
				print(io, "        :alt: $(u[:fullname])\n        :target: $(u[:url])\n\n")
			end  #for contributor
		end

		print(io, "----\n\n")
	end  #for pkg
	print(io, ".. footer: $(length(Pkg.Metadata.packages())) 个扩展包，本文档生成于 $(now()) \n\n")
	end  #cd
	
	close(io)
end #function

global user_cache = Dict{String, Dict}()

function get_user_details_default()
	u=Dict{Symbol, String}()
	u[:login] = "Unknown"
	u[:fullname] = "Unknown"
	u[:avatar] = "Not provided"
	u[:url] = "Not provided"

end

function get_user_details_gh(user)

	if !has(user_cache, user)
		gh_user_url = "https://api.github.com/users/$(user)"
		gh_user=JSON.parse(readall(download_file(gh_user_url)))
		fullname = get(gh_user, "name", user)
		if fullname == nothing; fullname = user; end
		avatar = 
		user_url = gh_user["html_url"]

	  u=Dict{Symbol, String}()

	  u[:login] = user
	  u[:avatar] = gh_user["avatar_url"]
	  #Sometimes name is missing, sometimes it is null in the JSON
	  if get(gh_user, "name", user) == nothing
	  	u[:fullname] = user
	  else
	  	u[:fullname] = get(gh_user, "name", user)
	  end
	  u[:url] = gh_user["html_url"]

	  user_cache[user] = u
	end

	return user_cache[user]

end #function 

gen_listpkg()
