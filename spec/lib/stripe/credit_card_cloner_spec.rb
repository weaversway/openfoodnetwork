# frozen_string_literal: true

require 'spec_helper'
require 'stripe/credit_card_cloner'

module Stripe
  describe CreditCardCloner do
    describe "#clone" do
      let(:cloner) { Stripe::CreditCardCloner.new }

      let(:customer_id) { "cus_A123" }
      let(:payment_method_id) { "pm_1234" }
      let(:new_customer_id) { "cus_A456" }
      let(:new_payment_method_id) { "pm_456" }
      let(:stripe_account_id) { "acct_456" }
      let(:customer_response_mock) { { status: 200, body: customer_response_body } }
      let(:payment_method_response_mock) { { status: 200, body: payment_method_response_body } }

      let(:credit_card) { create(:credit_card, user: create(:user)) }

      before do
        allow(Stripe).to receive(:api_key) { "sk_test_12345" }

        stub_request(:post, "https://api.stripe.com/v1/payment_methods")
          .with(body: { customer: customer_id, payment_method: payment_method_id},
                headers: { 'Stripe-Account' => stripe_account_id })
          .to_return(payment_method_response_mock)

        stub_request(:post, "https://api.stripe.com/v1/customers")
          .with(body: { email: credit_card.user.email },
                headers: { 'Stripe-Account' => stripe_account_id })
          .to_return(customer_response_mock)

        stub_request(:post, "https://api.stripe.com/v1/payment_methods/#{new_payment_method_id}/attach")
          .with(body: { customer: new_customer_id },
                headers: { 'Stripe-Account' => stripe_account_id })
          .to_return(payment_method_response_mock)
      end

      context "when called with a credit_card with valid id (card_*)" do
        let(:payment_method_response_body) {
          JSON.generate(id: new_payment_method_id)
        }
        let(:customer_response_body) {
          JSON.generate(id: new_customer_id)
        }

        before do
          credit_card.update_attributes gateway_customer_profile_id: customer_id,
                                        gateway_payment_profile_id: payment_method_id
        end

        it "clones the card successefully" do
          customer_id, payment_method_id = cloner.clone(credit_card, stripe_account_id)

          expect(customer_id).to eq new_customer_id
          expect(payment_method_id).to eq new_payment_method_id
        end
      end
    end
  end
end
