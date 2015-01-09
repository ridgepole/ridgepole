if mysql_awesome_enabled?
  describe 'Ridgepole::Client (with bigint pk)' do
    let(:dsl) {
      <<-RUBY
        create_table "books", id: :primary_key, limit: 8, force: true do |t|
          t.string   "title",      null: false
          t.integer  "author_id",  null: false
          t.datetime "created_at"
          t.datetime "updated_at"
        end
      RUBY
    }

    context 'when dump with activerecord-mysql-pkdump' do
      subject { client }

      before { subject.diff(dsl).migrate }

      it {
        expect(show_create_table(:books)).to include '`id` bigint(20) unsigned NOT NULL AUTO_INCREMENT'
      }
    end
  end
end
