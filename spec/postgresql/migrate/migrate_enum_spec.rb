# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate', condition: '>= 7.0' do
  context 'create table with enum' do
    let(:actual_dsl) do
      ''
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "person", force: :cascade do |t|
          t.text "name"
          t.enum "current_mood", enum_type: "mood"
        end
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
  end

  context 'add enum column with enum' do
    let(:actual_dsl) do
      <<~RUBY
        create_table "person", force: :cascade do |t|
          t.text "name"
        end
      RUBY
    end

    let(:expected_dsl) do
      <<~RUBY
        create_table "person", force: :cascade do |t|
          t.text "name"
          t.enum "current_mood", enum_type: "mood"
        end
      RUBY
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
  end

  context 'drop enum column with enum' do
    let(:actual_dsl) do
      <<~RUBY
        create_table "person", force: :cascade do |t|
          t.text "name"
          t.enum "current_mood", enum_type: "mood"
        end
      RUBY
    end

    let(:expected_dsl) do
      <<~RUBY
        create_table "person", force: :cascade do |t|
          t.text "name"
        end
      RUBY
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
  end

  context 'change enum column to not null' do
    let(:actual_dsl) do
      <<~RUBY
        create_table "person", force: :cascade do |t|
          t.text "name"
          t.enum "current_mood", enum_type: "mood"
        end
      RUBY
    end

    let(:expected_dsl) do
      <<~RUBY
        create_table "person", force: :cascade do |t|
          t.text "name"
          t.enum "current_mood", enum_type: "mood", null: false
        end
      RUBY
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
  end

  context 'change enum column to nullable' do
    let(:actual_dsl) do
      <<~RUBY
        create_table "person", force: :cascade do |t|
          t.text "name"
          t.enum "current_mood", enum_type: "mood", null: false
        end
      RUBY
    end

    let(:expected_dsl) do
      <<~RUBY
        create_table "person", force: :cascade do |t|
          t.text "name"
          t.enum "current_mood", enum_type: "mood", null: true
        end
      RUBY
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl.sub(', null: true', '')
    }
  end
end
