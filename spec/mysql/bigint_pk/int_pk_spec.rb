# frozen_string_literal: true

describe 'Ridgepole::Client (with integer pk)' do
  context 'when with id:integer' do
    let(:dsl) do
      erbh(<<-ERB)
        create_table "books", id: :integer, force: :cascade do |t|
          t.string   "title", null: false
          t.integer  "author_id", null: false
          t.datetime "created_at", <%= i cond(">= 7.0", { precision: 6 }) %>
          t.datetime "updated_at", <%= i cond(">= 7.0", { precision: 6 }) %>
        end
      ERB
    end

    subject { client }

    before { subject.diff(dsl).migrate }

    specify do
      expect(show_create_table(:books)).to include '`id` int NOT NULL AUTO_INCREMENT'
      expect(subject.dump).to match_ruby dsl
    end
  end

  context 'when without id:integer' do
    let(:dsl) do
      erbh(<<-ERB)
        create_table "books", force: :cascade do |t|
          t.string   "title", null: false
          t.integer  "author_id", null: false
          t.datetime "created_at", <%= i cond(">= 7.0", { precision: 6 }) %>
          t.datetime "updated_at", <%= i cond(">= 7.0", { precision: 6 }) %>
        end
      ERB
    end

    subject { client }

    before { subject.diff(dsl).migrate }

    specify do
      expect(show_create_table(:books)).to include '`id` bigint NOT NULL AUTO_INCREMENT'
      expect(subject.dump).to match_ruby dsl
    end
  end
end
