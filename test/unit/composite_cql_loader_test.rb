require 'test_helper'
require 'vcr_setup.rb'

class CompositeCQLLoaderTest < ActiveSupport::TestCase
  
  setup do
    @composite_cql_mat_export = File.new File.join('test', 'fixtures', 'CMSAWA_v5_6_Artifacts.zip')
    @invalid_composite_cql_mat_export = File.new File.join('test', 'fixtures', 'CMSAWA_v5_6_Artifacts_missing_file.zip')
  end

  test 'Loading a Composite Measure' do
    VCR.use_cassette('load_composite_measure') do
      dump_db
      user = User.new
      user.save

      measure_details = { 'episode_of_care'=> false }
      begin
        Measures::CqlLoader.extract_measures(@composite_cql_mat_export, user, measure_details, { profile: APP_CONFIG['vsac']['default_profile'] }, get_ticket_granting_ticket).map {|measure| measure.save}
      rescue => e
            $stdout.puts e.inspect
            $stdout.puts e.backtrace
      end
      assert_equal 8, CqlMeasure.all.count
      # Verify there is only one composite measure
      assert_equal 1, CqlMeasure.all.where(composite: true).count
      assert_equal 7, CqlMeasure.all.where(composite: false).count

      composite_measure = CqlMeasure.all.where(composite: true).first 
      component_measures = CqlMeasure.all.where(composite: false).all
      component_measures.each do |measure|
        # Verify the component contains the composite's hqmf_set_id
        assert measure.hqmf_set_id.include?(composite_measure.hqmf_set_id)
        # Verify each composite measure has a unique hqmf_set_id
        assert_equal 1, CqlMeasure.all.where(hqmf_set_id: measure.hqmf_set_id).count
        # Verify the composite's array of components is correct
        assert composite_measure.components.include?(measure.hqmf_set_id)
      end
      # Verify the composite is associated with each of the components
      assert_equal 7, composite_measure.components.count
    end
  end

  test 'Loading an invalid composite measure that has a component measure with missing xml file' do
    skip("WIP")
    VCR.use_cassette('load_invalid_composite_measure') do
      dump_db
      user = User.new
      user.save

      measure_details = { 'episode_of_care'=> false }
      Measures::CqlLoader.extract_measures(@invalid_composite_cql_mat_export, user, measure_details, { profile: APP_CONFIG['vsac']['default_profile'] }, get_ticket_granting_ticket)
      assert_equal 0, CqlMeasure.all.count
    end
  end

  test 'Loading the same composite measure twice' do
    skip("WIP")
    VCR.use_cassette('load_composite_measure_twice') do
      dump_db
      user = User.new
      user.save

      measure_details = { 'episode_of_care'=> false }
      Measures::CqlLoader.extract_measures(@composite_cql_mat_export, user, measure_details, { profile: APP_CONFIG['vsac']['default_profile'] }, get_ticket_granting_ticket)
      assert_equal 8, CqlMeasure.all.count
      Measures::CqlLoader.extract_measures(@composite_cql_mat_export, user, measure_details, { profile: APP_CONFIG['vsac']['default_profile'] }, get_ticket_granting_ticket)
      assert_equal 8, CqlMeasure.all.count

    end
  end

  test 'Loading a composite measure with a missing component measure' do
    skip("WIP")
  end

  test 'Valid Update of a composite measure' do
    skip("WIP")
  end
  
  test 'Updating a composite measure that has a different component measure' do
    skip("WIP")
  end

end