<?php

defined('BASEPATH') OR exit('No direct script access allowed');

// This can be removed if you use __autoload() in config.php OR use Modular Extensions
/** @noinspection PhpIncludeInspection */
require APPPATH . '/libraries/REST_Controller.php';

class Data extends REST_Controller {
    function __construct()
    {
        // Construct the parent class
        parent::__construct();

        // Configure limits on our controller methods
        // Ensure you have created the 'limits' table and enabled 'limits' within application/config/rest.php
        $this->methods['index_get']['limit'] = 500;
    }

    public function index_get()
    {
        $this->load->model('Lab1_model');

        $message = $this->Lab1_model->get_last_entries();

        $this->set_response($message, REST_Controller::HTTP_CREATED); // CREATED (201) being the HTTP response code
    }

    public function index_post()
    {
        $message = [
            'x' => $this->post('x'),
            'y' => $this->post('y'),
            'z' => $this->post('z')
        ];

        // 입력 유효성 체크는 커녕 널체크도 귀찮다(언젠가 하긴 해야 한다는 뜻)
        
        $this->load->model('Lab1_model');
        
        $this->Lab1_model->insert_entry($message);

        $this->set_response($message, REST_Controller::HTTP_CREATED); // CREATED (201) being the HTTP response code
    }
}