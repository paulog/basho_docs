require './lib/sitemap_render_override'

module BashoDocsHelpers
  include ::SitemapRenderOverride

  def self.build_keyword_pages(sitemap)
    keyword_pages = {}
    sitemap.resources.each do |resource|
      keywords = resource.metadata[:page]["keywords"]
      next if keywords.blank?
      keywords.each do |keyword|
        (keyword_pages[keyword] ||= []) << resource
      end
    end
    keyword_pages
  end

  # get all pages that match this page's keywords
  def similar_pages(page)
    return [] if page.blank?
    $keyword_pages ||= BashoDocsHelpers.build_keyword_pages(sitemap)
    keywords = page.metadata[:page]["keywords"] || []
    pages = Set.new
    for keyword in keywords
      pages += $keyword_pages[keyword] || []
    end
    pages.delete_if{|g| g.url == page.url }.to_a
  end

  def current_version(default_proj='riak')
    $versions[(data.page.project || default_proj).to_sym] || ENV['RIAK_VERSION']
  end

  def project_version_path(page)
    project = (page.metadata[:page] || {})['project'] || 'riak'
    version = current_version(project)
    current_project = (current_page.metadata[:page] || {})['project'] || 'riak'
    url = page.url.sub(/\.html/, '/')
    if project != current_project
      url = "/#{project}/#{version}#{url}"
    end
    url
  end

  def api_index(api_dir_name)
    apis_path = current_path.sub(/(\w+\.html)$/, '')
    # apis_path = "/references/apis/"
    dir = sitemap.find_resource_by_destination_path("#{apis_path}#{api_dir_name}/index.html").source_file.sub(/([^\/]+)$/, '')
    groups = {}
    for file in Dir.glob("#{dir}*")
      next if file =~ /(?:html|:api)$/
      page = sitemap.find_resource_by_path(sitemap.file_to_path(file))
      metadata = page.metadata[:page] || {}
      next if metadata["index"].to_s =~ /true/i
      (groups[metadata["group_by"]] ||= []) << page
    end
    groups
  end

  def current_projects()
    projects = {}
    data.versions.each do |project, versions|
      next if project == 'currents'
      projects[project] = {
        :deployment => $versions[project.to_sym],
        :latest => versions.last.last
      }
    end
    projects
  end

  # used to convert global nav wiki links into real links
  # TODO: extract this into reuable method
  def wiki_to_link(wiki_link)
    link_found = ($wiki_links ||= {})[wiki_link]
    return link_found if link_found
    if wiki_link =~ (/\[\[([^\]]+?)(?:\|([^\]]+))?\]\]/u)
      link_name = $2 || $1
      link_label = $1 || link_name
      anchor = nil
      link_name, anchor = link_name.split('#', 2) if link_name.include?('#')
      sitemap_key = format_name(link_name)
      link_data = sitemap_pages[sitemap_key] || {}
      # heuristic that an unfound url, is probably not a link
      link_url = link_data[:url]
      unless link_url.blank? && link_name.scan(/[.\/]/).empty?
        # no html inside of the link or label
        link_label.gsub!(/\<[^\>]+\>/u, '_')
        link_url ||= link_name
        link_url += '#' + anchor unless anchor.blank?
        link_url.gsub!(/\<[^\>]+\>/u, '_')
        return $wiki_links[wiki_link] = {:name => link_label, :url => link_url, :key => sitemap_key}
      end
    end
    {}
  end

  # generate reverse breadcrumbs
  def build_breadcrumbs(parent, searching)
    parent.each do |child|
      if child.class == String
        link_data = wiki_to_link(child)
        return [{}] if searching == link_data[:key]
      elsif child.include?('title')
        link_data = wiki_to_link(child['title'])
        if (response = build_breadcrumbs(child['sub'], searching)).present?
          return [link_data] + response
        elsif searching == link_data[:key]
          return [{}]
        end
      end
    end
    []
  end

  def bread_crumbs(page)
    return [] if page.blank?
    page_key = sitemap_page_key(page)
    project = page.metadata[:page]["project"] || 'riak'
    build_breadcrumbs(data.global_nav[project], page_key)
  end

  def build_nav(section, c_name='', depth=1)
    active = false
    nav = ''
    section.each do |sub|
      if sub.class == String
        link_data = wiki_to_link(sub)
        current_link = link_data[:url] == current_page.url
        active ||= current_link
        nav += "<li#{current_link ? ' class="active current"' : ''}>#{sub}</li>"
      else
        nested, sub_active = build_nav(sub['sub'], c_name, depth+1)
        link_data = wiki_to_link(sub['title'])
        current_link = link_data[:url] == current_page.url
        active ||= sub_active || current_link
        active_class = active ? ' class="active"' : ''
        current_class = current_link ? ' class="active current"' : ''
        nav += "<li#{active_class}><h4#{current_class}><span>#{sub['title']}</span></h4>#{nested}</li>"
      end
    end
    nav = "<ul class=\"depth-#{depth} #{c_name}#{active ? ' active' : ''}\">" + nav + "</ul>"
    [nav, active]
  end

end