require 'rails_helper'

RSpec.describe Crm::HomeRefinancing::LeadScoreUpdater do
  class FooCalculator
    def calculate(_context)
      1
    end
  end

  let(:lead) { FactoryGirl.create(:lead_home_refinancing_type, score: 1, value: 1, closing_probability: 0.1) }
  let(:transaction_status) { 'ready' }
  let(:transaction) do
    FactoryGirl.create(:home_refinancing_transaction_transaction, :with_specific_transaction,
      lead: lead, status: transaction_status)
  end
  let(:described_instance) { described_class.new(transaction, calculators: [FooCalculator.new]) }
  let(:described_instance_default) { described_class.new(transaction) }

  describe '#update' do
    context 'when using calculators default' do
      let(:closing_probability_calculator) { double('closing_probability_calculator') }
      let(:lead_value_calculator) { double('lead_value_calculator') }
      let(:lead_score_calculator) { double('lead_score_calculator') }
      let(:lead_class_calculator) { double('lead_class_calculator') }

      after { described_instance_default.update }

      it 'calls default calculators' do
        expect(Crm::HomeRefinancing::Calculators::ClosingProbability).to receive(:new)
          .and_return(closing_probability_calculator)
        expect(closing_probability_calculator).to receive(:calculate)
        expect(Crm::HomeRefinancing::Calculators::LeadValue).to receive(:new).and_return(lead_value_calculator)
        expect(lead_value_calculator).to receive(:calculate)
        expect(Crm::HomeRefinancing::Calculators::LeadScore).to receive(:new).and_return(lead_score_calculator)
        expect(lead_score_calculator).to receive(:calculate)
        expect(Crm::HomeRefinancing::Calculators::LeadClass).to receive(:new).and_return(lead_class_calculator)
        expect(lead_class_calculator).to receive(:calculate)
      end
    end

    subject { described_instance.update }

    context 'when lead is nil' do
      let(:lead) { nil }

      it { is_expected.to be_nil }
    end

    context 'when transaction passed is not ready' do
      let(:transaction_status) { 'no_service' }

      context 'when there is not another ready transaction for lead' do
        it { is_expected.to_not be_nil }
      end

      context 'when there is another ready transaction for lead' do
        before do
          FactoryGirl.create(:home_refinancing_transaction_transaction, status: 'ready', lead: lead)
        end

        it { is_expected.to be_nil }
      end
    end

    context 'when transaction passed is ready' do
      it { is_expected.to_not be_nil }
    end
  end

  describe '#lead_value' do
    subject { described_instance.lead_value }

    it { is_expected.to eq lead.value }
  end

  describe '#lead_score' do
    subject { described_instance.lead_score }

    it { is_expected.to eq lead.score }
  end

  describe '#loan_amount' do
    subject { described_instance.loan_amount }

    it { is_expected.to eq transaction.specific.loan_amount }
  end

  describe '#lead_closing_probability' do
    subject { described_instance.lead_closing_probability }

    it { is_expected.to eq lead.closing_probability }
  end
end
