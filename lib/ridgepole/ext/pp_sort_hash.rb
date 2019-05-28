# frozen_string_literal: true

module Ridgepole
  module Ext
    module PpSortHash
      def pretty_print(pp_obj)
        pp_obj.group(1, '{', '}') do
          pp_obj.seplist(sort_by { |k, _| k.to_s }, nil, :each) do |k, v|
            v = PpSortHash.extend_if_hash(v)

            pp_obj.group do
              pp_obj.pp k
              pp_obj.text '=>'
              pp_obj.group(1) do
                pp_obj.breakable ''
                pp_obj.pp v
              end
            end
          end
        end
      end

      def self.extend_if_hash(obj)
        if obj.is_a?(Hash)
          obj = obj.dup
          obj.extend(self)
        end

        obj
      end
    end
  end
end
