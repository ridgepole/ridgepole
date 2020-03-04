# frozen_string_literal: true

describe Ridgepole::DSLParser::Context do
  describe '#require_relative' do
    subject { context.require_relative(relative_path) }

    let!(:context) do
      Ridgepole::DSLParser::Context.new
    end
    let!(:relative_path) do
      '../fixtures/for_require_relative_spec.rb'
    end

    it { is_expected.to be_truthy }
  end
end
