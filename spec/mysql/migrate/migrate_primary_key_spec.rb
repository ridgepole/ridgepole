# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  let(:actual_dsl) do
    erbh(<<-ERB)
      create_table "employees", <%= i cond(">= 6.1", { id: { type: :integer, unsigned: true } }, { id: :integer, unsigned: true }) %>, force: :cascade do |t|
      end
    ERB
  end

  before { subject.diff(actual_dsl).migrate }
  subject { client(allow_pk_change: allow_pk_change) }

  context 'when allow_pk_change option is false' do
    let(:allow_pk_change) { false }

    context 'with difference' do
      let(:expected_dsl) do
        erbh(<<-ERB)
          create_table "employees", id: :bigint, unsigned: true, force: :cascade do |t|
          end
        ERB
      end

      it {
        expect(Ridgepole::Logger.instance).to receive(:warn).with(erbh(<<-ERB))
[WARNING] Primary key definition of `employees` differ but `allow_pk_change` option is false
  from: <%= i cond(">= 6.1", "{:id=>{:type=>:integer, :unsigned=>true}}", "{:id=>:integer, :unsigned=>true}") %>
    to: {:id=>:bigint, :unsigned=>true}
        ERB

        delta = subject.diff(expected_dsl)
        expect(delta.differ?).to be_falsey
        delta.migrate
        expect(subject.dump).to match_ruby actual_dsl
      }
    end

    context 'with no difference' do
      let(:actual_dsl) do
        erbh(<<-ERB)
          create_table "employees", unsigned: true, force: :cascade do |t|
          end
        ERB
      end
      let(:expected_dsl) { actual_dsl }

      it {
        expect(Ridgepole::Logger.instance).to_not receive(:warn)

        delta = subject.diff(expected_dsl)
        expect(delta.differ?).to be_falsey
      }
    end
  end

  context 'when allow_pk_change option is true' do
    let(:allow_pk_change) { true }
    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "employees", <%= i cond(">= 6.1", { id: { type: :bigint, unsigned: true } }, { id: :bigint, unsigned: true }) %>, force: :cascade do |t|
        end

        create_table "salaries", force: :cascade do |t|
          t.bigint "employee_id", null: false, unsigned: true
          t.index ["employee_id"], name: "fk_salaries_employees"
        end
        add_foreign_key "salaries", "employees", name: "fk_salaries_employees"
      ERB
    end

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when deafult: nil' do
    let(:allow_pk_change) { true }

    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "foo", id: :integer, unsigned: true, default: nil, force: :cascade do |t|
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "foo", id: :integer, default: nil, force: :cascade do |t|
        end
      ERB
    end

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end
end
