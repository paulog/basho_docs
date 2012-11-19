

File.open('full.md', 'w') do |full|
  %w{index intro concepts developers operators}.each do |page_name|
    page = File.readlines("#{page_name}.md").join
    page = page.gsub(/^---$.*?^---$/m, '').strip
    full << page
    full << "\n\n"
  end
end
