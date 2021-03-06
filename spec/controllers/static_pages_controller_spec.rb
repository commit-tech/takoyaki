# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StaticPagesController, type: :controller do
  describe 'GET static_pages#guide' do
    before do
      sign_in create(:user)
      get :guide
    end

    it { should redirect_to StaticPagesController::GUIDE_URL }
  end

  describe 'GET static_pages#claim_form' do
    before do
      sign_in create(:user)
      get :claim_form
    end

    it { should redirect_to StaticPagesController::CLAIM_FORM_URL }
  end
end
