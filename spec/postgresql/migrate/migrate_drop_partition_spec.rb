# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate', condition: '>= 6.0' do
  after { drop_tables }

  context 'when delete partition' do
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

  context 'when delete default partition' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "list_partitions", id: false, force: :cascade, options: "PARTITION BY LIST(id)"  do |t|
          t.integer "id", null: false
          t.date "logdate", null: false
        end
        add_partition "list_partitions", :list, [:id], partition_definitions: [{ name: "list_partitions_default", values: {:default=>true} }, { name: "list_partitions_p0", values: {:in=>[1]} }]
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
        remove_partition "list_partitions", name: "list_partitions_default"
      RUBY
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when delete hash partition' do
    let(:actual_dsl) do
      erbh(<<-ERB)
      create_table "hash_partitions", id: false, force: :cascade, options: "PARTITION BY HASH(id)" do |t|
        t.integer "id", null: false
        t.date "logdate", null: false
      end
      add_partition "hash_partitions", :hash, [:id], partition_definitions: [{ name: "p0", values: {:modulus=>3, :remainder=>0} }, { name: "p1", values: {:modulus=>3, :remainder=>1} }]
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
      create_table "hash_partitions", id: false, force: :cascade, options: "PARTITION BY HASH(id)" do |t|
        t.integer "id", null: false
        t.date "logdate", null: false
      end
      add_partition "hash_partitions", :hash, [:id], partition_definitions: [{ name: "p0", values: {:modulus=>3, :remainder=>0} }]
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
        remove_partition "hash_partitions", name: "p1"
      RUBY
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end
end
