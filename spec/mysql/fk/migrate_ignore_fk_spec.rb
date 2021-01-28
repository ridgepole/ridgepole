# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when create fk with ignore:true' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id"
        end

        create_table "parent", id: :integer, force: :cascade do |t|
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(actual_dsl + <<-ERB)
        add_foreign_key "child", "parent", name: "child_ibfk_1", ignore: true
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
    }
  end

  context 'when change fk with ignore:true' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "parent", id: :integer, force: :cascade do |t|
        end

        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id"
        end

        add_foreign_key "child", "parent", name: "child_ibfk_1", on_delete: :cascade
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id"
        end

        create_table "parent", id: :integer, force: :cascade do |t|
        end

        add_foreign_key "child", "parent", name: "child_ibfk_1", ignore: true
      ERB
    end

    before { subject.diff(actual_dsl).migrate }

    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
    }
  end
end
