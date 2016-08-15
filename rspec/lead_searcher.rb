module Crm
  class LeadSearcher
    class << self
      def search(identifier, order_attribute = :created_at, order = :asc)
        identifier = identifier.to_s

        @conditions = []
        @values = []

        search_by_id(identifier)
        search_by_cpf(identifier)
        search_by_email(identifier)
        search_by_name(identifier)

        search_with_conditions(order_attribute, order)
      end

      private
      def search_by_id(identifier)
        if is_integer?(identifier)
          @conditions << "leads.id = ?"
          @values << identifier
        end
      end

      def is_integer?(string)
        /\A\d+\z/ === string
      end

      def search_by_cpf(identifier)
        cpf = CPF.new(identifier).stripped
        if cpf.present?
          @conditions << "users.cpf = ?"
          @values << cpf
        end
      end

      def search_by_email(identifier)
        if identifier.include? "@"
          @conditions << "users.email LIKE ?"
          @values << "%#{identifier}%"
        end
      end

      def search_by_name(identifier)
        if is_name?(identifier)
          @conditions << "CONCAT_WS(' ', users.name, users.last_name) LIKE ?"
          @values << "%#{identifier}%"
        end
      end

      def is_name?(identifier)
        !(/\A([\d|\.|-])+\z/ === identifier)
      end

      def search_with_conditions(order_attribute, order)
        conditions = @conditions.join(" OR ")
        Lead.includes(:user).where(conditions, *@values).order("leads.#{order_attribute} #{order}").references(:users).uniq
      end
    end
  end
end
