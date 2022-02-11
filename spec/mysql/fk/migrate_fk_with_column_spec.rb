# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when create fk with column' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "direct_messages", id: :integer, force: :cascade do |t|
          t.integer "sender_id"
          t.integer "reciever_id"
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
          t.index ["reciever_id"], name: "index_direct_messages_on_reciever_id"
          t.index ["sender_id"], name: "index_direct_messages_on_sender_id"
        end

        create_table "users", id: :integer, force: :cascade do |t|
          t.string "email"
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(actual_dsl + <<-ERB)
        add_foreign_key "direct_messages", "users", column: "reciever_id"
        add_foreign_key "direct_messages", "users", column: "sender_id"
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
        add_foreign_key("direct_messages", "users", **{:column=>"reciever_id"})
        add_foreign_key("direct_messages", "users", **{:column=>"sender_id"})
      RUBY
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when drop fk  with column' do
    let(:actual_dsl) do
      erbh(expected_dsl + <<-ERB)
        add_foreign_key "direct_messages", "users", column: "reciever_id"
        add_foreign_key "direct_messages", "users", column: "sender_id"
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "direct_messages", id: :integer, force: :cascade do |t|
          t.integer "sender_id"
          t.integer "reciever_id"
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
          t.index ["reciever_id"], name: "index_direct_messages_on_reciever_id"
          t.index ["sender_id"], name: "index_direct_messages_on_sender_id"
        end

        create_table "users", id: :integer, force: :cascade do |t|
          t.string "email"
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }

    it {
      delta = client(bulk_change: true).diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl
      expect(delta.script).to match_fuzzy <<-RUBY
        remove_foreign_key("direct_messages", "users")
        remove_foreign_key("direct_messages", "users")
      RUBY
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when change fk with column' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "direct_messages", id: :integer, force: :cascade do |t|
          t.integer "sender_id"
          t.integer "reciever_id"
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
          t.index ["reciever_id"], name: "index_direct_messages_on_reciever_id"
          t.index ["sender_id"], name: "index_direct_messages_on_sender_id"
        end

        create_table "users", id: :integer, force: :cascade do |t|
          t.string "email"
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
        end

        add_foreign_key "direct_messages", "users", column: "reciever_id", on_delete: :cascade
        add_foreign_key "direct_messages", "users", column: "sender_id", on_delete: :cascade
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "direct_messages", id: :integer, force: :cascade do |t|
          t.integer "sender_id"
          t.integer "reciever_id"
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
          t.index ["reciever_id"], name: "index_direct_messages_on_reciever_id"
          t.index ["sender_id"], name: "index_direct_messages_on_sender_id"
        end

        create_table "users", id: :integer, force: :cascade do |t|
          t.string "email"
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
        end

        add_foreign_key "direct_messages", "users", column: "reciever_id"
        add_foreign_key "direct_messages", "users", column: "sender_id"
      ERB
    end

    before { subject.diff(actual_dsl).migrate }

    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end
end
