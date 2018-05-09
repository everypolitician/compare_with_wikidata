module CompareWithWikidata
  class MediawikiAPIClient
    extend Forwardable

    def initialize(mediawiki_site:, username:, password:, client: nil)
      @mediawiki_site = mediawiki_site
      @username = username
      @password = password
      @client = client
    end

    def_delegators :@client, :action, :get_wikitext

    def edit(params)
      return client.edit(params) unless username == bot_username
      # Note that the value of the bot parameter isn't important - the
      # parameter just has to be present:
      # https://www.wikidata.org/w/api.php?action=help&modules=main#main/datatypes
      client.edit(params.merge(bot: 'true'))
    end

    def log_in
      client.log_in(username, password)
    end

    private

    attr_reader :mediawiki_site, :username, :password

    def client
      @client ||= MediawikiApi::Client.new("https://#{mediawiki_site}/w/api.php").tap do |c|
        result = c.log_in(username, password)
        raise "MediawikiApi::Client#log_in failed: #{result}" unless result['result'] == 'Success'
      end
    end

    def bot_username
      ENV.fetch('BOT_USERNAME', 'Prompter Bot')
    end
  end
end
