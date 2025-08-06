ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/reporters"
require "webmock/minitest"

# Configure minitest reporters
Minitest::Reporters.use! [Minitest::Reporters::ProgressReporter.new]

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    
    # Helper method to create a test PDF file
    def create_test_pdf_file(content = "Test PDF content")
      file = Tempfile.new(['test', '.pdf'])
      file.write(content)
      file.rewind
      file
    end

    # Helper method to mock OpenAI responses
    def mock_openai_response(response_data)
      stub_request(:post, /api\.openai\.com/)
        .to_return(
          status: 200,
          body: response_data.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    # Helper method to mock embedding response
    def mock_embedding_response(embeddings = [0.1] * 1536)
      mock_openai_response({
        object: "list",
        data: [
          {
            object: "embedding",
            embedding: embeddings,
            index: 0
          }
        ],
        model: "text-embedding-3-small",
        usage: {
          prompt_tokens: 10,
          total_tokens: 10
        }
      })
    end

    # Helper method to mock chat completion response
    def mock_chat_completion_response(content)
      mock_openai_response({
        id: "chatcmpl-test",
        object: "chat.completion",
        created: Time.current.to_i,
        model: "gpt-4o-mini",
        choices: [
          {
            index: 0,
            message: {
              role: "assistant",
              content: content
            },
            finish_reason: "stop"
          }
        ],
        usage: {
          prompt_tokens: 100,
          completion_tokens: 50,
          total_tokens: 150
        }
      })
    end

    # Helper method to create document with chunks
    def create_document_with_chunks(title: "Test Document", chunk_count: 3)
      document = Document.create!(
        title: title,
        status: :completed,
        metadata: { pages: 1, file_size: 1024 }
      )

      chunk_count.times do |i|
        document.doc_chunks.create!(
          content: "Test chunk content #{i + 1}",
          chunk_index: i,
          metadata: { page: 1, position: i }
        )
      end

      document
    end

    # Disable external HTTP requests during tests
    def setup
      WebMock.disable_net_connect!(allow_localhost: true)
    end

    def teardown
      WebMock.reset!
    end
  end
end

# Configure ActiveJob to use test adapter
ActiveJob::Base.queue_adapter = :test