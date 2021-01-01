# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  before { subject.diff(actual_dsl).migrate }
  subject { client(table_options: table_options, table_hash_options: table_hash_options, dump_without_table_options: dump_without_table_options) }

  let(:warning_regexp) { /Table option changes are ignored/ }
  let(:dump_without_table_options) { false }
  let(:table_options) { nil }
  let(:table_hash_options) { {} }

  let(:actual_dsl) do
    erbh(<<-ERB)
      create_table "employees", primary_key: "emp_no", force: :cascade, <%= i cond('>= 6.1', { charset: 'utf8' }, { options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8' }) %> do |t|
      end
    ERB
  end

  let(:expected_dsl) do
    erbh(<<-ERB)
      create_table :employees, primary_key: :emp_no, force: :cascade do |t|
      end
    ERB
  end

  context 'when change options (no change)', condition: '< 6.1' do
    let(:table_options) { 'ENGINE=InnoDB DEFAULT CHARSET=utf8' }

    it {
      expect(Ridgepole::Logger.instance).to_not receive(:warn).with(warning_regexp)
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
    }
  end

  context 'when change options (change)', condition: '< 6.1' do
    let(:table_options) { 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4' }

    it {
      expect(Ridgepole::Logger.instance).to receive(:warn).with(warning_regexp)
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
    }
  end

  context 'when dump_without_table_options => true', condition: '< 6.1' do
    let(:table_options) { 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4' }
    let(:dump_without_table_options) { true }

    it {
      expect(Ridgepole::Logger.instance).to_not receive(:warn)
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
    }
  end

  context 'when change options (no change)', condition: '>= 6.1' do
    let(:table_hash_options) { { charset: 'utf8' } }

    it {
      expect(Ridgepole::Logger.instance).to_not receive(:warn).with(warning_regexp)
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
    }
  end

  context 'when change options (change)', condition: '>= 6.1' do
    let(:table_hash_options) { { charset: 'utf8mb4' } }

    it {
      expect(Ridgepole::Logger.instance).to receive(:warn).with(warning_regexp)
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
    }
  end

  context 'when dump_without_table_options => true', condition: '>= 6.1' do
    let(:table_hash_options) { { charset: 'utf8mb4' } }
    let(:dump_without_table_options) { true }

    it {
      expect(Ridgepole::Logger.instance).to_not receive(:warn)
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
    }
  end
end
