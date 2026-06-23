require_relative 'example_utilities'

class GhostCms < StructuredApi::Endpoint
  url ASK['What URL is your ghostcms at?', 'https://demo.ghost.io'] + '/ghost/api/v4/content'
  params key: ASK["What is your content API key? (under 'integrations' => 'Custom Integration')",
                  '22444f78447824223cefc48062']
  # might need basicauth, depending on how you are set up
end

class GhostCms::Posts < GhostCms
  path '/posts'
end

## Not possible yet
class GhostCms::GetPost < GhostCms
  path '/posts'
  stringish_attr :id

  def override_path
    "#{get_attr(:path)}/#{get_attr(:id)}"
  end
end

class GhostCms::Authors < GhostCms
  path '/authors'
end

authors = JSON.parse(GhostCms::Authors.new.debug!.run!)['authors']
posts = JSON.parse(GhostCms::Posts.new.debug!.run!)['posts']

authors.each do |author|
  puts "Author: #{author['id']} => #{author['name'][0..100]}"
end

posts.each do |post|
  puts "Post: #{post['id']} => #{post['title'][0..100]}...\n#{post['html'][0..100]}...\n"
end

GhostCms::GetPost.new.id(ASK['Enter a ghost post id', posts.first['id']]).debug!.run!
