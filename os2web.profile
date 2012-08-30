<?php

function os2web_install_tasks() {
  $task = array(
      'os2web_profile_prepare' => array(
          'type' => 'normal',
          'display_name' => st('Prepare OS2web..')
      ),
      'os2web_settings_form' => array(
          'display_name' => st('Setup OS2Web'),
          'type' => 'form',
      ),
      'os2web_import_default_feeds_form' => array(
          'display_name' => st('Setup Imports'),
          'type' => 'form',
      ),
      'os2web_import_default_feeds' => array(
          'display_name' => st('Import default content'),
          'type' => 'batch',
      ),
  );
  return $task;
}

function os2web_profile_prepare() {
  drupal_bootstrap(DRUPAL_BOOTSTRAP_FULL);
  // Menu rebuild neccesary to load xpath_parser
  menu_rebuild();

  variable_set('typekit_api_token', '42f286fdd829f36627e2002272e6f5df8a57e8f2');
  typekit_api_fontyourface_import();

  // Create the basic site structure.
  $vid = db_select('taxonomy_vocabulary', 'tv')
      ->fields('tv', array('vid'))
      ->condition('machine_name', 'site_struktur')
      ->execute()
      ->fetchField();

  // Hovedtermer
  taxonomy_term_save((object) array('name' => 'Borger', 'description' => 'Borger sektionen.', 'vid' => $vid ));
  taxonomy_term_save((object) array('name' => 'Erhverv', 'description' => 'Erhvervs sektionen.', 'vid' => $vid ));
  taxonomy_term_save((object) array('name' => 'Politik & Planer', 'description' => 'Politisk debat og indsigt.', 'vid' => $vid ));

  // Undertermer til Borger
  $tid = db_select('taxonomy_term_data', 'td')
          ->fields('td', array('tid'))
          ->condition('name', 'Borger')
          ->condition('vid', $vid)
          ->execute()->fetchField();
  taxonomy_term_save((object) array('name' => 'Dagpasning 0-6 år', 'description' => '', 'parent' => $tid, 'vid' => $vid ));
  taxonomy_term_save((object) array('name' => 'Kultur og Fritid', 'description' => '', 'parent' => $tid, 'vid' => $vid ));
  taxonomy_term_save((object) array('name' => 'Social, psykiatri og handikap', 'description' => '', 'parent' => $tid, 'vid' => $vid ));
  taxonomy_term_save((object) array('name' => 'Natur, miljø og klima', 'description' => '', 'parent' => $tid, 'vid' => $vid ));
  taxonomy_term_save((object) array('name' => 'Ældre', 'description' => '', 'parent' => $tid, 'vid' => $vid ));
  taxonomy_term_save((object) array('name' => 'Sundhed', 'description' => '', 'parent' => $tid, 'vid' => $vid ));

}

function os2web_settings_form($install_state) {
  $form['os2web_pws_config_group'] = array(
      '#type' => 'fieldset',
      '#title' => t('PWS Endpoint configuration'),
  );
  $form['os2web_pws_config_group']['os2web_pws_url'] = array(
      '#type' => 'textfield',
      '#default_value' => variable_get('os2web_pws_url'),
      '#title' => t('PWS URL for V4'),
      '#description' => t('URL to the PWS webservice endpoint.'),
  );
  $form['os2web_pws_config_group']['os2web_pws_url_v6'] = array(
      '#type' => 'textfield',
      '#default_value' => variable_get('os2web_pws_url_v6'),
      '#title' => t('PWS URL for  V6'),
      '#description' => t('URL to the PWSv6 webservice endpoint.'),
  );
  $form['os2web_pws_config_group']['os2web_pws_url_search'] = array(
      '#type' => 'textfield',
      '#default_value' => variable_get('os2web_pws_url_search'),
      '#title' => t('PWS URL for Search service'),
      '#description' => t('URL to the webservice endpoint that runs the search service.'),
  );
  $form['os2web_pws_config_group']['os2web_pws_user'] = array(
      '#type' => 'textfield',
      '#default_value' => variable_get('os2web_pws_user'),
      '#title' => t('PWS login user'),
      '#description' => t('PWS HTTP authentification user.'),
  );
  $form['os2web_pws_config_group']['os2web_pws_password'] = array(
      '#type' => 'textfield',
      '#default_value' => variable_get('os2web_pws_password'),
      '#title' => t('PWS password'),
      '#description' => t('PWS HTTP authentification password.'),
  );
  $form['os2web_pws_adlib_group'] = array(
      '#type' => 'fieldset',
      '#title' => t('Adlib Endpoint configuration'),
  );
  $form['os2web_pws_adlib_group']['os2web_adlib_url'] = array(
      '#type' => 'textfield',
      '#default_value' => variable_get('os2web_adlib_url', 'http://10.1.1.180/ExponentWSA/ExponentWSA.asmx?wsdl'),
      '#title' => t('URL for Adlib service endpoint'),
      '#description' => t('URL to the webservice endpoint that runs the Adlib service.'),
  );

  // Proxy setups
  $form['os2web_pws_proxy_group'] = array(
      '#type' => 'fieldset',
      '#collapsible' => TRUE,
      '#collapsed' => !variable_get('os2web_pws_proxy'),
      '#title' => t('Proxy configuration'),
      '#weight' => 10,
  );
  $form['os2web_pws_proxy_group']['os2web_pws_proxy'] = array(
      '#type' => 'checkbox',
      '#default_value' => variable_get('os2web_pws_proxy'),
      '#title' => t('Use proxy?'),
  );
  $form['os2web_pws_proxy_group']['os2web_pws_proxy_host'] = array(
      '#type' => 'textfield',
      '#default_value' => variable_get('os2web_pws_proxy_host'),
      '#title' => t('Proxy hostname or IP'),
  );
  $form['os2web_pws_proxy_group']['os2web_pws_proxy_port'] = array(
      '#type' => 'textfield',
      '#default_value' => variable_get('os2web_pws_proxy_port'),
      '#title' => t('Proxy port number.'),
  );
  return system_settings_form($form);
}

/**
 * Implements hook_form_FORM_ID_alter().
 *
 * Allows the profile to alter the site configuration form.
 */
function os2web_form_install_configure_form_alter(&$form, $form_state) {
  // Pre-populate the site name with the server name.
  $form['site_information']['site_name']['#default_value'] = 'OS2Web Test';
  $form['update_notifications']['update_status_module']['#default_value'] = array(0, 0);
  $form['server_settings']['site_default_country']['#default_value'] = 'DK';
  $form['admin_account']['account']['name']['#default_value'] = 'admin';
}

function os2web_import_default_feeds_form($install_state) {
  $form = array(
      'os2web_import_group' => array(
          '#type' => 'fieldset',
          '#title' => st('KLE Import'),
          '#description' => st('Setup for the KLE Term import.'),
          'os2web_import_kle_url' => array(
              '#type' => 'textfield',
              '#title' => st('Default URL for KLE terms import feed.'),
              '#default_value' => 'http://10.1.1.182/SOFDDataService/SOFDWebService.asmx/GetTaxonomy?taxonomyId=1',
          ),
          'os2web_import_kle_import' => array(
              '#type' => 'checkbox',
              '#title' => st('Import during install ?'),
              '#default_value' => false,
          ),
      ),
      'os2web_import_group2' => array(
          '#type' => 'fieldset',
          '#title' => st('Organization Terms Import'),
          '#description' => st('Setup for the Organization terms import.'),
          'os2web_import_org_url' => array(
              '#type' => 'textfield',
              '#title' => st('Default URL for Organization terms import feed.'),
              '#default_value' => 'http://10.1.1.182/SOFDDataService/SOFDWebService.asmx/GetTaxonomy?taxonomyId=5',
          ),
          'os2web_import_org_import' => array(
              '#type' => 'checkbox',
              '#title' => st('Import during install ?'),
              '#default_value' => false,
          ),
      ),
      'os2web_import_group3' => array(
          '#type' => 'fieldset',
          '#title' => st('Politics terms Import'),
          '#description' => st('Setup for the Politics terms import.'),
          'os2web_import_pol_url' => array(
              '#type' => 'textfield',
              '#title' => st('Default URL for Organization terms import feed.'),
              '#default_value' => 'http://10.1.1.182/SOFDDataService/SOFDWebService.asmx/GetTaxonomy?taxonomyId=2',
          ),
          'os2web_import_pol_import' => array(
              '#type' => 'checkbox',
              '#title' => st('Import during install ?'),
              '#default_value' => false,
          ),
      ),
      'os2web_import_group4' => array(
          '#type' => 'fieldset',
          '#title' => st('GIS terms Import'),
          '#description' => st('Setup for the GIS terms import.'),
          'os2web_import_gis_url' => array(
              '#type' => 'textfield',
              '#title' => st('Default URL for GIS terms import feed.'),
              '#default_value' => 'http://10.1.1.182/SOFDDataService/SOFDWebService.asmx/GetGisNames',
          ),
          'os2web_import_gis_import' => array(
              '#type' => 'checkbox',
              '#title' => st('Import during install ?'),
              '#default_value' => false,
          ),
      ),
      'os2web_import_group5' => array(
          '#type' => 'fieldset',
          '#title' => st('Ofir.dk job Import'),
          '#description' => st('Setup for the Ofir.dk import.'),
          'os2web_import_ofir_url' => array(
              '#type' => 'textfield',
              '#title' => st('Default URL for Ofir.dk job feed.'),
              '#default_value' => 'http://job.ofir.dk/Templates/XMLliste_7DAE0E45-E8C0-43EF-9D3C-350F69BE5C9B.asp',
          ),
          'os2web_import_ofir_import' => array(
              '#type' => 'checkbox',
              '#title' => st('Import during install ?'),
              '#default_value' => true,
          ),
      ),
  );
  return system_settings_form($form);
}

function os2web_import_default_feeds($install_state) {
  //Set default KLE taxonomy feed url
  $source = feeds_source('taxonomy_kle');
  $config = $source->getConfig();
  $config['FeedsHTTPFetcher']['source'] = variable_get('os2web_import_kle_url', '');
  $source->setConfig($config);
  $source->save();

  //Set default Organisation taxonomy feed url
  $source = feeds_source('taxonomy_organization');
  $config = $source->getConfig();
  $config['FeedsHTTPFetcher']['source'] = variable_get('os2web_import_org_url', '');
  $source->setConfig($config);
  $source->save();

  //Set default Politik taxonomy feed url
  $source = feeds_source('taxonomy_politics');
  $config = $source->getConfig();
  $config['FeedsHTTPFetcher']['source'] = variable_get('os2web_import_pol_url', '');
  $source->setConfig($config);
  $source->save();

  //Set default Egenavne/stednavne taxonomy feed url
  $source = feeds_source('taxonomy_gisnames');
  $config = $source->getConfig();
  $config['FeedsHTTPFetcher']['source'] = variable_get('os2web_import_gis_url', '');
  $source->setConfig($config);
  $source->save();

  //Set default Ofir feed url
  $source = feeds_source('ofir_job_import');
  $config = $source->getConfig();
  $config['FeedsHTTPFetcher']['source'] = variable_get('os2web_import_ofir_url', '');
  $source->setConfig($config);
  $source->save();

  $batch = array(
      'title' => t('Importing feeds'),
      'operations' => array(),
      'progress_message' => t('Current: @current | Remaining:
        @remaining | Total: @total | Percentage: @percentage'),
  );

  if (variable_get('os2web_import_kle_import'))
    $batch['operations'][] = array('feeds_batch', array('import', 'taxonomy_kle', 0));

  if (variable_get('os2web_import_org_import'))
    $batch['operations'][] = array('feeds_batch', array('import', 'taxonomy_organization', 0));

  if (variable_get('os2web_import_pol_import'))
    $batch['operations'][] = array('feeds_batch', array('import', 'taxonomy_politics', 0));

  if (variable_get('os2web_import_gis_import'))
    $batch['operations'][] = array('feeds_batch', array('import', 'taxonomy_gisnames', 0));

  if (variable_get('os2web_import_ofir_import'))
    $batch['operations'][] = array('feeds_batch', array('import', 'ofir_job_import', 0));

  // Clean up temporary vars
  variable_del('os2web_import_kle_url');
  variable_del('os2web_import_org_url');
  variable_del('os2web_import_pol_url');
  variable_del('os2web_import_gis_url');
  variable_del('os2web_import_ofir_url');
  variable_del('os2web_import_kle_import');
  variable_del('os2web_import_org_import');
  variable_del('os2web_import_pol_import');
  variable_del('os2web_import_gis_import');
  variable_del('os2web_import_ofir_import');


  return $batch;
}
