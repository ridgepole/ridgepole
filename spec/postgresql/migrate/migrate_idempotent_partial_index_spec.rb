# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  let(:dsl) do
    erbh(<<-ERB)
      create_table "clubs", id: :serial, force: :cascade do |t|
        t.string "name", limit: 255, default: "", null: false
        t.datetime "deleted_at"
        t.index ["name"], name: "idx_name", unique: true
        t.index ["name"], name: "idx_name_not_deleted", where: "(deleted_at IS NULL)"
      end
    ERB
  end

  let(:dsl_without_parens) do
    erbh(<<-ERB)
      create_table "clubs", id: :serial, force: :cascade do |t|
        t.string "name", limit: 255, default: "", null: false
        t.datetime "deleted_at"
        t.index ["name"], name: "idx_name", unique: true
        t.index ["name"], name: "idx_name_not_deleted", where: "deleted_at IS NULL"
      end
    ERB
  end

  before { subject.diff(dsl).migrate }
  subject { client }

  it 'should not detect diff when WHERE clause has parentheses' do
    delta = subject.diff(dsl)
    expect(delta.differ?).to be_falsey
  end

  it 'should not detect diff when WHERE clause omits parentheses' do
    delta = subject.diff(dsl_without_parens)
    expect(delta.differ?).to be_falsey
  end

  it 'should not corrupt WHERE clause where parentheses do not wrap entire expression' do
    # "(a) OR (b)" style should not be stripped
    dsl_partial_parens = erbh(<<-ERB)
      create_table "clubs", id: :serial, force: :cascade do |t|
        t.string "name", limit: 255, default: "", null: false
        t.integer "status", default: 0, null: false
        t.datetime "deleted_at"
        t.index ["name"], name: "idx_name", unique: true
        t.index ["name"], name: "idx_name_conditional", where: "(status = 1) OR (deleted_at IS NULL)"
      end
    ERB
    subject.diff(dsl_partial_parens).migrate
    delta = subject.diff(dsl_partial_parens)
    expect(delta.differ?).to be_falsey
  end
end
