class AiController < ApplicationController
  before_action :set_document

  def summarize_and_risks
    schema = {
      type: "object",
      properties: {
        summary: { type: "string" },
        top_risks: {
          type: "array",
          items: {
            type: "object",
            properties: {
              risk: { type: "string" },
              severity: { type: "string", enum: ["low", "medium", "high", "critical"] },
              description: { type: "string" }
            }
          }
        },
        citations: {
          type: "array",
          items: {
            type: "object",
            properties: {
              chunk_id: { type: "integer" },
              start: { type: "integer" },
              end: { type: "integer" },
              quote: { type: "string" }
            }
          }
        }
      }
    }

    process_ai_request(
      schema: schema.to_json,
      question: "Provide a comprehensive summary of this document and identify the top 3-5 risks with their severity levels.",
      event_type: 'summarization'
    )
  end

  def answer_question
    question = params[:question]
    return handle_error('Question is required', :bad_request) unless question.present?

    schema = {
      type: "object",
      properties: {
        question: { type: "string" },
        answer: { type: "string" },
        confidence: { type: "number", minimum: 0, maximum: 1 },
        citations: {
          type: "array",
          items: {
            type: "object",
            properties: {
              chunk_id: { type: "integer" },
              start: { type: "integer" },
              end: { type: "integer" },
              quote: { type: "string" }
            }
          }
        }
      }
    }

    process_ai_request(
      schema: schema.to_json,
      question: question,
      event_type: 'question_answering'
    )
  end

  def propose_redlines
    schema = {
      type: "object",
      properties: {
        edits: {
          type: "array",
          items: {
            type: "object",
            properties: {
              type: { type: "string", enum: ["addition", "deletion", "modification"] },
              location: { type: "string" },
              current_text: { type: "string" },
              suggested_text: { type: "string" },
              reason: { type: "string" },
              severity: { type: "string", enum: ["low", "medium", "high"] }
            }
          }
        }
      }
    }

    process_ai_request(
      schema: schema.to_json,
      question: "Analyze this document and propose specific redlines (edits) to improve clarity, legal compliance, and risk mitigation.",
      event_type: 'redlining'
    )
  end

  private

  def set_document
    @document = Document.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    handle_error('Document not found', :not_found)
  end

  def process_ai_request(schema:, question:, event_type:)
    start_time = Time.current

    # Create cache key based on document, question, and schema
    cache_key = "ai_analysis:#{@document.id}:#{Digest::MD5.hexdigest(question)}:#{Digest::MD5.hexdigest(schema)}"
    
    # Try to get cached result first
    cached_result = Rails.cache.read(cache_key)
    if cached_result
      Rails.logger.info "Cache hit for AI analysis: #{cache_key}"
      
      respond_to do |format|
        format.html do
          @ai_result = cached_result
          @cached = true
          render :show
        end
        format.json do
          render json: cached_result.merge(cached: true)
        end
      end
      return
    end

    begin
      # Search for relevant chunks
      rag_service = RagSearchService.new
      search_result = rag_service.search(question, document_id: @document.id)

      if search_result[:chunks].empty?
        return handle_error('insufficient_context', :bad_request, { missing: ['document content'] })
      end

      # Get AI response
      llm_service = LlmClientService.new
      response = llm_service.answer(
        schema: schema,
        context: search_result[:chunks],
        question: question
      )

      # Parse JSON response
      result = JSON.parse(response[:answer])

      # Cache the result for 3 hours
      Rails.cache.write(cache_key, result, expires_in: 3.hours)
      Rails.logger.info "Cached AI analysis result: #{cache_key}"

      # Track AI event
      latency_ms = ((Time.current - start_time) * 1000).round
      @document.ai_events.create!(
        event_type: event_type,
        model: response[:model],
        tokens_used: response[:tokens_used],
        latency_ms: latency_ms,
        cost_cents: calculate_llm_cost(response[:tokens_used], response[:model]),
        metadata: {
          search_latency_ms: search_result[:latency_ms],
          chunks_retrieved: search_result[:total_chunks],
          cached: false
        }
      )

      respond_to do |format|
        format.html do
          @ai_result = result
          render :show
        end
        format.json do
          render json: result
        end
      end

    rescue JSON::ParserError => e
      Rails.logger.error "JSON parsing error: #{e.message}"
      handle_error('Invalid AI response format', :internal_server_error)
    rescue => e
      Rails.logger.error "AI request failed: #{e.message}"
      handle_error('AI processing failed', :internal_server_error)
    end
  end

  def handle_error(message, status = :bad_request, additional_data = {})
    respond_to do |format|
      format.html do
        flash[:alert] = message
        redirect_to document_path(params[:id])
      end
      format.json do
        render json: { error: message }.merge(additional_data), status: status
      end
    end
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

  def clear_document_cache(document_id)
    # Clear all cached AI analysis results for this document
    pattern = "ai_analysis:#{document_id}:*"
    Rails.cache.delete_matched(pattern)
    Rails.logger.info "Cleared cache for document #{document_id}"
  end
end 