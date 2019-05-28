# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'with verbose log' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   "hire_date", null: false
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender2", limit: 1, null: false
          t.date   "hire_date", null: false
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      verbose_infos = []
      allow(Ridgepole::Logger.instance).to receive(:verbose_info) { |m| verbose_infos << m }

      Ridgepole::Logger.verbose = true
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
      Ridgepole::Logger.verbose = false

      expected_verbose_infos = [
        '# Parse DSL',
        '# Load tables',
        '#   employees',
        '# Compare definitions',
        '#   employees',
        " {:definition=>\n   {\"birth_date\"=>{:options=>{:null=>false}, :type=>:date},\n    \"first_name\"=>{:options=>{:limit=>14, :null=>false}, :type=>:string},\n-   \"gender\"=>{:options=>{:limit=>1, :null=>false}, :type=>:string},\n+   \"gender2\"=>{:options=>{:limit=>1, :null=>false}, :type=>:string},\n    \"hire_date\"=>{:options=>{:null=>false}, :type=>:date},\n    \"last_name\"=>{:options=>{:limit=>16, :null=>false}, :type=>:string}},\n  :options=>{:primary_key=>\"emp_no\"}}",
        '# Load tables',
        '#   employees',
        '# Load tables',
        '#   employees'
      ]

      expect(verbose_infos).to match_array expected_verbose_infos
    }
  end
end
