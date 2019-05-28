# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when change float column' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.float   "salary", limit: 24, null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end
      ERB
    end

    let(:expected_dsl) do
      <<-RUBY
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.float   "salary", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end
      RUBY
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client(default_float_limit: 0) }

    it {
      delta = subject.diff(expected_dsl)

      if condition('< 5.2.0.beta2')
        expect(delta.differ?).to be_truthy
        expect(subject.dump).to match_ruby actual_dsl
        delta.migrate
        expect(subject.dump).to match_ruby actual_dsl
      else
        expect(delta.differ?).to be_falsy
      end
    }
  end

  context 'when change float column (no change)' do
    let(:actual_dsl) do
      <<-RUBY
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.float   "salary", limit: 24, null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end
      RUBY
    end

    let(:expected_dsl) do
      <<-RUBY
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.float   "salary", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
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
