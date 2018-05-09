require 'test_helper'

describe CompareWithWikidata::MediawikiAPIClient do
  it 'should delegate get_wikitext' do
    mock_wrapped_client = MiniTest::Mock.new
    mock_wrapped_client.expect(:get_wikitext, 'some result', ['Example Page Title'])
    client = CompareWithWikidata::MediawikiAPIClient.new(
      username: nil, password: nil, mediawiki_site: nil, client: mock_wrapped_client
    )
    client.get_wikitext('Example Page Title').must_equal 'some result'
    mock_wrapped_client.verify
  end

  it 'should delegate action' do
    mock_wrapped_client = MiniTest::Mock.new
    mock_wrapped_client.expect(:action, 'results of purging', [:purge, titles: ['Example Page Title']])
    client = CompareWithWikidata::MediawikiAPIClient.new(
      username: nil, password: nil, mediawiki_site: nil, client: mock_wrapped_client
    )
    client.action(:purge, titles: ['Example Page Title']).must_equal 'results of purging'
    mock_wrapped_client.verify
  end

  it 'should log_in with the encapsulated username and password' do
    mock_wrapped_client = MiniTest::Mock.new
    mock_wrapped_client.expect(:log_in, 'login results', %w[alice 1234])
    client = CompareWithWikidata::MediawikiAPIClient.new(
      username: 'alice', password: '1234', mediawiki_site: nil, client: mock_wrapped_client
    )
    client.log_in
    mock_wrapped_client.verify
  end

  describe 'if the bot username has been specified in the environment' do
    before do
      @old_bot_username = ENV['BOT_USERNAME']
      ENV['BOT_USERNAME'] = 'Another_Bot_User'
    end

    after do
      ENV['BOT_USERNAME'] = @old_bot_username if @old_bot_username
    end

    it 'should use the bot flag for edits if the username matches BOT_USERNAME' do
      mock_wrapped_client = MiniTest::Mock.new
      mock_wrapped_client.expect(:edit, nil, [{ title: 'Foo', text: '== hello ==', bot: 'true' }])
      client = CompareWithWikidata::MediawikiAPIClient.new(
        username:       'Another_Bot_User',
        password:       nil,
        mediawiki_site: 'wikidata.example.com',
        client:         mock_wrapped_client
      )
      client.edit(title: 'Foo', text: '== hello ==')
      mock_wrapped_client.verify
    end

    it 'should not use the bot flag for edits if the username does not match BOT_USERNAME' do
      mock_wrapped_client = MiniTest::Mock.new
      mock_wrapped_client.expect(:edit, nil, [{ title: 'Foo', text: '== hello ==' }])
      client = CompareWithWikidata::MediawikiAPIClient.new(
        username:       'Not_A_Bot',
        password:       nil,
        mediawiki_site: 'wikidata.example.com',
        client:         mock_wrapped_client
      )
      client.edit(title: 'Foo', text: '== hello ==')
      mock_wrapped_client.verify
    end
  end

  describe 'if the bot username is not specified in the environment' do
    before do
      @old_bot_username = ENV['BOT_USERNAME']
      ENV.delete('BOT_USERNAME')
    end

    after do
      ENV['BOT_USERNAME'] = @old_bot_username if @old_bot_username
    end

    describe 'if the username is not special' do
      it 'should not use the bot flag for edits' do
        mock_wrapped_client = MiniTest::Mock.new
        mock_wrapped_client.expect(:edit, nil, [{ title: 'Foo', text: '== hello ==' }])
        client = CompareWithWikidata::MediawikiAPIClient.new(
          username:       'Some User',
          password:       nil,
          mediawiki_site: 'wikidata.example.com',
          client:         mock_wrapped_client
        )
        client.edit(title: 'Foo', text: '== hello ==')
        mock_wrapped_client.verify
      end
    end

    describe 'if the username is the default bot username' do
      it 'should use the bot flag for edits' do
        mock_wrapped_client = MiniTest::Mock.new
        mock_wrapped_client.expect(:edit, nil, [{ title: 'Foo', text: '== hello ==', bot: 'true' }])
        client = CompareWithWikidata::MediawikiAPIClient.new(
          username:       'Prompter Bot',
          password:       nil,
          mediawiki_site: 'wikidata.example.com',
          client:         mock_wrapped_client
        )
        client.edit(title: 'Foo', text: '== hello ==')
        mock_wrapped_client.verify
      end
    end
  end
end
