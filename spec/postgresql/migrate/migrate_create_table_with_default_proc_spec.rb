describe 'Ridgepole::Client#diff -> migrate' do
  context 'when create table with default proc' do
    let(:dsl) { '' }

    let(:actual_dsl) {
      erbh(<<-EOS)
        create_table "users", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
          t.string   "name"
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
        end
      EOS
    }

    let(:expected_dsl) { dsl }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      expect(Ridgepole::Logger.instance).to_not receive(:warn)

      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy expected_dsl
    }
  end

  context 'when create table with default proc without change' do
    let(:dsl) {
      erbh(<<-EOS)
        create_table "users", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
          t.string   "name"
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
        end
      EOS
    }

    before { subject.diff(dsl).migrate }
    subject { client }

    it {
      expect(Ridgepole::Logger.instance).to_not receive(:warn)

      delta = subject.diff(dsl)
      expect(delta.differ?).to be_falsey
      expect(subject.dump).to match_fuzzy dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy dsl
    }
  end

  context 'when migrate table with default proc' do
    let(:actual_dsl) {
      erbh(<<-EOS)
        create_table "users", id: :uuid, default: -> { "uuid_generate_v1()" }, force: :cascade do |t|
          t.string   "name"
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
        end
      EOS
    }

    let(:expected_dsl) {
      erbh(<<-EOS)
        create_table "users", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
          t.string   "name"
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
        end
      EOS
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      expect(Ridgepole::Logger.instance).to receive(:warn).with("[WARNING] No difference of schema configuration for table `users` but table options differ.")
      expect(Ridgepole::Logger.instance).to receive(:warn).with(erbh(%Q!  from: {:id=>:uuid, :default=>"uuid_generate_v1()"}!))
      expect(Ridgepole::Logger.instance).to receive(:warn).with(erbh(%Q!    to: {:id=>:uuid, :default=>"uuid_generate_v4()"}!))

      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
      expect(subject.dump).to match_fuzzy actual_dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy actual_dsl
    }
  end
end
