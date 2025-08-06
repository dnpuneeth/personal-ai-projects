require 'rails_helper'

RSpec.describe "Costs", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/costs/index"
      expect(response).to have_http_status(:success)
    end
  end

end
