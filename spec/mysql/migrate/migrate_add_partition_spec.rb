# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when add list partition' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "list_partitions", id: false, force: :cascade do |t|
          t.integer "id", null: false
          t.date "logdate", null: false
        end
        add_partition "list_partitions", :list, [:id], partition_definitions: [{ name: "list_partitions_p0", values: {:in=>[1]} }]
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "list_partitions", id: false, force: :cascade do |t|
          t.integer "id", null: false
          t.date "logdate", null: false
        end
        add_partition "list_partitions", :list, [:id], partition_definitions: [{ name: "list_partitions_p0", values: {:in=>[1]} } ,{ name: "list_partitions_p1", values: {:in=>[2, 3]} }]
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
        add_partition "list_partitions", name: "list_partitions_p1", values: {:in=>[2, 3]}
      RUBY
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when add range partition' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "range_partitions", primary_key: ["id", "logdate"], force: :cascade do |t|
          t.integer "id", null: false
          t.date "logdate", null: false
        end
        add_partition "range_partitions", :range, [:logdate], partition_definitions: [{ name: "p0", values: {:to=>["2021-01-01"]} }]
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "range_partitions", primary_key: ["id", "logdate"], force: :cascade do |t|
          t.integer "id", null: false
          t.date "logdate", null: false
        end
        add_partition "range_partitions", :range, [:logdate], partition_definitions: [{ name: "p0", values: {:to=>["2021-01-01"]} }, {name: "p1", values: {:to=>["2022-01-01"]} }]
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
        add_partition "range_partitions", name: "p1", values: {:to=>["2022-01-01"]}
      RUBY
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when add list partition with multiple columns' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "list_partitions", primary_key: ["id", "name"], force: :cascade do |t|
          t.integer "id", null: false
          t.string "name", null: false
        end
        add_partition "list_partitions", :list, [:id, :name], partition_definitions: [{ name: "list_partitions_p0", values: {:in=>[[1, "a"]]} }]
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "list_partitions", primary_key: ["id", "name"], force: :cascade do |t|
          t.integer "id", null: false
          t.string "name", null: false
        end
        add_partition "list_partitions", :list, [:id, :name], partition_definitions: [{ name: "list_partitions_p0", values: {:in=>[[1, "a"]]} } ,{ name: "list_partitions_p1", values: {:in=>[[2, "b"], [3, "c"]]} }]
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
        add_partition "list_partitions", name: "list_partitions_p1", values: {:in=>[[2, "b"], [3, "c"]]}
      RUBY
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when add range partition with multiple columns' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "range_partitions", primary_key: ["id", "logdate"], force: :cascade do |t|
          t.integer "id", null: false
          t.date "logdate", null: false
        end
        add_partition "range_partitions", :range, [:id, :logdate], partition_definitions: [{ name: "p0", values: {:to=>[1, "2021-01-01"]} }]
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "range_partitions", primary_key: ["id", "logdate"], force: :cascade do |t|
          t.integer "id", null: false
          t.date "logdate", null: false
        end
        add_partition "range_partitions", :range, [:id, :logdate], partition_definitions: [{ name: "p0", values: {:to=>[1, "2021-01-01"]} }, {name: "p1", values: {:to=>[2, "2022-01-01"]} }]
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
        add_partition "range_partitions", name: "p1", values: {:to=>[2, "2022-01-01"]}
      RUBY
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end
end
