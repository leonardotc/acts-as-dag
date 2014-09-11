module Dag

    #Validations on model instance creation. Ensures no duplicate links, no cycles, and correct count and direct attributes
  class CreateCorrectnessValidator < ActiveModel::Validator

    def validate(record)
      record.errors[:base] << I18n.t('acts_as_dag.errors.create.has_duplicatess') if has_duplicates(record)
      record.errors[:base] << I18n.t('acts_as_dag.errors.create.has_long_cycles') if has_long_cycles(record)
      record.errors[:base] << I18n.t('acts_as_dag.errors.create.has_short_cycles') if has_short_cycles(record)
      cnt = check_possible(record)
      record.errors[:base] << I18n.t('acts_as_dag.errors.create.direct_nonzero_link') if cnt == 1
      record.errors[:base] << I18n.t('acts_as_dag.errors.create.indirect_less_than_one') if cnt == 2
    end

    private

    #check for duplicates
    def has_duplicates(record)
      record.class.find_link(record.source, record.sink)
    end

    #check for long cycles
    def has_long_cycles(record)
      record.class.find_link(record.sink, record.source)
    end

    #check for short cycles
    def has_short_cycles(record)
      record.sink.matches?(record.source)
    end

    #check not impossible
    def check_possible(record)
      record.direct? ? (record.count != 0 ? 1 : 0) : (record.count < 1 ? 2 : 0)
    end
  end

  #Validations on update. Makes sure that something changed, that not making a lonely link indirect, and count is correct.
  class UpdateCorrectnessValidator < ActiveModel::Validator

    def validate(record)
      record.errors[:base] << I18n.t('acts_as_dag.errors.update.no_changes') unless record.changed?
      record.errors[:base] << I18n.t('acts_as_dag.errors.update.no_manually_change_count') if manual_change(record)
      record.errors[:base] << I18n.t('acts_as_dag.errors.update.direct_link_with_one_count_indirect') if direct_indirect(record)
    end

    private

    def manual_change(record)
      record.direct_changed? && record.count_changed?
    end

    def direct_indirect(record)
      record.direct_changed? && !record.direct? && record.count == 1
    end
  end

end
