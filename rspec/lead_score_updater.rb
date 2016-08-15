module Crm
  module HomeRefinancing
    class LeadScoreUpdater

      attr_reader :transaction, :lead
      attr_accessor :lead_score

      delegate :update_attributes, :closing_probability, :value, :transactions, :reload, to: :lead, prefix: true
      delegate :opportunities, to: :transaction

      def initialize(transaction, options = {})
        @transaction = transaction
        @lead        = transaction.lead
        @lead_score  = lead.try(:score)
        @calculators = options[:calculators] || default_calculators
      end

      def update
        return unless lead && (transaction.ready? || Transaction.ready_by_lead(lead).empty?)

        @calculators.each { |calculator| calculator.calculate(self) }
      end

      def loan_amount
        transaction.specific.loan_amount
      end

      private
      def default_calculators
        [
          Crm::HomeRefinancing::Calculators::ClosingProbability.new,
          Crm::HomeRefinancing::Calculators::LeadValue.new,
          Crm::HomeRefinancing::Calculators::LeadScore.new,
          Crm::HomeRefinancing::Calculators::LeadClass.new
        ]
      end
    end
  end
end
