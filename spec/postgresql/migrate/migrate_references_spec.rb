# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when use references (no change)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.<%= cond('>= 5.1','bigint', 'integer') %> "products_id"
          t.<%= cond('>= 5.1','bigint', 'integer') %> "user_id"
          t.index "products_id"
          t.index "user_id"
        end
      ERB
    end

    let(:expected_dsl) do
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.references :products, :user, index: true
        end
      RUBY
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
    }
  end

  context 'when use references with polymorphic (no change)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.<%= cond('>= 5.1','bigint', 'integer') %> "products_id"
          t.string "products_type"
          t.<%= cond('>= 5.1','bigint', 'integer') %> "user_id"
          t.string "user_type"
          t.index ["products_type", "products_id"]
          t.index ["user_type", "user_id"]
        end
      ERB
    end

    let(:expected_dsl) do
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.references :products, :user, index: true, polymorphic: true
        end
      RUBY
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
    }
  end

  context 'when use references with index false (no change)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.<%= cond('>= 5.1','bigint', 'integer') %> "products_id"
          t.<%= cond('>= 5.1','bigint', 'integer') %> "user_id"
        end
      ERB
    end

    let(:expected_dsl) do
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.references :products, :user, index: false
        end
      RUBY
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
    }
  end
end
