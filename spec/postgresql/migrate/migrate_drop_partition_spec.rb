# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate', condition: '>= 6.0' do
  context 'when add partition' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "list_partitions", id: false, force: :cascade, options: "PARTITION BY LIST(id)"  do |t|
          t.integer "id", null: false
          t.date "logdate", null: false
        end
        add_partition "list_partitions", :list, [:id], partition_definitions: [{ name: "list_partitions_p0", values: {:in=>[1]} } ,{ name: "list_partitions_p1", values: {:in=>[2, 3]} }]
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "list_partitions", id: false, force: :cascade, options: "PARTITION BY LIST(id)"  do |t|
          t.integer "id", null: false
          t.date "logdate", null: false
        end
        add_partition "list_partitions", :list, [:id], partition_definitions: [{ name: "list_partitions_p0", values: {:in=>[1]} }]
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }

    it {
      delta = client(bulk_change: true).diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      expect(delta.script).to match_fuzzy <<-RUBY
        remove_partition "list_partitions", name: "list_partitions_p1"
      RUBY
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end
end
