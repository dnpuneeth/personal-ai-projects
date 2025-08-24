#!/bin/bash

# RedlineAI API Test Script
# Make sure the Rails server is running on port 3000

BASE_URL="http://localhost:3000"

echo "🧪 Testing RedlineAI API"
echo "========================"

# Test health endpoint
echo "1. Testing health endpoint..."
curl -s "$BASE_URL/healthz" | jq .
echo ""

# Test document upload (this will fail with non-PDF)
echo "2. Testing document upload validation..."
curl -s "$BASE_URL/documents" -X POST -F "file=@test_document.txt" | jq .
echo ""

# Test getting a non-existent document
echo "3. Testing get non-existent document..."
curl -s "$BASE_URL/documents/999" | jq .
echo ""

echo "✅ Basic API tests completed!"
echo ""
echo "To test with a real PDF:"
echo "1. Get a PDF file"
echo "2. Run: curl -s $BASE_URL/documents -X POST -F 'file=@your_document.pdf' | jq ."
echo "3. Use the returned document_id to test AI endpoints"
echo ""
echo "Example AI endpoints:"
echo "- POST $BASE_URL/documents/{id}/summarize"
echo "- POST $BASE_URL/documents/{id}/answer"
echo "- POST $BASE_URL/documents/{id}/redlines" 