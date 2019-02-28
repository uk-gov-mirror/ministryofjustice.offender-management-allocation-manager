namespace :delius do
  desc 'Generates seed data for delius from T3'
  task generate_data: :environment do
    response = Nomis::Elite2::Api.get_offender_list('LEI', page_size: 1)
    total_elements = response.meta.total_elements

    response = Nomis::Elite2::Api.get_offender_list('LEI', page_size: total_elements)
    response.data.each_with_index { |offender, idx|
      id_val = 100 + idx
      statement = <<~HEREDOC

        INSERT INTO OFFENDER(
          FIRST_NAME, OFFENDER_ID, CRN, NOMS_NUMBER,
          SECOND_NAME, SURNAME, DATE_OF_BIRTH_DATE,
          PARTITION_AREA_ID, SOFT_DELETED, ROW_VERSION, GENDER_ID,
          SURNAME_SOUNDEX, CREATED_DATETIME, LAST_UPDATED_DATETIME,
          CURRENT_EXCLUSION, CREATED_BY_USER_ID, LAST_UPDATED_USER_ID,
          FIRST_NAME_SOUNDEX, LAST_UPDATED_USER_ID_DIVERSITY, CURRENT_DISPOSAL,
          CURRENT_RESTRICTION, PENDING_TRANSFER, CURRENT_TIER
        ) VALUES(
          '#{offender.first_name.sub("'", "\''")}', #{id_val}, 'CRN#{id_val}', '#{offender.offender_no}',
          '#{offender.middle_name}', '#{offender.last_name.sub("'", "\''")}', '#{offender.date_of_birth}',
          1, 0, 1, 1,
          'SURNAME_SOUNDEX', '2018-01-01', '2018-01-01',
          0, 1, 1,
          'FIRST_NAME_SOUNDEX', 1, 0,
          0, 0, #{random_tier}
        );
      HEREDOC

      puts statement
    }
  end
end

def random_tier
  (4096..4102).to_a.sample
end
