# frozen_string_literal: true

describe 'Ridgepole::Client (with new text/blob types)' do
  context 'when use new types' do
    subject { client }

    it do
      table_def = <<-RUBY
        create_table :foos, id: :unsigned_integer do |t|
          t.blob             :blob
          t.tinyblob         :tiny_blob
          t.mediumblob       :medium_blob
          t.longblob         :long_blob
          t.tinytext         :tiny_text
          t.mediumtext       :medium_text
          t.longtext         :long_text
          t.unsigned_decimal :unsigned_decimal
          t.unsigned_float   :unsigned_float
          t.unsigned_bigint  :unsigned_bigint
          t.unsigned_integer :unsigned_integer
        end
      RUBY
      delta = subject.diff(table_def)

      expect(delta.differ?).to be_truthy
      delta.migrate

      expect(subject.dump).to match_ruby erbh(<<-ERB)
        create_table "foos", id: :integer, unsigned: true, force: :cascade do |t|
          t.binary  "blob", <%= i cond(5.0, limit: 65535) %>
          t.<%= cond('< 6.0.0.beta2', :blob, :binary) %> "tiny_blob", <%= i cond('< 6.0.0.beta2', {limit: 255}, {size: :tiny}) %>
          t.binary  "medium_blob", <%= i cond('< 6.0.0.beta2', {limit: 16777215}, {size: :medium}) %>
          t.binary  "long_blob", <%= i cond('< 6.0.0.beta2', {limit: 4294967295}, {size: :long}) %>
          t.text    "tiny_text", <%= i cond('< 6.0.0.beta2', {limit: 255}, {size: :tiny}) %>
          t.text    "medium_text", <%= i cond('< 6.0.0.beta2', {limit: 16777215}, {size: :medium}) %>
          t.text    "long_text", <%= i cond('< 6.0.0.beta2', {limit: 4294967295}, {size: :long}) %>
          t.decimal "unsigned_decimal", precision: 10, unsigned: true
          t.float   "unsigned_float", <%= i cond('< 5.2.0.beta2', limit: 24) %>, unsigned: true
          t.bigint  "unsigned_bigint", unsigned: true
          t.integer "unsigned_integer", unsigned: true
        end
      ERB

      expect(subject.diff(table_def).differ?).to be_falsey
    end
  end

  context 'when compare new types', condition: '< 6.0.0.beta2' do
    subject { client }

    before do
      subject.diff(<<-RUBY).migrate
        create_table :foos do |t|
          t.blob             :blob
          t.tinyblob         :tiny_blob
          t.mediumblob       :medium_blob
          t.longblob         :long_blob
          t.tinytext         :tiny_text
          t.mediumtext       :medium_text
          t.longtext         :long_text
          t.unsigned_decimal :unsigned_decimal
          t.unsigned_float   :unsigned_float
          t.unsigned_bigint  :unsigned_bigint
          t.unsigned_integer :unsigned_integer
        end
      RUBY
    end

    it do
      delta = subject.diff(<<-RUBY)
        create_table :foos do |t|
          t.blob             :blob
          t.tinyblob         :tiny_blob
          t.mediumblob       :medium_blob
          t.longblob         :long_blob
          t.tinytext         :tiny_text
          t.mediumtext       :medium_text
          t.longtext         :long_text
          t.unsigned_decimal :unsigned_decimal
          t.unsigned_float   :unsigned_float
          t.unsigned_bigint  :unsigned_bigint
          t.unsigned_integer :unsigned_integer
        end
      RUBY

      expect(delta.differ?).to be_falsey
    end
  end

  context 'when compare new types', condition: '>= 6.0.0.beta2' do
    subject { client }

    before do
      subject.diff(<<-RUBY).migrate
        create_table "foos", force: :cascade do |t|
          t.binary "blob"
          t.binary "tiny_blob", size: :tiny
          t.binary "medium_blob", size: :medium
          t.binary "long_blob", size: :long
          t.text "tiny_text", size: :tiny
          t.text "medium_text", size: :medium
          t.text "long_text", size: :long
          t.decimal "unsigned_decimal", precision: 10, unsigned: true
          t.float "unsigned_float", unsigned: true
          t.bigint "unsigned_bigint", unsigned: true
          t.integer "unsigned_integer", unsigned: true
        end
      RUBY
    end

    it do
      delta = subject.diff(<<-RUBY)
        create_table "foos", force: :cascade do |t|
          t.binary "blob"
          t.binary "tiny_blob", size: :tiny
          t.binary "medium_blob", size: :medium
          t.binary "long_blob", size: :long
          t.text "tiny_text", size: :tiny
          t.text "medium_text", size: :medium
          t.text "long_text", size: :long
          t.decimal "unsigned_decimal", precision: 10, unsigned: true
          t.float "unsigned_float", unsigned: true
          t.bigint "unsigned_bigint", unsigned: true
          t.integer "unsigned_integer", unsigned: true
        end
      RUBY

      expect(delta.differ?).to be_falsey
    end
  end
end
