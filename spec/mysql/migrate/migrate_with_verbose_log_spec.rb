describe 'Ridgepole::Client#diff -> migrate' do
  context 'with verbose log' do
    let(:actual_dsl) {
      erbh(<<-EOS)
        create_table "employees", primary_key: "emp_no", <%= i unsigned(true) + {force: :cascade} %> do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end
      EOS
    }

    let(:expected_dsl) {
      erbh(<<-EOS)
        create_table "employees", primary_key: "emp_no", <%= i unsigned(true) + {force: :cascade} %> do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender2",    limit: 1,  null: false
          t.date   "hire_date",             null: false
        end
      EOS
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      verbose_infos = []
      allow(Ridgepole::Logger.instance).to receive(:verbose_info) {|m| verbose_infos << m }

      Ridgepole::Logger.verbose = true
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy expected_dsl
      Ridgepole::Logger.verbose = false

      expected_verbose_infos = [
        "# Parse DSL",
        "# Load tables",
        "#   employees",
        "# Compare definitions",
        "#   employees",
        "# Load tables",
        "#   employees",
        "# Load tables",
        "#   employees",
      ]


      if condition(:mysql_awesome_enabled)
        expected_verbose_infos << "   {\"birth_date\"=>{:type=>:date, :options=>{:null=>false}},\n    \"first_name\"=>{:type=>:string, :options=>{:limit=>14, :null=>false}},\n    \"last_name\"=>{:type=>:string, :options=>{:limit=>16, :null=>false}},\n-   \"gender\"=>{:type=>:string, :options=>{:limit=>1, :null=>false}},\n+   \"gender2\"=>{:type=>:string, :options=>{:limit=>1, :null=>false}},\n    \"hire_date\"=>{:type=>:date, :options=>{:null=>false}}},\n  :options=>{:primary_key=>\"emp_no\", :unsigned=>true}}"
      else
        expected_verbose_infos << "   {\"birth_date\"=>{:type=>:date, :options=>{:null=>false}},\n    \"first_name\"=>{:type=>:string, :options=>{:limit=>14, :null=>false}},\n    \"last_name\"=>{:type=>:string, :options=>{:limit=>16, :null=>false}},\n-   \"gender\"=>{:type=>:string, :options=>{:limit=>1, :null=>false}},\n+   \"gender2\"=>{:type=>:string, :options=>{:limit=>1, :null=>false}},\n    \"hire_date\"=>{:type=>:date, :options=>{:null=>false}}},\n  :options=>{:primary_key=>\"emp_no\"}}"
      end

      expect(verbose_infos).to match_array expected_verbose_infos
    }
  end
end
