# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when drop column and unique index' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.index ["first_name", "last_name"], name: "first_name_last_name", unique: true, <%= i cond(5.0, using: :btree) %>
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.string "first_name", limit: 14, null: false
        end
      ERB
    end

    before do
      subject.diff(actual_dsl).migrate
      ActiveRecord::Base.connection.execute(<<-'SQL'
        insert into
          employees (first_name, last_name)
        values
          ('Taro', 'Yamada'), ('Taro', 'Sato')
        ;
      SQL
                                           )
    end
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate(noop: true)
      expect(subject.dump).to match_ruby actual_dsl
    }
  end
end
