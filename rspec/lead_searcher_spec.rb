require 'rails_helper'

module Crm
  RSpec.describe LeadSearcher do
    describe '.search' do
      subject(:result) { described_class.search(search_params) }

      context 'when lead is found' do
        let(:lead) { FactoryGirl.create(:lead_auto_financing_type) }

        context 'when find by cpf' do
          context 'when cpf is only numbers' do
            let(:user) { lead.user }
            let(:search_params) { user.cpf }

            it { is_expected.to eq([lead]) }
          end

          context 'when cpf is formatted (has .-)' do
            let(:user) { lead.user }
            let(:search_params) { CPF.new(user.cpf).formatted }

            it { is_expected.to eq([lead]) }
          end
        end

        context 'when just the id is found' do
          let(:search_params) { lead.id }

          it { is_expected.to eq([lead]) }
        end

        context 'when found by id and cpf' do
          context 'when the record is the same' do
            let(:search_params) { lead.id }

            before do
              user = lead.user
              user.cpf = lead.id
              user.save!(validate: false)
            end

            it 'does not duplicate the record' do
              expect(result).to eq([lead])
            end
          end

          context 'when the records are not the same' do
            let(:lead_two) { FactoryGirl.create(:lead_auto_financing_type, created_at: 2.days.ago) }
            let(:user_two) { lead_two.user }
            let(:search_params) { lead.id }

            before do
              user_two.cpf = lead.id
              user_two.save!(validate: false)
            end

            it 'returns both records order by created_at asc' do
              expect(result).to eq [lead_two, lead]
            end
          end
        end

        context 'when find by email' do
          let(:search_params) { lead.user.email }

          it { is_expected.to eq([lead]) }
        end

        context 'when find by name' do
          let(:search_params) { lead.user.name[1..-2] }

          it { is_expected.to eq([lead]) }
        end
      end

      context 'when lead is not found' do
        let(:search_params) { 'oi' }

        it { is_expected.to be_empty }
      end
    end
  end
end
