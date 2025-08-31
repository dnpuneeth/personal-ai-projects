class ChatController < ApplicationController
  before_action :set_document
  before_action :set_conversation
  before_action :check_ai_action_limit!, only: [:send_message]

  def show
    # Show the chat interface
    @messages = @conversation.messages.includes(:conversation).order(:created_at)

    respond_to do |format|
      format.html
      format.json { render json: { conversation: @conversation, messages: @messages } }
    end
  end

  def send_message
    Rails.logger.info "Chat message request - Content-Type: #{request.content_type}"
    Rails.logger.info "Chat message params: #{params.inspect}"

    # Extract content from params (JSON or FormData)
    content = if request.content_type == 'application/json'
                JSON.parse(request.body.read)['content']
              else
                params[:content]
              end&.strip

    Rails.logger.info "Extracted content: #{content.inspect}"

    return handle_error('Message content is required', :bad_request) unless content.present?

    # Check if conversation can accept more messages
    unless @conversation.can_add_message?
      return handle_error('Conversation limit reached. Please start a new conversation.', :bad_request)
    end

    # Add user message
    user_message = @conversation.add_message(
      role: 'user',
      content: content
    )

    unless user_message
      return handle_error('Failed to add message', :internal_server_error)
    end

    # Process with AI
    begin
      ai_response = process_chat_message(content)

      # Add AI response
      ai_message = @conversation.add_message(
        role: 'assistant',
        content: ai_response[:answer],
        tokens_used: ai_response[:tokens_used],
        cost_cents: ai_response[:cost_cents],
        metadata: {
          citations: ai_response[:citations],
          confidence: ai_response[:confidence],
          model: ai_response[:model]
        }
      )

      # Track AI event
      @document.ai_events.create!(
        event_type: 'question_answering',
        model: ai_response[:model],
        tokens_used: ai_response[:tokens_used],
        latency_ms: ai_response[:latency_ms],
        cost_cents: ai_response[:cost_cents],
        metadata: {
          conversation_id: @conversation.id,
          message_id: ai_message.id,
          cached: ai_response[:cached] || false
        }
      )

      # Track usage for anonymous/authenticated users
      increment_anonymous_ai_action_count!

      Rails.logger.info "Chat response - Request format: #{request.format}, Accept header: #{request.headers['Accept']}"

      respond_to do |format|
        format.html {
          Rails.logger.info "Rendering HTML response"
          redirect_to chat_document_path(@document)
        }
        format.json {
          Rails.logger.info "Rendering JSON response"
          render json: {
            success: true,
            user_message: user_message,
            ai_message: ai_message,
            conversation: @conversation
          }
        }
        format.any {
          Rails.logger.info "Rendering default response (JSON)"
          render json: {
            success: true,
            user_message: user_message,
            ai_message: ai_message,
            conversation: @conversation
          }
        }
      end

    rescue => e
      Rails.logger.error "Chat message processing failed: #{e.message}"

      # Add error message
      @conversation.add_message(
        role: 'assistant',
        content: "I'm sorry, I encountered an error processing your message. Please try again.",
        metadata: { type: 'error', error: e.message }
      )

      handle_error('Failed to process message', :internal_server_error)
    end
  end

  def new_conversation
    # End current conversation and start fresh
    @conversation.update!(expires_at: 1.minute.ago)

    # Create new conversation
    @conversation = @document.get_or_create_conversation(current_user)

    redirect_to chat_document_path(@document)
  end

  private

  def set_document
    @document = Document.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    handle_error('Document not found', :not_found)
  end

  def set_conversation
    @conversation = @document.get_or_create_conversation(current_user)
  end

  def process_chat_message(content)
    start_time = Time.current

    # Check cache first
    cache_key = "chat_response:#{@document.id}:#{Digest::MD5.hexdigest(content.downcase.strip)}"
    cached_response = Rails.cache.read(cache_key)

    if cached_response
      Rails.logger.info "Cache hit for question: #{content}"
      return cached_response.merge(
        cached: true,
        latency_ms: 0
      )
    end

    # Get conversation context (aggressively optimized for token usage)
    conversation_history = if @conversation.message_count > 8
                             @conversation.conversation_context_short  # Last 2 messages for long conversations
                           else
                             @conversation.conversation_context        # Last 3 messages for normal conversations
                           end

    # Build context-aware prompt (aggressively optimized)
    context_prompt = build_context_prompt(conversation_history, content)

    # Search for relevant document chunks (aggressively optimized for token usage)
    rag_service = RagSearchService.new
    search_result = rag_service.search(content, document_id: @document.id, top_k: 3)  # Reduced from 6 to 3 chunks

    if search_result[:chunks].empty?
      return {
        answer: "I don't have enough context from the document to answer your question. Could you please rephrase or ask about something more specific?",
        citations: [],
        confidence: 0.3,
        model: 'gpt-4o-mini',
        tokens_used: 0,
        cost_cents: 0,
        latency_ms: ((Time.current - start_time) * 1000).round,
        cached: false
      }
    end

        # Truncate chunk content to save tokens (create new objects to avoid modifying originals)
    truncated_chunks = search_result[:chunks].map do |chunk|
      # Create a new object with truncated content
      chunk.dup.tap do |truncated_chunk|
        if truncated_chunk.content.length > 1500
          truncated_chunk.content = truncated_chunk.content[0..1499] + "..."
        end
      end
    end

    # Use cheaper model for chat (gpt-4o-mini)
    llm_service = LlmClientService.new
    response = llm_service.chat_answer(
      context: truncated_chunks,
      conversation_history: conversation_history,
      current_question: content
    )

    result = {
      answer: response[:answer],
      citations: response[:citations] || [],
      confidence: response[:confidence] || 0.8,
      model: response[:model],
      tokens_used: response[:tokens_used],
      cost_cents: calculate_llm_cost(response[:tokens_used], response[:model]),
      latency_ms: ((Time.current - start_time) * 1000).round,
      cached: false
    }

    # Cache the response for 1 hour
    Rails.cache.write(cache_key, result, expires_in: 1.hour)

    # Log token usage for monitoring
    estimated_input = estimate_input_tokens(conversation_history, search_result[:chunks], content)
    Rails.logger.info "Chat tokens used: #{result[:tokens_used]} (estimated input: #{estimated_input}, total: #{estimated_input + 500})"

    # Log cost savings
    old_cost = calculate_llm_cost(8000, 'gpt-4o-mini')  # Old average
    new_cost = result[:cost_cents]
    savings = old_cost - new_cost
    Rails.logger.info "Cost savings: $#{sprintf('%.4f', savings/100.0)} (from $#{sprintf('%.4f', old_cost/100.0)} to $#{sprintf('%.4f', new_cost/100.0)})"

    result
  end

  def estimate_input_tokens(conversation_history, chunks, question)
    # Rough estimation: 1 token ≈ 4 characters for English text
    history_tokens = conversation_history.sum { |msg| (msg.content.length / 4.0).ceil }
    chunks_tokens = chunks.sum { |chunk| (chunk.content.length / 4.0).ceil }
    question_tokens = (question.length / 4.0).ceil

    history_tokens + chunks_tokens + question_tokens
  end

  def build_context_prompt(conversation_history, current_question)
    # Build a context-aware prompt (aggressively optimized for token usage)
    history_text = conversation_history.map do |msg|
      "#{msg.role}: #{msg.content}"
    end.join("\n")

    <<~PROMPT
      Document chat. History:
      #{history_text}

      Q: #{current_question}

      IMPORTANT: Answer ONLY based on the document content provided. If the information is not in the document, say "This information is not available in the document." Do not give generic answers.

      A: (1-2 sentences, specific to document content)
    PROMPT
  end

  def calculate_llm_cost(tokens, model)
    # Approximate costs (in cents per 1K tokens)
    costs = {
      'gpt-4o-mini' => 0.15,      # $0.0015 per 1K tokens
      'gpt-4o' => 5.0,           # $0.05 per 1K tokens
      'claude-3.5-sonnet' => 0.75, # $0.0075 per 1K tokens
      'claude-3-opus' => 15.0     # $0.15 per 1K tokens
    }

    cost_per_1k = costs[model] || 0.15
    ((tokens / 1000.0) * cost_per_1k * 100).round
  end

  def handle_error(message, status = :bad_request, additional_data = {})
    respond_to do |format|
      format.html do
        flash[:alert] = message
        redirect_to chat_document_path(@document)
      end
      format.json do
        render json: { error: message }.merge(additional_data), status: status
      end
    end
  end
end
