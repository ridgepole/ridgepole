describe 'Ridgepole::Client (with new text/blob types)' do
  context 'when use new types' do
    subject { client }

    it do
      delta = subject.diff(<<-RUBY)
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

      expect(delta.differ?).to be_truthy
      delta.migrate

      expect(subject.dump).to match_fuzzy erbh(<<-ERB)
        create_table "foos", id: :integer, unsigned: true, force: :cascade do |t|
          t.binary  "blob", <%= i cond(5.0, limit: 65535) %>
          t.blob    "tiny_blob", limit: 255
          t.binary  "medium_blob", limit: 16777215
          t.binary  "long_blob", limit: 4294967295
          t.text    "tiny_text", limit: 255
          t.text    "medium_text", limit: 16777215
          t.text    "long_text", limit: 4294967295
          t.decimal "unsigned_decimal", precision: 10, unsigned: true
          t.float   "unsigned_float", <%= i cond('< 5.2.0.beta2', limit: 24) %>, unsigned: true
          t.bigint  "unsigned_bigint", unsigned: true
          t.integer "unsigned_integer", unsigned: true
        end
      ERB
    end
  end

  context 'when compare new types' do
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
end
