describe 'Ridgepole::Client#dump', condition: [:mysql_awesome_enabled, :activerecord_5] do
  let(:template_variables) {
    opts = {
      table_comment: {comment: '"london" bridge "is" falling "down"'},
    }

    if condition(:activerecord_4)
      opts.merge!(
        table_comment: {}
      )
    end

    opts
  }

  let(:actual_dsl) {
    erbh(<<-'EOS', template_variables)
      create_table "books", unsigned: true, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='\"london\" bridge \"is\" falling \"down\"'" do |t|
        t.string   "title",      <%= i limit(255) + {null: false} %>
        t.integer  "author_id",  <%= i limit(4) + {null: false} %>
        t.datetime "created_at"
        t.datetime "updated_at"
      end
    EOS
  }

  context 'when without table options' do
    let(:expected_dsl) {
      erbh(<<-EOS, template_variables)
        create_table "books", <%= i({unsigned: true, force: :cascade} + @table_comment) %> do |t|
          t.string   "title",      <%= i limit(255) + {null: false} %>
          t.integer  "author_id",  <%= i limit(4) + {null: false} %>
          t.datetime "created_at"
          t.datetime "updated_at"
        end
      EOS
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      expect(subject.dump).to match_fuzzy expected_dsl
    }
  end

  context 'when with table options' do
    before { subject.diff(actual_dsl).migrate }
    subject { client(dump_without_table_options: false) }

    it {
      if condition(:activerecord_5)
        skip
      else
        expect(subject.dump).to match_fuzzy actual_dsl
      end
    }
  end
end
