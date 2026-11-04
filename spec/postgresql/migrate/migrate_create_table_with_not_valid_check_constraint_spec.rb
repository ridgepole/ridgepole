# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  def convalidated(name)
    ActiveRecord::Base.connection.select_value(<<~SQL)
      SELECT convalidated FROM pg_constraint WHERE conname = #{ActiveRecord::Base.connection.quote(name)}
    SQL
  end

  # Rails does not dump `validate: false` for check constraints before 7.1
  def dump_validate_option?
    ActiveRecord.gem_version >= Gem::Version.new('7.1.0')
  end

  # Rails dumps NOT VALID check constraints outside `create_table` since 7.2.3 / 8.0.1
  # cf. https://github.com/rails/rails/pull/53735
  def dump_not_valid_check_constraint_outside_create_table?
    version = ActiveRecord.gem_version
    version >= Gem::Version.new('8.0.1') ||
      (version >= Gem::Version.new('7.2.3') && version < Gem::Version.new('8.0.0'))
  end

  context 'when create table with NOT VALID check constraint' do
    subject { client }

    let(:dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.bigint "value", null: false
          t.check_constraint "value < 100", name: "value_upper_check"
          t.check_constraint "value > 0", name: "value_check", validate: false
        end
      ERB
    end

    let(:expected_dsl) do
      if dump_not_valid_check_constraint_outside_create_table?
        erbh(<<-ERB)
          create_table "clubs", force: :cascade do |t|
            t.bigint "value", null: false
            t.check_constraint "value < 100", name: "value_upper_check"
          end

          add_check_constraint "clubs", "value > 0", name: "value_check", validate: false
        ERB
      elsif dump_validate_option?
        dsl
      else
        erbh(<<-ERB)
          create_table "clubs", force: :cascade do |t|
            t.bigint "value", null: false
            t.check_constraint "value < 100", name: "value_upper_check"
            t.check_constraint "value > 0", name: "value_check"
          end
        ERB
      end
    end

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_truthy
      # PostgreSQL ignores NOT VALID on inline CREATE TABLE constraints,
      # so the NOT VALID one must be added via ALTER TABLE to remain NOT VALID.
      expect(delta.script).to match_ruby(<<-RUBY)
        create_table("clubs", **{}) do |t|
          t.column("value", :"bigint", **{:null=>false})
          t.check_constraint("value < 100", **{:name=>"value_upper_check"})
        end
        add_check_constraint("clubs", "value > 0", **{:name=>"value_check", :validate=>false})
      RUBY
      delta.migrate
      expect(convalidated('value_check')).to be false
      expect(convalidated('value_upper_check')).to be true
      expect(subject.dump).to match_ruby expected_dsl
      expect(subject.diff(dsl).differ?).to be_falsey
    }
  end

  context 'when create table with NOT VALID check constraint (bulk_change)' do
    subject { client(bulk_change: true) }

    let(:dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.bigint "value", null: false
          t.check_constraint "value > 0", name: "value_check", validate: false
        end
      ERB
    end

    let(:expected_dsl) do
      if dump_not_valid_check_constraint_outside_create_table?
        erbh(<<-ERB)
          create_table "clubs", force: :cascade do |t|
            t.bigint "value", null: false
          end

          add_check_constraint "clubs", "value > 0", name: "value_check", validate: false
        ERB
      elsif dump_validate_option?
        dsl
      else
        erbh(<<-ERB)
          create_table "clubs", force: :cascade do |t|
            t.bigint "value", null: false
            t.check_constraint "value > 0", name: "value_check"
          end
        ERB
      end
    end

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_truthy
      delta.migrate
      expect(convalidated('value_check')).to be false
      expect(subject.dump).to match_ruby expected_dsl
    }
  end
end
