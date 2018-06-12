module Ridgepole
  module Ext
    module PpSortHash
      def pretty_print(q)
        q.group(1, '{', '}') do
          q.seplist(sort_by { |k, _| k.to_s }, nil, :each) do |k, v|
            v = PpSortHash.extend_if_hash(v)

            q.group do
              q.pp k
              q.text '=>'
              q.group(1) do
                q.breakable ''
                q.pp v
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
