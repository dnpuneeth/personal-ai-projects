class LlmClientService
  include HTTParty

  # Increase timeout to 120 seconds for AI API calls
  default_timeout 120

  def initialize
    @openai_key = ENV['OPENAI_API_KEY']
    @anthropic_key = ENV['ANTHROPIC_API_KEY']
    @default_model = ENV.fetch('LLM_MODEL', 'gpt-4o-mini')
  end

  def answer(schema:, context:, question:, model: nil)
    model ||= @default_model

    if model.start_with?('gpt-')
      openai_answer(schema: schema, context: context, question: question, model: model)
    elsif model.start_with?('claude-')
      anthropic_answer(schema: schema, context: context, question: question, model: model)
    else
      raise "Unsupported model: #{model}"
    end
  end

  def chat_answer(context:, conversation_history:, current_question:, model: nil)
    model ||= 'gpt-4o-mini'  # Use cheaper model for chat

    if model.start_with?('gpt-')
      openai_chat_answer(context: context, conversation_history: conversation_history, current_question: current_question, model: model)
    elsif model.start_with?('claude-')
      anthropic_chat_answer(context: context, conversation_history: conversation_history, current_question: current_question, model: model)
    else
      raise "Unsupported model: #{model}"
    end
  end

  private

  def openai_answer(schema:, context:, question:, model:)
    response = self.class.post('https://api.openai.com/v1/chat/completions',
      headers: {
        'Authorization' => "Bearer #{@openai_key}",
        'Content-Type' => 'application/json'
      },
      body: {
        model: model,
        messages: [
          {
            role: 'system',
            content: build_system_prompt(schema)
          },
          {
            role: 'user',
            content: build_user_prompt(context: context, question: question)
          }
        ],
        temperature: 0.1,
        max_tokens: 2000
      }.to_json
    )

    if response.success?
      {
        answer: response['choices'][0]['message']['content'],
        model: model,
        tokens_used: response['usage']['total_tokens'],
        provider: 'openai'
      }
    else
      Rails.logger.error "OpenAI API error: #{response.code} - #{response.body}"
      raise "OpenAI API error: #{response.code}"
    end
  end

  def anthropic_answer(schema:, context:, question:, model:)
    response = self.class.post('https://api.anthropic.com/v1/messages',
      headers: {
        'x-api-key' => @anthropic_key,
        'Content-Type' => 'application/json',
        'anthropic-version' => '2023-06-01'
      },
      body: {
        model: model,
        max_tokens: 2000,
        messages: [
          {
            role: 'user',
            content: build_user_prompt(context: context, question: question)
          }
        ],
        system: build_system_prompt(schema)
      }.to_json
    )

    if response.success?
      {
        answer: response['content'][0]['text'],
        model: model,
        tokens_used: response['usage']['input_tokens'] + response['usage']['output_tokens'],
        provider: 'anthropic'
      }
    else
      Rails.logger.error "Anthropic API error: #{response.code} - #{response.body}"
      raise "Anthropic API error: #{response.code}"
    end
  end

  def build_system_prompt(schema)
    <<~PROMPT
      You are a helpful AI assistant that analyzes documents and answers questions based on the provided context.

      CRITICAL: You MUST respond with ONLY valid JSON that exactly matches this schema:
      #{schema}

      FORMATTING RULES:
      1. Return ONLY the JSON object, no additional text before or after
      2. Use double quotes for all strings
      3. Ensure all JSON syntax is correct (commas, brackets, etc.)
      4. Do not include markdown code blocks or explanations
      5. Always cite specific chunks using chunk_id, start, end, and quote fields
      6. If insufficient context, return: {"error": "insufficient_context", "missing": ["specific information needed"]}
      7. Be precise and factual in your responses
      8. Include confidence scores where appropriate (0.0 to 1.0)

      Example valid response format:
      {"summary": "Document summary here", "top_risks": [{"risk": "Risk name", "severity": "medium", "description": "Risk description"}], "citations": [{"chunk_id": 1, "start": 0, "end": 50, "quote": "Relevant quote"}]}
    PROMPT
  end

  def build_user_prompt(context:, question:)
    <<~PROMPT
      Context from document chunks:
      #{context.map { |chunk| "Chunk #{chunk.id}: #{chunk.content}" }.join("\n\n")}

      Question: #{question}

      Please provide your answer in the specified JSON format.
    PROMPT
  end

  def openai_chat_answer(context:, conversation_history:, current_question:, model:)
    # Build conversation history for context (aggressively optimized for token usage)
    messages = [
      {
        role: 'system',
        content: build_chat_system_prompt
      }
    ]

    # Add conversation history (last 2 messages to stay within token limits)
    conversation_history.last(2).each do |msg|
      messages << {
        role: msg.role,
        content: msg.content
      }
    end

    # Add current question with document context
    messages << {
      role: 'user',
      content: build_chat_user_prompt(context: context, current_question: current_question)
    }

    response = self.class.post('https://api.openai.com/v1/chat/completions',
      headers: {
        'Authorization' => "Bearer #{@openai_key}",
        'Content-Type' => 'application/json'
      },
              body: {
          model: model,
          messages: messages,
          temperature: 0.7,  # Slightly more creative for chat
          max_tokens: 500    # Very short responses for chat (aggressively optimized)
        }.to_json
    )

    if response.success?
      {
        answer: response['choices'][0]['message']['content'],
        model: model,
        tokens_used: response['usage']['total_tokens'],
        provider: 'openai',
        citations: extract_citations_from_response(response['choices'][0]['message']['content'])
      }
    else
      Rails.logger.error "OpenAI chat API error: #{response.code} - #{response.body}"
      raise "OpenAI chat API error: #{response.code}"
    end
  end

  def anthropic_chat_answer(context:, conversation_history:, current_question:, model:)
    # Build conversation history for context (aggressively optimized for token usage)
    messages = []

    # Add conversation history (last 2 messages to stay within token limits)
    conversation_history.last(2).each do |msg|
      messages << {
        role: msg.role,
        content: msg.content
      }
    end

    # Add current question with document context
    messages << {
      role: 'user',
      content: build_chat_user_prompt(context: context, current_question: current_question)
    }

    response = self.class.post('https://api.anthropic.com/v1/messages',
      headers: {
        'x-api-key' => @anthropic_key,
        'Content-Type' => 'application/json',
        'anthropic-version' => '2023-06-01'
      },
              body: {
          model: model,
          max_tokens: 500,   # Very short responses for chat (aggressively optimized)
          messages: messages,
          system: build_chat_system_prompt
        }.to_json
    )

    if response.success?
      {
        answer: response['content'][0]['text'],
        model: model,
        tokens_used: response['usage']['input_tokens'] + response['usage']['output_tokens'],
        provider: 'anthropic',
        citations: extract_citations_from_response(response['content'][0]['text'])
      }
    else
      Rails.logger.error "Anthropic chat API error: #{response.code} - #{response.body}"
      raise "Anthropic chat API error: #{response.code}"
    end
  end

  def build_chat_system_prompt
    <<~PROMPT
      You are a document analysis AI. Your job is simple:

      1. Read the document chunks provided
      2. Answer questions using ONLY information from those chunks
      3. If you find the information, give the exact answer with numbers
      4. If you don't find it, say "This information is not available in the document."
      5. Do NOT mention chunks, chunk IDs, or any technical details in your answer

      That's it. No generic answers. Only use what's in the chunks.
    PROMPT
  end

  def build_chat_user_prompt(context:, current_question:)
    <<~PROMPT
      DOCUMENT CONTENT:
      #{context.map { |chunk| "CHUNK #{chunk.id}: #{chunk.content}" }.join("\n\n")}

      QUESTION: #{current_question}

      INSTRUCTIONS:
      - Read the chunks above
      - Answer using ONLY information from those chunks
      - If you find the information, give the exact answer with numbers
      - If you don't find it, say "This information is not available in the document."
      - Do NOT mention chunks, chunk IDs, or any technical details in your answer
    PROMPT
  end

  def extract_citations_from_response(response_text)
    # Simple citation extraction - look for chunk references
    citations = []

    # Look for patterns like "Chunk X" or "section X"
    response_text.scan(/chunk\s+(\d+)/i).each do |match|
      chunk_id = match[0].to_i
      citations << {
        chunk_id: chunk_id,
        start: 0,
        end: 0,
        quote: "Referenced in response"
      }
    end

    citations
  end
end
