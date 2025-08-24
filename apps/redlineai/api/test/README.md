# RedlineAI Test Suite

This directory contains a comprehensive Minitest suite for the RedlineAI application.

## Test Structure

```
test/
├── controllers/           # Controller tests
│   ├── ai_controller_test.rb
│   ├── costs_controller_test.rb
│   └── documents_controller_test.rb
├── fixtures/             # Test data fixtures
│   ├── ai_events.yml
│   ├── doc_chunks.yml
│   └── documents.yml
├── integration/          # End-to-end workflow tests
│   └── document_processing_workflow_test.rb
├── jobs/                 # Background job tests
│   ├── extract_text_job_test.rb
│   └── generate_embeddings_job_test.rb
├── models/               # Model tests
│   ├── ai_event_test.rb
│   ├── doc_chunk_test.rb
│   └── document_test.rb
├── test_helper.rb        # Test configuration and utilities
└── README.md            # This file
```

## Running Tests

### Option 1: Using the Test Runner Script

```bash
./bin/test_runner.rb
```

### Option 2: Manual Test Database Setup

```bash
# Set up test database
RAILS_ENV=test bundle exec rails db:drop db:create db:migrate

# Run all tests
bundle exec rails test

# Run specific test suites
bundle exec rails test test/models/
bundle exec rails test test/controllers/
bundle exec rails test test/jobs/
bundle exec rails test test/integration/

# Run specific test file
bundle exec rails test test/models/document_test.rb

# Run with verbose output
bundle exec rails test -v
```

## Test Coverage

### Model Tests

- **Document**: Validations, status transitions, associations, metadata handling
- **DocChunk**: Content validation, chunk indexing, embedding storage, uniqueness
- **AiEvent**: Event types, cost tracking, token usage, metadata validation

### Controller Tests

- **DocumentsController**: CRUD operations, file uploads, error handling, security
- **AiController**: AI analysis endpoints, caching, error handling, authentication
- **CostsController**: Cost tracking dashboard, statistics, formatting

### Job Tests

- **ExtractTextJob**: PDF text extraction, chunking, error handling, file validation
- **GenerateEmbeddingsJob**: OpenAI API integration, batch processing, retry logic

### Integration Tests

- **Document Processing Workflow**: End-to-end document upload → processing → AI analysis
- **Caching Workflow**: Cache hit/miss scenarios, performance optimization
- **Cost Tracking**: Cost accumulation across different AI operations
- **Error Handling**: Graceful degradation and user feedback

## Test Utilities

### Test Helper Features

- **WebMock Integration**: HTTP request mocking for external APIs
- **OpenAI Mocking**: Pre-configured responses for embeddings and chat completions
- **File Upload Helpers**: Utilities for testing PDF uploads
- **Database Cleanup**: Automatic test data isolation
- **Cache Testing**: Memory store configuration for cache testing

### Fixtures

- **Sample Documents**: Various document states (pending, processing, completed, failed)
- **Document Chunks**: Text chunks with embeddings and metadata
- **AI Events**: Historical AI analysis events with cost and performance data

## Mocking Strategy

### External Services

- **OpenAI API**: All requests are mocked using WebMock
- **PDF Processing**: PDF::Reader responses are stubbed
- **File Storage**: ActiveStorage operations use test adapter

### Database

- **Test Isolation**: Each test runs in a transaction that's rolled back
- **Fixtures**: Consistent test data loaded from YAML files
- **Factory Helpers**: Dynamic test data creation utilities

## Best Practices

### Writing Tests

1. Use descriptive test names that explain the behavior being tested
2. Follow the Arrange-Act-Assert pattern
3. Mock external dependencies consistently
4. Test both success and failure scenarios
5. Include edge cases and boundary conditions

### Test Data

1. Use fixtures for consistent baseline data
2. Create test-specific data in individual tests when needed
3. Clean up any test artifacts that might affect other tests
4. Use realistic but anonymized data

### Performance

1. Tests run in parallel using `parallelize(workers: :number_of_processors)`
2. Use database transactions for fast rollback
3. Mock expensive operations (API calls, file processing)
4. Keep test data minimal but representative

## Continuous Integration

The test suite is designed to run in CI environments with:

- Parallel test execution
- Comprehensive mocking of external dependencies
- Proper database isolation
- Clear failure reporting

## Troubleshooting

### Common Issues

1. **Database Connection**: Ensure PostgreSQL is running and test database exists
2. **Missing Extensions**: pgvector extension must be available in test environment
3. **File Permissions**: Test files need read/write permissions in tmp directory
4. **Environment Variables**: Test environment should not require production API keys

### Debug Mode

```bash
# Run tests with full backtrace
bundle exec rails test --backtrace

# Run single test with debugging
bundle exec rails test test/models/document_test.rb::test_should_be_valid_with_valid_attributes -v
```
