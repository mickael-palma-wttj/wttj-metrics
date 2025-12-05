# frozen_string_literal: true

# Shared examples for presenters
RSpec.shared_examples 'a presenter' do
  it { is_expected.to respond_to(:name) }
  it { is_expected.to respond_to(:value) }
  it { is_expected.to respond_to(:label) }
  it { is_expected.to respond_to(:display_value) }
  it { is_expected.to respond_to(:to_h) }
end
