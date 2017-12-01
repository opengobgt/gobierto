# frozen_string_literal: true

module GobiertoAdmin
  module GobiertoCms
    class SectionItemSerializer < ActiveModel::Serializer
      attributes :id, :name, :children, :item_type

      def children
        object.children.sorted.map do |children|
          GobiertoAdmin::GobiertoCms::SectionItemSerializer.new(children)
        end
      end

      def name
        case object.item_type
          when "GobiertoModule"
            object.item_id
          else
            object.item.try(:title)
        end
      end
    end
  end
end
