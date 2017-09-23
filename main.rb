require 'readline'
require 'net/http'
require 'json'
require 'set'

# github api helper
# TODO(query generator)
class GitHubApiHelper
  attr_accessor :host_url

  # host api url
  DEFAULT_HOST_URL = 'http://github.ebaykorea.com/api/v3'.freeze

  # language option
  LANGUAGE = {
    ebay: '+language:csharp' + '+language:asp' + '+language:html',
    empty: ''
  }.freeze

  def initialize(id, pw, host_url: DEFAULT_HOST_URL)
    @id = id
    @pw = pw
    @host_url = host_url
    check_login
  end

  def call_api_with_basic_auth(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    # http.use_ssl = true
    req = Net::HTTP::Get.new(uri.request_uri)
    req.basic_auth @id, @pw
    http.request(req)
  end

  def check_login
    res = call_api_with_basic_auth(@host_url + '/user')
    data = JSON.parse(res.body)
    abort("Login failed for user #{@id}.") unless data.key?('login')
  end

  def search_code(querystring)
    call_api_with_basic_auth @host_url + '/search/code?q=' + querystring
  end
end

# basic auth
login_id = Readline.readline('id: ')
password = Readline.readline('pw: ')

github = GitHubApiHelper.new(login_id, password)

# repository: [keyword1, keyword2, ...]
repo_hash = Hash.new(Set.new)

# read input.txt, call search api
File.foreach('input.txt') do |keyword|
  keyword = keyword.strip
  querys = keyword + GitHubApiHelper::LANGUAGE[:ebay]
  res = github.search_code(querys)
  # parse data
  data = JSON.parse(res.body)
  data['items'].each do |item|
    repo_info = item['repository']
    repo_name = repo_info['full_name']
    repo_hash[repo_name] = repo_hash[repo_name]
    repo_hash[repo_name].add(keyword)
  end
end

# output
File.open('output.txt', 'w') do |file|
  repo_hash.each_pair do |repo_name, keyword_set|
    file.puts repo_name
    keyword_set.each { |keyword| file.puts "\t#{keyword}" }
  end
end
