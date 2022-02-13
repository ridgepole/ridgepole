# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when add virtual column', condition: %i[mysql57 mysql80] do
    let(:actual_dsl) do
      <<-RUBY
        create_table "books", force: :cascade do |t|
          t.string  "title"
          t.index ["title"], name: "index_books_on_title"
        end
      RUBY
    end

    let(:expected_dsl) do
      <<-RUBY
        create_table "books", force: :cascade do |t|
          t.string   "title"
          t.virtual  "upper_title", type: :string, as: "upper(`title`)"
          t.virtual  "title_length", type: :integer, as: "length(`title`)", stored: true
          t.index ["title"], name: "index_books_on_title"
          t.index ["title_length"], name: "index_books_on_title_length"
        end
      RUBY
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      expect(Ridgepole::Logger.instance).to_not receive(:warn)
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }

    context 'when generated column has extra white spaces' do
      let(:expected_dsl) do
        <<-RUBY
        create_table "books", force: :cascade do |t|
          t.string   "title"
          t.string   "sub_title"
          t.virtual  "full_title", type: :string, as: "concat(`title`, ' ', `sub_title`)"
          t.index ["title"], name: "index_books_on_title"
        end
        RUBY
      end
      let(:delta) { subject.diff(expected_dsl) }
      it {
        expect(Ridgepole::Logger.instance).to_not receive(:warn)
        expect(delta.differ?).to be_truthy
        expect(subject.dump).to match_ruby actual_dsl
        expect { delta.migrate }.not_to raise_error
        expect(subject.dump).to match_ruby expected_dsl.sub("concat(`title`, ' ', `sub_title`)", "concat(`title`,' ',`sub_title`)")
        expect(subject.dump).not_to match_ruby expected_dsl
      }
      context 'migrated again without change' do
        before { subject.diff(expected_dsl).migrate }
        it {
          expect(Ridgepole::Logger.instance).to receive(:warn).with(<<-MSG)
[WARNING] Same expressions but only differed by white spaces were detected. This operation may fail.
  Before: 'concat(`title`,' ',`sub_title`)'
  After : 'concat(`title`, ' ', `sub_title`)'
          MSG
          expect(delta.differ?).to be_truthy # because of white spaces
          expect(subject.dump).to match_ruby expected_dsl.sub("concat(`title`, ' ', `sub_title`)", "concat(`title`,' ',`sub_title`)")
          expect(subject.dump).not_to match_ruby expected_dsl
          expect { delta.migrate }.to raise_error(RuntimeError)
        }
      end
    end
  end
end
