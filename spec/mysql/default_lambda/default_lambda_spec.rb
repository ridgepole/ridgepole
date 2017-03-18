describe 'Ridgepole::Client (use default:lambda)' do
  context 'when create table with default:lambda' do
    subject { client }

    it do
      delta = subject.diff(<<-EOS)
        create_table "foos", force: :cascade do |t|
          t.datetime "bar", default: -> { "CURRENT_TIMESTAMP" }, null: false
        end
      EOS

      expect(delta.differ?).to be_truthy
      delta.migrate

      expect(subject.dump).to match_fuzzy <<-EOS
        create_table "foos", force: :cascade do |t|
          t.datetime "bar", default: -> { "CURRENT_TIMESTAMP" }, null: false
        end
      EOS
    end
  end

  context 'when there is no difference' do
    let(:dsl) do
      <<-EOS
        create_table "foos", force: :cascade do |t|
          t.datetime "bar", default: -> { "CURRENT_TIMESTAMP" }, null: false
        end
      EOS
    end

    subject { client }

    before do
      subject.diff(dsl).migrate
    end

    it do
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_falsey
    end
  end

  context 'when change column (1)' do
    subject { client }

    before do
      subject.diff(<<-EOS).migrate
        create_table "foos", force: :cascade do |t|
          t.datetime "bar", default: -> { "CURRENT_TIMESTAMP" }, null: false
        end
      EOS
    end

    it do
      delta = subject.diff(<<-EOS)
        create_table "foos", force: :cascade do |t|
          t.datetime "bar", default: -> { '"1970-01-01 00:00:00"' }, null: false
        end
      EOS

      expect(delta.differ?).to be_truthy
      delta.migrate

      expect(subject.dump).to match_fuzzy erbh(<<-EOS)
        create_table "foos", force: :cascade do |t|
          t.datetime "bar", default: <%= cond('5.1', '"1970-01-01 00:00:00"', "'1970-01-01 00:00:00'") %>, null: false
        end
      EOS
    end
  end

  context 'when change column (2)' do
    subject { client }

    before do
      subject.diff(<<-EOS).migrate
        create_table "foos", force: :cascade do |t|
          t.datetime "bar", default: '1970-01-01 00:00:00', null: false
        end
      EOS
    end

    it do
      delta = subject.diff(<<-EOS)
        create_table "foos", force: :cascade do |t|
          t.datetime "bar", default: -> { "CURRENT_TIMESTAMP" }, null: false
        end
      EOS

      expect(delta.differ?).to be_truthy
      delta.migrate

      expect(subject.dump).to match_fuzzy <<-EOS
        create_table "foos", force: :cascade do |t|
          t.datetime "bar", default: -> { "CURRENT_TIMESTAMP" }, null: false
        end
      EOS
    end
  end

  context 'when add column' do
    subject { client }

    before do
      subject.diff(<<-EOS).migrate
        create_table "foos", force: :cascade do |t|
          t.integer "zoo"
        end
      EOS
    end

    it do
      delta = subject.diff(<<-EOS)
        create_table "foos", force: :cascade do |t|
          t.datetime "bar", default: -> { "CURRENT_TIMESTAMP" }, null: false
          t.integer "zoo"
        end
      EOS

      expect(delta.differ?).to be_truthy
      delta.migrate

      expect(subject.dump).to match_fuzzy <<-EOS
        create_table "foos", force: :cascade do |t|
          t.datetime "bar", default: -> { "CURRENT_TIMESTAMP" }, null: false
          t.integer "zoo"
        end
      EOS
    end
  end

  context 'when drop column' do
    subject { client }

    before do
      subject.diff(<<-EOS).migrate
        create_table "foos", force: :cascade do |t|
          t.datetime "bar", default: -> { "CURRENT_TIMESTAMP" }, null: false
          t.integer "zoo"
        end
      EOS
    end

    it do
      delta = subject.diff(<<-EOS)
        create_table "foos", force: :cascade do |t|
          t.integer "zoo"
        end
      EOS

      expect(delta.differ?).to be_truthy
      delta.migrate

      expect(subject.dump).to match_fuzzy <<-EOS
        create_table "foos", force: :cascade do |t|
          t.integer "zoo"
        end
      EOS
    end
  end
end
